//
//  ViewControllerStudentSections.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 8/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerStudentSections: myUIViewController, UITableViewDelegate, UITableViewDataSource, MyCellDelegate2{
    
    
   
    
    
    
    
    @IBOutlet var studentSectionsTableView: UITableView!
    var mySchools:[Channel] = []
    var uid:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tabBar = tabBarController as! BaseTabBarController
               
              authorizeUser(tabBar: tabBar)
       
        studentSectionsTableView.delegate = self
        studentSectionsTableView.dataSource = self
        refreshTable()
    }
    func authorizeUser(tabBar:BaseTabBarController){
                
                Auth.auth().signInAnonymously() {[weak self] (authResult, error) in
                  // ...
                 guard let user = authResult?.user else { return }
                     self?.uid = user.uid
                 tabBar.userID=user.uid
                  FirestoreService.sharedInstance.getBlockedUsers(uid: user.uid) { (myblockedUsers) in
                      blockedUsers = myblockedUsers
                  }
                }
                
               
            }
    
    
    func refreshTable(){
        FirestoreService.sharedInstance.getUniversities {[weak self] (schools) in
            self?.mySchools = schools
            self?.studentSectionsTableView.reloadData()
        }
    }
    
    func arrowTapped(cell: CategoryCells) {
        self.studentSectionsTableView.selectRow(at: self.studentSectionsTableView.indexPath(for: cell), animated: true, scrollPosition: .middle)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mySchools.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           if let cell = studentSectionsTableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryCells{
                 
                  
                  cell.categoryName?.text = self.mySchools[indexPath.row].channelName
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
        
        if let feedVC = segue.destination as? ViewControllerFeed{
               
               if let index = studentSectionsTableView.indexPathForSelectedRow?.row{
                                      
                   let passedChannel = mySchools[index]
                   let myIndexPath = IndexPath(item: index, section: 0)
                    studentSectionsTableView.deselectRow(at: myIndexPath, animated: true)
                   Analytics.logEvent(AnalyticsEventViewItem, parameters: [AnalyticsParameterGroupID:mySchools[index].channelName ?? "Other",
                   AnalyticsParameterContentType:"viewEvent"])
                feedVC.myChannel = passedChannel
                feedVC.isOpen = true
                
                 feedVC.uid=self.uid
                   }
            
            }
    }
    

}
