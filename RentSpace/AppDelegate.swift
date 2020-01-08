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
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    let dataController = DataController(modelName: "RentSpace")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.load()
        Global.dataController = dataController
        
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        
        return true
    }
    
  

    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
//        return ApplicationDelegate.shared.application(application, open: url, options: options)
      return GIDSignIn.sharedInstance().handle(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    

    // MARK: UISceneSession Lifecycle

//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }
    
    func saveViewContext () {
          try? dataController.viewContext.save()
      }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
      // ...
      if let error = error {
        // ...
        return
      }

      guard let authentication = user.authentication else { return }
      let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
      // ...
        Auth.auth().signIn(with: credential) { (authResult, error) in
          if let error = error {
            // ...
            return
          }
          // User is signed in
          // ...
            UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: nil)
            
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    

//    //  AppDelegate.m
//    #import <FBSDKCoreKit/FBSDKCoreKit.h>
//
//    - (BOOL)application:(UIApplication *)application
//        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//      
//      [[FBSDKApplicationDelegate sharedInstance] application:application
//        didFinishLaunchingWithOptions:launchOptions];
//      // Add any custom logic here.
//      return YES;
//    }
//
//    - (BOOL)application:(UIApplication *)application
//                openURL:(NSURL *)url
//                options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
//
//      BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
//        openURL:url
//        sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
//        annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
//      ];
//      // Add any custom logic here.
//      return handled;
//    }
        

}

