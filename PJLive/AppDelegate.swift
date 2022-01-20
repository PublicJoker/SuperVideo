//
//  AppDelegate.swift
//  PJLive
//
//  Created by Tony-sg on 2019/4/12.
//  Copyright © 2019 Tony-sg. All rights reserved.

//

import UIKit
import Alamofire
import AdSupport

let KeyChain = "userId"

@UIApplicationMain
@objcMembers class AppDelegate: UIResponder, UIApplicationDelegate, BUAdSDKPrivacyProvider {
    public var keyChainUuid: String {
        var uuid: String? = KeychainManager.keyChainReadData(identifier: KeyChain) as? String
        
        if uuid == nil {
            uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
            // 存储数据
            let saveBool = KeychainManager.keyChainSaveData(data: uuid as Any, withIdentifier: KeyChain)
            if saveBool {
                print("存储成功:\(uuid!)")
            } else {
                print("存储失败")
            }
        }
        return uuid!
    }
    
    var launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]
    
    var appConfig: ConfigModel? = nil
    var window: UIWindow?

    var makeOrientation :UIInterfaceOrientation?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if UserDefaults.isFirstLaunchOfNewVersion() {//当前版本首次启动.重置标识位(升级APP)
            UserDefaults.setVersionChecked(flag: false)
            changeIcon()
        }
        
        self.requestServerConfig()
        
        BUAdSDKManager.setAppID("5208554")
        #if DEBUG
        BUAdSDKManager.setLoglevel(.debug)
        #endif
        
        /// Coppa 0 adult, 1 child
        if UserDefaults.isVersionChecked() {
            BUAdSDKManager.setCoppa(0)
        } else {
            BUAdSDKManager.setCoppa(1)
        }
        
        self.launchOptions = launchOptions ?? [:]
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = WelcomeViewController()
        window?.makeKeyAndVisible()
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeIcon), name: NSNotification.Name.init(rawValue: "isChecked"), object: nil)
        return true
    }

    func requestServerConfig() {
        NetWorkTools.requestData(type: .post, URLString: "http://cy.yinyinapp.cn/ios-config.json", parameters: nil) { (result) in
            guard let dataDic = result["data"] as? [String: NSObject] else { return }
            let config = ConfigModel(dict: dataDic)
            // 更新app全局配置
            self.appConfig = config
        }
    }
    
    open func supportedInterfaceOrientations(for window: UIWindow?) -> UIInterfaceOrientationMask{
        return .allButUpsideDown//支持倒立除外的其他方向
    }
    
    var blockRotation: UIInterfaceOrientationMask = .portrait{
        didSet{
            if blockRotation.contains(.portrait){
                //强制设置成竖屏
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }else{
                //强制设置成横屏
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
        }
    }
}

//extension AppDelegate {
//    func signForContent(_ content: String) -> String {
//        let charArray = content.cString(using: .utf8)!
//        let length = charArray.count
//        let pointer = UnsafeMutablePointer<Int8>.allocate(capacity: length)
//        for i in 0..<length
//        {
//            pointer[i]=charArray[i]
//        }
//        let signResultChar = sign(pointer)!
//        return String(cString: signResultChar, encoding: .utf8) ?? ""
//    }
//}

//MARK:--推送代理
extension AppDelegate : JPUSHRegisterDelegate {
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification!) {
        let userInfo = notification.request.content.userInfo
        
        //从通知界面直接进入应用
        if notification.request.trigger is UNPushNotificationTrigger {
            JPUSHService.handleRemoteNotification(userInfo)
        } else {//从通知设置界面进入应用
            
        }
    }
    
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable : Any]!) {
        
    }
    
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!, withCompletionHandler completionHandler: ((Int) -> Void)!) {

        let userInfo = notification.request.content.userInfo
        if notification.request.trigger is UNPushNotificationTrigger {
            JPUSHService.handleRemoteNotification(userInfo)
        }
        // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue | UNNotificationPresentationOptions.sound.rawValue))
    }

    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if response.notification.request.trigger is UNPushNotificationTrigger {
            JPUSHService.handleRemoteNotification(userInfo)
            handleMsg(userInfo)
        }
        
        // 系统要求执行这个方法
        completionHandler()
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Required, iOS 7 Support
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // 系统获取Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 在极光平台注册deviceToken
        JPUSHService.registerDeviceToken(deviceToken)
    }

    // 获取token 失败
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { //可选
    }
    
    func handleMsg(_ userInfo: [AnyHashable : Any]!) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if UserDefaults.isVersionChecked() && UserDefaults.isShowNewFeature() == false {
            window?.rootViewController = WelcomeViewController()
            window?.makeKeyAndVisible()
        }
    }
    
    @objc func changeIcon() {
        if #available(iOS 10.3, *) {
            guard UIApplication.shared.supportsAlternateIcons else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if UserDefaults.isVersionChecked() {
                    UIApplication.shared.setAlternateIconName("2021") { error in
                        print(error?.localizedDescription ?? "")
                    }
                    // 进入后台
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                } else {
                    UIApplication.shared.setAlternateIconName(nil) { error in
                        print(error?.localizedDescription ?? "")
                    }
                }
            }
        }
    }
}
