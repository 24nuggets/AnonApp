//
//  ViewControllerDiscover.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/11/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerDiscover: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate3 {
  
    
    //IBOutlets
    @IBOutlet weak var channelTable: UITableView!
    @IBOutlet weak var upcomingBtn: UIButton!
    @IBOutlet weak var activeBtn: UIButton!
    @IBOutlet weak var pastBtn: UIButton!
    @IBOutlet weak var catName: UILabel!
    
   
    @IBOutlet weak var navBar: UINavigationItem!
    
    
    //Declare Variables
    private var upcomingChannels:[Channel] = []
    private var activeChannels:[Channel] = []
    private var pastChannels:[Channel] = []
    var uid:String?
    private var seenUpcoming:Bool = false
    private var seenActive:Bool = false
    private var feedVC:ViewControllerFeed?
    private var passedChannel:Channel?
    var ref:DatabaseReference?
    var db:Firestore?
    var storageRef:StorageReference?
    var myCategory:Category?
    var bigCategory:String?
    private var activeBorder:CALayer?
    private var isfav:Bool?
    private var myFavs:[String:Any] = [:]
    private var isFavourited:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelTable.delegate=self
        channelTable.dataSource=self
        getIfUserFavCategory()
        //notification when user presses home button, detachlisteners is called
       // NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.detachlisteners), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        //notification for when user reopens app after being in the background, appWillEnterForeground is called
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification
        , object: nil)
        
        
        catName.text = myCategory?.categoryName
        
        
        activeBtn.isSelected=true
        activeBorder = activeBtn.selectCategoryButton()
       
        setUpButtons()
       
        
        
        
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
    
    func setUpButtons(){
           pastBtn.setTitleColor(.black, for: .selected  )
           activeBtn.setTitleColor(.black, for: .selected  )
           upcomingBtn.setTitleColor(.black, for: .selected  )
           if #available(iOS 13.0, *) {
               pastBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
               activeBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
               upcomingBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
           } else {
               // Fallback on earlier versions
           }
           
       }
   
    
    //called on initial load and when this view controller is first one shown when app goes from background to foreground
     func onLoad(){
         
               //if activebtn is the current one selected and have not seen it yet
               if activeBtn.isSelected && !seenActive{
                   getActive()
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
    
    func getIfUserFavCategory(){
        self.myFavs = [:]
        if let aUid = uid{
                 
                  
                 let docRef = db?.collection("/Users/\(aUid)/Favorites").document("Favs")
                        
                    
                        docRef?.getDocument{ (document, error) in
                            if let document = document, document.exists {
                              if let myMap = document.data() as? [String:String]{
                                  self.myFavs=myMap
                              }
                              
                            
                             
                            } else {
                             self.myFavs = [:]
                            }
                            self.updateFavButton()
                        }
                      
                  }
              
    }
    
    func updateRighBarButton(isFavourite : Bool){
        let btnFavourite = UIButton(frame: CGRect(x: 0,y: 0,width: 40,height: 40))
        btnFavourite.addTarget(self, action: #selector(self.btnFavouriteDidTap), for: .touchUpInside)


        if isFavourite {
            if #available(iOS 13.0, *) {
                btnFavourite.setImage(UIImage(systemName: "star.fill"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            btnFavourite.tintColor = .orange
        }else{
            if #available(iOS 13.0, *) {
                btnFavourite.setImage(UIImage(systemName: "star"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            btnFavourite.tintColor = .black
        }
        let rightButton = UIBarButtonItem(customView: btnFavourite)
        navBar.setRightBarButtonItems([rightButton], animated: true)
        
    }

    
    func updateFavButton(){
        if let aCatName = myCategory?.categoryName{
            if let bigCat = myFavs[aCatName] as? String{
            if bigCat != "None"{
                isFavourited = true
                updateRighBarButton(isFavourite: isFavourited)
                
                return
            }
            }
        }
        updateRighBarButton(isFavourite: isFavourited)
        
    }
    
    func getActive(){
        
        self.activeChannels=[]
        
        if let aGenCat = bigCategory{
            if let aCatName = myCategory?.categoryName{
                if  let docRef = db?.collection("Categories/\(aGenCat)/\(aCatName)").document("Active"){

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
                                    self.activeChannels.append(myChannel)
                                    }
                                }
                                
                            }
                             self.channelTable.reloadData()
                        }
                               
                                
                            
                            
                            
                    } else {
                        print("Document does not exist")
                    }
                   
                   
                }
            }
        }
        }
        
    }
    func getUpcoming(){
        self.upcomingChannels=[]
        if let aGenCat = bigCategory{
                   if let aCatName = myCategory?.categoryName{
                       if  let docRef = db?.collection("Categories/\(aGenCat)/\(aCatName)").document("Upcoming"){

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
                                           self.upcomingChannels.append(myChannel)
                                           }
                                       }
                                       
                                   }
                                    self.channelTable.reloadData()
                               }
                                      
                                       
                                   
                                   
                                   
                           } else {
                               print("Document does not exist")
                           }
                          
                          
                       }
                   }
               }
               }
        
    }
   
    func getPast(){
        self.pastChannels=[]
               if let aGenCat = bigCategory{
                          if let aCatName = myCategory?.categoryName{
                              if  let docRef = db?.collection("Categories/\(aGenCat)/\(aCatName)").document("Past"){

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
                                                  self.pastChannels.append(myChannel)
                                                  }
                                              }
                                              
                                          }
                                           self.channelTable.reloadData()
                                      }
                                             
                                              
                                          
                                          
                                          
                                  } else {
                                      print("Document does not exist")
                                  }
                                 
                                 
                              }
                          }
                      }
                      }
        
    }
  
    
    
 
  
    
     // MARK: - IBAction Functions
    
    @objc func btnFavouriteDidTap(){
        isFavourited = !isFavourited;
           if self.isFavourited {
               favourite();
           }else{
               unfavourite();
           }
        updateRighBarButton(isFavourite: isFavourited);
        
    }
    
    func favourite(){
        if let aUid = uid{
        let favdoc = db?.collection("/Users/\(aUid)/Favorites").document("Favs")
            if let myCatName = myCategory?.categoryName{
                let mydata = [myCatName:bigCategory]
                favdoc?.setData(mydata as [String : Any], merge: true)
            }
        }
    }
    func unfavourite(){
        if let aUid = uid{
               let favdoc = db?.collection("/Users/\(aUid)/Favorites").document("Favs")
                   if let myCatName = myCategory?.categoryName{
                    let mydata = [myCatName:"None"] as [String : Any?]
                    favdoc?.setData(mydata as [String : Any], merge: true)
                   }
               }
        
    }
    
   
