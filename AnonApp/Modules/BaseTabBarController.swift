//
//  BaseTabBarController.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/22/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class BaseTabBarController: UITabBarController {
    
    private var DatabaseUrl:String="https://quippet-2213.firebaseio.com/"
    var userID:String?
    private var discoverVC:ViewControllerDiscover?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
       
        
       
       
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
