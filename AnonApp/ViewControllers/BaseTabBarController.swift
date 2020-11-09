//
//  BaseTabBarController.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/22/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class BaseTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    
    var userID:String?
  

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        self.delegate = self
        
        authorizeUser { (uid) in
            
        }
       
        
    }
    
    
    
 
    
   
    
 
    
    func authorizeUser(completion: @escaping (String)->()){
        if Core.shared.isKeyPresentInUserDefaults(key: "UID"){
            if let uid = UserDefaults.standard.string(forKey: "UID"){
                FirestoreService.sharedInstance.getHiddenPosts(uid: uid) { (ahiddenPosts) in
                    hiddenPosts =  ahiddenPosts
                }
                
            FirestoreService.sharedInstance.getBlockedUsers(uid: uid) { (myblockedUsers) in
                blockedUsers = myblockedUsers
            }
                completion(uid)
            }
            
        }else{
        
        Auth.auth().signInAnonymously() {[weak self] (authResult, error) in
          // ...
         guard let user = authResult?.user else { return }
            self?.userID = user.uid
            let topVC = (self?.viewControllers?[0] as? UINavigationController)?.topViewController as? ViewControllerFeed
            topVC?.uid = user.uid
            topVC?.collectionView.reloadData()
            UserDefaults.standard.set(user.uid, forKey: "UID")
            FirestoreService.sharedInstance.getBlockedUsers(uid: user.uid) { (myblockedUsers) in
                blockedUsers = myblockedUsers
            }
            completion(user.uid)
        }
        }
       
    }
    
    func getUID()->String{
         return self.userID ?? "defaultUser"
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
      
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
      
    }
   

}
