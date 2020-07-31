//
//  CollectionViewCellUser.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK

class CollectionViewCellUser: UICollectionViewCell, MyCellDelegate {
    
    var myUserController: ViewControllerUser?
    var currentTime:Double?
    
    lazy var MenuLauncher:ellipsesMenuUser = {
               let launcher = ellipsesMenuUser()
            launcher.userController = myUserController
                return launcher
           }()
    
     let shareText = "Check out this crack on pnut!"
    
    func btnRepliesTapped(cell: QuipCells) {
        
    }
    
    func btnSharedTapped(cell: QuipCells) {
                 
             }
       
       func btnEllipsesTapped(cell: QuipCells) {
           MenuLauncher.makeViewFade()
           MenuLauncher.addMenuFromBottom()
          }
       
       func btnUpTapped(cell: QuipCells) {
            
          }
          
          func btnDownTapped(cell: QuipCells) {
                  
              
          }
    func generateDynamicLink(aquip:Quip, cell: QuipCells?){
        var components = URLComponents()
        var eventparentIDQueryItem2:URLQueryItem?
        components.scheme = "https"
        components.host = "anonapp.page.link"
        components.path = "/quips"
         let eventIDQueryItem3 = URLQueryItem(name: "eventid", value: aquip.channelKey)
        if let parentEventKey = aquip.parentKey{
            eventparentIDQueryItem2 = URLQueryItem(name: "parenteventid", value: parentEventKey)
        }
        
        
        let eventNameQueryItem1 = URLQueryItem(name: "eventname", value: aquip.channel?.encodeUrl())
        let quipIDQueryItem4 = URLQueryItem(name: "quipid", value: aquip.quipID)
        if let parentqueryitem = eventparentIDQueryItem2{
        components.queryItems = [eventNameQueryItem1,parentqueryitem, eventIDQueryItem3,quipIDQueryItem4]
        }else{
            components.queryItems = [eventNameQueryItem1, eventIDQueryItem3,quipIDQueryItem4]
        }
        guard let linkparam = components.url else {return}
        print(linkparam)
        let dynamicLinksDomainURIPrefix = "https://anonapp.page.link"
        guard let sharelink = DynamicLinkComponents.init(link: linkparam, domainURIPrefix: dynamicLinksDomainURIPrefix) else {return}
        if let bundleId = Bundle.main.bundleIdentifier {
            sharelink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleId)
        }
        //change to app store id
        sharelink.iOSParameters?.appStoreID = appStoreID
        sharelink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        sharelink.socialMetaTagParameters?.imageURL = logoURL
        sharelink.socialMetaTagParameters?.title = aquip.quipText
        sharelink.socialMetaTagParameters?.descriptionText = aquip.channel
        if let myImage = aquip.imageRef {
             FirebaseStorageService.sharedInstance.getDownloadURL(imageRef: myImage, completion: {[weak self] (url) in
                print(url)
                
                sharelink.socialMetaTagParameters?.imageURL = url
                guard sharelink.url != nil else { return }
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
                                
                               self?.showShareViewController(url: url)
                           }
            })
        }else if let myGif = aquip.gifID {
                GiphyCore.shared.gifByID(myGif) { (response, error) in
                    if let media = response?.data {
                        if let gifURL = media.url(rendition: .fixedWidthStill, fileType: .gif){
                        print(gifURL)
                        sharelink.socialMetaTagParameters?.imageURL = URL(string: gifURL)
                        }
                    }
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
            }
            
        }
        else {
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
        
        
            
        }
        Analytics.logEvent(AnalyticsEventShare, parameters:
                  [AnalyticsParameterItemID:"id- \(aquip.quipID ?? "Other")",
                      AnalyticsParameterItemName: aquip.quipText ?? "None",
                      AnalyticsParameterContentType: "quip"])
    }
    
    func showShareViewController(url:URL){
        let myactivity1 = shareText
        let myactivity2 = url
                             
                        
                               // set up activity view controller
        let firstactivity = [myactivity1, myactivity2] as [Any]
                        let activityViewController = UIActivityViewController(activityItems: firstactivity, applicationActivities: nil)
                              activityViewController.popoverPresentationController?.sourceView = myUserController?.view // so that iPads won't crash

                               // exclude some activity types from the list (optional)
                        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]

                               // present the view controller
                               myUserController?.present(activityViewController, animated: true, completion: nil)
    }
       
       func downPressedForOtherCell(aQuip:Quip, cell:QuipCells){
             if cell.upButton.isSelected {
                             if let aQuipScore = aQuip.quipScore{
                              cell.upToDown2(quipScore: aQuipScore, quip: aQuip)
                 }
             }else if cell.downButton.isSelected {
                 if let aQuipScore = aQuip.quipScore{
                  cell.downToNone2(quipScore: aQuipScore, quip: aQuip)
                                 }
             }else{
               if let aQuipScore = aQuip.quipScore{
                  cell.noneToDown2(quipScore: aQuipScore, quip:aQuip)
                     }
             }
                                 
         }
         
         func upPressedForOtherCell(aQuip:Quip, cell:QuipCells){
             if cell.upButton.isSelected {
                          if let aQuipScore = aQuip.quipScore{
                              cell.upToNone2(quipScore: aQuipScore, quip:aQuip)
                 }
             } else if cell.downButton.isSelected {
                              if let aQuipScore = aQuip.quipScore{
                                  cell.downToUp2(quipScore: aQuipScore, quip:aQuip)
                 }
             }else{
             if let aQuipScore = aQuip.quipScore{
                 cell.noneToUp2(quipScore: aQuipScore, quip:aQuip)
                 }
             }
         }
       
       // MARK: - Like/Dislike Logic
          
          func downButtonPressed(aQuip:Quip, cell:QuipCells){
              if cell.upButton.isSelected {
                     if let aQuipScore = aQuip.quipScore{
                      let diff = cell.upToDown(quipScore: aQuipScore, quip: aQuip)
                          if let aID = aQuip.quipID{
                              
                              myUserController?.myNewLikesDislikesMap[aID] = -1
                              myUserController?.myLikesDislikesMap[aID] = -1
                          
                           if let aChannelKey = aQuip.channelKey{
                               myUserController?.myChannelsMap[aID] = aChannelKey
                               if let aParent = aQuip.parentKey{
                                   myUserController?.myParentChannelsMap[aID] = aParent
                               }
                           }else if let aParentQuip = aQuip.quipParent{
                               myUserController?.myParentQuipsMap[aID]=aParentQuip
                           }
                            myUserController?.updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                          }
                  }
              }
              else if cell.downButton.isSelected {
                     if let aQuipScore = aQuip.quipScore{
                      let diff = cell.downToNone(quipScore: aQuipScore, quip: aQuip)
                          if let aID = aQuip.quipID{
                              
                              myUserController?.myNewLikesDislikesMap[aID]=0
                              myUserController?.myLikesDislikesMap[aID]=0
                             if let aChannelKey = aQuip.channelKey{
                                 myUserController?.myChannelsMap[aID] = aChannelKey
                                 if let aParent = aQuip.parentKey{
                                     myUserController?.myParentChannelsMap[aID] = aParent
                                 }
                             }else if let aParentQuip = aQuip.quipParent{
                                 myUserController?.myParentQuipsMap[aID]=aParentQuip
                             }
                           myUserController?.updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                          }
                      
                  }
              }
              else{
                   if let aQuipScore = aQuip.quipScore{
                      let diff = cell.noneToDown(quipScore: aQuipScore, quip:aQuip)
                      if let aID = aQuip.quipID{
                          
                          myUserController?.myNewLikesDislikesMap[aID] = -1
                          myUserController?.myLikesDislikesMap[aID] = -1
                        if let aChannelKey = aQuip.channelKey{
                             myUserController?.myChannelsMap[aID] = aChannelKey
                             if let aParent = aQuip.parentKey{
                                 myUserController?.myParentChannelsMap[aID] = aParent
                             }
                         }else if let aParentQuip = aQuip.quipParent{
                             myUserController?.myParentQuipsMap[aID]=aParentQuip
                         }
                       myUserController?.updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                      }
                  }
                  
              }
              
          }
          func upButtonPressed(aQuip:Quip, cell:QuipCells){
              if cell.upButton.isSelected {
                  if let aQuipScore = aQuip.quipScore{
                      let diff = cell.upToNone(quipScore: aQuipScore, quip:aQuip)
                      if let aID = aQuip.quipID{
                          
                          myUserController?.myNewLikesDislikesMap[aID]=0
                          myUserController?.myLikesDislikesMap[aID]=0
                         if let aChannelKey = aQuip.channelKey{
                              myUserController?.myChannelsMap[aID] = aChannelKey
                              if let aParent = aQuip.parentKey{
                                  myUserController?.myParentChannelsMap[aID] = aParent
                              }
                          }else if let aParentQuip = aQuip.quipParent{
                              myUserController?.myParentQuipsMap[aID]=aParentQuip
                          }
                       myUserController?.updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                          }
                          
                  }
                   }
                   else if cell.downButton.isSelected {
                      if let aQuipScore = aQuip.quipScore{
                          let diff = cell.downToUp(quipScore: aQuipScore, quip:aQuip)
                              if let aID = aQuip.quipID{
                                  
                                  myUserController?.myNewLikesDislikesMap[aID] = 1
                                  myUserController?.myLikesDislikesMap[aID] = 1
                                 if let aChannelKey = aQuip.channelKey{
                                     myUserController?.myChannelsMap[aID] = aChannelKey
                                     if let aParent = aQuip.parentKey{
                                         myUserController?.myParentChannelsMap[aID] = aParent
                                     }
                                 }else if let aParentQuip = aQuip.quipParent{
                                     myUserController?.myParentQuipsMap[aID]=aParentQuip
                                 }
                               myUserController?.updateVotesFirebase(diff: diff, quipID: aID,myQuip: aQuip)
                              }
                          }
                      }
                   else{
                      if let aQuipScore = aQuip.quipScore{
                          let diff = cell.noneToUp(quipScore: aQuipScore, quip:aQuip)
                          if let aID = aQuip.quipID{
                              
                              myUserController?.myNewLikesDislikesMap[aID] = 1
                              myUserController?.myLikesDislikesMap[aID] = 1
                              if let aChannelKey = aQuip.channelKey{
                                  myUserController?.myChannelsMap[aID] = aChannelKey
                                  if let aParent = aQuip.parentKey{
                                      myUserController?.myParentChannelsMap[aID] = aParent
                                  }
                              }else if let aParentQuip = aQuip.quipParent{
                                  myUserController?.myParentQuipsMap[aID]=aParentQuip
                              }
                           myUserController?.updateVotesFirebase(diff: diff, quipID: aID, myQuip: aQuip)
                          }
                      }
                   }
              
          }
    
    func getUserLikesDislikesForUser(completion: @escaping ()->()){
          myUserController?.myLikesDislikesMap = [:]
          if let aUID = myUserController?.uidProfile {
              if let bUId = myUserController?.uid{
                FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: bUId, aKey: aUID) {[weak self] (myLikesDislikesMap) in
                      self?.myUserController?.myLikesDislikesMap = myLikesDislikesMap
                      
                      completion()
                  }
                      
              }
          }
      }
    
}


