//
//  ViewControllerQuip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK

class ViewControllerQuip: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, MyCellDelegate {
    
    

    
    var myQuip:Quip?
    var myChannel:Channel?
    var ref:DatabaseReference?
    var db:Firestore?
    var storageRef:StorageReference?
    var uid:String?
    var mediaView:GPHMediaView?
    var imageView:UIImageView?
    var giphyBottomSpaceConstraint:NSLayoutConstraint?
    var giphyTrailingSpace:NSLayoutConstraint?
    var imageViewSpaceToBottom:NSLayoutConstraint?
    var imageTrailingSpace:NSLayoutConstraint?
    private var isNewImage = true
    var currentTime:Double?
    var quipScore:String?
    var quipLikeStatus:Bool?
    private var replyScores:[String:Int] = [:]
    private var myReplyID:String?
    private var myReplyText:String?
    private var myReplyScore:String?
    private var timePosted:String?
    private var myReplies:[Quip?] = []
    private var origBottom:CGFloat?
    private var writeReply:ViewControllerWriteReply?
    var parentViewFeed:ViewControllerFeed?
    var parentViewUser:ViewControllerUser?
    var passedQuipCell:QuipCells?
    private var myVotes:[String:Any] = [:]
    private var myLikesDislikesMap:[String:Int] = [:]
    private var myNewLikesDislikesMap:[String:Int] = [:]
    var myUserMap:[String:String] = [:]
    private var refreshControl = UIRefreshControl()

    @IBOutlet weak var replyTable: UITableView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var textView: UITextView!
    
  
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
   
    
   
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var toolBar: UIToolbar!
    
 
    @IBOutlet weak var postReplyView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        replyTable.delegate=self
        replyTable.dataSource=self
        
        refreshControl.addTarget(self, action: #selector(ViewControllerQuip.refreshData), for: .valueChanged)
        replyTable.refreshControl=refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    
        textView.layer.cornerRadius = 8.0
        
        textView.delegate = self
        textView.textColor = UIColor.lightGray
        textView.translatesAutoresizingMaskIntoConstraints = true
      
        textView.isScrollEnabled = false
        
        hideKeyboardWhenTappedAround()
        
        resetVars()
        refreshData()
        
        
    }
    override func viewWillAppear(_ animated: Bool){
      super.viewWillAppear(animated)
       
        
        
      
    }
    
    override func viewWillDisappear(_ animated: Bool){
      super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        updateFirestoreLikesDislikes()
        ref?.updateChildValues(myVotes)
        resetVars()
      
    }
    func resetVars(){
        myUserMap=[:]
           myNewLikesDislikesMap=[:]
           myVotes=[:]
       }
    
    @objc func handleKeyboardNotification(_ notification: Notification) {

       if let userInfo = notification.userInfo {

        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue

        let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification

        if isKeyboardShowing{
            
            bottomConstraint?.constant = keyboardFrame.height - self.view.safeAreaInsets.bottom
            toolBar.isHidden = false
          
        }
        else{
           
                bottomConstraint?.constant = 0
            toolBar.isHidden = true
            
        }
      //  print(bottomConstraint.constant)
        
           UIView.animate(withDuration: 0.5, animations: { () -> Void in
               self.view.layoutIfNeeded()
           
            self.view.bringSubviewToFront(self.stackView)
           })
        
       }
    }
    
    
    @IBAction func imageBtnClicked(_ sender: Any) {
        
         showImagePickerController()
    }
    
    
    @IBAction func gifBtnClicked(_ sender: Any) {
        let g = GiphyViewController()
               g.theme = .automatic
               g.layout = .waterfall
               g.mediaTypeConfig = [.gifs, .recents]
               g.showConfirmationScreen = true
               g.rating = .ratedPG13
               g.delegate = self
               present(g, animated: true, completion: nil)
        
    }
    
    
    
    @IBAction func postBtnClicked(_ sender: Any) {
        
        saveReply()
        
    }
    
    
    
