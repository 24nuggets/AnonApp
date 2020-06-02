//
//  ViewControllerUser.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerUser: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate {
   
    
   
 

    @IBOutlet weak var editProfileBtn: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var userQuipsTable: UITableView!
    @IBOutlet weak var recentTop: UISegmentedControl!
    
    private var uid:String?
    private var newUserQuips:[Quip?]=[]
    private var topUserQuips:[Quip?]=[]
    private var databaseHandleNewValue:DatabaseReference?
    private var databaseHandleHotValue:DatabaseReference?
    private var currentTime:Double?
    private var myQuipID:String?
    private var myQuipText:String?
    private var myQuipChannel:String?
    private var myQuipScore:String?
    private var timePosted:Timestamp?
    private var author:String?
    private var parentChannelKey:String?
    private var channelKey:String?
    private var myScores:[String:Any]=[:]
    private var myTopScores:[Quip]=[]
    private var myPreviousTopQuips:[Quip]=[]
   
    private var moreTopQuipDocs:Bool = false

    private var moreRecentQuips:Bool = false
    private var lastiVal:Int?
    private var lastjVal:Int?
    private var quipVC:ViewControllerQuip?
    private var passedQuip:Quip?
    private var myVotes:[String:Any] = [:]
    var myLikesDislikesMap:[String:Int] = [:]
    var myNewLikesDislikesMap:[String:Int] = [:]
    var myChannelsMap:[String:String] = [:]
    var myParentChannelsMap:[String:String] = [:]
    var myParentQuipsMap:[String:String] = [:]
    private var refreshControl = UIRefreshControl()
    lazy var MenuLauncher:ellipsesMenuUser = {
              let launcher = ellipsesMenuUser()
           launcher.userController = self
               return launcher
          }()
    
    lazy var settingsMenuLauncher:SettingsMenuQuip = {
                 let launcher = SettingsMenuQuip()
              launcher.userController = self
                  return launcher
             }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userQuipsTable.delegate=self
        userQuipsTable.dataSource=self
          refreshControl.addTarget(self, action: #selector(ViewControllerUser.refreshData), for: .valueChanged)
          userQuipsTable.refreshControl=refreshControl
              let tabBar = tabBarController as! BaseTabBarController
              self.uid = tabBar.userID
              
            loadUserPage()
        
            
    }
    
    override func viewDidAppear(_ animated: Bool){
          super.viewDidAppear(animated)
         refreshData()
          
        }
    
    //updates firestore and firebase with likes when view is dismissed
      override func viewWillDisappear(_ animated: Bool){
             super.viewWillDisappear(animated)

           updateFirestoreLikesDislikes()
        FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
          resetVars()
             
           }
      
      //resets all arrays haveing to do with new user likes/dislikes
      func resetVars(){
          myChannelsMap=[:]
          myNewLikesDislikesMap=[:]
          myVotes=[:]
      }
    func loadUserPage(){
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        editProfileBtn.layer.borderColor = UIColor.black.cgColor
        editProfileBtn.layer.borderWidth = 0.5
        editProfileBtn.layer.masksToBounds = true
        editProfileBtn.layer.cornerRadius = 8
    }
    
    
    @IBAction func recentTopChange(_ sender: Any) {
        switch recentTop.selectedSegmentIndex
                  {
                  case 0:
                      
                                updateNew()
                       
                   
                  case 1:
                      
                               updateTop()
                          
                   
                  default:
                      break
                  }
        
    }
    
    @IBAction func settingsBtnTapped(_ sender: UIBarButtonItem) {
        settingsMenuLauncher.makeViewFade()
        settingsMenuLauncher.addMenuFromSide()
    }
    
    
    func btnSharedTapped(cell: QuipCells) {
              
          }
    
    func btnEllipsesTapped(cell: QuipCells) {
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
       }
    
    func btnUpTapped(cell: QuipCells) {
           //Get the indexpath of cell where button was tapped
                 if let indexPath = self.userQuipsTable.indexPath(for: cell){
                 switch recentTop.selectedSegmentIndex
                 {
                 case 0:
                     if let myQuip = newUserQuips[indexPath.row]{
                     upButtonPressed(aQuip: myQuip, cell: cell)
                     }
                  
                 case 1:
                     if let myQuip = topUserQuips[indexPath.row]{
                     upButtonPressed(aQuip: myQuip, cell: cell)
                     }
                  
                 default:
                     break
                 }
                 }
       }
       
       func btnDownTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
               if let indexPath = self.userQuipsTable.indexPath(for: cell){
               switch recentTop.selectedSegmentIndex
               {
               case 0:
                   if let myQuip = newUserQuips[indexPath.row]{
                   downButtonPressed(aQuip: myQuip, cell: cell)
                   }
                
               case 1:
                   
                   if let myQuip = topUserQuips[indexPath.row]{
                   downButtonPressed(aQuip: myQuip, cell: cell)
                   }
                
               default:
                   break
               }
               }
               
           
       }
    
    
    
    // MARK: - Like/Dislike Logic
       
       func downButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
                  if let aQuipScore = aQuip.quipScore{
                   let diff = cell.upToDown(quipScore: aQuipScore, quip: aQuip)
                       if let aID = aQuip.quipID{
                           updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                           myNewLikesDislikesMap[aID] = -1
                           myLikesDislikesMap[aID] = -1
                        if let aChannelKey = aQuip.channelKey{
                            myChannelsMap[aID] = aChannelKey
                            if let aParent = aQuip.parentKey{
                                myParentChannelsMap[aID] = aParent
                            }
                        }else if let aParentQuip = aQuip.quipParent{
                            myParentQuipsMap[aID]=aParentQuip
                        }
                       }
               }
           }
           else if cell.downButton.isSelected {
                  if let aQuipScore = aQuip.quipScore{
                   let diff = cell.downToNone(quipScore: aQuipScore, quip: aQuip)
                       if let aID = aQuip.quipID{
                           updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                           myNewLikesDislikesMap[aID]=0
                           myLikesDislikesMap[aID]=0
                          if let aChannelKey = aQuip.channelKey{
                              myChannelsMap[aID] = aChannelKey
                              if let aParent = aQuip.parentKey{
                                  myParentChannelsMap[aID] = aParent
                              }
                          }else if let aParentQuip = aQuip.quipParent{
                              myParentQuipsMap[aID]=aParentQuip
                          }
                       }
                   
               }
           }
           else{
                if let aQuipScore = aQuip.quipScore{
                   let diff = cell.noneToDown(quipScore: aQuipScore, quip:aQuip)
                   if let aID = aQuip.quipID{
                       updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                       myNewLikesDislikesMap[aID] = -1
                       myLikesDislikesMap[aID] = -1
                     if let aChannelKey = aQuip.channelKey{
                          myChannelsMap[aID] = aChannelKey
                          if let aParent = aQuip.parentKey{
                              myParentChannelsMap[aID] = aParent
                          }
                      }else if let aParentQuip = aQuip.quipParent{
                          myParentQuipsMap[aID]=aParentQuip
                      }
                   }
               }
               
           }
           
       }
       func upButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
               if let aQuipScore = aQuip.quipScore{
                   let diff = cell.upToNone(quipScore: aQuipScore, quip:aQuip)
                   if let aID = aQuip.quipID{
                       updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                       myNewLikesDislikesMap[aID]=0
                       myLikesDislikesMap[aID]=0
                      if let aChannelKey = aQuip.channelKey{
                           myChannelsMap[aID] = aChannelKey
                           if let aParent = aQuip.parentKey{
                               myParentChannelsMap[aID] = aParent
                           }
                       }else if let aParentQuip = aQuip.quipParent{
                           myParentQuipsMap[aID]=aParentQuip
                       }
                       }
                       
               }
                }
                else if cell.downButton.isSelected {
                   if let aQuipScore = aQuip.quipScore{
                       let diff = cell.downToUp(quipScore: aQuipScore, quip:aQuip)
                           if let aID = aQuip.quipID{
                               updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                               myNewLikesDislikesMap[aID] = 1
                               myLikesDislikesMap[aID] = 1
                              if let aChannelKey = aQuip.channelKey{
                                  myChannelsMap[aID] = aChannelKey
                                  if let aParent = aQuip.parentKey{
                                      myParentChannelsMap[aID] = aParent
                                  }
                              }else if let aParentQuip = aQuip.quipParent{
                                  myParentQuipsMap[aID]=aParentQuip
                              }
                           }
                       }
                   }
                else{
                   if let aQuipScore = aQuip.quipScore{
                       let diff = cell.noneToUp(quipScore: aQuipScore, quip:aQuip)
                       if let aID = aQuip.quipID{
                           updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                           myNewLikesDislikesMap[aID] = 1
                           myLikesDislikesMap[aID] = 1
                           if let aChannelKey = aQuip.channelKey{
                               myChannelsMap[aID] = aChannelKey
                               if let aParent = aQuip.parentKey{
                                   myParentChannelsMap[aID] = aParent
                               }
                           }else if let aParentQuip = aQuip.quipParent{
                               myParentQuipsMap[aID]=aParentQuip
                           }
                       }
                   }
                }
           
       }
       
    func updateVotesFirebase(diff:Int, quipID:String, myQuip:Quip){
        //increment value has to be double or long or it wont work properly
        let myDiff = Double(diff)
        if let aChannelKey =  myQuip.channelKey{
           myVotes["A/\(aChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
        if let aParentChannelKey = myQuip.parentKey{
              myVotes["A/\(aParentChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
           if let aUID = uid {
           myVotes["M/\(aUID)/q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
       }
       
    func updateFirestoreLikesDislikes(){
        if myNewLikesDislikesMap.count>0{
           if let aUID = uid {
               if let bUId = uid{
                
                FirestoreService.sharedInstance.updateLikesDislikes(myNewLikesDislikesMap: myNewLikesDislikesMap, aChannelOrUserKey: bUId, myMap: myChannelsMap, aUID: aUID, parentChannelKey: nil, parentChannelMap: myParentQuipsMap)
                
            }
        }
       }
    }
    
    func getUserLikesDislikesForUser(completion: @escaping ()->()){
        myLikesDislikesMap = [:]
        if let aUID = uid {
            if let bUId = uid{
                FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: aUID, aKey: bUId) { (myLikesDislikesMap) in
                    self.myLikesDislikesMap = myLikesDislikesMap
                    self.userQuipsTable.reloadData()
                    self.refreshControl.endRefreshing()
                    completion()
                }
                    
            }
        }
    }
       
    
       
    
    
    func updateNew(){
       getActiveUserQuips()
       
          
       
          
          
    }
    func getActiveUserQuips(){
        
        self.myScores = [:]
        self.myTopScores = []
      
        if let auid = uid{
            FirebaseService.sharedInstance.getActiveUserQuips(uid: auid) { (myTopScores, myScores, currentTime) in
                
                self.myScores = myScores
                self.myTopScores = myTopScores
                self.currentTime = currentTime
                switch self.recentTop.selectedSegmentIndex
                {
                    case 0:
                        self.getRecentUserQuipsFirestore()
                              
                    case 1:
                      //  self.getTopUserQuipsFirestore()
                         break
                    default:
                        break
                }
            }
            
        }
    }
    
    func getRecentUserQuipsFirestore(){
        moreRecentQuips = false
        newUserQuips = []
        if let auid = uid {
            FirestoreService.sharedInstance.getRecentUserQuipsFirestore(uid: auid, myScores: myScores) { (newUserQuips, moreRecentQuips) in
                self.newUserQuips = newUserQuips
                self.getUserLikesDislikesForUser {
                    self.moreRecentQuips = moreRecentQuips
                }
            }
        }
    }

      
      
      
      func updateTop(){
          
         getActiveUserQuips()
          
      }
    
    //come back to this i think i am going to make this logic the same way we deal with top channel quips for past channels
    /*
    func getTopUserQuipsFirestore(){
        self.moreTopQuipDocs = false
        self.tempMoreTopQuipDocs = false
        numOfHotLoads = 1
        if let auid = uid {
        let userTopRef = db?.collection("Users/\(auid)/TopQuips")
            self.topUserQuips = []
        self.myPreviousTopQuips = []
          var newQuipsFromFirestore:[Quip] = []
        userTopRef?.order(by: "t", descending: true).limit(to: 1).getDocuments{ (querySnapshot, err) in
           if let err = err {
                      print("Error getting documents: \(err)")
        } else {
            var i = 0
                for document in querySnapshot!.documents {
                    let docData = document.data(with: ServerTimestampBehavior.estimate) as [String:Any]
                    for aKey in docData.keys{
                        if aKey == "t"{
                            continue
                        }
                        let quipID = aKey
                        let quipData = docData[aKey] as! [String:Any]
                        let author = quipData["a"] as? String
                        let channelName = quipData["c"] as? String
                        let quipText = quipData["t"] as? String
                        let timePosted = quipData["d"] as? Timestamp
                        let quipScore = quipData["s"] as? Int
                        let quipReplies = quipData["r"] as? Int
                         let myImageRef = quipData["i"] as? String
                        let myGifRef = quipData["g"] as? String
                        let myQuip = Quip(text: quipText!, bowl: channelName!, time: timePosted!, score: quipScore!, myQuipID: quipID, author: author!, replies: quipReplies!, myImageRef: myImageRef, myGifID: myGifRef)
                        newQuipsFromFirestore.append(myQuip)
                        i += 1
                        if i == 20 {
                            self.tempMoreTopQuipDocs = true
                            self.myLastTopQuipDoc = document
                        }
                    }
                    
                   
                    }
        }
            newQuipsFromFirestore = newQuipsFromFirestore.sorted(by: {$0.quipScore! > $1.quipScore!})
            self.mergePreviousTopAndCurrentTop(newFirstoreArray: newQuipsFromFirestore)
        }
        }
    }
    
    func mergePreviousTopAndCurrentTop(newFirstoreArray:[Quip]){
        var i:Int=0
        var j:Int=0
        if numOfHotLoads != 1 {
            j = lastjVal!
        }
        var k = 0
        var getNewQuipsInfo = false
        var newQuipsToGet:[Int:Quip] = [:]
        while (i < newFirstoreArray.count && j < myTopScores.count && k < 20 * numOfHotLoads!)
           {
            if (myPreviousTopQuips[k].quipScore! < myTopScores[j].quipScore!)
               {
                topUserQuips.append(myPreviousTopQuips[i])
                   i += 1
               }
               else
               {
                    getNewQuipsInfo=true
                    newQuipsToGet[k] = myTopScores[j]
                topUserQuips.append(myTopScores[j])
                   j += 1
               }
               k += 1
           }

           while (i < myPreviousTopQuips.count)
           {
            topUserQuips.append(myPreviousTopQuips[i])
               i += 1
               k += 1
           }

           while (j < myTopScores.count)
           {
            getNewQuipsInfo = true
            newQuipsToGet[k] = myTopScores[j]
            topUserQuips.append(myTopScores[j])
               j += 1
               k += 1
           }
        if getNewQuipsInfo {
            getInfoForNewQuips(newQuips: newQuipsToGet)
        }
        else{
            self.userQuipsTable.reloadData()
            if tempMoreTopQuipDocs {
                moreTopQuipDocs = true
            }
        }
        lastiVal = i
        lastjVal = j
        
    }
    
    func getInfoForNewQuips(newQuips:[Int:Quip]){
        var i = 0
        for aNewQuip in newQuips{
            if let myQuip = topUserQuips[aNewQuip.key]{
            if let myQuipId = topUserQuips[aNewQuip.key]?.quipID{
            self.db?.collection("Quips").document(myQuipId).getDocument { (document, error) in
               if let document = document, document.exists {
                let quipData = document.data(with: ServerTimestampBehavior.estimate)
                myQuip.user = quipData!["a"] as? String
                myQuip.channel = quipData!["c"] as? String
                myQuip.quipText = quipData!["t"] as? String
                myQuip.timePosted = quipData!["d"] as? Timestamp
                 i += 1
               }
            if i == newQuips.count{
            
                self.getUserLikesDislikesForUser()
                if self.tempMoreTopQuipDocs {
                    self.moreTopQuipDocs = true
                }
            }
           }
        }
        }
        }
        
    }
     func loadMoreTopUserQuips(){
         
         self.moreTopQuipDocs = false
         self.tempMoreTopQuipDocs = false
         numOfHotLoads! += 1
         let userTopRef = db?.collection("Quips")
                
         userTopRef?.order(by: "s", descending: true).start(afterDocument: self.myLastTopQuipDoc!).limit(to: 10).whereField("a", isEqualTo: uid!).getDocuments{ (querySnapshot, err) in
                   if let err = err {
                              print("Error getting documents: \(err)")
                } else {
                     var i = 0
                        for document in querySnapshot!.documents {
                            let quipData = document.data(with: ServerTimestampBehavior.estimate) as [String:Any]
                            let quipID = document.documentID
                            let author = quipData["a"] as? String
                            let channelName = quipData["c"] as? String
                            let quipText = quipData["t"] as? String
                            let timePosted = quipData["d"] as? Timestamp
                            let quipScore = quipData["s"] as? Int
                            let quipReplies = quipData["r"] as? Int
                             let myImageRef = quipData["i"] as? String
                         let myGifRef = quipData["g"] as? String
                            let myQuip = Quip(text: quipText!, bowl: channelName!, time: timePosted!, score: quipScore!, myQuipID: quipID, author: author!, replies: quipReplies!, myImageRef: myImageRef, myGifID: myGifRef)
                            self.myPreviousTopQuips.append(myQuip)
                         
                         i += 1
                         if i == 10 {
                             self.tempMoreTopQuipDocs = true
                             self.myLastTopQuipDoc = document
                             }
                         }
                }
              //uncomment when you make top quips for user method
             //   self.mergePreviousTopAndCurrentTop()
                }
         
     }
 */
    
    func loadMoreRecentUserQuips(){
        self.moreRecentQuips = false
        if let auid = uid {
            FirestoreService.sharedInstance.loadMoreRecentUserQuips(uid: auid, myScores: myScores) { (newUserQuips, moreRecentQuips) in
                self.newUserQuips = self.newUserQuips + newUserQuips
                self.userQuipsTable.reloadData()
                self.moreRecentQuips = moreRecentQuips
            }
        }
        
    }
    
    
    
    @objc func refreshData(){
        refreshControl.beginRefreshing()
        switch recentTop.selectedSegmentIndex
                         {
                         case 0:
                             
                                       updateNew()
                              
                          
                         case 1:
                             
                                      updateTop()
                                 
                          
                         default:
                             break
                         }
    }
  
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          switch recentTop.selectedSegmentIndex
                {
                case 0:
                    return self.newUserQuips.count
                 
                case 1:
                    return self.topUserQuips.count
                 
                default:
                    break
                }
                return 0
     }
     
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = userQuipsTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! QuipCells
              
               switch recentTop.selectedSegmentIndex
                     {
                     case 0:
                          if newUserQuips.count > 0 {
                                if let myQuip = self.newUserQuips[indexPath.row]{
                                    cell.aQuip = myQuip
                                        if let myImageRef = myQuip.imageRef  {
                                            
                                                cell.addImageViewToTableCell()
                                                cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.userQuipsTable)
                                            
                                                                                                                    
                                        }
                                                                                                                                                       
                                        else if let myGifID = myQuip.gifID  {
                                                                                                                 
                                            cell.addGifViewToTableCell()
                                            cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.userQuipsTable)
                                                                                                                                                           
                                        }
                                                            
                                                                   
                                                                 
                                                            
                                cell.categoryLabel.text = String(indexPath.row)
                                cell.categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
                                
                                if let dateVal = myQuip.timePosted?.seconds{
                                    let milliTimePost = dateVal * 1000
                                    if let aCurrentTime = self.currentTime{
                                        cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: aCurrentTime)
                                    }
                                }
                                if let aID = myQuip.quipID{
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
                      
                     case 1:
                         if topUserQuips.count > 0 {
                          if let myQuip = self.topUserQuips[indexPath.row]{
                            cell.aQuip = myQuip
                                       if let myImageRef = myQuip.imageRef  {
                                           
                                               cell.addImageViewToTableCell()
                                               cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.userQuipsTable)
                                           
                                                                                                                   
                                       }
                                                                                                                                                      
                                       else if let myGifID = myQuip.gifID  {
                                                                                                                
                                           cell.addGifViewToTableCell()
                                           cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.userQuipsTable)
                                                                                                                                                          
                                       }
                                                           
                                                                  
                                                                
                                                           
                               cell.categoryLabel.text = String(indexPath.row)
                               cell.categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
                              
                                                                                                                    
                            if let aID = myQuip.quipID{
                                if self.myLikesDislikesMap[aID] == 1{
                                    cell.upButton.isSelected=true
                                    cell.upButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                            }
                            else if self.myLikesDislikesMap[aID] == -1{
                                    cell.downButton.isSelected=true
                                    cell.downButton.tintColor = UIColor(red: 152.0/255.0, green: 212.0/255.0, blue: 186.0/255.0, alpha: 1.0)
                                                                                            
                                }
                            }
                               
                               if let dateVal = myQuip.timePosted?.seconds{
                                   let milliTimePost = dateVal * 1000
                                   if let aCurrentTime = self.currentTime{
                                       cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: aCurrentTime)
                                   }
                               }
                              
                                                                 
                                                               
                           }
                                    }
                                    else{
                                        return cell
                                    }
                      
                     default:
                         break
                     }
        cell.downButton.changeButtonWeight()
        cell.upButton.changeButtonWeight()
                cell.delegate = self
              return cell
     }
     
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
           let height = scrollView.frame.size.height
           let contentYoffset = scrollView.contentOffset.y
           let distanceFromBottom = scrollView.contentSize.height - contentYoffset
           if distanceFromBottom < height {
              
                      
                     
                          // handle your logic here to get more items, add it to dataSource and reload tableview
            switch recentTop.selectedSegmentIndex
                                 {
                                 case 0:
                                    if moreRecentQuips{
                                        loadMoreRecentUserQuips()
                                    }
                                 case 1:
                                      if moreTopQuipDocs {
                                     //  loadMoreTopUserQuips()
                                       }
                                 default:
                                     break
                                 }
                   
           }
       }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let index = userQuipsTable.indexPathForSelectedRow?.row {
             switch recentTop.selectedSegmentIndex
                   {
                   case 0:
                      passedQuip = newUserQuips[index]
                    
                   case 1:
                       passedQuip = topUserQuips[index]
                    
                   default:
                       break
                   }
            quipVC = segue.destination as? ViewControllerQuip
            let myCell = userQuipsTable.cellForRow(at: userQuipsTable.indexPathForSelectedRow!) as? QuipCells
                       quipVC?.quipScore = myCell?.score.text
                       if myCell?.upButton.isSelected ?? false {
                           quipVC?.quipLikeStatus = true
                       }
                       else if myCell?.downButton.isSelected ?? false{
                           quipVC?.quipLikeStatus = false
                       }
            quipVC?.myQuip = self.passedQuip
         
            quipVC?.uid=self.uid
            
            quipVC?.currentTime = self.currentTime
            quipVC?.parentViewUser = self
            quipVC?.passedQuipCell = myCell
            userQuipsTable.deselectRow(at: userQuipsTable.indexPathForSelectedRow!, animated: false)
            
        }
        else{
            
        }
    }
    

}
