import FirebaseFirestore

struct Review: Identifiable, Codable {
  var id: String = UUID().uuidString

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
