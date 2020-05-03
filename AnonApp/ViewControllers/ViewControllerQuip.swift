//
//  ViewControllerQuip.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerQuip: UIViewController, UITableViewDataSource, UITableViewDelegate {

    
    var myQuip:Quip?
    var myChannel:Channel?
    var ref:DatabaseReference?
    var db:Firestore?
    var uid:String?
    private var currentTime:Double?
    private var replyScores:[String:Int] = [:]
    private var myReplyID:String?
    private var myReplyText:String?
    private var myReplyScore:String?
    private var timePosted:String?
    private var myReplies:[Reply] = []
    
    private var writeReply:ViewControllerWriteReply?

    @IBOutlet weak var replyTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        replyTable.delegate=self
        replyTable.dataSource=self
        
        
    }
    override func viewWillAppear(_ animated: Bool){
      super.viewWillAppear(animated)
       updateReplies()
      
    }
    
    func updateReplies(){
        self.replyScores = [:]
           setCurrentTime()
           
        ref?.child("Q/" + (myQuip?.quipID)! + "/R").observeSingleEvent(of: .value, with: {(snapshot)   in
               
               let enumerator = snapshot.children
               while let rest = enumerator.nextObject() as? DataSnapshot {
                   if rest.key == "z"{
                       self.currentTime = rest.childSnapshot(forPath: "d").value as? Double
                   
                   }
                   else{
                           
                       self.myReplyID = rest.key
                       if let actualkey = self.myReplyID {
                           
                           
                           let myReplyScore = rest.childSnapshot(forPath: "s").value as? String
                           
                          let  myReplyScore2 = Int(myReplyScore ?? "0")
                          
                    
                           
                           self.replyScores[actualkey]=myReplyScore2
                                                  
                           
                           }
                       }
               }
            self.getFirestoreReplies()
            
               
           })
           
                  
           
       
           
           
       }
    func getFirestoreReplies(){
        self.myReplies = []
        let repliesRef = db?.collection("/Quips/\(myQuip?.quipID ?? "Other")/Replies")
        
        repliesRef?.getDocuments() {(querySnapshot, err) in
        if let err = err {
                print("Error getting documents: \(err)")
        }
        else{
                      
                           
        let document = querySnapshot!.documents[0]
                           
        guard document.data(with: ServerTimestampBehavior.estimate)["replies"] != nil else {return}
        let myReplies = document.data(with: ServerTimestampBehavior.estimate)["replies"] as! [String:Any]
            let sortedKeys = Array(myReplies.keys).sorted(by: >)
            for aKey in sortedKeys{
                let myInfo = myReplies[aKey] as! [String:Any]
                           let aReplyID = aKey
                           let atimePosted = myInfo["d"] as? Timestamp
                           let aReplyText = myInfo["t"] as? String
                           let myAuthor = myInfo["a"] as? String
                          
                if self.replyScores[aKey] == nil{
                    continue
                } else {
                        let aReplyScore = self.replyScores[aKey]
                          
                        let myReply = Reply(aScore: aReplyScore ?? 0, aKey: aReplyID, atimePosted: atimePosted!, aText: aReplyText!, aAuthor: myAuthor!)
                        self.myReplies.append(myReply)
                }
            }
                       
        }
            self.replyTable.reloadData()
        
    }
        
        
        
        
    }
       
       func setCurrentTime(){
           
        ref!.child("Q/" + (myQuip?.quipID)! + "/R/z/d").setValue(ServerValue.timestamp())
           
       }
       
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myReplies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = replyTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! QuipCells
               
              if myReplies.count > 0 {
                        cell.quipText?.text = self.myReplies[indexPath.row].replyText
                         let aReplyScore=self.myReplies[indexPath.row].replyScore!
                            cell.score?.text = String(aReplyScore)
                        let dateVal = (self.myReplies[indexPath.row].timePosted?.seconds)!
                        let milliTimePost = dateVal * 1000
                        cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                }
            else{
                    return cell
                }
        return cell
    }
    
    

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        writeReply = segue.destination as? ViewControllerWriteReply
        writeReply?.myQuip = self.myQuip
        writeReply?.ref=self.ref
        writeReply?.uid=self.uid
        writeReply?.db = self.db
        writeReply?.myChannel=self.myChannel
               
              
    }
    

}
