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
    import FBSDKCoreKit
    import FacebookCore
    
    @UIApplicationMain
    
    class AppDelegate: UIResponder, UIApplicationDelegate {
        
        var window: UIWindow?
        var deepLink: String?
        var facebookLink:String?
        let gcmMessageIDKey = "gcm.message_id"
        
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
            
            FirebaseApp.configure()
            registerForPushNotification(application: application)
            AppLinkUtility.fetchDeferredAppLink { (url, error) in
                if let error = error {
                    print("Received error while fetching deferred app link %@", error)
                }
                if let url = url {
                    self.facebookLink = url.absoluteString;
                    
                    //                    if #available(iOS 10, *) {
                    //                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //                    } else {
                    //                        UIApplication.shared.openURL(url)
                    //                    }
                }
            }
            
            ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
            
            return true
        }
        
        
        
        
        func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                         restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
            let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
                if(dynamiclink != nil) {
                    
                    self.deepLink =  dynamiclink?.url?.absoluteString;
                    let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController;
                    
                    viewController.webView.evaluateJavaScript("parseDynamicLink('\(self.deepLink ?? "")')", completionHandler: {(result,error) in
                        if error == nil {
                            print("no error")
                        }
                        else {
                            print("app open link : ",error.debugDescription)
                        }
                    })
                    
                }
            }
            
            return handled
        }
        
        
        
        @available(iOS 9.0, *)
        func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
            
            return application(app, open: url,
                               sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                               annotation: "")
        }
        
        func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
            if(url.absoluteString.hasPrefix("growthfile://")) {
                
                
                let viewController = UIApplication.shared.windows.first!.rootViewController as! ViewController;
                self.facebookLink = url.absoluteString;
                viewController.webView.evaluateJavaScript("parseFacebookDeeplink('\(self.facebookLink ?? "")')", completionHandler: {(result,error) in
                    if error == nil {
                        print("no error")
                    }
                    else {
                        print("app open link : ",error.debugDescription)
                    }
                })
                
                return true
            }
            
            
            if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url){
                // Handle the deep link. For example, show the deep-linked content or
                // apply a promotional offer to the user's account.
                // ...
                if(dynamicLink.url?.absoluteString != nil) {
                    deepLink = dynamicLink.url?.absoluteString;
                }
                
                return true
            }
            
            return false
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
            
            AppEvents.activateApp()
            
            
        }
        
        func applicationWillTerminate(_ application: UIApplication) {
            // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        }
        
    }
    extension UIApplicationDelegate  {
        func locationAlert(title:String,message:String) -> Void {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Go To Settings", style: UIAlertAction.Style.default, handler: {( alert : UIAlertAction!) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL, options:[:],completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
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
    
