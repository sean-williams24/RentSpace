//
//  SceneDelegate.swift
//  RentSpace
//
//  Created by Sean Williams on 26/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import FBSDKCoreKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var spaceSelectionViewController: SpaceSelectionViewController? {
        get {
            let navController = self.window?.rootViewController?.children[0] as! UINavigationController
            return navController.topViewController as? SpaceSelectionViewController
        }
    }
          
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext> ) {
        guard let url = URLContexts.first?.url else { return }
        let _ = ApplicationDelegate.shared.application(UIApplication.shared, open: url, sourceApplication: nil, annotation: [UIApplication.OpenURLOptionsKey.annotation])
    }
    
    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        spaceSelectionViewController?.pinStackViewToBottom()

    }
}

