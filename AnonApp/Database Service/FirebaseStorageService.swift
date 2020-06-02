//
//  FirebaseStorageService.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/29/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class FirebaseStorageService: NSObject {
    
   
     let storageRef = Storage.storage().reference()
     static let sharedInstance = FirebaseStorageService()
    
    func uploadImage(imageRef:String, imageData: Data){
        let uploadref = storageRef.child(imageRef)
        
        uploadref.putData(imageData)
    }

}
