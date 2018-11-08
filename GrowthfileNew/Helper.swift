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
        
        if let receivedData = KeyChainService.load(key: "MyNumber") {
            let result = receivedData.to(type: Int.self)
            let stringResult:String =  String(result);
            let concat :String = stringResult+"&"+brand+"&"+model+"&"+systemName
            return concat
        }
        else {
            
            let uuid: String = KeyChainService.createUniqueID()
            let data = Data(from: uuid)
            let status = KeyChainService.save(key: "MyNumber", data: data)
            print("status: ", status)
            print("data : " , data)
            print("uuid: " , uuid)
            let concat:String = uuid+"&"+brand+"&"+model+"&"+systemName
            return concat
        }
    }
    static func convertImageDataToBase64(image:UIImage) -> Any {
        let imgData:NSData  = image.pngData()! as NSData
        let imageBase64 = imgData.base64EncodedString(options: [])
        

        return imageBase64
    }
   
}
