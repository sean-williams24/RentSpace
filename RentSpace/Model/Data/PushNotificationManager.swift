//
//  PushNotificationManager.swift
//  RentSpace
//
//  Created by Sean Williams on 09/04/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import Firebase
//import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications


class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    let ref = Database.database().reference()
    let userID: String
    init(userID: String) {
        self.userID = userID
        super.init()
    }
    
    func registerForPushNotifications() {
        print("Register called")
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        updateFirebaseRTDatabasePushTokenIfNeeded()
    }
    
    func updateFirebaseRTDatabasePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken {
            let usersRef = ref.child("users/\(userID)/tokens/fcmToken")
            usersRef.setValue(token)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        updateFirebaseRTDatabasePushTokenIfNeeded()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
    }
}
