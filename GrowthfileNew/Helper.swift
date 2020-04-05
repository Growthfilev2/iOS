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
            
            switch CLLocationManager.authorizationStatus() {
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
        let appVersion = "10"
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
        let size = image.size;
     
        let maxWidth = deviceWidth();
        let maxHeight = deviceHeight();
        let widthRatio = maxWidth / size.width;
        let heightRatio = maxHeight / size.height;
        let newSize:CGSize;
        var outWidth = size.width;
        var outHeight = size.height;
        if(size.width > size.height) {
            if(size.width > maxWidth) {
                outWidth = maxWidth;
                outHeight = (outHeight * maxWidth) / size.width
            }
        }
        else {
            if(size.height > maxHeight) {
                outHeight = maxHeight;
                outWidth = (outWidth * maxHeight) / size.height
            }
        }
        newSize = CGSize(width: outWidth, height: outHeight)
        let rect = CGRect(x:0,y:0,width: newSize.width,height:newSize.height);
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
      
        return newImage!
      

    }
}
