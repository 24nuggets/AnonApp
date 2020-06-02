//
//  ViewControllerCategories.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewControllerCategories: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate2, MyCellDelegate3, UISearchBarDelegate {
  
    
    @IBOutlet weak var sportsBtn: UIButton!
    
    @IBOutlet weak var entertainmentBtn: UIButton!
    @IBOutlet weak var liveBtn: UIButton!
    @IBOutlet weak var categoriesTable: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var bottomBar: UIView!
    
    @IBOutlet weak var bottomBarLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarTrailing2: NSLayoutConstraint!
    @IBOutlet weak var bottomBarLeading2: NSLayoutConstraint!
    @IBOutlet weak var bottomBarLeading3: NSLayoutConstraint!
    
    @IBOutlet weak var bottomBarTrailing3: NSLayoutConstraint!
    
    @IBOutlet weak var menuView: UIView!
    
    
    
   
    private var discoverVC:ViewControllerDiscover?
    private var uid:String?
    private var category:[String:String]=[:]
    private var myLiveEvents:[Channel]=[]
    private var mySports:[Category]=[]
    private var allSports:[Category]=[]
    private var allEntertainment:[Category]=[]
    private var myEntertainment:[Category]=[]
    private var filteredCats:[Category]=[]
   
   
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoriesTable.delegate=self
        categoriesTable.dataSource=self
        
        liveBtn.isSelected=true
        
        
        let tabBar = tabBarController as! BaseTabBarController
        authorizeUser(tabBar: tabBar)
        
        setUpButtons()
        self.searchBar.layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            self.searchBar.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            // Fallback on earlier versions
        }    
        self.searchBar.layoutIfNeeded()
        self.searchBar.delegate=self
       
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
            UIView.animate(withDuration: 1, animations: {
                self.liveBtn.isSelected=false
                self.entertainmentBtn.isSelected=false
                self.sportsBtn.isSelected=true
                self.bottomBarLeading2.priority = .required
                self.bottomBarTrailing2.priority = .required
                self.bottomBarTrailingConstraint.priority = .defaultLow
                self.bottomBarLeadingConstraint.priority = .defaultLow
                self.bottomBarLeading3.priority = .defaultLow
                self.bottomBarTrailing3.priority = .defaultLow
                UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.menuView.layoutIfNeeded()
                }, completion: nil)
                
            })
           
            updateTable()
        }
    
    }
    
    @IBAction func liveClicked(_ sender: Any) {
         if liveBtn.isSelected==false{
                   liveBtn.isSelected=true
                   entertainmentBtn.isSelected=false
               sportsBtn.isSelected=false
               self.bottomBarLeading2.priority = .defaultLow
                              self.bottomBarTrailing2.priority = .defaultLow
                              self.bottomBarTrailingConstraint.priority = .required
                              self.bottomBarLeadingConstraint.priority = .required
                              self.bottomBarLeading3.priority = .defaultLow
                              self.bottomBarTrailing3.priority = .defaultLow
            
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                               self.menuView.layoutIfNeeded()
                           }, completion: nil)
            updateTable()
               }
        
        
    }
    
    @IBAction func entertainmentClicked(_ sender: Any) {
         if entertainmentBtn.isSelected==false{
                   liveBtn.isSelected=false
                   entertainmentBtn.isSelected=true
               sportsBtn.isSelected=false
               self.bottomBarLeading2.priority = .defaultLow
                              self.bottomBarTrailing2.priority = .defaultLow
                              self.bottomBarTrailingConstraint.priority = .defaultLow
                              self.bottomBarLeadingConstraint.priority = .defaultLow
                              self.bottomBarLeading3.priority = .required
                              self.bottomBarTrailing3.priority = .required
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                               self.menuView.layoutIfNeeded()
                           }, completion: nil)
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
        FirestoreService.sharedInstance.getLiveEvents { (myLiveEvents) in
            self.myLiveEvents = myLiveEvents
            self.categoriesTable.reloadData()
        }
           
       }
    func getSports(){
        self.allSports = []
        self.mySports = []
        FirestoreService.sharedInstance.getSports { (mySports, allSports) in
            self.mySports = mySports
            self.allSports = allSports
            self.categoriesTable.reloadData()
        }
        
    }
    func getEntertainment(){
        allEntertainment = []
           self.myEntertainment=[]
        FirestoreService.sharedInstance.getEntertainment { (myEntertainment, allEntertainment) in
            self.myEntertainment = myEntertainment
            self.allEntertainment = allEntertainment
             self.categoriesTable.reloadData()
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
                
                 discoverVC.uid=self.uid
                
                }
                if let feedVC = segue.destination as? ViewControllerFeed{
                if liveBtn.isSelected {
                
               feedVC.myChannel = myLiveEvents[index]
                 
                 feedVC.uid=self.uid
                 
                }
                 
        }
    }
    }
    
   
}

