//
//  AppDelegate.swift
//  GrowthfileNew
//
//  Created by Puja Capital on 03/11/18.
//  Copyright © 2018 Puja Capital. All rights reserved.
//

import UIKit
import WebKit
import Firebase
import FirebaseMessaging
import UserNotifications

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
   
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        registerForPushNotification(application: application)
 
        return true
    }

   
    /** Register for receiveing push notifications **/
    
    func registerForPushNotification(application: UIApplication){
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        }
        
        application.registerForRemoteNotifications()
    }
    
    /** On failure during registeration process. This happens when app is launched first time and user denies the
    permission for notification **/
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print(error.localizedDescription)
        }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(UIBackgroundFetchResult.newData)
       
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("app in background")
    }
    

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("view has beome active")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        let locationServiceAvailable =  Helper.checkLocationServiceState()
        if locationServiceAvailable == false {
            locationAlert(title: "Location Service is Disabled",message:"Please Enable Location Services to use Growthfile")
        }
     
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}
extension UIApplicationDelegate  {
    func locationAlert(title:String,message:String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Go To Settings", style: UIAlertAction.Style.default, handler: {( alert : UIAlertAction!) in
            UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL, options:[:],completionHandler: nil)
        }));
        
       self.window??.rootViewController?.present(alert, animated: true, completion: nil)
    }

    func connectionAlert(title:String,message:String) ->Void{
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default))
        self.window??.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
extension MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        let fcmToken:[String:String] = ["updatedToken":fcmToken]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RefreshedToken"),object:nil,userInfo:fcmToken)
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "fcmMessageReceived"),object:nil,userInfo:notification.request.content.userInfo)
    }
    
    /// Handle tap on the notification banner
    ///
    /// - Parameters:
    ///   - center: Notification Center
    ///   - response: Notification response
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
   
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { // Change `2.0` to the desired number of seconds.
            // Code you want to be delayed
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: "fcmMessageReceived"),object:nil,userInfo:response.notification.request.content.userInfo)
        
        }
      
        completionHandler();

}
}
