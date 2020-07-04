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
    
    func uploadImage(imageRef:String, imageData: Data, completion: @escaping (Bool)->()){
        let uploadref = storageRef.child(imageRef)
        
        uploadref.putData(imageData, metadata: nil) { (metaData, error) in
            if let error = error{
                print(error)
                return
            }
            cloudFunctionManager.sharedInstance.functions.httpsCallable("filterOffensiveImages").call(["imageRef": imageRef]) { (result, error) in
                     if let error = error as NSError? {
                       if error.domain == FunctionsErrorDomain {
                         let code = FunctionsErrorCode(rawValue: error.code)
                         let message = error.localizedDescription
                         let details = error.userInfo[FunctionsErrorDetailsKey]
                       }
                       // ...
                     }
                     if let isClean = result?.data as? Bool {
                        if isClean{
                            completion(true)
                        }else{
                            self.deleteImage(imageRef: imageRef)
                            completion(false)
                        }
                     }
                   }
        }
       
    }
    
    func deleteImage(imageRef:String){
        
    }
    
    func getDownloadURL(imageRef:String, completion: @escaping (URL)->()){
        storageRef.child(imageRef).downloadURL { (url, error) in
            if let error = error{
                print(error)
                return
            }
            if let aurl = url{
                completion(aurl)
            }
            
        }
    }

}