class CollectionViewCellUserNew: CollectionViewCellUser, UITableViewDelegate, UITableViewDataSource{
   
    
    @IBOutlet weak var userQuipsTable: UITableView!
    
    private var refreshControl = UIRefreshControl()
      var newUserQuips:[Quip?]=[]
    private var myScores:[String:Any]=[:]
    private var moreRecentQuips:Bool = false
     private var moreRecentUserQuipsFirebase:Bool = false
    private var cellHeights = [IndexPath: CGFloat]()
    
    override func awakeFromNib() {
         super.awakeFromNib()
         userQuipsTable.delegate = self
         userQuipsTable.dataSource = self
       self.userQuipsTable.rowHeight = UITableView.automaticDimension
       self.userQuipsTable.estimatedRowHeight = 500.0
          refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
          
          userQuipsTable.refreshControl = refreshControl
          
        
      }
    
    override func btnEllipsesTapped(cell: QuipCells) {
          if let indexPath = self.userQuipsTable.indexPath(for: cell){
                                                     
                    if let myQuip = newUserQuips[indexPath.row]{
                        if let myUserController = myUserController{
                                MenuLauncher.setVars(userController: myUserController, myQuip: myQuip)
                        }
                    }
                                                          
                                                      
            }
                     MenuLauncher.makeViewFade()
                     MenuLauncher.addMenuFromBottom()
    }
    
