import FirebaseFirestore

struct Restaurant: Codable {
  var name: String
  var category: String // Could become an enum
  var city: String
  var price: Int // from 1-3; could also be an enum
  var ratingCount: Int // numRatings
  var averageRating: Float
  var photo: URL

  enum CodingKeys: String, CodingKey {
    case name
    case category
    case city
    case price
    case ratingCount = "numRatings"
    case averageRating = "avgRating"
    case photo
  }
}

extension Restaurant {
  static let cities = [
    "Tel Aviv",
    "Jerusalem",
    "Haifa",
    "Rishon LeZion",
    "Petah Tikva",
    "Ashdod",
    "Netanya",
    "Beer Sheva",
    "Holon",
    "Bnei Brak",
    "Ramat Gan",
    "Bat Yam",
    "Rehovot",
    "Herzliya",
    "Kfar Saba",
    "Ra'anana",
    "Modi'in",
    "Nahariya",
    "Tiberias",
    "Eilat",
    "Safed",
    "Nazareth",
    "Akko",
    "Tiberias",
    "Kiryat Gat",
    "Lod",
    "Ramla",
    "Nazareth Illit",
    "Kiryat Ata",
    "Kiryat Bialik",
    "Kiryat Motzkin",
    "Kiryat Yam",
    "Kiryat Shmona",
    "Tirat Carmel",
    "Yavne",
    "Or Yehuda",
    "Elad",
    "Kiryat Malakhi",
    "Kiryat Ono",
    "Givatayim",
    "Yehud",
    "Kfar Yona",
    "Tira",
    "Sakhnin",
    "Karmiel",
    "Nazareth",
    "Tiberias"
  ]

  static let categories = [
    "Brunch", "Burgers", "Coffee", "Deli", "Dim Sum", "Indian", "Italian",
    "Mediterranean", "Mexican", "Pizza", "Ramen", "Sushi",
  ]

  static func imageURL(forName name: String) -> URL {
    let number = (abs(name.hashValue) % 10) + 1
    // Use local images from your app bundle
    let URLString = "https://storage.googleapis.com/firestorequickstarts.appspot.com/food_\(number).png"
    // Or use a different external service
    // let URLString = "https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=Restaurant+\(number)"
    return URL(string: URLString)!
  }

  var imageURL: URL {
    return Restaurant.imageURL(forName: name)
  }
}

struct Review: Codable {
  var rating: Int // Can also be enum
  var userID: String
  var username: String
  var text: String
  var date: Timestamp

  enum CodingKeys: String, CodingKey {
    case rating
    case userID = "userId"
    case username = "userName"
    case text
    case date
  }
}