    func updateReplies(){
        self.replyScores = [:]
           setCurrentTime()
           
        ref?.child("Q/" + (myQuip?.quipID)! + "/R").observeSingleEvent(of: .value, with: {(snapshot)   in
               
               let enumerator = snapshot.children
               while let rest = enumerator.nextObject() as? DataSnapshot {
                   if rest.key == "z"{
                       self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                   
                   }
                   else{
                           
                       self.myReplyID = rest.key
                       if let actualkey = self.myReplyID {
                           
                           
                           let myReplyScore = rest.childSnapshot(forPath: "s").value as? Int
                           
                          
                          
                    
                           
                           self.replyScores[actualkey]=myReplyScore
                                                  
                           
                           }
                       }
               }
            self.getFirestoreReplies()
            
               
           })
           
                  
           
       
           
           
       }
    
    
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
         textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
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
        print(self.stackView.frame.minY)
        print(self.view.safeAreaInsets.top)
        if self.stackView.frame.minY - self.view.safeAreaInsets.top < 20 {
            
            textView.isScrollEnabled = true
            return
        }
        else{
            textView.isScrollEnabled = false
        }
          let fixedWidth = textView.frame.size.width
        let origHeight = textView.frame.size.height
           let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
           textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        let diff = newSize.height - origHeight
        adjustStackViewHeigt(height: diff)
        
        
          
       }
    func adjustStackViewHeigt(height:CGFloat){
        stackViewHeight.constant += height
        
        
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
    
    func getFirestoreReplies(){
        self.myReplies = []
        let repliesRef = db?.collection("/Quips/\(myQuip?.quipID ?? "Other")/Replies")
        
        repliesRef?.getDocuments() {(querySnapshot, err) in
        if let err = err {
                print("Error getting documents: \(err)")
        }
        else{
                      
            if querySnapshot!.documents.count == 0{
                self.refreshControl.endRefreshing()
                return
            }
             let document = querySnapshot!.documents[0]
                           
       
            let myReplies = document.data(with: ServerTimestampBehavior.estimate)
            let sortedKeys = Array(myReplies.keys).sorted(by: <)
            for aKey in sortedKeys{
                let myInfo = myReplies[aKey] as! [String:Any]
                           let aReplyID = aKey
                           let atimePosted = myInfo["d"] as? Timestamp
                           let aReplyText = myInfo["t"] as? String
                           let myAuthor = myInfo["a"] as? String
                          let myImageRef = myInfo["i"] as? String
                            let myGifRef = myInfo["g"] as? String
                if self.replyScores[aKey] == nil{
                    continue
                } else {
                        let aReplyScore = self.replyScores[aKey]
                          
                    let myReply = Quip(aScore: aReplyScore ?? 0, aKey: aReplyID, atimePosted: atimePosted!, aText: aReplyText!, aAuthor: myAuthor!, image:myImageRef, gif:myGifRef, quipParentID: self.myQuip?.quipID)
                        self.myReplies.append(myReply)
                }
            }
                       
        }
            self.replyTable.reloadData()
            self.refreshControl.endRefreshing()
        
    }
        
        
        
        
    }
       
       func setCurrentTime(){
           
        ref!.child("Q/" + (myQuip?.quipID)! + "/R/z/d").setValue(ServerValue.timestamp())
           
       }
       
    
    

    
    func setUpGiphyView(){
        mediaView?.removeFromSuperview()
        mediaView = GPHMediaView()
        stackView.addSubview(mediaView!)
        mediaView?.translatesAutoresizingMaskIntoConstraints = false
        let leadingSpace = NSLayoutConstraint(item: mediaView!, attribute: .leading, relatedBy: .equal, toItem: stackView, attribute: .leading, multiplier: 1, constant: 4)
        giphyBottomSpaceConstraint = NSLayoutConstraint(item: stackView!, attribute: .bottom, relatedBy: .equal, toItem: mediaView!, attribute: .bottom, multiplier: 1, constant: 4)
        giphyTrailingSpace = NSLayoutConstraint(item: stackView!, attribute: .trailing, relatedBy: .equal, toItem: mediaView!, attribute: .trailing, multiplier: 1, constant: 4)
        let topSpace = NSLayoutConstraint(item: mediaView!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1, constant: 8)
       
        stackView.addConstraints([leadingSpace,topSpace, giphyTrailingSpace!, giphyBottomSpaceConstraint!])
        
        mediaView?.isHidden=true
        mediaView?.contentMode = UIView.ContentMode.scaleAspectFit
       
        
    }
    func btnUpTapped(cell: QuipCells) {
           //Get the indexpath of cell where button was tapped
         if let indexPath = self.replyTable.indexPath(for: cell){
           if indexPath.row == 0 {
            if let aQuip = myQuip{
               upButtonPressed(aQuip: aQuip, cell: cell)
            }
           }
           else{
            if let myReply = myReplies[indexPath.row - 1]{
            upButtonPressedReply(aReply: myReply , cell: cell)
            }
               
           }
              
           }
           
       }
       
       func btnDownTapped(cell: QuipCells) {
           //Get the indexpath of cell where button was tapped
        if let indexPath = self.replyTable.indexPath(for: cell){
        if indexPath.row == 0 {
            if let aQuip = myQuip{
              downButtonPressed(aQuip: aQuip, cell: cell)
            }
            
        }
        else{
            if let myReply = myReplies[indexPath.row - 1]{
            downButtonPressedReply(aReply: myReply , cell: cell)
            }
        }
           
        }
       }
    func btnSharedTapped(cell: QuipCells) {
        
    }
    func downButtonPressedReply(aReply:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                let diff = cell.upToDown(quipScore: aQuipScore, quip: aReply)
                if let aID = aReply.quipID{
                               updateVotesFirebase(diff: diff, replyID: aID)
                               myNewLikesDislikesMap[aID] = -1
                    myLikesDislikesMap[aID] = -1
                    myUserMap[aID]=aReply.user
                           }
                   }
               }
               else if cell.downButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                           let diff = cell.downToNone(quipScore: aQuipScore,quip: aReply)
                if let aID = aReply.quipID{
                               updateVotesFirebase(diff: diff, replyID: aID)
                               myNewLikesDislikesMap[aID]=0
                                myLikesDislikesMap[aID]=0
                              myUserMap[aID]=aReply.user
                           }
                       
                   }
               }
               else{
            if let aQuipScore = aReply.quipScore{
                       let diff = cell.noneToDown(quipScore: aQuipScore,quip:  aReply)
                if let aID = aReply.quipID{
                           updateVotesFirebase(diff: diff, replyID: aID)
                           myNewLikesDislikesMap[aID] = -1
                     myLikesDislikesMap[aID] = -1
                           myUserMap[aID]=aReply.user
                       }
                   }
                   
               }
               
        
    }
    func upButtonPressedReply(aReply:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                       let diff = cell.upToNone(quipScore: aQuipScore,quip:  aReply)
                if let aID = aReply.quipID{
                           updateVotesFirebase(diff: diff, replyID: aID)
                           myNewLikesDislikesMap[aID]=0
                            myLikesDislikesMap[aID]=0
                          myUserMap[aID]=aReply.user
                           }
                           
                   }
                    }
                    else if cell.downButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                               let diff = cell.downToUp(quipScore: aQuipScore,quip:  aReply)
                if let aID = aReply.quipID{
                                   updateVotesFirebase(diff: diff, replyID: aID)
                                   myNewLikesDislikesMap[aID] = 1
                                    myLikesDislikesMap[aID] = 1
                                  myUserMap[aID]=aReply.user
                               }
                           }
                       }
                    else{
            if let aQuipScore = aReply.quipScore{
                       let diff = cell.noneToUp(quipScore: aQuipScore,quip:  aReply)
                if let aID = aReply.quipID{
                               updateVotesFirebase(diff: diff, replyID: aID)
                               myNewLikesDislikesMap[aID] = 1
                                myLikesDislikesMap[aID] = 1
                              myUserMap[aID]=aReply.user
                           }
                       }
                    }
        
    }
    
    func updateVotesFirebase(diff:Int, replyID:String){
        //increment value has to be double or long or it wont work properly
        let myDiff = Double(diff)
        if let aQuipKey = myQuip?.quipID {
           myVotes["Q/\(aQuipKey)/R/\(replyID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
           
           if let aUID = uid {
           myVotes["M/\(aUID)/q/\(replyID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
       }
    
    func updateFirestoreLikesDislikes(){
         
        if let aUID = uid {
            if let quipKey = myQuip?.quipID {
                   let docRef = db?.collection("/Users/\(aUID)/LikesDislikes").document(quipKey)
                    let batch = self.db?.batch()
                                 batch?.setData(myNewLikesDislikesMap, forDocument: docRef!, merge: true)
                                 
                                 for aKey in myNewLikesDislikesMap.keys{
                                     if let myUser = myUserMap[aKey]{
                                        let docRefChannel = db?.collection("/Users/\(aUID)/LikesDislikes").document(myUser)
                                        batch?.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel!, merge: true)
                                                                       }
                                     
                                 }
                                    batch?.commit()
            }
        }
       }
    
    func getUserLikesDislikesForQuip(){
          // let myRef = "Users/\(uid ?? "Other")/LikesDislikes"
        if let aUID = uid, let aQuipKey = myQuip?.quipID {
           let docRef = db?.collection("/Users/\(aUID)/LikesDislikes").document(aQuipKey)
                  
              
                  docRef?.getDocument{ (document, error) in
                      if let document = document, document.exists {
                       if let myMap = document.data() as? [String:Int]{
                             self.myLikesDislikesMap=myMap
                         }
                         
                       
                        
                       } else {
                        self.myLikesDislikesMap = [:]
                       }
                    self.updateReplies()
                  }
        }
           
       }
    
    func downButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.upToDown(quipScore: myQuipScore,quip: aQuip)
                    if let myPassedQuipCell = passedQuipCell{
                        diff = myPassedQuipCell.upToDown(quipScore: myQuipScore, quip:aQuip)
                    }
                }
             if let aID = aQuip.quipID{
                if let myParent = parentViewFeed {
                    myParent.updateVotesFirebase(diff: diff, quipID: aID)
                    myParent.myNewLikesDislikesMap[aID] = -1
                     myParent.myLikesDislikesMap[aID] = -1
                    myParent.myUserMap[aID] = aQuip.user
                    
                }else if let myParent = parentViewUser{
                    myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    myParent.myNewLikesDislikesMap[aID] = -1
                    myParent.myLikesDislikesMap[aID] = -1
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                    myParent.myParentChannelsMap[aID] = aQuip.parentKey
                    
                }
            }
           
           }
           else if cell.downButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.downToNone(quipScore: myQuipScore,quip: aQuip)
                    if let myPassedQuipCell = passedQuipCell{
                               diff = myPassedQuipCell.downToNone(quipScore: myQuipScore,quip: aQuip)
                                
                               }
                }
             if let aID = aQuip.quipID{
                if let myParent = parentViewFeed {
                    myParent.updateVotesFirebase(diff: diff, quipID: aID)
                    myParent.myNewLikesDislikesMap[aID]=0
                     myParent.myLikesDislikesMap[aID]=0
                     myParent.myUserMap[aID] = aQuip.user
                }
                else if let myParent = parentViewUser{
                    myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    myParent.myNewLikesDislikesMap[aID]=0
                    myParent.myLikesDislikesMap[aID]=0
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                    myParent.myParentChannelsMap[aID] = aQuip.parentKey
                }
            }
           }
           else{
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.noneToDown(quipScore: myQuipScore,quip: aQuip)
                        if let myPassedQuipCell = passedQuipCell{
                           diff = myPassedQuipCell.noneToDown(quipScore: myQuipScore,quip: aQuip)
                        }
                }
             if let aID = aQuip.quipID{
                if let myParent = parentViewFeed{
                    myParent.updateVotesFirebase(diff: diff, quipID: aID)
                    myParent.myNewLikesDislikesMap[aID] = -1
                     myParent.myLikesDislikesMap[aID] = -1
                     myParent.myUserMap[aID] = aQuip.user
                }
                else if let myParent = parentViewUser{
                    myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    myParent.myNewLikesDislikesMap[aID] = -1
                     myParent.myLikesDislikesMap[aID] = -1
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                                       myParent.myParentChannelsMap[aID] = aQuip.parentKey
                }
            }
           }
           
       }
       func upButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.upToNone(quipScore:myQuipScore,quip: aQuip)
                        if let myPassedQuipCell = passedQuipCell{
                           diff = myPassedQuipCell.upToNone(quipScore:myQuipScore,quip: aQuip)
                                   
                        }
                }
            if let aID = aQuip.quipID{
                if let myParent = parentViewFeed{
                    myParent.updateVotesFirebase(diff: diff, quipID: aID)
                    myParent.myNewLikesDislikesMap[aID]=0
                    myParent.myLikesDislikesMap[aID]=0
                     myParent.myUserMap[aID] = aQuip.user
                }else if let myParent = parentViewUser{
                    myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    myParent.myNewLikesDislikesMap[aID]=0
                    myParent.myLikesDislikesMap[aID]=0
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                                       myParent.myParentChannelsMap[aID] = aQuip.parentKey
                }
            }
           }
           else if cell.downButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.downToUp(quipScore:myQuipScore,quip: aQuip)
                    if let myPassedQuipCell = passedQuipCell{
                      diff = myPassedQuipCell.downToUp(quipScore:myQuipScore,quip: aQuip)
                    }
                }
                if let aID = aQuip.quipID{
                    if let myParent = parentViewFeed{
                        
                        myParent.updateVotesFirebase(diff: diff, quipID: aID)
                        myParent.myNewLikesDislikesMap[aID] = 1
                         myParent.myLikesDislikesMap[aID] = 1
                        myParent.myUserMap[aID] = aQuip.user
                    }else if let myParent = parentViewUser{
                        myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                        myParent.myNewLikesDislikesMap[aID] = 1
                        myParent.myLikesDislikesMap[aID] = 1
                        myParent.myChannelsMap[aID] = aQuip.channelKey
                                           myParent.myParentChannelsMap[aID] = aQuip.parentKey
                    }
                }
            }
           else{
                    var diff = 0
                    if let myQuipScore = aQuip.quipScore {
                            diff = cell.noneToUp(quipScore: myQuipScore,quip: aQuip)
                            if let myPassedQuipCell = passedQuipCell{
                               diff = myPassedQuipCell.noneToUp(quipScore: myQuipScore,quip: aQuip)
                            }
                    }
                    if let aID = aQuip.quipID{
                        if let myParent = parentViewFeed{
                               
                                myParent.updateVotesFirebase(diff: diff, quipID: aID)
                                myParent.myNewLikesDislikesMap[aID] = 1
                            myParent.myLikesDislikesMap[aID] = 1
                                myParent.myUserMap[aID] = aQuip.user
                        }
                        else if let myParent = parentViewUser{
                            myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                                myParent.myNewLikesDislikesMap[aID] = 1
                                myParent.myLikesDislikesMap[aID] = 1
                            myParent.myChannelsMap[aID] = aQuip.channelKey
                                               myParent.myParentChannelsMap[aID] = aQuip.parentKey
                        }
                    }
            }
           
       }
 
   
    func setUpImageView(){
        imageView?.removeFromSuperview()
        
          imageView = UIImageView()
          stackView.addSubview(imageView!)
          imageView?.translatesAutoresizingMaskIntoConstraints = false
          let leadingSpace = NSLayoutConstraint(item: imageView!, attribute: .leading, relatedBy: .equal, toItem: stackView, attribute: .leading, multiplier: 1, constant: 4)
          imageViewSpaceToBottom = NSLayoutConstraint(item: imageView!, attribute: .bottom, relatedBy: .equal, toItem: imageView!, attribute: .bottom, multiplier: 1, constant: 4)
          imageTrailingSpace = NSLayoutConstraint(item: stackView!, attribute: .trailing, relatedBy: .equal, toItem: imageView!, attribute: .trailing, multiplier: 1, constant: 4)
          let topSpace = NSLayoutConstraint(item: imageView!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1, constant: 8)
         
          stackView.addConstraints([leadingSpace,topSpace, imageTrailingSpace!, imageViewSpaceToBottom!])
          
          imageView?.isHidden=true
          imageView?.contentMode = UIView.ContentMode.scaleAspectFit
         
          
      }
    
    func resetGiphyView(){
       
               self.view.addConstraints([giphyTrailingSpace!,giphyBottomSpaceConstraint!])
        
    }
    
    func saveReply(){
            var imageRef:String?
               var hasImage:Bool=false
               var gifID:String?
               var hasGif:Bool=false
        if imageView?.image != nil  && imageView?.isHidden==false{
                   if true { //send to google sensor api
                       hasImage=true
                       let randomID = UUID.init().uuidString
                       imageRef = "\(uid ?? "Other")/\(randomID)"
                       let uploadref = storageRef?.child(imageRef!)
                       guard let imageData = imageView?.image?.jpegData(compressionQuality: 0.75) else {print("error getting image")
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
         guard let key = ref?.child("replies").childByAutoId().key else { return }
             
        var post2 = [   "t": textView.text ?? "",
                        "a": uid ?? "Other",
                        "d": FieldValue.serverTimestamp(),
                        "r": true] as [String : Any]
                   
               if hasImage {
                   
                   post2["i"]=imageRef
               }
               else if hasGif{
                  
                   post2["g"]=gifID
               }
                   
        
         addReplyToFirestore(key: key, data: post2)
        
        
         
        
     }
    
    func addReplyToFirestore(key:String, data:[String:Any]){
        let mydata = data
        
        let repliesQuipsRef = self.db?.collection("/Quips/\(myQuip?.quipID ?? "Other")/Replies").document("RecentReplies")

                             let batch = self.db?.batch()
                             batch?.setData([key : mydata], forDocument: repliesQuipsRef!, merge: true)
                            batch?.commit()
                             addReplyToFirebase(key: key)
                            runTransactionForRecentUser(data: mydata, key: key)
                     
                        
                 
         
         
        
        
        
    }
    func runTransactionForRecentUser(data:[String:Any], key: String){
            var mydata = data
            mydata["reply"] = true
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
        textView.text = "Type something"
        textView.resignFirstResponder()
        if imageView?.image != nil || mediaView?.media != nil{
            adjustStackViewHeigt(height: -210)
        }
        mediaView?.removeFromSuperview()
        imageView?.removeFromSuperview()
        
        updateReplies()
    }
    
    @objc func refreshData(){
        refreshControl.beginRefreshing()
        getUserLikesDislikesForQuip()
    }
 
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return myReplies.count + 1
     }
     
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
          
         if indexPath.row == 0 {
             if let cell = replyTable.dequeueReusableCell(withIdentifier: "mainQuip", for: indexPath) as? QuipCells{
             if let myImageRef = myQuip?.imageRef  {
                     cell.addImageViewToTableCell()
                 if let aStorageRef = storageRef{
                     cell.myImageView.getImage(myQuipImageRef: myImageRef, storageRef: aStorageRef, feedTable: self.replyTable)
                 }
             }
                                                                                        
             else if let aGifID = myQuip?.gifID{
                     cell.addGifViewToTableCell()
                 cell.myGifView.getImageFromGiphy(gifID: aGifID, feedTable:self.replyTable)
                                                             
             }
             if self.quipLikeStatus == true {
                 cell.upButton.isSelected = true
                  cell.upButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
             }else if self.quipLikeStatus == false{
                 cell.downButton.isSelected = true
                  cell.downButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
             }
             cell.score.text = self.quipScore
             cell.quipText?.text = myQuip?.quipText
             let dateVal = myQuip?.timePosted?.seconds
             let milliTimePost = (dateVal)! * 1000
             cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                 cell.upButton.changeButtonWeight()
                 cell.downButton.changeButtonWeight()
             cell.delegate = self
             return cell
             }
             
         }
         else{
             if let cell = replyTable.dequeueReusableCell(withIdentifier: "replyCell", for: indexPath) as? QuipCells{
         
                
               if myReplies.count > 0 {
                 if let aReply = self.myReplies[indexPath.row - 1] {
                     if let myImageRef = aReply.imageRef {
                         if let aStorageRef = storageRef{
                         cell.addImageViewToTableCell()
                         cell.myImageView.getImage(myQuipImageRef: myImageRef, storageRef: aStorageRef, feedTable: self.replyTable)
                         }
                                                                                     
                 }
                                                                             
                     else if let aGID = aReply.gifID {
                                                                                            
                             cell.addGifViewToTableCell()
                             cell.myGifView.getImageFromGiphy(gifID: aGID, feedTable:self.replyTable)
                                                                                                                                      
                 }
                         cell.quipText?.text = aReply.quipText
                             if let aReplyScore=aReply.tempScore{
                                     cell.score?.text = String(aReplyScore)
                             }
                     if let dateVal = (aReply.timePosted?.seconds){
                         let milliTimePost = dateVal * 1000
                         if let currentTime = self.currentTime{
                         cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: currentTime)
                         }
                     }
                     if let aID = aReply.quipText{
                     if self.myLikesDislikesMap[aID] == 1{
                                     cell.upButton.isSelected=true
                            
                            
                             cell.upButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                         }
                         else if self.myLikesDislikesMap[aID] == -1{
                                     cell.downButton.isSelected=true
                                           cell.downButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                         }
                 }
                 }
               }
             else{
                     return cell
                 }
                 cell.upButton.changeButtonWeight()
                 cell.downButton.changeButtonWeight()
         cell.delegate = self
         return cell
         }
     }
         return UITableViewCell()
     }
     
     

    
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
         writeReply = segue.destination as? ViewControllerWriteReply
         writeReply?.myQuip = self.myQuip
         writeReply?.ref=self.ref
         writeReply?.uid=self.uid
         writeReply?.db = self.db
         writeReply?.storageRef = self.storageRef
         writeReply?.myChannel=self.myChannel
                
               
     }
    

}
extension ViewControllerQuip: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func showImagePickerController(){
        let imagePickerController = UIImagePickerController()
           imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController,animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        setUpImageView()
        
