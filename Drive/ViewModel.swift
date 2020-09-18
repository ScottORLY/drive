//Copyright © 2020 Scott Orlyck. All rights reserved.

import RxSwift
import RxCocoa
import Foundation

class ViewModel {

    //MARK: - Outputs

    let validatedEmail: Driver<Validation>
    let validatedPassword: Driver<Validation>

    let signingIn: Driver<Bool>
    let signedIn: Driver<LoginResponse>

    //MARK: - Inputs

    init(
        email: Driver<String>,
        password: Driver<String>,
        signIn: Driver<Void>
    ) {
        let validation = ValidationService.shared

        validatedEmail = Driver.combineLatest(email, signIn).flatMapLatest {
            validation.validate(email: $0.0)
                .asDriver(onErrorJustReturn: .failed("Email required."))
        }

        validatedPassword = Driver.combineLatest(password, signIn).flatMapLatest {
            validation.validate(password: $0.0)
                .asDriver(onErrorJustReturn: .failed("Password required."))
        }

        let emailPassword = Driver.combineLatest(email, password)

        let activity = ActivityIndicator()
        signingIn = activity.asDriver()

        let validated = Driver.combineLatest(
            emailPassword,
            validatedEmail,
            validatedPassword,
            signingIn
        )

        signedIn = signIn.withLatestFrom(validated).flatMapLatest { combined in
            let (emailPassword, validatedUsername, validatedPassword, signingIn) = combined
            guard case (.success, .success, false) = (validatedUsername, validatedPassword, signingIn) else {
                return .just(.validating)
            }
            return Network.shared.login(email: emailPassword.0,
                                        password: emailPassword.1)
                .flatMap { response -> Observable<LoginResponse> in
                    if case .failure = response {
                        return .just(.success)
                    }
                    return .just(response)
            }
            .trackActivity(activity)
            .asDriver(onErrorJustReturn: .failure)
        }
    }
}
