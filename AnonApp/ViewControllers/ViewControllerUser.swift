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
    private var currentTime:Double?
    private var myScores:[String:Any]=[:]
    private var myTopScores:[Quip?]=[]
    private var myHotIDs:[String] = []
    
    private var moreTopUserQuipsFirebase:Bool = false
    private var moreTopQuipDocs:Bool = false
    private var moreRecentUserQuipsFirebase:Bool = false
    private var moreRecentQuips:Bool = false
    private var quipVC:ViewControllerQuip?
    private weak var passedQuip:Quip?
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
                         updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                       }
               }
           }
           else if cell.downButton.isSelected {
                  if let aQuipScore = aQuip.quipScore{
                   let diff = cell.downToNone(quipScore: aQuipScore, quip: aQuip)
                       if let aID = aQuip.quipID{
                           
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
                        updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                       }
                   
               }
           }
           else{
                if let aQuipScore = aQuip.quipScore{
                   let diff = cell.noneToDown(quipScore: aQuipScore, quip:aQuip)
                   if let aID = aQuip.quipID{
                       
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
                    updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                   }
               }
               
           }
           
       }
       func upButtonPressed(aQuip:Quip, cell:QuipCells){
           if cell.upButton.isSelected {
               if let aQuipScore = aQuip.quipScore{
                   let diff = cell.upToNone(quipScore: aQuipScore, quip:aQuip)
                   if let aID = aQuip.quipID{
                       
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
                    updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                       }
                       
               }
                }
                else if cell.downButton.isSelected {
                   if let aQuipScore = aQuip.quipScore{
                       let diff = cell.downToUp(quipScore: aQuipScore, quip:aQuip)
                           if let aID = aQuip.quipID{
                               
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
                            updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                           }
                       }
                   }
                else{
                   if let aQuipScore = aQuip.quipScore{
                       let diff = cell.noneToUp(quipScore: aQuipScore, quip:aQuip)
                       if let aID = aQuip.quipID{
                           
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
                        updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
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
        updateFirestoreLikesDislikes()
               FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
                 resetVars()
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
       getRecentUserQuips()
       
          
       
          
          
    }
    func getRecentUserQuips(){
        
        self.myScores = [:]
        moreRecentQuips = false
        newUserQuips = []
      
        if let auid = uid{
            FirebaseService.sharedInstance.getRecentUserQuips(uid: auid) { [weak self](myScores, currentTime, moreRecentUserQuipsFirebase) in
                
                self?.myScores = myScores
                
                self?.currentTime = currentTime
                FirestoreService.sharedInstance.getRecentUserQuipsFirestore(uid: auid, myScores: myScores) {[weak self] (newUserQuips, moreRecentQuips) in
                    self?.newUserQuips = newUserQuips
                    self?.getUserLikesDislikesForUser {
                        self?.moreRecentQuips = moreRecentQuips
                        self?.moreRecentUserQuipsFirebase = moreRecentUserQuipsFirebase
                               }
                           }
               
            }
            
        }
    }
    
  func loadMoreRecentUserQuips(){
        self.moreRecentQuips = false
        
        if let auid = uid {
            if self.moreRecentUserQuipsFirebase == true{
                FirebaseService.sharedInstance.getMoreNewScoresUser(aUid: auid) {[weak self] (moreScores, moreRecentUserQuipsFirebase) in
                    if let aself = self{
                    aself.myScores = aself.myScores.merging(moreScores, uniquingKeysWith: { (_, new) -> Any in
                        new
                    })
                      aself.moreRecentUserQuipsFirebase = moreRecentUserQuipsFirebase
                    }
                }
            }
            FirestoreService.sharedInstance.loadMoreRecentUserQuips(uid: auid, myScores: myScores) {[weak self] (newUserQuips, moreRecentQuips) in
                if let aself = self{
                aself.newUserQuips = aself.newUserQuips + newUserQuips
                aself.userQuipsTable.reloadData()
                aself.moreRecentQuips = moreRecentQuips
                }
              
            }
        }
        
    }
    

      
      
      
      func updateTop(){
        self.topUserQuips = []
        self.myHotIDs = []
        if let auid = uid{
        FirebaseService.sharedInstance.getTopUserQuips(uid: auid) { [weak self](myTopScores, currentTime, moreTopFirebaseQuips, myHotIDs) in
            self?.topUserQuips = myTopScores
            self?.currentTime = currentTime
            self?.myHotIDs = myHotIDs
            FirestoreService.sharedInstance.getHotQuipsUser(myUid: auid, aHotIDs: myHotIDs, hotQuips: myTopScores) {[weak self] (myData, aHotQuips, more) in
                self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                self?.moreTopUserQuipsFirebase = moreTopFirebaseQuips
                self?.refreshControl.endRefreshing()
            }
        }
        }
      }
    func populateHotQuipsArr(data:[String:Any], aHotQuips:[Quip?], more:Bool){
                for aQuip in aHotQuips{
                    if let myQuip = aQuip{
                        if let myID = myQuip.quipID{
                            let quipData = data[myID] as! [String:Any]
                            myQuip.user = quipData["a"] as? String
                            myQuip.channel = quipData["c"] as? String
                            myQuip.channelKey = quipData["k"] as? String
                            myQuip.quipText = quipData["t"] as? String
                            myQuip.timePosted = quipData["d"] as? Timestamp
                           myQuip.gifID = quipData["g"] as? String
                           myQuip.imageRef = quipData["i"] as? String
                            myQuip.isReply = quipData["r"] as? Bool ?? false
                            if myQuip.isReply{
                                myQuip.quipParent = quipData["p"] as? String
                            }
                        
                    }
                    }
                    
                }
                if more{
                    self.topUserQuips = self.topUserQuips + aHotQuips
                }
            self.userQuipsTable.reloadData()
                
                
            }
    func loadMoreTopUserQuips(){
        moreTopUserQuipsFirebase = false
        if let auid = uid{
            FirebaseService.sharedInstance.loadMoreHotUser(auid: auid) {[weak self] (ahotquips, ahotids, morehotquipsfirebase) in
                FirestoreService.sharedInstance.loadMoreHotUser(auid: auid, aHotIDs: ahotids, hotQuips: ahotquips) {[weak self] (myData, aHotQuips, more) in
                    self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                    self?.moreTopUserQuipsFirebase=morehotquipsfirebase
                    self?.refreshControl.endRefreshing()
                }
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
                                                            
                                                                   
                                    if myQuip.isReply{
                                        cell.replyButton.isHidden = true
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
                                                           
                            if myQuip.isReply{
                                    cell.replyButton.isHidden = true
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
                                      if moreTopUserQuipsFirebase {
                                       loadMoreTopUserQuips()
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
            if passedQuip?.isReply ?? false {
                if let aquipId = passedQuip?.quipParent{
                passedQuip = nil
                    FirestoreService.sharedInstance.getQuip(quipID: aquipId) { [weak self](myQuip) in
                        FirebaseService.sharedInstance.getQuipScore(aQuip: myQuip) {[weak self] (aQuip) in
                            FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: (self?.uid)!, aKey: aQuip.user!) {[weak self] (myLikes) in
                                if myLikes[aQuip.quipID!] == 1 {
                                    self?.quipVC?.quipLikeStatus=true
                                }else if myLikes[aQuip.quipID!] == -1{
                                    self?.quipVC?.quipLikeStatus=false
                                }
                                self?.quipVC?.myQuip = aQuip
                                self?.quipVC?.refreshData()
                                
                            }
                           
                        }
                    }
                }
            }
           
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
