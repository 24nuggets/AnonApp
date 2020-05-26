//
//  ViewControllerCategories.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerCategories: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate2, MyCellDelegate3, UISearchBarDelegate {
  
    
    @IBOutlet weak var sportsBtn: UIButton!
    
    @IBOutlet weak var entertainmentBtn: UIButton!
    @IBOutlet weak var liveBtn: UIButton!
    @IBOutlet weak var categoriesTable: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    private var ref:DatabaseReference?
    private var db:Firestore?
    private var discoverVC:ViewControllerDiscover?
    private var uid:String?
    private var category:[String:String]=[:]
    private var myLiveEvents:[Channel]=[]
    private var mySports:[Category]=[]
    private var allSports:[Category]=[]
    private var allEntertainment:[Category]=[]
    private var myEntertainment:[Category]=[]
    private var filteredCats:[Category]=[]
    private var storageRef:StorageReference?
    private var activeBorder:CALayer?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoriesTable.delegate=self
        categoriesTable.dataSource=self
        
        liveBtn.isSelected=true
        activeBorder = liveBtn.selectCategoryButton()
        
        let tabBar = tabBarController as! BaseTabBarController
        authorizeUser(tabBar: tabBar)
        self.ref = tabBar.refDatabaseFirebase()
        self.db = tabBar.refDatabaseFirestore()
        self.storageRef = tabBar.refStorage()
        setUpButtons()
        self.searchBar.layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            self.searchBar.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            // Fallback on earlier versions
        }    
        self.searchBar.layoutIfNeeded()
        self.searchBar.delegate=self
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           if let selectedIndexPath = categoriesTable.indexPathForSelectedRow {
               categoriesTable.deselectRow(at: selectedIndexPath, animated: animated)
           }
    
           updateTable()
       }
    func setUpButtons(){
        sportsBtn.setTitleColor(.black, for: .selected  )
        liveBtn.setTitleColor(.black, for: .selected  )
        entertainmentBtn.setTitleColor(.black, for: .selected  )
        if #available(iOS 13.0, *) {
            sportsBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
            liveBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
            entertainmentBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
        } else {
            // Fallback on earlier versions
        }
        
    }
    func updateTable(){
        if sportsBtn.isSelected{
            searchBar.placeholder = "Search Teams and Leagues"
            getSports()
        }else if liveBtn.isSelected{
            searchBar.placeholder = "Search Current Events"
            getLive()
        }else if entertainmentBtn.isSelected{
            searchBar.placeholder = "Search T.V. Shows and Entertainment"
            getEntertainment()
        }
    }
    
    @IBAction func sportsClicked(_ sender: Any) {
        if sportsBtn.isSelected==false{
            liveBtn.isSelected=false
            entertainmentBtn.isSelected=false
        sportsBtn.isSelected=true
        activeBorder?.removeFromSuperlayer()
        activeBorder = sportsBtn.selectCategoryButton()
            updateTable()
        }
    
    }
    
    @IBAction func liveClicked(_ sender: Any) {
         if liveBtn.isSelected==false{
                   liveBtn.isSelected=true
                   entertainmentBtn.isSelected=false
               sportsBtn.isSelected=false
               activeBorder?.removeFromSuperlayer()
               activeBorder = liveBtn.selectCategoryButton()
            updateTable()
               }
        
        
    }
    
    @IBAction func entertainmentClicked(_ sender: Any) {
         if entertainmentBtn.isSelected==false{
                   liveBtn.isSelected=false
                   entertainmentBtn.isSelected=true
               sportsBtn.isSelected=false
               activeBorder?.removeFromSuperlayer()
               activeBorder = entertainmentBtn.selectCategoryButton()
            updateTable()
               }
    }
    
    
    func authorizeUser(tabBar:BaseTabBarController){
              
              Auth.auth().signInAnonymously() { (authResult, error) in
                // ...
               guard let user = authResult?.user else { return }
                   self.uid = user.uid
               tabBar.userID=user.uid
              }
              
             
          }
    
    func getLive(){
        self.myLiveEvents=[]
        let docRef = db?.collection("Categories").document("Live")

        docRef?.getDocument { (document, error) in
            if let document = document, document.exists {
                if let myLiveEvents = document.data() {
                
                for aEvent in myLiveEvents.keys{
                    let eventID = aEvent
                    if let eventInfo = myLiveEvents[aEvent] as? [String:Any]{
                        if let eventName = eventInfo["name"] as? String{
                            let priority = eventInfo["priority"] as? Int
                            let myEvent = Channel(name: eventName, start: nil, akey: eventID, aparent: nil, aparentkey: nil, apriority: priority)
                            self.myLiveEvents.append(myEvent)
                        }
                    }
                }
                    self.categoriesTable.reloadData()
                
                
                
                }
                
            } else {
                print("Document does not exist")
            }
        }
        
    }
    
    func getSports(){
        allSports = []
           self.mySports=[]
           let docRef = db?.collection("Categories").document("Sports")

           docRef?.getDocument { (document, error) in
               if let document = document, document.exists {
                if let mySports = document.data(){
                    for aSport in mySports.keys{
                        let name = aSport
                        if let myInfo = mySports[aSport] as? [String:Any]{
                             let priority = myInfo["priority"] as? Int
                            let mySport = Category(name: name, aPriority: priority)
                            self.allSports.append(mySport)
                            if priority != 0 {
                            self.mySports.append(mySport)
                            }
                        }
                        
                    }
                     self.categoriesTable.reloadData()
                }
                    
                  
                       
                   
               } else {
                   print("Document does not exist")
               }
           }
           
       }
    func getEntertainment(){
        allEntertainment = []
           self.myEntertainment=[]
           let docRef = db?.collection("Categories").document("Entertainment")

           docRef?.getDocument { (document, error) in
           if let document = document, document.exists {
            if let myEntertainments = document.data(){
                for aEntertainment in myEntertainments.keys{
                    let name = aEntertainment
                    if let myInfo = myEntertainments[aEntertainment] as? [String:Any]{
                         let priority = myInfo["priority"] as? Int
                        let myEntertainment = Category(name: name, aPriority: priority)
                        self.allEntertainment.append(myEntertainment)
                        if priority != 0 {
                        self.myEntertainment.append(myEntertainment)
                        }
                    }
                    
                }
                 self.categoriesTable.reloadData()
                }
                       
                   
               } else {
                   print("Document does not exist")
               }
           }
           
       }
    
    func arrowTapped(cell: CategoryCells){
        self.categoriesTable.selectRow(at: self.categoriesTable.indexPath(for: cell), animated: true, scrollPosition: .middle)
    }
    func arrowTap(cell: ChannelCells){
        self.categoriesTable.selectRow(at: self.categoriesTable.indexPath(for: cell), animated: true, scrollPosition: .middle)
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if isSearchBarEmpty() == false{
            filterSearchResults(searchText: searchText)
        }
        
    }
    
    func filterSearchResults(searchText:String){
        
       
        if liveBtn.isSelected{
            
        }else if sportsBtn.isSelected{
            
            filteredCats = allSports.filter{($0.categoryName?.contains(searchText) ?? false)}
            
        }else if entertainmentBtn.isSelected{
            filteredCats = allEntertainment.filter{($0.categoryName?.contains(searchText) ?? false)}
        }
        self.categoriesTable.reloadData()
    }
    
    func isSearchBarEmpty()->Bool{
       return searchBar.text?.isEmpty ?? true
    }
       
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchBarEmpty(){
        if liveBtn.isSelected{
            return myLiveEvents.count
        }else if sportsBtn.isSelected{
            return mySports.count
        }else if entertainmentBtn.isSelected{
            return myEntertainment.count
        }
        }else{
            if liveBtn.isSelected  {
                return 0
            }
            else {
                return filteredCats.count
            }
        }
          return 0
    }
         
         func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            
            if liveBtn.isSelected{
                if let cell = categoriesTable.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as? ChannelCells{
                               
                        cell.channelName?.text = self.myLiveEvents[indexPath.row].channelName
                    cell.delegate = self
                               return cell
                }
                
                
                
            }else if sportsBtn.isSelected{
                if let cell = categoriesTable.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryCells{
                    if isSearchBarEmpty(){
                      cell.categoryName.text = self.mySports[indexPath.row].categoryName
                        
                    }else{
                        cell.categoryName.text = self.filteredCats[indexPath.row].categoryName
                    }
                    
                    cell.delegate = self
                              return cell
                
                }
            }else if entertainmentBtn.isSelected{
                if let cell = categoriesTable.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryCells{
                    if isSearchBarEmpty(){
                cell.categoryName.text = self.myEntertainment[indexPath.row].categoryName
                    }else{
                    cell.categoryName.text = self.filteredCats[indexPath.row].categoryName
                    }
                 cell.delegate = self
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
      
            if let index = categoriesTable.indexPathForSelectedRow?.row {
                if let discoverVC = segue.destination as? ViewControllerDiscover{
                if isSearchBarEmpty(){
                    if sportsBtn.isSelected {
                    discoverVC.myCategory = mySports[index]
                        discoverVC.bigCategory = "Sports"
                    }else if entertainmentBtn.isSelected{
                        discoverVC.myCategory = myEntertainment[index]
                        discoverVC.bigCategory = "Entertainment"
                    }
                }else{
                    if sportsBtn.isSelected {
                    discoverVC.myCategory = filteredCats[index]
                        discoverVC.bigCategory = "Sports"
                    }else if entertainmentBtn.isSelected{
                        discoverVC.myCategory = filteredCats[index]
                        discoverVC.bigCategory = "Entertainment"
                    }
                    }
                 discoverVC.ref=self.ref
                discoverVC.db=self.db
                 discoverVC.uid=self.uid
                discoverVC.storageRef=self.storageRef
                }
                if let feedVC = segue.destination as? ViewControllerFeed{
                if liveBtn.isSelected {
                
               feedVC.myChannel = myLiveEvents[index]
                 feedVC.ref=self.ref
                 feedVC.uid=self.uid
                 feedVC.db=self.db
                 feedVC.storageRef=self.storageRef
                }
                 
        }
    }
    }
    
   
}

