import FirebaseFirestore

extension Restaurant {
  var ratingsCollection: CollectionReference? {
    return reference?.collection("ratings")
  }

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

  static let prices = [1, 2, 3]

  static let sortOptions = ["category", "city", "price", "avgRating"]

  static func imageURL(forName name: String) -> URL {
    let number = (abs(name.hashValue) % 22) + 1
    let URLString =
      "https://storage.googleapis.com/firestorequickstarts.appspot.com/food_\(number).png"
    return URL(string: URLString)!
  }

  var imageURL: URL {
    return Restaurant.imageURL(forName: name)
  }

  static func priceString(from price: Int) -> String {
    if !Restaurant.prices.contains(price) {
      fatalError("price must be between one and three")
    }

    return String(repeating: "$", count: price)
  }
}