    override func btnUpTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
              if let indexPath = self.userQuipsTable.indexPath(for: cell){
             
                  if let myQuip = newUserQuips[indexPath.row]{
                  upButtonPressed(aQuip: myQuip, cell: cell)
                    if let aQuipID = myQuip.quipID{
                    myUserController?.checkHotQuips(myQuipID: aQuipID, isUp: true)
                    }
                  }
               
            
              }
    }
    
    override func btnDownTapped(cell: QuipCells) {
     //Get the indexpath of cell where button was tapped
            if let indexPath = self.userQuipsTable.indexPath(for: cell){
           
                if let myQuip = newUserQuips[indexPath.row]{
                downButtonPressed(aQuip: myQuip, cell: cell)
                    if let aQuipID = myQuip.quipID{
                                       myUserController?.checkHotQuips(myQuipID: aQuipID, isUp: false)
                                       }
                }
            
            }
            
        
    }
    override func btnSharedTapped(cell: QuipCells) {
        if let indexPath = self.userQuipsTable.indexPath(for: cell){
        
             if let myQuip = newUserQuips[indexPath.row]{
             
                 generateDynamicLink(aquip: myQuip, cell: cell)
             }
         
         }
    }
    
    override func btnRepliesTapped(cell: QuipCells) {
         userQuipsTable.selectRow(at: userQuipsTable.indexPath(for: cell), animated: true, scrollPosition: .none)
    }
      
      @objc func refreshData(){
        myUserController?.getUserScore()
          updateNew()
      }
    
    func updateNew(){
        refreshControl.beginRefreshing()
          self.myScores = [:]
          moreRecentQuips = false
          newUserQuips = []
        
        if let auid = myUserController?.uidProfile{
            getUserLikesDislikesForUser {
              FirebaseService.sharedInstance.getRecentUserQuips(uid: auid) { [weak self](myScores, currentTime, moreRecentUserQuipsFirebase) in
                  
                  self?.myScores = myScores
                  
                  self?.currentTime = currentTime
                  FirestoreService.sharedInstance.getRecentUserQuipsFirestore(uid: auid, myScores: myScores) {[weak self] (newUserQuips, moreRecentQuips) in
                      self?.newUserQuips = newUserQuips
                        self?.userQuipsTable.reloadData()
                        self?.refreshControl.endRefreshing()
                          self?.moreRecentQuips = moreRecentQuips
                          self?.moreRecentUserQuipsFirebase = moreRecentUserQuipsFirebase
                                 }
                             }
                 
              }
              
          }
      }
      
    func loadMoreRecentUserQuips(){
          self.moreRecentQuips = false
          
          if let auid = myUserController?.uidProfile {
              if self.moreRecentUserQuipsFirebase == true{
                  FirebaseService.sharedInstance.getMoreNewScoresUser(aUid: auid) {[weak self] (moreScores, moreRecentUserQuipsFirebase) in
                      if let aself = self{
                      aself.myScores = aself.myScores.merging(moreScores, uniquingKeysWith: { (_, new) -> Any in
                          new
                      })
                        aself.moreRecentUserQuipsFirebase = moreRecentUserQuipsFirebase
                      }
                    if let aScores = self?.myScores{
                    FirestoreService.sharedInstance.loadMoreRecentUserQuips(uid: auid, myScores: aScores) {[weak self] (newUserQuips, moreRecentQuips) in
                                     if let aself = self{
                                     aself.newUserQuips = aself.newUserQuips + newUserQuips
                                     aself.userQuipsTable.reloadData()
                                     aself.moreRecentQuips = moreRecentQuips
                                     }
                                   
                                 }
                    }
                  }
              }
             
          }
          
      }
      
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newUserQuips.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userQuipsTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! QuipCells
           if newUserQuips.count > 0 {
                                          if let myQuip = self.newUserQuips[indexPath.row]{
                                              cell.aQuip = myQuip
                                                  if let myImageRef = myQuip.imageRef  {
                                                      
                                                          cell.addImageViewToTableCell()
                                                          cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.userQuipsTable)
                                                      
                                                                                                                              
                                                  }
                                                                                                                                                                 
                                                  else if let myGifID = myQuip.gifID  {
                                                                                                                           
                                                      cell.addGifViewToTableCell()
                                                      cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.userQuipsTable)
                                                                                                                                                                     
                                                  }
                                                                      
                                                                             
                                              if myQuip.isReply{
                                                  cell.replyButton.isHidden = true
                                                cell.shareButton.isHidden = true
                                                 cell.categoryLabel.text = ""
                                              }else if let aChannel = myQuip.channel{
                                              cell.categoryLabel.text = aChannel
                                          }
                                          
                                          if let dateVal = myQuip.timePosted?.seconds{
                                              let milliTimePost = dateVal * 1000
                                              if let aCurrentTime = self.currentTime{
                                                  cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: aCurrentTime)
                                              }
                                          }
                                          if let aID = myQuip.quipID{
                                              if self.myUserController?.myLikesDislikesMap[aID] == 1{
                                                  cell.upButton.isSelected=true
                                                                                          
                                                  cell.upButton.tintColor = UIColor(hexString: "ffaf46")
                                              }
                                              else if self.myUserController?.myLikesDislikesMap[aID] == -1{
                                                  cell.downButton.isSelected=true
                                                                                         
                                                  cell.downButton.tintColor = UIColor(hexString: "ffaf46")
                                                                                                                                                
                                              }
                                          }
                                                                            
                                                                          
                                      }
                                  }
                                  else{
                                      return cell
                                  }
        cell.downButton.changeButtonWeight()
              cell.upButton.changeButtonWeight()
                      cell.delegate = self
                    return cell
       }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
              let height = scrollView.frame.size.height
              let contentYoffset = scrollView.contentOffset.y
              let distanceFromBottom = scrollView.contentSize.height - contentYoffset
              if distanceFromBottom < height {
                 
                         
                        
                 
                                       if moreRecentQuips{
                                           loadMoreRecentUserQuips()
                                       }
                                  
                      
              }
          }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
          cellHeights[indexPath] = cell.frame.size.height
      }

      func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
          return cellHeights[indexPath] ?? UITableView.automaticDimension
      }
       
}

