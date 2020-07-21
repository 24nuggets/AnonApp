//
//  ViewControllerUser.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/25/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerUser: myUIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   
    
    @IBOutlet weak var nameTextView: UITextView!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var levelLable: UILabel!
    @IBOutlet weak var firstRangeLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var userScoreLabel: UILabel!
    @IBOutlet weak var secondRangeLabel: UILabel!
    @IBOutlet weak var viewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newBtn: UIButton!
    @IBOutlet weak var topBtn: UIButton!
    @IBOutlet weak var bottomBarLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leadingScoreBarConstraint: NSLayoutConstraint!
    
    
    
  //  var bioHeightConstraint:NSLayoutConstraint?
    var uid:String?
    var uidProfile:String?
  private weak var quipVC:ViewControllerQuip?
   private weak var passedQuip:Quip?
   var myLikesDislikesMap:[String:Int] = [:]
   var myNewLikesDislikesMap:[String:Int] = [:]
   var myChannelsMap:[String:String] = [:]
   var myParentChannelsMap:[String:String] = [:]
   var myParentQuipsMap:[String:String] = [:]
    let bioPlaceholderText = "Insert Bio"

   
    
 
    
 
    
    lazy var settingsMenuLauncher:SettingsMenuQuip = {
                 let launcher = SettingsMenuQuip()
              launcher.userController = self
                  return launcher
             }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     //   bioHeightConstraint = NSLayoutConstraint(item: bioTextView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        // Do any additional setup after loading the view.
        if navigationController?.viewControllers.count == 1{
              let tabBar = tabBarController as! BaseTabBarController
              self.uid = tabBar.userID
            uidProfile = uid
        }else{
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
            addGesture()
        }
        nameTextView.layer.cornerRadius = 10
        nameTextView.clipsToBounds = true
        bioTextView.layer.cornerRadius = 10
        bioTextView.clipsToBounds = true
        nameTextView.textContainer.maximumNumberOfLines = 2
        nameTextView.textContainer.lineBreakMode = .byClipping
        bioTextView.textContainer.maximumNumberOfLines = 5
        bioTextView.textContainer.lineBreakMode = .byClipping
        loadUserProfile()
        getUserScore()
        
        
        
            collectionView.delegate = self
                   collectionView.dataSource = self
                  setUpButtons()
                  selectNew()
        
            
    }
    
   
    
    override func viewDidAppear(_ animated: Bool){
          super.viewDidAppear(animated)
        
           
        }
    
    //updates firestore and firebase with likes when view is dismissed
      override func viewWillDisappear(_ animated: Bool){
             super.viewWillDisappear(animated)

          
             
           }
    func loadUserProfile(){
        if let auid = uidProfile{
        FirestoreService.sharedInstance.getUserProfile(uid: auid) {[weak self] (name, bio) in
            self?.nameTextView.text = name
            self?.bioTextView.text = bio
            if bio == self?.bioPlaceholderText{
             //   self?.bioTextView.addConstraint((self?.bioHeightConstraint)!)
                self?.bioTextView.isHidden = true
            }else{
             //   self?.bioTextView.removeConstraint((self?.bioHeightConstraint)!)
                self?.bioTextView.isHidden = false
            }
            self?.view.setNeedsLayout()
        }
        }
    }
    
    func setUpButtons(){
               let selectedColor = UIColor(hexString: "ffaf46")
                newBtn.setTitleColor(selectedColor, for: .selected  )
                topBtn.setTitleColor(selectedColor, for: .selected  )
                
            }
    
    func getUserScore(){
        if let auid = uidProfile{
            FirebaseService.sharedInstance.getUserOverallScore(uid: auid) {[weak self] (score) in
                self?.adjustScoreLogic(score: score)
                
            }
        }
    }
    
    func adjustScoreLogic(score:Int){
        let progressBarLength = progressBar.bounds.width
        if score < 0 {
            userScoreLabel.text = "0"
            levelLable.text = "Level 1"
            firstRangeLabel.text = "0"
            secondRangeLabel.text = "100"
            progressBar.progress = 0.0
            leadingScoreBarConstraint.constant = 0
            
        }
        else if score < 100{
        
        userScoreLabel.text = String(score)
        levelLable.text = "Level 1"
        firstRangeLabel.text = "0"
        secondRangeLabel.text = "100"
            let progress = Float(score) / 100.0
        progressBar.progress = progress
            leadingScoreBarConstraint.constant = progressBarLength * CGFloat(progress)
        }
        else if score < 1000{
            userScoreLabel.text = String(score)
                   levelLable.text = "Level 2"
                   firstRangeLabel.text = "100"
                   secondRangeLabel.text = "1000"
                       let progress = (Float(score) - 100) / 900.0
                   progressBar.progress = progress
                       leadingScoreBarConstraint.constant = progressBarLength * CGFloat(progress)
        }
        else if score < 10000{
                   userScoreLabel.text = String(score)
                          levelLable.text = "Level 3"
                          firstRangeLabel.text = "1000"
                          secondRangeLabel.text = "10000"
                              let progress = (Float(score) - 1000) / 9000.0
                          progressBar.progress = progress
                              leadingScoreBarConstraint.constant = progressBarLength * CGFloat(progress)
               }
        
    }
    
    @IBAction func newBtnClicked(_ sender: Any) {
        selectNew()
               scrollToItemAtIndexPath(index: 0)
    }
    
    @IBAction func topBtnClicked(_ sender: Any) {
        selectTop()
               scrollToItemAtIndexPath(index: 1)
    }
    
    func selectNew(){
        topBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        newBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
           newBtn.isSelected = true
           topBtn.isSelected = false
           
       }
       
       func selectTop(){
        topBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        newBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
           newBtn.isSelected = false
           topBtn.isSelected = true
           
           
       }
    
    func scrollToItemAtIndexPath(index: Int){
                let indexPath = IndexPath(item: index, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
      
      func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           return 2
       }
       
       func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
           if indexPath.row == 0{
               if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCell", for: indexPath) as? CollectionViewCellUserNew{
                  cell.myUserController = self
                  cell.updateNew()
                return cell
               }
               
           }else if indexPath.row == 1{
               if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topCell", for: indexPath) as? CollectionViewCellUserTop{
                  cell.myUserController = self
                  cell.updateTop()
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
              selectNew()
           }else if index == 1{
               selectTop()
           }
           
       }
      
      func scrollViewDidScroll(_ scrollView: UIScrollView) {
          bottomBarLeadingConstraint.constant = scrollView.contentOffset.x / 2
      }
    
    
      
      //resets all arrays haveing to do with new user likes/dislikes
      func resetVars(){
          myChannelsMap=[:]
          myNewLikesDislikesMap=[:]
     
      }
   
    @IBAction func settingsBtnClicked(_ sender: Any) {
       
        settingsMenuLauncher.makeViewFade()
        settingsMenuLauncher.addMenuFromSide()
    }
    
    func showNextControllerSettings(menuItem:MenuItem){
        if menuItem.name == "Edit Profile"{
            changeToEditMode()
        }else if menuItem.name == "Privacy Policy"{
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "PrivacyController") as! myUIViewController
            navigationController?.pushViewController(nextViewController, animated: true)
        }else if menuItem.name == "Report a Problem"{
            let email = "quipitinc@gmail.com"
            if let url = URL(string: "mailto:\(email)") {
                 UIApplication.shared.open(url)
            }
        }else if menuItem.name == "Contact Us"{
            let email = "quipitinc@gmail.com"
                       if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                       }
        }
        
    }
    
    func showNextControllerEllipses(menuItem: MenuItem, quip: Quip?){
        if menuItem.name == "View Event Feed"{
            
        }else if menuItem.name == "Report Quip"{
            displayMsgBox()
        }else if menuItem.name == "Share Quip"{
            if let aquip = quip{
            if let collectionViewCell = collectionView.visibleCells[0] as? CollectionViewCellUser{
                collectionViewCell.generateDynamicLink(aquip: aquip, cell: nil)
            }
            }
        }else if menuItem.name == "Delete Quip"{
            if let aQuipID = quip?.quipID{
                           FirestoreService.sharedInstance.deleteQuip(quipID: aQuipID){
                               self.collectionView.reloadData()
                           }
                       }
        }
        
    }
    
    func displayMsgBox(){
    let title = "Report Successful"
    let message = "The user has been reported. If you want to give us more details on this incident please email us at quipitinc@gmail.com"
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
          switch action.style{
          case .default:
                print("default")

          case .cancel:
                print("cancel")

          case .destructive:
                print("destructive")


          @unknown default:
            print("unknown action")
        }}))
    self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func editBtnClicked(_ sender: Any) {
        if nameTextView.isEditable {
            changeToNormalMode()
            saveChanges()
        }else{
            changeToEditMode()
        }
    }
    
    func changeToEditMode(){
      //  bioTextView.removeConstraint(bioHeightConstraint!)
        bioTextView.isHidden = false
        self.view.setNeedsLayout()
        nameTextView.isEditable = true
        nameTextView.isSelectable = true
        bioTextView.isSelectable = true
        bioTextView.isEditable = true
        nameTextView.backgroundColor = .white
        bioTextView.backgroundColor = .white
        self.navigationItem.leftBarButtonItem?.title = "Done"
        self.navigationItem.title = "EDIT PROFILE"
        self.navigationItem.rightBarButtonItem?.isEnabled = false
       
    }
   
    func changeToNormalMode(){
        nameTextView.isEditable = false
        nameTextView.isSelectable = false
        bioTextView.isSelectable = false
        bioTextView.isEditable = false
        if #available(iOS 13.0, *) {
            nameTextView.backgroundColor = .secondarySystemBackground
            bioTextView.backgroundColor = .secondarySystemBackground
        } else {
            // Fallback on earlier versions
            nameTextView.backgroundColor = self.view.backgroundColor
            bioTextView.backgroundColor = self.view.backgroundColor
        }
        if bioTextView.text == bioPlaceholderText{
      //      bioTextView.addConstraint(bioHeightConstraint!)
            bioTextView.isHidden = true
        }else{
      //     bioTextView.removeConstraint(bioHeightConstraint!)
            bioTextView.isHidden = false
            
        }
        
        
        self.navigationItem.leftBarButtonItem?.title = "Edit"
        self.navigationItem.title = "PROFILE"
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    func saveChanges(){
        if let auid = uid{
            FirestoreService.sharedInstance.saveUserProfile(uid: auid, name: nameTextView.text, bio: bioTextView.text)
        }
        
    }
    
   
    
   
       
    func updateVotesFirebase(diff:Int, quipID:String, myQuip:Quip){
        //increment value has to be double or long or it wont work properly
        let myDiff = Double(diff)
        var myVotes:[String:Any] = [:]
        if let aChannelKey =  myQuip.channelKey{
           myVotes["A/\(aChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
        if let aParentChannelKey = myQuip.parentKey{
              myVotes["A/\(aParentChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
        if let aUID = uid {
           myVotes["M/\(aUID)/q/\(quipID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
            myVotes["M/\(aUID)/s"] = ServerValue.increment(NSNumber(value: myDiff))
           }
        updateFirestoreLikesDislikes()
               FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
                 resetVars()
       }
       
    func updateFirestoreLikesDislikes(){
        if myNewLikesDislikesMap.count>0{
           if let aUID = uid {
               if let bUId = uid{
                
                FirestoreService.sharedInstance.updateLikesDislikes(myNewLikesDislikesMap: myNewLikesDislikesMap, aChannelOrUserKey: bUId, myMap: myChannelsMap, aUID: aUID, parentChannelKey: nil, parentChannelMap: myParentQuipsMap)
                
            }
        }
       }
    }
  
    func checkNewQuips(myQuipID:String, isUp:Bool){
              var i = 0
        let indexPath = IndexPath(item: 0, section: 0)
               if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellUserNew{
                for aQuip in cell.newUserQuips{
                
                 if aQuip?.quipID == myQuipID{
                     if let myQuip = aQuip{
                         updateOtherQuipList(index: 0, myQuip: myQuip, i: i, isUp: isUp)

                     }
                    
                 }
                i += 1
             }
        
        }
         }
    
    func checkHotQuips(myQuipID:String, isUp:Bool){
           var i = 0
        let indexPath = IndexPath(item: 1, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellUserTop{
            for aQuip in cell.topUserQuips{
               
               if aQuip?.quipID == myQuipID{
                   if let myQuip = aQuip{
                       updateOtherQuipList(index: 1, myQuip: myQuip, i: i, isUp: isUp)

                   }
                   
               }
               i += 1
           }
        }
       }
    
    func updateOtherQuipList(index:Int, myQuip:Quip, i:Int, isUp:Bool){
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellUserNew{
            let indexPath2 = IndexPath(item: i, section: 0)
            if let myCell = cell.userQuipsTable.cellForRow(at: indexPath2) as? QuipCells{
            if isUp{
                cell.upPressedForOtherCell(aQuip: myQuip, cell: myCell)
            }else{
                cell.downPressedForOtherCell(aQuip: myQuip, cell: myCell)
            }
            }
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellUserTop{
        let indexPath2 = IndexPath(item: i, section: 0)
        if let myCell = cell.userQuipsTable.cellForRow(at: indexPath2) as? QuipCells{
                   if isUp{
                       cell.upPressedForOtherCell(aQuip: myQuip, cell: myCell)
                   }else{
                       cell.downPressedForOtherCell(aQuip: myQuip, cell: myCell)
                   }
                   }
    }
    }

   
     
    
     
  
    
    // MARK: - Navigation
    
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let quipVC = segue.destination as? ViewControllerQuip{
               if newBtn.isSelected{
                   let indexPath = IndexPath(item: 0, section: 0)
                   if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellUserNew {
                   if let index = cell.userQuipsTable.indexPathForSelectedRow?.row {
                       passedQuip = cell.newUserQuips[index]
                    if passedQuip?.isReply ?? false{
                        quipVC.passedReply = passedQuip
                        
                    }
                   }
                if passedQuip?.isReply ?? false {
                               if let aquipId = passedQuip?.quipParent{
                               passedQuip = nil
                                   quipVC.loadParentQuip(aquipId: aquipId)
                               }
                    quipVC.currentTime = cell.currentTime
              //       let myCell = cell.userQuipsTable.cellForRow(at: cell.userQuipsTable.indexPathForSelectedRow!) as? QuipCells
                    //   quipVC.passedQuipCell = myCell
                     cell.userQuipsTable.deselectRow(at: cell.userQuipsTable.indexPathForSelectedRow!, animated: false)
                }else{
                   let myCell = cell.userQuipsTable.cellForRow(at: cell.userQuipsTable.indexPathForSelectedRow!) as? QuipCells
                              quipVC.quipScore = myCell?.score.text
                              if myCell?.upButton.isSelected == true {
                                  quipVC.quipLikeStatus = true
                              }
                              else if myCell?.downButton.isSelected == true{
                                  quipVC.quipLikeStatus = false
                              }
                   quipVC.currentTime = cell.currentTime
              //     quipVC.passedQuipCell = myCell
                   cell.userQuipsTable.deselectRow(at: cell.userQuipsTable.indexPathForSelectedRow!, animated: false)
                   }
                }
                
                   quipVC.parentIsNew = true
               }else if topBtn.isSelected{
                   let indexPath = IndexPath(item: 1, section: 0)
                   if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellUserTop{
                   if let index = cell.userQuipsTable.indexPathForSelectedRow?.row {
                       passedQuip = cell.topUserQuips[index]
                    if passedQuip?.isReply ?? false{
                        quipVC.passedReply = passedQuip
                        
                    }
                   }
                    if passedQuip?.isReply ?? false {
                        if let aquipId = passedQuip?.quipParent{
                            passedQuip = nil
                           
                            quipVC.loadParentQuip(aquipId: aquipId)
                                                  }
                                       quipVC.currentTime = cell.currentTime
              //           let myCell = cell.userQuipsTable.cellForRow(at: cell.userQuipsTable.indexPathForSelectedRow!) as? QuipCells
                   //quipVC.passedQuipCell = myCell
                         cell.userQuipsTable.deselectRow(at: cell.userQuipsTable.indexPathForSelectedRow!, animated: false)
                                   }else{
                   let myCell = cell.userQuipsTable.cellForRow(at: cell.userQuipsTable.indexPathForSelectedRow!) as? QuipCells
                                         quipVC.quipScore = myCell?.score.text
                                         if myCell?.upButton.isSelected == true {
                                             quipVC.quipLikeStatus = true
                                         }
                                         else if myCell?.downButton.isSelected == true{
                                             quipVC.quipLikeStatus = false
                                         }
                    quipVC.currentTime = cell.currentTime
                 //  quipVC.passedQuipCell = myCell
               cell.userQuipsTable.deselectRow(at: cell.userQuipsTable.indexPathForSelectedRow!, animated: false)
                   }
                }
                   quipVC.parentIsNew = false

               }
           
           
            
                       
            quipVC.myQuip = self.passedQuip
         
            quipVC.uid=self.uid
            
            
            quipVC.parentViewUser = self
            
            
        }
        
    }
    

}
