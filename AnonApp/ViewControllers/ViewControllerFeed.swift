//
//  ViewControllerFeed.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/17/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerFeed: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate {
   
    
    
    

    var myChannel:Channel?
    var ref:DatabaseReference?
    var db:Firestore?
  
    private var timesDownloaded:Int=0
    private var myQuipID:String?
    private var myQuipText:String?
    private var myQuipChannel:String?
    private var myQuipScore:String?
    private var timePosted:String?
    private var myReplies:String?
    private var author:String?
    private var newQuips:[Quip] = []
    private var hotQuips:[Quip] = []
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
    
    @IBOutlet weak var feedTable: UITableView!
    @IBOutlet weak var topBar: UINavigationItem!
    @IBOutlet weak var newHot: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
        
        feedTable.delegate=self
        feedTable.dataSource=self
        
         NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
       
    }
    

    override func viewWillAppear(_ animated: Bool){
         super.viewWillAppear(animated)
        
         onLoad()
         
       }
    override func viewWillDisappear(_ animated: Bool){
           super.viewWillDisappear(animated)
          
        ref?.updateChildValues(myVotes)
           
         }
    
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
    
    func btnUpTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
        let indexPath = self.feedTable.indexPath(for: cell)
        switch newHot.selectedSegmentIndex
        {
        case 0:
            let myQuip = newQuips[indexPath!.row]
            upButtonPressed(aQuip: myQuip, cell: cell)
             
         
        case 1:
            let myQuip = hotQuips[indexPath!.row]
            upButtonPressed(aQuip: myQuip, cell: cell)
                
         
        default:
            break
        }
        
    }
    
    func btnDownTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
        let indexPath = self.feedTable.indexPath(for: cell)
        switch newHot.selectedSegmentIndex
        {
        case 0:
            let myQuip = newQuips[indexPath!.row]
            downButtonPressed(aQuip: myQuip, cell: cell)
             
         
        case 1:
            let myQuip = hotQuips[indexPath!.row]
            downButtonPressed(aQuip: myQuip, cell: cell)
                
         
        default:
            break
        }
        
        
    }
    
    func btnSharedTapped(cell: QuipCells) {
           return
       }
    
    
    func downButtonPressed(aQuip:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
                cell.upButton.isSelected = false
                cell.downButton.isSelected = true
                let originalScore = Int(cell.score.text!)
                cell.score.text = String(originalScore! - 2)
            myVotes["A/\(myChannel?.key ?? "Other")/Q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(-1)
            myVotes["M/\(uid ?? "Other")/q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(-1)
                                
        }
        else if cell.downButton.isSelected {
                cell.downButton.isSelected=false
                let originalScore = Int(cell.score.text!)
                cell.score.text = String(originalScore! + 1)
            myVotes.removeValue(forKey: "A/\(myChannel?.key ?? "Other")/Q/\(aQuip.quipID ?? "Other")/s")
            myVotes.removeValue(forKey: "M/\(uid ?? "Other")/q/\(aQuip.quipID ?? "Other")/s")
                              
        }
        else{
                cell.downButton.isSelected=true
                let originalScore = Int(cell.score.text!)
                cell.score.text = String(originalScore! - 1)
            myVotes["A/\(myChannel?.key ?? "Other")/Q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(-1)
            myVotes["M/\(uid ?? "Other")/q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(-1)
                            
        }
        
    }
    func upButtonPressed(aQuip:Quip, cell:QuipCells){
        if cell.upButton.isSelected {
                 cell.upButton.isSelected = false
                 let originalScore = Int(cell.score.text!)
                 cell.score.text = String(originalScore! - 1)
            myVotes.removeValue(forKey: "A/\(myChannel?.key ?? "Other")/Q/\(aQuip.quipID ?? "Other")/s")
            myVotes.removeValue(forKey: "M/\(uid ?? "Other")/q/\(aQuip.quipID ?? "Other")/s")
               
                 
             }
             else if cell.downButton.isSelected {
                 cell.downButton.isSelected=false
                 cell.upButton.isSelected=true
                 let originalScore = Int(cell.score.text!)
                 cell.score.text = String(originalScore! + 2)
            myVotes["A/\(myChannel?.key ?? "Other")/Q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(1)
                myVotes["M/\(uid ?? "Other")/q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(1)
                 
                 
             }
             else{
                 cell.upButton.isSelected=true
                 let originalScore = Int(cell.score.text!)
                 cell.score.text = String(originalScore! + 1)
                myVotes["A/\(myChannel?.key ?? "Other")/Q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(1)
                myVotes["M/\(uid ?? "Other")/q/\(aQuip.quipID ?? "Other")/s"] = ServerValue.increment(1)
                 
             }
        
    }
    
    
    //deinitializer for notification center
       deinit {
              NotificationCenter.default.removeObserver(self)
          }
    
    
    @objc func appWillEnterForeground() {
       //checks if this view controller is the first one visible
        if self.viewIfLoaded?.window != nil {
            // viewController is visible
            onLoad()
        }
    }
    
    func onLoad(){
        topBar.title = myChannel?.channelName
        
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
    
    
    func updateNew(){
        
        
        
       
            self.newQuips = []
            self.myScores = [:]
            setCurrentTime()
        self.lastRecentKeyFirebase = ""
        self.moreRecentQuipsFirebase = false
        let query1 = ref?.child("A/" + (myChannel?.key)! + "/Q").queryOrderedByKey().queryLimited(toLast:  9)
        
       
        query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
            
             var i = 0
            let enumerator = snapshot.children
            var tempLastRecentkey:String?
            while let rest = enumerator.nextObject() as? DataSnapshot {
                if rest.key == "z"{
                    self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                
                }
                else{
                        
                    self.myQuipID = rest.key
                    if let actualkey = self.myQuipID {
                        if i == 0 {
                         tempLastRecentkey = actualkey
                        }
                       
                        
                        let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                        let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                       
                        self.myScores[actualkey]=["s":myQuipScore2,
                                                  "r":myReplies2]
                        
                        i += 1
                        if i == 8 {
                            self.lastRecentKeyFirebase = tempLastRecentkey!
                            self.moreRecentQuipsFirebase = true
                            
                        }
                       
                        }
                    }
            }
           
           
            self.getRecentFirestoreQuips()
                  
            })
        
    }
    
    func getRecentFirestoreQuips(){
        let channelRef = db?.collection("Channels/\(myChannel?.key ?? "Other")/RecentQuips")
        self.moreRecentQuipsFirestore = false
        channelRef?.order(by: "t", descending: true).limit(to: 3).getDocuments(){ (querySnapshot, err) in
            if let err = err {
                            print("Error getting documents: \(err)")
            }
            else{
                let length = querySnapshot!.documents.count
                if length == 0 {
                    return
                }
                
                for i in 0...length-1{
                    if i == 0{
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
                    let myQuip = Quip(text: aQuipText!, bowl: (self.myChannel?.channelName)!, time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, author: myAuthor!, replies: aReplies!)
                    self.newQuips.append(myQuip)
                    
                }
                
            }
                self.feedTable.reloadData()
            }
            
        }
        
    
    }
    
    func loadMoreRecentFirebase(){
           moreRecentQuipsFirebase=false
        tempMoreRecentQuipsFirebase = false
           let query1 = ref?.child("A/" + (myChannel?.key)! + "/Q").queryOrderedByKey().queryLimited(toLast:  10).queryEnding(atValue:lastRecentKeyFirebase)
                  query1?.observeSingleEvent(of: .value, with: {(snapshot)   in
                   self.lastRecentKeyFirebase = ""
                       var i = 0
                      let enumerator = snapshot.children
                   var tempLastRecentkey:String?
                      while let rest = enumerator.nextObject() as? DataSnapshot {
                          if rest.key == "z"{
                              self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                          
                          }
                          else{
                                  
                              self.myQuipID = rest.key
                              if let actualkey = self.myQuipID {
                                  
                               if i == 0 {
                                   tempLastRecentkey = actualkey
                               }
                                  
                                  let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                  let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                  
                                  self.myScores[actualkey]=["s":myQuipScore2,
                                                            "r":myReplies2]
                                  
                                  
                               i += 1
                                   if i == 10 {
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
           let channelRef = db?.collection("Channels/\(myChannel?.key ?? "Other")/RecentQuips")
            
           channelRef?.order(by: "t", descending: true).start(afterDocument: self.lastRecentDocumentFirestore!).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                     if let err = err {
                                     print("Error getting documents: \(err)")
                     }
                     else{
                         let length = querySnapshot!.documents.count
                         if length == 0 {
                             return
                         }
                         
                         for i in 0...length-1{
                            
                         
                             
                             let document = querySnapshot!.documents[i]
                           if i == 0{
                                   self.lastRecentDocumentFirestore = document
                                   self.tempMoreRecentQuipsFirestore = true
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
                             let myQuip = Quip(text: aQuipText!, bowl: (self.myChannel?.channelName)!, time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, author: myAuthor!, replies: aReplies!)
                             self.newQuips.append(myQuip)
                             
                         }
                         
                     }
                         self.feedTable.reloadData()
                       if self.tempMoreRecentQuipsFirestore {
                           self.moreRecentQuipsFirestore = true
                       }
                       if self.tempMoreRecentQuipsFirebase {
                           self.moreRecentQuipsFirebase = true
                       }
                     }
                     
                 }
           
       }
    
    
    func setCurrentTime(){
        let timeUpdates = ["d":ServerValue.timestamp(),
                           "s":2] as [String : Any]
        ref!.child("A/" + (myChannel?.key)! + "/Q/z").updateChildValues(timeUpdates)
        
    }
    
    
    
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
                                        
                                        
                                        i += 1
                                                               
                                        if i == 9 {
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
             let channelRef = db?.collection("Channels/\(myChannel?.key ?? "Other")/HotQuips")
            channelRef?.order(by: "t", descending: false).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                  if let err = err {
                                  print("Error getting documents: \(err)")
                  }
                  else{
                      let length = querySnapshot!.documents.count
                      if length == 0 {
                        self.createHotQuipsDoc(aHotIDs: aHotIDs, aHotQuips: self.hotQuips)
                        
                      }
                      else if self.compareHotQuips(doc: querySnapshot!.documents[0], aHotIDs: aHotIDs)==false{
                        self.updateHotQuipsDoc(doc: querySnapshot!.documents[0],aHotQuips: self.hotQuips)
                        self.lastHotDocumentFirestore = querySnapshot!.documents[0]
        
                      }else{
                        self.populateHotQuipsArr(data: querySnapshot!.documents[0].data(), aHotQuips: self.hotQuips)
                        self.lastHotDocumentFirestore = querySnapshot!.documents[0]
                        }
                   
                    
                   
                      
                  }
                  
              }
        
        
    }
    func populateHotQuipsArr(data:[String:Any], aHotQuips:[Quip]){
        for aQuip in aHotQuips{
            let quipData = data[aQuip.quipID!] as! [String:Any]
            aQuip.user = quipData["a"] as? String
            aQuip.channel = quipData["c"] as? String
            aQuip.channelKey = quipData["k"] as? String
            aQuip.quipText = quipData["t"] as? String
            aQuip.timePosted = quipData["d"] as? Timestamp
            
        }
       
        self.feedTable.reloadData()
        if tempMoreHotQuipsFirebase {
            moreHotQuipsFirebase = true
        }
        
    }
    func populateHotQuipsArr2(data:[String:Any], aHotQuips:[Quip]){
          for aQuip in aHotQuips{
              let quipData = data[aQuip.quipID!] as! [String:Any]
              aQuip.user = quipData["a"] as? String
              aQuip.channel = quipData["c"] as? String
              aQuip.channelKey = quipData["k"] as? String
              aQuip.quipText = quipData["t"] as? String
              aQuip.timePosted = quipData["d"] as? Timestamp
              
          }
        self.hotQuips = self.hotQuips + aHotQuips
        
          self.feedTable.reloadData()
          if tempMoreHotQuipsFirebase {
              moreHotQuipsFirebase = true
          }
          
      }
    func updateHotQuipsDoc(doc:DocumentSnapshot, aHotQuips:[Quip]){
       
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
                    self.populateHotQuipsArr(data: self.myNewHotQuipData, aHotQuips:aHotQuips )
                }
               }
               
            }
        
    }
    func updateHotQuipsDoc2(doc:DocumentSnapshot, aHotQuips:[Quip]){
       
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
                    self.populateHotQuipsArr2(data: self.myNewHotQuipData, aHotQuips:aHotQuips )
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
    
    func createHotQuipsDoc(aHotIDs:[String], aHotQuips:[Quip]){
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
                
                let docRef=self.db?.collection("Channels/\(self.myChannel?.key ?? "Other")/HotQuips").addDocument(data: myData)
                 sleep(1)
               self.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips)
                docRef?.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.lastHotDocumentFirestore = document
                 
                }
            }
           }
           
        }
       
    }
    }
    func createHotQuipsDoc2(aHotIDs:[String], aHotQuips:[Quip]){
        var i:Int = 0
        var myData:[String:Any] = [:]
        for aHotId in aHotIDs{
           self.db?.collection("Quips").document(aHotId).getDocument { (document, error) in
               if let document = document, document.exists {
                let data = document.data(with: ServerTimestampBehavior.estimate)
                myData[aHotId] = data
                i += 1
               }
            if i == aHotIDs.count{
            myData["t"] = FieldValue.serverTimestamp()
             
           
           
                
                let docRef=self.db?.collection("Channels/\(self.myChannel?.key ?? "Other")/HotQuips").addDocument(data: myData)
                sleep(1)
               self.populateHotQuipsArr2(data: myData, aHotQuips: aHotQuips)
                docRef?.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.lastHotDocumentFirestore = document
                 
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
        let channelRef = db?.collection("Channels/\(myChannel?.key ?? "Other")/HotQuips")
        channelRef?.order(by: "t", descending: false).start(afterDocument: self.lastHotDocumentFirestore!).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                   if let err = err {
                                   print("Error getting documents: \(err)")
                   }
                   else{
                       let length = querySnapshot!.documents.count
                       if length == 0 {
                         self.createHotQuipsDoc2(aHotIDs: aHotIDs, aHotQuips: aHotQuips)
                       }
                       else if self.compareHotQuips(doc: querySnapshot!.documents[0],aHotIDs: aHotIDs)==false{
                         self.updateHotQuipsDoc2(doc: querySnapshot!.documents[0], aHotQuips: aHotQuips)
                        self.lastHotDocumentFirestore = querySnapshot!.documents[0]
                       }else{
                         self.populateHotQuipsArr2(data: querySnapshot!.documents[0].data(), aHotQuips: aHotQuips)
                        self.lastHotDocumentFirestore = querySnapshot!.documents[0]
                         }
                    
                     
                    
                       
                   }
                   
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! QuipCells

        
         switch newHot.selectedSegmentIndex
               {
               case 0:
                    if newQuips.count > 0 {
                        cell.quipText?.text = self.newQuips[indexPath.row].quipText
                        let aQuipScore=self.newQuips[indexPath.row].quipScore!
                        cell.score?.text = String(aQuipScore)
                        let dateVal = (self.newQuips[indexPath.row].timePosted?.seconds)!
                        let milliTimePost = dateVal * 1000
                        cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                              }
                              else{
                                  return cell
                              }
                
               case 1:
                   if hotQuips.count > 0 {
                    cell.quipText?.text = self.hotQuips[indexPath.row].quipText
                    let aQuipScore=self.hotQuips[indexPath.row].quipScore!
                    cell.score?.text = String(aQuipScore)
                    let dateVal = (self.hotQuips[indexPath.row].timePosted?.seconds)!
                    let milliTimePost = dateVal * 1000
                    cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                              }
                              else{
                                  return cell
                              }
                
               default:
                   break
               }
        cell.delegate = self
        return cell
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
            quipVC?.myQuip = self.passedQuip
            quipVC?.ref=self.ref
            quipVC?.uid=self.uid
            quipVC?.db=self.db
            quipVC?.myChannel=self.myChannel
            
        }else{
        writeQuip = segue.destination as? ViewControllerWriteQuip
        
        
        writeQuip?.myChannel = self.myChannel
        writeQuip?.ref=self.ref
        writeQuip?.db=self.db
        writeQuip?.uid=self.uid
        
        newHot.selectedSegmentIndex = 0
        }
    }
    

}