class CollectionViewCellUserTop: CollectionViewCellUser, UITableViewDelegate, UITableViewDataSource{
  
    
    @IBOutlet weak var userQuipsTable: UITableView!
    
    private var refreshControl = UIRefreshControl()
    var topUserQuips:[Quip?]=[]
    private var moreTopUserQuipsFirebase:Bool = false
    private var myHotIDs:[String] = []
    private var cellHeights = [IndexPath: CGFloat]()
    
    override func awakeFromNib() {
         super.awakeFromNib()
         userQuipsTable.delegate = self
         userQuipsTable.dataSource = self
       self.userQuipsTable.rowHeight = UITableView.automaticDimension
       self.userQuipsTable.estimatedRowHeight = 500.0
          refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
          
          userQuipsTable.refreshControl = refreshControl
          
        
      }
    override func btnEllipsesTapped(cell: QuipCells) {
        if let indexPath = self.userQuipsTable.indexPath(for: cell){
                                               
                                                    if let myQuip = topUserQuips[indexPath.row]{
                                                       if let myUserController = myUserController{
                                                      MenuLauncher.setVars(userController: myUserController, myQuip: myQuip)
                                                       }
                                                    }
                                                    
                                                
                                                }
               MenuLauncher.makeViewFade()
               MenuLauncher.addMenuFromBottom()
    }
   override func btnUpTapped(cell: QuipCells) {
        //Get the indexpath of cell where button was tapped
              if let indexPath = self.userQuipsTable.indexPath(for: cell){
              
                  if let myQuip = topUserQuips[indexPath.row]{
                  upButtonPressed(aQuip: myQuip, cell: cell)
                    if let aQuipID = myQuip.quipID{
                                     myUserController?.checkNewQuips(myQuipID: aQuipID, isUp: true)
                                 }
                  }
             
              }
    }
    
