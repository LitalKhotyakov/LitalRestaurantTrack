import UIKit
import FirebaseAuth
import FirebaseFirestore

class NewReviewViewController: UIViewController, UITextFieldDelegate {
  static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil))
    -> NewReviewViewController {
    let controller = storyboard
      .instantiateViewController(
        withIdentifier: "NewReviewViewController"
      ) as! NewReviewViewController
    return controller
  }

  weak var delegate: NewReviewViewControllerDelegate?

  @IBOutlet var doneButton: UIBarButtonItem!

  @IBOutlet var ratingView: RatingView! {
    didSet {
      ratingView.addTarget(self, action: #selector(ratingDidChange(_:)), for: .valueChanged)
    }
  }

  @IBOutlet var reviewTextField: UITextField! {
    didSet {
      reviewTextField.addTarget(
        self,
        action: #selector(textFieldTextDidChange(_:)),
        for: .editingChanged
      )
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    doneButton.isEnabled = false
    reviewTextField.delegate = self
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let review = Review(rating: ratingView.rating!,
                        userID: uid,
                        username: Auth.auth().currentUser?.displayName ?? "Anonymous",
                        text: reviewTextField.text!,
                        date: Timestamp())
    delegate?.reviewController(self, didSubmitFormWithReview: review)
  }

  @objc func ratingDidChange(_ sender: Any) {
    updateSubmitButton()
  }

  func textFieldIsEmpty() -> Bool {
    guard let text = reviewTextField.text else { return true }
    return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func updateSubmitButton() {
    doneButton.isEnabled = (ratingView.rating != nil && !textFieldIsEmpty())
  }

  @objc func textFieldTextDidChange(_ sender: Any) {
    updateSubmitButton()
  }
}

protocol NewReviewViewControllerDelegate: NSObjectProtocol {
  func reviewController(_ controller: NewReviewViewController,
                        didSubmitFormWithReview review: Review)
}