//event when active button is clicked
    @IBAction func activeClicked(_ sender: UIButton) {
        //change buttons state
        upcomingBtn.isSelected = false
             activeBtn.isSelected = true
             pastBtn.isSelected = false
        activeBorder?.removeFromSuperlayer()
               activeBorder = activeBtn.selectCategoryButton()
        getActive()

        
        
        
        
        
    }
    //event when past is clicked
    @IBAction func pastClicked(_ sender: UIButton) {
        upcomingBtn.isSelected = false
        activeBtn.isSelected = false
        pastBtn.isSelected = true
        activeBorder?.removeFromSuperlayer()
        activeBorder = pastBtn.selectCategoryButton()
        getPast()
    }
    
    //event when upcoming is clicked
    @IBAction func upcomingClicked(_ sender: UIButton) {
        //change state of buttons
        upcomingBtn.isSelected = true
        activeBtn.isSelected = false
        pastBtn.isSelected = false
        activeBorder?.removeFromSuperlayer()
        activeBorder = upcomingBtn.selectCategoryButton()
        getUpcoming()
      
        
     

    }
    
    func arrowTap(cell: ChannelCells){
        self.channelTable.selectRow(at: self.channelTable.indexPath(for: cell), animated: true, scrollPosition: .middle)
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
            
        }else if pastBtn.isSelected{
            return pastChannels.count
        }
       return 0
        
    }
    
    
    //populate cells in table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
              
        if upcomingBtn.isSelected {
            let cell = channelTable.dequeueReusableCell(withIdentifier: "upcomingChannelCell", for: indexPath) as! UpcomingChannelCells
            if upcomingChannels.count > 0 {
                cell.channelName?.text = self.upcomingChannels[indexPath.row].channelName
                cell.startDate?.text = "Start: Date"
                cell.selectionStyle = .none
            }
            return cell
        }
        else{
            let cell = channelTable.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! ChannelCells
        if activeBtn.isSelected {
            if activeChannels.count > 0 {
                cell.channelName?.text = self.activeChannels[indexPath.row].channelName
                cell.delegate = self
            }
            return cell
            
        }else if pastBtn.isSelected{
            if pastChannels.count > 0{
                 cell.channelName?.text = self.pastChannels[indexPath.row].channelName
                cell.delegate = self
            }
            return cell
        }
        }
          return UITableViewCell()
    }
  

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let index = channelTable.indexPathForSelectedRow?.row {
            if activeBtn.isSelected{
                passedChannel = activeChannels[index]
            }else if pastBtn.isSelected{
                passedChannel = pastChannels[index]
            }
            
            feedVC = segue.destination as? ViewControllerFeed
            feedVC?.myChannel = passedChannel
            feedVC?.ref=self.ref
            feedVC?.uid=self.uid
            feedVC?.db=self.db
            feedVC?.storageRef=self.storageRef
        }
       
        
        
        
    }
    

}//end of class
