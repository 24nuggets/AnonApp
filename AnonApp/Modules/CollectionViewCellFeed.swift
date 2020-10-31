//
//  CollectionViewCellFeed.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/23/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase
import GiphyUISDK
import GiphyCoreSDK

class CollectionCellFeed:UICollectionViewCell, MyCellDelegate{
    
   let shareText = "Check out this crack on the Nut House!"
     var currentTime:Double?
    var myFeedController:ViewControllerFeed?
     var newQuips:[Quip?] = []
     var hotQuips:[Quip?] = []
    var hiddenPosts:[String:Bool] = [:]
   
    lazy var MenuLauncher:ellipsesMenuFeed = {
            let launcher = ellipsesMenuFeed()
         launcher.feedController = myFeedController
             return launcher
        }()
    
    func btnRepliesTapped(cell: QuipCells) {
        
    }
   
    func btnDownTapped(cell: QuipCells) {
        
    }
     func btnUpTapped(cell: QuipCells) {
    }
    
    
    func btnEllipsesTapped(cell: QuipCells) {
          
       }
    
    func btnSharedTapped(cell: QuipCells) {
                     
                       
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
                              activityViewController.popoverPresentationController?.sourceView = myFeedController?.view // so that iPads won't crash

                               // exclude some activity types from the list (optional)
                        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.print]

                               // present the view controller
                               myFeedController?.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - Like/Dislike Logic
     
     //each if statement:
     //1. updates cell to reflect changes
     //2. adds votes to firebase array
     //3. adds votes to newlikesdislikes map - this is never read just used to push changes to database
     //4. adds votes to current likesdislikes map - this is so changes are reflected when scrolling back and forth
     //5. adds user id to dict so it can be easily found when votes in firestore are commited
    
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
    
