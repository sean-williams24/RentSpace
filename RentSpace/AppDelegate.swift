//
//  AppDelegate.swift
//  RentSpace
//
//  Created by Sean Williams on 26/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//
import FacebookCore
import Firebase
import FirebaseAuth
import GoogleSignIn
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var delegate: UpdateSignInDelegate?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        UINavigationBar.appearance().barTintColor = .black
//        UINavigationBar.appearance().isTranslucent = false
                
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    

    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let appId: String = Settings.appID
        if url.scheme != nil && url.scheme!.hasPrefix("fb\(appId)") && url.host ==  "authorize" {
            return ApplicationDelegate.shared.application(application, open: url, options: options)
        } else {
        return GIDSignIn.sharedInstance().handle(url)
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    
    // MARK: - Google Sign In
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
      // ...
        print("Google sign in called")
      if let error = error {
        
        print(error.localizedDescription)
        
        return
      }

      guard let authentication = user.authentication else { return }
      let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
      // ...
        Auth.auth().signIn(with: credential) { (authResult, GSIError) in
          if let gsiError = GSIError {
            print(gsiError.localizedDescription)
            return
          }
          // User is signed in
            UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: nil)
            self.delegate?.updateSignInButton()
            self.delegate?.adjustViewForTabBar?()
        }
    }
}


