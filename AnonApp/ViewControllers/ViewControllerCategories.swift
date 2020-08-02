//
//  ViewControllerCategories.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase


class ViewControllerCategories: myUIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
  
    
    
   
    
  
    
    @IBOutlet weak var sportsBtn: UIButton!
    
    @IBOutlet weak var entertainmentBtn: UIButton!
    @IBOutlet weak var liveBtn: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var bottomBar: UIView!
    
    @IBOutlet weak var bottomBarLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarTrailing2: NSLayoutConstraint!
    @IBOutlet weak var bottomBarLeading2: NSLayoutConstraint!
    @IBOutlet weak var bottomBarLeading3: NSLayoutConstraint!
    
    @IBOutlet weak var bottomBarTrailing3: NSLayoutConstraint!
    
    @IBOutlet weak var menuView: UIView!
    
    
    
   
    private weak var discoverVC:ViewControllerDiscover?
    private var uid:String?
    private var category:[String:String]=[:]
    weak var selectedCategory:Category?
   weak  var selectedChannel:Channel?
   
   
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let flowlayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout{
            flowlayout.minimumLineSpacing = 0
        }
        
        liveBtn.isSelected=true
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let tabBar = tabBarController as! BaseTabBarController
        authorizeUser(tabBar: tabBar)
        
        setUpButtons()
        selectLive()
          
        
        self.searchBar.delegate=self
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.font = .systemFont(ofSize: 16)
        } else {
            // Fallback on earlier versions
        }
       hideKeyboardWhenTappedAround2()
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
       //    if let selectedIndexPath = categoriesTable.indexPathForSelectedRow {
        //       categoriesTable.deselectRow(at: selectedIndexPath, animated: animated)
       //    }
    self.searchBar.layer.borderWidth = 1
    if #available(iOS 13.0, *) {
        self.searchBar.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        
    } else {
        // Fallback on earlier versions
    }
    self.searchBar.layoutIfNeeded()
          // updateTable()
        
        
        
       }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.searchBar.layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            self.searchBar.layer.borderColor = UIColor.secondarySystemBackground.cgColor
            
        } else {
            // Fallback on earlier versions
        }
        self.searchBar.layoutIfNeeded()
    }
    func setUpButtons(){
       let selectedColor = UIColor(hexString: "ffaf46")
                      liveBtn.setTitleColor(selectedColor, for: .selected  )
                      sportsBtn.setTitleColor(selectedColor, for: .selected  )
        entertainmentBtn.setTitleColor(selectedColor, for: .selected  )
        
    }
    func updateTable(){
        if sportsBtn.isSelected{
            searchBar.text = ""
            searchBar.placeholder = "Search Teams and Leagues"
            
        }else if liveBtn.isSelected{
            searchBar.text = ""
            searchBar.placeholder = "Search Live Events"
           
        }else if entertainmentBtn.isSelected{
            searchBar.text = ""
            searchBar.placeholder = "Search Shows"
           
        }
    }
    
    @IBAction func sportsClicked(_ sender: Any) {
        if sportsBtn.isSelected==false{
           selectSports()
             
        }
    
    }
    func selectSports(){
        sportsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        liveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        entertainmentBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
       
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
                  scrollToItemAtIndexPath(index:  1)
                   updateTable()
        
        let myIndexPath = IndexPath(item: 1, section: 0)
                       if let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellSportsCategories{
                        cell.isFiltered = false
                           cell.categoriesTable.reloadData()
                       }
    }
    
    @IBAction func liveClicked(_ sender: Any) {
         if liveBtn.isSelected==false{
               selectLive()
            
               }
        
        
    }
    func selectLive(){
        liveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        sportsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        entertainmentBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
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
        scrollToItemAtIndexPath(index:  0)
                updateTable()
        let myIndexPath = IndexPath(item: 0, section: 0)
                       if let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellLiveCategories{
                           cell.isFiltered = false
                           cell.categoriesTable.reloadData()
                       }
        
    }
    
    @IBAction func entertainmentClicked(_ sender: Any) {
         if entertainmentBtn.isSelected==false{
              selectEntertainment()
            
               }
    }
    func selectEntertainment(){
        entertainmentBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        sportsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        liveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
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
        scrollToItemAtIndexPath(index:  2)
               updateTable()
        let myIndexPath = IndexPath(item: 2, section: 0)
                       if let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellEntertainmentCategories{
                           cell.isFiltered = false
                           cell.categoriesTable.reloadData()
                       }
    }
    
    func scrollToItemAtIndexPath(index: Int){
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    
    func authorizeUser(tabBar:BaseTabBarController){
              
              Auth.auth().signInAnonymously() {[weak self] (authResult, error) in
                // ...
               guard let user = authResult?.user else { return }
                   self?.uid = user.uid
               tabBar.userID=user.uid
              }
              
             
          }
    
  
    
   
    
   
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if isSearchBarEmpty() == false{
            if liveBtn.isSelected{
                let myIndexPath = IndexPath(item: 0, section: 0)
                let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellLiveCategories
                cell?.filterSearchResults(searchText: searchText)
            }else if sportsBtn.isSelected{
                let myIndexPath = IndexPath(item: 1, section: 0)
                let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellSportsCategories
                cell?.filterSearchResults(searchText: searchText)
            }else if entertainmentBtn.isSelected{
                let myIndexPath = IndexPath(item: 2, section: 0)
                let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellEntertainmentCategories
                cell?.filterSearchResults(searchText: searchText)
            }
            
        }else{
            for i in 0...2{
            let myIndexPath = IndexPath(item: i, section: 0)
                if let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellLiveCategories{
                    cell.isFiltered = false
                    cell.categoriesTable.reloadData()
                }else if let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellSportsCategories{
                    cell.isFiltered = false
                  cell.categoriesTable.reloadData()
                }else if let cell = collectionView.cellForItem(at: myIndexPath) as? collectionCellEntertainmentCategories{
                    cell.isFiltered = false
                    cell.categoriesTable.reloadData()
                    
                }
            
            }
        }
        
    }
    
   
    
    func isSearchBarEmpty()->Bool{
       return searchBar.text?.isEmpty ?? true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCollectionCellLiveCategories", for: indexPath) as? collectionCellLiveCategories{
             
             return cell
            }
            
        }else if indexPath.row == 1{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCollectionCellSportsCategories", for: indexPath) as? collectionCellSportsCategories{
            
             return cell
            }
            
        }else if indexPath.row == 2{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCollectionCellEntertainmentCategories", for: indexPath) as? collectionCellEntertainmentCategories{
         
            return cell
            }
        }
      
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let index = targetContentOffset.pointee.x / view.frame.width
        if index == 0 {
           selectLive()
        }else if index == 1{
            selectSports()
        }else if index == 2{
            selectEntertainment()
        }
        
    }
       
   
         
       

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
      
           
                if let discoverVC = segue.destination as? ViewControllerDiscover{
                if isSearchBarEmpty(){
                    if sportsBtn.isSelected {
                        let indexPath = IndexPath(item: 1, section: 0)
                        let cell = collectionView.cellForItem(at: indexPath) as? collectionCellSportsCategories
                        if let index = cell?.categoriesTable.indexPathForSelectedRow?.row{
                        
                        discoverVC.myCategory = cell?.mySports[index]
                        discoverVC.bigCategory = "Sports"
                            let myIndexPath = IndexPath(item: index, section: 0)
                                                        cell?.categoriesTable.deselectRow(at: myIndexPath, animated: true)
                        }
                       
                    }else if entertainmentBtn.isSelected{
                         let indexPath = IndexPath(item: 2, section: 0)
                        let cell = collectionView.cellForItem(at: indexPath) as? collectionCellEntertainmentCategories
                        if let index = cell?.categoriesTable.indexPathForSelectedRow?.row{
                                               
                            discoverVC.myCategory = cell?.myEntertainment[index]
                            discoverVC.bigCategory = "Entertainment"
                            let myIndexPath = IndexPath(item: index, section: 0)
                             cell?.categoriesTable.deselectRow(at: myIndexPath, animated: true)
                        }
                        
                        
                    }
                }else{
                    if sportsBtn.isSelected {
                    let indexPath = IndexPath(item: 1, section: 0)
                    let cell = collectionView.cellForItem(at: indexPath) as? collectionCellSportsCategories
                    if let index = cell?.categoriesTable.indexPathForSelectedRow?.row{
                                           
                        discoverVC.myCategory = cell?.filteredCats[index]
                        discoverVC.bigCategory = "Sports"
                        let myIndexPath = IndexPath(item: index, section: 0)
                                                    cell?.categoriesTable.deselectRow(at: myIndexPath, animated: true)
                        }
                        
                    }else if entertainmentBtn.isSelected{
                         let indexPath = IndexPath(item: 2, section: 0)
                        let cell = collectionView.cellForItem(at: indexPath) as? collectionCellEntertainmentCategories
                        if let index = cell?.categoriesTable.indexPathForSelectedRow?.row{
                                                                      
                            discoverVC.myCategory = cell?.filteredCats[index]
                            discoverVC.bigCategory = "Entertainment"
                            let myIndexPath = IndexPath(item: index, section: 0)
                                                        cell?.categoriesTable.deselectRow(at: myIndexPath, animated: true)
                        }
                         
                    }
                    }
                
                 discoverVC.uid=self.uid
                
                }
        
        
                if let feedVC = segue.destination as? ViewControllerFeed{
                if liveBtn.isSelected {
                    let indexPath = IndexPath(item: 0, section: 0)
                    let cell = collectionView.cellForItem(at: indexPath) as? collectionCellLiveCategories
                    if let index = cell?.categoriesTable.indexPathForSelectedRow?.row{
                                                                                         
                        feedVC.myChannel = cell?.myLiveEvents[index]
                        feedVC.isOpen = true
                        feedVC.uid=self.uid
                        let myIndexPath = IndexPath(item: index, section: 0)
                                                    cell?.categoriesTable.deselectRow(at: myIndexPath, animated: true)
                       
                        
                        Analytics.logEvent(AnalyticsEventViewItem, parameters: [AnalyticsParameterGroupID:cell?.myLiveEvents[index].channelName ?? "Other",
                        AnalyticsParameterContentType:"viewEvent"])
                    }
                    
                
              
                 
                }
                 
        }
    
    }
    
   
}

