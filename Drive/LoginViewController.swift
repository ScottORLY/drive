//Copyright © 2020 Scott Orlyck. All rights reserved.

import UIKit
import RxSwift
import RxCocoa

import UIKit

class ViewController: UIViewController {

    lazy var viewModel: LoginViewModel = {
        LoginViewModel(email: email.rx.text.orEmpty.asDriver().distinctUntilChanged(),
                       password: password.rx.text.orEmpty.asDriver().distinctUntilChanged(),
                       signIn: signIn.rx.tap.asDriver())
    }()

    let bag = DisposeBag()

    // MARK: - IBOutlets

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signIn: UIButton!

    @IBOutlet weak var emailError: UIView!
    @IBOutlet weak var passwordError: UIView!
    @IBOutlet weak var emailErrorMessage: UILabel!
    @IBOutlet weak var passwordErrorMessage: UILabel!

    @IBOutlet var tap: UITapGestureRecognizer!

    @IBOutlet weak var scroll: UIScrollView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        bindValidation()
        bindKeyboardNotifications()
    }

    func bindKeyboardNotifications() {
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: frame.height, right: 0.0)
                self?.scroll.contentInset = contentInset
            }).disposed(by: bag)

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                self?.scroll.contentInset = .zero
            }).disposed(by: bag)
    }

    func bindValidation() {

        viewModel.validatedEmail.drive(onNext: { [weak self] result in
            if case .failed(let message) = result {
                self?.emailError.isHidden = false
                self?.emailErrorMessage.text = message
            } else {
                self?.emailError.isHidden = true
                self?.emailErrorMessage.text = ""
            }
        }).disposed(by: bag)

        viewModel.validatedPassword.drive(onNext: { [weak self] result in
            if case .failed(let message) = result {
                self?.passwordError.isHidden = false
                self?.passwordErrorMessage.text = message
            } else {
                self?.passwordError.isHidden = true
                self?.passwordErrorMessage.text = ""
            }
        }).disposed(by: bag)
    }

    func bind() {

        viewModel.signingIn.drive(onNext: { [weak self] signingIn in
            self?.signIn.isEnabled = !signingIn
        }).disposed(by: bag)

        viewModel.signedIn.drive(onNext: { [weak self] signedIn in
            if case .success = signedIn {
                self?.emailError.isHidden = true
                self?.passwordError.isHidden = true
                self?.view.endEditing(true)
            }
            if case .failure = signedIn {
                let message = "Cannot login with that email and password combination. Please try again."
                self?.passwordErrorMessage.text = message
                self?.passwordError.isHidden = false
                self?.emailError.isHidden = true
            }
        }).disposed(by: bag)

        viewModel.error
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] _ in
                self?.emailError.isHidden = false
                self?.passwordError.isHidden = false
            }).disposed(by: bag)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: self.view)
        if translation.y > 0 {
            view.endEditing(true)
        }
    }
}
