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
    
    private var DatabaseUrl:String="https://quippet-2213.firebaseio.com/"
    var userID:String?
    private weak var discoverVC:ViewControllerDiscover?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        self.delegate = self
        
       
       
        
    }
    
 
    
   
    
    //initializes database reference
    func refDatabaseFirebase()->DatabaseReference{
       
       let ref = Database.database().reference(fromURL: DatabaseUrl)
        
        return ref
      }
    func refDatabaseFirestore()->Firestore{
        let db = Firestore.firestore()
        return db
    }
    func refStorage()->StorageReference{
        let storageRef = Storage.storage().reference()
        return storageRef
    }
    
    func authorizeUser(){
        
        Auth.auth().signInAnonymously() { (authResult, error) in
          // ...
         guard let user = authResult?.user else { return }
             self.userID = user.uid
            
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
