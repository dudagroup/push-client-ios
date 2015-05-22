//
//  PushClient.swift
//  PushClient
//
//  Copyright (c) 2015 DU DA Group. All rights reserved.

import Foundation
import UIKit


private func hexadecimalStringFromData(data: NSData) -> String {
    if data.length == 0 {
        return String()
    }
    
    var hexString = ""
    
    data.enumerateByteRangesUsingBlock { (bytes, range, stop) -> Void in
        let unsignedCharBytes = UnsafePointer<CUnsignedChar>(bytes)
        
        for i in 0...range.length - 1 {
            hexString += String(format: "%02lx", unsignedCharBytes[i])
        }
    }
    
    return hexString
}

@objc public class PushClient: NSObject {

    private let pushServerUrl: NSURL

    public init(pushServerUrl: NSURL) {
        self.pushServerUrl = pushServerUrl;
    }
    
    public func subscribe(token: NSData, domain: String, customData: [NSObject : AnyObject]?) {
        let request = NSMutableURLRequest(URL: self.pushServerUrl.URLByAppendingPathComponent("api/subscribe/"))

        #if DEBUG
        let platform = "apnsSandbox"
        let developmentDevice = true
        #else
        let platform = "apns"
        let developmentDevice = false
        #endif
        
        let currentDevice = UIDevice.currentDevice()
        let mainBundle = NSBundle.mainBundle()
        
        var error: NSError?
        var body: [NSObject : AnyObject] = [
            "token": hexadecimalStringFromData(token),
            "domain": domain,
            "platform": platform,
            "name": currentDevice.name,
            "deviceType": currentDevice.model,
            "osVersion": currentDevice.systemVersion,
            "developmentDevice": developmentDevice
        ]
        
        if let appId = mainBundle.infoDictionary?["CFBundleIdentifier"] as? NSString {
            body["appId"] = appId
        }
        
        if let appVersion = mainBundle.infoDictionary?["CFBundleShortVersionString"] as? NSString,
               buildVersion = mainBundle.infoDictionary?["CFBundleVersion"] as? NSString {
               
            body["appVersion"] = String(format: "%@ (%@)", appVersion, buildVersion)
        }
        
        if let customData = customData {
            body["custom"] = customData
        }
        
        let jsonDataBody = NSJSONSerialization.dataWithJSONObject(body, options: nil, error: &error)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.HTTPMethod = "POST"
        request.HTTPBody = jsonDataBody
    
        let session = NSURLSession.sharedSession()
        let taks = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            if error != nil {
                NSLog("PushServer Request Error: %@", error)
            }
            
            if let response = response as? NSHTTPURLResponse {
                if response.statusCode != 200 {
                    let responseObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    
                    if let responseObject = responseObject as? NSObject {
                        NSLog("PushServer Request Error: %@", responseObject)
                    } else {
                        NSLog("Unknown PushServer Error")
                    }
                }
            }
        }
        
        taks.resume()
    }
}