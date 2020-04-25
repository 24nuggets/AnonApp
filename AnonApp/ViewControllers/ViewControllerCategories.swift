//
//  ViewControllerCategories.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerCategories: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
    
    
    @IBOutlet weak var categoriesTable: UITableView!
    
   
    
    private var ref:DatabaseReference?
    private var db:Firestore?
    private var discoverVC:ViewControllerDiscover?
    private var uid:String?
    private var category:[String:String]=[:]
    private var myCategories:[Category]=[]
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoriesTable.delegate=self
        categoriesTable.dataSource=self
    
        let tabBar = tabBarController as! BaseTabBarController
        authorizeUser(tabBar: tabBar)
        self.ref = tabBar.refDatabaseFirebase()
        self.db = tabBar.refDatabaseFirestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           if let selectedIndexPath = categoriesTable.indexPathForSelectedRow {
               categoriesTable.deselectRow(at: selectedIndexPath, animated: animated)
           }
    
           updateTable()
       }
    
    func authorizeUser(tabBar:BaseTabBarController){
              
              Auth.auth().signInAnonymously() { (authResult, error) in
                // ...
               guard let user = authResult?.user else { return }
                   self.uid = user.uid
               tabBar.userID=user.uid
              }
              
             
          }
    
    func updateTable(){
        self.myCategories=[]
        let docRef = db?.collection("Categories").document("AllCategories")

        docRef?.getDocument { (document, error) in
            if let document = document, document.exists {
                document.data()?.forEach({aCategory in
                    let myID=aCategory.key
                    let myMap = aCategory.value as! [String:String]
                    let myActiveUpcomingID = myMap["AU"]
                    let myPastID = myMap["Past"]
                    let myCategory = Category(name: myID, akeyUpcomingActive: myActiveUpcomingID ?? "", aKeyPast:   myPastID ?? "")
                
                    self.myCategories.append(myCategory)
                    
                })
                 
                self.categoriesTable.reloadData()
                    
                
            } else {
                print("Document does not exist")
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return myCategories.count
         }
         
         func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = categoriesTable.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
                   
           cell.textLabel?.text = self.myCategories[indexPath.row].categoryName
                
                   return cell
           
           
         }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
      
            if let index = categoriesTable.indexPathForSelectedRow?.row {
                 discoverVC = segue.destination as? ViewControllerDiscover
                discoverVC?.myCategory = myCategories[index]
                 discoverVC?.ref=self.ref
                discoverVC?.db=self.db
                 discoverVC?.uid=self.uid
                 
        }
    }
    
   
}