        if mediaView?.isHidden == false || imageView?.isHidden == false {
             isNewImage = false
        }
        mediaView?.isHidden=true
        imageView?.isHidden=false
        if let myImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView?.translatesAutoresizingMaskIntoConstraints=false
            let newImage = resizeImage(image: myImage, targetSize: CGSize(width: (textView.frame.size.width), height: 200))
            if imageViewSpaceToBottom != nil {
                imageViewSpaceToBottom!.isActive = false
            }
            imageView?.image = newImage
            if imageTrailingSpace != nil {
                imageTrailingSpace!.isActive = false
            }
            
            imageView?.layer.cornerRadius = 8
            imageView?.clipsToBounds = true
        }
        if isNewImage{
            adjustStackViewHeigt(height: 210)
            isNewImage = false
        }
        
        dismiss(animated: true, completion: nil)

    }
    
    
  
}

extension ViewControllerQuip: GiphyDelegate {
   func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia)   {
   
    setUpGiphyView()
    
    if mediaView?.isHidden == false || imageView?.isHidden == false {
         isNewImage = false
    }
    mediaView?.isHidden = false
    imageView?.isHidden = true
    
    mediaView?.media = media
    if giphyBottomSpaceConstraint != nil {
        giphyBottomSpaceConstraint?.isActive = false
    }
    if giphyTrailingSpace != nil{
        giphyTrailingSpace?.isActive = false
    }
    let height = textView.frame.width * (1/media.aspectRatio)
    if media.aspectRatio > 1 && height <= 200 {
        mediaView?.widthAnchor.constraint(equalToConstant: textView.frame.width).isActive = true
        
        mediaView?.heightAnchor.constraint(equalTo: mediaView!.widthAnchor, multiplier: 1/media.aspectRatio).isActive = true
        
    }
    else {
        mediaView?.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        mediaView?.widthAnchor.constraint(equalTo: mediaView!.heightAnchor, multiplier: media.aspectRatio).isActive = true
        
    }
    
    
    mediaView?.layer.cornerRadius = 8.0
    mediaView?.clipsToBounds = true
    
   
    if isNewImage {
    adjustStackViewHeigt(height: 210)
        isNewImage = false
    }
        
        // your user tapped a GIF!
        giphyViewController.dismiss(animated: true, completion: nil)
   
     
   }
   
   func didDismiss(controller: GiphyViewController?) {
        // your user dismissed the controller without selecting a GIF.
   }
}
