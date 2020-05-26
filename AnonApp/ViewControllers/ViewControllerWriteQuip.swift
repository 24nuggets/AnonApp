//
//  ViewControllerWriteQuip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/21/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK



class ViewControllerWriteQuip: UIViewController, UITextViewDelegate{
    
    var ref:DatabaseReference?
    var db:Firestore?
    var myChannel:Channel?
    private var feedVC:ViewControllerFeed?
    var uid:String?
    private var childUpdates:[String:Any]=[:]
    var storageRef:StorageReference?
    var mediaView:GPHMediaView?
    var giphyBottomSpaceConstraint:NSLayoutConstraint?
    var giphyTrailingSpace:NSLayoutConstraint?
    
    @IBOutlet weak var textView: UITextView!
    
  
    @IBOutlet weak var Quipit: UINavigationItem!
    
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageBtn: UIBarButtonItem!
    
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewSpaceToBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        textView.textColor = UIColor.lightGray
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.isScrollEnabled = false
        
        Quipit.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelClicked))
        Quipit.leftBarButtonItem?.tintColor = .black
        
        Quipit.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(self.postClicked))
        Quipit.rightBarButtonItem?.tintColor = .black
        
        imageView.layer.cornerRadius = 8.0
        hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //have text view be selected and keyboard appear when view appears
        textView.becomeFirstResponder()
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
    }
    
    
    // -MARK: ActionFunctions
    
    @objc func postClicked(){
        saveQuip()
    }
  
    
    
    @objc func cancelClicked(){
        self.textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
        
    }
  
    
    @IBAction func imageClicked(_ sender: Any) {
        showImagePickerController()
        
    }
    
    
    @IBAction func gifClicked(_ sender: Any) {
        let g = GiphyViewController()
        g.theme = .automatic
        g.layout = .waterfall
        g.mediaTypeConfig = [.gifs, .recents]
        g.showConfirmationScreen = true
        g.rating = .ratedPG13
        g.delegate = self
        present(g, animated: true, completion: nil)
    }
    
     // -MARK: TextViewFunctions
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = toolBar
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Type something"
            textView.textColor = .gray
            self.adjustTextViewHeight()
        } else {
            textView.textColor = .black
            self.adjustTextViewHeight()
        }
    }
    func adjustTextViewHeight() {
       let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
       
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text.isEmpty {
            let updatedText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            if updatedText.isEmpty {
                textView.text = "Type something"
                textView.textColor = .gray
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
        } else {
            if textView.text == "Type something" {
                textView.text = ""
            }
            
            
            textView.textColor = .black
            
            return textView.text.count < 141
            
        }
        return true
    }
    
     // -MARK: SaveQuip
    
    func saveQuip(){
        var imageRef:String?
        var hasImage:Bool=false
        var gifID:String?
        var hasGif:Bool=false
        if imageView.image != nil  && imageView.isHidden==false{
            if true { //send to google sensor api
                hasImage=true
                let randomID = UUID.init().uuidString
                imageRef = "\(uid ?? "Other")/\(randomID)"
                let uploadref = storageRef?.child(imageRef!)
                guard let imageData = imageView.image?.jpegData(compressionQuality: 0.75) else {print("error getting image")
                    return
                }
                uploadref?.putData(imageData)
                
            }
            else{
                return
            }
        }
        else if mediaView?.media != nil && mediaView?.isHidden == false{
            gifID = mediaView?.media?.id
            hasGif = true
        }
        guard let key = ref?.child("posts").childByAutoId().key else { return }
              
       var post2:[String:Any]=[:]
         var post3:[String:Any]=[:]
         var post4:[String:Any]=[:]
          
       
        
        let post1 = ["s": 0,
                          "r":0] as [String : Any]
        
       
        if let auid = uid{
            
            post3 = ["a": auid,
                    "t": textView.text ?? "",
                    "d": FieldValue.serverTimestamp()]
        
        if let myChannelKey = myChannel?.key{
            if let myChannelName = myChannel?.channelName{
                
       
            if let myParentChannelKey = myChannel?.parentKey {
                if let myParentChannelName = myChannel?.parent{
                post2 = [   "t": textView.text ?? "",
                             "k": myChannelKey,
                             "c": myChannelName,
                             "pk": myParentChannelKey,
                             "p": myParentChannelName,
                              "a": auid,
                              "d": FieldValue.serverTimestamp()]
                
                post4 = ["c": myChannel?.channelName ?? "Other",
                                "t": textView.text ?? "",
                               "d": FieldValue.serverTimestamp(),
                               "k": myChannelKey,
                               "pk":myParentChannelKey]
                
            
                    childUpdates = ["/A/\(myChannelKey)/Q/\(key)":post1,
                    "/M/\(auid)/q/\(key)":post1,
                    "/A/\(myParentChannelKey)/Q/\(key)":post1  ] as [String : Any]
                }
            }
            else{
                post2 = [        "t": textView.text ?? "",
                                  "c": myChannelName,
                                  "k": myChannelKey,
                                  "a": auid,
                                  "d": FieldValue.serverTimestamp()]
                
                    post4 = ["c": myChannelName,
                     "t": textView.text ?? "",
                    "d": FieldValue.serverTimestamp(),
                    "k": myChannelKey]
              
                childUpdates = ["/A/\(myChannelKey)/Q/\(key)":post1,
                                    "/M/\(auid)/q/\(key)":post1] as [String : Any]
                
             
                }
                
            }
        }
        }
        if hasImage {
            post3["i"]=imageRef
            post4["i"]=imageRef
            post2["i"]=imageRef
        }
        else if hasGif{
            post3["g"]=gifID
            post4["g"]=gifID
            post2["g"]=gifID
        }
        
        queryRecentChannelQuips(data: post3, key: key,post4: post4, post2: post2)
        
       
        
          
        
        
    }
    
    //add quips to recentChannelDoc
    func queryRecentChannelQuips(data:[String:Any], key:String, post4:[String:Any], post2:[String:Any]){
         let mydata = data
        if let myChannelKey = self.myChannel?.key{
        let recentQuipsRef = self.db?.collection("Channels/\(myChannelKey)/RecentQuips")
                  
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
                                   querySnapshot?.documents[1].data()["n"] as! Double >= 20{
                               
                                   self.createNewDocForRecentChannel(data: data, key: key, transaction: transaction, channelKey: myChannelKey)
                           
                                
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
               
                self.textView.resignFirstResponder()
             self.dismiss(animated: true, completion: nil)
                self.runTransactionForRecentUser(data: post4, key: key)
                self.addQuipDocToFirestore(data: post2, key: key)
            }
        }
        }
        }
        if let myParentChannelKey = self.myChannel?.parentKey{
              let recentQuipsRef = self.db?.collection("Channels/\(myParentChannelKey)/RecentQuips")
                        
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
                                         querySnapshot?.documents[1].data()["n"] as! Double >= 20{
                                     
                                         self.createNewDocForRecentChannel(data: data, key: key, transaction: transaction, channelKey: myParentChannelKey)
                                 
                                      
                                          let mydata2=["n":FieldValue.increment(Int64(1))]
                                          
                                      transaction.updateData(mydata2, forDocument: sfDocument.reference)
                                      transaction.updateData(["quips.\(key)" : mydata], forDocument: sfDocument.reference)
                                          
                                         
                                     }
                                     else{
                                         let mydata2=["n":FieldValue.increment(Int64(1))]
                                        
                                         transaction.updateData(mydata2, forDocument: (querySnapshot?.documents[1].reference)!)
                                         transaction.updateData(["quips.\(key)" : mydata], forDocument: (querySnapshot?.documents[1].reference)!)
                                         
                                 }
                             
                         
                  return nil
              }){ (object, error) in
                  if let error = error {
                      print("Transaction failed: \(error)")
                  } else {
                     
                    
                  }
              }
              }
              }
    }
   
    
    
    func createNewDocForRecentChannel(data:[String:Any], key:String, transaction:Transaction, channelKey:String){
        
        var mydata2:[String:Any] = [:]
        mydata2 = ["n": 0,
                   "t": FieldValue.serverTimestamp()]
        
        
        guard let recentQuipRef = self.db?.collection("Channels/\(channelKey)/RecentQuips").document() else { return  }
       
        transaction.setData(mydata2, forDocument: recentQuipRef)
        
       
                       
   
        
    }
    
    func runTransactionForRecentUser(data:[String:Any], key: String){
         let mydata = data
        if let auid = uid{
             let recentQuipsRef = self.db?.collection("Users/\(auid)/RecentQuips")
                 
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
    }
    func createNewDocForRecentUser(data:[String:Any], key:String){
           
           var mydata2:[String:Any] = [:]
           mydata2 = ["n": 1,
                      "t": FieldValue.serverTimestamp()]
           let batch = db?.batch()
        if let auid = uid{
           guard let recentQuipRef = self.db?.collection("Users/\(auid)/RecentQuips").document() else { return  }
           batch?.setData(["quips" : [key:data]], forDocument: recentQuipRef, merge: true)
           batch?.updateData(mydata2, forDocument: recentQuipRef)
           batch?.commit()
        }
       }
    
    func addQuipDocToFirestore(data:[String:Any],key:String){
        let batch = db?.batch()
        guard let newQuipRef=db?.collection("Quips").document(key) else { return  }
        
        batch?.setData(data, forDocument: newQuipRef)
       
        batch?.commit()
        
        
    }
    
    func addQuipToFirebase(){
         ref?.updateChildValues(childUpdates)
       
    }
    
    func setUpGiphyView(){
        mediaView?.removeFromSuperview()
        mediaView = GPHMediaView()
        view.addSubview(mediaView!)
        mediaView?.translatesAutoresizingMaskIntoConstraints = false
        let leadingSpace = NSLayoutConstraint(item: mediaView!, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 15)
      giphyBottomSpaceConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: mediaView!, attribute: .bottom, multiplier: 1, constant: 40)
        giphyTrailingSpace = NSLayoutConstraint(item: self.view!, attribute: .trailing, relatedBy: .equal, toItem: mediaView!, attribute: .trailing, multiplier: 1, constant: 40)
        let topSpace = NSLayoutConstraint(item: mediaView!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1, constant: 10)
       resetGiphyView()
        self.view.addConstraints([leadingSpace,topSpace, giphyTrailingSpace!, giphyBottomSpaceConstraint!])
        
        mediaView?.isHidden=true
        mediaView?.contentMode = UIView.ContentMode.scaleAspectFit
       
        
    }
    
    func resetGiphyView(){
       
               self.view.addConstraints([giphyTrailingSpace!,giphyBottomSpaceConstraint!])
        
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
extension ViewControllerWriteQuip: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func showImagePickerController(){
        let imagePickerController = UIImagePickerController()
           imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController,animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        mediaView?.isHidden=true
        imageView.isHidden=false
        if let myImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.translatesAutoresizingMaskIntoConstraints=false
             let newImage = resizeImage(image: myImage, targetSize: CGSize(width: imageView.frame.width, height: imageView.frame.width * 2 ))
            if imageViewSpaceToBottom != nil {
            imageViewSpaceToBottom.isActive = false
            }
            imageView.image = newImage
        }
        
        dismiss(animated: true, completion: nil)

    }
  
}

extension ViewControllerWriteQuip: GiphyDelegate {
   func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia)   {
   // let giphyID = media.id
    setUpGiphyView()
    mediaView?.isHidden = false
    imageView.isHidden = true
    
    mediaView?.media = media
    if giphyBottomSpaceConstraint != nil {
        giphyBottomSpaceConstraint?.isActive = false
    }
    if giphyTrailingSpace != nil{
        giphyTrailingSpace?.isActive = false
    }
    mediaView?.widthAnchor.constraint(equalTo: mediaView!.heightAnchor, multiplier: media.aspectRatio).isActive = true
    
    mediaView?.layer.cornerRadius = 8.0
    mediaView?.clipsToBounds = true 
    
 //   mediaView?.frame.size = resizeGIF(image: media, targetSize: CGSize(width: (mediaView?.frame.width)!, height: (mediaView?.frame.width)! * 2))
        
        // your user tapped a GIF!
        giphyViewController.dismiss(animated: true, completion: nil)
   }
   
   func didDismiss(controller: GiphyViewController?) {
        // your user dismissed the controller without selecting a GIF.
   }
}

