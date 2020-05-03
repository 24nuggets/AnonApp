//
//  ViewControllerUser.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerUser: UIViewController, UITableViewDataSource, UITableViewDelegate {
 

    
    
    @IBOutlet weak var userQuipsTable: UITableView!
    @IBOutlet weak var recentTop: UISegmentedControl!
    
    private var ref:DatabaseReference?
    private var db:Firestore?
    private var uid:String?
    private var newUserQuips:[Quip]=[]
    private var topUserQuips:[Quip]=[]
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userQuipsTable.delegate=self
        userQuipsTable.dataSource=self
          
              let tabBar = tabBarController as! BaseTabBarController
              self.uid = tabBar.userID
              self.ref = tabBar.refDatabaseFirebase()
              self.db = tabBar.refDatabaseFirestore()
    }
    
    override func viewWillAppear(_ animated: Bool){
          super.viewWillAppear(animated)
          updateNew()
          
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
                           
                        var aQuipScore:Int?
                        var aReplies:Int?
                        if let myQuipNumbers = self.myScores[aQuipID] as? [String:Int]{
                            aQuipScore = myQuipNumbers["s"]
                            aReplies = myQuipNumbers["r"]
                        } else {
                            aQuipScore = myInfo["s"] as? Int
                           aReplies = myInfo["r"] as? Int
                            
                        }
                          
                        let myQuip = Quip(text: aQuipText!, bowl: myChannel ?? "Other", time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, replies: aReplies!)
                           self.newUserQuips.append(myQuip)
                        
                        j += 1
                           
                       }
                        if i == 1 {
                        self.userQuipsTable.reloadData()
                               if j == 20  {
                                        self.myLastRecentDoc = document
                                        self.moreRecentQuips = true
                                }
                        }
                   }
                       
                   }
                
            }
        
    }
      
      func setCurrentTime(){
          
                let timeUpdates = ["d":ServerValue.timestamp(),
                                   "s": 100000] as [String : Any]
               
          ref!.child("M/\(uid ?? "Other")/q/z").updateChildValues(timeUpdates)
          
      }
      
      
      
      func updateTop(){
          
         
          
      }
    func getTopUserQuipsFirestore(){
        self.moreTopQuipDocs = false
        self.tempMoreTopQuipDocs = false
        numOfHotLoads = 1
        let userTopRef = db?.collection("Quips")
        self.myPreviousTopQuips = []
        userTopRef?.order(by: "s", descending: true).limit(to: 10).whereField("a", isEqualTo: uid!).getDocuments{ (querySnapshot, err) in
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
                    
                    let myQuip = Quip(text: quipText!, bowl: channelName!, time: timePosted!, score: quipScore!, myQuipID: quipID, author: author!, replies: quipReplies!)
                    self.myPreviousTopQuips.insert(myQuip, at: 0)
                    i += 1
                    if i == 10 {
                        self.tempMoreTopQuipDocs = true
                        self.myLastTopQuipDoc = document
                    }
                      }
        }
        
        self.mergePreviousTopAndCurrentTop()
        }
        
    }
    
    func mergePreviousTopAndCurrentTop(){
        var i:Int=0
        var j:Int=0
        if numOfHotLoads != 1 {
            i = lastiVal!
            j = lastjVal!
        }
        var k = (numOfHotLoads! - 1) * 10
        var getNewQuipsInfo = false
        var newQuipsToGet:[Int:Quip] = [:]
        while (i < myPreviousTopQuips.count && j < myTopScores.count && k < 10 * numOfHotLoads!)
           {
            if (myPreviousTopQuips[i].quipScore! < myTopScores[j].quipScore!)
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
            let myQuip = topUserQuips[aNewQuip.key]
            self.db?.collection("Quips").document(myQuip.quipID!).getDocument { (document, error) in
               if let document = document, document.exists {
                let quipData = document.data(with: ServerTimestampBehavior.estimate)
                myQuip.user = quipData!["a"] as? String
                myQuip.channel = quipData!["c"] as? String
                myQuip.quipText = quipData!["t"] as? String
                myQuip.timePosted = quipData!["d"] as? Timestamp
                 i += 1
               }
            if i == newQuips.count{
            
                self.userQuipsTable.reloadData()
                if self.tempMoreTopQuipDocs {
                    self.moreTopQuipDocs = true
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
                                 
                               let myQuip = Quip(text: aQuipText!, bowl: myChannel ?? "Other", time: atimePosted!, score: aQuipScore!, myQuipID: aQuipID, replies: aReplies!)
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
                           
                           let myQuip = Quip(text: quipText!, bowl: channelName!, time: timePosted!, score: quipScore!, myQuipID: quipID, author: author!, replies: quipReplies!)
                           self.myPreviousTopQuips.append(myQuip)
                        
                        i += 1
                        if i == 10 {
                            self.tempMoreTopQuipDocs = true
                            self.myLastTopQuipDoc = document
                            }
                        }
               }
               
               self.mergePreviousTopAndCurrentTop()
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
                              cell.quipText?.text = self.newUserQuips[indexPath.row].quipText
                            let aQuipScore=self.newUserQuips[indexPath.row].quipScore!
                                                     cell.score?.text = String(aQuipScore)
                            let dateVal = (self.newUserQuips[indexPath.row].timePosted?.seconds)!
                            let milliTimePost = dateVal * 1000
                                cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                                    }
                                    else{
                                        return cell
                                    }
                      
                     case 1:
                         if topUserQuips.count > 0 {
                           cell.quipText?.text = self.topUserQuips[indexPath.row].quipText
                            let aQuipScore=self.topUserQuips[indexPath.row].quipScore!
                                                                              cell.score?.text = String(aQuipScore)
                        let dateVal = (self.topUserQuips[indexPath.row].timePosted?.seconds)!
                        let milliTimePost = dateVal * 1000
                        cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                                    }
                                    else{
                                        return cell
                                    }
                      
                     default:
                         break
                     }
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
            quipVC?.myQuip = self.passedQuip
            quipVC?.ref=self.ref
            quipVC?.uid=self.uid
            quipVC?.db=self.db
           
            
        }
    }
    

}
