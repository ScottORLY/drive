//  Copyright © 2020 Scott Orlyck. All rights reserved.

import XCTest
import RxSwift
import RxCocoa

@testable import Drive

class TestDrive: XCTestCase {

    var subject: ViewModel?
    let bag = DisposeBag()
    override func setUpWithError() throws {
        
        let email: Observable<String> = Observable<String>.just("email@email")
        let password: Observable<String> = .just("email@email")
        let signIn: Observable<Void> = .just(())

        subject = ViewModel(
            email: email.asDriver(onErrorJustReturn: ""),
            password: password.asDriver(onErrorJustReturn: ""),
            signIn: signIn.asDriver(onErrorJustReturn:())
        )
    }

    func testDrive() throws {
        XCTAssertNotNil(subject)
        subject?.validatedEmail.drive(onNext: { result in
            XCTAssertEqual(result, .failed("Please enter a valid email address."))
        }).disposed(by: bag)
    }
}
