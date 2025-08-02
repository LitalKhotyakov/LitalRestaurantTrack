import SwiftUI
import FirebaseCore

@main
struct FirestoreSwiftUIExampleApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      SignInView()
    }
  }
}
