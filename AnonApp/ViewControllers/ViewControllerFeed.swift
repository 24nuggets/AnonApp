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

class ViewControllerFeed: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate {
   
    
    
    

    var myChannel:Channel?
    var ref:DatabaseReference?
    var db:Firestore?
    var storageRef:StorageReference?
    private var timesDownloaded:Int=0
    private var newQuips:[Quip?] = []
    private var hotQuips:[Quip?] = []
    private var currentTime:Double?
    private var writeQuip:ViewControllerWriteQuip?
    var uid:String?
    private var passedQuip:Quip?
    private var quipVC:ViewControllerQuip?
    private var myScores:[String:Any]=[:]
    private var myHotIDs:[String]=[]
    private var hotQuipsInfo:[String:Any]=[:]
    private var hotQuipAdds:[String]=[]
    private var myNewHotQuipData:[String:Any] = [:]
    private var lastRecentKeyFirebase:String?
    private var moreRecentQuipsFirebase:Bool = false
    private var moreRecentQuipsFirestore:Bool = false
    private var tempMoreRecentQuipsFirebase:Bool = false
    private var tempMoreRecentQuipsFirestore:Bool = false
    private var moreHotQuipsFirebase:Bool = false
    private var lastHotQuipKeyFirebase:String?
    private var tempMoreHotQuipsFirebase:Bool = false
    private var lastRecentDocumentFirestore:DocumentSnapshot?
    private var lastHotDocumentFirestore:DocumentSnapshot?
    private var lastHotScore:Int?
    private var myVotes:[String:Any] = [:]
     var myLikesDislikesMap:[String:Int] = [:]
     var myNewLikesDislikesMap:[String:Int] = [:]
    var myUserMap:[String:String] = [:]
    private var refreshControl=UIRefreshControl()
    
    @IBOutlet weak var feedTable: UITableView!
    @IBOutlet weak var topBar: UINavigationItem!
    @IBOutlet weak var newHot: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
      //  self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        
        //gets rid of border between the two navigation bars on top
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        feedTable.delegate=self
        feedTable.dataSource=self
        refreshControl.addTarget(self, action: #selector(ViewControllerFeed.refreshData), for: .valueChanged)
        feedTable.refreshControl=refreshControl
        //notification when app will enter foreground
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
       topBar.title = myChannel?.channelName
        resetVars()
        //move user likes so its asynchronous in loading process
        
       
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
        myUserMap=[:]
        myNewLikesDislikesMap=[:]
        myVotes=[:]
    }
    
    @objc func appWillEnterForeground() {
          //checks if this view controller is the first one visible
           if self.viewIfLoaded?.window != nil {
               // viewController is visible
               onLoad()
           }
       }
    
    //deinitializer for notification center
    deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
    // MARK: - ActionFunctions
    
    @IBAction func newHotValueChange(_ sender: Any) {
        switch newHot.selectedSegmentIndex
           {
           case 0:
               
                         updateNew()
                
            
           case 1:
               
                        updateHot()
                   
            
           default:
               break
           }
    }
    
    func btnSharedTapped(cell: QuipCells) {
            // text to share
                  let myactivity1 = cell.quipText.text
                   let myactivity2 = "quipit link"
           
                  // set up activity view controller
           let firstactivity = [myactivity1, myactivity2]
           let activityViewController = UIActivityViewController(activityItems: firstactivity as [Any], applicationActivities: nil)
                  activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

                  // exclude some activity types from the list (optional)
           activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]