    func downButtonPressed(aQuip:Quip, cell:QuipCells, checkHot:Bool){
          if cell.upButton.isSelected {
                 if let aQuipScore = aQuip.quipScore{
                  let diff = cell.upToDown(quipScore: aQuipScore, quip: aQuip)
                      if let aID = aQuip.quipID{
                          if let aAuthor = aQuip.user{
                          
                            myFeedController?.myNewLikesDislikesMap[aID] = -1
                          myFeedController?.myLikesDislikesMap[aID] = -1
                         myFeedController?.myUserMap[aID]=aQuip.user
                            if aQuip.channelKey != myFeedController?.myChannel?.key{
                                                          myFeedController?.childChannelMap[aID] = aQuip.channelKey
                                                      }
                            myFeedController?.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aAuthor)
                          
                            
                            if checkHot{
                            myFeedController?.checkHotQuips(myQuipID: aID, isUp: false, change: diff)
                            } else{
                                  myFeedController?.checkNewQuips(myQuipID: aID, isUp: false, change: diff)
                                }

                          }
                      }
              }
          }
          else if cell.downButton.isSelected {
                 if let aQuipScore = aQuip.quipScore{
                  let diff = cell.downToNone(quipScore: aQuipScore, quip: aQuip)
                      if let aID = aQuip.quipID{
                          if let aAuthor = aQuip.user{
                          
                          myFeedController?.myNewLikesDislikesMap[aID]=0
                          myFeedController?.myLikesDislikesMap[aID]=0
                          myFeedController?.myUserMap[aID]=aQuip.user
                            if aQuip.channelKey != myFeedController?.myChannel?.key{
                                                           myFeedController?.childChannelMap[aID] = aQuip.channelKey
                                                       }
                              myFeedController?.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aAuthor)
                           
                            if checkHot{
                            myFeedController?.checkHotQuips(myQuipID: aID, isUp: false, change: diff)
                            } else{
                              myFeedController?.checkNewQuips(myQuipID: aID, isUp: false, change: diff)
                            }
                          }
                      }
                  
              }
          }
          else{
               if let aQuipScore = aQuip.quipScore{
                  let diff = cell.noneToDown(quipScore: aQuipScore, quip:aQuip)
                  if let aID = aQuip.quipID{
                      if let aAuthor = aQuip.user{
                      
                      myFeedController?.myNewLikesDislikesMap[aID] = -1
                      myFeedController?.myLikesDislikesMap[aID] = -1
                      myFeedController?.myUserMap[aID]=aQuip.user
                        
                        if aQuip.channelKey != myFeedController?.myChannel?.key{
                            myFeedController?.childChannelMap[aID] = aQuip.channelKey
                        }
                          myFeedController?.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aAuthor)
                        if checkHot{
                        myFeedController?.checkHotQuips(myQuipID: aID, isUp: false, change: diff)
                        } else{
                          myFeedController?.checkNewQuips(myQuipID: aID, isUp: false, change: diff)
                        }
                      }
                  }
              }
              
          }
          
      }
    func upButtonPressed(aQuip:Quip, cell:QuipCells, checkHot:Bool){
          if cell.upButton.isSelected {
              if let aQuipScore = aQuip.quipScore{
                  let diff = cell.upToNone(quipScore: aQuipScore, quip:aQuip)
                  if let aID = aQuip.quipID{
                      if let aAuthor = aQuip.user{
                      
                        myFeedController?.myNewLikesDislikesMap[aID]=0
                        myFeedController?.myLikesDislikesMap[aID]=0
                      myFeedController?.myUserMap[aID]=aQuip.user
                        if aQuip.channelKey != myFeedController?.myChannel?.key{
                                                  myFeedController?.childChannelMap[aID] = aQuip.channelKey
                                              }
                          myFeedController?.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aAuthor)
                      
                        if checkHot{
                         myFeedController?.checkHotQuips(myQuipID: aID, isUp: true, change: diff)
                        }else{
                           myFeedController?.checkNewQuips(myQuipID: aID, isUp: true, change: diff)
                        }
                      }
                      }
                      
              }
               }
               else if cell.downButton.isSelected {
                  if let aQuipScore = aQuip.quipScore{
                      let diff = cell.downToUp(quipScore: aQuipScore, quip:aQuip)
                          if let aID = aQuip.quipID{
                              if let aAuthor = aQuip.user{
                              
                              myFeedController?.myNewLikesDislikesMap[aID] = 1
                              myFeedController?.myLikesDislikesMap[aID] = 1
                              myFeedController?.myUserMap[aID]=aQuip.user
                                if aQuip.channelKey != myFeedController?.myChannel?.key{
                                                                   myFeedController?.childChannelMap[aID] = aQuip.channelKey
                                                               }
                                  myFeedController?.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aAuthor)
                               
                                if checkHot{
                                 myFeedController?.checkHotQuips(myQuipID: aID, isUp: true, change: diff)
                                }else{
                                   myFeedController?.checkNewQuips(myQuipID: aID, isUp: true, change: diff)
                                }
                              }
                          }
                      }
                  }
               else{
                  if let aQuipScore = aQuip.quipScore{
                      let diff = cell.noneToUp(quipScore: aQuipScore, quip:aQuip)
                      if let aID = aQuip.quipID{
                          if let aAuthor = aQuip.user{
                          
                          myFeedController?.myNewLikesDislikesMap[aID] = 1
                          myFeedController?.myLikesDislikesMap[aID] = 1
                          myFeedController?.myUserMap[aID]=aQuip.user
                            if aQuip.channelKey != myFeedController?.myChannel?.key{
                                myFeedController?.childChannelMap[aID] = aQuip.channelKey
                            }
                          myFeedController?.updateVotesFirebase(diff: diff, quip: aQuip, aUID: aAuthor)
                            
                            if checkHot{
                             myFeedController?.checkHotQuips(myQuipID: aID, isUp: true, change: diff)
                            }else{
                               myFeedController?.checkNewQuips(myQuipID: aID, isUp: true, change: diff)
                            }
                          }
                      }
                  }
               }
          
      }
    
    
 
    
    
}

class CollectionViewCellFeedRecent: CollectionCellFeed, UITableViewDelegate, UITableViewDataSource  {
   
    
    var refreshControl=UIRefreshControl()
    private var firestoreQuips:[Quip?] = []
    var myScores:[String:Any]=[:]
    private var moreRecentQuipsFirebase:Bool = false
    private var moreRecentQuipsFirestore:Bool = false
   private var cellHeights = [IndexPath: CGFloat]()
    
    @IBOutlet weak var feedTable: UITableView!
    
    override func awakeFromNib() {
       super.awakeFromNib()
       feedTable.delegate = self
       feedTable.dataSource = self
        self.feedTable.rowHeight = UITableView.automaticDimension
        self.feedTable.estimatedRowHeight = 500.0
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        feedTable.refreshControl = refreshControl
        
      
    }
    
    @objc func refreshData(){
        
        updateNew(){
            
        }
    }
    
