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
class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler,UIImagePickerControllerDelegate,UINavigationControllerDelegate  {
    
  
    
    @IBOutlet  var webView: WKWebView!

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
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,((info[UIImagePickerController.InfoKey.originalImage] as? UIImage) != nil)  {
            
            let base64Image = Helper.convertImageDataToBase64(image:pickedImage)
           
            let setFilePath = "setFilePath('\(base64Image)')"
            
            webView.evaluateJavaScript(setFilePath) {(result,error) in
                if error == nil {
                    print ("success in sending base64 image to js")
                }
                else {
                    print("error in sending base64 image to js" , error)
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
        configuration.userContentController = userContentController
        
       
        
        self.view.addSubview(webView)
        self.view.sendSubviewToBack(webView)

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        
        view = webView
    }
    
    @objc func startPullToRef(refresh:UIRefreshControl){
        
        webView.evaluateJavaScript("requestCreator('Null','false')",completionHandler: {(result,error) in
            if error == nil {
                self.refreshController.endRefreshing()
            }
            else {
                print(error)
            }
        })
}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view will load")
        let request:URLRequest;
        // Do any additional setup after loading the view, typically from a nib.
        if Reachability.isConnectedToNetwork() {
          request = URLRequest(url:URL(string:"https://growthfile-207204.firebaseapp.com")!)
            print("network avaiable")
        }
        else {
            request = URLRequest(url:URL(string:"https://growthfile-207204.firebaseapp.com")!, cachePolicy:.returnCacheDataElseLoad)
            print("network not available")
        }
       
        
        NotificationCenter.default.addObserver(self, selector:#selector(callReadInJs), name: UIApplication.didBecomeActiveNotification, object: nil)
      
        NotificationCenter.default.addObserver(self, selector:#selector(retrieveUpdatedTokenFromNotificationDict(_:)), name: NSNotification.Name(rawValue:"RefreshedToken" ),object:nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(callReadInJs), name: NSNotification.Name(rawValue: "fcmMessageReceived"), object: nil)

        
        webView.navigationDelegate = self
        webView.load(request)

    }
    
    
    @objc func callReadInJs(){
        print("view become active from controller")
         webView.evaluateJavaScript("runRead()", completionHandler: nil)
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
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error : Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView:WKWebView, didStartProvisionalNavigation navigation :WKNavigation!) {
        print("Start to load")
    }
    
    
    func webView(_ webView:WKWebView, didFinish navigation:WKNavigation!) {
        print("webview has finished loading")
        let deviceInfo:String = Helper.generateDeviceIdentifier()
        print(deviceInfo)
       
        webView.evaluateJavaScript("native.setName('Ios')", completionHandler: nil);
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
       
        refreshController.bounds = CGRect.init(x: 0.0, y: 50.0, width: refreshController.bounds.size.width, height: refreshController.bounds.size.height)
        refreshController.addTarget(self, action: #selector(self.startPullToRef(refresh:)), for: .valueChanged)
        refreshController.attributedTitle = NSAttributedString(string: "Loading")
        webView.scrollView.addSubview(refreshController)
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
