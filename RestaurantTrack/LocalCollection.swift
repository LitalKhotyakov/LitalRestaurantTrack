import FirebaseFirestore

final class LocalCollection<T: Codable> {
  private(set) var items: [T]
  private(set) var documents: [DocumentSnapshot] = []
  let query: Query

  private let updateHandler: ([DocumentChange]) -> Void

  private var listener: ListenerRegistration? {
    didSet {
      oldValue?.remove()
    }
  }

  var count: Int {
    return items.count
  }

  subscript(index: Int) -> T {
    return items[index]
  }

  init(query: Query, updateHandler: @escaping ([DocumentChange]) -> Void) {
    items = []
    self.query = query
    self.updateHandler = updateHandler
  }

  func index(of document: DocumentSnapshot) -> Int? {
    for i in 0 ..< documents.count {
      if documents[i].documentID == document.documentID {
        return i
      }
    }

    return nil
  }

  func listen() {
    guard listener == nil else { return }
    print("🎧 Starting listener for query: \(query)")
    listener = query.addSnapshotListener { [unowned self] querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error fetching snapshot results: \(error!)")
        return
      }
      print("📥 Received \(snapshot.documents.count) documents from Firestore")
      for (index, doc) in snapshot.documents.enumerated() {
        print("  📄 Document \(index): \(doc.reference.path)")
      }
      let models = snapshot.documents.map { (document) -> T in
        let maybeModel: T?
        do {
          maybeModel = try document.data(as: T.self)
        } catch {
          fatalError("Unable to initialize type \(T.self) from data \(document.data()): \(error)")
        }

        if let model = maybeModel {
          return model
        } else {
          fatalError("Missing document of type \(T.self) at \(document.reference.path)")
        }
      }
      
      // Check for duplicates
      let uniqueDocumentIDs = Set(snapshot.documents.map { $0.documentID })
      if uniqueDocumentIDs.count != snapshot.documents.count {
        print("⚠️ WARNING: Duplicate documents detected! Expected \(uniqueDocumentIDs.count) unique documents, got \(snapshot.documents.count)")
      }
      
      print("🔄 Updating collection with \(models.count) items")
      self.items = models
      self.documents = snapshot.documents
      self.updateHandler(snapshot.documentChanges)
    }
  }

  func stopListening() {
    listener = nil
  }

  deinit {
    stopListening()
  }
}
