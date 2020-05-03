//
//  ViewControllerDiscover.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/11/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerDiscover: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
    
    //IBOutlets
    @IBOutlet weak var channelTable: UITableView!
    @IBOutlet weak var upcomingBtn: UIButton!
    @IBOutlet weak var activeBtn: UIButton!
    @IBOutlet weak var pastBtn: UIButton!
    
   
    
    
    
    //Declare Variables
    private var upcomingChannels:[Channel] = []
    private var activeChannels:[Channel] = []
    private var databaseHandleChannelsAdd:DatabaseHandle?
    private var databaseHandleChannelsRemove:DatabaseHandle?
    private var databaseHandleLiveChannelsAdd:DatabaseHandle?
    private var databaseHandleLiveChannelsRemove:DatabaseHandle?
    private var index:Int?
    var uid:String?
    private var seenUpcoming:Bool = false
    private var seenActive:Bool = false
    private var feedVC:ViewControllerFeed?
    private var passedChannel:Channel?
    var ref:DatabaseReference?
    var db:Firestore?
    var myCategory:Category?
    private var opQueue:OperationQueue=OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelTable.delegate=self
        channelTable.dataSource=self
        
        //notification when user presses home button, detachlisteners is called
       // NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.detachlisteners), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        //notification for when user reopens app after being in the background, appWillEnterForeground is called
         NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
       
        
        
        
       
        
       
        
        
        
        // Do any additional setup after loading the view.
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = channelTable.indexPathForSelectedRow {
            channelTable.deselectRow(at: selectedIndexPath, animated: animated)
        }
        onLoad()
    }
   
    
    //deinitializer for notification center
    deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
   
    
    //called on initial load and when this view controller is first one shown when app goes from background to foreground
     func onLoad(){
         
               //if activebtn is the current one selected and have not seen it yet
               if activeBtn.isSelected && !seenActive{
                   updateActiveUpcoming()
                   seenActive=true
                   
               }
             //if upcoming is selected and have not seen it yet
               else if upcomingBtn.isSelected && !seenUpcoming{
                  
                   seenUpcoming=true
                   
               }
     }
    
    // MARK: - NotificationCenter Functions
       
    //called when app goes from background to active
    @objc func appWillEnterForeground() {
       //checks if this view controller is the first one visible
        if self.viewIfLoaded?.window != nil {
            // viewController is visible
            
            onLoad()
        }
    }
    
   
  
    
 
    
     // MARK: - Database Functions
    
    func updateActiveUpcoming(){
        
        self.activeChannels=[]
        self.upcomingChannels=[]
        let docRef = db?.collection("Categories/AllCategories/Channels").document("\(myCategory?.activeUpcomingKey ?? "Other")")

        docRef?.getDocument { (document, error) in
            if let document = document, document.exists {
                document.data()?.forEach({state in
                    let myMap = state.value as! [String:Any]
                    if state.key == "Active"{
                        myMap.forEach({aChannel in
                            let myMap2 = aChannel.value as! [String:Any]
                            let aName = myMap2["name"] as! String
                            let aParent = myMap2["parent"] as? String
                            let aParentKey = myMap2["parentKey"] as? String
                            let aChannel = Channel(name: aName, start: "", akey: aChannel.key, aparent: aParent, aparentkey: aParentKey)
                            self.activeChannels.append(aChannel)
                        })
                        
                       
                    }else{
                        myMap.forEach({aChannel in
                                                   let myMap2 = aChannel.value as! [String:Any]
                                                   let aName = myMap2["name"] as! String
                                                   let aParent = myMap2["parent"] as? String
                                                   let aParentKey = myMap2["parentKey"] as? String
                                                    let aStart = myMap2["start"] as? String
                                                   let aChannel = Channel(name: aName, start: aStart, akey: aChannel.key, aparent: aParent, aparentkey: aParentKey)
                                                   self.upcomingChannels.append(aChannel)
                                               })
                        
                    }
                })
            } else {
                print("Document does not exist")
            }
            self.channelTable.reloadData()
           
        }
        
    }
   
    func updatePast(){
        
    }
  
    
    
 
  
    
     // MARK: - IBAction Functions
    
   
    //event when active button is clicked
    @IBAction func activeClicked(_ sender: UIButton) {
        //change buttons state
        upcomingBtn.isSelected = false
             activeBtn.isSelected = true
             pastBtn.isSelected = false
        self.channelTable.reloadData()
        

        
        
        
        
        
    }
    //event when past is clicked
    @IBAction func pastClicked(_ sender: UIButton) {
        upcomingBtn.isSelected = false
                activeBtn.isSelected = false
                pastBtn.isSelected = true
    }
    
    //event when upcoming is clicked
    @IBAction func upcomingClicked(_ sender: UIButton) {
        //change state of buttons
              upcomingBtn.isSelected = true
                   activeBtn.isSelected = false
                   pastBtn.isSelected = false
        self.channelTable.reloadData()
      
      
        
     

    }
    
 
    
  
    
     // MARK: - TableView Functions
    
    
    //gets number of sections for tableview
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //returns how many cells are in table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if upcomingBtn.isSelected {
             
             return upcomingChannels.count
           
        } else if activeBtn.isSelected {
            
            return activeChannels.count
            
        }
       return 0
        
    }
    
    
    //populate cells in table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
          let cell = channelTable.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! UpcomingChannelCells
    
        if upcomingBtn.isSelected {
            if upcomingChannels.count > 0 {
                cell.channelName?.text = self.upcomingChannels[indexPath.row].channelName
            }
            else{
                return cell
            }
        } else if activeBtn.isSelected {
            if activeChannels.count > 0 {
                cell.channelName?.text = self.activeChannels[indexPath.row].channelName
            }
            else{
                return cell
            }
            
        }
          return cell
    }
  

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let index = channelTable.indexPathForSelectedRow?.row {
            if activeBtn.isSelected{
                passedChannel = activeChannels[index]
            }else if upcomingBtn.isSelected{
                passedChannel = upcomingChannels[index]
            }
            feedVC = segue.destination as? ViewControllerFeed
            feedVC?.myChannel = passedChannel
            feedVC?.ref=self.ref
            feedVC?.uid=self.uid
            feedVC?.db=self.db
            
        }
       
        
        
        
    }
    

}//end of class
