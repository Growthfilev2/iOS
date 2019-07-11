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
import ContactsUI
class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CLLocationManagerDelegate,CNContactPickerDelegate  {
    @IBOutlet  var webView: WKWebView!
    var activityIndicator: UIActivityIndicatorView!
    var locationManager:CLLocationManager!
    var didFindLocation:Bool = false;
    var callbackName:String = "";
    

    
     func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            print("no camera")
        }
    };

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            
            let base64Image:String = Helper.convertImageDataToBase64(image:pickedImage) as! String;

            let setFilePath = "\(callbackName)('\(base64Image)')"
            
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
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true, completion: nil)

      
        let phoneNumberCount = contact.phoneNumbers.count;
        var name:String = contact.givenName;
        var phoneNumber:String = "";
        var email:String = "";
        var stringBuilder = "";
        if contact.emailAddresses.count >= 1 {
            email = contact.emailAddresses[0].value as String;
        }
        
        if(phoneNumberCount == 0) {
            self.simpleAlert(title: "Missing info", message: "You have no phone numbers associated with this contact")
            return;
        };
        
        if(phoneNumberCount == 1) {
            phoneNumber = contact.phoneNumbers[0].value.stringValue
            stringBuilder = "displayName=\(name)&phoneNumber=\(phoneNumber)&email=\(email)"
 
            let script = "\(callbackName)('\(stringBuilder)')"
            webView.evaluateJavaScript(script,completionHandler: {(result,error) in
                if error == nil {
                    print ("success in sedngin contact")
                }
                else {
                    print("error" , error!)
                }
            });
            return;
        }
        if(phoneNumberCount > 1) {
            
            let multipleNumbersActionAlert = UIAlertController(title:"Which Contact To Choose",message: "This contact has multiple phone numbers, which one did you want use?",preferredStyle: UIAlertController.Style.alert)
            for number in contact.phoneNumbers {
                if let actualNumber = number.value as? CNPhoneNumber {
                    var label:String = number.label ?? "phone Number";
                
                    label = label.replacingOccurrences(of:"_", with:  "", options: NSString.CompareOptions.literal, range: nil)
                    label = label.replacingOccurrences(of:"$", with: "", options: NSString.CompareOptions.literal, range: nil)
                    label = label.replacingOccurrences(of:"!", with: "", options: NSString.CompareOptions.literal, range: nil)
                    label = label.replacingOccurrences(of:"<", with: "", options: NSString.CompareOptions.literal, range: nil)
                    label = label.replacingOccurrences(of:">", with: "", options: NSString.CompareOptions.literal, range: nil)
                    let title = label + " : " + actualNumber.stringValue;
                  
                    
                    let numberAction = UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: {(theAction) -> Void in
                        name = contact.givenName;
                        phoneNumber =  actualNumber.stringValue;
                        stringBuilder = "displayName=\(name)&phoneNumber=\(phoneNumber)&email=\(email)"
                        
                        let script = "\(self.callbackName)('\(stringBuilder)')"
                        self.webView.evaluateJavaScript(script,completionHandler: {(result,error) in
                            if error == nil {
                                print ("success in sedngin contact")
                            }
                            else {
                                print("error" , error!)
                            }
                        });
                    })
                    multipleNumbersActionAlert.addAction(numberAction);
                    
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (theAction) -> Void in
                //Cancel action completion
            })
            
            //Add the cancel action
            multipleNumbersActionAlert.addAction(cancelAction)
            self.present(multipleNumbersActionAlert, animated: true, completion: nil)

            return;
        }
        
        
     
    }
    
    func contactPickerDidCancel(picker: CNContactPickerViewController) {
        picker.dismiss(animated: true,completion: nil)
    }
    
    override func loadView() {
        super.loadView()
      
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let userContentController = WKUserContentController()

        userContentController.add(self,name:"startCamera")
        userContentController.add(self,name:"updateApp")
        userContentController.add(self,name:"checkInternet")
        userContentController.add(self,name:"locationService")
        userContentController.add(self,name:"getContact")
        configuration.userContentController = userContentController
        
        self.view.addSubview(webView)
        self.view.sendSubviewToBack(webView)
        webView = WKWebView(frame: view.frame, configuration: configuration)
        
        view = webView
    }
    

   
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view will load")
        let request:URLRequest;
      
        // Do any additional setup after loading the view, typically from a nib.
        
        if Reachability.isConnectedToNetwork() {
            request = URLRequest(url:URL(string:"https://growthfilev2-0.firebaseapp.com/v1/")!, cachePolicy:.reloadRevalidatingCacheData)
        }
        else {
            request = URLRequest(url:URL(string:"https://growthfilev2-0.firebaseapp.com/v1/")!, cachePolicy:.returnCacheDataElseLoad)
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
        
        NotificationCenter.default.addObserver(self, selector:#selector(retrieveUpdatedTokenFromNotificationDict(_:)), name: NSNotification.Name(rawValue:"RefreshedToken"),object:nil);
        
        NotificationCenter.default.addObserver(self, selector:#selector(callReadInJs), name: NSNotification.Name(rawValue: "fcmMessageReceived"), object: nil);
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
    
        webView.evaluateJavaScript("try { runRead(\(jsonString))}catch(e){}", completionHandler: nil)
    }
    
    @objc func retrieveUpdatedTokenFromNotificationDict(_ notification :NSNotification){
        if let dict = notification.userInfo as NSDictionary? {
            let newToken:String = dict["updateToken"]! as! String
            setFcmTokenToJsStorage(token: newToken);
        }
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
            webView.evaluateJavaScript("updateIosLocation(\(jsonString))", completionHandler: nil);
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
        
     
        if(didFindLocation == false) {
            webView.evaluateJavaScript("iosLocationError('\(error.localizedDescription)')", completionHandler: nil)
            didFindLocation = true
        }
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
        
        if message.name == "startCamera" {
            callbackName = message.body as! String
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
         
            if(Helper.checkLocationServiceState()) {
                didFindLocation = false;
                locationManager = CLLocationManager()
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestAlwaysAuthorization();
                locationManager.startUpdatingLocation();
            }
            else {
                locationAlert(title: "Location Service is Disabled",message:"Please Enable Location Services to use Growthfile");
            }
        }
        if message.name == "getContact" {
            callbackName = message.body as! String
            let contactPicker = CNContactPickerViewController();
            contactPicker.delegate = self;
            contactPicker.displayedPropertyKeys = [CNContactGivenNameKey,CNContactPhoneNumbersKey,CNContactEmailAddressesKey];
          
            self.present(contactPicker,animated: true,completion:nil);
            
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
    func locationAlert(title:String,message:String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Go To Settings", style: UIAlertAction.Style.default, handler: {( alert : UIAlertAction!) in
            UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL, options:[:],completionHandler: nil)
        }));
        
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

