//  Copyright © 2020 Scott Orlyck. All rights reserved.

import Foundation
import RxSwift

enum LoginResponse {
    case success
    case failure
    case validating
}

class Network {

    static let shared = Network()

    let session = URLSession.shared.rx

    let url = URL(string: "http://localhost/login")!

    func login(email: String, password: String) -> Observable<LoginResponse> {
        let request = URLRequest(url: url)
        return session.response(request: request).map { (response, data) -> LoginResponse in
            if response.statusCode == 401 || response.statusCode == 400 {
                return .failure
            }
            if response.statusCode == 201 {
                    return .success
            }
            return .failure
        }
    }
}

