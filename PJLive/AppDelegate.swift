//
//  AppDelegate.swift
//  PJLive
//
//  Created by Tony-sg on 2019/4/12.
//  Copyright © 2019 Tony-sg. All rights reserved.

//

import UIKit
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var makeOrientation :UIInterfaceOrientation?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //1. 设置 Tabbar 的 tintColor
        UITabBar.appearance().tintColor = .purple
        
        // 三方SDK初始化
        PlatformConfig.shared.init3rdSDK(application: application, launchOptions: launchOptions)
        
        
        ApiMoya.apiMoyaRequest(target: ApiMoya.getAppVersion(appId: "1581815639")) { json in
            let model = AppVersion.deserialize(from: json.rawString())
            //线上版本
            let appStoreVersion = model?.results.first?.version.toDouble() ?? 0.0
            //当前版本号
            let currentVersion = UserDefaults.currentVersionNum().toDouble()
            
            let checked = currentVersion <= appStoreVersion
            self.showLive(checked)//当前版本已上线
        } failure: { error in
            self.showLive(false)
        }
        return true
    }
    
    func showLive(_ checked: Bool) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = checked ? MainViewController() : BaseTableViewController()
        window?.makeKeyAndVisible()
        
        if checked {//更换图标
            changeIcon()
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
    
    func changeIcon() {
        if #available(iOS 10.3, *) {
            guard UIApplication.shared.supportsAlternateIcons else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIApplication.shared.setAlternateIconName("2021") { error in
                    print(error?.localizedDescription ?? "")
                }
            }
        }
    }
}

extension AppDelegate {
    func signForContent(_ content: String) -> String {
        let charArray = content.cString(using: .utf8)!
        let length = charArray.count
        let pointer = UnsafeMutablePointer<Int8>.allocate(capacity: length)
        for i in 0..<length
        {
            pointer[i]=charArray[i]
        }
        let signResultChar = sign(pointer)!
        return String(cString: signResultChar, encoding: .utf8) ?? ""
    }
}

//MARK:--推送代理
extension AppDelegate : JPUSHRegisterDelegate {
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification!) {
        
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
    
}
