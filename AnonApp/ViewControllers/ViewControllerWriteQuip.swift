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
    var myChannel:Channel?
    private var feedVC:ViewControllerFeed?
    var uid:String?
    
   
    
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
            textView.resignFirstResponder()
            navigationController?.popViewController(animated: true)
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
        print(ServerValue.timestamp())
        let post1 = ["d":ServerValue.timestamp(),
                    "r": "0",
                    "s": "0",
                    "t": textView.text     ] as [String : Any]
        let post2 = ["d":ServerValue.timestamp(),
                     "r": "0",
                     "s": "0",
                     "t": textView.text     ] as [String : Any]
        if myChannel!.parent != "" {
            let post3 = ["d":ServerValue.timestamp(),
                         "r": "0",
                         "s": "0",
                         "t": textView.text     ] as [String:Any]
                let childUpdates = ["/A/\(myChannel!.key ?? "Other")/Q/\(key)":post1,
                "/M/\(uid ?? "defaultUser")/q/\(key)":post2,
                "/A/\(myChannel!.parentKey ?? "Other")/Q/\(key)":post3  ] as [String : Any]
            ref?.updateChildValues(childUpdates)
        }
        else{
            let childUpdates = ["/A/\(myChannel!.key ?? "Other")/Q/\(key)":post1,
                                "/M/\(uid ?? "defaultUser")/q/\(key)":post2] as [String : Any]
            
            ref?.updateChildValues(childUpdates)
        }
        
        
        
        
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
