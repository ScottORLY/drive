//  Copyright © 2020 Scott Orlyck. All rights reserved.

import Foundation
import RxSwift

enum Validation: Equatable {
    case failed(String)
    case success
}

class ValidationService {

    static let shared = ValidationService()

    let emailTest = NSPredicate(
        format: "SELF MATCHES %@",
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")

    let passwordTest = NSPredicate(
        format: "SELF MATCHES %@",
        "^(?=.*?[A-Za-z])(?=.*?[0-9]).{8,}$")

    func validate(email: String) -> Observable<Validation> {
        if !emailTest.evaluate(with: email) {
            return .just(.failed("Please enter a valid email address."))
        }
        return .just(.success)
    }

    func validate(password: String) -> Observable<Validation> {
        if !passwordTest.evaluate(with: password) {
            return .just(.failed("Password requires 8 characters, both numbers and letters."))
        }
        return .just(.success)
    }
}