    func updateNew(completion: @escaping ()->()){
        self.refreshControl.beginRefreshing()
        self.firestoreQuips = []
        self.myScores = [:]
        self.moreRecentQuipsFirebase = false
        if let myChannelKey = myFeedController?.myChannel?.key{
            if let aUid = myFeedController?.uid {
                FirestoreService.sharedInstance.getHiddenPosts(uid: aUid, key: myChannelKey) {[weak self] (hiddenPosts) in
                    self?.hiddenPosts = hiddenPosts
                }
            FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: aUid, aKey: myChannelKey) { [weak self](myLikesDislikesMap) in
            self?.myFeedController?.myLikesDislikesMap = myLikesDislikesMap
            
            FirebaseService.sharedInstance.getNewScoresFeed(myChannelKey: myChannelKey) { [weak self](myScores, currentTime,  moreRecentQuipsFirebase) in
                self?.myScores = myScores
                self?.currentTime = currentTime
                self?.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                if let myChannelName = self?.myFeedController?.myChannel?.channelName{
                    FirestoreService.sharedInstance.getNewQuipsFeed(myChannelKey: myChannelKey, myChannelName: myChannelName) { [weak self](newQuips, moreRecentQuipsFirestore) in
                        self?.firestoreQuips = newQuips
                        self?.mergeFirestoreFirebaseNewQuips()
                        self?.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                        
                            self?.feedTable.reloadData()
                            self?.refreshControl.endRefreshing()
                            completion()
                            }
                        }
                    }
                }
                
            }
        
       
       
        }
        
    }
    
    func loadMoreRecent(){
              moreRecentQuipsFirestore=false
           
           if let myChannelKey = myFeedController?.myChannel?.key{
               if moreRecentQuipsFirebase==true{
                   moreRecentQuipsFirebase=false
               FirebaseService.sharedInstance.getMoreNewScoresFeed(myChannelKey: myChannelKey) {[weak self] (myScores, moreRecentQuipsFirebase) in
                   if let aself = self{
                   self?.myScores = aself.myScores.merging(myScores, uniquingKeysWith: { (_, new) -> Any in
                       new
                   })
                   }
                   
                  
                       if let myChannelName = self?.myFeedController?.myChannel?.channelName{
                           FirestoreService.sharedInstance.loadMoreNewQuipsFeed(myChannelKey: myChannelKey, channelName: myChannelName) { [weak self](newQuips, moreRecentQuipsFirestore) in
                               if let aself = self{
                               self?.firestoreQuips = aself.firestoreQuips + newQuips
                               self?.mergeFirestoreFirebaseNewQuips()
                               self?.feedTable.reloadData()
                                //have to reload table before setting these to true
                               self?.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                               self?.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                               }
                           }
                           
                       
                   }else{
                       self?.mergeFirestoreFirebaseNewQuips()
                       self?.feedTable.reloadData()
                       self?.moreRecentQuipsFirebase = moreRecentQuipsFirebase
                   }
                   
               }
               }else{
                   if let myChannelName = self.myFeedController?.myChannel?.channelName{
                       FirestoreService.sharedInstance.loadMoreNewQuipsFeed(myChannelKey: myChannelKey, channelName: myChannelName) {[weak self] (newQuips, moreRecentQuipsFirestore) in
                           if let aself = self{
                           self?.firestoreQuips = aself.firestoreQuips + newQuips
                           self?.mergeFirestoreFirebaseNewQuips()
                           self?.feedTable.reloadData()
                           }
                                               //have to reload table before setting these to true
                       
                           self?.moreRecentQuipsFirestore = moreRecentQuipsFirestore
                   }
                   }
               }
           }
           
           
             
              
          }
       
       func mergeFirestoreFirebaseNewQuips(){
           newQuips = []
           for aQuip in firestoreQuips{
               guard let myQuipInfo = myScores[aQuip?.quipID ?? ""] as? [String:Int] else {continue}
               aQuip?.setScore(aScore:myQuipInfo["s"] ?? 0)
               aQuip?.quipReplies = myQuipInfo["r"]
            if hiddenPosts[aQuip?.quipID ?? "Other"]  == true{
                
            }else if blockedUsers[aQuip?.user ?? "Other"] == true{
               
            }
            else{
               newQuips.append(aQuip)
            }
           }
           
       }
    //gets number of sections for tableview
       func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newQuips.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        
            
          let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? QuipCells
                
          
                if newQuips.count > 0 {
                
                    if let myQuip = self.newQuips[indexPath.row]{
                     //   myQuip.channel = myFeedController?.myChannel?.channelName
                     //   myQuip.parentKey = myFeedController?.myChannel?.parentKey
                       
                        cell?.aQuip = myQuip
                           if let myImageRef = myQuip.imageRef  {
                               
                               cell?.addImageViewToTableCell()
                             cell?.myImageView.getImage(myQuipImageRef: myImageRef,  feedTable: self.feedTable)
                                                       //        }
                        }
                         else if let myGifID = myQuip.gifID  {
                               // cell?.addGifViewToTableCell()
                               // cell?.myGifView.getImageFromGiphy(gifID: myGifID, feedTable:self.feedTable)
                            cell?.table = feedTable
                            cell?.gifID = myGifID
                                                                    
                                                               }
                       /*
                        if myFeedController?.hasAccess ?? false{
                            cell?.upButton.isHidden = false
                            cell?.downButton.isHidden = false
                        }else{
                            cell?.upButton.isHidden = true
                            cell?.downButton.isHidden = true
                        }
        */
                if let dateVal = myQuip.timePosted?.seconds{
                    let milliTimePost = dateVal * 1000
                if let aCurrentTime = self.currentTime{
                        cell?.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: aCurrentTime)
                                               }
                                           }
                        if myQuip.parentKey == myFeedController?.myChannel?.key{
                            cell?.categoryLabel.text = myQuip.channel
                        }else{
                        cell?.categoryLabel.text = ""
                        }
                if let aID = myQuip.quipID{
                if self.myFeedController?.myLikesDislikesMap[aID] == 1{
                    cell?.upButton.isSelected=true
                                        
                                                       cell?.upButton.tintColor = UIColor(hexString: "ffaf46")
                                               }
                                               else if self.myFeedController?.myLikesDislikesMap[aID] == -1{
                                                       cell?.downButton.isSelected=true
                                                      
                                                       cell?.downButton.tintColor = UIColor(hexString: "ffaf46")
                                                                                                             
                                               }
                                           }
                }
                
                else{
                    return UITableViewCell()
                }
                cell?.downButton.changeButtonWeight()
                     cell?.upButton.changeButtonWeight()
                     cell?.delegate = self
                   
                 return cell!
        }
        return UITableViewCell()
       }
    
   

   func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       
       cellHeights[indexPath] = cell.frame.size.height
   }

   func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
       return cellHeights[indexPath] ?? UITableView.automaticDimension
   }
    override func btnDownTapped(cell: QuipCells) {
         if myFeedController?.hasAccess ?? false{
        //Get the indexpath of cell where button was tapped
        if let indexPath = self.feedTable.indexPath(for: cell){
       
            if let myQuip = newQuips[indexPath.row]{
                downButtonPressed(aQuip: myQuip, cell: cell, checkHot:true)
                

            }
        }
        }else{
            myFeedController?.displayMsgBoxAccess()
        }
        
    }
    
    override func btnRepliesTapped(cell: QuipCells) {
         feedTable.selectRow(at: feedTable.indexPath(for: cell), animated: true, scrollPosition: .none)
    }
    
    override func btnUpTapped(cell: QuipCells) {
           //Get the indexpath of cell where button was tapped
        if myFeedController?.hasAccess ?? false{
           if let indexPath = self.feedTable.indexPath(for: cell){
          
               if let myQuip = newQuips[indexPath.row]{
                upButtonPressed(aQuip: myQuip, cell: cell, checkHot:true)
               
               }
               
           
           }
        }else{
            myFeedController?.displayMsgBoxAccess()
        }
       }
    
   override func btnSharedTapped(cell: QuipCells) {
                        if let indexPath = self.feedTable.indexPath(for: cell){
                                
                                     if let myQuip = newQuips[indexPath.row]{
                                    generateDynamicLink(aquip: myQuip, cell: cell)
                                     }
                                     
                                 
                                 }
                          
       }
    
    override func btnEllipsesTapped(cell: QuipCells) {
       
        if let indexPath = self.feedTable.indexPath(for: cell){
                                          
                                               if let myQuip = newQuips[indexPath.row]{
                                                if let myFeedController = myFeedController{
                                                MenuLauncher.setVars(feedController: myFeedController, myQuip: myQuip)
                                                }
                                               }
                                               
                                           
                                           }
         MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
     
    }
    
   
      func scrollViewDidScroll(_ scrollView: UIScrollView) {
          let height = scrollView.frame.size.height
          let contentYoffset = scrollView.contentOffset.y
          let distanceFromBottom = scrollView.contentSize.height - contentYoffset
          if distanceFromBottom < height {
             
                     
                    
                         // handle your logic here to get more items, add it to dataSource and reload tableview
                       
                                 if moreRecentQuipsFirestore {
                                    loadMoreRecent()
                                 }
                                
                                 
                  
          }
      }
    
}


