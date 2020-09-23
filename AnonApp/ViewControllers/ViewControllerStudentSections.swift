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
    private var refreshControl = UIRefreshControl()
    lazy var settingsMenuLauncher:SettingsMenuQuip = {
        let launcher = SettingsMenuQuip()
     launcher.homeController = self
         return launcher
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tabBar = tabBarController as! BaseTabBarController
               
              authorizeUser(tabBar: tabBar)
       
        studentSectionsTableView.delegate = self
        studentSectionsTableView.dataSource = self
        refreshControl.addTarget(self, action: #selector(ViewControllerStudentSections.refreshTable), for: .valueChanged)
        studentSectionsTableView.refreshControl = refreshControl
        refreshTable()
    }
    
    @IBAction func settingsClicked(_ sender: Any) {
        settingsMenuLauncher.makeViewFade()
        settingsMenuLauncher.addMenuFromSide()
        
    }
    
    func authorizeUser(tabBar:BaseTabBarController){
                
                Auth.auth().signInAnonymously() {[weak self] (authResult, error) in
                  // ...
                 guard let user = authResult?.user else { return }
                     self?.uid = user.uid
                 tabBar.userID=user.uid
                   UserDefaults.standard.set(user.uid, forKey: "UID")
                  FirestoreService.sharedInstance.getBlockedUsers(uid: user.uid) { (myblockedUsers) in
                      blockedUsers = myblockedUsers
                  }
                }
                
               
            }
    
    
    @objc func refreshTable(){
        refreshControl.beginRefreshing()
        FirestoreService.sharedInstance.getUniversities {[weak self] (schools) in
            self?.mySchools = schools
            self?.studentSectionsTableView.reloadData()
            self?.refreshControl.endRefreshing()
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
    func showNextControllerSettings(menuItem:MenuItem){
         if menuItem.name == "Privacy Policy"{
              let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
              let nextViewController = storyBoard.instantiateViewController(withIdentifier: "PrivacyController") as! myUIViewController
              navigationController?.pushViewController(nextViewController, animated: true)
          }else if menuItem.name == "Report a Problem"{
              let email = supportEmail
              if let url = URL(string: "mailto:\(email)") {
                   UIApplication.shared.open(url)
              }
          }else if menuItem.name == "Contact Us"{
              let email = supportEmail
                         if let url = URL(string: "mailto:\(email)") {
                              UIApplication.shared.open(url)
                         }
          }else if menuItem.name == "Link Email"{
              let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
              let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CreateAccount") as! myUIViewController
              nextViewController.navigationItem.title = "Link Email"
              navigationController?.pushViewController(nextViewController, animated: true)
          }
          
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
