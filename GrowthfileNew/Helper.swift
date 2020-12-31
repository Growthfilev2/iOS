//
//  Helper.swift
//  GrowthfileNew
//
//  Created by Puja Capital on 04/11/18.
//  Copyright © 2018 Puja Capital. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class Helper{
    
    
    
    
    static func checkLocationServiceState() -> Bool {
        
        if CLLocationManager.locationServicesEnabled() {
            let manager = CLLocationManager()
           
            switch manager.authorizationStatus {
            case .notDetermined :
                return true
            case .restricted , .denied:
                return false
            case .authorizedWhenInUse:
                return true
            case .authorizedAlways:
                return true
            default:
                return false
            }
        }
        else {
            return false
        }
    }
    
  
    static func generateDeviceIdentifier() -> String {
        let systemName = UIDevice.current.systemName
        let model = UIDevice.current.model
        let brand : String = "apple"
        let baseOs = "ios"
        let appVersion = "12"
        let commonString =  "baseOs="+baseOs+"&deviceBrand="+brand+"&deviceModel="+model+"&appVersion="+appVersion+"&osVersion="+systemName;
        
        if let receivedData = KeyChainService.load(key: "growthfileNewKey") {
            let result = receivedData.to(type: Int.self)
            let stringResult:String =  String(result);
            return commonString+"&id="+stringResult
        }
        else {
            let uuid: String = KeyChainService.createUniqueID()
            let data = Data(from: uuid)
            KeyChainService.save(key: "growthfileNewKey", data: data)
            return commonString+"&id="+uuid;
        }
    }
    
    static func convertImageDataToBase64(image:UIImage) -> Any {
        let resizedImage:UIImage = resizeImage(image: image);
        guard let imageData = resizedImage.jpegData(compressionQuality:0.5) else {
            return ""
        }
        return imageData.base64EncodedString()
        
    }
    static func deviceWidth() -> CGFloat {
        return UIScreen.main.bounds.width;
    }
    static func deviceHeight() -> CGFloat {
        return UIScreen.main.bounds.height;
    }
    
    static func resizeImage(image:UIImage) -> UIImage {
        
        let newSize:CGSize
        let (newWidth,newHeight) = calculateAspectRation(image: image)
        
        newSize = CGSize(width: newWidth, height: newHeight)
        let rect = CGRect(x:0,y:0,width: newSize.width,height:newSize.height);
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    static func calculateAspectRation(image:UIImage) -> (Float,Float) {
        let srcWidth = image.size.width
        let srcHeight = image.size.height
        
        let maxWidth = deviceWidth()
        let maxHeight = deviceHeight()
        let ratio = min(maxWidth/srcWidth, maxHeight/srcHeight)
        
        let calcWidth = Float(srcWidth*ratio)
        let calHeight = Float(srcHeight*ratio)
        return (calcWidth,calHeight)
    }
}