class CollectionViewCellFeedTop: CollectionCellFeed,UITableViewDelegate, UITableViewDataSource  {
   
    var refreshControl=UIRefreshControl()
     private var myHotIDs:[String]=[]
    private var moreHotQuipsFirebase:Bool = false
    private var cellHeights = [IndexPath: CGFloat]()
    
    @IBOutlet weak var feedTable: UITableView!
    
    override func awakeFromNib() {
         super.awakeFromNib()
         feedTable.delegate = self
         feedTable.dataSource = self
       self.feedTable.rowHeight = UITableView.automaticDimension
             self.feedTable.estimatedRowHeight = 500.0
         refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        feedTable.refreshControl = refreshControl
      }
    
    @objc func refreshData(){
           
        updateHot(){
            
        }
       }
    
    func updateHot(completion: @escaping ()->()){
         refreshControl.beginRefreshing()
         self.hotQuips = []
         self.myHotIDs = []
         
         moreHotQuipsFirebase = false
         if let myChannelKey = myFeedController?.myChannel?.key{
             if let aUid = myFeedController?.uid {
                FirestoreService.sharedInstance.getHiddenPosts(uid: aUid, key: myChannelKey) {[weak self] (hiddenPosts) in
                    self?.hiddenPosts = hiddenPosts
                
             FirestoreService.sharedInstance.getUserLikesDislikesForChannelOrUser(aUid: aUid, aKey: myChannelKey) { [weak self](myLikesDislikesMap) in
                        self?.myFeedController?.myLikesDislikesMap = myLikesDislikesMap
             FirebaseService.sharedInstance.getHotFeed(myChannelKey: myChannelKey) {[weak self] (myHotQuips, myHotQuipIDs, moreHotQuipsFirebase, currentTime)  in
                 self?.hotQuips = myHotQuips
                 self?.myHotIDs = myHotQuipIDs
                 self?.currentTime = currentTime
                 FirestoreService.sharedInstance.getHotQuipsFeed(myChannelKey: myChannelKey, aHotIDs: myHotQuipIDs, hotQuips: myHotQuips) {[weak self] (myData, aHotQuips, more) in
                     self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                     self?.moreHotQuipsFirebase = moreHotQuipsFirebase
                     self?.refreshControl.endRefreshing()
                    completion()
                 }
             }
                    }
         }
        }
        }
     }
    
     
    func populateHotQuipsArr(data:[String:Any], aHotQuips: [Quip?], more:Bool){
        
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
                        myQuip.parentKey = quipData["pk"] as? String
                      
                  }
                }
                  
              }
              if more{
                  self.hotQuips = self.hotQuips + aHotQuips
              }
            checkForHiddenPosts()
              self.feedTable.reloadData()
              
              
          }
     
    func checkForHiddenPosts(){
        var i = 0
        for aQuip in hotQuips{
            if let myID = aQuip?.quipID{
                if hiddenPosts[myID] == true{
                    hotQuips.remove(at: i)
                }else if blockedUsers[aQuip?.user ?? "Other"] == true{
                    hotQuips.remove(at: i)
                }
                else{
                    i = i + 1
                }
            
            }
            
        }
    }
    
     
    
     
    
     func loadMoreHotQuips(){
         moreHotQuipsFirebase = false
         if let myChannelKey = myFeedController?.myChannel?.key{
             FirebaseService.sharedInstance.loadMoreHotFeed(myChannelKey: myChannelKey) {[weak self] (aHotQuips, aHotIDs, moreHotQuipsFirebase) in
                 FirestoreService.sharedInstance.loadMoreHotFeed(myChannelKey: myChannelKey, aHotIDs: aHotIDs, hotQuips: aHotQuips) {[weak self] (myData, aHotQuips, more) in
                     self?.populateHotQuipsArr(data: myData, aHotQuips: aHotQuips, more: more)
                     self?.moreHotQuipsFirebase = moreHotQuipsFirebase
                     self?.refreshControl.endRefreshing()
                 }
                 
                 
             }
         }
        
         
     }
    
    //gets number of sections for tableview
       func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hotQuips.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = feedTable.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath) as? QuipCells {
            if hotQuips.count > 0 {
                               if let myQuip = self.hotQuips[indexPath.row]{
                                   cell.aQuip=myQuip
                               if let myImageRef = myQuip.imageRef {
                                   
                                       cell.addImageViewToTableCell()
                                
                                       cell.myImageView.getImage(myQuipImageRef: myImageRef, feedTable: self.feedTable)
                                   
                                                                
                               }
                                                                                                   
                               else if let gifID = myQuip.gifID {
                                                             
                                       //cell.addGifViewToTableCell()
                                       //cell.myGifView.getImageFromGiphy(gifID: gifID, feedTable:self.feedTable)
                                cell.table = feedTable
                                cell.gifID = gifID
                               }
                            /*
                                if myFeedController?.hasAccess ?? false{
                                cell.upButton.isHidden = false
                                cell.downButton.isHidden = false
                            }else{
                                cell.upButton.isHidden = true
                                cell.downButton.isHidden = true
                            }
    */
                              
                               if myQuip.parentKey == myFeedController?.myChannel?.key{
                                   cell.categoryLabel.text = myQuip.channel
                               }else{
                                cell.categoryLabel.text = ""
                                }
                              
                               if let dateVal = myQuip.timePosted?.seconds{
                                   let milliTimePost = dateVal * 1000
                                   cell.timePosted.text = timeSincePost(timePosted: Double(milliTimePost), currentTime: self.currentTime!)
                               }
                                   if let aID = myQuip.quipID{
                               if self.myFeedController?.myLikesDislikesMap[aID] == 1{
                                           cell.upButton.isSelected=true
                                  
                                  
                                   cell.upButton.tintColor = UIColor(hexString: "ffaf46")
                               }
                               else if self.myFeedController?.myLikesDislikesMap[aID] == -1{
                                           cell.downButton.isSelected=true
                                                 cell.downButton.tintColor = UIColor(hexString: "ffaf46")
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
            
        }
          return UITableViewCell()
       }
    
   func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
         cellHeights[indexPath] = cell.frame.size.height
     }

     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
         return cellHeights[indexPath] ?? UITableView.automaticDimension
     }
      override func btnDownTapped(cell: QuipCells) {
        if myFeedController?.hasAccess ?? false{
          //Get the indexpath of cell where button was tapped
          if let indexPath = self.feedTable.indexPath(for: cell){
         
              
              if let myQuip = hotQuips[indexPath.row]{
              downButtonPressed(aQuip: myQuip, cell: cell, checkHot: false)
               
              }
          }
    }else{
        myFeedController?.displayMsgBoxAccess()
    }
          
      }
    override func btnRepliesTapped(cell: QuipCells) {
         feedTable.selectRow(at: feedTable.indexPath(for: cell), animated: true, scrollPosition: .none)
    }
    
    override func btnUpTapped(cell: QuipCells) {
        if myFeedController?.hasAccess ?? false{
           //Get the indexpath of cell where button was tapped
           if let indexPath = self.feedTable.indexPath(for: cell){
           
               if let myQuip = hotQuips[indexPath.row]{
               upButtonPressed(aQuip: myQuip, cell: cell, checkHot: false)
               
               }
            
        }
    }else{
        myFeedController?.displayMsgBoxAccess()
    }
       }
    
    override func btnSharedTapped(cell: QuipCells) {
                           if let indexPath = self.feedTable.indexPath(for: cell){
                                   
                                        if let myQuip = hotQuips[indexPath.row]{
                                       generateDynamicLink(aquip: myQuip, cell: cell)
                                        }
                                        
                                    
                                    }
                             
          }
    
    override func btnEllipsesTapped(cell: QuipCells) {
        
            
           if let indexPath = self.feedTable.indexPath(for: cell){
                                        
                                             if let myQuip = hotQuips[indexPath.row]{
                                                if let myFeedController = myFeedController{
                                               MenuLauncher.setVars(feedController: myFeedController, myQuip: myQuip)
                                                }
                                             }
                                             
                                         
                                         }
        MenuLauncher.makeViewFade()
        MenuLauncher.addMenuFromBottom()
 
       }
   
    
      func scrollViewDidScroll(_ scrollView: UIScrollView) {
          let height = scrollView.frame.size.height
          let contentYoffset = scrollView.contentOffset.y
          let distanceFromBottom = scrollView.contentSize.height - contentYoffset
          if distanceFromBottom < height {
             
                     
                    
                         // handle your logic here to get more items, add it to dataSource and reload tableview
                        
                                     if moreHotQuipsFirebase {
                                      loadMoreHotQuips()
                                      }
                                
                  
          }
      }
}
