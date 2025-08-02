import Combine
import FirebaseFirestore
import SwiftUI

class RestaurantListViewModel: ObservableObject {
  @Published var restaurants = [Restaurant]()
  private var db = Firestore.firestore()
  private var listener: ListenerRegistration?
  private let baseQuery: Query = Firestore.firestore().collection("restaurants").limit(to: 50)

  deinit {
    unsubscribe()
  }

  func unsubscribe() {
    if listener != nil {
      listener?.remove()
      listener = nil
    }
  }

  func subscribe(to query: Query) {
    if listener == nil {
      listener = query.addSnapshotListener { [weak self] querySnapshot, error in
        guard let documents = querySnapshot?.documents else {
          print("Error fetching documents: \(error!)")
          return
        }

        guard let self = self else { return }
        self.restaurants = documents.compactMap { document in
          do {
            var restaurant = try document.data(as: Restaurant.self)
            restaurant.reference = document.reference
            return restaurant
          } catch {
            print(error)
            return nil
          }
        }
      }
    }
  }

  func filter(query: Query) {
    unsubscribe()
    subscribe(to: query)
  }

  func query(category: String?, city: String?, price: Int?, sortOption: String?) -> Query {
    var filteredQuery = baseQuery

    if let category = category {
      filteredQuery = filteredQuery.whereField("category", isEqualTo: category)
    }

    if let city = city {
      filteredQuery = filteredQuery.whereField("city", isEqualTo: city)
    }

    if let price = price {
      filteredQuery = filteredQuery.whereField("price", isEqualTo: price)
    }

    if let sortOption = sortOption {
      filteredQuery = filteredQuery.order(by: sortOption)
    }

    return filteredQuery
  }

  func populate() {
    db.populate()
  }
}
