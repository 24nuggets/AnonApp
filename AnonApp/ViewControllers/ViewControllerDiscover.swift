//
//  ViewControllerDiscover.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/11/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit


class ViewControllerDiscover: myUIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
  
    
    //IBOutlets
   
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var upcomingBtn: UIButton!
    @IBOutlet weak var activeBtn: UIButton!
    @IBOutlet weak var pastBtn: UIButton!
    @IBOutlet weak var catName: UILabel!
    
    @IBOutlet weak var bottomBarLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var navBar: UINavigationItem!
    
    
    //Declare Variables
   
   
    
    var uid:String?
    private var seenUpcoming:Bool = false
    private var seenActive:Bool = false
    private weak var feedVC:ViewControllerFeed?
    private weak var passedChannel:Channel?
  private var lastContentOffset: CGFloat = 0
    
    weak var myCategory:Category?
    var bigCategory:String?
    private var isfav:Bool?
    private var myFavs:[Category] = []
    private var isFavourited:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       addGesture()
        getIfUserFavCategory()
        //notification when user presses home button, detachlisteners is called
       // NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.detachlisteners), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        //notification for when user reopens app after being in the background, appWillEnterForeground is called
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerDiscover.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification
        , object: nil)
        
        
        catName.text = myCategory?.categoryName
        
        
        activeBtn.isSelected=true
       
       
        setUpButtons()
      
        
       
       
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Do any additional setup after loading the view.
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
       
    }
   
    
    //deinitializer for notification center
    deinit {
           NotificationCenter.default.removeObserver(self)
       }
    
    func setUpButtons(){
           pastBtn.setTitleColor(.black, for: .selected  )
           activeBtn.setTitleColor(.black, for: .selected  )
           upcomingBtn.setTitleColor(.black, for: .selected  )
           if #available(iOS 13.0, *) {
               pastBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
               activeBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
               upcomingBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .bold), forImageIn: .selected)
           } else {
               // Fallback on earlier versions
           }
           
       }
   
    
 
    
    // MARK: - NotificationCenter Functions
       
    //called when app goes from background to active
    @objc func appWillEnterForeground() {
       //checks if this view controller is the first one visible
        if self.viewIfLoaded?.window != nil {
            // viewController is visible
            
            
        }
    }
    
   
   /*
   func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
             navigationController?.popViewController(animated: true)
         }
         return false
     }
  */
    
 
    
     // MARK: - Database Functions
    
    func getIfUserFavCategory(){
        self.myFavs = []
        if let aUid = uid{
            FirestoreService.sharedInstance.getUserFavCategories(aUid: aUid) {[weak self] (myFavs) in
                self?.myFavs = myFavs
                self?.updateFavButton()
            }
                  
                 
                      
        }
              
    }
    
    func updateRighBarButton(isFavourite : Bool){
        let btnFavourite = UIButton(frame: CGRect(x: 0,y: 0,width: 40,height: 40))
        btnFavourite.addTarget(self, action: #selector(self.btnFavouriteDidTap), for: .touchUpInside)


        if isFavourite {
            if #available(iOS 13.0, *) {
                btnFavourite.setImage(UIImage(systemName: "star.fill"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            btnFavourite.tintColor = .orange
        }else{
            if #available(iOS 13.0, *) {
                btnFavourite.setImage(UIImage(systemName: "star"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            btnFavourite.tintColor = .black
        }
        let rightButton = UIBarButtonItem(customView: btnFavourite)
        navBar.setRightBarButtonItems([rightButton], animated: true)
        
    }

    
    func updateFavButton(){
        for aCat in myFavs{
            if aCat.categoryName == myCategory?.categoryName{
                      
                           isFavourited = true
                           updateRighBarButton(isFavourite: isFavourited)
                           
                           return
                       
                   }
        }
       
        updateRighBarButton(isFavourite: isFavourited)
        
    }
    
   
   
   
    
  
    
    
 
  
    
     // MARK: - IBAction Functions
    
    @objc func btnFavouriteDidTap(){
        isFavourited = !isFavourited;
           if self.isFavourited {
               favourite();
           }else{
               unfavourite();
           }
        updateRighBarButton(isFavourite: isFavourited);
        
    }
    
    func favourite(){
        if let aUid = uid{
            if let myCatName = myCategory?.categoryName{
                FirestoreService.sharedInstance.favoriteCatagory(aUid: aUid, myCatName: myCatName, bigCategory: bigCategory ?? "None")
            }
        }
    }
    func unfavourite(){
        if let aUid = uid{
            if let myCatName = myCategory?.categoryName{
                if let bigCat = bigCategory{
                FirestoreService.sharedInstance.unfavoriteCatagory(aUid: aUid, myCatName: myCatName, bigCategory: bigCat)
                }
                   }
               }
        
    }
    
   
//event when active button is clicked
    @IBAction func activeClicked(_ sender: UIButton) {
        //change buttons state
        selectLive()
        
       scrollToItemAtIndexPath(index: 0)
       
        
        
        
        
        
    }
    //event when past is clicked
    @IBAction func pastClicked(_ sender: UIButton) {
       selectPast()
        
        scrollToItemAtIndexPath(index: 1)
      
    }
    
    //event when upcoming is clicked
    @IBAction func upcomingClicked(_ sender: UIButton) {
        //change state of buttons
        selectUpcoming()
       
        scrollToItemAtIndexPath(index: 2)
       
      
    
     

    }
    func scrollToItemAtIndexPath(index: Int){
           let indexPath = IndexPath(item: index, section: 0)
           collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
       }
    
    func selectLive(){
        upcomingBtn.isSelected = false
        activeBtn.isSelected = true
        pastBtn.isSelected = false
    }
    func selectPast(){
        upcomingBtn.isSelected = false
               activeBtn.isSelected = false
               pastBtn.isSelected = true
    }
    func selectUpcoming(){
        upcomingBtn.isSelected = true
        activeBtn.isSelected = false
        pastBtn.isSelected = false
    }
    
   
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return 3
     }
     
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         if indexPath.row == 0{
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "liveCell", for: indexPath) as? CollectionViewCellChannelLive{
                cell.bigCategory = bigCategory
                cell.categoryName = myCategory?.categoryName
                cell.getActive()
              return cell
             }
             
         }else if indexPath.row == 1{
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "pastCell", for: indexPath) as? CollectionViewCellChannelPast{
             cell.bigCategory = bigCategory
                            cell.categoryName = myCategory?.categoryName
                cell.getPast()
              return cell
             }
             
         }else if indexPath.row == 2{
             if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "upcomingCell", for: indexPath) as? CollectionViewCellChannelUpcoming{
                    cell.bigCategory = bigCategory
                    cell.categoryName = myCategory?.categoryName
                cell.getUpcoming()
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
             selectPast()
         }else if index == 2{
             selectUpcoming()
         }
         
     }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        bottomBarLeadingConstraint.constant = scrollView.contentOffset.x / 3
        
        if (self.lastContentOffset > scrollView.contentOffset.x) {
                       // move left
            if activeBtn.isSelected{
                
            }
                   }
                 

                   // update the new position acquired
                   self.lastContentOffset = scrollView.contentOffset.x
    }
    
  
    
   

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
   
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if activeBtn.isSelected {
        let indexPath = IndexPath(item: 0, section: 0)
        let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellChannelLive
        if let index = cell?.channelTable.indexPathForSelectedRow?.row{
                               
            passedChannel = cell?.activeChannels[index]
            let myIndexPath = IndexPath(item: index, section: 0)
                                        cell?.channelTable.deselectRow(at: myIndexPath, animated: true)
            }
            
        }
        else if pastBtn.isSelected{
             let indexPath = IndexPath(item: 1, section: 0)
                    let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCellChannelPast
                    if let index = cell?.channelTable.indexPathForSelectedRow?.row{
                                           
                        passedChannel = cell?.pastChannels[index]
                        let myIndexPath = IndexPath(item: index, section: 0)
                                                    cell?.channelTable.deselectRow(at: myIndexPath, animated: true)
                        }
             
        }
            if let feedVC = segue.destination as? ViewControllerFeed{
            feedVC.myChannel = passedChannel
           
            feedVC.uid=self.uid
            }
            
    }
      
    
  
    
    

}//end of class
