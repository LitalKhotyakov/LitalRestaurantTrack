import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseAuthUI
import FirebaseEmailAuthUI
import SDWebImage

func priceString(from price: Int) -> String {
  let priceText: String
  switch price {
  case 1:
    priceText = "$"
  case 2:
    priceText = "$$"
  case 3:
    priceText = "$$$"
  case _:
    fatalError("price must be between one and three")
  }

  return priceText
}

class RestaurantsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var tableView: UITableView!
  @IBOutlet var activeFiltersStackView: UIStackView!
  @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet var cityFilterLabel: UILabel!
  @IBOutlet var categoryFilterLabel: UILabel!
  @IBOutlet var priceFilterLabel: UILabel!

  let backgroundView = UIImageView()

  private var restaurants: [Restaurant] = []
  private var documents: [DocumentSnapshot] = []

  fileprivate var query: Query? {
    didSet {
      if let listener = listener {
        listener.remove()
        observeQuery()
      }
    }
  }

  private var listener: ListenerRegistration?

  fileprivate func observeQuery() {
    guard let query = query else { return }
    stopObserving()

    // Display data from Firestore, part one

    listener = query.addSnapshotListener { [unowned self] snapshot, error in
      guard let snapshot = snapshot else {
        print("Error fetching snapshot results: \(error!)")
        return
      }
      let models = snapshot.documents.map { (document) -> Restaurant in
        let maybeModel: Restaurant?
        do {
          maybeModel = try document.data(as: Restaurant.self)
        } catch {
          fatalError(
            "Unable to initialize type \(Restaurant.self) with dictionary \(document.data()): \(error)"
          )
        }

        if let model = maybeModel {
          return model
        } else {
          // Don't use fatalError here in a real app.
          fatalError("Missing document of type \(Restaurant.self) at \(document.reference.path)")
        }
      }
      self.restaurants = models
      self.documents = snapshot.documents

      if self.documents.count > 0 {
        self.tableView.backgroundView = nil
      } else {
        self.tableView.backgroundView = self.backgroundView
      }

      self.tableView.reloadData()
    }
  }

  fileprivate func stopObserving() {
    listener?.remove()
  }

  fileprivate func baseQuery() -> Query {
    return Firestore.firestore().collection("restaurants").limit(to: 50)
  }

  private lazy var filters: (navigationController: UINavigationController,
                             filtersController: FiltersViewController) = {
    FiltersViewController.fromStoryboard(delegate: self)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    backgroundView.image = UIImage(named: "tasty")!
    backgroundView.contentMode = .scaleAspectFit
    backgroundView.alpha = 0.5
    tableView.backgroundView = backgroundView
    tableView.tableFooterView = UIView()

    navigationController?.navigationBar.applyFirebaseAppearance()

    tableView.dataSource = self
    tableView.delegate = self
    query = baseQuery()
    stackViewHeightConstraint.constant = 0
    activeFiltersStackView.isHidden = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setNeedsStatusBarAppearanceUpdate()
    observeQuery()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let auth = FUIAuth.defaultAuthUI()!
    if auth.auth?.currentUser == nil {
      let emailAuthProvider = FUIEmailAuth()
      auth.providers = [emailAuthProvider]
      present(auth.authViewController(), animated: true, completion: nil)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopObserving()
  }

  private func clearExistingData() {
    print("🧹 Clearing existing data...")
    let firestore = Firestore.firestore()
    
    // Get all existing restaurants
    firestore.collection("restaurants").getDocuments { [weak self] snapshot, error in
      if let error = error {
        print("Error getting restaurants: \(error)")
        return
      }
      
      guard let documents = snapshot?.documents else { return }
      print("🗑️ Found \(documents.count) existing restaurants to delete")
      
      // Use a dispatch group to wait for all review queries to complete
      let group = DispatchGroup()
      var allOperations: [() -> Void] = []
      
      for document in documents {
        group.enter()
        
        // Delete all reviews for this restaurant
        let reviewsQuery = document.reference.collection("ratings")
        reviewsQuery.getDocuments { snapshot, error in
          defer { group.leave() }
          
          if let reviewDocs = snapshot?.documents {
            for reviewDoc in reviewDocs {
              allOperations.append {
                firestore.batch().deleteDocument(reviewDoc.reference).commit { error in
                  if let error = error {
                    print("Error deleting review: \(error)")
                  }
                }
              }
            }
          }
          
          // Delete the restaurant
          allOperations.append {
            firestore.batch().deleteDocument(document.reference).commit { error in
              if let error = error {
                print("Error deleting restaurant: \(error)")
              }
            }
          }
        }
      }
      
      // Execute all operations after all queries complete
      group.notify(queue: .main) {
        print("✅ Successfully cleared existing data")
      }
    }
  }

  @IBAction func didTapPopulateButton(_ sender: Any) {
    // First, clear existing data to ensure clean state
    clearExistingData()
    
    // Wait a moment for the clear operation to complete
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      self?.generateNewData()
    }
  }
  
  private func generateNewData() {
    let words = ["Bar", "Fire", "Grill", "Drive Thru", "Place", "Best", "Spot", "Prime", "Eatin'"]

    let cities = Restaurant.cities
    let categories = Restaurant.categories

    for _ in 0 ..< 20 {
      let randomIndexes = (Int(arc4random_uniform(UInt32(words.count))),
                           Int(arc4random_uniform(UInt32(words.count))))
      let name = words[randomIndexes.0] + " " + words[randomIndexes.1]
      let category = categories[Int(arc4random_uniform(UInt32(categories.count)))]
      let city = cities[Int(arc4random_uniform(UInt32(cities.count)))]
      let price = Int(arc4random_uniform(3)) + 1
      let photo = Restaurant.imageURL(forName: name)

      // Basic writes

      let collection = Firestore.firestore().collection("restaurants")

      let restaurant = Restaurant(
        name: name,
        category: category,
        city: city,
        price: price,
        ratingCount: 0,  // Start with 0 reviews
        averageRating: 0, // Start with 0 average rating
        photo: photo
      )

      let restaurantRef = collection.document()
      print("🏪 Creating restaurant: \(name) with ID: \(restaurantRef.documentID)")
      do {
        try restaurantRef.setData(from: restaurant)
      } catch {
        fatalError("Encoding Restaurant failed: \(error)")
      }
      
      // No automatic reviews - only users can add reviews
      print("✅ Restaurant created: \(name) - No reviews added (users will add reviews manually)")
    }
    
    // Verify the data structure after generation
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
      self?.verifyDataStructure()
    }
  }
  
  private func verifyDataStructure() {
    print("🔍 Verifying data structure...")
    let firestore = Firestore.firestore()
    
    firestore.collection("restaurants").getDocuments { snapshot, error in
      if let error = error {
        print("Error getting restaurants: \(error)")
        return
      }
      
      guard let documents = snapshot?.documents else { return }
      print("📊 Found \(documents.count) restaurants")
      
      for document in documents {
        let restaurantName = document.data()["name"] as? String ?? "Unknown"
        let ratingCount = document.data()["numRatings"] as? Int ?? 0
        print("🏪 Restaurant: \(restaurantName) (ID: \(document.documentID)) - Reviews: \(ratingCount)")
        
        // Check reviews for this restaurant
        document.reference.collection("ratings").getDocuments { snapshot, error in
          if let reviewDocs = snapshot?.documents {
            print("  📝 Found \(reviewDocs.count) reviews for \(restaurantName)")
            if reviewDocs.isEmpty {
              print("    - No reviews yet (users will add reviews manually)")
            } else {
              for reviewDoc in reviewDocs {
                let reviewData = reviewDoc.data()
                let text = reviewData["text"] as? String ?? "No text"
                let username = reviewData["userName"] as? String ?? "Unknown"
                print("    - \(username): \(text)")
              }
            }
          }
        }
      }
    }
  }

  @IBAction func didTapClearButton(_ sender: Any) {
    filters.filtersController.clearFilters()
    controller(
      filters.filtersController,
      didSelectCategory: nil,
      city: nil,
      price: nil,
      sortBy: nil
    )
  }
  
  @IBAction func didTapClearReviewsButton(_ sender: Any) {
    clearAllReviews()
  }
  
  private func clearAllReviews() {
    print("🧹 Clearing all existing reviews...")
    let firestore = Firestore.firestore()
    
    // Get all existing restaurants
    firestore.collection("restaurants").getDocuments { snapshot, error in
      if let error = error {
        print("Error getting restaurants: \(error)")
        return
      }
      
      guard let documents = snapshot?.documents else { return }
      print("🗑️ Found \(documents.count) restaurants to clear reviews from")
      
      for document in documents {
        // Delete all reviews for this restaurant
        let reviewsQuery = document.reference.collection("ratings")
        reviewsQuery.getDocuments { snapshot, error in
          if let reviewDocs = snapshot?.documents {
            for reviewDoc in reviewDocs {
              firestore.batch().deleteDocument(reviewDoc.reference).commit { error in
                if let error = error {
                  print("Error deleting review: \(error)")
                }
              }
            }
          }
        }
        
        // Reset restaurant rating data
        firestore.batch().updateData([
          "numRatings": 0,
          "avgRating": 0
        ], forDocument: document.reference).commit { error in
          if let error = error {
            print("Error resetting restaurant data: \(error)")
          }
        }
      }
      
      print("✅ Successfully cleared all reviews - restaurants remain")
    }
  }

  @IBAction func didTapFilterButton(_ sender: Any) {
    present(filters.navigationController, animated: true, completion: nil)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    set {}
    get {
      return .lightContent
    }
  }

  deinit {
    listener?.remove()
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell",
                                             for: indexPath) as! RestaurantTableViewCell
    let restaurant = restaurants[indexPath.row]
    cell.populate(restaurant: restaurant)
    return cell
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return restaurants.count
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let controller = RestaurantDetailViewController.fromStoryboard()
    controller.titleImageURL = restaurants[indexPath.row].photo
    controller.restaurant = restaurants[indexPath.row]
    controller.restaurantReference = documents[indexPath.row].reference
    navigationController?.pushViewController(controller, animated: true)
  }
}

