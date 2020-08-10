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

class ViewControllerQuip: myUIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, MyCellDelegate{
    
    
    
    

    let shareText = "Check out this crack on pnut!"
    var myQuip:Quip?
    var passedReply:Quip?
    weak var myChannel:Channel?
    var uid:String?
    var mediaView:GPHMediaView?
    var imageView:UIImageView?
    var deleteBtn:UIButton?
    var giphyBottomSpaceConstraint:NSLayoutConstraint?
    var giphyTrailingSpace:NSLayoutConstraint?
    var imageViewSpaceToBottom:NSLayoutConstraint?
    var imageTrailingSpace:NSLayoutConstraint?
    private var isNewImage = true
    var currentTime:Double?
    var quipLikeStatus:Bool?
    var quipScore:String?
    private var replyScores:[String:Int] = [:]
    private var myReplies:[Quip?] = []
    private var origBottom:CGFloat?
    weak var parentViewFeed:ViewControllerFeed?
    weak var parentViewUser:ViewControllerUser?
  //  weak var passedQuipCell:QuipCells?
    private var myVotes:[String:Any] = [:]
    private var myLikesDislikesMap:[String:Int] = [:]
    private var myNewLikesDislikesMap:[String:Int] = [:]
    var myUserMap:[String:String] = [:]
    var parentIsNew:Bool?
    private var refreshControl = UIRefreshControl()
    private var cellHeights = [IndexPath: CGFloat]()
    lazy var MenuLauncher:ellipsesMenuQuip = {
              let launcher = ellipsesMenuQuip()
           launcher.quipController = self
               return launcher
          }()
    let placeHolderText = "Reply to this crack"
    let blackView = UIView()
    var activityIndicator:UIActivityIndicatorView?
    var hiddenPosts:[String:Bool] = [:]

    @IBOutlet weak var replyTable: UITableView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var postReplyView: UIView!
    
    @IBOutlet weak var postBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addGesture()
        replyTable.delegate=self
        replyTable.dataSource=self
        self.replyTable.rowHeight = UITableView.automaticDimension
        self.replyTable.estimatedRowHeight = 500.0
        refreshControl.addTarget(self, action: #selector(ViewControllerQuip.refreshData), for: .valueChanged)
        replyTable.refreshControl=refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    
        textView.layer.cornerRadius = 8.0
        
        textView.delegate = self
        textView.textColor = UIColor.lightGray
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.tintColorDidChange()
        textView.isScrollEnabled = false
        textView.textContainer.maximumNumberOfLines = 10
        textView.textContainer.lineBreakMode = .byClipping
       // hideKeyboardWhenTappedAround()
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
        
      
    }
    func resetVars(){
        myUserMap=[:]
           myNewLikesDislikesMap=[:]
           myVotes=[:]
       }
    func makeViewFade(){
              if let window = UIApplication.shared.keyWindow{
                     
                       
                         blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
                     window.addSubview(blackView)
                     blackView.frame = window.frame
                         blackView.alpha = 1
                         
                         
                     }
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
        g.theme = GPHTheme(type: .automatic)
               g.layout = .waterfall
               g.mediaTypeConfig = [.gifs, .recents]
               g.showConfirmationScreen = true
               g.rating = .ratedPG13
               g.delegate = self
               present(g, animated: true, completion: nil)
        
    }
    
    
    
    @IBAction func postButtonClicked(_ sender: UIButton) {
        refreshControl.beginRefreshing()
        postBtn.isEnabled = false
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
        saveReply()
    }
    
    @IBAction func ellipsesBarButtonClicked(_ sender: Any) {
        MenuLauncher.setVars(quipController: self, myQuip: myQuip)
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
        
    }
    
    
    
