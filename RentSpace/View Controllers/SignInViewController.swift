//
//  SignInViewController.swift
//  RentSpace
//
//  Created by Sean Williams on 05/01/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import AuthenticationServices
import CryptoKit
import FacebookLogin
import FirebaseUI
import Firebase
import GoogleSignIn
import NVActivityIndicatorView
import UIKit

@objc protocol UpdateSignInDelegate {
    func updateSignInButton()
    @objc optional func adjustViewForTabBar()
}


class SignInViewController: UIViewController, LoginButtonDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    //MARK: - Outlets
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var googleSignInButton: GIDSignInButton!
    
    
    //MARK: - Properties
    
    fileprivate var handle: AuthStateDidChangeListenerHandle!
    var delegate: UpdateSignInDelegate?
    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                Settings.currentUser = user
            }
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = Settings.cornerRadius
        addLeftPadding(for: emailTextField, placeholderText: "Email", placeholderColour: .gray)
        addLeftPadding(for: passwordTextField, placeholderText: "Password", placeholderColour: .gray)
        showCancelButton()
        passwordTextField.isSecureTextEntry = true
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        googleSignInButton.style = .wide
        googleSignInButton.contentHorizontalAlignment = .center
        let loginButton = FBLoginButton(permissions: [ .publicProfile, .email ])
        loginButton.permissions = ["email"]
        
        for const in loginButton.constraints{
            if const.firstAttribute == NSLayoutConstraint.Attribute.height && const.constant == 28 {
                loginButton.removeConstraint(const)
            }
        }
        
        loginButton.delegate = self
        
        view.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        loginButton.leadingAnchor.constraint(equalTo: googleSignInButton.leadingAnchor, constant: 4).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: googleSignInButton.trailingAnchor, constant: -4).isActive = true
        loginButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 10).isActive = true
        
        if #available(iOS 13.0, *) {
            let authorizationButton = ASAuthorizationAppleIDButton()
            authorizationButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
            authorizationButton.cornerRadius = 3
            view.addSubview(authorizationButton)
            authorizationButton.translatesAutoresizingMaskIntoConstraints = false
            authorizationButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            authorizationButton.leadingAnchor.constraint(equalTo: loginButton.leadingAnchor).isActive = true
            authorizationButton.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor).isActive = true
            authorizationButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 13).isActive = true
        }
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    
    // MARK: - Facebook Delegates
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        }
        guard let accessTokenString = AccessToken.current?.tokenString else { return }
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        Auth.auth().signIn(with: credentials) { (FBuser, error) in
            if error != nil {
                print("Problem signing into FireBase with Facebook:", error?.localizedDescription as Any)
                self.showAlert(title: "Sign-In Error", message: "We encountered a problem signing you in through Facebook; Please try again or use a different sign-in method.")
                return
            }
            print("Successfully logged into FireBase with Facebook user:", FBuser as Any)
            self.delegate?.adjustViewForTabBar?()
            
            self.dismiss(animated: true) {
                self.delegate?.updateSignInButton()
            }
        }
    }
    
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("Facebook did logout")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let registerVC = segue.destination as! RegisterViewController
        registerVC.delegate = self
    }
    
    
    // MARK: - Apple Authentication Services
    
    @available(iOS 13, *)
    @objc func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("presentation anchor method called")
        return self.view.window!
    }
    
    
    // MARK: - Private Methods
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    
    // MARK: - Action Methods
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authUser, error) in
            if error == nil {
                self.dismiss(animated: true)
                self.delegate?.updateSignInButton()
                self.delegate?.adjustViewForTabBar?()
                
            } else {
                if let error = error, authUser == nil {
                    self.showAlert(title: "Problem Signing In", message: error.localizedDescription)
                }
            }
        }
    }
    
    
    @IBAction func forgotButtonTapped(_ sender: Any) {
        let ac = UIAlertController(title: "Password Problems?", message: "No worries, we'll send you a reset link...", preferredStyle: .alert)
        ac.addTextField { (textfield) in
            textfield.placeholder = "Enter your email address..."
            if self.emailTextField.text != nil {
                textfield.text = self.emailTextField.text
            }
        }
        
        ac.addAction(UIAlertAction(title: "SEND", style: .default, handler: { _ in
            guard let email = ac.textFields?[0].text else { return }
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                if error != nil {
                    self.showAlert(title: "Oops!", message: "There was a problem sending the reset link, please check you've got the correct email adress and try again.")
                } else {
                    self.showAlert(title: "All Good", message: "Check your inbox...")
                }
            }
        }))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .default))
        present(ac, animated: true)
    }
}

extension SignInViewController: RegisterDelegate {
    func adjustViewAfterRegistration() {
        self.delegate?.adjustViewForTabBar?()
    }
}


@available(iOS 13.0, *)
extension SignInViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                // User is signed in to Firebase with Apple.
                print("User signing into firebase with Apple")
                self.dismiss(animated: true)
                self.delegate?.updateSignInButton()
                self.delegate?.adjustViewForTabBar?()
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let ASError = error as! ASAuthorizationError
        switch ASError.code {
        case .failed, .invalidResponse, .notHandled:
            showAlert(title: "Apple Sign-In Error", message: "Please try again or try signing in via another method.")
        case .canceled:
            print("User Cancelled Apple Sign in")

        default:
            print("Unknown error")
        }
    }
    
}
