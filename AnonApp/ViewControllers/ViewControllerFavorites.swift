//
//  ViewControllerFavorites.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/22/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerFavorites: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate2 {
   
    //IB Outlets
    @IBOutlet weak var favCategoriesTable: UITableView!
    
    
    //Declare Variables
       private var ref:DatabaseReference?
       private var db:Firestore?
    private var storageRef:StorageReference?
       private var index:Int?
       var uid:String?
       private var feedVC:ViewControllerFeed?
       private var passedChannel:Channel?
    private var myFavs:[String:Any] = [:]
    private var myFavCats:[Category] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        favCategoriesTable.delegate=self
        favCategoriesTable.dataSource=self
        
    
        
        //notification for when user reopens app after being in the background, appWillEnterForeground is called
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerFavorites.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let tabBar = tabBarController as! BaseTabBarController
        self.ref = tabBar.refDatabaseFirebase()
        self.uid = tabBar.userID
        self.db = tabBar.refDatabaseFirestore()
        self.storageRef = tabBar.refStorage()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         if let selectedIndexPath = favCategoriesTable  .indexPathForSelectedRow {
             favCategoriesTable.deselectRow(at: selectedIndexPath, animated: animated)
         }
         onLoad()
     }
    
    //deinitializer for notification center
    deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
    //called on initial load and when this view controller is first one shown when app goes from background to foreground
        func onLoad(){
            
                 getIfUserFavCategories()
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
    
    func getIfUserFavCategories(){
        self.myFavCats = []
        self.myFavs = [:]
          if let aUid = uid{
                   
                    
                   let docRef = db?.collection("/Users/\(aUid)/Favorites").document("Favs")
                          
                      
                          docRef?.getDocument{ (document, error) in
                              if let document = document, document.exists {
                                if let myMap = document.data() {
                                    self.myFavs=myMap
                                    for akey in self.myFavs.keys{
                                        if let output = self.myFavs[akey] as? String{
                                            if output != "None"{
                                                let myCat = Category(name: akey, aPriority: nil)
                                                self.myFavCats.append(myCat)
                                        }
                                        }
                                    }
                                }
                                
                              
                               
                              } else {
                               self.myFavs = [:]
                              }
                            self.favCategoriesTable.reloadData()
                          }
                        
                    }
                
      }
    
    func arrowTapped(cell: CategoryCells){
           self.favCategoriesTable.selectRow(at: self.favCategoriesTable.indexPath(for: cell), animated: true, scrollPosition: .middle)
       }
     // MARK: - TableView Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myFavCats.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = favCategoriesTable.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryCells{
           
            
            cell.categoryName?.text = self.myFavCats[indexPath.row].categoryName
            cell.delegate = self
             return cell
       
       }
     return UITableViewCell()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let index = favCategoriesTable.indexPathForSelectedRow?.row {
               
            if let discoverVC = segue.destination as? ViewControllerDiscover{
                discoverVC.myCategory = myFavCats[index]
                if let aCatName = myFavCats[index].categoryName{
                discoverVC.bigCategory = myFavs[aCatName] as? String
                }
            discoverVC.ref=self.ref
            discoverVC.db=self.db
            discoverVC.storageRef=self.storageRef
                discoverVC.uid=self.uid
            }
           }
           
           
        
    }
    
    
}
