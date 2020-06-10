//
//  FirestoreService.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/29/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class FirestoreService: NSObject {

    
    let db = Firestore.firestore()
    
    static let sharedInstance = FirestoreService()
    
    private var lastRecentDocFeed:DocumentSnapshot?
    private var lastHotDocumentFeed:DocumentSnapshot?
    private var lastHotDocUser:DocumentSnapshot?
    private var myLastRecentDocUser:DocumentSnapshot?
    private var hotQuipAdds:[String] = []
    private var myNewHotQuipData:[String:Any] = [:]
    
    
    func getNewQuipsFeed(myChannelKey:String, myChannelName:String, completion: @escaping ([Quip], Bool)->() ){
        let channelRef = db.collection("Channels/\(myChannelKey)/RecentQuips")
               var moreRecentQuipsFirestore = false
        
        var newQuips:[Quip] = []
               //gets 2 most recent documents that have quips
               channelRef.order(by: "t", descending: true).limit(to: 2).getDocuments(){ (querySnapshot, err) in
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
                            self.lastRecentDocFeed = document
                               moreRecentQuipsFirestore = true
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
                           
                           
                          
                           
                        let aQuipScore = 0
                        let aReplies = 0
                          let myImageRef = myInfo["i"] as? String
                           
                           
                           let myGifRef = myInfo["g"] as? String
                           let myQuip = Quip(text: aQuipText!, bowl: myChannelName, time: atimePosted!, score: aQuipScore, myQuipID: aQuipID, author: myAuthor!, replies: aReplies, myImageRef: myImageRef, myGifID: myGifRef)
                         
                            newQuips.append(myQuip)
                         
                           
                       }
                       
                   }
                      
                       
                   }
                completion(newQuips, moreRecentQuipsFirestore)
                   
               }
    }
    
    
    func getUserLikesDislikesForChannelOrUser(aUid:String, aKey:String, completion: @escaping ([String:Int])->()){
        var myLikesDislikesMap:[String:Int] = [:]
        let docRef = db.collection("/Users/\(aUid)/LikesDislikes").document(aKey)
                         
                     
                         docRef.getDocument{ (document, error) in
                             if let document = document, document.exists {
                               if let myMap = document.data() as? [String:Int]{
                                   myLikesDislikesMap=myMap
                               }
                               
                             
                              
                             }
                           completion(myLikesDislikesMap)
                         }
       
    }
    
    func loadMoreNewQuipsFeed(myChannelKey:String,  channelName:String, completion: @escaping ([Quip], Bool)->()){
        var moreRecentQuipsFirestore:Bool = false
        var newQuips:[Quip] = []
        let channelRef = db.collection("Channels/\(myChannelKey)/RecentQuips")
        if let myLastDoc = lastRecentDocFeed{
            channelRef.order(by: "t", descending: true).start(afterDocument: myLastDoc).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                            if let err = err {
                                            print("Error getting documents: \(err)")
                            }
                            else{
                                let length = querySnapshot!.documents.count
                                if length == 0 {
                                    return
                                }
                                
                               
                                   
                                
                                    
                                    let document = querySnapshot!.documents[0]
                                 
                                          self.lastRecentDocFeed = document
                                          moreRecentQuipsFirestore = true
                                  
                                    
                                    guard document.data(with: ServerTimestampBehavior.estimate)["quips"] != nil else {return}
                                    let myQuips = document.data(with: ServerTimestampBehavior.estimate)["quips"] as! [String:Any]
                                let sortedKeys = Array(myQuips.keys).sorted(by: >)
                                for aQuip in sortedKeys{
                                    let myInfo = myQuips[aQuip] as! [String:Any]
                                    let aQuipID = aQuip
                                    let atimePosted = myInfo["d"] as? Timestamp
                                    let aQuipText = myInfo["t"] as? String
                                    let myAuthor = myInfo["a"] as? String
                                   
                                   
                                    let aQuipScore = 0
                                    let aReplies = 0
                                    let myImageRef = myInfo["i"] as? String
                                   let myGifRef = myInfo["g"] as? String
                                   let myQuip = Quip(text: aQuipText!, bowl: channelName, time: atimePosted!, score: aQuipScore, myQuipID: aQuipID, author: myAuthor!, replies: aReplies, myImageRef: myImageRef, myGifID: myGifRef)
                                    newQuips.append(myQuip)
                                    
                                }
                                
                            
                                
                              
                             
                            }
                           completion(newQuips, moreRecentQuipsFirestore)
                        }
        }
    
    }
    
    func getHotQuipsFeed(myChannelKey:String, aHotIDs:[String], hotQuips:[Quip], completion: @escaping ([String:Any],[Quip], Bool)->()){
        var mydata:[String:Any] = [:]
        let channelRef = db.collection("Channels/\(myChannelKey)/HotQuips")
            channelRef.order(by: "t", descending: false).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                  if let err = err {
                                  print("Error getting documents: \(err)")
                  }
                  else{
                    if let querySnapshot = querySnapshot{
                      let length = querySnapshot.documents.count
                       
                     if length == 0 {
                                                  
                        self.createHotQuipsDoc(aHotIDs: aHotIDs, aHotQuips: hotQuips, more: false, aChannelKey: myChannelKey) { (myData, aHotQuips, more) in
                            completion(myData, aHotQuips, more)
                        }
                                                   
                     }else{
                        mydata = querySnapshot.documents[0].data(with: .estimate) as [String:Any]
                        if self.compareHotQuips(myData: mydata, aHotIDs: aHotIDs)==false{
                            self.lastHotDocumentFeed = querySnapshot.documents[0]
                            self.updateHotQuipsDoc(doc: querySnapshot.documents[0], aHotQuips: hotQuips, more: false) { (myData, aHotQuips, more) in
                                completion(myData, aHotQuips, more)
                            }
                                
                                       
                        }else{
                            
                            self.lastHotDocumentFeed = querySnapshot.documents[0]
                            completion(mydata, hotQuips, false)
                                    
                                        
                        }
                    }
                    
                   
                    }
                    
                     
                  }
                
                 
              }
    }
    
    func loadMoreHotFeed(myChannelKey:String, aHotIDs:[String], hotQuips:[Quip], completion: @escaping ([String:Any],[Quip], Bool)->()){
        var mydata:[String:Any] = [:]
        let channelRef = db.collection("Channels/\(myChannelKey)/HotQuips")
        if let lastdoc = lastHotDocumentFeed{
               channelRef.order(by: "t", descending: false).start(afterDocument: lastdoc).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                          if let err = err {
                                          print("Error getting documents: \(err)")
                          }
                          else{
                              if let querySnapshot = querySnapshot{
                                let length = querySnapshot.documents.count
                                mydata = querySnapshot.documents[0].data(with: .estimate) as [String:Any]
                                if length == 0 {
                                                                        
                                    self.createHotQuipsDoc(aHotIDs: aHotIDs, aHotQuips: hotQuips, more: true, aChannelKey: myChannelKey) { (myData, aHotQuips, more) in
                                            completion(myData, aHotQuips, more)
                                        }
                                                                                
                                    }
                                else if self.compareHotQuips(myData: mydata, aHotIDs: aHotIDs)==false{
                                    self.lastHotDocumentFeed = querySnapshot.documents[0]
                                    self.updateHotQuipsDoc(doc: querySnapshot.documents[0], aHotQuips: hotQuips, more: true) { (myData, aHotQuips, more) in
                                            completion(myData, aHotQuips, more)
                                    }
                                                         
                                                                
                                }else{
                                                    
                                    self.lastHotDocumentFeed = querySnapshot.documents[0]
                                        completion(mydata, hotQuips, true)
                                                             
                                                                 
                                }
                                                
                            }
                           
                            
                           
                              
                          }
                          
                      }
        }
    }
    
    func getHotQuipsUser(myUid:String, aHotIDs:[String], hotQuips:[Quip], completion: @escaping ([String:Any],[Quip], Bool)->()){
           var mydata:[String:Any] = [:]
           let channelRef = db.collection("Users/\(myUid)/HotQuips")
               channelRef.order(by: "t", descending: false).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                     if let err = err {
                                     print("Error getting documents: \(err)")
                     }
                     else{
                       if let querySnapshot = querySnapshot{
                         let length = querySnapshot.documents.count
                          
                        if length == 0 {
                                                     
                           self.createHotQuipsDocUser(aHotIDs: aHotIDs, aHotQuips: hotQuips, more: false, aUid: myUid) { (myData, aHotQuips, more) in
                               completion(myData, aHotQuips, more)
                           }
                                                      
                        }else{
                           mydata = querySnapshot.documents[0].data(with: .estimate) as [String:Any]
                           if self.compareHotQuips(myData: mydata, aHotIDs: aHotIDs)==false{
                               self.lastHotDocUser = querySnapshot.documents[0]
                               self.updateHotQuipsDoc(doc: querySnapshot.documents[0], aHotQuips: hotQuips, more: false) { (myData, aHotQuips, more) in
                                   completion(myData, aHotQuips, more)
                               }
                                   
                                          
                           }else{
                               
                               self.lastHotDocUser = querySnapshot.documents[0]
                               completion(mydata, hotQuips, false)
                                       
                                           
                           }
                       }
                       
                      
                       }
                       
                        
                     }
                   
                    
                 }
       }
    
    func compareHotQuips(myData:[String:Any], aHotIDs:[String])->Bool{
        hotQuipAdds = []
        
        myNewHotQuipData = [:]
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
   
     
      func updateHotQuipsDoc(doc:DocumentSnapshot, aHotQuips:[Quip], more:Bool, completion: @escaping ([String:Any],[Quip], Bool)->()){
         
          var i:Int = 0
          
          for aHotId in self.hotQuipAdds{
                 self.db.collection("Quips").document(aHotId).getDocument { (document, error) in
                     if let document = document, document.exists {
                      let data = document.data(with: ServerTimestampBehavior.estimate)
                      self.myNewHotQuipData[aHotId] = data
                       i += 1
                     }
                  if i == self.hotQuipAdds.count{
                  
                      
                      doc.reference.updateData(self.myNewHotQuipData)
                    completion(self.myNewHotQuipData, aHotQuips, more)
                  }
                 }
                 
              }
          
      }
    
     
      
    func createHotQuipsDoc(aHotIDs:[String], aHotQuips:[Quip], more:Bool, aChannelKey:String, completion: @escaping ([String:Any],[Quip], Bool)->()){
          var i:Int = 0
          var myData:[String:Any] = [:]
          for aHotId in aHotIDs{
             self.db.collection("Quips").document(aHotId).getDocument { (document, error) in
                 if let document = document, document.exists {
                  let data = document.data(with: ServerTimestampBehavior.estimate)
                  myData[aHotId] = data
                  i += 1
                 }
              if i == aHotIDs.count{
              myData["t"] = FieldValue.serverTimestamp()
                  
            let docRef=self.db.collection("Channels/\(aChannelKey)/HotQuips").addDocument(data: myData)
                //   sleep(1)
                 
                  docRef.getDocument { (document, error) in
                  if let document = document, document.exists {
                      self.lastHotDocumentFeed = document
                   
                      }
                      }
               completion(myData, aHotQuips, more)
             }
             
          }
         
      }
      }
    func createHotQuipsDocUser(aHotIDs:[String], aHotQuips:[Quip], more:Bool, aUid:String, completion: @escaping ([String:Any],[Quip], Bool)->()){
             var i:Int = 0
             var myData:[String:Any] = [:]
             for aHotId in aHotIDs{
                self.db.collection("Quips").document(aHotId).getDocument { (document, error) in
                    if let document = document, document.exists {
                     let data = document.data(with: ServerTimestampBehavior.estimate)
                     myData[aHotId] = data
                     i += 1
                    }
                 if i == aHotIDs.count{
                 myData["t"] = FieldValue.serverTimestamp()
                     
               let docRef=self.db.collection("Users/\(aUid)/HotQuips").addDocument(data: myData)
                   //   sleep(1)
                    
                     docRef.getDocument { (document, error) in
                     if let document = document, document.exists {
                         self.lastHotDocUser = document
                      
                         }
                         }
                  completion(myData, aHotQuips, more)
                }
                
             }
            
         }
         }
    func updateLikesDislikes(myNewLikesDislikesMap:[String:Int], aChannelOrUserKey:String, myMap:[String:String], aUID:String, parentChannelKey:String?, parentChannelMap:[String:String]?){
        let batch = self.db.batch()
        
            let docRef = db.collection("/Users/\(aUID)/LikesDislikes").document(aChannelOrUserKey)
            
            batch.setData(myNewLikesDislikesMap, forDocument: docRef,merge: true)
        
        for aKey in myNewLikesDislikesMap.keys{
                           
                           if let myUserOrChannel = myMap[aKey]{
                               let docRefChannel = db.collection("/Users/\(aUID)/LikesDislikes").document(myUserOrChannel)
                            batch.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel, merge: true)
                           }
            if let myParentChannel = parentChannelMap?[aKey]{
                let docRefChannel = db.collection("/Users/\(aUID)/LikesDislikes").document(myParentChannel)
                                           batch.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel, merge: true)
            }
            if let myParentChannel = parentChannelKey {
                let docRefChannel = db.collection("/Users/\(aUID)/LikesDislikes").document(myParentChannel)
                batch.setData([aKey:myNewLikesDislikesMap[aKey]  as Any], forDocument: docRefChannel, merge: true)
            }
        }
            batch.commit()
    }
    
    
    
    func getActive(aGenCat:String, aCatName:String, completion: @escaping ([Channel])->()){
        let docRef = db.collection("Categories/\(aGenCat)/\(aCatName)").document("Active")
        var activeChannels:[Channel] = []
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    
                  if let myChannels = document.data(){
                        for aChannel in myChannels.keys{
                            let key = aChannel
                            if let myInfo = myChannels[aChannel] as? [String:Any]{
                                 let priority = myInfo["priority"] as? Int
                                if let name = myInfo["name"] as? String{
                                let parent = myInfo["parent"] as? String
                                let parentkey = myInfo["parentkey"] as? String
                                    let myChannel = Channel(name: name, start: nil, akey: key, aparent: parent, aparentkey: parentkey, apriority: priority)
                                activeChannels.append(myChannel)
                                }
                            }
                            
                        }
                    completion(activeChannels)
                       
                    }
                           
                            
                        
                        
                        
                } else {
                    print("Document does not exist")
                }
               
               
            }
        }
    
    func getUpcoming(aGenCat:String, aCatName:String, completion: @escaping ([Channel])->()){
        let docRef = db.collection("Categories/\(aGenCat)/\(aCatName)").document("Upcoming")
        var upcomingChannels:[Channel] = []
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                                     
                    if let myChannels = document.data(){
                                         for aChannel in myChannels.keys{
                                             let key = aChannel
                                             if let myInfo = myChannels[aChannel] as? [String:Any]{
                                                  let priority = myInfo["priority"] as? Int
                                                 if let name = myInfo["name"] as? String{
                                                 let parent = myInfo["parent"] as? String
                                                 let parentkey = myInfo["parentkey"] as? String
                                                     let myChannel = Channel(name: name, start: nil, akey: key, aparent: parent, aparentkey: parentkey, apriority: priority)
                                                 upcomingChannels.append(myChannel)
                                                 }
                                             }
                                             
                                         }
                                completion(upcomingChannels)
                                     }
                                            
                                             
                                         
                                         
                                         
                                 } else {
                                     print("Document does not exist")
                                 }
                                
                                
                             }
                         }
    
    func getPast(aGenCat:String, aCatName:String, completion: @escaping ([Channel])->()){
        let docRef = db.collection("Categories/\(aGenCat)/\(aCatName)").document("Past")
        var pastChannels:[Channel] = []
                                    docRef.getDocument { (document, error) in
                                        if let document = document, document.exists {
                                            
                                          if let myChannels = document.data(){
                                                for aChannel in myChannels.keys{
                                                    let key = aChannel
                                                    if let myInfo = myChannels[aChannel] as? [String:Any]{
                                                         let priority = myInfo["priority"] as? Int
                                                        if let name = myInfo["name"] as? String{
                                                        let parent = myInfo["parent"] as? String
                                                        let parentkey = myInfo["parentkey"] as? String
                                                            let myChannel = Channel(name: name, start: nil, akey: key, aparent: parent, aparentkey: parentkey, apriority: priority)
                                                       pastChannels.append(myChannel)
                                                        }
                                                    }
                                                    
                                                }
                                            completion(pastChannels)
                                                
                                            }
                                                   
                                                    
                                                
                                                
                                                
                                        } else {
                                            print("Document does not exist")
                                        }
                                       
                                       
                                    }
                                }
    
    func favoriteCatagory(aUid:String, myCatName:String, bigCategory:String){
        let favdoc = db.collection("/Users/\(aUid)/Favorites").document("Favs")
                   
                      
        let myData = ["n":myCatName,
                      "b":bigCategory]
        favdoc.setData(["favs":FieldValue.arrayUnion([myData])], merge:true)
       
    }
    
    func unfavoriteCatagory(aUid:String, myCatName:String, bigCategory:String){
        let favdoc = db.collection("/Users/\(aUid)/Favorites").document("Favs")
        
         let myData = ["n":myCatName,
                           "b":bigCategory]
        favdoc.setData(["favs":FieldValue.arrayRemove([myData])],merge:true)
    }
    
    func addQuipToRecentChannelTransaction(myChannelKey:String, data:[String:Any], key:String, completion: @escaping ()->()){
        
        let recentQuipsRef = self.db.collection("Channels/\(myChannelKey)/RecentQuips")
                  
        recentQuipsRef.order(by: "t", descending: true).limit(to: 2).getDocuments(){ (querySnapshot, err) in
                       if err != nil {
                           return
                       }
                       
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                        let sfDocument: DocumentSnapshot
                  do {
                       try sfDocument = transaction.getDocument((querySnapshot?.documents[0].reference)!)
                   } catch let fetchError as NSError {
                       errorPointer?.pointee = fetchError
                       return nil
                   }
                            
                        
                               if querySnapshot?.isEmpty ?? true ||
                                   querySnapshot?.documents[1].data()["n"] as! Double >= 20{
                               
                                   self.createNewDocForRecentChannel(data: data, key: key, transaction: transaction, channelKey: myChannelKey)
                           
                                
                                    let mydata2=["n":FieldValue.increment(Int64(1))]
                                    
                                transaction.updateData(mydata2, forDocument: sfDocument.reference)
                                transaction.updateData(["quips.\(key)" : data], forDocument: sfDocument.reference)
                                    
                                    
                               }
                               else{
                                   let mydata2=["n":FieldValue.increment(Int64(1))]
                                  
                                   transaction.updateData(mydata2, forDocument: (querySnapshot?.documents[1].reference)!)
                                   transaction.updateData(["quips.\(key)" : data], forDocument: (querySnapshot?.documents[1].reference)!)
                                   
                           }
                       
                   
            return nil
        }){ (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            
            } else {
               completion()
               
            }
        }
        }
    }
    
    func createNewDocForRecentChannel(data:[String:Any], key:String, transaction:Transaction, channelKey:String){
           
           var mydata2:[String:Any] = [:]
           mydata2 = ["n": 0,
                      "t": FieldValue.serverTimestamp()]
           
           
        let recentQuipRef = self.db.collection("Channels/\(channelKey)/RecentQuips").document()
          
           transaction.setData(mydata2, forDocument: recentQuipRef)
       }
    
    
    func addQuipToRecentUserQuips(auid:String, data:[String:Any], key:String){
        let recentQuipsRef = self.db.collection("Users/\(auid)/RecentQuips")
                    
            recentQuipsRef.order(by: "t", descending: true).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                        if let err = err {
                                   print("Error getting documents: \(err)")
                        }else{
                          
                            if querySnapshot?.isEmpty ?? true ||
                                querySnapshot?.documents[0].data()["n"] as! Double >= 20{
                                self.createNewDocForRecentUser(data: data, key: key, auid: auid)
                        
                            }
                            else{
                                let mydata2=["n":FieldValue.increment(Int64(1))]
                                let batch = self.db.batch()
                                batch.updateData(mydata2, forDocument: (querySnapshot?.documents[0].reference)!)
                                batch.updateData(["quips.\(key)" : data], forDocument: (querySnapshot?.documents[0].reference)!)
                                batch.commit()
                                
                               }
                           
                       }
          
           }
    }
    func createNewDocForRecentUser(data:[String:Any], key:String, auid:String){
              
              var mydata2:[String:Any] = [:]
              mydata2 = ["n": 1,
                         "t": FieldValue.serverTimestamp()]
              let batch = db.batch()
          
              let recentQuipRef = self.db.collection("Users/\(auid)/RecentQuips").document()
              batch.setData(["quips" : [key:data]], forDocument: recentQuipRef, merge: true)
              batch.updateData(mydata2, forDocument: recentQuipRef)
              batch.commit()
           
          }
    
    func addQuipDocToFirestore(data:[String:Any], key:String){
        let batch = db.batch()
        let newQuipRef=db.collection("Quips").document(key)
              
        batch.setData(data, forDocument: newQuipRef)
             
              batch.commit()
    }
    
    func reorderUserFavs(aUid:String, myFavs:[Category]){
        var myNewFavCats:[[String:String]] = []
        let docRef = db.collection("/Users/\(aUid)/Favorites").document("Favs")
        for aCat in myFavs{
            if let myCatName = aCat.categoryName{
                if let myBigCat = aCat.bigCat{
                    myNewFavCats.append(["n":myCatName,
                                         "b":myBigCat])
                }
            }
            
        }
        docRef.setData(["favs":myNewFavCats])
            
               
    }
    
    func getUserFavCategories(aUid:String,  completion: @escaping ([Category])->()){
        
        var myFavCats:[Category] = []
        let docRef = db.collection("/Users/\(aUid)/Favorites").document("Favs")
               
           
               docRef.getDocument{ (document, error) in
                   if let document = document, document.exists {
                    if let myMap = document.data()?["favs"] as? [[String:String]]{
                        
                        for aCat in myMap{
                            if let aCatName = aCat["n"]{
                            let bigCatName = aCat["b"]
                            let myCategory = Category(name: aCatName, aPriority: nil, aBigCat: bigCatName)
                            myFavCats.append(myCategory)
                            }
                        }
                         
                     }
                     
                   
                    
                   } else {
                    myFavCats = []
                   }
                completion(myFavCats)
                 
               }
    }
    
    func getLiveEvents(completion: @escaping ([Channel])->()){
        var aLiveEvents:[Channel] = []
        let docRef = db.collection("Categories").document("Live")

               docRef.getDocument { (document, error) in
                   if let document = document, document.exists {
                       if let myLiveEvents = document.data() {
                       
                       for aEvent in myLiveEvents.keys{
                           let eventID = aEvent
                           if let eventInfo = myLiveEvents[aEvent] as? [String:Any]{
                               if let eventName = eventInfo["name"] as? String{
                                   let priority = eventInfo["priority"] as? Int
                                   let myEvent = Channel(name: eventName, start: nil, akey: eventID, aparent: nil, aparentkey: nil, apriority: priority)
                                   aLiveEvents.append(myEvent)
                               }
                           }
                       }
                        
                        
                           
                       
                       
                       
                       }
                       
                   } else {
                       print("Document does not exist")
                   }
                completion(aLiveEvents)
               }
               
           }
    
           
    func getSports(completion: @escaping ([Category], [Category])->()){
        var allSports:[Category] = []
        var aSports:[Category]=[]
                  let docRef = db.collection("Categories").document("Sports")

                  docRef.getDocument { (document, error) in
                      if let document = document, document.exists {
                       if let mySports = document.data(){
                           for aSport in mySports.keys{
                               let name = aSport
                               if let myInfo = mySports[aSport] as? [String:Any]{
                                    let priority = myInfo["priority"] as? Int
                                   let mySport = Category(name: name, aPriority: priority, aBigCat: "Sports")
                                   allSports.append(mySport)
                                   if priority != 0 {
                                   aSports.append(mySport)
                                   }
                               }
                               
                           }
                            
                       }
                           
                         
                              
                          
                      } else {
                          print("Document does not exist")
                      }
                    completion(aSports,allSports)
                  }
    }
    
      func getEntertainment(completion: @escaping ([Category], [Category])->()){
    let docRef = db.collection("Categories").document("Entertainment")
        var aEntertainments:[Category] = []
        var allEntertainment:[Category] = []
    docRef.getDocument { (document, error) in
    if let document = document, document.exists {
     if let myEntertainments = document.data(){
         for aEntertainment in myEntertainments.keys{
             let name = aEntertainment
             if let myInfo = myEntertainments[aEntertainment] as? [String:Any]{
                  let priority = myInfo["priority"] as? Int
                 let myEntertainment = Category(name: name, aPriority: priority, aBigCat: "Entertainment")
                 allEntertainment.append(myEntertainment)
                 if priority != 0 {
                 aEntertainments.append(myEntertainment)
                 }
             }
             
         }
         
         }
                
            
        } else {
            print("Document does not exist")
        }
        completion(aEntertainments, allEntertainment)
    }
    }
    
    
    func getRecentUserQuipsFirestore(uid:String, myScores:[String:Any], completion: @escaping ([Quip], Bool)->()){
        var newUserQuips:[Quip] = []
        var moreRecentQuips = false
        let userRecentRef = db.collection("Users/\(uid)/RecentQuips")
           
           userRecentRef.order(by: "t", descending: true).limit(to: 2).getDocuments(){ (querySnapshot, err) in
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
                    if let myQuipNumbers = myScores[aQuipID] as? [String:Int]{
                        aQuipScore = myQuipNumbers["s"]
                        aReplies = myQuipNumbers["r"]
                    } else {
                        aQuipScore = myInfo["s"] as? Int
                       aReplies = myInfo["r"] as? Int
                    }
                    
                      let myImageRef = myInfo["i"] as? String
                      let myGifRef = myInfo["g"] as? String
                    let myQuip = Quip(text: aQuipText ?? "", bowl: myChannel ?? "Other", time: atimePosted ?? Timestamp(), score: aQuipScore ?? 0, myQuipID: aQuipID, replies: aReplies ?? 0,myImageRef: myImageRef,myGifID: myGifRef, myChannelKey: myChannelKey,myParentChannelKey: myChannelParentKey, isReply: isReply)
                       newUserQuips.append(myQuip)
                    
                    j += 1
                       
                   }
                    if i == 1 {
                    
                           if j == 20  {
                                    self.myLastRecentDocUser = document
                                    moreRecentQuips = true
                            }
                    }
               }
                completion(newUserQuips,moreRecentQuips)
                
               }
            
        }
    }
    
    func loadMoreRecentUserQuips(uid:String, myScores:[String:Any], completion: @escaping ([Quip], Bool)->()){
        var newUserQuips:[Quip] = []
        var moreRecentQuipsUser = false
        let userRecentRef = db.collection("Users/\(uid)/RecentQuips")
        if let myLastDoc = self.myLastRecentDocUser{
        userRecentRef.order(by: "t", descending: true).start(afterDocument: myLastDoc).limit(to: 1).getDocuments(){ (querySnapshot, err) in
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
                               if let myQuipNumbers = myScores[aQuipID] as? [String:Int]{
                                   aQuipScore = myQuipNumbers["s"]
                                   aReplies = myQuipNumbers["r"]
                               } else {
                                   aQuipScore = 0
                                  aReplies = 0
                                   
                               }
                                 let myImageRef = myInfo["i"] as? String
                                let myGifRef = myInfo["g"] as? String
                                let myChannelKey = myInfo["k"] as? String
                                let myChannelParentKey = myInfo["pk"] as? String
                                let isReply = myInfo["reply"] as? Bool
                               let myQuip = Quip(text: aQuipText!, bowl: myChannel ?? "Other", time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, replies: aReplies!,myImageRef: myImageRef,myGifID: myGifRef, myChannelKey: myChannelKey,myParentChannelKey: myChannelParentKey, isReply: isReply)
                                  newUserQuips.append(myQuip)
                                
                                i += 1
                               
                                    
                                }
                            
                            
                            
                                    if i == 20 {
                                        self.myLastRecentDocUser = document
                                        moreRecentQuipsUser = true
                                    }
                            completion(newUserQuips, moreRecentQuipsUser)
                                  
                              }
                           
            }
                       
        }
    }
    
    func loadMoreHotUser(auid:String, aHotIDs:[String], hotQuips:[Quip], completion: @escaping ([String:Any],[Quip], Bool)->()){
        var mydata:[String:Any] = [:]
        let channelRef = db.collection("Users/\(auid)/HotQuips")
        if let lastdoc = lastHotDocUser{
               channelRef.order(by: "t", descending: false).start(afterDocument: lastdoc).limit(to: 1).getDocuments(){ (querySnapshot, err) in
                          if let err = err {
                                          print("Error getting documents: \(err)")
                          }
                          else{
                              if let querySnapshot = querySnapshot{
                                let length = querySnapshot.documents.count
                                mydata = querySnapshot.documents[0].data(with: .estimate) as [String:Any]
                                if length == 0 {
                                                                        
                                    self.createHotQuipsDocUser(aHotIDs: aHotIDs, aHotQuips: hotQuips, more: true, aUid:auid) { (myData, aHotQuips, more) in
                                            completion(myData, aHotQuips, more)
                                        }
                                                                                
                                    }
                                else if self.compareHotQuips(myData: mydata, aHotIDs: aHotIDs)==false{
                                    self.lastHotDocumentFeed = querySnapshot.documents[0]
                                    self.updateHotQuipsDoc(doc: querySnapshot.documents[0], aHotQuips: hotQuips, more: true) { (myData, aHotQuips, more) in
                                            completion(myData, aHotQuips, more)
                                    }
                                                         
                                                                
                                }else{
                                                    
                                    self.lastHotDocumentFeed = querySnapshot.documents[0]
                                        completion(mydata, hotQuips, true)
                                                             
                                                                 
                                }
                                                
                            }
                           
                            
                           
                              
                          }
                          
                      }
        }
    }
    
    func getReplies(quipID:String, replyScores:[String:Int], completion: @escaping ([Quip])->()){
        var aReplies:[Quip] = []
        let repliesRef = db.collection("/Quips/\(quipID)/Replies")
            
            repliesRef.getDocuments() {(querySnapshot, err) in
            if let err = err {
                    print("Error getting documents: \(err)")
            }
            else{
                          
                if querySnapshot!.documents.count == 0{
                    
                    completion(aReplies)
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
                    if replyScores[aKey] == nil{
                        continue
                    } else {
                        let aReplyScore = replyScores[aKey]
                              
                        let myReply = Quip(aScore: aReplyScore ?? 0, aKey: aReplyID, atimePosted: atimePosted!, aText: aReplyText!, aAuthor: myAuthor!, image:myImageRef, gif:myGifRef, quipParentID: quipID)
                            aReplies.append(myReply)
                    }
                }
                           
            }
                completion(aReplies)
                
            
        }
    }
    
    func saveReply(quipId:String, mydata:[String:Any], key:String, completion: @escaping ()->()){
        let repliesQuipsRef = self.db.collection("/Quips/\(quipId)/Replies").document("RecentReplies")

                    let batch = self.db.batch()
                    batch.setData([key : mydata], forDocument: repliesQuipsRef, merge: true)
                                   batch.commit()
        completion()
                                   
    }
}
