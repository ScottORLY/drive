//Copyright © 2020 Scott Orlyck. All rights reserved.

import UIKit
import RxSwift
import RxCocoa

import UIKit

class ViewController: UIViewController {

    lazy var viewModel: ViewModel = {
        ViewModel(email: email.rx.text.orEmpty.asDriver(),
                  password: password.rx.text.orEmpty.asDriver(),
                  signIn: signIn.rx.tap.asDriver())
    }()

    let bag = DisposeBag()

    // MARK: - IBOutlets

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signIn: UIButton!

    @IBOutlet weak var emailError: UILabel!
    @IBOutlet weak var passwordError: UILabel!

    @IBOutlet var tap: UITapGestureRecognizer!
    @IBOutlet weak var scroll: UIScrollView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        bindKeyboardNotifications()
    }

    func bind() {

        viewModel.validatedEmail.drive(onNext: { [weak self] result in
            if case .failed(let message) = result {
                self?.emailError.text = message
                self?.emailError.isHidden = false
            } else {
                self?.emailError.isHidden = true
            }
            UIView.animate(withDuration: 0.2) {
                self?.view.layoutIfNeeded()
            }
        }).disposed(by: bag)

        viewModel.validatedPassword.drive(onNext: { [weak self] result in
            if case .failed(let message) = result {
                self?.passwordError.isHidden = false
                self?.passwordError.text = message
            } else {
                self?.passwordError.isHidden = true
            }
            UIView.animate(withDuration: 0.2) {
                self?.view.layoutIfNeeded()
            }
        }).disposed(by: bag)

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
                let message = "Failed, please try again."
                self?.passwordError.text = message
                self?.passwordError.isHidden = false
                self?.emailError.isHidden = true
            }
            UIView.animate(withDuration: 0.2) {
                self?.view.layoutIfNeeded()
            }
        }).disposed(by: bag)

        tap.rx.event.asDriver().drive(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: bag)
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
