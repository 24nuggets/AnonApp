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
    private var timesDownloaded:Int=0
    private var newQuips:[Quip?] = []
    private var hotQuips:[Quip?] = []
    private var firestoreQuips:[Quip?] = []
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
    private var moreRecentQuipsFirebase:Bool = false
    private var moreRecentQuipsFirestore:Bool = false
    private var moreHotQuipsFirebase:Bool = false

    private var myVotes:[String:Any] = [:]
     var myLikesDislikesMap:[String:Int] = [:]
     var myNewLikesDislikesMap:[String:Int] = [:]
    var myUserMap:[String:String] = [:]
    private var refreshControl=UIRefreshControl()
    lazy var MenuLauncher:ellipsesMenuFeed = {
           let launcher = ellipsesMenuFeed()
        launcher.feedController = self
            return launcher
       }()
    
    @IBOutlet weak var feedTable: UITableView!
    @IBOutlet weak var newHot: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
      //  self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        
        //gets rid of border between the two navigation bars on top
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        self.title =  myChannel?.channelName
        
        feedTable.delegate=self
        feedTable.dataSource=self
        refreshControl.addTarget(self, action: #selector(ViewControllerFeed.refreshData), for: .valueChanged)
        feedTable.refreshControl=refreshControl
        //notification when app will enter foreground
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
         
       
        resetVars()
        //move user likes so its asynchronous in loading process
        
       
       
    }
    
    override func viewDidAppear(_ animated: Bool){
              super.viewDidAppear(animated)
        
        navigationController?.hidesBarsOnSwipe = true
        
       
        
        
        
        refreshData()
           
              
    }
    
    //updates firestore and firebase with likes when view is dismissed
    override func viewWillDisappear(_ animated: Bool){
           super.viewWillDisappear(animated)

         updateFirestoreLikesDislikes()
        FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
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
    
    func btnEllipsesTapped(cell: QuipCells) {
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
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
        let myDiff2 = Double(diff)
        let myDiff = NSNumber(value: myDiff2)
        if let aChannelKey = myChannel?.key {
            myVotes["A/\(aChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(myDiff)
        }
        if let aParentChannelKey = myChannel?.parentKey {
            myVotes["A/\(aParentChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(myDiff)
        }
        if let aUID = uid {
        myVotes["M/\(aUID)/q/\(quipID)/s"] = ServerValue.increment(myDiff)
            
        }
    }
    
    func updateFirestoreLikesDislikes(){
        if myNewLikesDislikesMap.count>0{
            if let aUID = uid {
                if let aChannelKey = myChannel?.key{
                    FirestoreService.sharedInstance.updateLikesDislikes(myNewLikesDislikesMap: myNewLikesDislikesMap, aChannelOrUserKey: aChannelKey, myMap: myUserMap, aUID: aUID, parentChannelKey: myChannel?.parentKey, parentChannelMap: nil)
                    
                myNewLikesDislikesMap = [:]
                }
            }
        }
    }
    
    // MARK: - GetFirestoreVotes
    
    
   
    
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
    
  
    
    
    // MARK: - LoadNewQuips
    
    func updateNew(){
        self.refreshControl.beginRefreshing()
        self.firestoreQuips = []
        self.myScores = [:]
        self.moreRecentQuipsFirebase = false
        if let myChannelKey = myChannel?.key{
            FirebaseService.sharedInstance.getNewScoresFeed(myChannelKey: myChannelKey) { (myScores, currentTime,  moreRecentQuipsFirebase) in
                self.myScores = myScores
                self.currentTime = currentTime
                self.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                if let myChannelName = self.myChannel?.channelName{
                    FirestoreService.sharedInstance.getNewQuipsFeed(myChannelKey: myChannelKey, myChannelName: myChannelName) { (newQuips, moreRecentQuipsFirestore) in
                        self.firestoreQuips = newQuips
                        self.mergeFirestoreFirebaseNewQuips()
                        self.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                        if let aUid = self.uid {
                            FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: aUid, aKey: myChannelKey) { (myLikesDislikesMap) in
                                self.myLikesDislikesMap = myLikesDislikesMap
                                self.feedTable.reloadData()
                                self.refreshControl.endRefreshing()
                            }
                        }
                    }
                }
                
            }
        
       
       
        }
        
    }
    
   
    
    func loadMoreRecent(){
           moreRecentQuipsFirebase=false
        
        if let myChannelKey = myChannel?.key{
            FirebaseService.sharedInstance.getMoreNewScoresFeed(myChannelKey: myChannelKey) { (myScores, moreRecentQuipsFirebase) in
                self.myScores = self.myScores.merging(myScores, uniquingKeysWith: { (_, new) -> Any in
                    new
                })
                //need to make sure firebase is always ahead of firestore
                if self.moreRecentQuipsFirestore{
                    if let myChannelName = self.myChannel?.channelName{
                        FirestoreService.sharedInstance.loadMoreNewQuipsFeed(myChannelKey: myChannelKey, channelName: myChannelName) { (newQuips, moreRecentQuipsFirestore) in
                            self.firestoreQuips = self.firestoreQuips + newQuips
                            self.mergeFirestoreFirebaseNewQuips()
                            self.feedTable.reloadData()
                             //have to reload table before setting these to true
                            self.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                            self.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                        }
                        
                    }
                }else{
                    self.mergeFirestoreFirebaseNewQuips()
                    self.feedTable.reloadData()
                    self.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                }
                
            }
        }
        
        
          
           
       }
    
    func mergeFirestoreFirebaseNewQuips(){
        newQuips = []
        for aQuip in firestoreQuips{
            guard let myQuipInfo = myScores[aQuip?.quipID ?? ""] as? [String:Int] else {continue}
            aQuip?.setScore(aScore:myQuipInfo["s"] ?? 0)
            aQuip?.quipReplies = myQuipInfo["r"]
            newQuips.append(aQuip)
        }
        
    }
   
    
     // MARK: - LoadHotQuips
    
    func updateHot(){
        
        self.hotQuips = []
        self.myHotIDs = []
        
        moreHotQuipsFirebase = false
        if let myChannelKey = myChannel?.key{
            
            FirebaseService.sharedInstance.getHotFeed(myChannelKey: myChannelKey) { (myHotQuips, myHotQuipIDs, moreHotQuipsFirebase, currentTime)  in
                self.hotQuips = myHotQuips
                self.myHotIDs = myHotQuipIDs
                self.currentTime = currentTime
                FirestoreService.sharedInstance.getHotQuipsFeed(myChannelKey: myChannelKey, aHotIDs: myHotQuipIDs, hotQuips: myHotQuips) { (myData, aHotQuips, more) in
                    self.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                    self.moreHotQuipsFirebase = moreHotQuipsFirebase
                    self.refreshControl.endRefreshing()
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
                     
                 }
                 }
                 
             }
             if more{
                 self.hotQuips = self.hotQuips + aHotQuips
             }
             self.feedTable.reloadData()
             
             
         }
    
    
   
    
   
    
   
    func loadMoreHotQuips(){
        moreHotQuipsFirebase = false
        if let myChannelKey = myChannel?.key{
            FirebaseService.sharedInstance.loadMoreHotFeed(myChannelKey: myChannelKey) { (aHotQuips, aHotIDs, moreHotQuipsFirebase) in
                FirestoreService.sharedInstance.loadMoreHotFeed(myChannelKey: myChannelKey, aHotIDs: aHotIDs, hotQuips: aHotQuips) { (myData, aHotQuips, more) in
                    self.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                    self.moreHotQuipsFirebase = moreHotQuipsFirebase
                    self.refreshControl.endRefreshing()
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
 
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       
        if let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? QuipCells {
         switch newHot.selectedSegmentIndex
               {
               case 0:
                    if newQuips.count > 0 {
                        
                            if let myQuip = self.newQuips[indexPath.row]{
                                cell.aQuip = myQuip
                                    if let myImageRef = myQuip.imageRef  {
                                        cell.addImageViewToTableCell()
                                        cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.feedTable)
                                                                       }
                                                                                                                                                          
                                    else if let myGifID = myQuip.gifID  {
                                        cell.addGifViewToTableCell()
                                        cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.feedTable)
                                                                            
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
                    if let myQuip = self.hotQuips[indexPath.row]{
                        cell.aQuip=myQuip
                    if let myImageRef = myQuip.imageRef {
                        
                            cell.addImageViewToTableCell()
                            cell.myImageView.getImage(myQuipImageRef: myImageRef, feedTable: self.feedTable)
                        
                                                     
                    }
                                                                                        
                    else if let gifID = myQuip.gifID {
                                                  
                            cell.addGifViewToTableCell()
                            cell.myGifView.getImageFromGiphy(gifID: gifID, feedTable:self.feedTable)
                                                                                            
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
                                  loadMoreRecent()
                               }
                               
                              case 1:
                                   if moreHotQuipsFirebase {
                                    loadMoreHotQuips()
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
            
            quipVC?.uid=self.uid
            
            quipVC?.myChannel=self.myChannel
            
            quipVC?.currentTime = self.currentTime
            quipVC?.parentViewFeed = self
            quipVC?.passedQuipCell = myCell
           feedTable.deselectRow(at: feedTable.indexPathForSelectedRow!, animated: false)
            
        }else{
            if let writeQuip = segue.destination as? ViewControllerWriteQuip{
        
        
        writeQuip.myChannel = self.myChannel
        
        writeQuip.uid=self.uid
        
        newHot.selectedSegmentIndex = 0
            }
            
            
        }
    }
    
   

}


