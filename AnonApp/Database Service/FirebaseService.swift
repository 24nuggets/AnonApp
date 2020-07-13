//
//  FirebaseService.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/29/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class FirebaseService: NSObject {
    
    let ref = Database.database().reference(fromURL: "https://quippet-2213.firebaseio.com/")
    
    static let sharedInstance = FirebaseService()
    
    private var lastRecentKeyFeed:String?
    private var lastHotKeyFeed:String?
    private var lastHotScoreFeed:Int?
    private var lastRecentKeyUser:String?
    private var lastTopKeyUser:String?
    private var lastTopScoreUser:Int?
  
    
    func setCurrentTimeForChannel(myChannelKey: String){
          let timeUpdates = ["d":ServerValue.timestamp(),
                                       "s":10000] as [String : Any]
                    ref.child("A/" + myChannelKey + "/Q/z").updateChildValues(timeUpdates)
    }
    
    func setCurrentTimeForUser(uid:String){
        
        let timeUpdates = ["d":ServerValue.timestamp(),
                           "s": 10000] as [String : Any]
                      
                 ref.child("M/\(uid)/q/z").updateChildValues(timeUpdates)
    }
    func setCurrentTimeForReply(quipId:String){
         ref.child("Q/" + quipId + "/R/z/d").setValue(ServerValue.timestamp())
    }
    
    func getNewScoresFeed(myChannelKey:String, completion: @escaping ([String:Any], Double, Bool)->() ){
        setCurrentTimeForChannel(myChannelKey: myChannelKey)
        let query1 = ref.child("A/" + myChannelKey + "/Q").queryOrderedByKey().queryLimited(toLast:  41)
        //query should be limited to double the firestore doc storage plus 1 to account for fetching time, could have extra as well
        query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)  in
                    var i = 0
            let keys = snapshot.children.allObjects as? [DataSnapshot]
                   var tempLastRecentkey:String?
            var myScores:[String:Any] = [:]
            self?.lastRecentKeyFeed = ""
            var moreRecentQuipsFirebase = false
            var currentTime:Double = 1.0
            if let mykeys = keys{
                
                   for key in mykeys {
                        i += 1
                    if key.key == "z"{
                        currentTime = key.childSnapshot(forPath: "d").value as! Double
                       }
                       else{
                        let aQuipID:String? = key.key
                           if let actualkey = aQuipID {
                               if i == 1 {
                                tempLastRecentkey = actualkey
                               }
                               let myQuipScore2 = key.childSnapshot(forPath: "s").value as? Int
                            if myQuipScore2 ?? -5 <= -5{
                                FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                }
                                continue
                            }
                               let myReplies2 =  key.childSnapshot(forPath: "r").value as? Int
                               myScores[actualkey]=["s":myQuipScore2,
                                                         "r":myReplies2]

                             
                              
                               }
                           }
                }
                    if i == 41 {
                        self?.lastRecentKeyFeed = tempLastRecentkey!
                        moreRecentQuipsFirebase = true
                                                     
                    }
                   
                  
                   completion(myScores, currentTime,  moreRecentQuipsFirebase)
                         
                   }
        
            })
        
        
        
        
    }
    
    func getMoreNewScoresFeed(myChannelKey:String, completion: @escaping ([String:Any], Bool)->()){
        //limited to last should be at least the size of a firestore doc + 1 becasue one of the ones retrieved will be the quip we ended at last time
        var myScores:[String:Any] = [:]
        var moreRecentQuipsFirebase:Bool = false
        let query1 = ref.child("A/" + myChannelKey + "/Q").queryOrderedByKey().queryLimited(toLast:  21).queryEnding(atValue:lastRecentKeyFeed)
                         query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                            self?.lastRecentKeyFeed = ""
                              var i = 0
                             let enumerator = snapshot.children
                          var tempLastRecentkey:String?
                             while let rest = enumerator.nextObject() as? DataSnapshot {
                                i += 1
                                 if rest.key == "z"{
                                     
                                 
                                 }
                                 else{
                                         
                                   let aQuipID:String? = rest.key
                                     if let actualkey = aQuipID {
                                         
                                      if i == 1 {
                                          tempLastRecentkey = actualkey
                                      }
                                         
                                         let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                        if myQuipScore2 ?? -5 <= -5{
                                            FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                                
                                            }
                                            continue
                                        }
                                         let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                         
                                            myScores[actualkey]=["s":myQuipScore2,
                                                                   "r":myReplies2]
                                         
                                         
                                     
                                         
                                         }
                                     }
                            }
                                if i == 20 {
                                    self?.lastRecentKeyFeed = tempLastRecentkey!
                                    moreRecentQuipsFirebase = true
                                                                                        
                                }
                                
                             
                            
                            completion(myScores, moreRecentQuipsFirebase)
                             
                            
            
                                   
                             })
        
    }
    
    func getHotFeed(myChannelKey:String, completion: @escaping ([Quip],[String], Bool, Double)->()){
        setCurrentTimeForChannel(myChannelKey:  myChannelKey)
        var hotQuips:[Quip] = []
        var myHotIDs:[String] = []
        var moreHotQuipsFirebase:Bool = false
        var currentTime:Double = 0
        let query1 = ref.child("A/" + myChannelKey + "/Q").queryOrdered(byChild: "s").queryLimited(toLast: 21)
              
               query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                   
                   let enumerator = snapshot.children
                   var i = 0
                  
                   while let rest = enumerator.nextObject() as? DataSnapshot {
                        i += 1
                      if rest.key == "z"{
                           currentTime = rest.childSnapshot(forPath: "d").value as! Double
                       
                       }
                       else{
                               
                       var aQuipID:String?
                       aQuipID = rest.key
                       
                            if  let actualkey = aQuipID{
                                                 
                                              
                                                 
                                    let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                if myQuipScore2 ?? -5 <= -5{
                                    FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                        
                                    }
                                    continue
                                }
                                    let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                                
                                    let myQuip = Quip(score: myQuipScore2!, replies: myReplies2 ?? 0, myQuipID: actualkey)
                                    if i == 1 {
                                        self?.lastHotKeyFeed = actualkey
                                        self?.lastHotScoreFeed = myQuipScore2
                                    }
                                                                        
                                                 hotQuips.insert(myQuip, at: 0)
                                               myHotIDs.append(actualkey)
                                               
                                        
                                              
                                                                      
                                               
                                              }
                      
                                                      
                               
                               }
                }
                    if i == 21 {
                        moreHotQuipsFirebase = true
                    }
                           
                   completion(hotQuips, myHotIDs, moreHotQuipsFirebase, currentTime)
                
                
                   
                   
               })
    }
    
    func loadMoreHotFeed(myChannelKey:String,  completion: @escaping ([Quip],[String], Bool)->()){
        var moreHotQuipsFirebase = false
        let query1 = ref.child("A/" + myChannelKey + "/Q").queryOrdered(byChild: "s").queryLimited(toLast: 21).queryEnding(atValue: self.lastHotScoreFeed, childKey: self.lastHotKeyFeed)
                     
                      query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                       let count = snapshot.childrenCount
                          let enumerator = snapshot.children
                       var i = 0
                       var tempLastHotKeyFirebase:String?
                       var tempHotScore:Int?
                       var aHotQuips:[Quip] = []
                       var aHotIDs:[String] = []
                       
                          while let rest = enumerator.nextObject() as? DataSnapshot {
                           i += 1
                           if i == count {
                               continue
                           }
                             if rest.key == "z"{
                                  
                              
                              }
                              else{
                                      
                              var aQuipID:String?
                              aQuipID = rest.key
                                           if  let actualkey = aQuipID{
                                                        
                                                       
                                                        
                                               let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                            if myQuipScore2 ?? -5 <= -5{
                                                FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                                    
                                                }
                                                continue
                                            }
                                               let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                                       
                                               let myQuip = Quip(score: myQuipScore2!, replies: myReplies2 ?? 0, myQuipID: actualkey)
                                                      
                                                                               
                                                        aHotQuips.insert(myQuip, at: 0)
                                                      aHotIDs.append(actualkey)
                                                       if i == 1 {
                                                           tempLastHotKeyFirebase = actualkey
                                                           tempHotScore = myQuipScore2
                                                       }
                                                      
                                                                                   
                                       
                                               }
                               
                                      
                                      }
                           
                        }
                        if i == 21 {
                            self?.lastHotKeyFeed = tempLastHotKeyFirebase
                            self?.lastHotScoreFeed = tempHotScore
                            moreHotQuipsFirebase = true
                        }
                          completion(aHotQuips, aHotIDs, moreHotQuipsFirebase)
                          
                          
                      })
               
    }
    
    func loadMoreHotUser(auid:String,  completion: @escaping ([Quip],[String], Bool)->()){
        var moreHotQuipsFirebase = false
        let query1 = ref.child("M/" + auid + "/q").queryOrdered(byChild: "s").queryLimited(toLast: 11).queryEnding(atValue: self.lastTopScoreUser, childKey: self.lastTopKeyUser)
                     
                      query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                       let count = snapshot.childrenCount
                          let enumerator = snapshot.children
                       var i = 0
                       var tempLastHotKeyFirebase:String?
                       var tempHotScore:Int?
                       var aHotQuips:[Quip] = []
                       var aHotIDs:[String] = []
                       
                          while let rest = enumerator.nextObject() as? DataSnapshot {
                           i += 1
                           if i == count {
                               continue
                           }
                             if rest.key == "z"{
                                  
                              
                              }
                              else{
                                      
                              var aQuipID:String?
                              aQuipID = rest.key
                                           if  let actualkey = aQuipID{
                                                        
                                                       
                                                        
                                               let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                            
                                            if myQuipScore2 ?? -5 <= -5{
                                                FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                                    
                                                }
                                                continue
                                            }
                                               let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                                       
                                               let myQuip = Quip(score: myQuipScore2!, replies: myReplies2 ?? 0, myQuipID: actualkey)
                                                      
                                                                               
                                                        aHotQuips.insert(myQuip, at: 0)
                                                      aHotIDs.append(actualkey)
                                                       if i == 1 {
                                                        self?.lastTopKeyUser = actualkey
                                                        self?.lastTopScoreUser = myQuipScore2
                                                       }
                                                      
                                                                                   
                                       
                                               }
                               
                                      
                                      }
                        }
                            if i == 11 {
                                
                                moreHotQuipsFirebase = true
                                    }
                                  
                          completion(aHotQuips, aHotIDs, moreHotQuipsFirebase)
                          
                          
                      })
               
    }
    
    func updateChildValues(myUpdates:[String:Any]){
        ref.updateChildValues(myUpdates)
    }
    
    func generatePostKey()->String?{
       return ref.child("posts").childByAutoId().key
    }
    
   

    
    func getTopUserQuips(uid:String, completion: @escaping ([Quip], Double, Bool, [String])->()){
        setCurrentTimeForUser(uid:uid)
        var currentTime:Double = 0
        var myTopScores:[Quip] = []
        var myHotIDs:[String]=[]
        var tempLastHotKeyFirebase:String?
        var tempHotScore:Int?
        var moreHotQuipsUserFirebase = false
        let query1 = ref.child("M/\(uid)/q").queryOrdered(byChild: "s").queryLimited(toLast: 11)
        
        query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                    
                     let enumerator = snapshot.children
            var i = 0
            while let rest = enumerator.nextObject() as? DataSnapshot {
                            i+=1
                                 if rest.key == "z"{
                                     currentTime = rest.childSnapshot(forPath: "d").value as! Double
                                 
                                 }
                                 else{
                                         
                                     let actualkey = rest.key
                                     
                                         
                                        
                                         
                                          let myQuipScore2  = rest.childSnapshot(forPath: "s").value as? Int
                                        if myQuipScore2 ?? -5 <= -5{
                                            FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                                
                                            }
                                            continue
                                        }
                                         let myReplies2  =  rest.childSnapshot(forPath: "r").value as? Int
                                       
                                        
                                        
                                        let myQuip = Quip(score: myQuipScore2!, replies: myReplies2 ?? 0, myQuipID: actualkey)
                                        
                                    myHotIDs.append(actualkey)
                                        myTopScores.insert(myQuip, at: 0)
                                         if i == 1 {
                                            self?.lastTopKeyUser = actualkey
                                            self?.lastTopScoreUser = myQuipScore2
                                                                                               }
                                                                                              
                                       
                                         
                                         
                                     }
            }
                if i == 11 {
                        
                        moreHotQuipsUserFirebase = true
                            }
                    
            
                        completion(myTopScores, currentTime, moreHotQuipsUserFirebase, myHotIDs)
            
            })
    }
    
    func getRecentUserQuips(uid:String, completion: @escaping ([String:Any], Double, Bool)->()){
        setCurrentTimeForUser(uid:uid)
        var currentTime:Double = 0
        var myRecentScores:[String:Any] = [:]
        var tempLastRecentKey:String?
        var moreRecentQuipsUserFirebase = false
        let query1 = ref.child("M/\(uid)/q").queryLimited(toLast: 21)
        
        query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                    
                     let enumerator = snapshot.children
            var i = 0
            while let rest = enumerator.nextObject() as? DataSnapshot {
                i+=1
                                 if rest.key == "z"{
                                     currentTime = rest.childSnapshot(forPath: "d").value as! Double
                                 
                                 }
                                 else{
                                         
                                     let actualkey = rest.key
                                     
                                         if i == 1 {
                                            tempLastRecentKey = actualkey
                                         }
                                        
                                         
                                          let myQuipScore2  = rest.childSnapshot(forPath: "s").value as? Int
                                        if myQuipScore2 ?? -5 <= -5{
                                            FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                                
                                            }
                                            continue
                                        }
                                         let myReplies2  =  rest.childSnapshot(forPath: "r").value as? Int
                                       
                                    myRecentScores[actualkey]=["s":myQuipScore2,
                                                         "r":myReplies2]
                                   
                                         
                                         
                                     }
            }
                if i == 21{
                    self?.lastRecentKeyUser=tempLastRecentKey
                    moreRecentQuipsUserFirebase = true
                }
                             
            
                        completion(myRecentScores, currentTime, moreRecentQuipsUserFirebase)
            
            })
    }
    func getMoreNewScoresUser(aUid:String, completion: @escaping ([String:Any], Bool)->()){
           //limited to last should be at least the size of a firestore doc + 1 becasue one of the ones retrieved will be the quip we ended at last time
           var myScores:[String:Any] = [:]
           var moreRecentQuipsFirebase:Bool = false
           let query1 = ref.child("M/" + aUid + "/q").queryOrderedByKey().queryLimited(toLast:  11).queryEnding(atValue:lastRecentKeyUser)
                            query1.observeSingleEvent(of: .value, with: {[weak self](snapshot)   in
                                self?.lastRecentKeyUser = ""
                                 var i = 0
                                let enumerator = snapshot.children
                                let count = snapshot.childrenCount
                             var tempLastRecentkey:String?
                                while let rest = enumerator.nextObject() as? DataSnapshot {
                                   i += 1
                                    
                                    if i == count {
                                        continue
                                    }
                                    if rest.key == "z"{
                                        
                                    
                                    }
                                    else{
                                            
                                      let aQuipID:String? = rest.key
                                        if let actualkey = aQuipID {
                                            
                                         if i == 1 {
                                             tempLastRecentkey = actualkey
                                         }
                                            
                                            let myQuipScore2 = rest.childSnapshot(forPath: "s").value as? Int
                                            if myQuipScore2 ?? -5 <= -5{
                                                FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                                    
                                                }
                                                continue
                                            }
                                            let myReplies2 =  rest.childSnapshot(forPath: "r").value as? Int
                                            
                                               myScores[actualkey]=["s":myQuipScore2,
                                                                      "r":myReplies2]
                                            
                                            
                                        
                                            
                                            }
                                        }
                                }
                        if i == 11 {
                            self?.lastRecentKeyUser = tempLastRecentkey!
                            moreRecentQuipsFirebase = true
                                    }
                                   
                                   
                                
                               
                               completion(myScores, moreRecentQuipsFirebase)
                                
                               
               
                                      
                                })
           
       }
    func getQuipScore(aQuip:Quip, completion: @escaping (Quip)->()){
        let aQuipUser = aQuip.user!
        let aQuipID = aQuip.quipID!
        let path = "M/\(aQuipUser)/q/\(aQuipID)"
        ref.child(path).observeSingleEvent(of: .value) {(snapshot) in
        
            if let score = snapshot.childSnapshot(forPath: "s").value as? Int{
            
            aQuip.setScore(aScore: score)
           
            completion(aQuip)
            }
        }
        
    }
    
    func getReplyScores(quipId:String, completion: @escaping (Double,[String:Int])->()){
        setCurrentTimeForReply(quipId: quipId)
        var currentTime:Double = 0
        var replyScores:[String:Int] = [:]
        ref.child("Q/" + quipId + "/R").observeSingleEvent(of: .value, with: {(snapshot)   in
                      
                      let enumerator = snapshot.children
                      while let rest = enumerator.nextObject() as? DataSnapshot {
                          if rest.key == "z"{
                              currentTime = rest.childSnapshot(forPath: "d").value as! Double
                          
                          }
                          else{
                                  
                              let actualkey = rest.key
                              
                                  
                                  
                                  let myReplyScore = rest.childSnapshot(forPath: "s").value as? Int
                            if myReplyScore ?? -5 <= -5{
                                FirestoreService.sharedInstance.deleteQuip(quipID: actualkey) {
                                    
                                }
                                continue
                            }
                                  
                                  replyScores[actualkey]=myReplyScore
                                                         
                                  
                                  
                              }
                      }
            completion(currentTime, replyScores)
                  
                   
                      
                  })
    }
    
    func deleteQuip(quipID:String, eventID: String, author:String, parentEventID:String?, completion: @escaping ()->()){
        
        ref.child("A/\(eventID)/Q/\(quipID)").removeValue()
        ref.child("M/\(author)/q/\(quipID)").removeValue()
        if let aparentID = parentEventID{
           ref.child("A/\(aparentID)/Q/\(quipID)").removeValue()
        }
        ref.child("Q/\(quipID)/R").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if snapshot.childrenCount < 2{
                    self.ref.child("Q/\(quipID)").removeValue()
                }
            }
            completion()
        }
    }
    
    func deleteReply(parentQuipID:String, author:String, replyID:String, completion: @escaping ()->()){
        ref.child("M/\(author)/q/\(replyID)").removeValue()
        
        ref.child("Q/\(parentQuipID)/R/\(replyID)").removeValue { (error, databaseRef) in
            
        }
        FirestoreService.sharedInstance.getQuip(quipID: parentQuipID) { (quip) in
            var updates:[String:Any] = [:]
            
                if let eventId = quip.channelKey{
                  //  self.ref.child("A/\(eventId)/Q/\(parentQuipID)").updateChildValues(updates)
                    updates["A/\(eventId)/Q/\(parentQuipID)/r"] = ServerValue.increment(-1)
                }
                if let parentEventId = quip.parentKey{
                   // self.ref.child("A/\(parentEventId)/Q/\(parentQuipID)").updateChildValues(updates)
                    updates["A/\(parentEventId)/Q/\(parentQuipID)/r"] = ServerValue.increment(-1)
                }
                if let quipAuthor = quip.user{
                   // self.ref.child("M/\(quipAuthor)/q/\(parentQuipID)").updateChildValues(updates)
                    updates["M/\(quipAuthor)/q/\(parentQuipID)/r"] = ServerValue.increment(-1)
                }
            
                self.ref.updateChildValues(updates)
            
            completion()
            
        }
    }
}
