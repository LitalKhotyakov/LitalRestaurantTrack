import UIKit

extension UINavigationBar {
  static let firebaseBlue =
    UIColor(red: 0x3D / 0xFF, green: 0x5A / 0xFF, blue: 0xFE / 0xFF, alpha: 1.0)
  static let firebaseTitleTextAttributes =
    [NSAttributedString.Key.foregroundColor: UIColor.white]

  @available(iOS 13.0, *)
  var firebaseNavigationBarAppearance: UINavigationBarAppearance {
    let navBarAppearance = UINavigationBarAppearance()
    navBarAppearance.configureWithOpaqueBackground()
    navBarAppearance.backgroundColor = UINavigationBar.firebaseBlue
    navBarAppearance.titleTextAttributes = UINavigationBar.firebaseTitleTextAttributes
    return navBarAppearance
  }

  @available(iOS 13.0, *)
  func applyAppearance(_ appearance: UINavigationBarAppearance) {
    standardAppearance = appearance
    compactAppearance = appearance
    scrollEdgeAppearance = appearance
    if #available(iOS 15.0, *) {
      compactScrollEdgeAppearance = appearance
    }
  }

  func applyFirebaseAppearance() {
    barTintColor = UINavigationBar.firebaseBlue
    isTranslucent = false
    titleTextAttributes = UINavigationBar.firebaseTitleTextAttributes

    if #available(iOS 13.0, *) {
      applyAppearance(firebaseNavigationBarAppearance)
    }
  }
}