    func updateReplies(){
        self.replyScores = [:]
        self.myReplies = []
        if let quipID = myQuip?.quipID{
        FirebaseService.sharedInstance.getReplyScores(quipId: quipID) { (currentTime, replyScores) in
                self.currentTime = currentTime
                self.replyScores = replyScores
                if replyScores.count > 0 {
                 self.getFirestoreReplies()
                }else{
                    self.replyTable.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
                  
        }
           
       }
    
    
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
             DispatchQueue.main.async {
               textView.selectedRange = NSMakeRange(0, 0)
               
             
         }
        
        
           textView.inputAccessoryView = toolBar
           return true
       }
   
    
    
       
       func textViewDidChange(_ textView: UITextView) {
      //  print(textView.tintColor)
           if textView.text.isEmpty {
               textView.text = placeHolderText
               textView.textColor = .gray
               self.adjustTextViewHeight()
           } else {
            if textView.text == placeHolderText{
                textView.textColor = .gray
            }else{
                if #available(iOS 13.0, *) {
                    textView.textColor = .label
                } else {
                    // Fallback on earlier versions
                    textView.textColor = .black
                }
            }
               self.adjustTextViewHeight()
           }
       }
       func adjustTextViewHeight() {
       
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
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.stackView.layoutIfNeeded()
                              }, completion: nil)
       
        
        
    }

       func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
           
           if text.isEmpty {
               let updatedText = (textView.text as NSString).replacingCharacters(in: range, with: text)
               if updatedText.isEmpty {
                   textView.text = placeHolderText
                   textView.textColor = .gray
                   textView.selectedRange = NSRange(location: 0, length: 0)
               }
           } else {
               if textView.text == placeHolderText{
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
    
    func getFirestoreReplies(){
        
        if let aQuipID = myQuip?.quipID{
            FirestoreService.sharedInstance.getReplies(quipID: aQuipID, replyScores: replyScores) {[weak self] (myReplies) in
                self?.myReplies = myReplies
                self?.checkForHiddenPosts()
                self?.replyTable.reloadData()
                self?.refreshControl.endRefreshing()
            }
        }
        
        
        
        
    }
    
    func checkForHiddenPosts(){
        var i = 0
        for aQuip in myReplies{
            if let myID = aQuip?.quipID{
                if hiddenPosts[myID] == true{
                    myReplies.remove(at: i)
                }else if blockedUsers[aQuip?.user ?? "Other"] == true{
                    myReplies.remove(at: i)
                }
                else{
                    i = i + 1
                }
            
            }
            
        }
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
    func btnRepliesTapped(cell: QuipCells) {
        
    }
    
    func btnEllipsesTapped(cell: QuipCells) {
        
        if let indexPath = self.replyTable.indexPath(for: cell){
                                         
                if let myQuip = myReplies[indexPath.row - 1]{
                        MenuLauncher.setVars(quipController: self, myQuip: myQuip)
                }
                                              
                                          
        }
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
    }
    
    func showNextControllerReply(menuItem:MenuItem, quip:Quip){
        if menuItem.name == "View User's Profile"{
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ViewControllerUser") as! ViewControllerUser
            nextViewController.uid = uid
            nextViewController.uidProfile = quip.user
            navigationController?.pushViewController(nextViewController, animated: true)
        }else if menuItem.name == "Report Quip"{
            FirestoreService.sharedInstance.reportQuip(quip: quip)
            displayMsgBoxReport()
        }else if menuItem.name == "Share Quip"{
            generateDynamicLink(aquip: quip, cell: nil)
        }else if menuItem.name == "Delete Quip"{
            if let aQuipID = quip.quipID{
                           FirestoreService.sharedInstance.deleteQuip(quipID: aQuipID){
                        
                               self.updateReplies()
                           }
                       }
        }else if menuItem.name == "Hide This Post From Me"{
            displayHidePost(quip: quip)
               
            
        }else if menuItem.name == "Block This User"{
            displayBlockUser(quip: quip)
        }
        
    }
    
    func displayHidePost(quip:Quip){
          let message = "Are you sure you want to hide this post? This action cannot be undone."
          //create alert
          let alert = UIAlertController(title: "Hide Post", message: message, preferredStyle: .alert)
          
          //create Decline button
          let declineAction = UIAlertAction(title: "Hide Post" , style: .destructive){ (action) -> Void in
              //DECLINE LOGIC GOES HERE
             if let aQuipID = quip.quipID{
                if let auid = self.uid {
                                if let channelKey = quip.channelKey{
                                    let parentChannelKey = quip.parentKey
                                        if let quipAuthor = quip.user{
                                            FirestoreService.sharedInstance.addQuipToUsersHiddenPost(quipID: aQuipID, uid: auid, channelkey: channelKey, parentChannelKey: parentChannelKey, quipParentKey: nil, quipAuthoruid: quipAuthor) {
                                                self.updateReplies()
                                            }
                                           
                            
                            }
                            }
                            }
                            }
          }
          
          //create Accept button
          let acceptAction = UIAlertAction(title: "Cancel", style: .default) { (action) -> Void in
              //ACCEPT LOGIC GOES HERE
          }
          
          //add task to tableview buttons
          alert.addAction(declineAction)
          alert.addAction(acceptAction)
    
          self.present(alert, animated: true, completion: nil)
          
      }
    func displayBlockUser(quip:Quip){
          let message = "Are you sure you want to block this user? You will not be able to view any past or future posts from this user. This action cannot be undone."
          //create alert
          let alert = UIAlertController(title: "Block User", message: message, preferredStyle: .alert)
          
          //create Decline button
          let declineAction = UIAlertAction(title: "Block User" , style: .destructive){ (action) -> Void in
              //DECLINE LOGIC GOES HERE
            if let ablockID = quip.user{
                if let auid = self.uid {
            FirestoreService.sharedInstance.addBlockedUser(uid: auid, blockedUid: ablockID)
                }
            }
          }
          
          //create Accept button
          let acceptAction = UIAlertAction(title: "Cancel", style: .default) { (action) -> Void in
              //ACCEPT LOGIC GOES HERE
          }
          
          //add task to tableview buttons
          alert.addAction(declineAction)
          alert.addAction(acceptAction)
    
          self.present(alert, animated: true, completion: nil)
          
      }
    
    func generateDynamicLink(aquip:Quip, cell: QuipCells?){
           var components = URLComponents()
           var eventparentIDQueryItem2:URLQueryItem?
           components.scheme = "https"
           components.host = "anonapp.page.link"
           components.path = "/quips"
            let eventIDQueryItem3 = URLQueryItem(name: "eventid", value: aquip.channelKey)
           if let parentEventKey = aquip.parentKey{
               eventparentIDQueryItem2 = URLQueryItem(name: "parenteventid", value: parentEventKey)
           }
           
           
           let eventNameQueryItem1 = URLQueryItem(name: "eventname", value: aquip.channel?.encodeUrl())
           let quipIDQueryItem4 = URLQueryItem(name: "quipid", value: aquip.quipID)
           if let parentqueryitem = eventparentIDQueryItem2{
           components.queryItems = [eventNameQueryItem1,parentqueryitem, eventIDQueryItem3,quipIDQueryItem4]
           }else{
               components.queryItems = [eventNameQueryItem1, eventIDQueryItem3,quipIDQueryItem4]
           }
           guard let linkparam = components.url else {return}
           print(linkparam)
           let dynamicLinksDomainURIPrefix = "https://anonapp.page.link"
           guard let sharelink = DynamicLinkComponents.init(link: linkparam, domainURIPrefix: dynamicLinksDomainURIPrefix) else {return}
           if let bundleId = Bundle.main.bundleIdentifier {
               sharelink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
           }
           //change to app store id
           sharelink.iOSParameters?.appStoreID = appStoreID
           sharelink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        sharelink.socialMetaTagParameters?.imageURL = logoURL
           sharelink.socialMetaTagParameters?.title = aquip.quipText
           sharelink.socialMetaTagParameters?.descriptionText = aquip.channel
           if let myImage = aquip.imageRef {
                FirebaseStorageService.sharedInstance.getDownloadURL(imageRef: myImage, completion: {[weak self] (url) in
                   print(url)
                   
                   sharelink.socialMetaTagParameters?.imageURL = url
                    guard sharelink.url != nil else { return }
                    sharelink.shorten {[weak self] (url, warnings, error) in
                                  if let error = error{
                                      print(error)
                                      return
                                  }
                                  if let warnings = warnings{
                                      for warning in warnings{
                                          print(warning)
                                      }
                                  }
                                  guard let url = url else {return}
                                   
                                  self?.showShareViewController(url: url)
                              }
               })
           }else if let myGif = aquip.gifID {
                   GiphyCore.shared.gifByID(myGif) { (response, error) in
                       if let media = response?.data {
                           if let gifURL = media.url(rendition: .fixedWidthStill, fileType: .gif){
                           print(gifURL)
                           sharelink.socialMetaTagParameters?.imageURL = URL(string: gifURL)
                           }
                       }
                       guard let longDynamicLink = sharelink.url else { return }
                       print("The long URL is: \(longDynamicLink)")
                           sharelink.shorten {[weak self] (url, warnings, error) in
                               if let error = error{
                                   print(error)
                                   return
                               }
                               if let warnings = warnings{
                                   for warning in warnings{
                                       print(warning)
                                   }
                               }
                               guard let url = url else {return}
                               print(url)
                               self?.showShareViewController(url: url)
                           }
               }
               
           }
           else {
               guard let longDynamicLink = sharelink.url else { return }
               print("The long URL is: \(longDynamicLink)")
                   sharelink.shorten {[weak self] (url, warnings, error) in
                       if let error = error{
                           print(error)
                           return
                       }
                       if let warnings = warnings{
                           for warning in warnings{
                               print(warning)
                           }
                       }
                       guard let url = url else {return}
                       print(url)
                       self?.showShareViewController(url: url)
                   }
           
           
               
           }
        Analytics.logEvent(AnalyticsEventShare, parameters:
                  [AnalyticsParameterItemID:"id- \(aquip.quipID ?? "Other")",
                      AnalyticsParameterItemName: aquip.quipText ?? "None",
                      AnalyticsParameterContentType: "quip"])
       }
       
       func showShareViewController(url:URL){
           let myactivity1 = shareText
           let myactivity2 = url
                                
                           
                                  // set up activity view controller
           let firstactivity = [myactivity1, myactivity2] as [Any]
                           let activityViewController = UIActivityViewController(activityItems: firstactivity, applicationActivities: nil)
                                 activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

                                  // exclude some activity types from the list (optional)
                           activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]

                                  // present the view controller
                                  self.present(activityViewController, animated: true, completion: nil)
       }
    
    func displayMsgBoxReport(){
       let title = "Report Successful"
       let message = "The user has been reported. If you want to give us more details on this incident please email us at quipitinc@gmail.com"
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
       }
       
    
    func downButtonPressedReply(aReply:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                let diff = cell.upToDown(quipScore: aQuipScore, quip: aReply)
                
                if let aID = aReply.quipID{
                    if let auid = aReply.user{
                               
                               myNewLikesDislikesMap[aID] = -1
                    myLikesDislikesMap[aID] = -1
                    myUserMap[aID]=aReply.user
                        updateVotesFirebase(diff: diff, reply: aReply, aUID: auid)
                 if let myParent = parentViewUser{
                                                                              
                                myParent.myNewLikesDislikesMap[aID] = -1
                            myParent.myLikesDislikesMap[aID] = -1
                                                                               
                            
                                    myParent.checkHotQuips(myQuipID: aID, isUp: false)
                              
                                    myParent.checkNewQuips(myQuipID: aID, isUp: false)
                               
                    }
                    }
                           }
                   }
               }
               else if cell.downButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                           let diff = cell.downToNone(quipScore: aQuipScore,quip: aReply)
                
                if let aID = aReply.quipID{
                              if let auid = aReply.user{
                               
                               myNewLikesDislikesMap[aID]=0
                                myLikesDislikesMap[aID]=0
                              myUserMap[aID]=aReply.user
                                updateVotesFirebase(diff: diff, reply: aReply, aUID: auid)
                                if let myParent = parentViewUser{
                                                                                                             
                                                               myParent.myNewLikesDislikesMap[aID] = 0
                                                           myParent.myLikesDislikesMap[aID] = 0
                                                                                                              
                                                           
                                                                   myParent.checkHotQuips(myQuipID: aID, isUp: false)
                                                               
                                                                   myParent.checkNewQuips(myQuipID: aID, isUp: false)
                                                             
                                                   }
                    }
                           }
                       
                   }
               }
               else{
            if let aQuipScore = aReply.quipScore{
                       let diff = cell.noneToDown(quipScore: aQuipScore,quip:  aReply)
               
                if let aID = aReply.quipID{
                           if let auid = aReply.user{
                          
                           myNewLikesDislikesMap[aID] = -1
                     myLikesDislikesMap[aID] = -1
                           myUserMap[aID]=aReply.user
                             updateVotesFirebase(diff: diff, reply: aReply, aUID: auid)
                            if let myParent = parentViewUser{
                                                                                                         
                                                           myParent.myNewLikesDislikesMap[aID] = -1
                                                       myParent.myLikesDislikesMap[aID] = -1
                                                                                                          
                                                       
                                                               myParent.checkHotQuips(myQuipID: aID, isUp: false)
                                                           
                                                               myParent.checkNewQuips(myQuipID: aID, isUp: false)
                                                            
                                               }
                    }
                       }
                   }
                   
               }
               
        
    }
    
    
    
    func upButtonPressedReply(aReply:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                       let diff = cell.upToNone(quipScore: aQuipScore,quip:  aReply)
               
                if let aID = aReply.quipID{
                          if let auid = aReply.user{
                           
                           myNewLikesDislikesMap[aID]=0
                            myLikesDislikesMap[aID]=0
                          myUserMap[aID]=aReply.user
                            updateVotesFirebase(diff: diff, reply: aReply, aUID: auid)
                            if let myParent = parentViewUser{
                               
                                myParent.myNewLikesDislikesMap[aID]=0
                                myParent.myLikesDislikesMap[aID]=0
                                
                                
                                    myParent.checkHotQuips(myQuipID: aID, isUp: true)
                               
                                    myParent.checkNewQuips(myQuipID: aID, isUp: true)
                               
                            }
                    }
                           }
                           
                   }
                    }
                    else if cell.downButton.isSelected {
            if let aQuipScore = aReply.quipScore{
                               let diff = cell.downToUp(quipScore: aQuipScore,quip:  aReply)
               
                if let aID = aReply.quipID{
                                   if let auid = aReply.user{
                                   
                                   myNewLikesDislikesMap[aID] = 1
                                    myLikesDislikesMap[aID] = 1
                                  myUserMap[aID]=aReply.user
                                    updateVotesFirebase(diff: diff, reply: aReply, aUID: auid)
                                    if let myParent = parentViewUser{
                                                                  
                                                                   myParent.myNewLikesDislikesMap[aID]=1
                                                                   myParent.myLikesDislikesMap[aID]=1
                                                                   
                                                                  
                                                                       myParent.checkHotQuips(myQuipID: aID, isUp: true)
                                                                  
                                                                       myParent.checkNewQuips(myQuipID: aID, isUp: true)
                                                                   
                                                               }
                    }
                               }
                           }
                       }
                    else{
            if let aQuipScore = aReply.quipScore{
                       let diff = cell.noneToUp(quipScore: aQuipScore,quip:  aReply)
               
                if let aID = aReply.quipID{
                              if let auid = aReply.user{
                               
                               myNewLikesDislikesMap[aID] = 1
                                myLikesDislikesMap[aID] = 1
                              myUserMap[aID]=aReply.user
                                updateVotesFirebase(diff: diff, reply: aReply, aUID: auid)
                                if let myParent = parentViewUser{
                                                              
                                                               myParent.myNewLikesDislikesMap[aID]=1
                                                               myParent.myLikesDislikesMap[aID]=1
                                                               
                                                               
                                                                   myParent.checkHotQuips(myQuipID: aID, isUp: true)
                                                               
                                                                   myParent.checkNewQuips(myQuipID: aID, isUp: true)
                                                              
                                                           }
                    }
                           }
                       }
                    }
        
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
          cellHeights[indexPath] = cell.frame.size.height
      }

      func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
          return cellHeights[indexPath] ?? UITableView.automaticDimension
      }
    
    func updateVotesFirebase(diff:Int, reply:Quip, aUID:String){
        //increment value has to be double or long or it wont work properly
        let myDiff = Double(diff)
        if let aQuipKey = myQuip?.quipID {
            if let replyID = reply.quipID{
           myVotes["Q/\(aQuipKey)/R/\(replyID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
        }
        if let aUID = reply.user {
            if let replyID = reply.quipID{
           myVotes["M/\(aUID)/q/\(replyID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
            myVotes["M/\(aUID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
        }
        updateFirestoreLikesDislikes()
        FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
        resetVars()
       }
    
    func updateFirestoreLikesDislikes(){
         
        if let aUID = uid {
            if let quipKey = myQuip?.quipID {
                
                
                FirestoreService.sharedInstance.updateLikesDislikes(myNewLikesDislikesMap: myNewLikesDislikesMap, aChannelOrUserKey: quipKey, myMap: myUserMap, aUID: aUID, parentChannelKey: nil, parentChannelMap: nil, parentQuipsMap: nil)
                  
            }
        }
       }
    
    func loadParentQuip(aquipId:String){
        FirestoreService.sharedInstance.getQuip(quipID: aquipId) { [weak self](myQuip) in
        FirebaseService.sharedInstance.getQuipScore(aQuip: myQuip) {[weak self] (aQuip) in
        FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: (self?.uid)!, aKey: aQuip.user!) {[weak self] (myLikes) in
            if myLikes[aQuip.quipID!] == 1 {
                self?.quipLikeStatus=true
            }else if myLikes[aQuip.quipID!] == -1{
                self?.quipLikeStatus=false
            }
                self?.myQuip = aQuip
                self?.refreshData()
                                          
                                      }
                                     
                                  }
                              }
    }
    
    func getUserLikesDislikesForQuip(){
          // let myRef = "Users/\(uid ?? "Other")/LikesDislikes"
        
        if let aUID = uid, let aQuipKey = myQuip?.quipID {
            FirestoreService.sharedInstance.getHiddenPosts(uid: aUID, key: aQuipKey) {[weak self] (hiddenPosts) in
                self?.hiddenPosts = hiddenPosts
            }
            FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: aUID, aKey: aQuipKey) { [weak self](myLikesDislikesMap) in
                self?.myLikesDislikesMap = myLikesDislikesMap
                self?.updateReplies()
            }
        }
           
       }
    
    func downButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.upToDown(quipScore: myQuipScore,quip: aQuip)
                  
                }
             if let aID = aQuip.quipID{
                if let myParent = parentViewFeed {
                    if let aQuipUser = aQuip.user{
                    
                    myParent.myNewLikesDislikesMap[aID] = -1
                     myParent.myLikesDislikesMap[aID] = -1
                    myParent.myUserMap[aID] = aQuip.user
                        if aQuip.channelKey != myParent.myChannel?.key{
                                    myParent.childChannelMap[aID] = aQuip.channelKey
                            }
                        myParent.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aQuipUser)
                      
                            myParent.checkHotQuips(myQuipID: aID, isUp: false, change: diff)
                       
                        myParent.checkNewQuips(myQuipID: aID, isUp: false, change: diff)
                       
                    }
                }else if let myParent = parentViewUser{
                   
                    myParent.myNewLikesDislikesMap[aID] = -1
                    myParent.myLikesDislikesMap[aID] = -1
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                    myParent.myParentChannelsMap[aID] = aQuip.parentKey
                
                     myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    
                        myParent.checkHotQuips(myQuipID: aID, isUp: false)
                   
                        myParent.checkNewQuips(myQuipID: aID, isUp: false)
                    
                    
                }
            }
           
           }
           else if cell.downButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.downToNone(quipScore: myQuipScore,quip: aQuip)
                   
                }
             if let aID = aQuip.quipID{
                if let myParent = parentViewFeed {
                   if let aQuipUser = aQuip.user{
                   
                    myParent.myNewLikesDislikesMap[aID]=0
                     myParent.myLikesDislikesMap[aID]=0
                     myParent.myUserMap[aID] = aQuip.user
                    if aQuip.channelKey != myParent.myChannel?.key{
                            myParent.childChannelMap[aID] = aQuip.channelKey
                    }
                     myParent.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aQuipUser)
                    
                        myParent.checkHotQuips(myQuipID: aID, isUp: false, change: diff)
                   
                        myParent.checkNewQuips(myQuipID: aID, isUp: false, change: diff)
                    
                    }
                }
                else if let myParent = parentViewUser{
                   
                    myParent.myNewLikesDislikesMap[aID]=0
                    myParent.myLikesDislikesMap[aID]=0
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                    myParent.myParentChannelsMap[aID] = aQuip.parentKey
                     myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    
                        myParent.checkHotQuips(myQuipID: aID, isUp: false)
                    
                        myParent.checkNewQuips(myQuipID: aID, isUp: false)
                    
                }
            }
           }
           else{
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.noneToDown(quipScore: myQuipScore,quip: aQuip)
                        
                }
             if let aID = aQuip.quipID{
                if let myParent = parentViewFeed{
                   if let aQuipUser = aQuip.user{
                    
                    myParent.myNewLikesDislikesMap[aID] = -1
                     myParent.myLikesDislikesMap[aID] = -1
                     myParent.myUserMap[aID] = aQuip.user
                    if aQuip.channelKey != myParent.myChannel?.key{
                            myParent.childChannelMap[aID] = aQuip.channelKey
                    }
                    myParent.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aQuipUser)
                   
                        myParent.checkHotQuips(myQuipID: aID, isUp: false, change: diff)
                    
                        myParent.checkNewQuips(myQuipID: aID, isUp: false, change: diff)
                    
                    }
                }
                else if let myParent = parentViewUser{
                   
                    myParent.myNewLikesDislikesMap[aID] = -1
                     myParent.myLikesDislikesMap[aID] = -1
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                                       myParent.myParentChannelsMap[aID] = aQuip.parentKey
                     myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    if let aparentIsNew = parentIsNew{
                    if aparentIsNew{
                        myParent.checkHotQuips(myQuipID: aID, isUp: false)
                    }else{
                        myParent.checkNewQuips(myQuipID: aID, isUp: false)
                    }
                    }
                }
            }
           }
           
       }
       func upButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.upToNone(quipScore:myQuipScore,quip: aQuip)
                        
                }
            if let aID = aQuip.quipID{
                if let myParent = parentViewFeed{
                   if let aQuipUser = aQuip.user{
                   
                    myParent.myNewLikesDislikesMap[aID]=0
                    myParent.myLikesDislikesMap[aID]=0
                     myParent.myUserMap[aID] = aQuip.user
                    if aQuip.channelKey != myParent.myChannel?.key{
                            myParent.childChannelMap[aID] = aQuip.channelKey
                    }
                     myParent.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aQuipUser)
                   
                        myParent.checkHotQuips(myQuipID: aID, isUp: true, change: diff)
               
                        myParent.checkNewQuips(myQuipID: aID, isUp: true, change: diff)
                    
                    }
                }else if let myParent = parentViewUser{
                   
                    myParent.myNewLikesDislikesMap[aID]=0
                    myParent.myLikesDislikesMap[aID]=0
                    myParent.myChannelsMap[aID] = aQuip.channelKey
                                       myParent.myParentChannelsMap[aID] = aQuip.parentKey
                     myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                    if let aparentIsNew = parentIsNew{
                    if aparentIsNew{
                        myParent.checkHotQuips(myQuipID: aID, isUp: true)
                    }else{
                        myParent.checkNewQuips(myQuipID: aID, isUp: true)
                    }
                    }
                }
            }
           }
           else if cell.downButton.isSelected {
                var diff = 0
                if let myQuipScore = aQuip.quipScore {
                    diff = cell.downToUp(quipScore:myQuipScore,quip: aQuip)
                    
                }
                if let aID = aQuip.quipID{
                    if let myParent = parentViewFeed{
                        
                        if let aQuipUser = aQuip.user{
                       
                        myParent.myNewLikesDislikesMap[aID] = 1
                         myParent.myLikesDislikesMap[aID] = 1
                        myParent.myUserMap[aID] = aQuip.user
                            if aQuip.channelKey != myParent.myChannel?.key{
                                    myParent.childChannelMap[aID] = aQuip.channelKey
                            }
                             myParent.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aQuipUser)
                           
                                                  myParent.checkHotQuips(myQuipID: aID, isUp: true, change: diff)
                                              
                                                  myParent.checkNewQuips(myQuipID: aID, isUp: true, change: diff)
                                              
                        }
                    }else if let myParent = parentViewUser{
                       
                        myParent.myNewLikesDislikesMap[aID] = 1
                        myParent.myLikesDislikesMap[aID] = 1
                        myParent.myChannelsMap[aID] = aQuip.channelKey
                                           myParent.myParentChannelsMap[aID] = aQuip.parentKey
                         myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                        if let aparentIsNew = parentIsNew{
                        if aparentIsNew{
                            myParent.checkHotQuips(myQuipID: aID, isUp: true)
                        }else{
                            myParent.checkNewQuips(myQuipID: aID, isUp: true)
                        }
                        }
                    }
                }
            }
           else{
                    var diff = 0
                    if let myQuipScore = aQuip.quipScore {
                            diff = cell.noneToUp(quipScore: myQuipScore,quip: aQuip)
                          //  if let myPassedQuipCell = passedQuipCell{
                            //   diff = myPassedQuipCell.noneToUp(quipScore: myQuipScore,quip: aQuip)
                          //  }
                    }
                    if let aID = aQuip.quipID{
                        if let myParent = parentViewFeed{
                               if let aQuipUser = aQuip.user{
                               
                                myParent.myNewLikesDislikesMap[aID] = 1
                            myParent.myLikesDislikesMap[aID] = 1
                                myParent.myUserMap[aID] = aQuip.user
                                if aQuip.channelKey != myParent.myChannel?.key{
                                        myParent.childChannelMap[aID] = aQuip.channelKey
                                }
                                 myParent.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aQuipUser)
                              //  if let aparentIsNew = parentIsNew{
                                                 // if aparentIsNew{
                                                      myParent.checkHotQuips(myQuipID: aID, isUp: true, change: diff)
                                                //  }else{
                                                      myParent.checkNewQuips(myQuipID: aID, isUp: true, change: diff)
                                               //   }
                                     //             }
                            }
                        }
                        else if let myParent = parentViewUser{
                            
                                myParent.myNewLikesDislikesMap[aID] = 1
                                myParent.myLikesDislikesMap[aID] = 1
                            myParent.myChannelsMap[aID] = aQuip.channelKey
                                               myParent.myParentChannelsMap[aID] = aQuip.parentKey
                            myParent.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                        //    if let aparentIsNew = parentIsNew{
                       //     if aparentIsNew{
                                myParent.checkHotQuips(myQuipID: aID, isUp: true)
                        //    }else{
                                myParent.checkNewQuips(myQuipID: aID, isUp: true)
                       //     }
                       //     }
                        }
                    }
            }
           
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
    
    func addCancelImageButton(isGif:Bool){
         let width:CGFloat = 20
         deleteBtn = UIButton()
         self.stackView.addSubview(deleteBtn!)
         deleteBtn?.setImage(UIImage(named: "multiply")?.withRenderingMode(.alwaysTemplate), for: .normal)
         deleteBtn?.tintColor = .white
         deleteBtn?.backgroundColor = .black
         deleteBtn?.translatesAutoresizingMaskIntoConstraints = false
         deleteBtn?.widthAnchor.constraint(equalToConstant: width).isActive=true
         deleteBtn?.heightAnchor.constraint(equalToConstant:  width ).isActive = true
        if isGif{
         let mybuttonTopConstraint = NSLayoutConstraint(item: deleteBtn!, attribute: .top, relatedBy: .equal, toItem: mediaView, attribute: .top, multiplier: 1, constant: 10)
         let mybuttonSideConstraint = NSLayoutConstraint(item: deleteBtn!, attribute: .trailing, relatedBy: .equal, toItem: mediaView, attribute: .trailing, multiplier: 1, constant: -10)
             self.stackView.addConstraints([mybuttonTopConstraint,mybuttonSideConstraint])
        }else{
            let mybuttonTopConstraint = NSLayoutConstraint(item: deleteBtn!, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1, constant: 10)
            let mybuttonSideConstraint = NSLayoutConstraint(item: deleteBtn!, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .trailing, multiplier: 1, constant: -10)
                self.stackView.addConstraints([mybuttonTopConstraint,mybuttonSideConstraint])
        }
        
         deleteBtn?.addTarget(self, action: #selector(self.deleteImage), for: .touchUpInside)
         deleteBtn?.layer.cornerRadius = width / 2
         deleteBtn?.clipsToBounds = true
         
         self.stackView.bringSubviewToFront(deleteBtn!)
        
     }
     
     @objc func deleteImage(){
        adjustStackViewHeigt(height: -210)
        imageView?.removeFromSuperview()
         mediaView?.removeFromSuperview()
         deleteBtn?.removeFromSuperview()
        imageView?.isHidden = true
        mediaView?.isHidden = true
        isNewImage = true
        
         
     }
    
    func saveReply(){
            
              
               var gifID:String?
               var hasGif:Bool=false
        if imageView?.image != nil  && imageView?.isHidden==false{
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
                              
                            guard let imageData = self.imageView?.image?.jpegData(compressionQuality: 0.75) else {print("error getting image")
                              return
                           }
                           FirebaseStorageService.sharedInstance.uploadImage(imageRef: imageRef, imageData: imageData) { (isClean) in
                               if isClean{
                                  self.generatePost(hasImage: hasImage, hasGif: false, imageRef: imageRef, gifID: nil)
                               }else{
                                self.activityIndicator?.stopAnimating()
                                self.activityIndicator?.removeFromSuperview()
                                self.blackView.removeFromSuperview()
                                self.postBtn.isEnabled = true
                                   self.displayMsgBox()
                               }
                           }
           }
           
       }
       
          func displayMsgBox(){
           let title = "Inappropriate Image"
           let message = "We could not post your image becuase we have identified it has having inappropriate content.  If you want more information on this please email us at quipitinc@gmail.com"
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
       }
    
    func generatePost(hasImage:Bool, hasGif:Bool, imageRef:String?, gifID:String?){
        guard let key = FirebaseService.sharedInstance.generatePostKey() else { return }
                    var quipText = ""
                           
                           if textView.text != placeHolderText {
                               quipText = textView.text
                           }
               var post2 = [   "t": quipText,
                               "a": uid ?? "Other",
                               "d": FieldValue.serverTimestamp(),
                               "r": true,
                               "p": myQuip?.quipID as Any] as [String : Any]
                          
                      if hasImage {
                          
                          post2["i"]=imageRef
                      }
                      else if hasGif{
                         
                          post2["g"]=gifID
                      }
                          
               
                addReplyToFirestore(key: key, data: post2)
    }
    
    func addReplyToFirestore(key:String, data:[String:Any]){
        
        if let aQuipID = myQuip?.quipID{
            FirestoreService.sharedInstance.saveReply(quipId: aQuipID, mydata: data, key: key) {
                self.addReplyToFirebase(key: key)
                self.addQuipToRecentsForUser(data: data, key: key)
                self.addQuipDocToFirestore(data: data, key: key)
            }
        
       
        }
        
    }
    func addQuipToRecentsForUser(data:[String:Any], key: String){
        var mydata = data
            mydata["reply"] = true
        if let auid = uid{
            FirestoreService.sharedInstance.addQuipToRecentUserQuips(auid: auid, data: mydata, key: key){
                self.updateReplies()
            }
        }
       }
    
    func addQuipDocToFirestore(data:[String:Any],key:String){
      
        FirestoreService.sharedInstance.addQuipDocToFirestore(data: data, key: key)
        
    }
    
    func addReplyToFirebase(key:String){
         let reply1 = ["s": 0] as [String : Any]
        
       
        var childUpdates:[String:Any]=[:]
        if myChannel != nil{
                 childUpdates = ["/Q/\(myQuip!.quipID ?? "Other")/R/\(key)":reply1,
                                    "/M/\(uid ?? "Other")/q/\(key)":reply1,
                                    "A/\(myQuip?.channelKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r": ServerValue.increment(1),
                                    "M/\(myQuip?.user ?? "Other")/q/\(myQuip?.quipID ?? "Other")/r":ServerValue.increment(1)] as [String : Any]
                 
                  
                  if myQuip?.parentKey != nil{
                    childUpdates["A/\(myChannel?.parentKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r"]=ServerValue.increment(1)
                  }
              }
        else{
             childUpdates = ["/Q/\(myQuip!.quipID ?? "Other")/R/\(key)":reply1,
                            "/M/\(uid ?? "Other")/q/\(key)":reply1,
                            "A/\(myQuip?.channelKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r": ServerValue.increment(1),
                            "M/\(myQuip?.user ?? "Other")/q/\(myQuip?.quipID ?? "Other")/r":ServerValue.increment(1)] as [String : Any]
                if myQuip?.parentKey != nil{
                        childUpdates["A/\(myQuip?.parentKey ?? "Other")/Q/\(myQuip?.quipID ?? "Other")/r"]=ServerValue.increment(1)
                        
                }
            }
                   
        FirebaseService.sharedInstance.updateChildValues(myUpdates: childUpdates)
        textView.text = placeHolderText
        let fixedWidth = textView.frame.size.width
        let initialHeight = textView.frame.size.height
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let diffHeight = newSize.height - initialHeight
        textView.frame.size = CGSize(width: fixedWidth, height: newSize.height)
        textView.textColor = .gray
        textView.resignFirstResponder()
        adjustStackViewHeigt(height: diffHeight)
        if imageView?.image != nil || mediaView?.media != nil{
            adjustStackViewHeigt(height: -210)
        }
       deleteBtn?.removeFromSuperview()
        mediaView?.removeFromSuperview()
        
        
        imageView?.removeFromSuperview()
        
        mediaView?.isHidden = true
        imageView?.isHidden = true
        isNewImage = true
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        self.blackView.removeFromSuperview()
        updateReplies()
        postBtn.isEnabled = true
        
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
                if myQuip != nil{
             if let myImageRef = myQuip?.imageRef  {
                     cell.addImageViewToTableCell()
                 
                     cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.replyTable)
                 
             }
                                                                                        
             else if let aGifID = myQuip?.gifID{
                     cell.addGifViewToTableCell()
                 cell.myGifView.getImageFromGiphy(gifID: aGifID, feedTable:self.replyTable)
                                                             
             }
             if self.quipLikeStatus == true {
                 cell.upButton.isSelected = true
                  cell.upButton.tintColor = UIColor(hexString: "ffaf46")
             }else if self.quipLikeStatus == false{
                 cell.downButton.isSelected = true
                  cell.downButton.tintColor = UIColor(hexString: "ffaf46")
             }
                    if let aScore = myQuip?.tempScore{
                    cell.score.text = String(aScore)
                    }
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
         }
         else{
             if let cell = replyTable.dequeueReusableCell(withIdentifier: "replyCell", for: indexPath) as? QuipCells{
         
                
               if myReplies.count > 0 {
                 if let aReply = self.myReplies[indexPath.row - 1] {
                     if let myImageRef = aReply.imageRef {
                                                cell.addImageViewToTableCell()
                         cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.replyTable)
                         
                                                                                     
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
                     if let aID = aReply.quipID{
                     if self.myLikesDislikesMap[aID] == 1{
                                     cell.upButton.isSelected=true
                            
                            
                             cell.upButton.tintColor = UIColor(hexString: "ffaf46")
                         }
                         else if self.myLikesDislikesMap[aID] == -1{
                                     cell.downButton.isSelected=true
                                           cell.downButton.tintColor = UIColor(hexString: "ffaf46")
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
      
                
               
     }
    

}
extension ViewControllerQuip: UIImagePickerControllerDelegate{
    func showImagePickerController(){
        let imagePickerController = UIImagePickerController()
           imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController,animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        setUpImageView()
        addCancelImageButton(isGif: false)
        if mediaView?.isHidden == false || imageView?.isHidden == false{
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
          self.stackView.layoutIfNeeded()
        dismiss(animated: true, completion: nil)

    }
    
    
  
}

extension ViewControllerQuip: GiphyDelegate {
   func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia)   {
   
    setUpGiphyView()
    addCancelImageButton(isGif: true)
    if mediaView?.isHidden == false || imageView?.isHidden == false{
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
    self.stackView.layoutIfNeeded()
        // your user tapped a GIF!
        giphyViewController.dismiss(animated: true, completion: nil)
   
     
   }
   
   func didDismiss(controller: GiphyViewController?) {
        // your user dismissed the controller without selecting a GIF.
   }
}
