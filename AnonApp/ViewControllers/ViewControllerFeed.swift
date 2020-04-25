//
//  ViewControllerFeed.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/17/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerFeed: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    

    var myChannel:Channel?
    var ref:DatabaseReference?
    private var seenNew:Bool = false
    private var seenHot:Bool = false
    private var databaseHandleNewAdd:DatabaseHandle?
    private var databaseHandleNewRemove:DatabaseHandle?
    private var databaseHandleHotAdd:DatabaseHandle?
    private var databaseHandleHotRemove:DatabaseHandle?
    private var databaseHandleNewValue:DatabaseHandle?
    private var databaseHandleHotValue:DatabaseHandle?
    private var myQuipID:String?
    private var myQuipText:String?
    private var myQuipChannel:String?
    private var myQuipScore:String?
    private var timePosted:String?
    private var newQuips:[Quip] = []
    private var hotQuips:[Quip] = []
    private var currentTime:String?
    private var writeQuip:ViewControllerWriteQuip?
    var uid:String?
    
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
    
    @IBAction func newHotValueChange(_ sender: Any) {
        switch newHot.selectedSegmentIndex
           {
           case 0:
               if seenNew == true {
                              self.feedTable.reloadData()
                }else{
                          attachListenersNew()
                              seenNew = true
                }
            
           case 1:
                if seenHot == true{
                              self.feedTable.reloadData()
                } else{
                             attachListenersHot()
                              seenHot = true
                }
            
           default:
               break
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
            if seenNew == true {
                self.feedTable.reloadData()
            }else{
            attachListenersNew()
                seenNew = true
            }
           case 1:
            if seenHot == true{
                self.feedTable.reloadData()
            } else{
               attachListenersHot()
                seenHot = true
            }
           default:
               break
           }
        
    }
    
    
    func attachListenersNew(){
        self.newQuips = []
        setCurrentTime()
        
        databaseHandleNewValue = ref?.child("A/" + (myChannel?.key)! + "/Q").observe(.value, with: {(snapshot)   in
            
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? DataSnapshot {
                if rest.key == "e" || rest.key == "n"{
                    
                }
                else if rest.key == "t"{
                    self.currentTime = rest.key
                
                }
                else{
                        
                    self.myQuipID = rest.key
                    if let actualkey = self.myQuipID {
                        
                        self.myQuipText = rest.childSnapshot(forPath: "t").value as? String
                        if self.myQuipText == nil{
                            self.myQuipText = ""
                        }
                        self.myQuipChannel = rest.childSnapshot(forPath: "c").value as? String
                        if self.myQuipChannel == nil {
                            self.myQuipChannel = ""
                        }
                        
                        self.myQuipScore = rest.childSnapshot(forPath: "s").value as? String
                        self.timePosted = rest.childSnapshot(forPath: "d").value as? String
                        var myQuipScore2 = Int(self.myQuipScore ?? "0")
                        if myQuipScore2 == nil{
                            myQuipScore2 = 0
                        }
                        if self.timePosted == nil{
                            self.timePosted = "0"
                        }
                        var myQuip:Quip
                        myQuip = Quip(text: self.myQuipText!, bowl: self.myQuipChannel!, time: self.timePosted!, score: myQuipScore2 ?? 0, myQuipID: actualkey)
                        
                        self.newQuips.append(myQuip)
                                               
                        
                        }
                    }
            }
            self.feedTable.reloadData()
        })
        
               
               if let databaseHandle1 = databaseHandleNewValue{
                ref?.child("A/" + (myChannel?.key)! + "/Q").removeObserver(withHandle: databaseHandle1)
                          
                      }
               
        
    
        
        
    }
    
    func setCurrentTime(){
        
        ref!.child("A/" + (myChannel?.key)! + "/Q/t").setValue(ServerValue.timestamp())
        
    }
    
    func updateScores(){
        
       
    }
    
    
    func attachListenersHot(){
        self.hotQuips = []
        setCurrentTime()
        
        databaseHandleHotValue = ref?.child("A/" + (myChannel?.key)! + "/Q").observe(.value, with: {(snapshot)   in
            
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? DataSnapshot {
                if rest.key == "e" || rest.key == "n"{
                    
                }
                else if rest.key == "t"{
                    self.currentTime = rest.key
                
                }
                else{
                        
                    self.myQuipID = rest.key
                    if let actualkey = self.myQuipID {
                        
                        self.myQuipText = rest.childSnapshot(forPath: "t").value as? String
                        if self.myQuipText == nil{
                            self.myQuipText = ""
                        }
                        self.myQuipChannel = rest.childSnapshot(forPath: "c").value as? String
                        if self.myQuipChannel == nil {
                            self.myQuipChannel = ""
                        }
                        
                        self.myQuipScore = rest.childSnapshot(forPath: "s").value as? String
                        self.timePosted = rest.childSnapshot(forPath: "d").value as? String
                        var myQuipScore2 = Int(self.myQuipScore ?? "0")
                        if myQuipScore2 == nil{
                            myQuipScore2 = 0
                        }
                        if self.timePosted == nil{
                            self.timePosted = "0"
                        }
                        var myQuip:Quip
                        myQuip = Quip(text: self.myQuipText!, bowl: self.myQuipChannel!, time: self.timePosted!, score: myQuipScore2 ?? 0, myQuipID: actualkey)
                        
                        self.hotQuips.append(myQuip)
                                               
                        
                        }
                    }
            }
            self.feedTable.reloadData()
        })
        
               
               if let databaseHandle1 = databaseHandleHotValue{
                ref?.child("A/" + (myChannel?.key)! + "/Q").removeObserver(withHandle: databaseHandle1)
                          
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
                              }
                              else{
                                  return cell
                              }
                
               case 1:
                   if hotQuips.count > 0 {
                    cell.quipText?.text = self.hotQuips[indexPath.row].quipText
                              }
                              else{
                                  return cell
                              }
                
               default:
                   break
               }
        return cell
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        writeQuip = segue.destination as? ViewControllerWriteQuip
        seenNew = false
        
        writeQuip?.myChannel = self.myChannel
        writeQuip?.ref=self.ref
        writeQuip?.uid=self.uid
        
        newHot.selectedSegmentIndex = 0
    }
    

}
