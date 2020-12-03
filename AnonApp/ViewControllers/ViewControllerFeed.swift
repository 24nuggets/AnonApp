//
//  ViewControllerFeed.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/17/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK
import MailchimpSDK

class ViewControllerFeed: myUIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    
   
    
    
    

    var myChannel:Channel?
    private weak var writeQuip:ViewControllerWriteQuip?
    var uid:String?
    private weak var passedQuip:Quip?
    private weak var quipVC:ViewControllerQuip?
    var isOpen:Bool?
    var emailEnding:String?
    var hasAccess = false
    var isAdmin = false
  
   
           var myLikesDislikesMap:[String:Int] = [:]
           var myNewLikesDislikesMap:[String:Int] = [:]
          var myUserMap:[String:String] = [:]
    var childChannelMap:[String:String] = [:]
    lazy var ellipeseMenuLauncher:EllipsesMenuEvent = {
                    let launcher = EllipsesMenuEvent()
                 launcher.feedController = self
                     return launcher
                }()
    
    @IBOutlet weak var writeQuipBtn: UIBarButtonItem!
    
    @IBOutlet weak var bottomBarLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBtn: UIButton!
    
    @IBOutlet weak var newBtn: UIButton!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var notConnectedView: UIView!
    
    @IBOutlet weak var notConnectedMessage: UILabel!
    
    @IBOutlet weak var linkEmailButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerFeed.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        // Do any additional setup after loading the view.
        
       if navigationController?.viewControllers.count != 1{
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            notConnectedView.isHidden = true
        self.title =  myChannel?.channelName
        addGesture()
        /*
           if isOpen ?? false{
                      self.navigationItem.rightBarButtonItem = self.writeQuipBtn
                  }else{
                      self.navigationItem.rightBarButtonItem = nil
                  }
       
            if let channelKey = myChannel?.key{
                FirestoreService.sharedInstance.getEvent(eventID: channelKey) {[weak self] (stage, parentKey, parentName) in
                    if let aStage = stage{
                        if aStage == 2{
                            self?.navigationItem.rightBarButtonItem = self?.writeQuipBtn
                        }else{
                            self?.navigationItem.rightBarButtonItem = nil
                        }
                    }
                    if let aparentKey = parentKey{
                        self?.myChannel?.parentKey = aparentKey
                    }
                    if let aparentName = parentName{
                        self?.myChannel?.parent = aparentName
                    }
                }
            }
            */
        }
        if navigationController?.viewControllers.count == 1{
           // let tabBar = tabBarController as! BaseTabBarController
           // authorizeUser(tabBar: tabBar)
            if Core.shared.isKeyPresentInUserDefaults(key: "UID"){
            uid = UserDefaults.standard.string(forKey: "UID")
            }
            loadFeedOrNot(homeSchool: myChannel?.channelName ?? "")
        }
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        topView.backgroundColor = darktint
        
        collectionView.delegate = self
        collectionView.dataSource = self
       setUpButtons()
       selectNew()
        
        
        
    }
    @objc func appWillEnterForeground(){
        selectNew()
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           if Core.shared.isNewUser(){
               //onboarding sequence
               let vc = storyboard?.instantiateViewController(identifier: "WelcomeViewController") as! WelcomeViewController
               vc.modalPresentationStyle = .fullScreen
              present(vc, animated: true)
           }
       }
    
    
    
    func checkIfViewOnly(emailEnd:String){
        let length = emailEnd.count
        let email = UserDefaults.standard.string(forKey: "Email")
        let userEmail = UserDefaults.standard.string(forKey: "EmailConfirmed")
        let userEmailEnd = String(userEmail?.suffix(length) ?? "")
        if emailEnd == userEmailEnd || email == "testid3241"{
           hasAccess = true
        }else if userEmail == "matthewcapriotti4@gmail.com" || userEmail == "jmichaelthompson96@gmail.com"{
            hasAccess = true
            isAdmin = true
        }else{
           hasAccess = false
        }
       
    }
    
    func setUpButtons(){
        let selectedColor = UIColor(hexString: "ffaf46")
             newBtn.setTitleColor(selectedColor, for: .selected  )
             topBtn.setTitleColor(selectedColor, for: .selected  )
       
             
         }
  
    
    override func viewWillAppear(_ animated: Bool){
              super.viewWillAppear(animated)
        if navigationController?.viewControllers.count == 1{
           
            
            var homeSchool = ""
            let userEmail = UserDefaults.standard.string(forKey: "EmailConfirmed")
            let userEmailEnd = userEmail?.components(separatedBy: "@").last
            //remove in next release
            if userEmailEnd == "ufl.edu"{
                UserDefaults.standard.set("University of Florida", forKey: "HomeSchool")
            }
            
            if Core.shared.isKeyPresentInUserDefaults(key: "HomeSchool"){
                homeSchool = UserDefaults.standard.string(forKey: "HomeSchool") ?? ""
                myChannel = Channel(name: homeSchool, akey: homeSchool, email: userEmailEnd ?? "")
               
                if notConnectedView.isHidden == false{
                collectionView.reloadData()
                loadFeedOrNot(homeSchool: homeSchool)
                }
            }
            
            
            
        }else{
      
        if let schoolEmail = myChannel?.aemail{
                   emailEnding = schoolEmail
                   checkIfViewOnly(emailEnd: schoolEmail)
               }
       
        
        }
        //take out in a few weeks, just to get the previous signups to subscribe
        if Core.shared.isKeyPresentInUserDefaults(key: "AskedToSubscribe") == false && Core.shared.isKeyPresentInUserDefaults(key: "Email"){
            if Core.shared.isKeyPresentInUserDefaults(key: "EmailConfirmed"){
                
            }
            displayAskToSendEmail()
            
            
        }
              
    }
    
    func displayAskToSendEmail(){
        let title = "Subscribe"
        let message = "Can Nut House send you occasional promotional emails?"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
          switch action.style{
          case .default:
                print("default")
            if let email = UserDefaults.standard.string(forKey: "Email"){
                do{
                    try Mailchimp.initialize(token: "2059e91faea42aa5a8ea67c9b1874d82-us2")
                }
                catch{
                    print("error initializing mailchimp")
                }
            var contact: Contact = Contact(emailAddress: email)
                if Core.shared.isKeyPresentInUserDefaults(key: "EmailConfirmed"){
                    contact.tags = [Contact.Tag(name: email.components(separatedBy: "@").last ?? "", status: .active), Contact.Tag(name: "SignedUp", status: .active)]
                }else{
            contact.tags = [Contact.Tag(name: email.components(separatedBy: "@").last ?? "", status: .active)]
                }
           UserDefaults.standard.setValue(true, forKey: "AskedToSubscribe")
            Mailchimp.createOrUpdate(contact: contact) { result in
                switch result {
                case .success:
                    print("Successfully added or updated contact")
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
            }
          case .cancel:
                print("cancel")

          case .destructive:
                print("destructive")


          @unknown default:
            print("unknown action")
        }}))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")
                if let email = UserDefaults.standard.string(forKey: "Email"){
                    do{
                        try Mailchimp.initialize(token: "2059e91faea42aa5a8ea67c9b1874d82-us2")
                    }
                    catch{
                        print("error initializing mailchimp")
                    }
                var contact: Contact = Contact(emailAddress: email)
                    if Core.shared.isKeyPresentInUserDefaults(key: "EmailConfirmed"){
                        contact.tags = [Contact.Tag(name: email.components(separatedBy: "@").last ?? "", status: .active), Contact.Tag(name: "SignedUp", status: .active)]
                    }else{
                contact.tags = [Contact.Tag(name: email.components(separatedBy: "@").last ?? "", status: .active)]
                    }
                contact.marketingPermissions = [Contact.MarketingPermission(marketingPermissionId: "marketing", enabled: true)]
                contact.status = .subscribed
                
               UserDefaults.standard.setValue(true, forKey: "AskedToSubscribe")
                Mailchimp.createOrUpdate(contact: contact) { result in
                    switch result {
                    case .success:
                        print("Successfully added or updated contact")
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
                }
              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


              @unknown default:
                print("unknown action")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadFeedOrNot(homeSchool:String){
        //linked email and school exists
        if homeSchool != "" {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.navigationItem.leftBarButtonItem?.isEnabled = true
         notConnectedView.isHidden = true
            self.navigationItem.title = homeSchool
            
            hasAccess = true
            if let schoolEmail = myChannel?.aemail{
                       emailEnding = schoolEmail
            }
        }
        //linked email but not school email or school does not exist
        else if Core.shared.isKeyPresentInUserDefaults(key: "EmailConfirmed"){
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            notConnectedView.isHidden = false
            notConnectedView.backgroundColor = darktint
            notConnectedMessage.text = "The email you have linked does not have a college page. Please contact us if you want your college added to Nut House."
            linkEmailButton.layer.cornerRadius = 20
            linkEmailButton.clipsToBounds = true
            
        }
        //have not linked email
        else{
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            notConnectedView.isHidden = false
            notConnectedView.backgroundColor = darktint
            notConnectedMessage.text = "Please link your .edu college email to view your college's page here."
            linkEmailButton.layer.cornerRadius = 20
            linkEmailButton.clipsToBounds = true
            
        }
        
    }
    
    //updates firestore and firebase with likes when view is dismissed
    override func viewWillDisappear(_ animated: Bool){
           super.viewWillDisappear(animated)
        let indexPath = IndexPath(item: 0, section: 0)
                     let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent
              cell?.refreshControl.endRefreshing()
                          let indexPath2 = IndexPath(item: 1, section: 0)
                                 let cell2 = collectionView.cellForItem(at: indexPath2) as? CollectionViewCellFeedTop
              cell2?.refreshControl.endRefreshing()
         
    }
    
    //resets all arrays haveing to do with new user likes/dislikes
    
 /*
    @objc func appWillEnterForeground() {
          //checks if this view controller is the first one visible
          
        
       }
    
    //deinitializer for notification center
    deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
  */
    
    // MARK: - putVotesToDatabase
      
      func updateVotesFirebase(diff:Int, quip:Quip, aUID:String){
          //increment value has to be double or long or it wont work properly
          let myDiff2 = Double(diff)
          let myDiff = NSNumber(value: myDiff2)
        var myVotes:[String:Any] = [:]
        if let quipID = quip.quipID{
            if let aChannelKey = quip.channelKey {
              myVotes["A/\(aChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(myDiff)
          }
            if let aParentChannelKey = quip.parentKey {
              myVotes["A/\(aParentChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(myDiff)
          }
         
          myVotes["M/\(aUID)/q/\(quipID)/s"] = ServerValue.increment(myDiff)
         myVotes["M/\(aUID)/s"] = ServerValue.increment(myDiff)
          
              updateFirestoreLikesDislikes()
               FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
              resetVars()
        }
          
      }
      
      func updateFirestoreLikesDislikes(){
        if !isAdmin {
          if myNewLikesDislikesMap.count>0{
              if let aUID = uid {
                  if let aChannelKey = myChannel?.key{
                      FirestoreService.sharedInstance.updateLikesDislikes(myNewLikesDislikesMap: myNewLikesDislikesMap, aChannelOrUserKey: aChannelKey, myMap: myUserMap, aUID: aUID, parentChannelKey: myChannel?.parentKey, parentChannelMap: childChannelMap, parentQuipsMap: nil)
                      
                  myNewLikesDislikesMap = [:]
                  }
              }
          }
        }else{
            myNewLikesDislikesMap = [:]
        }
      }
    
    func resetVars(){
           myUserMap=[:]
           myNewLikesDislikesMap=[:]
        childChannelMap = [:]
       }
    
    @IBAction func linkEmailClicked(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CreateAccount") as! myUIViewController
        nextViewController.navigationItem.title = "Link Email"
        navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    
    @IBAction func eventEllipsesClicked(_ sender: Any) {
        ellipeseMenuLauncher.makeViewFade()
        ellipeseMenuLauncher.addMenuFromBottom()
    }
    
    @IBAction func newClicked(_ sender: Any) {
        selectNew()
        scrollToItemAtIndexPath(index: 0)
    }
    
    
    @IBAction func topClicked(_ sender: Any) {
        selectTop()
        scrollToItemAtIndexPath(index: 1)
    }
    
    
    @IBAction func writeClicked(_ sender: Any) {
        
        if hasAccess{
           let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let writeQuip = storyBoard.instantiateViewController(withIdentifier: "ViewControllerWriteQuip") as! ViewControllerWriteQuip
            writeQuip.myChannel = self.myChannel
                writeQuip.feedVC = self
                writeQuip.emailEnding = emailEnding
            writeQuip.uid=self.uid
            self.navigationController?.showDetailViewController(writeQuip, sender: nil)
        }else{
            displayMsgBoxAccess()
        }
    }
    
    func displayMsgBoxAccess(){
        let title = "Link Email"
        let message = "Link your \(emailEnding ?? "") email to post and vote in this group."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
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
        alert.addAction(UIAlertAction(title: "Link Email", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                           let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CreateAccount") as! ViewControllerCreateAccount
                    self.navigationController?.pushViewController(nextViewController, animated: true)
              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


              @unknown default:
                print("unknown action")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func selectNew(){
        topBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        newBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        newBtn.isSelected = true
        topBtn.isSelected = false
        
    }
    
    func selectTop(){
        topBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        newBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        newBtn.isSelected = false
        topBtn.isSelected = true
        
        
    }
    
   
    
    func shareEvent(){
        var components = URLComponents()
        var eventparentIDQueryItem2:URLQueryItem?
        components.scheme = "https"
        components.host = "nuthouse.page.link"
        components.path = "/events"
        let eventIDQueryItem3 = URLQueryItem(name: "eventid", value: myChannel?.key)
        if let parentEventKey = myChannel?.parentKey{
            eventparentIDQueryItem2 = URLQueryItem(name: "parenteventid", value: parentEventKey)
        }
        
        
        let eventNameQueryItem1 = URLQueryItem(name: "eventname", value: myChannel?.channelName?.encodeUrl())
        let eventUIDQueryItem = URLQueryItem(name: "invitedby", value: uid)
        if let parentqueryitem = eventparentIDQueryItem2{
        components.queryItems = [eventNameQueryItem1,parentqueryitem, eventIDQueryItem3]
        }else{
            components.queryItems = [eventUIDQueryItem, eventNameQueryItem1, eventIDQueryItem3]
        }
        guard let linkparam = components.url else {return}
        print(linkparam)
        let dynamicLinksDomainURIPrefix = "https://nuthouse.page.link"
        guard let sharelink = DynamicLinkComponents.init(link: linkparam, domainURIPrefix: dynamicLinksDomainURIPrefix) else {return}
        if let bundleId = Bundle.main.bundleIdentifier {
            sharelink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
        }
        //change to app store id
        sharelink.iOSParameters?.appStoreID = appStoreID
        sharelink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        sharelink.socialMetaTagParameters?.imageURL = logoURL
        sharelink.socialMetaTagParameters?.title = myChannel?.channelName
       // sharelink.socialMetaTagParameters?.descriptionText = aquip.channel
       
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
        
        
            Analytics.logEvent(AnalyticsEventShare, parameters:
                [AnalyticsParameterItemID:"id- \(myChannel?.key ?? "Other")",
                    AnalyticsParameterItemName: myChannel?.channelName ?? "None",
                          AnalyticsParameterContentType: "event"])
        
    }
    
    func showShareViewController(url:URL){
        let myactivity1 = "Join the Nut House now!"
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
    
    func checkNewQuips(myQuipID:String, isUp:Bool, change:Int?){
              var i = 0
        let indexPath = IndexPath(item: 0, section: 0)
               if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent{
                for aQuip in cell.newQuips{
                
                 if aQuip?.quipID == myQuipID{
                     if let myQuip = aQuip{
                         updateOtherQuipList(index: 0, myQuip: myQuip, i: i, isUp: isUp, change: change)

                     }
                    
                 }
                i += 1
             }
        
        }
         }
    
    func checkHotQuips(myQuipID:String, isUp:Bool, change:Int?){
           var i = 0
        let indexPath = IndexPath(item: 1, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedTop{
            for aQuip in cell.hotQuips{
               
               if aQuip?.quipID == myQuipID{
                   if let myQuip = aQuip{
                       updateOtherQuipList(index: 1, myQuip: myQuip, i: i, isUp: isUp, change: change)

                   }
                   
               }
               i += 1
           }
        }
       }
    
    func updateOtherQuipList(index:Int, myQuip:Quip, i:Int, isUp:Bool, change:Int?){
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent{
            let indexPath2 = IndexPath(item: i, section: 0)
            if let myCell = cell.feedTable.cellForRow(at: indexPath2) as? QuipCells{
                if isUp{
                    cell.upPressedForOtherCell(aQuip: myQuip, cell: myCell)
                }else{
                    cell.downPressedForOtherCell(aQuip: myQuip, cell: myCell)
                }
            }else{
                if let aChange = change{
                  //  myQuip.quipScore! += aChange
                    myQuip.tempScore! += aChange
                    guard var myQuipInfo = cell.myScores[myQuip.quipID ?? ""] as? [String:Int] else {return}
                    myQuipInfo["s"]! += aChange
                    
                }
            }
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedTop{
        let indexPath2 = IndexPath(item: i, section: 0)
        if let myCell = cell.feedTable.cellForRow(at: indexPath2) as? QuipCells{
                       if isUp{
                           cell.upPressedForOtherCell(aQuip: myQuip, cell: myCell)
                       }else{
                           cell.downPressedForOtherCell(aQuip: myQuip, cell: myCell)
                       }
                   }else{
                       if let aChange = change{
                      //  myQuip.quipScore! += aChange
                        myQuip.tempScore! += aChange
                       }
                   }
    }
    }
    
    func scrollToItemAtIndexPath(index: Int){
              let indexPath = IndexPath(item: index, section: 0)
              collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
          }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return 2
     }
     
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         if indexPath.row == 0{
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCell", for: indexPath) as? CollectionViewCellFeedRecent{
                cell.myFeedController = self
                cell.updateNew(){
                    
                   
                }
              return cell
             }
             
         }else if indexPath.row == 1{
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topCell", for: indexPath) as? CollectionViewCellFeedTop{
                cell.myFeedController = self
                cell.updateHot(){
                    
                }
              return cell
             }
             
         }
       
         
         return UICollectionViewCell()
     }
     
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
     }
     
     func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
         let index = targetContentOffset.pointee.x / view.frame.width
         if index == 0 {
            selectNew()
         }else if index == 1{
             selectTop()
         }
         
     }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        bottomBarLeadingConstraint.constant = scrollView.contentOffset.x / 2
    }
  
    func showNextController(menuItem:MenuItem, quip:Quip){
        if menuItem.name == "View User's Profile"{
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ViewControllerUser") as! ViewControllerUser
            nextViewController.uid = uid
            nextViewController.uidProfile = quip.user
            navigationController?.pushViewController(nextViewController, animated: true)
        }else if menuItem.name == "Report Crack"{
            FirestoreService.sharedInstance.reportQuip(quip: quip)
            displayMsgBoxReport()
        }else if menuItem.name == "Share Crack"{
            if let collectionViewCell = collectionView.visibleCells[0] as? CollectionCellFeed{
                collectionViewCell.generateDynamicLink(aquip: quip, cell: nil)
            }
        }else if menuItem.name == "Delete Crack"{
            if let aQuipID = quip.quipID{
                FirestoreService.sharedInstance.deleteQuip(quipID: aQuipID){
                    self.collectionView.reloadData()
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
                                                self.collectionView.reloadData()
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
    
    func displayMsgBoxReport(){
    let title = "Report Successful"
    let message = "The user has been reported. If you want to give us more details on this incident please email us at \(supportEmail)"
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
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let quipVC = segue.destination as? ViewControllerQuip{
        if newBtn.isSelected{
            let indexPath = IndexPath(item: 0, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent {
            if let index = cell.feedTable.indexPathForSelectedRow?.row {
                passedQuip = cell.newQuips[index]
            }
            let myCell = cell.feedTable.cellForRow(at: cell.feedTable.indexPathForSelectedRow!) as? QuipCells
                       quipVC.quipScore = myCell?.score.text
                       if myCell?.upButton.isSelected == true {
                           quipVC.quipLikeStatus = true
                       }
                       else if myCell?.downButton.isSelected == true{
                           quipVC.quipLikeStatus = false
                       }
            quipVC.currentTime = cell.currentTime
       //     quipVC.passedQuipCell = myCell
            cell.feedTable.deselectRow(at: cell.feedTable.indexPathForSelectedRow!, animated: false)
            }
            quipVC.parentIsNew = true
        }else if topBtn.isSelected{
            let indexPath = IndexPath(item: 1, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedTop{
            if let index = cell.feedTable.indexPathForSelectedRow?.row {
                passedQuip = cell.hotQuips[index]
            }
            let myCell = cell.feedTable.cellForRow(at: cell.feedTable.indexPathForSelectedRow!) as? QuipCells
                                  quipVC.quipScore = myCell?.score.text
                                  if myCell?.upButton.isSelected == true {
                                      quipVC.quipLikeStatus = true
                                  }
                                  else if myCell?.downButton.isSelected == true{
                                      quipVC.quipLikeStatus = false
                                  }
             quipVC.currentTime = cell.currentTime
     //quipVC.passedQuipCell = myCell
            cell.feedTable.deselectRow(at: cell.feedTable.indexPathForSelectedRow!, animated: false)
            }
            quipVC.parentIsNew = false

        }
        
            
            
           
            quipVC.myQuip = self.passedQuip
            
            quipVC.uid=self.uid
            
            quipVC.myChannel=self.myChannel
            
            quipVC.emailEnding = emailEnding
            quipVC.parentViewFeed = self
            
           
            
        }else if let writeQuip = segue.destination as? ViewControllerWriteQuip{
        
        
        writeQuip.myChannel = self.myChannel
            writeQuip.feedVC = self
            writeQuip.emailEnding = emailEnding
        writeQuip.uid=self.uid
        //select new quips tab before leaving
            
            
            
        }
    }
    
   func authorizeUser(tabBar:BaseTabBarController){
                  
                  Auth.auth().signInAnonymously() {[weak self] (authResult, error) in
                    // ...
                   guard let user = authResult?.user else { return }
                       self?.uid = user.uid
                   tabBar.userID=user.uid
                     UserDefaults.standard.set(user.uid, forKey: "UID")
                    self?.collectionView.reloadData()
                   
                  }
                  
                 
              }

}

class Core{
    
    static let shared = Core()
    
    func isNewUser()->Bool{
        //inverse it because first time it is not set it will return false
        return !UserDefaults.standard.bool(forKey: "isNewUser")
    }
    func setIsNotNewUser(){
        UserDefaults.standard.set(true, forKey: "isNewUser")
        
    }
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}
