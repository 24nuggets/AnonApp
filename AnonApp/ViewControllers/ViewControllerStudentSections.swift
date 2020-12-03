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
        
       
        studentSectionsTableView.delegate = self
        studentSectionsTableView.dataSource = self
        refreshControl.addTarget(self, action: #selector(ViewControllerStudentSections.refreshTable), for: .valueChanged)
        studentSectionsTableView.refreshControl = refreshControl
        refreshTable()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
       
        self.uid = UserDefaults.standard.string(forKey: "UID")
    }
   
    
    @IBAction func settingsClicked(_ sender: Any) {
        settingsMenuLauncher.makeViewFade()
        settingsMenuLauncher.addMenuFromSide()
        
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
          }else if menuItem.name == "EULA"{
              let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                         let nextViewController = storyBoard.instantiateViewController(withIdentifier: "EULAViewController") as! myUIViewController
                         navigationController?.pushViewController(nextViewController, animated: true)
          }else if menuItem.name == "Share"{
            shareApp()
          }
          
      }
    
    
    @IBAction func shareClicked(_ sender: Any) {
        shareApp()
    }
    
    func shareApp(){
        DynamicLinks.performDiagnostics(completion: nil)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "nuthouse.page.link"
        components.path = "/app"
        
        let eventUIDQueryItem = URLQueryItem(name: "invitedby", value: uid)
      
        components.queryItems = [eventUIDQueryItem]
        guard let linkparam = components.url else {return}
        
        let dynamicLinksDomainURIPrefix = "https://nuthouse.page.link"
        
        guard let sharelink = DynamicLinkComponents.init(link: linkparam, domainURIPrefix: dynamicLinksDomainURIPrefix) else {return}
        if let bundleId = Bundle.main.bundleIdentifier {
            print(bundleId)
            sharelink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
        }
        //change to app store id
        sharelink.iOSParameters?.appStoreID = appStoreID
        print(sharelink.iOSParameters?.appStoreID)
        sharelink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        sharelink.socialMetaTagParameters?.imageURL = logoURL
        
       // sharelink.socialMetaTagParameters?.descriptionText = aquip.channel
       
            guard let longDynamicLink = sharelink.url else { return }
        
            print("The long URL is: \(longDynamicLink)")
        
                sharelink.shorten {[weak self] (url, warnings, error) in
                    if let error = error{
                        print(error)
                        return
                    }
                    if let warnings = warnings{
                        for warning in warnings{
                            print(warning)
                        }
                    }
                    guard let url = url else {return}
                    print(url)
                    self?.showShareViewController(url: url)
                }
        
       
            Analytics.logEvent(AnalyticsEventShare, parameters:
                [AnalyticsParameterItemID:"id- \(uid ?? "Other")",
                    AnalyticsParameterItemName: uid ?? "None",
                          AnalyticsParameterContentType: "event"])
        
    }
    
    func showShareViewController(url:URL){
        let myactivity1 = "Join the Nut House now!"
        let myactivity2 = url
                             
                        
                               // set up activity view controller
        let firstactivity = [myactivity1, myactivity2] as [Any]
                        let activityViewController = UIActivityViewController(activityItems: firstactivity, applicationActivities: nil)
                              activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

                               // exclude some activity types from the list (optional)
                        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]

                               // present the view controller
                               self.present(activityViewController, animated: true, completion: nil)
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



