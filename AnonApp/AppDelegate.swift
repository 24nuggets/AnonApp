//
//  AppDelegate.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/5/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
       
        if let webURL = userActivity.webpageURL{
            if handlePasswordlessSignIn(withURL: webURL) {
                     return true
                   }
      let handled = DynamicLinks.dynamicLinks().handleUniversalLink(webURL) {[weak self] (dynamiclink, error) in
        guard error == nil else {
            print(error?.localizedDescription ?? "error")
            return
        }
        if let dynamiclink = dynamiclink{
            self?.handleDynamicLink(dynamicLink: dynamiclink)
        }
        // ...
      }
            
      return handled
        }
        return false
    }
    
    func handleDynamicLink(dynamicLink:DynamicLink){
        
        guard let url = dynamicLink.url else{
            print("no url paramter")
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {return}
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        guard let initialVC = window?.rootViewController as? BaseTabBarController else {
          return
        }
     //  let initialVC = storyBoard.instantiateViewController(withIdentifier: "BaseTabBarController") as! BaseTabBarController
    //    self.window?.rootViewController = initialVC
     //   self.window?.makeKeyAndVisible()
       // let tabVC = initialVC.tabBarController as! BaseTabBarController
        initialVC.authorizeUser { (uid) in
            var eventName:String?
            var parentEventKey:String?
            var eventId:String?
            var feedViewController:ViewControllerFeed?
            for queryItem in queryItems{
               
                
                if queryItem.name == "quipid"{
                    guard let quipid = queryItem.value else {return}
                    FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: uid, aKey: eventId!) { (likesDislikes) in
                        
                    
                    FirestoreService.sharedInstance.getQuip(quipID: quipid) { (quip) in
                        FirebaseService.sharedInstance.getQuipScore(aQuip: quip) { (aquip) in
                            //  self?.window = UIWindow(frame: UIScreen.main.bounds)
                                            //  self?.window?.rootViewController = tabVC
                                           
                                              
                                             let quipViewController = storyBoard.instantiateViewController(withIdentifier: "ViewControllerQuip") as! ViewControllerQuip
                                              quipViewController.myQuip = quip
                                              quipViewController.currentTime = Date().timeIntervalSince1970 * 1000
                                              quipViewController.uid = uid
                            if likesDislikes[quipid] == 1 {
                                quipViewController.quipLikeStatus = true
                            }else if likesDislikes[quipid]  == -1{
                                quipViewController.quipLikeStatus = false
                            }
                            if let score = aquip.quipScore{
                            quipViewController.quipScore = String(score)
                             //   guard let viewControllers = initialVC.viewControllers,
                              //  let listIndex = viewControllers.firstIndex(where: { $0 is HomeNavigationController }),
                          //  let navVC = viewControllers[listIndex] as? HomeNavigationController else { return }
                               // navVC.popToRootViewController(animated: false)
                              //  initialVC.selectedIndex = listIndex
                                let navVC = feedViewController?.navigationController
                                    quipViewController.parentViewFeed = feedViewController
                                  //  feedViewController?.definesPresentationContext = true
                                navVC?.pushViewController(quipViewController, animated: true)
                                    
                            }
                        }
                    }
                    }
                }else if queryItem.name == "eventid" {
                    eventId = queryItem.value
                    
                    FirestoreService.sharedInstance.checkIfEventIsOpen(eventID: eventId!) { (isOpen) in
                        feedViewController = storyBoard.instantiateViewController(withIdentifier: "ViewControllerFeed") as? ViewControllerFeed
                        feedViewController?.isOpen = isOpen
                        if let eventName = eventName {
                            let myChannel = Channel(name: eventName, akey: eventId!, aparent: nil, aparentkey: parentEventKey, apriority: nil, astartDate: nil, aendDate: nil)
                            feedViewController?.myChannel = myChannel
                            feedViewController?.uid = uid
                            let listIndex = 0
                            guard let viewControllers = initialVC.viewControllers,
                            let navVC = viewControllers[listIndex] as? UINavigationController else { return }
                             
                           navVC.popToRootViewController(animated: false)
                           initialVC.selectedIndex = listIndex
                                if let feedViewController = feedViewController{
                                  //  navVC.definesPresentationContext = true
                                navVC.pushViewController(feedViewController, animated: true)
                                }
                                
                            
                        }
                    }
                    
                }else if  queryItem.name == "eventname" {
                    eventName = queryItem.value?.decodeUrl()
                    
                }else if queryItem.name == "parenteventid"{
                    parentEventKey = queryItem.value
                }
            }
        }
        
        
        
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
        handleDynamicLink(dynamicLink: dynamicLink)
        // Handle the deep link. For example, show the deep-linked content or
        // apply a promotional offer to the user's account.
        // ...
        return true
      }
      return false
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if handlePasswordlessSignIn(withURL: url) {
          return true
        }
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
        handleDynamicLink(dynamicLink: dynamicLink)
        // Handle the deep link. For example, show the deep-linked content or
        // apply a promotional offer to the user's account.
        // ...
        return true
      }
      return false
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
       Database.database().isPersistenceEnabled=false
        Giphy.configure(apiKey: "5Wj0tBPL6cAW7zUJenU6lF0TG7febmp1")
        
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }
       

        application.registerForRemoteNotifications()
       Messaging.messaging().delegate = self
        
        if !isAppAlreadyLaunchedOnce() {
            displayLicenAgreement()
        }
        if #available(iOS 13.0, *) {
           // if UITraitCollection.current.userInterfaceStyle == .light{
            //    UINavigationBar.appearance().barTintColor = UIColor(hexString: "ffaf46")
           //      UITabBar.appearance().barTintColor = .secondarySystemBackground
            //    UITableViewCell.appearance().backgroundColor = .systemBackground
           //      UITableView.appearance().backgroundColor = .systemBackground
            //     UICollectionViewCell.appearance().backgroundColor = .systemBackground
            //    UICollectionView.appearance().backgroundColor = .systemBackground
            //     }else{
              //       UINavigationBar.appearance().barTintColor = UIColor(hexString: "1C150A")
             //   UITabBar.appearance().barTintColor = UIColor(hexString: "1C150A")
               UITableViewCell.appearance().backgroundColor = darktint
                UITableView.appearance().backgroundColor = darktint
                UICollectionViewCell.appearance().backgroundColor = darktint
               UICollectionView.appearance().backgroundColor = darktint
            //     }
          
             } else {
                 // Fallback on earlier versions
     //  UINavigationBar.appearance().barTintColor = UIColor(hexString: "ffaf46")
             }
        return true
    }
    func isAppAlreadyLaunchedOnce()->Bool{
        let defaults = UserDefaults.standard

        if let isAppAlreadyLaunchedOnce = defaults.string(forKey: "isAppAlreadyLaunchedOnce"){
            print("App already launched : \(isAppAlreadyLaunchedOnce)")
            return true
        }else{
            defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
            print("App launched first time")
            return false
        }
    }
    func displayMsgBoxEmailLink(email:String){
          let title = "Email Link Successful"
          let message = "\(email) has been successfully linked to your account."
          let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                switch action.style{
                case .default:
                      print("default")
                 
                      
                case .cancel:
                      print("cancel")

                case .destructive:
                      print("destructive")


                @unknown default:
                  print("unknown action")
              }}))
            let root = window?.rootViewController as? BaseTabBarController
                let navContoller = root?.viewControllers?[0] as? UINavigationController
                let firstController = navContoller?.viewControllers[0]
                DispatchQueue.main.async {
                firstController?.present(alert, animated: true, completion: nil)
                }
      }
    
    func displayLicenAgreement(){
        let message = "We use Apple's Standard End User License Agreement and to use this app you must agree to the terms outlined in the EULA."
        //create alert
        let alert = UIAlertController(title: "License Agreement", message: message, preferredStyle: .alert)
         let defaults = UserDefaults.standard
        //create Decline button
        let declineAction = UIAlertAction(title: "Decline" , style: .destructive){ (action) -> Void in
            //DECLINE LOGIC GOES HERE
            self.displayLicenAgreement()
            
            defaults.set(false, forKey: "isAppAlreadyLaunchedOnce")
        }
        
        //create Accept button
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { (action) -> Void in
            //ACCEPT LOGIC GOES HERE
            defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
        }
        
        //add task to tableview buttons
        alert.addAction(declineAction)
        alert.addAction(acceptAction)
        
        let root = window?.rootViewController as? BaseTabBarController
        let navContoller = root?.viewControllers?[0] as? UINavigationController
        let firstController = navContoller?.viewControllers[0]
        DispatchQueue.main.async {
        firstController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func handlePasswordlessSignIn(withURL url: URL) -> Bool {
      let link = url.absoluteString
      // [START is_signin_link]
      if Auth.auth().isSignIn(withEmailLink: link) {
        // [END is_signin_link]
        UserDefaults.standard.set(link, forKey: "Link")
        guard let email = UserDefaults.standard.string(forKey: "Email") else {return true}
        guard let uid = UserDefaults.standard.string(forKey: "UID") else { return true }
        UserDefaults.standard.set(email, forKey: "EmailConfirmed")
        FirestoreService.sharedInstance.linkEmail(uid: uid, email: email) {
            
        }
        let root = window?.rootViewController as? UITabBarController
        (root?.viewControllers?[0] as? UINavigationController)?.popToRootViewController(animated: false)
        (root?.viewControllers?[1] as? UINavigationController)?.popToRootViewController(animated: false)
        //window?.rootViewController?.children[0].performSegue(withIdentifier: "passwordless", sender: nil)
        var components = email.components(separatedBy: "@")
        let school = components[1]
        Analytics.setUserProperty(school, forName: "School")
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
        AnalyticsParameterItemID: school,
        AnalyticsParameterItemName: "School",
        AnalyticsParameterContentType: "cont"
        ])
        displayMsgBoxEmailLink(email: email)
        return true
      }
      return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
       
    
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
   
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {

        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                //  self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
            }
        }

        print(userInfo)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
      print("Firebase registration token: \(fcmToken)")

      let dataDict:[String: String] = ["token": fcmToken]
      NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
  
}

