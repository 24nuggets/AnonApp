//
//  ViewControllerWriteQuip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/21/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerWriteQuip: UIViewController, UITextViewDelegate {
    
    var ref:DatabaseReference?
    var db:Firestore?
    var myChannel:Channel?
    private var feedVC:ViewControllerFeed?
    var uid:String?
    private var childUpdates:[String:Any]=[:]
 
    @IBOutlet weak var textView: UITextView!
    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        textView.textColor = UIColor.lightGray
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
    }
    
    
    
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //when user presses send
        if (text == "\n" && textView.text != "Whats Happening") {
            saveQuip()
            
        }
        
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {

            textView.text = "Whats Happening"
            textView.textColor = UIColor.lightGray

            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }

        // Else if the text view's placeholder is showing and the
        // length of the replacement string is greater than 0, set
        // the text color to black then set its text to the
        // replacement string
         else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text
            
        }

        // For every other case, the text should change with the usual
        // behavior...
        else {
            //max 140 characters
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            let numberOfChars = newText.count
            return numberOfChars < 140
        }

        // ...otherwise return false since the updates have already
        // been made
        return false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
    
    func saveQuip(){
        guard let key = ref?.child("posts").childByAutoId().key else { return }
              
       var post2:[String:Any]=[:]
         var post3:[String:Any]=[:]
         var post4:[String:Any]=[:]
          
       
        
        let post1 = ["s": 0,
                          "r":0] as [String : Any]
        
        post3 = ["a": uid ?? "Other",
                    "t": textView.text,
                    "d": FieldValue.serverTimestamp()]
        
        post4 = ["c": myChannel?.channelName ?? "Other",
                                    "t": textView.text,
                                    "d": FieldValue.serverTimestamp()]
       
        if myChannel!.parent != nil {
            
             post2 = [   "t": textView.text,
                         "k": myChannel?.key ?? "Other",
                         "c": myChannel?.channelName ?? "Other",
                         "pk": myChannel!.parentKey!,
                         "p": myChannel?.parent ?? "Other",
                          "a": uid ?? "Other",
                          "d": FieldValue.serverTimestamp()]
            
        
                childUpdates = ["/A/\(myChannel!.key ?? "Other")/Q/\(key)":post1,
                "/M/\(uid ?? "defaultUser")/q/\(key)":post1,
                "/A/\(myChannel!.parentKey ?? "Other")/Q/\(key)":post1  ] as [String : Any]
            
        }
        else{
             post2 = [        "t": textView.text,
                              "c": myChannel?.channelName ?? "Other",
                              "k": myChannel?.key ?? "Other",
                              "a": uid ?? "Other",
                              "d": FieldValue.serverTimestamp()]
            
       
          
            childUpdates = ["/A/\(myChannel!.key ?? "Other")/Q/\(key)":post1,
                                "/M/\(uid ?? "defaultUser")/q/\(key)":post1] as [String : Any]
            
         
        }
        
        queryRecentChannelQuips(data: post3, key: key,post4: post4, post2: post2)
        
       
        
          
        
        
    }
    func queryRecentChannelQuips(data:[String:Any], key:String, post4:[String:Any], post2:[String:Any]){
         let mydata = data
        let recentQuipsRef = self.db?.collection("Channels/\(self.myChannel?.key ?? "Other")/RecentQuips")
                  
        recentQuipsRef?.order(by: "t", descending: true).limit(to: 2).getDocuments(){ (querySnapshot, err) in
                       if err != nil {
                           return
                       }
                       
            self.db?.runTransaction({ (transaction, errorPointer) -> Any? in
                        let sfDocument: DocumentSnapshot
                  do {
                       try sfDocument = transaction.getDocument((querySnapshot?.documents[0].reference)!)
                   } catch let fetchError as NSError {
                       errorPointer?.pointee = fetchError
                       return nil
                   }
                            
                        
                               if querySnapshot?.isEmpty ?? true ||
                                   querySnapshot?.documents[1].data()["n"] as! Double >= 4{
                               
                                   self.createNewDocForRecentChannel(data: data, key: key, transaction: transaction)
                           
                                
                                    let mydata2=["n":FieldValue.increment(Int64(1))]
                                    
                                transaction.updateData(mydata2, forDocument: sfDocument.reference)
                                transaction.updateData(["quips.\(key)" : mydata], forDocument: sfDocument.reference)
                                    
                                    self.addQuipToFirebase()
                               }
                               else{
                                   let mydata2=["n":FieldValue.increment(Int64(1))]
                                  
                                   transaction.updateData(mydata2, forDocument: (querySnapshot?.documents[1].reference)!)
                                   transaction.updateData(["quips.\(key)" : mydata], forDocument: (querySnapshot?.documents[1].reference)!)
                                    self.addQuipToFirebase()
                           }
                       
                   
            return nil
        }){ (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                print("Transaction successfully committed!")
                self.textView.resignFirstResponder()
                self.navigationController?.popViewController(animated: true)
                self.runTransactionForRecentUser(data: post4, key: key)
                self.addQuipDocToFirestore(data: post2, key: key)
            }
        }
        }
        
    }
   
    
    
    func createNewDocForRecentChannel(data:[String:Any], key:String, transaction:Transaction){
        
        var mydata2:[String:Any] = [:]
        mydata2 = ["n": 0,
                   "t": FieldValue.serverTimestamp()]
        
        
        guard let recentQuipRef = self.db?.collection("Channels/\(self.myChannel?.key ?? "Other")/RecentQuips").document() else { return  }
       
        transaction.setData(mydata2, forDocument: recentQuipRef)
        
       
                       
   
        
    }
    
    func runTransactionForRecentUser(data:[String:Any], key: String){
         let mydata = data
        
             let recentQuipsRef = self.db?.collection("Users/\(uid ?? "Other")/RecentQuips")
                 
                 recentQuipsRef?.order(by: "t", descending: true).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                     if let err = err {
                                print("Error getting documents: \(err)")
                     }else{
                       
                         if querySnapshot?.isEmpty ?? true ||
                             querySnapshot?.documents[0].data()["n"] as! Double >= 20{
                             self.createNewDocForRecentUser(data: data, key: key)
                     
                         }
                         else{
                             let mydata2=["n":FieldValue.increment(Int64(1))]
                             let batch = self.db?.batch()
                             batch?.updateData(mydata2, forDocument: (querySnapshot?.documents[0].reference)!)
                             batch?.updateData(["quips.\(key)" : mydata], forDocument: (querySnapshot?.documents[0].reference)!)
                             batch?.commit()
                             
                            }
                        
                    }
       
        }
    }
    func createNewDocForRecentUser(data:[String:Any], key:String){
           
           var mydata2:[String:Any] = [:]
           mydata2 = ["n": 1,
                      "t": FieldValue.serverTimestamp()]
           let batch = db?.batch()
           
           guard let recentQuipRef = self.db?.collection("Users/\(uid ?? "Other")/RecentQuips").document() else { return  }
           batch?.setData(["quips" : [key:data]], forDocument: recentQuipRef, merge: true)
           batch?.updateData(mydata2, forDocument: recentQuipRef)
           batch?.commit()
       }
    
    func addQuipDocToFirestore(data:[String:Any],key:String){
        let batch = db?.batch()
        guard let newQuipRef=db?.collection("Quips").document(key) else { return  }
        guard let newRepliesRef = db?.collection("Quips/\(key)/Replies").document() else { return  }
        batch?.setData(data, forDocument: newQuipRef)
        batch?.setData(["exists":true], forDocument: newRepliesRef)
        batch?.commit()
        
        
    }
    
    func addQuipToFirebase(){
         ref?.updateChildValues(childUpdates)
       
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
