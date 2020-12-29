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
import FacebookCore
import FBSDKCoreKit
import MessageUI
import AVFoundation


class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CLLocationManagerDelegate,CNContactPickerDelegate  {
    
    @IBOutlet  var webView: WKWebView!
    @IBOutlet weak var myTopBar: UIView!
    
    
    var activityIndicator: UIActivityIndicatorView!
    var locationManager:CLLocationManager!
    var didFindLocation:Bool = false;
    var callbackName:String = "";
    
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    func openCamera(){
        let deviceDiscoverySession = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        guard let captureDevice = deviceDiscoverySession else {
            print("Failed to get the camera device")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            print("camera type",input.device)
            
            let inputs = captureSession.inputs
            for input in inputs {
                captureSession.removeInput(input)
            }
            
            
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            for output in captureSession.outputs {
                captureSession.removeOutput(output)
            }
            
            captureSession.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            
        } catch {
            print(error)
            return
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        captureSession.startRunning()
        //        webView.isHidden = true
    };
    
    func closeCamera() {
        captureSession.stopRunning()
      
        //        videoPreviewLayer?.session?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Change `2.0` to the desired number of seconds.
//            // Code you want to be delayed
//            self.openCamera()
//        }
        //        webView.isHidden = fal
        //        webView.isHidden = false
        //        videoPreviewLayer?.isHidden = true
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        videoPreviewLayer?.frame = self.view.bounds
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.videoPreviewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                case .landscapeRight:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                case .landscapeLeft:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                case .portraitUpsideDown:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                default:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
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
            self.simpleAlert(title: "No phone numbers found", message: "No phone number found for this contact")
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
            
            let multipleNumbersActionAlert = UIAlertController(title:"Choose a contact number",message: "This contact has multiple phone numbers. Which one do you want to use?",preferredStyle: UIAlertController.Style.alert)
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
        configuration.limitsNavigationsToAppBoundDomains = true;
        
        let userContentController = WKUserContentController()
        userContentController.add(self,name:"startCamera")
        userContentController.add(self,name:"updateApp")
        userContentController.add(self,name:"checkInternet")
        userContentController.add(self,name:"locationService")
        userContentController.add(self,name:"getContact")
        userContentController.add(self,name:"logEvent")
        userContentController.add(self,name:"share");
        userContentController.add(self,name:"firebaseAnalytics")
        configuration.userContentController = userContentController
        
        //        self.view.addSubview(webView)
        //        self.view.sendSubviewToBack(webView)
        
        webView = WKWebView(frame:self.view.frame , configuration: configuration)
        webView.navigationDelegate = self
        view = webView
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view will load")
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        //        self.view.addSubview(self.webView)
        // You can set constant space for Left, Right, Top and Bottom Anchors
        NSLayoutConstraint.activate([
            self.webView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.webView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
        ])
        // For constant height use the below constraint and set your height constant and remove either top or bottom constraint
        //self.webView.heightAnchor.constraint(equalToConstant: 200.0),
        
        self.view.setNeedsLayout()
        
        
        let request:URLRequest;
        
        // Do any additional setup after loading the view, typically from a nib.
        
        if Reachability.isConnectedToNetwork() {
            request = URLRequest(url:URL(string:"https://app.growthfile.com")!, cachePolicy:.reloadRevalidatingCacheData)
        }
        else {
            request = URLRequest(url:URL(string:"https://app.growthfile.com")!, cachePolicy:.returnCacheDataElseLoad)
        }
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.large
        
        if #available(iOS 10.0, *) {
            activityIndicator.color = UIColor(displayP3Red: 3/255, green: 153/255, blue: 244/255, alpha: 255/255)
        } else {
            // Fallback on earlier versions
        }
        //        webView.addSubview(activityIndicator)
        //        webView.navigationDelegate = self
        
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
        
        webView.evaluateJavaScript("backgroundTransition()", completionHandler: nil);
    }
    
