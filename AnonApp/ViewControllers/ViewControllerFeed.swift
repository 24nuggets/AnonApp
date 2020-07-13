//
//  ViewControllerFeed.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/17/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK

class ViewControllerFeed: myUIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    
   
    
    
    

    weak var myChannel:Channel?
    private weak var writeQuip:ViewControllerWriteQuip?
    var uid:String?
    private weak var passedQuip:Quip?
    private weak var quipVC:ViewControllerQuip?
    var isOpen:Bool?
  
   
           var myLikesDislikesMap:[String:Int] = [:]
           var myNewLikesDislikesMap:[String:Int] = [:]
          var myUserMap:[String:String] = [:]
    
    @IBOutlet weak var writeQuipBtn: UIBarButtonItem!
    
    @IBOutlet weak var bottomBarLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBtn: UIButton!
    
    @IBOutlet weak var newBtn: UIButton!
    
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
      //  self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        
        //gets rid of border between the two navigation bars on top
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
     
        if isOpen ?? false{
            self.navigationItem.rightBarButtonItem = self.writeQuipBtn
        }else{
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.title =  myChannel?.channelName
        
        //notification when app will enter foreground
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
         
        bottomBar.layer.cornerRadius = 10
        bottomBar.clipsToBounds = true
       
        addGesture()
        collectionView.delegate = self
        collectionView.dataSource = self
       setUpButtons()
       selectNew()
    }
    
    func setUpButtons(){
             newBtn.setTitleColor(.darkText, for: .selected  )
             topBtn.setTitleColor(.darkText, for: .selected  )
             
             if #available(iOS 13.0, *) {
                 newBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
                 topBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
                 
             } else {
                 // Fallback on earlier versions
             }
             
         }
  
    
    override func viewDidAppear(_ animated: Bool){
              super.viewDidAppear(animated)
        
      
        
       
        
        

           
              
    }
    
    //updates firestore and firebase with likes when view is dismissed
    override func viewWillDisappear(_ animated: Bool){
           super.viewWillDisappear(animated)

         
    }
    
    //resets all arrays haveing to do with new user likes/dislikes
    
    
    @objc func appWillEnterForeground() {
          //checks if this view controller is the first one visible
          
        
       }
    
    //deinitializer for notification center
    deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
  
    
    // MARK: - putVotesToDatabase
      
      func updateVotesFirebase(diff:Int, quipID:String, aUID:String){
          //increment value has to be double or long or it wont work properly
          let myDiff2 = Double(diff)
          let myDiff = NSNumber(value: myDiff2)
        var myVotes:[String:Any] = [:]
         if let aChannelKey = myChannel?.key {
              myVotes["A/\(aChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(myDiff)
          }
          if let aParentChannelKey = myChannel?.parentKey {
              myVotes["A/\(aParentChannelKey)/Q/\(quipID)/s"] = ServerValue.increment(myDiff)
          }
         
          myVotes["M/\(aUID)/q/\(quipID)/s"] = ServerValue.increment(myDiff)
          
              updateFirestoreLikesDislikes()
               FirebaseService.sharedInstance.updateChildValues(myUpdates: myVotes)
              resetVars()
          
      }
      
      func updateFirestoreLikesDislikes(){
          if myNewLikesDislikesMap.count>0{
              if let aUID = uid {
                  if let aChannelKey = myChannel?.key{
                      FirestoreService.sharedInstance.updateLikesDislikes(myNewLikesDislikesMap: myNewLikesDislikesMap, aChannelOrUserKey: aChannelKey, myMap: myUserMap, aUID: aUID, parentChannelKey: myChannel?.parentKey, parentChannelMap: nil)
                      
                  myNewLikesDislikesMap = [:]
                  }
              }
          }
      }
    
    func resetVars(){
           myUserMap=[:]
           myNewLikesDislikesMap=[:]
       }
    
  
    @IBAction func newClicked(_ sender: Any) {
        selectNew()
        scrollToItemAtIndexPath(index: 0)
    }
    
    
    @IBAction func topClicked(_ sender: Any) {
        selectTop()
        scrollToItemAtIndexPath(index: 1)
    }
    
    func selectNew(){
        newBtn.isSelected = true
        topBtn.isSelected = false
        
    }
    
    func selectTop(){
        newBtn.isSelected = false
        topBtn.isSelected = true
        
        
    }
    
    func checkNewQuips(myQuipID:String, isUp:Bool){
              var i = 0
        let indexPath = IndexPath(item: 0, section: 0)
               if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent{
                for aQuip in cell.newQuips{
                
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
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedTop{
            for aQuip in cell.hotQuips{
               
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
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent{
            let indexPath2 = IndexPath(item: i, section: 0)
            if let myCell = cell.feedTable.cellForRow(at: indexPath2) as? QuipCells{
            if isUp{
                cell.upPressedForOtherCell(aQuip: myQuip, cell: myCell)
            }else{
                cell.downPressedForOtherCell(aQuip: myQuip, cell: myCell)
            }
            }
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedTop{
        let indexPath2 = IndexPath(item: i, section: 0)
        if let myCell = cell.feedTable.cellForRow(at: indexPath2) as? QuipCells{
                   if isUp{
                       cell.upPressedForOtherCell(aQuip: myQuip, cell: myCell)
                   }else{
                       cell.downPressedForOtherCell(aQuip: myQuip, cell: myCell)
                   }
                   }
    }
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
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCell", for: indexPath) as? CollectionViewCellFeedRecent{
                cell.myFeedController = self
                cell.updateNew(){
                    
                   
                }
              return cell
             }
             
         }else if indexPath.row == 1{
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topCell", for: indexPath) as? CollectionViewCellFeedTop{
                cell.myFeedController = self
                cell.updateHot(){
                    
                }
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
  
    func showNextController(menuItem:MenuItem, quip:Quip){
        if menuItem.name == "View User's Profile"{
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ViewControllerUser") as! ViewControllerUser
            nextViewController.uid = uid
            nextViewController.uidProfile = quip.user
            navigationController?.pushViewController(nextViewController, animated: true)
        }else if menuItem.name == "Report Quip"{
            displayMsgBox()
        }else if menuItem.name == "Share Quip"{
            
        }else if menuItem.name == "Delete Quip"{
            if let aQuipID = quip.quipID{
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
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let quipVC = segue.destination as? ViewControllerQuip{
        if newBtn.isSelected{
            let indexPath = IndexPath(item: 0, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedRecent {
            if let index = cell.feedTable.indexPathForSelectedRow?.row {
                passedQuip = cell.newQuips[index]
            }
            let myCell = cell.feedTable.cellForRow(at: cell.feedTable.indexPathForSelectedRow!) as? QuipCells
                       quipVC.quipScore = myCell?.score.text
                       if myCell?.upButton.isSelected == true {
                           quipVC.quipLikeStatus = true
                       }
                       else if myCell?.downButton.isSelected == true{
                           quipVC.quipLikeStatus = false
                       }
            quipVC.currentTime = cell.currentTime
            quipVC.passedQuipCell = myCell
            cell.feedTable.deselectRow(at: cell.feedTable.indexPathForSelectedRow!, animated: false)
            }
            quipVC.parentIsNew = true
        }else if topBtn.isSelected{
            let indexPath = IndexPath(item: 1, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellFeedTop{
            if let index = cell.feedTable.indexPathForSelectedRow?.row {
                passedQuip = cell.hotQuips[index]
            }
            let myCell = cell.feedTable.cellForRow(at: cell.feedTable.indexPathForSelectedRow!) as? QuipCells
                                  quipVC.quipScore = myCell?.score.text
                                  if myCell?.upButton.isSelected == true {
                                      quipVC.quipLikeStatus = true
                                  }
                                  else if myCell?.downButton.isSelected == true{
                                      quipVC.quipLikeStatus = false
                                  }
             quipVC.currentTime = cell.currentTime
            quipVC.passedQuipCell = myCell
            cell.feedTable.deselectRow(at: cell.feedTable.indexPathForSelectedRow!, animated: false)
            }
            quipVC.parentIsNew = false

        }
        
            
            
           
            quipVC.myQuip = self.passedQuip
            
            quipVC.uid=self.uid
            
            quipVC.myChannel=self.myChannel
            
           
            quipVC.parentViewFeed = self
            
           
            
        }else if let writeQuip = segue.destination as? ViewControllerWriteQuip{
        
        
        writeQuip.myChannel = self.myChannel
            writeQuip.feedVC = self
        writeQuip.uid=self.uid
        //select new quips tab before leaving
            
            
            
        }
    }
    
   

}


