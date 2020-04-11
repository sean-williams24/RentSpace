//
//  PushNotificationSender.swift
//  RentSpace
//
//  Created by Sean Williams on 10/04/2020.
//  Copyright © 2020 Sean Williams. All rights reserved.
//

import UIKit

class PushNotificationSender {
    
    func sendPushNotification(to token: String, title: String, body: String, badgeCount: Int) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "sound": "default", "badge": badgeCount],
                                           "data" : ["user" : "test_id"]
        ]
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAa_vAfK8:APA91bHvaLgd_biiT8QGMi72HWiwt0Z1jHfow8dz7XrLCJaxYN7EkGYd_2cHbtN5JzTZdOzFK44KsJSpGBX2c5m2Hjc1ckHbCt_5d1aMvvU5Zx5_OtCXRvyW2ZyRnM0vRHNpfCRnoCKR", forHTTPHeaderField: "Authorization")
        
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
