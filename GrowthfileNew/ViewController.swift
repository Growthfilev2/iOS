//
//  ViewController.swift
//  GrowthfileNew
//
//  Created by Puja Capital on 03/11/18.
//  Copyright © 2018 Puja Capital. All rights reserved.
//



import UIKit
import WebKit
import Foundation
import Firebase
import UserNotifications
import CoreLocation
import EventKit
class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CLLocationManagerDelegate  {
    @IBOutlet  var webView: WKWebView!
    var activityIndicator: UIActivityIndicatorView!
    var locationManager:CLLocationManager!
    var didFindLocation:Bool = false;
    weak var weakTimer: Timer?

    var refreshController : UIRefreshControl = UIRefreshControl()
     func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.modalPresentationStyle = .popover
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            print("no camera")
        }
    };
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,((info[UIImagePickerController.InfoKey.originalImage] as? UIImage) != nil)  {
            
            let base64Image = Helper.convertImageDataToBase64(image:pickedImage)
           
            let setFilePath = "setFilePath('\(base64Image)')"
            
            webView.evaluateJavaScript(setFilePath) {(result,error) in
                if error == nil {
                    print ("success in sending base64 image to js")
                }
                else {
                    print("error in sending base64 image to js" , error!)
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    override func loadView() {
        super.loadView()
      
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let userContentController = WKUserContentController()

        userContentController.add(self,name:"takeImageForAttachment")
        userContentController.add(self,name:"updateApp")
        userContentController.add(self,name:"checkInternet")
        userContentController.add(self,name:"locationService")
        configuration.userContentController = userContentController
        
        self.view.addSubview(webView)
        self.view.sendSubviewToBack(webView)
        webView = WKWebView(frame: view.frame, configuration: configuration)
        
        view = webView
    }
    
    @objc func startPullToRef(refresh:UIRefreshControl){
        
        webView.evaluateJavaScript("requestCreator('Null','false')",completionHandler: {(result,error) in
            if error == nil {
                self.refreshController.endRefreshing()
            }
            else {
                print(error!)
            }
        })
}
   
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view will load")
        let request:URLRequest;
      
        // Do any additional setup after loading the view, typically from a nib.
        
        if Reachability.isConnectedToNetwork() {
            request = URLRequest(url:URL(string:"https://growthfile-207204.firebaseapp.com/v1/")!, cachePolicy:.reloadRevalidatingCacheData)
        }
        else {
            request = URLRequest(url:URL(string:"https://growthfile-207204.firebaseapp.com/v1/")!, cachePolicy:.returnCacheDataElseLoad)
        }

        activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.color = UIColor(displayP3Red: 3/255, green: 153/255, blue: 244/255, alpha: 255/255)
        webView.addSubview(activityIndicator)
        webView.navigationDelegate = self

        webView.load(request);
        
        NotificationCenter.default.addObserver(self, selector:#selector(foregroundRead), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(retrieveUpdatedTokenFromNotificationDict(_:)), name: NSNotification.Name(rawValue:"RefreshedToken"),object:nil)
        
    }
    

    func showActivityIndicator(show: Bool) {
        if show {
            activityIndicator.startAnimating()
            
        } else {
            activityIndicator.stopAnimating()
        }
    }
    @objc func foregroundRead(){
      
        webView.evaluateJavaScript("runRead()", completionHandler: nil);
    }

    @objc func callReadInJs(notification: NSNotification){
        let jsonData = try? JSONSerialization.data(withJSONObject: notification.userInfo!,options: .prettyPrinted)
        let jsonString = NSString(data: jsonData as! Data, encoding: String.Encoding.utf8.rawValue)! as String
        print(jsonString);
        webView.evaluateJavaScript("runRead(\(jsonString))", completionHandler: nil)
    }
    
    @objc func retrieveUpdatedTokenFromNotificationDict(_ notification :NSNotification){
        if let dict = notification.userInfo as NSDictionary? {
            let newToken:String = dict["updateToken"]! as! String
            setFcmTokenToJsStorage(token: newToken);
        }
    }
    
    @objc func timerMethod(){
        didFindLocation = false;
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization();
        locationManager.startUpdatingLocation();
       
    }
  
    override func viewDidAppear(_ animated: Bool) {
        print("apperance started")
        super.viewDidAppear(animated)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        let jsonObject: NSMutableDictionary = NSMutableDictionary()
        jsonObject.setValue(userLocation.coordinate.latitude, forKey: "latitude");
        jsonObject.setValue(userLocation.coordinate.longitude, forKey: "longitude");
        jsonObject.setValue(userLocation.horizontalAccuracy, forKey: "accuracy");
        jsonObject.setValue("Ios", forKey: "provider");

        let jsonData: NSData
        do {
            if(didFindLocation == false && userLocation.horizontalAccuracy <= 350) {
            jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options:JSONSerialization.WritingOptions()) as NSData
            let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            webView.evaluateJavaScript("updateLocationInRoot(\(jsonString))", completionHandler: nil);
            didFindLocation = true
        }
        } catch let jsonErr {
            webView.evaluateJavaScript("iosLocationError('\(jsonErr.localizedDescription)')", completionHandler: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
       webView.evaluateJavaScript("iosLocationError('\(error.localizedDescription)')", completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error : Error) {
        
        showToast(controller: self, message:error.localizedDescription, seconds: 5)
    }
    
    func webView(_ webView:WKWebView, didStartProvisionalNavigation navigation :WKNavigation!) {
        showActivityIndicator(show: true)

        print("Start to load")
    }
    
    
    func webView(_ webView:WKWebView, didFinish navigation:WKNavigation!) {
        print("webview has finished loading");
        showActivityIndicator(show: false)
        
        let deviceInfo:String = Helper.generateDeviceIdentifier()
        print(deviceInfo);
        webView.evaluateJavaScript("native.setName('Ios')", completionHandler: {(result,error) in
            if error == nil {
                print("no error")
            }
            else {
                print(" js execution error at ", error.debugDescription)
            }
        })
            
        webView.evaluateJavaScript("native.setIosInfo('\(deviceInfo)')", completionHandler: {(result,error) in
            if error == nil {
                print("no error")
            }
            else {
                print(" js execution error at ", error as Any)
            }
        })
    
        
        InstanceID.instanceID().instanceID(handler: { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            }
            else if let result = result {
                print("Remote instance ID token: \(result.token)")
                self.setFcmTokenToJsStorage(token:result.token)
            }
        })
        
        
        NotificationCenter.default.addObserver(self, selector:#selector(callReadInJs), name: NSNotification.Name(rawValue: "fcmMessageReceived"), object: nil)

        
        refreshController.bounds = CGRect.init(x: 0.0, y: 50.0, width: refreshController.bounds.size.width, height: refreshController.bounds.size.height)
        refreshController.addTarget(self, action: #selector(self.startPullToRef(refresh:)), for: .valueChanged)
        refreshController.attributedTitle = NSAttributedString(string: "Loading")
        webView.scrollView.addSubview(refreshController)
        
        
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showActivityIndicator(show: false)
       showToast(controller: self, message: error.localizedDescription, seconds: 5)
    }
 
    func setFcmTokenToJsStorage(token:String){
        
        self.webView.evaluateJavaScript("native.setFCMToken('\(token)')", completionHandler: {(result,error) in
            if error == nil {
                print("no error whilst regiesteriton token")
            }
            else {
                print("error occured at registering token from ios ", error as Any)
            }
        })
    }
    func showToast(controller: UIViewController, message : String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        controller.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }

  
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        
        if message.name == "takeImageForAttachment" {
            openCamera()
        }
        
        if message.name == "updateApp" {
            
            let alert = UIAlertController(title: "Message", message: "There is a New version of your app available", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Update", style: UIAlertAction.Style.default, handler: {( alert : UIAlertAction!) in
                UIApplication.shared.open((URL(string: "itms-apps://itunes.apple.com/app/1441388774")!), options:[:], completionHandler: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        if message.name == "checkInternet" {
            
            if Reachability.isConnectedToNetwork() {
                print("can get to netowkr")
                let messageString = "{connected:true}"
                webView.evaluateJavaScript("iosConnectivity(\(messageString))", completionHandler: nil)
            }
            
            else {
                print("problem getting to network")
                
                simpleAlert(title: "Message", message: "Please check your internet connection")
                webView.evaluateJavaScript("iosConnectivity({connected:false})", completionHandler: nil)
            }
        }
        if message.name == "locationService" {
            let body = String(describing:message.body);
            
            if CLLocationManager.locationServicesEnabled() {
                if body == "start" {
                     self.weakTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.timerMethod), userInfo: nil, repeats: true)
                }
                
                if body == "stop" {
                    if(self.weakTimer != nil) {
                        self.weakTimer!.invalidate();
                        self.weakTimer = nil;
                    }
                }
            }
            else {
                simpleAlert(title: "Location Service Disabled", message: "Allow Growthfile to use location services");
            }
        }
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
extension ViewController {
    func simpleAlert(title:String,message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default))
        self.present(alert, animated: true, completion: nil)
    }

}
extension Dictionary {
    var jsonStringRepresentaiton: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
                                                                return nil
        }
        
        return String(data: theJSONData, encoding: .ascii)
    }
}

