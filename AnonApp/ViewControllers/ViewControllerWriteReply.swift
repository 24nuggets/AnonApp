//
//  ViewControllerWriteReply.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerWriteReply: UIViewController,UITextViewDelegate {
    
    var myQuip:Quip?
    var uid:String?
    var ref:DatabaseReference?
    var db:Firestore?
    var storageRef:StorageReference?
    var myChannel:Channel?
    private var repliesNumRef1:DatabaseReference?
    private var repliesNumRef2:DatabaseReference?
    private var repliesNumRef3:DatabaseReference?
    
    
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
            saveReply()
            
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
    
    func saveReply(){
        guard let key = ref?.child("replies").childByAutoId().key else { return }
            
              let post2 = [   "t": textView.text,
                                "a": uid ?? "Other",
                                "d": FieldValue.serverTimestamp()] as [String : Any]
                  
              
                  
       
        addReplyToFirestore(key: key, data: post2)
       
       
        
       
    }
    func addReplyToFirestore(key:String, data:[String:Any]){
        let mydata = data
        
        let repliesQuipsRef = self.db?.collection("/Quips/\(myQuip?.quipID ?? "Other")/Replies")

        repliesQuipsRef?.getDocuments(){ (querySnapshot, err) in
                     if let err = err {
                                print("Error getting documents: \(err)")
                     } else {
                        
                        
                             let batch = self.db?.batch()
                             batch?.updateData(["replies.\(key)" : mydata], forDocument: (querySnapshot?.documents[0].reference)!)
                             batch?.commit()
                             self.addReplyToFirebase(key: key)
                     
                        
                 }
         
         }
        
        
        
    }
    
    
    func addReplyToFirebase(key:String){
         let reply1 = ["s": 0] as [String : Any]
        
       
        var childUpdates:[String:Any]=[:]
        if myChannel != nil{
                 childUpdates = ["/Q/\(myQuip!.quipID ?? "Other")/R/\(key)":reply1,
                                    "/M/\(uid ?? "Other")/\(key)":reply1,
                                    "A/\(myChannel?.key ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r": ServerValue.increment(1),
                                    "M/\(myQuip?.user ?? "Other")/q/\(myQuip?.quipID ?? "Other")/r":ServerValue.increment(1)] as [String : Any]
                 
                  
                  if myChannel?.parentKey != nil{
                    childUpdates["A/\(myChannel?.parentKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r"]=ServerValue.increment(1)
                  }
              }else{
             childUpdates = ["/Q/\(myQuip!.quipID ?? "Other")/R/\(key)":reply1,
                            "/M/\(uid ?? "Other")/\(key)":reply1,
                            "A/\(myQuip?.channelKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r": ServerValue.increment(1),
                            "M/\(myQuip?.user ?? "Other")/q/\(myQuip?.quipID ?? "Other")/r":ServerValue.increment(1)] as [String : Any]
                     if myQuip?.parentKey != nil{
                        childUpdates["A/\(myQuip?.parentKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r"]=ServerValue.increment(1)
                        
                    }
            }
                   
        ref?.updateChildValues(childUpdates)
        
        textView.resignFirstResponder()
        navigationController?.popViewController(animated: true)
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
