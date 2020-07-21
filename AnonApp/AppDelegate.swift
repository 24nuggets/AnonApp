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
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let webURL = userActivity.webpageURL{
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
       let tabVC = storyBoard.instantiateViewController(withIdentifier: "BaseTabBarController") as! BaseTabBarController
        self.window?.rootViewController = tabVC
        self.window?.makeKeyAndVisible()
        tabVC.authorizeUser { (uid) in
            var eventName:String?
            var parentEventKey:String?
            var eventId:String?
            var feedViewController:ViewControllerFeed?
            for queryItem in queryItems{
               
                
                if queryItem.name == "quipid"{
                    guard let quipid = queryItem.value else {return}
                    FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: uid, aKey: eventId!) { (likesDislikes) in
                        
                    
                    FirestoreService.sharedInstance.getQuip(quipID: quipid) {[weak self] (quip) in
                        FirebaseService.sharedInstance.getQuipScore(aQuip: quip) { (aquip) in
                              self?.window = UIWindow(frame: UIScreen.main.bounds)
                                            //  self?.window?.rootViewController = tabVC
                                             //
                                              
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
                                if let navVC = feedViewController?.navigationController  {
                                    quipViewController.parentViewFeed = feedViewController
                                  //  feedViewController?.definesPresentationContext = true
                                        navVC.pushViewController(quipViewController, animated: true)
                                              }
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
                            if let navVC = tabVC.viewControllers?[0] as? UINavigationController{
                                if let feedViewController = feedViewController{
                                 //   navVC.definesPresentationContext = true
                                navVC.pushViewController(feedViewController, animated: true)
                                }
                                
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
        Giphy.configure(apiKey: "OtEKKo9ALte4EFRcelOCh5QH4b8iMfji", verificationMode: true)
        
        return true
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
        
 
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
   


}