    @objc func callReadInJs(notification: NSNotification){
        let jsonData = try? JSONSerialization.data(withJSONObject: notification.userInfo!,options: .prettyPrinted)
        let jsonString = NSString(data: jsonData as! Data, encoding: String.Encoding.utf8.rawValue)! as String
        print(jsonString);
        
        webView.evaluateJavaScript("try {navigator.serviceWorker.controller.postMessage({type:'read'})}catch(e){console.error(e)}", completionHandler: nil)
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
        print(error)
        showToast(controller: self, message:error.localizedDescription, seconds: 5)
    }
    
    func webView(_ webView:WKWebView, didStartProvisionalNavigation navigation :WKNavigation!) {
        showActivityIndicator(show: true)
        
        print("Start to load")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView {
            decisionHandler(.allow)
            return
        }
        
        let app  = UIApplication.shared;
        if let url = navigationAction.request.url {
            if url.scheme == "comgooglemaps://" || url.scheme?.starts(with: "comgooglemaps") ?? false {
                if app.canOpenURL(url) {
                    if #available(iOS 10.0, *) {
                        app.open(url, options: [:], completionHandler: nil)
                    } else {
                        // Fallback on earlier versions
                    }
                    decisionHandler(.cancel);
                    return
                }
                else {
                    let queryItems = URLComponents(string: url.absoluteString)?.queryItems
                    let ll = queryItems?.filter({$0.name == "center"}).first
                    let appleMapScheme : String = "http://maps.apple.com/?ll=\(ll?.value ?? "")";
                    let newUrl = NSURL(string: appleMapScheme)!;
                    if app.canOpenURL(newUrl as URL) {
                        if #available(iOS 10.0, *) {
                            app.open(newUrl as URL, options: [:], completionHandler: nil)
                        } else {
                            // Fallback on earlier versions
                        }
                        decisionHandler(.cancel);
                        return
                    }
                }
            }
            
