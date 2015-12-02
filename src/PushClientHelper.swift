//
//  PushClientHelper.swift
//  PushClient
//
//  Copyright (c) 2015 DU DA Group. All rights reserved.

import Foundation
import UIKit


public typealias PushCallbackHandler = ([NSObject : AnyObject], Bool) -> Void

public class PushClientHelper {
    
    private static var callbackHandlers: [PushCallbackHandler] = []

    public class var mustRegisterUserNotificationSettings: Bool {
        get {
            let app = UIApplication.sharedApplication()
            return app.respondsToSelector("registerUserNotificationSettings:")
        }
    }
    
    @available(iOS 8.0, *)
    public class func registerUserNotificationSettings(types: UIUserNotificationType = [.Alert, .Badge, .Sound],
                                                       categories: Set<UIUserNotificationCategory>? = nil) {
        let app = UIApplication.sharedApplication()
        let settings = UIUserNotificationSettings(forTypes: types, categories: categories)
        
        app.registerUserNotificationSettings(settings)
        app.registerForRemoteNotifications()
    }
    
    public class func registerForRemoteNotificationTypes(types: UIRemoteNotificationType = [.Alert, .Badge, .Sound]) {
        let app = UIApplication.sharedApplication()
        app.registerForRemoteNotificationTypes(types)
    }
    
    public class func addCallbackHandler(callbackHandler: PushCallbackHandler) {
        callbackHandlers.append(callbackHandler)
    }
    
    public class func handleLaunchNotification(launchOptions: [NSObject : AnyObject]?) {
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
            for callbackHandler in callbackHandlers {
                callbackHandler(userInfo, true)
            }
        }
    }
    
    public class func receivedRemoteNotification(userInfo: [NSObject : AnyObject]) {
        let app = UIApplication.sharedApplication()
        let fromBackground: Bool = app.applicationState != .Active
        
        for callbackHandler in callbackHandlers {
            callbackHandler(userInfo, fromBackground)
        }
    }
}