extension RestaurantsTableViewController: FiltersViewControllerDelegate {
  func query(withCategory category: String?, city: String?, price: Int?, sortBy: String?) -> Query {
    var filtered = baseQuery()

    if category == nil, city == nil, price == nil, sortBy == nil {
      stackViewHeightConstraint.constant = 0
      activeFiltersStackView.isHidden = true
    } else {
      stackViewHeightConstraint.constant = 44
      activeFiltersStackView.isHidden = false
    }

    // Advanced queries

    if let category = category, !category.isEmpty {
      filtered = filtered.whereField("category", isEqualTo: category)
    }

    if let city = city, !city.isEmpty {
      filtered = filtered.whereField("city", isEqualTo: city)
    }

    if let price = price {
      filtered = filtered.whereField("price", isEqualTo: price)
    }

    if let sortBy = sortBy, !sortBy.isEmpty {
      filtered = filtered.order(by: sortBy)
    }

    return filtered
  }

  func controller(_ controller: FiltersViewController,
                  didSelectCategory category: String?,
                  city: String?,
                  price: Int?,
                  sortBy: String?) {
    let filtered = query(withCategory: category, city: city, price: price, sortBy: sortBy)

    if let category = category, !category.isEmpty {
      categoryFilterLabel.text = category
      categoryFilterLabel.isHidden = false
    } else {
      categoryFilterLabel.isHidden = true
    }

    if let city = city, !city.isEmpty {
      cityFilterLabel.text = city
      cityFilterLabel.isHidden = false
    } else {
      cityFilterLabel.isHidden = true
    }

    if let price = price {
      priceFilterLabel.text = priceString(from: price)
      priceFilterLabel.isHidden = false
    } else {
      priceFilterLabel.isHidden = true
    }

    query = filtered
    observeQuery()
  }
}

class RestaurantTableViewCell: UITableViewCell {
  @IBOutlet private var thumbnailView: UIImageView!

  @IBOutlet private var nameLabel: UILabel!

  @IBOutlet var starsView: ImmutableStarsView!

  @IBOutlet private var cityLabel: UILabel!

  @IBOutlet private var categoryLabel: UILabel!

  @IBOutlet private var priceLabel: UILabel!

  func populate(restaurant: Restaurant) {
    // Displaying data, part two

    nameLabel.text = restaurant.name
    cityLabel.text = restaurant.city
    categoryLabel.text = restaurant.category
    starsView.rating = Int(restaurant.averageRating.rounded())
    priceLabel.text = priceString(from: restaurant.price)

    let image = restaurant.photo
    thumbnailView.sd_setImage(with: image)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.sd_cancelCurrentImageLoad()
  }
}
