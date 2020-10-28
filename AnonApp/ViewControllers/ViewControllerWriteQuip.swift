//
//  ViewControllerWriteQuip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/21/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import GiphyUISDK
import GiphyCoreSDK
import Firebase



class ViewControllerWriteQuip: myUIViewController, UITextViewDelegate{
    
    
    weak var myChannel:Channel?
    weak var feedVC: ViewControllerFeed?
    
    var uid:String?
    private var childUpdates:[String:Any]=[:]
    var deleteBtn:UIButton?
    var mediaView:GPHMediaView?
    var giphyBottomSpaceConstraint:NSLayoutConstraint?
    var giphyTrailingSpace:NSLayoutConstraint?
    let placeholderText = "Get cracking"
    var activityIndicator:UIActivityIndicatorView?
    let blackView = UIView()
    var emailEnding:String?
    
    @IBOutlet weak var textView: UITextView!
    
  
    @IBOutlet weak var Quipit: UINavigationItem!
    
    @IBOutlet weak var deleteImageBtn: UIButton!
    
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
        textView.textContainer.maximumNumberOfLines = 10
        textView.textContainer.lineBreakMode = .byClipping
        Quipit.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelClicked))
        Quipit.leftBarButtonItem?.tintColor = .white
        
        Quipit.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(self.postClicked))
        Quipit.rightBarButtonItem?.tintColor = .white
        deleteImageBtn.clipsToBounds = true
        deleteImageBtn.layer.cornerRadius = deleteImageBtn.bounds.width/2
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
        Quipit.leftBarButtonItem?.isEnabled = false
        Quipit.rightBarButtonItem?.isEnabled = false
        
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        } else {
            // Fallback on earlier versions
        }
        activityIndicator?.center = self.view.center
        activityIndicator?.startAnimating()
        if let myActivityIndicator = activityIndicator{
        self.view.addSubview(myActivityIndicator)
        }
        makeViewFade()
        dismissKeyboard()
        if emailEnding != nil{
            saveQuip()
        }else{
        FirestoreService.sharedInstance.checkIfEventIsOpen(eventID: myChannel?.key ?? "Other") {[weak self] (isOpen) in
            if isOpen{
                self?.saveQuip()
            }else{
                self?.displayMsgBox2()
            }
        }
        }
    }
    
    func makeViewFade(){
            if let window = UIApplication.shared.keyWindow{
                   
                     
                       blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
                   window.addSubview(blackView)
                   blackView.frame = window.frame
                       blackView.alpha = 1
                       
                       
                   }
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
        g.theme = GPHTheme(type: .automatic)
        //g.layout = .waterfall
        g.mediaTypeConfig = [.gifs, .recents]
        g.showConfirmationScreen = true
        g.rating = .ratedPG13
        g.delegate = self
        present(g, animated: true, completion: nil)
    }
    
    @IBAction func deleteImageBtnClick(_ sender: Any) {
        deleteImageBtn.isHidden = true
        deleteImageBtn.isEnabled = false
        imageView.image = nil
        imageView.isHidden = true
    }
    
    
     // -MARK: TextViewFunctions
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = toolBar
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = .gray
            self.adjustTextViewHeight()
        } else {
            if #available(iOS 13.0, *) {
                textView.textColor = .label
            } else {
                // Fallback on earlier versions
                textView.textColor = .black
            }
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
                textView.text = placeholderText
                textView.textColor = .gray
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
        } else {
            if textView.text == placeholderText {
                textView.text = ""
            }
            
            
            if #available(iOS 13.0, *) {
                textView.textColor = .label
            } else {
                // Fallback on earlier versions
                textView.textColor = .black
            }
            
            return textView.text.count < 141
            
        }
        return true
    }
    
    
    
     // -MARK: SaveQuip
    
    func saveQuip(){
        
        var gifID:String?
        var hasGif:Bool=false
        if imageView.image != nil  && imageView.isHidden==false {
           checkIfImageIsClean()
            return
        }
        else if mediaView?.media != nil && mediaView?.isHidden == false{
            gifID = mediaView?.media?.id
            hasGif = true
        }
       generatePost(hasImage: false, hasGif: hasGif, imageRef: nil, gifID: gifID)
        
       
        
          
        
        
    }
    
    func checkIfImageIsClean(){
        
       
                       let hasImage=true
                       let randomID = UUID.init().uuidString
                       if let auid = self.uid{
                       let imageRef = "\(auid)/\(randomID)"
                           
                           guard let imageData = self.imageView.image?.jpegData(compressionQuality: 0.75) else {print("error getting image")
                           return
                        }
                        FirebaseStorageService.sharedInstance.uploadImage(imageRef: imageRef, imageData: imageData) { (isClean) in
                            if isClean{
                               self.generatePost(hasImage: hasImage, hasGif: false, imageRef: imageRef, gifID: nil)
                            }else{
                                self.displayMsgBox()
                            }
                        }
        }
        
    }
    
    func displayMsgBox(){
        let title = "Inappropriate Image"
        let message = "We could not post your image becuase we have identified it has having inappropriate content.  If you want more information on this please email us at \(supportEmail)"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")

              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


              @unknown default:
                print("unknown action")
            }}))
        self.present(alert, animated: true, completion: nil)
        stopPosting()
    }
    func displayMsgBox2(){
           let title = "Event Closed"
           let message = "We could not post your quip because the event has ended."
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                 switch action.style{
                 case .default:
                       print("default")

                 case .cancel:
                       print("cancel")

                 case .destructive:
                       print("destructive")


                 @unknown default:
                   print("unknown action")
               }}))
           self.present(alert, animated: true, completion: nil)
           stopPosting()
       }
    
    func stopPosting(){
       Quipit.leftBarButtonItem?.isEnabled = true
        Quipit.rightBarButtonItem?.isEnabled = true
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        blackView.removeFromSuperview()
    }
    
    func generatePost(hasImage:Bool, hasGif:Bool, imageRef:String?, gifID:String?){
        guard let key = FirebaseService.sharedInstance.generatePostKey() else { return }
        Analytics.logEvent(AnalyticsEventSelectItem, parameters: [AnalyticsParameterItemID : "id- \(myChannel?.channelName ?? "Other")",
            AnalyticsParameterContentType: "PostToEvent"])
        Analytics.setUserProperty("true", forName: "Creator")
              var post2:[String:Any]=[:]
                var post3:[String:Any]=[:]
                var post4:[String:Any]=[:]
                 
              
               
               let post1 = ["s": 0,
                                 "r":0] as [String : Any]
               var quipText = ""
               
               if textView.text != placeholderText {
                   quipText = textView.text
               }
              
               if let auid = uid{
                   
                  
               
               if let myChannelKey = myChannel?.key{
                   if let myChannelName = myChannel?.channelName{
                       
              
                   if let myParentChannelKey = myChannel?.parentKey {
                       if let myParentChannelName = myChannel?.parent{
                        post3 = ["a": auid,
                                                  "t": quipText,
                                                  "c": myChannelName,
                                                  "k": myChannelKey,
                                                  "pk": myParentChannelKey,
                                                  "email": emailEnding as Any]
                                              //    "d": FieldValue.serverTimestamp()]
                       post2 = [   "t": quipText,
                                    "k": myChannelKey,
                                    "c": myChannelName,
                                    "pk": myParentChannelKey,
                                    "p": myParentChannelName,
                                     "a": auid,
                                     "email": emailEnding as Any,
                               //      "d": FieldValue.serverTimestamp(),
                                     "v":true]
                       
                       post4 = ["c": myChannel?.channelName ?? "Other",
                                       "t": quipText,
                               //       "d": FieldValue.serverTimestamp(),
                                      "email": emailEnding as Any,
                                      "k": myChannelKey,
                                      "pk":myParentChannelKey]
                       
                   
                           childUpdates = ["/A/\(myChannelKey)/Q/\(key)":post1,
                           "/M/\(auid)/q/\(key)":post1,
                           "/A/\(myParentChannelKey)/Q/\(key)":post1  ] as [String : Any]
                       }
                   }
                   else{
                    post3 = ["a": auid,
                                              "t": quipText,
                                              "email": emailEnding as Any,
                                              "k": myChannelKey]
                                         //     "d": FieldValue.serverTimestamp()]
                       post2 = [        "t": quipText,
                                         "c": myChannelName,
                                         "k": myChannelKey,
                                         "a": auid,
                                         "email": emailEnding as Any,
                                  //       "d": FieldValue.serverTimestamp(),
                                         "v":true]
                       
                           post4 = ["c": myChannelName,
                            "t": quipText,
                            "email": emailEnding as Any,
                       //    "d": FieldValue.serverTimestamp(),
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
        
        //TODO add cloud function
        
         
        if let myChannelKey = self.myChannel?.key{
            if let auid = uid{
                 self.textView.resignFirstResponder()
                cloudFunctionManager.sharedInstance.functions.httpsCallable("writeCrack").call(["key":key, "data":data, "uid":auid, "channelID": myChannelKey, "post4":post4, "post2":post2] ) {[weak self] (result, error) in
                    if let error = error as NSError? {
                      if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                       print("code:\(String(describing: code)), message:\(message), details:\(String(describing: details))")
                      }
                      // ...
                    }
                                //self?.resetView()
                    if let feedVC = self?.feedVC{
                                       feedVC.collectionView.reloadData()
                                   }
                                   self?.activityIndicator?.stopAnimating()
                                   self?.activityIndicator?.removeFromSuperview()
                                   self?.blackView.removeFromSuperview()
                    Messaging.messaging().subscribe(toTopic: "\(key)Author"){ error in
                      print("Subscribed to \(key)")
                    }
                               self?.dismiss(animated: true, completion: nil)
                                
                      
                    }
            }
           /*
            FirestoreService.sharedInstance.addQuipToRecentChannelTransaction(myChannelKey: myChannelKey, data: data, key: key) {
                self.addQuipToFirebase()
                
                
                self.runTransactionForRecentUser(data: post4, key: key)
                self.addQuipDocToFirestore(data: post2, key: key)
            }
        }
        if let myParentChannelKey = self.myChannel?.parentKey{
            FirestoreService.sharedInstance.addQuipToRecentChannelTransaction(myChannelKey: myParentChannelKey, data: data, key: key) {
                
            }
        }
    */
    }
   
    }
    
   
    
    func runTransactionForRecentUser(data:[String:Any], key: String){
        if let auid = uid{
            FirestoreService.sharedInstance.addQuipToRecentUserQuips(auid: auid, data: data, key: key){
             
               if let feedVC = self.feedVC{
                                                     feedVC.collectionView.reloadData()
                                                 }
                                                 self.activityIndicator?.stopAnimating()
                                                 self.activityIndicator?.removeFromSuperview()
                                                 self.blackView.removeFromSuperview()
                                             self.dismiss(animated: true, completion: nil)
            }
        }
    }
   
    
    func addQuipDocToFirestore(data:[String:Any],key:String){
      
        FirestoreService.sharedInstance.addQuipDocToFirestore(data: data, key: key)
        
    }
    
    func addQuipToFirebase(){
        FirebaseService.sharedInstance.updateChildValues(myUpdates: childUpdates)
       
    }
    
    func setUpGiphyView(){
        mediaView?.removeFromSuperview()
        deleteBtn?.removeFromSuperview()
        mediaView = GPHMediaView()
        view.addSubview(mediaView!)
        mediaView?.isHidden = false
        mediaView?.translatesAutoresizingMaskIntoConstraints = false
        let leadingSpace = NSLayoutConstraint(item: mediaView!, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 15)
      giphyBottomSpaceConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: mediaView!, attribute: .bottom, multiplier: 1, constant: 40)
        giphyTrailingSpace = NSLayoutConstraint(item: self.view!, attribute: .trailing, relatedBy: .equal, toItem: mediaView!, attribute: .trailing, multiplier: 1, constant: 40)
        let topSpace = NSLayoutConstraint(item: mediaView!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1, constant: 10)
       
        self.view.addConstraints([leadingSpace,topSpace, giphyTrailingSpace!, giphyBottomSpaceConstraint!])
        
        mediaView?.isHidden=true
        mediaView?.contentMode = UIView.ContentMode.scaleAspectFit
       
        
       
        
    }
    
    func addCancelImageButton(){
        let width:CGFloat = 20
        deleteBtn = UIButton()
        self.view.addSubview(deleteBtn!)
        deleteBtn?.setImage(UIImage(named: "multiply")?.withRenderingMode(.alwaysTemplate), for: .normal)
        deleteBtn?.tintColor = .white
        deleteBtn?.backgroundColor = .black
        deleteBtn?.translatesAutoresizingMaskIntoConstraints = false
        deleteBtn?.widthAnchor.constraint(equalToConstant: width).isActive=true
        deleteBtn?.heightAnchor.constraint(equalToConstant:  width ).isActive = true
        let mybuttonTopConstraint = NSLayoutConstraint(item: deleteBtn!, attribute: .top, relatedBy: .equal, toItem: mediaView, attribute: .top, multiplier: 1, constant: 10)
        let mybuttonSideConstraint = NSLayoutConstraint(item: deleteBtn!, attribute: .trailing, relatedBy: .equal, toItem: mediaView, attribute: .trailing, multiplier: 1, constant: -10)
        self.view.addConstraints([mybuttonTopConstraint,mybuttonSideConstraint])
        deleteBtn?.addTarget(self, action: #selector(self.deleteImage), for: .touchUpInside)
        deleteBtn?.layer.cornerRadius = width / 2
        deleteBtn?.clipsToBounds = true
        
        self.view.bringSubviewToFront(deleteBtn!)
       
    }
    
    @objc func deleteImage(){
        mediaView?.isHidden = true
        mediaView?.removeFromSuperview()
        deleteBtn?.removeFromSuperview()
             
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
extension ViewControllerWriteQuip: UIImagePickerControllerDelegate {
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
        deleteImageBtn.isEnabled = true
        deleteImageBtn.isHidden = false
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
    addCancelImageButton()
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
    
     self.view.layoutIfNeeded()
 //   mediaView?.frame.size = resizeGIF(image: media, targetSize: CGSize(width: (mediaView?.frame.width)!, height: (mediaView?.frame.width)! * 2))
        
        // your user tapped a GIF!
        giphyViewController.dismiss(animated: true, completion: nil)
    
   }
   
   func didDismiss(controller: GiphyViewController?) {
        // your user dismissed the controller without selecting a GIF.
   }
}

