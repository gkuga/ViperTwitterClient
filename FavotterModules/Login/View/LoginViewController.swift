//
//  LoginViewController.swift
//  Favotter
//
//  Created by hirothings on 2017/12/19.
//  Copyright © 2017年 hirothings. All rights reserved.
//

import UIKit
import TwitterKit

protocol LoginView: ErrorView {}

class LoginViewController: UIViewController, LoginView {
    var presenter: LoginPresentation!

    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton = TWTRLogInButton { [weak self] (session, error) in
            guard let session = session else {
                self?.showError(message: "ログインに失敗しました")
                return
            }
            if let error = error {
                // TODO: error処理
                self?.showError(message: error.localizedDescription)
                return
            }
            self?.presenter.succeedLogin(userID: session.userID)
        }
        
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
    }
}
