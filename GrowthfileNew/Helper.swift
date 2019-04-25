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
        let appVersion = "5"
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
        let imgData:NSData  = image.jpegData(compressionQuality: 0.1)! as NSData
        let imageBase64 = imgData.base64EncodedString(options:[])
        return imageBase64
    }
}