    override func btnDownTapped(cell: QuipCells) {
     //Get the indexpath of cell where button was tapped
            if let indexPath = self.userQuipsTable.indexPath(for: cell){
          
                
                if let myQuip = topUserQuips[indexPath.row]{
                downButtonPressed(aQuip: myQuip, cell: cell)
                    if let aQuipID = myQuip.quipID{
                        myUserController?.checkNewQuips(myQuipID: aQuipID, isUp: false)
                    }
                }
             
            
            }
            
        
    }
    override func btnSharedTapped(cell: QuipCells) {
        if let indexPath = self.userQuipsTable.indexPath(for: cell){
                 
                       
                       if let myQuip = topUserQuips[indexPath.row]{
                       generateDynamicLink(aquip: myQuip, cell: cell)
                       }
                    
                   
                   }
    }
    
    override func btnRepliesTapped(cell: QuipCells) {
         userQuipsTable.selectRow(at: userQuipsTable.indexPath(for: cell), animated: true, scrollPosition: .none)
    }
      
      @objc func refreshData(){
           myUserController?.getUserScore()
          updateTop()
      }
    
      func updateTop(){
        refreshControl.beginRefreshing()
        self.topUserQuips = []
        self.myHotIDs = []
        if let auid = myUserController?.uidProfile{
        FirebaseService.sharedInstance.getTopUserQuips(uid: auid) { [weak self](myTopScores, currentTime, moreTopFirebaseQuips, myHotIDs) in
            self?.topUserQuips = myTopScores
            self?.currentTime = currentTime
            self?.myHotIDs = myHotIDs
            FirestoreService.sharedInstance.getHotQuipsUser(myUid: auid, aHotIDs: myHotIDs, hotQuips: myTopScores) {[weak self] (myData, aHotQuips, more) in
                self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                self?.moreTopUserQuipsFirebase = moreTopFirebaseQuips
               
            }
        }
        }
      }
    func populateHotQuipsArr(data:[String:Any], aHotQuips:[Quip?], more:Bool){
                for aQuip in aHotQuips{
                    if let myQuip = aQuip{
                        if let myID = myQuip.quipID{
                            let quipData = data[myID] as! [String:Any]
                            myQuip.user = quipData["a"] as? String
                            myQuip.channel = quipData["c"] as? String
                            myQuip.channelKey = quipData["k"] as? String
                            myQuip.quipText = quipData["t"] as? String
                            myQuip.timePosted = quipData["d"] as? Timestamp
                           myQuip.gifID = quipData["g"] as? String
                           myQuip.imageRef = quipData["i"] as? String
                            myQuip.isReply = quipData["r"] as? Bool ?? false
                            if myQuip.isReply{
                                myQuip.quipParent = quipData["p"] as? String
                            }
                        
                    }
                    }
                    
                }
                if more{
                    self.topUserQuips = self.topUserQuips + aHotQuips
                }
            self.userQuipsTable.reloadData()
                self.refreshControl.endRefreshing()
                
            }
    func loadMoreTopUserQuips(){
        moreTopUserQuipsFirebase = false
        if let auid = myUserController?.uidProfile{
            FirebaseService.sharedInstance.loadMoreHotUser(auid: auid) {[weak self] (ahotquips, ahotids, morehotquipsfirebase) in
                FirestoreService.sharedInstance.loadMoreHotUser(auid: auid, aHotIDs: ahotids, hotQuips: ahotquips) {[weak self] (myData, aHotQuips, more) in
                    self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                    self?.moreTopUserQuipsFirebase=morehotquipsfirebase
                    self?.refreshControl.endRefreshing()
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topUserQuips.count
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userQuipsTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as! QuipCells
          if topUserQuips.count > 0 {
                                   if let myQuip = self.topUserQuips[indexPath.row]{
                                     cell.aQuip = myQuip
                                                if let myImageRef = myQuip.imageRef  {
                                                    
                                                        cell.addImageViewToTableCell()
                                                        cell.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.userQuipsTable)
                                                    
                                                                                                                            
                                                }
                                                                                                                                                               
                                                else if let myGifID = myQuip.gifID  {
                                                                                                                         
                                                    cell.addGifViewToTableCell()
                                                    cell.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.userQuipsTable)
                                                                                                                                                                   
                                                }
                                                                    
                                     if myQuip.isReply{
                                             cell.replyButton.isHidden = true
                                        cell.shareButton.isHidden = true
                                        cell.categoryLabel.text = ""
                                     }else if let aChannel = myQuip.channel{
                                            
                                            cell.categoryLabel.text = aChannel
                                            
                                        }
                                       
                                                                                                                             
                                     if let aID = myQuip.quipID{
                                         if self.myUserController?.myLikesDislikesMap[aID] == 1{
                                             cell.upButton.isSelected=true
                                             cell.upButton.tintColor = UIColor(hexString: "ffaf46")
                                     }
                                     else if self.myUserController?.myLikesDislikesMap[aID] == -1{
                                             cell.downButton.isSelected=true
                                             cell.downButton.tintColor = UIColor(hexString: "ffaf46")
                                                                                                     
                                         }
                                     }
                                        
                                        if let dateVal = myQuip.timePosted?.seconds{
                                            let milliTimePost = dateVal * 1000
                                            if let aCurrentTime = self.currentTime{
                                                cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: aCurrentTime)
                                            }
                                        }
                                       
                                                                          
                                                                        
                                    }
                                             }
                                             else{
                                                 return cell
                                             }
        cell.downButton.changeButtonWeight()
              cell.upButton.changeButtonWeight()
                      cell.delegate = self
                    return cell
      }
      func scrollViewDidScroll(_ scrollView: UIScrollView) {
                let height = scrollView.frame.size.height
                let contentYoffset = scrollView.contentOffset.y
                let distanceFromBottom = scrollView.contentSize.height - contentYoffset
                if distanceFromBottom < height {
                   
                           
                          
                               // handle your logic here to get more items, add it to dataSource and reload tableview
                 
                                           if moreTopUserQuipsFirebase {
                                            loadMoreTopUserQuips()
                                            }
                                    
                        
                }
            }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
          cellHeights[indexPath] = cell.frame.size.height
      }

      func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
          return cellHeights[indexPath] ?? UITableView.automaticDimension
      }
    
}