            if url.scheme == "tel" || url.scheme == "mailto" {
                if app.canOpenURL(url){
                    if #available(iOS 10.0, *) {
                        app.open(url, options: [:], completionHandler: nil)
                    } else {
                        // Fallback on earlier versions
                    }
                    decisionHandler(.cancel);
                    return;
                }
                
                
            }
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView:WKWebView, didFinish navigation:WKNavigation!) {
        print("webview has finished loading");
        showActivityIndicator(show: false)
        let deviceInfo:String = Helper.generateDeviceIdentifier()
        print(deviceInfo);
        print(webView.url?.host)
        if(webView.url?.host == "shauryamuttreja.com") {
            return
        }
        
        openCamera();
        
        webView.evaluateJavaScript("_native.setName('Ios')", completionHandler: {(result,error) in
            if error == nil {
                print("no error")
            }
            else {
                print(" js execution error at ", error.debugDescription)
            }
        })
        
        webView.evaluateJavaScript("_native.setIosInfo('\(deviceInfo)')", completionHandler: {(result,error) in
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        let deepLink = appDelegate.deepLink
        let facebookLink = appDelegate.facebookLink;
        
        if(deepLink != nil) {
            
            webView.evaluateJavaScript("getDynamicLink('\(deepLink ?? "")')", completionHandler: {
                (result,error) in
                if error == nil {
                    print("passed link")
                }
                else {
                    print("js execution error for deep link :  ", error.debugDescription)
                }
            });
        }
        
        if(facebookLink != nil) {
            webView.evaluateJavaScript("parseFacebookDeeplink('\(facebookLink ?? "")')", completionHandler: {
                (result,error) in
                if error == nil {
                    print("passed link")
                }
                else {
                    print("js execution error for deep link :  ", error.debugDescription)
                }
            });
        }
        
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showActivityIndicator(show: false)
        showToast(controller: self, message: error.localizedDescription, seconds: 5)
    }
    
    func setFcmTokenToJsStorage(token:String){
        
        self.webView.evaluateJavaScript("_native.setFCMToken('\(token)')", completionHandler: {(result,error) in
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
            
            let alert = UIAlertController(title: "Message", message: "There’s a new version of OnDuty App available. Update now.", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Update", style: UIAlertAction.Style.default, handler: {( alert : UIAlertAction!) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open((URL(string: "itms-apps://itunes.apple.com/app/1441388774")!), options:[:], completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
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
                locationAlert(title: "Location Services Disabled",message:"Please turn on Location to use OnDuty");
            }
        }
        
        if message.name == "getContact" {
            callbackName = message.body as! String
            let contactPicker = CNContactPickerViewController();
            contactPicker.delegate = self;
            contactPicker.displayedPropertyKeys = [CNContactGivenNameKey,CNContactPhoneNumbersKey,CNContactEmailAddressesKey];
            
            self.present(contactPicker,animated: true,completion:nil);
            
        }
        if message.name == "logEvent" {
            
            AppEvents.logEvent(AppEvents.Name(message.body as! String))
        }
        
        if message.name == "firebaseAnalytics" {
            guard let body = message.body as? [String: Any] else { return }
            guard let name = body["name"] as? String else { return }
            guard let command = body["command"] as? String else { return }
            
            
            if command == "logFirebaseAnlyticsEvent" {
                guard let params = body["parameters"] as? [String: NSObject] else { return }
                Analytics.logEvent(name, parameters: params)
            }
            if command == "setFirebaseAnalyticsUserProperty" {
                guard let value = body["value"] as? String else { return }
                Analytics.setUserProperty(value, forName: name)
            }
            
            if command == "setFirebaseAnalyticsUserId" {
                guard let id = body["id"] as? String else { return }
                Analytics.setUserID(id)
            }
            if command == "setAnalyticsCollectionEnabled" {
                guard let bool = body["enable"] as? Bool else { return }
                Analytics.setAnalyticsCollectionEnabled(bool)
            }
            
            
        }
        
        
        if message.name == "share" {
            if let messageBody:NSDictionary = message.body as? NSDictionary {
                let shareText:String = messageBody["shareText"] as! String;
                
                
                let activtyViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil);
                activtyViewController.popoverPresentationController?.sourceView = self.view;
                activtyViewController.completionWithItemsHandler = { activity, success, items, error in
                    if !success{
                        print("cancelled")
                        return
                    }
                    var appName:String = activity?.rawValue ?? "";
                    if(activity == UIActivity.ActivityType.mail) {
                        appName = "mail"
                    }
                    
                    if(activity == UIActivity.ActivityType.message) {
                        appName = "message"
                        
                    }
                    if(activity == UIActivity.ActivityType.postToFacebook) {
                        appName = "facebook"
                        
                    }
                    if(activity == UIActivity.ActivityType.postToTwitter) {
                        appName = "twitter"
                    }
                    
                    if(activity == UIActivity.ActivityType.copyToPasteboard) {
                        appName = "copy"
                    }
                    
                    self.webView.evaluateJavaScript("linkSharedComponent('\(appName)')", completionHandler: nil)
                    
                }
                
                if let emailBody:NSDictionary = messageBody["email"] as? NSDictionary {
                    
                    activtyViewController.setValue(emailBody["subject"], forKey: "subject")
                }
                
                self.present(activtyViewController,animated: true,completion: nil);
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
    func locationAlert(title:String,message:String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Go To Settings", style: UIAlertAction.Style.default, handler: {( alert : UIAlertAction!) in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL, options:[:],completionHandler: nil)
            } else {
                // Fallback on earlier versions
            }
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


extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            print("No qr code detected")
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            //            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                //                launchApp(decodedURL: metadataObj.stringValue!)
                //                messageLabel.text = metadataObj.stringValue
                
                print(metadataObj.stringValue ?? "No value")
                if((metadataObj.stringValue?.starts(with: "https://")) != nil) {
//                    closeCamera()
                    let request:URLRequest;
                    
                    // Do any additional setup after loading the view, typically from a nib.
                    
                    if Reachability.isConnectedToNetwork() {
                        request = URLRequest(url:URL(string:metadataObj.stringValue!)!, cachePolicy:.reloadRevalidatingCacheData)
                        closeCamera()
                        webView.load(request)
                    }
                    
                }
                
            }
            
        }
    }
    
}