                  // present the view controller
                  self.present(activityViewController, animated: true, completion: nil)
          }
    
    func btnUpTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
        if let indexPath = self.feedTable.indexPath(for: cell){
        switch newHot.selectedSegmentIndex
        {
        case 0:
            if let myQuip = newQuips[indexPath.row]{
            upButtonPressed(aQuip: myQuip, cell: cell)
            }
         
        case 1:
            if let myQuip = hotQuips[indexPath.row]{
            upButtonPressed(aQuip: myQuip, cell: cell)
            }
         
        default:
            break
        }
        }
    }
    
    func btnDownTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
        if let indexPath = self.feedTable.indexPath(for: cell){
        switch newHot.selectedSegmentIndex
        {
        case 0:
            if let myQuip = newQuips[indexPath.row]{
            downButtonPressed(aQuip: myQuip, cell: cell)
            }
         
        case 1:
            
            if let myQuip = hotQuips[indexPath.row]{
            downButtonPressed(aQuip: myQuip, cell: cell)
            }
         
        default:
            break
        }
        }
        
    }
    
   
    // MARK: - Like/Dislike Logic
    
    //each if statement:
    //1. updates cell to reflect changes
    //2. adds votes to firebase array
    //3. adds votes to newlikesdislikes map - this is never read just used to push changes to database
    //4. adds votes to current likesdislikes map - this is so changes are reflected when scrolling back and forth
    //5. adds user id to dict so it can be easily found when votes in firestore are commited
    
    func downButtonPressed(aQuip:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
               if let aQuipScore = aQuip.quipScore{
                let diff = cell.upToDown(quipScore: aQuipScore, quip: aQuip)
                    if let aID = aQuip.quipID{
                        updateVotesFirebase(diff: diff, quipID: aID)
                        myNewLikesDislikesMap[aID] = -1
                        myLikesDislikesMap[aID] = -1
                        myUserMap[aID]=aQuip.user
                    }
            }
        }
        else if cell.downButton.isSelected {
               if let aQuipScore = aQuip.quipScore{
                let diff = cell.downToNone(quipScore: aQuipScore, quip: aQuip)
                    if let aID = aQuip.quipID{
                        updateVotesFirebase(diff: diff, quipID: aID)
                        myNewLikesDislikesMap[aID]=0
                        myLikesDislikesMap[aID]=0
                        myUserMap[aID]=aQuip.user
                    }
                
            }
        }
        else{
             if let aQuipScore = aQuip.quipScore{
                let diff = cell.noneToDown(quipScore: aQuipScore, quip:aQuip)
                if let aID = aQuip.quipID{
                    updateVotesFirebase(diff: diff, quipID: aID)
                    myNewLikesDislikesMap[aID] = -1
                    myLikesDislikesMap[aID] = -1
                    myUserMap[aID]=aQuip.user
                }
            }
            
        }
        
    }
    func upButtonPressed(aQuip:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
            if let aQuipScore = aQuip.quipScore{
                let diff = cell.upToNone(quipScore: aQuipScore, quip:aQuip)
                if let aID = aQuip.quipID{
                    updateVotesFirebase(diff: diff, quipID: aID)
                    myNewLikesDislikesMap[aID]=0
                    myLikesDislikesMap[aID]=0
                    myUserMap[aID]=aQuip.user
                    }
                    
            }
             }
             else if cell.downButton.isSelected {
                if let aQuipScore = aQuip.quipScore{
                    let diff = cell.downToUp(quipScore: aQuipScore, quip:aQuip)
                        if let aID = aQuip.quipID{
                            updateVotesFirebase(diff: diff, quipID: aID)
                            myNewLikesDislikesMap[aID] = 1
                            myLikesDislikesMap[aID] = 1
                            myUserMap[aID]=aQuip.user
                        }
                    }
                }
             else{
                if let aQuipScore = aQuip.quipScore{
                    let diff = cell.noneToUp(quipScore: aQuipScore, quip:aQuip)
                    if let aID = aQuip.quipID{
                        updateVotesFirebase(diff: diff, quipID: aID)
                        myNewLikesDislikesMap[aID] = 1
                        myLikesDislikesMap[aID] = 1
                        myUserMap[aID]=aQuip.user
                    }
                }
             }
        
    }
    
     // MARK: - putVotesToDatabase
    
    func updateVotesFirebase(diff:Int, quipID:String){
        //increment value has to be double or long or it wont work properly
        let myDiff = Double(diff)
        if let aChannelKey = myChannel?.key {
            myVotes["A/\(aChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
        }
        if let aParentChannelKey = myChannel?.parentKey {
            myVotes["A/\(aParentChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
        }
        if let aUID = uid {
        myVotes["M/\(aUID)/q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
        }
    }
    
    func updateFirestoreLikesDislikes(){
        if myNewLikesDislikesMap.count>0{
            if let aUID = uid {
                let batch = self.db?.batch()
                if let aChannelKey = myChannel?.key{
                    let docRef = db?.collection("/Users/\(aUID)/LikesDislikes").document(aChannelKey)
                    
                    batch?.setData(myNewLikesDislikesMap, forDocument: docRef!,merge: true)
                }
                for aKey in myNewLikesDislikesMap.keys{
                                   
                                   if let myUser = myUserMap[aKey]{
                                       let docRefChannel = db?.collection("/Users/\(aUID)/LikesDislikes").document(myUser)
                                    batch?.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel!, merge: true)
                                   }
                }
                batch?.commit()
                myNewLikesDislikesMap = [:]
            }
        }
    }
    
    // MARK: - GetFirestoreVotes
    
    func getUserLikesDislikesForChannel(){
          
        if let aUid = uid{
            if let aChannelKey = myChannel?.key{
            
           let docRef = db?.collection("/Users/\(aUid)/LikesDislikes").document(aChannelKey)
                  
              
                  docRef?.getDocument{ (document, error) in
                      if let document = document, document.exists {
                        if let myMap = document.data() as? [String:Int]{
                            self.myLikesDislikesMap=myMap
                        }
                        
                      
                       
                      } else {
                       self.myLikesDislikesMap = [:]
                        
                      }
                    self.feedTable.reloadData()
                    self.refreshControl.endRefreshing()
                  }
                
            }
        }
           
       }
       
    
    
    
   
    
    func onLoad(){
        
        
        switch newHot.selectedSegmentIndex
        {
           case 0:
          
                updateNew()
           
           case 1:
           
               updateHot()
               
           
           default:
               break
           }
        
    }
    
    func setCurrentTime(){
        if let myChannelKey = myChannel?.key{
           let timeUpdates = ["d":ServerValue.timestamp(),
                              "s":10000] as [String : Any]
           ref?.child("A/" + myChannelKey + "/Q/z").updateChildValues(timeUpdates)
        }
       }
    
    
    // MARK: - LoadNewQuips
    
    func updateNew(){
       
            self.newQuips = []
            self.myScores = [:]
            setCurrentTime()
        self.lastRecentKeyFirebase = ""
        self.moreRecentQuipsFirebase = false
        if let myChannelKey = myChannel?.key{
        let query1 = ref?.child("A/" + myChannelKey + "/Q").queryOrderedByKey().queryLimited(toLast:  41)
        //query should be limited to double the firestore doc storage plus 1 to account for fetching time, could have extra as well
       
        query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
            
             var i = 0
            let enumerator = snapshot.children
            var tempLastRecentkey:String?
            while let rest = enumerator.nextObject() as? DataSnapshot {
                 i += 1
                if rest.key == "z"{
                    self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                
                }
                else{
                        
                   let aQuipID:String? = rest.key
                    if let actualkey = aQuipID {
                        if i == 0 {
                         tempLastRecentkey = actualkey
                        }
                       
                        
                        let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                        let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                       
                        self.myScores[actualkey]=["s":myQuipScore2,
                                                  "r":myReplies2]
                        
                       
                     
                        if i == 41 {
                            self.lastRecentKeyFirebase = tempLastRecentkey!
                            self.moreRecentQuipsFirebase = true
                            
                        }
                       
                        }
                    }
            }
           
           
            self.getRecentFirestoreQuips()
                  
            })
        }
        
    }
    
    func getRecentFirestoreQuips(){
        if let myChannelKey = myChannel?.key{
        let channelRef = db?.collection("Channels/\(myChannelKey)/RecentQuips")
        self.moreRecentQuipsFirestore = false
        //gets 2 most recent documents that have quips
        channelRef?.order(by: "t", descending: true).limit(to: 2).getDocuments(){ (querySnapshot, err) in
            if let err = err {
                            print("Error getting documents: \(err)")
            }
            else{
                let length = querySnapshot!.documents.count
                if length == 0 {
                    return
                }
                
                for i in 0...length-1{
                    if i == 0 {
                        continue
                    }
                    
                    let document = querySnapshot!.documents[i]
                
                    if i == 2{
                        self.lastRecentDocumentFirestore = document
                        self.moreRecentQuipsFirestore = true
                    }
                    
                    guard document.data(with: ServerTimestampBehavior.estimate)["quips"] != nil else {continue}
                    let myQuips = document.data(with: ServerTimestampBehavior.estimate)["quips"] as! [String:Any]
                let sortedKeys = Array(myQuips.keys).sorted(by: >)
                
                for aQuip in sortedKeys{
                    let myInfo = myQuips[aQuip] as! [String:Any]
                    let aQuipID = aQuip
                    let atimePosted = myInfo["d"] as? Timestamp
                    let aQuipText = myInfo["t"] as? String
                    let myAuthor = myInfo["a"] as? String
                    
                    
                   
                    guard let myQuipNumbers = self.myScores[aQuipID] as? [String:Int] else {continue}
                    let aQuipScore = myQuipNumbers["s"]
                    let aReplies = myQuipNumbers["r"]
                   let myImageRef = myInfo["i"] as? String
                    
                    
                    let myGifRef = myInfo["g"] as? String
                    let myQuip = Quip(text: aQuipText!, bowl: (self.myChannel?.channelName)!, time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, author: myAuthor!, replies: aReplies!, myImageRef: myImageRef, myGifID: myGifRef)
                  
                        self.newQuips.append(myQuip)
                  
                    
                }
                
            }
                self.getUserLikesDislikesForChannel()
                
            }
            
        }
        
        }
    }
    
    func loadMoreRecentFirebase(){
           moreRecentQuipsFirebase=false
        //need temp because dont want to change it and have another thread call it again before this one is done executing
        tempMoreRecentQuipsFirebase = false
        //limited to last should be at least the size of a firestore doc + 1 becasue one of the ones retrieved will be the quip we ended at last time
           let query1 = ref?.child("A/" + (myChannel?.key)! + "/Q").queryOrderedByKey().queryLimited(toLast:  21).queryEnding(atValue:lastRecentKeyFirebase)
                  query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
                   self.lastRecentKeyFirebase = ""
                       var i = 0
                      let enumerator = snapshot.children
                   var tempLastRecentkey:String?
                      while let rest = enumerator.nextObject() as? DataSnapshot {
                         i += 1
                          if rest.key == "z"{
                              self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                          
                          }
                          else{
                                  
                            let aQuipID:String? = rest.key
                              if let actualkey = aQuipID {
                                  
                               if i == 0 {
                                   tempLastRecentkey = actualkey
                               }
                                  
                                  let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                  let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                  
                                  self.myScores[actualkey]=["s":myQuipScore2,
                                                            "r":myReplies2]
                                  
                                  
                              
                                   if i == 21 {
                                       self.lastRecentKeyFirebase = tempLastRecentkey!
                                           self.tempMoreRecentQuipsFirebase = true
                                                        
                                   }
                                  }
                              }
                      }
                     
                     
                      self.loadMoreRecentQuipsFirestore()
                            
                      })
           
       }
       func loadMoreRecentQuipsFirestore(){
           moreRecentQuipsFirestore = false
           tempMoreRecentQuipsFirestore=false
        if let myChannelKey = myChannel?.key{
           let channelRef = db?.collection("Channels/\(myChannelKey)/RecentQuips")
            
           channelRef?.order(by: "t", descending: true).start(afterDocument: self.lastRecentDocumentFirestore!).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                     if let err = err {
                                     print("Error getting documents: \(err)")
                     }
                     else{
                         let length = querySnapshot!.documents.count
                         if length == 0 {
                             return
                         }
                         
                        
                            
                         
                             
                             let document = querySnapshot!.documents[0]
                          
                                   self.lastRecentDocumentFirestore = document
                                   self.tempMoreRecentQuipsFirestore = true
                           
                             
                             guard document.data(with: ServerTimestampBehavior.estimate)["quips"] != nil else {return}
                             let myQuips = document.data(with: ServerTimestampBehavior.estimate)["quips"] as! [String:Any]
                         let sortedKeys = Array(myQuips.keys).sorted(by: >)
                         for aQuip in sortedKeys{
                             let myInfo = myQuips[aQuip] as! [String:Any]
                             let aQuipID = aQuip
                             let atimePosted = myInfo["d"] as? Timestamp
                             let aQuipText = myInfo["t"] as? String
                             let myAuthor = myInfo["a"] as? String
                            
                             guard let myQuipNumbers = self.myScores[aQuipID] as? [String:Int] else {continue}
                             let aQuipScore = myQuipNumbers["s"]
                             let aReplies = myQuipNumbers["r"]
                             let myImageRef = myInfo["i"] as? String
                            let myGifRef = myInfo["g"] as? String
                            let myQuip = Quip(text: aQuipText!, bowl: (self.myChannel?.channelName)!, time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, author: myAuthor!, replies: aReplies!, myImageRef: myImageRef, myGifID: myGifRef)
                             self.newQuips.append(myQuip)
                             
                         }
                         
                     
                         self.feedTable.reloadData()
                        //have to reload table before setting these to true
                       if self.tempMoreRecentQuipsFirestore {
                           self.moreRecentQuipsFirestore = true
                       }
                       if self.tempMoreRecentQuipsFirebase {
                           self.moreRecentQuipsFirebase = true
                       }
                     }
                     
                 }
        }
       }
    
   
    
   
    
     // MARK: - LoadHotQuips
    
    func updateHot(){
        setCurrentTime()
        self.hotQuips = []
        self.myHotIDs = []
        
        moreHotQuipsFirebase = false
        let query1 = ref?.child("A/" + (myChannel?.key)! + "/Q").queryOrdered(byChild: "s").queryLimited(toLast: 10)
       
        query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
            
            let enumerator = snapshot.children
            var i = 0
            var tempLastHotKeyFirebase:String?
            var tempHotScore:Int?
            while let rest = enumerator.nextObject() as? DataSnapshot {
                 i += 1
               if rest.key == "z"{
                    self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                
                }
                else{
                        
                var aQuipID:String?
                aQuipID = rest.key
                
                                      if  let actualkey = aQuipID{
                                          
                                       
                                          
                                          let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                          let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                         
                                        let myQuip = Quip(score: myQuipScore2!, replies: myReplies2!, myQuipID: actualkey)
                                        if i == 0 {
                                            tempLastHotKeyFirebase = actualkey
                                            tempHotScore = myQuipScore2
                                        }
                                                                 
                                          self.hotQuips.insert(myQuip, at: 0)
                                        self.myHotIDs.append(actualkey)
                                        
                                        
                                       
                                                               
                                        if i == 10 {
                                            self.lastHotQuipKeyFirebase = tempLastHotKeyFirebase
                                            self.lastHotScore=tempHotScore
                                            self.moreHotQuipsFirebase = true
                                                }
                                       }
               
                                               
                        
                        }
                    }
            
            self.getHotQuipsFromFirestore(aHotIDs: self.myHotIDs)
            
        })
        
    }
    func getHotQuipsFromFirestore(aHotIDs:[String]){
        if let myChannelKey = myChannel?.key{
             let channelRef = db?.collection("Channels/\(myChannelKey)/HotQuips")
            channelRef?.order(by: "t", descending: false).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                  if let err = err {
                                  print("Error getting documents: \(err)")
                  }
                  else{
                    if let querySnapshot = querySnapshot{
                      let length = querySnapshot.documents.count
                      if length == 0 {
                       
                        self.createHotQuipsDoc(aHotIDs: aHotIDs, aHotQuips: self.hotQuips, more:false)
                        
                      }
                      else if self.compareHotQuips(doc: querySnapshot.documents[0], aHotIDs: aHotIDs)==false{
                        self.updateHotQuipsDoc(doc: querySnapshot.documents[0],aHotQuips: self.hotQuips, more:false)
                        self.lastHotDocumentFirestore = querySnapshot.documents[0]
        
                      }else{
                        self.populateHotQuipsArr(data: querySnapshot.documents[0].data(), aHotQuips: self.hotQuips, more:false)
                        self.lastHotDocumentFirestore = querySnapshot.documents[0]
                        }
                   
                    }
                    
                      
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
                
            }
            }
            
        }
        if more{
            self.hotQuips = self.hotQuips + aHotQuips
        }
        self.feedTable.reloadData()
        if tempMoreHotQuipsFirebase {
            moreHotQuipsFirebase = true
        }
        
    }
   
    func updateHotQuipsDoc(doc:DocumentSnapshot, aHotQuips:[Quip?], more:Bool){
       
        var i:Int = 0
        
        for aHotId in self.hotQuipAdds{
               self.db?.collection("Quips").document(aHotId).getDocument { (document, error) in
                   if let document = document, document.exists {
                    let data = document.data(with: ServerTimestampBehavior.estimate)
                    self.myNewHotQuipData[aHotId] = data
                     i += 1
                   }
                if i == self.hotQuipAdds.count{
                
                    
                    doc.reference.updateData(self.myNewHotQuipData)
                    self.populateHotQuipsArr(data: self.myNewHotQuipData, aHotQuips:aHotQuips, more:more )
                }
               }
               
            }
        
    }
  
    func compareHotQuips(doc:DocumentSnapshot, aHotIDs:[String])->Bool{
        self.hotQuipAdds = []
        let myData = doc.data(with: ServerTimestampBehavior.estimate)! as [String:Any]
        self.myNewHotQuipData = [:]
        var isSame = true
        for aHotId in aHotIDs{
            let keyExists = myData[aHotId] != nil
            if keyExists{
                myNewHotQuipData[aHotId] = myData[aHotId]
            }
            else{
                isSame = false
                hotQuipAdds.append(aHotId)
               
                    }
            }
        
        
        return isSame
    }
    
    func createHotQuipsDoc(aHotIDs:[String], aHotQuips:[Quip?], more:Bool){
        var i:Int = 0
        var myData:[String:Any] = [:]
        for aHotId in aHotIDs{
           self.db?.collection("Quips").document(aHotId).getDocument { (document, error) in
               if let document = document, document.exists {
                let data = document.data(with: ServerTimestampBehavior.estimate)
                myData[aHotId] = data
                i += 1
               }
            if i == self.myHotIDs.count{
            myData["t"] = FieldValue.serverTimestamp()
                if let myChannelKey = self.myChannel?.key{
                let docRef=self.db?.collection("Channels/\(myChannelKey)/HotQuips").addDocument(data: myData)
              //   sleep(1)
                self.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more:more)
                docRef?.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.lastHotDocumentFirestore = document
                 
                    }
                    }
                }
           }
           
        }
       
    }
    }
   
    
   
    func loadMoreHotQuipsFirebase(){
        moreHotQuipsFirebase = false
        tempMoreHotQuipsFirebase = false
        let query1 = ref?.child("A/" + (myChannel?.key)! + "/Q").queryOrdered(byChild: "s").queryLimited(toLast: 10).queryEnding(atValue: self.lastHotScore, childKey: self.lastHotQuipKeyFirebase)
              
               query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
                let count = snapshot.childrenCount
                   let enumerator = snapshot.children
                var i = 0
                var tempLastHotKeyFirebase:String?
                var tempHotScore:Int?
                var aHotQuips:[Quip] = []
                var aHotIDs:[String] = []
                
                   while let rest = enumerator.nextObject() as? DataSnapshot {
                   
                    if i == count - 1{
                        continue
                    }
                      if rest.key == "z"{
                           self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                       
                       }
                       else{
                               
                       var aQuipID:String?
                       aQuipID = rest.key
                                    if  let actualkey = aQuipID{
                                                 
                                                
                                                 
                                        let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                        let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                                
                                        let myQuip = Quip(score: myQuipScore2!, replies: myReplies2!, myQuipID: actualkey)
                                               
                                                                        
                                                 aHotQuips.insert(myQuip, at: 0)
                                               aHotIDs.append(actualkey)
                                                if i == 0 {
                                                    tempLastHotKeyFirebase = actualkey
                                                    tempHotScore = myQuipScore2
                                                }
                                                i += 1
                                                                            
                                            if i == 9 {
                                            self.lastHotQuipKeyFirebase = tempLastHotKeyFirebase
                                                self.lastHotScore = tempHotScore
                                            self.tempMoreHotQuipsFirebase = true
                                                }
                                        }
                        
                               
                               }
                           }
                   
                   self.loadMoreHotQuipsFireStore(aHotQuips: aHotQuips, aHotIDs: aHotIDs)
                   
               })
        
        
    }
    func loadMoreHotQuipsFireStore(aHotQuips:[Quip], aHotIDs:[String]){
        if let myChannelKey = myChannel?.key{
        let channelRef = db?.collection("Channels/\(myChannelKey)/HotQuips")
        channelRef?.order(by: "t", descending: false).start(afterDocument: self.lastHotDocumentFirestore!).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                   if let err = err {
                                   print("Error getting documents: \(err)")
                   }
                   else{
                       let length = querySnapshot!.documents.count
                       if length == 0 {
                        self.createHotQuipsDoc(aHotIDs: aHotIDs, aHotQuips: aHotQuips, more:true)
                       }
                       else if self.compareHotQuips(doc: querySnapshot!.documents[0],aHotIDs: aHotIDs)==false{
                        self.updateHotQuipsDoc(doc: querySnapshot!.documents[0], aHotQuips: aHotQuips, more:true)
                        self.lastHotDocumentFirestore = querySnapshot!.documents[0]
                       }else{
                        self.populateHotQuipsArr(data: querySnapshot!.documents[0].data(), aHotQuips: aHotQuips, more:true)
                        self.lastHotDocumentFirestore = querySnapshot!.documents[0]
                         }
                    
                     
                    
                       
                   }
                   
               }
        }
        
    }
    
 
   
    
  
    
    
  
    // MARK: - TableViewFunctions
   
    @objc func refreshData(){
        refreshControl.beginRefreshing()
        switch newHot.selectedSegmentIndex
              {
                 case 0:
                
                      updateNew()
                 
                 case 1:
                 
                     updateHot()
                     
                 
                 default:
                     break
                 }
       
    }
  
    
   
    
    //gets number of sections for tableview
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch newHot.selectedSegmentIndex
        {
        case 0:
            return newQuips.count
         
        case 1:
            return hotQuips.count
         
        default:
            break
        }
        return 0
    }
   func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       
        switch newHot.selectedSegmentIndex
        {
            case 0:
                 break
                  
            case 1:
                break
            
            default:
                break
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       
        if let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? QuipCells {
         switch newHot.selectedSegmentIndex
               {
               case 0:
                    if newQuips.count > 0 {
                        
                            if let myQuip = self.newQuips[indexPath.row]{
                                    
                                        if let myImageRef = myQuip.imageRef  {
                                            if let aStorageRef = storageRef{
                                                cell.addImageViewToTableCell()
                                                cell.myImageView.getImage(myQuipImageRef: myImageRef, storageRef: aStorageRef, feedTable: self.feedTable)
                                            }
                                                                                        
                                        }
                                                                                                                           
                                        else if let myGifID = myQuip.gifID  {
                                                                                     
                                                cell.addGifViewToTableCell()
                                                cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.feedTable)
                                                                                                                               
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
                   if hotQuips.count > 0 {
                    if let myQuip = self.newQuips[indexPath.row]{
                    if let myImageRef = myQuip.imageRef {
                        if let aStorage = storageRef{
                            cell.addImageViewToTableCell()
                            cell.myImageView.getImage(myQuipImageRef: myImageRef, storageRef: aStorage, feedTable: self.feedTable)
                        }
                                                     
                    }
                                                                                        
                    else if let gifID = myQuip.gifID {
                                                  
                            cell.addGifViewToTableCell()
                            cell.myGifView.getImageFromGiphy(gifID: gifID, feedTable:self.feedTable)
                                                                                            
                    }
                   
                    
                    cell.quipText?.text = myQuip.quipText
                        if let aQuipScore=myQuip.tempScore {
                    cell.score?.text = String(aQuipScore)
                        }
                    if let dateVal = myQuip.timePosted?.seconds{
                        let milliTimePost = dateVal * 1000
                        cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
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
                              else{
                                  return cell
                              }
            }
                
               default:
                   break
               }
            cell.downButton.changeButtonWeight()
            cell.upButton.changeButtonWeight()
            cell.delegate = self
       
        return cell
        }
        return UITableViewCell()
    }
    
   
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
           
                   
                  
                       // handle your logic here to get more items, add it to dataSource and reload tableview
                       switch newHot.selectedSegmentIndex
                              {
                              case 0:
                               if moreRecentQuipsFirebase {
                                  loadMoreRecentFirebase()
                                    moreRecentQuipsFirestore = false
                               }
                               else if moreRecentQuipsFirestore{
                                   loadMoreRecentQuipsFirestore()
                               }
                              case 1:
                                   if moreHotQuipsFirebase {
                                    loadMoreHotQuipsFirebase()
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
        if let index = feedTable.indexPathForSelectedRow?.row {
             switch newHot.selectedSegmentIndex
                   {
                   case 0:
                      passedQuip = newQuips[index]
                    
                   case 1:
                       passedQuip = hotQuips[index]
                    
                   default:
                       break
                   }
            quipVC = segue.destination as? ViewControllerQuip
            let myCell = feedTable.cellForRow(at: feedTable.indexPathForSelectedRow!) as? QuipCells
            quipVC?.quipScore = myCell?.score.text
            if myCell?.upButton.isSelected == true {
                quipVC?.quipLikeStatus = true
            }
            else if myCell?.downButton.isSelected == true{
                quipVC?.quipLikeStatus = false
            }
            quipVC?.myQuip = self.passedQuip
            quipVC?.ref=self.ref
            quipVC?.uid=self.uid
            quipVC?.db=self.db
            quipVC?.myChannel=self.myChannel
            quipVC?.storageRef = self.storageRef
            quipVC?.currentTime = self.currentTime
            quipVC?.parentViewFeed = self
            quipVC?.passedQuipCell = myCell
           feedTable.deselectRow(at: feedTable.indexPathForSelectedRow!, animated: false)
            
        }else{
            if let writeQuip = segue.destination as? ViewControllerWriteQuip{
        
        
        writeQuip.myChannel = self.myChannel
        writeQuip.ref=self.ref
        writeQuip.db=self.db
        writeQuip.storageRef=self.storageRef
        writeQuip.uid=self.uid
        
        newHot.selectedSegmentIndex = 0
            }
            
            
        }
    }
    
   

}


