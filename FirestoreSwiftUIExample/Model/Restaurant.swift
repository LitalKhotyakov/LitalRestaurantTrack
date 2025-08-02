import FirebaseFirestore

struct Restaurant: Identifiable, Codable {
  var id: String = UUID().uuidString
  var reference: DocumentReference?

  var name: String
  var category: String // Could become an enum
  var city: String
  var price: Int // from 1-3; could also be an enum
  var ratingCount: Int // numRatings
  var averageRating: Float
  var photo: URL

  enum CodingKeys: String, CodingKey {
    case reference
    case name
    case category
    case city
    case price
    case ratingCount = "numRatings"
    case averageRating = "avgRating"
    case photo
  }
}
