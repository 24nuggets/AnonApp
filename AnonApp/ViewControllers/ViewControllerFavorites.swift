//
//  ViewControllerFavorites.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/22/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit


class ViewControllerFavorites: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCellDelegate2 {
   
    //IB Outlets
    @IBOutlet weak var favCategoriesTable: UITableView!
    
    
    //Declare Variables
    
       private var index:Int?
    private var didReorder:Bool = false
       var uid:String?
       private weak var feedVC:ViewControllerFeed?
       private weak var passedChannel:Channel?
    private var myFavCats:[Category] = []
    lazy var MenuLauncher:addFavsMenu = {
        let launcher = addFavsMenu()
        launcher.favController = self
        return launcher
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        favCategoriesTable.delegate=self
        favCategoriesTable.dataSource=self
        
    
        
        //notification for when user reopens app after being in the background, appWillEnterForeground is called
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerFavorites.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let tabBar = tabBarController as! BaseTabBarController
        
        self.uid = tabBar.userID
        
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         
        resetVars()
         onLoad()
     }
    
    
    func resetVars(){
        didReorder = false
        if let selectedIndexPath = favCategoriesTable  .indexPathForSelectedRow {
            favCategoriesTable.deselectRow(at: selectedIndexPath, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       changeTableToNormal()
        
    }
    
    func reorderFavs(){
        if let auid = uid{
            FirestoreService.sharedInstance.reorderUserFavs(aUid: auid , myFavs: myFavCats)
        }
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
    
    @IBAction func editButtonClicked(_ sender: Any) {
        if(favCategoriesTable.isEditing == true)
          {
              changeTableToNormal()
                if didReorder{
                    reorderFavs()
                }
          }
          else
          {
              changeTableToEdit()
          }
    }
    private func changeTableToEdit(){
        favCategoriesTable.isEditing = true
        self.navigationItem.leftBarButtonItem?.title = "Done"
    }
    private func changeTableToNormal(){
        favCategoriesTable.isEditing = false
        self.navigationItem.leftBarButtonItem?.title = "Edit"
    }
    
    @IBAction func addFavClick(_ sender: Any) {
      
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
    }
    
    func showAddViewController(menuItem: MenuItem){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "addFavsOne") as! ViewControllerAddFavsOne
        nextViewController.uid = uid
        nextViewController.parentVC = self
        let catNames = myFavCats.map { (cat:Category) -> String in
            (cat.categoryName ?? "N/A")
        }
        if catNames.count > 0 {
        nextViewController.currentFavs=Dictionary(uniqueKeysWithValues: zip(catNames, 1...catNames.count))
        }
        if menuItem.name == "Add Teams and Leagues"{
            nextViewController.isAddSports = true
           // nextViewController.navigationItem.title = "Add Teams and Leagues"
        }else{
            nextViewController.isAddSports = false
           // nextViewController.navigationItem.title = "Add Shows"
        }
        navigationController?.showDetailViewController(nextViewController, sender: nil)
          
    }
    
       
        // MARK: - Database Functions
    
    func getIfUserFavCategories(){
        
        
          if let aUid = uid{
            FirestoreService.sharedInstance.getUserFavCategories(aUid: aUid) {[weak self] (myFavCats) in
                self?.myFavCats = myFavCats
                self?.favCategoriesTable.reloadData()
            }
                    
                        
                    }
                
      }
    
    func arrowTapped(cell: CategoryCells){
           self.favCategoriesTable.selectRow(at: self.favCategoriesTable.indexPath(for: cell), animated: true, scrollPosition: .middle)
       }
     // MARK: - TableView Functions
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            
            let myCat = myFavCats[indexPath.row]
            if let auid = uid{
                if let myCatName = myCat.categoryName{
                    if let bigCat = myCat.bigCat{
                        FirestoreService.sharedInstance.unfavoriteCatagory(aUid: auid, myCatName: myCatName, bigCategory: bigCat)
                        myFavCats.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
               
            }
        }
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCell.EditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
       
    }
    
   func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    didReorder = true
       let movedObject = self.myFavCats[sourceIndexPath.row]
       myFavCats.remove(at: sourceIndexPath.row)
       myFavCats.insert(movedObject, at: destinationIndexPath.row)
   }
    
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
            
                discoverVC.bigCategory = myFavCats[index].bigCat
           
                discoverVC.uid=self.uid
            }
           }
           
           
        
    }
    
    
}
