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
    
    private var ref:DatabaseReference?
    private var db:Firestore?
    private var storageRef:StorageReference?
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
    private var myLastTopQuipDoc:DocumentSnapshot?
    private var myLastRecentDoc:DocumentSnapshot?
    private var moreTopQuipDocs:Bool = false
    private var tempMoreTopQuipDocs:Bool = false
    private var moreRecentQuips:Bool = false
    private var numOfHotLoads:Int?
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userQuipsTable.delegate=self
        userQuipsTable.dataSource=self
          refreshControl.addTarget(self, action: #selector(ViewControllerUser.refreshData), for: .valueChanged)
          userQuipsTable.refreshControl=refreshControl
              let tabBar = tabBarController as! BaseTabBarController
              self.uid = tabBar.userID
              self.ref = tabBar.refDatabaseFirebase()
              self.db = tabBar.refDatabaseFirestore()
            self.storageRef = tabBar.refStorage()
            loadUserPage()
        
            refreshData()
    }
    
    override func viewDidAppear(_ animated: Bool){
          super.viewDidAppear(animated)
          
          
        }
    
    //updates firestore and firebase with likes when view is dismissed
      override func viewWillDisappear(_ animated: Bool){
             super.viewWillDisappear(animated)

           updateFirestoreLikesDislikes()
          ref?.updateChildValues(myVotes)
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
    
    
    
    func btnSharedTapped(cell: QuipCells) {
              
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
           let docRef = db?.collection("/Users/\(aUID)/LikesDislikes").document(bUId)
                   let batch = self.db?.batch()
                batch?.setData(myNewLikesDislikesMap, forDocument: docRef!, merge: true)
                
                for aKey in myNewLikesDislikesMap.keys{
                    
                    if let myChannel = myChannelsMap[aKey]{
                        let docRefChannel = db?.collection("/Users/\(aUID)/LikesDislikes").document(myChannel)
                        batch?.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel!, merge: true)
                        
                        if let myParentChannel = myParentChannelsMap[aKey]{
                            let docRefChannel = db?.collection("/Users/\(aUID)/LikesDislikes").document(myParentChannel)
                              batch?.setData([aKey:myNewLikesDislikesMap[aKey] as Any], forDocument: docRefChannel!, merge: true)
                        }
                    }else if let myParentQuip = myParentQuipsMap[aKey]{
                        let docRefChannel = db?.collection("/Users/\(aUID)/LikesDislikes").document(myParentQuip)
                        batch?.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel!, merge: true)
                    }
                }
                   batch?.commit()
               
           }
            }
        }
       }
    
    func getUserLikesDislikesForUser(){
         
        if let aUID = uid {
            if let bUId = uid{
                let docRef = db?.collection("/Users/\(aUID)/LikesDislikes").document(bUId)
                  
              
                  docRef?.getDocument{ (document, error) in
                      if let document = document, document.exists {
                        if let myMap = document.data() as? [String : Int]{
                            self.myLikesDislikesMap=myMap
                           
                          } else {
                           self.myLikesDislikesMap = [:]
                          }
                  }
                    self.userQuipsTable.reloadData()
                    self.refreshControl.endRefreshing()
            }
        }
    }
       
    }
       
    
    
    func updateNew(){
       getActiveUserQuips()
       
          
       
          
          
      }
    func getActiveUserQuips(){
        self.newUserQuips = []
        self.myScores = [:]
        self.myTopScores = []
        setCurrentTime()
        let query1 = ref?.child("M/\(uid ?? "Other")/q").queryOrdered(byChild: "s")
        query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
                    
                     let enumerator = snapshot.children
                             while let rest = enumerator.nextObject() as? DataSnapshot {
                                 if rest.key == "z"{
                                     self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                                 
                                 }
                                 else{
                                         
                                     self.myQuipID = rest.key
                                     if let actualkey = self.myQuipID {
                                         
                                        
                                         
                                          let myQuipScore2  = rest.childSnapshot(forPath: "s").value as? Int
                                         let myReplies2  =  rest.childSnapshot(forPath: "r").value as? Int
                                        
                                        
                                        let myQuip = Quip(score: myQuipScore2!, replies: myReplies2 ?? 0, myQuipID: actualkey)
                                        
                                         self.myScores[actualkey]=["s":myQuipScore2,
                                                                   "r":myReplies2 ?? 0]
                                        self.myTopScores.insert(myQuip, at: 0)
                                         
                                         
                                         }
                                     }
                             }
            
            switch self.recentTop.selectedSegmentIndex
                                 {
                                 case 0:
                                    self.getRecentUserQuipsFirestore()
                                  
                                 case 1:
                                    self.getTopUserQuipsFirestore()
                                  
                                 default:
                                     break
                    }
            })
    }
    
    func getRecentUserQuipsFirestore(){
        moreRecentQuips = false
        newUserQuips = []
        let userRecentRef = db?.collection("Users/\(uid ?? "Other")/RecentQuips")
               
               userRecentRef?.order(by: "t", descending: true).limit(to: 2).getDocuments(){ (querySnapshot, err) in
                   if let err = err {
                                   print("Error getting documents: \(err)")
                   }
                   else{
                       let length = querySnapshot!.documents.count
                       if length == 0 {
                           return
                       }
                       for i in 0...length-1{
                        var j = 0
                           let document = querySnapshot!.documents[i]
                       let myQuips = document.data(with: ServerTimestampBehavior.estimate)["quips"] as! [String:Any]
                       let sortedKeys = Array(myQuips.keys).sorted(by: >)
                       for aQuip in sortedKeys{
                           let myInfo = myQuips[aQuip] as! [String:Any]
                           let aQuipID = aQuip
                           let atimePosted = myInfo["d"] as? Timestamp
                           let aQuipText = myInfo["t"] as? String
                           let myChannel = myInfo["c"] as? String
                            let myChannelKey = myInfo["k"] as? String
                        let myChannelParentKey = myInfo["pk"] as? String
                        let isReply = myInfo["reply"] as? Bool
                        
                           
                        var aQuipScore:Int?
                        var aReplies:Int?
                        if let myQuipNumbers = self.myScores[aQuipID] as? [String:Int]{
                            aQuipScore = myQuipNumbers["s"]
                            aReplies = myQuipNumbers["r"]
                        } else {
                            aQuipScore = myInfo["s"] as? Int
                           aReplies = myInfo["r"] as? Int
                            
                        }
                          let myImageRef = myInfo["i"] as? String
                          let myGifRef = myInfo["g"] as? String
                        let myQuip = Quip(text: aQuipText!, bowl: myChannel ?? "Other", time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, replies: aReplies!,myImageRef: myImageRef,myGifID: myGifRef, myChannelKey: myChannelKey,myParentChannelKey: myChannelParentKey, isReply: isReply)
                           self.newUserQuips.append(myQuip)
                        
                        j += 1
                           
                       }
                        if i == 1 {
                        
                               if j == 20  {
                                        self.myLastRecentDoc = document
                                        self.moreRecentQuips = true
                                }
                        }
                   }
                    self.getUserLikesDislikesForUser()
                   }
                
            }
        
    }
      
      func setCurrentTime(){
          
                let timeUpdates = ["d":ServerValue.timestamp(),
                                   "s": 100000] as [String : Any]
               
          ref!.child("M/\(uid ?? "Other")/q/z").updateChildValues(timeUpdates)
          
      }
      
      
      
      func updateTop(){
          
         getTopUserQuipsFirestore()
          
      }
    
    //come back to this i think i am going to make this logic the same way we deal with top channel quips for past channels
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
    
    func loadMoreRecentUserQuips(){
        self.moreRecentQuips = false
        let userRecentRef = db?.collection("Users/\(uid ?? "Other")/RecentQuips")
                      
        userRecentRef?.order(by: "t", descending: true).start(afterDocument: self.myLastRecentDoc!).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                             var i = 0
                          if let err = err {
                                print("Error getting documents: \(err)")
                          }
                          else{
                              let length = querySnapshot!.documents.count
                              if length == 0 {
                                  return
                              }
                              
                                  let document = querySnapshot!.documents[0]
                              let myQuips = document.data(with: ServerTimestampBehavior.estimate)["quips"] as! [String:Any]
                              let sortedKeys = Array(myQuips.keys).sorted(by: >)
                           
                              for aQuip in sortedKeys{
                                  let myInfo = myQuips[aQuip] as! [String:Any]
                                  let aQuipID = aQuip
                                  let atimePosted = myInfo["d"] as? Timestamp
                                  let aQuipText = myInfo["t"] as? String
                                  let myChannel = myInfo["c"] as? String
                                  
                               var aQuipScore:Int?
                               var aReplies:Int?
                               if let myQuipNumbers = self.myScores[aQuipID] as? [String:Int]{
                                   aQuipScore = myQuipNumbers["s"]
                                   aReplies = myQuipNumbers["r"]
                               } else {
                                   aQuipScore = myInfo["s"] as? Int
                                  aReplies = myInfo["r"] as? Int
                                   
                               }
                                 let myImageRef = myInfo["i"] as? String
                                let myGifRef = myInfo["g"] as? String
                                let myChannelKey = myInfo["k"] as? String
                                let myChannelParentKey = myInfo["pk"] as? String
                                let isReply = myInfo["reply"] as? Bool
                               let myQuip = Quip(text: aQuipText!, bowl: myChannel ?? "Other", time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, replies: aReplies!,myImageRef: myImageRef,myGifID: myGifRef, myChannelKey: myChannelKey,myParentChannelKey: myChannelParentKey, isReply: isReply)
                                  self.newUserQuips.append(myQuip)
                                
                                i += 1
                               
                                    
                                }
                            self.userQuipsTable.reloadData()
                                    if i == 20 {
                                            self.myLastRecentDoc = document
                                        self.moreRecentQuips = true
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
                                                                
                                        if let myImageRef = myQuip.imageRef  {
                                            if let aStorageRef = storageRef{
                                                cell.addImageViewToTableCell()
                                                cell.myImageView.getImage(myQuipImageRef: myImageRef, storageRef: aStorageRef, feedTable: self.userQuipsTable)
                                            }
                                                                                                                    
                                        }
                                                                                                                                                       
                                        else if let myGifID = myQuip.gifID  {
                                                                                                                 
                                            cell.addGifViewToTableCell()
                                            cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.userQuipsTable)
                                                                                                                                                           
                                        }
                                                            
                                                                   
                                                                 
                                                            
                                cell.categoryLabel.text = String(indexPath.row)
                                cell.categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
                                cell.quipText?.text = myQuip.quipText
                                                                                                                              
                                if let aQuipScore=myQuip.tempScore{
                                    cell.score?.text = String(aQuipScore)
                                }
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
                                                               
                                       if let myImageRef = myQuip.imageRef  {
                                           if let aStorageRef = storageRef{
                                               cell.addImageViewToTableCell()
                                               cell.myImageView.getImage(myQuipImageRef: myImageRef, storageRef: aStorageRef, feedTable: self.userQuipsTable)
                                           }
                                                                                                                   
                                       }
                                                                                                                                                      
                                       else if let myGifID = myQuip.gifID  {
                                                                                                                
                                           cell.addGifViewToTableCell()
                                           cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.userQuipsTable)
                                                                                                                                                          
                                       }
                                                           
                                                                  
                                                                
                                                           
                               cell.categoryLabel.text = String(indexPath.row)
                               cell.categoryLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
                               cell.quipText?.text = myQuip.quipText
                                                                                                                    
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
                               if let aQuipScore=myQuip.tempScore{
                                   cell.score?.text = String(aQuipScore)
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
            let myCell = userQuipsTable.cellForRow(at: userQuipsTable.indexPathForSelectedRow!) as? QuipCells
                       quipVC?.quipScore = myCell?.score.text
                       if myCell?.upButton.isSelected ?? false {
                           quipVC?.quipLikeStatus = true
                       }
                       else if myCell?.downButton.isSelected ?? false{
                           quipVC?.quipLikeStatus = false
                       }
            quipVC?.myQuip = self.passedQuip
            quipVC?.ref=self.ref
            quipVC?.uid=self.uid
            quipVC?.db=self.db
            quipVC?.storageRef=self.storageRef
            quipVC?.currentTime = self.currentTime
            quipVC?.parentViewUser = self
            quipVC?.passedQuipCell = myCell
            userQuipsTable.deselectRow(at: userQuipsTable.indexPathForSelectedRow!, animated: false)
            
        }
        else{
            
        }
    }
    

}
