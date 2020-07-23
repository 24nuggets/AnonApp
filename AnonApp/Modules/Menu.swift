//
//  File.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/27/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//


import UIKit

class MenuItem: NSObject{
    let name:String
    let imageName:String
    
    init(name:String, imageName:String) {
        self.name = name
        self.imageName = imageName
    }
}



class Menu: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    
    let blackView = UIView()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.isScrollEnabled = false
        return cv
    }()
    
    let cellHeight:CGFloat = 60
    let cellId = "cellId"
    
    func makeViewFade(){
         if let window = UIApplication.shared.keyWindow{
                
                    blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
                    blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
                window.addSubview(blackView)
                blackView.frame = window.frame
                    blackView.alpha = 0
                    
                    
                }
     }
     
     
     @objc func handleDismiss(){
      dismiss()
      
    }
    
    func dismiss(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                   self.blackView.alpha = 0
                            if let window = UIApplication.shared.keyWindow{
                                let y:CGFloat = window.frame.height
                                  self.collectionView.frame = CGRect(x: 0, y: y, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
                            }
              },completion:nil)
    }
    
    
    func addMenuFromBottom(){
        if let window = UIApplication.shared.keyWindow{
        window.addSubview(collectionView)
            let height:CGFloat = CGFloat(menuItems.count) * cellHeight
        let y = window.frame.height - height
            collectionView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: height)
    
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                   self.blackView.alpha = 1
            self.collectionView.frame = CGRect(x: 0, y: y, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
               }, completion: nil)
    
        }
        
        
    
    }
    
    func addMenuFromSide(){
        if let window = UIApplication.shared.keyWindow{
               window.addSubview(collectionView)
            let height:CGFloat = window.frame.height
            collectionView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
            let x = window.frame.width * -0.6
                   collectionView.frame = CGRect(x: x, y: 0, width: x, height: height)
           
               
               UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                          self.blackView.alpha = 1
                   self.collectionView.frame = CGRect(x: 0, y: 0, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
                      }, completion: nil)
           
               }
               
        
    }
    
   var menuItems:[MenuItem] = []
    
   
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? MenuCellWithIcon{
        let menuItem = menuItems[indexPath.row]
        cell.MenuItem = menuItem
        return cell
    }
    return UICollectionViewCell()
    }
    
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize  {

        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          minimumLineSpacingForSectionAt section: Int) -> CGFloat{
        return 0
    }
    
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    selectItem(index: indexPath.row)
 
    }
    
    func selectItem(index:Int){
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                       
           self.blackView.alpha = 0
           if let window = UIApplication.shared.keyWindow{
               let y:CGFloat = window.frame.height
                 self.collectionView.frame = CGRect(x: 0, y: y, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
           }
               
               
         }, completion: {(value:Bool) in
           let menuItem = self.menuItems[index]
           if menuItem.name != "Cancel" {
               self.nextController(menuItem:menuItem)
           }
         })
        
    }
    
    
    func nextController(menuItem:MenuItem){
        
    }
    
    override init() {
        super.init()
        
        initialize()
        populateMenuItems()
    }
    
    func initialize(){
        
              
              collectionView.dataSource = self
              collectionView.delegate = self
                     
              collectionView.register(MenuCellWithIcon.self, forCellWithReuseIdentifier: cellId)
        
    }
    
    func populateMenuItems(){
    }
}

class addFavsMenu:Menu{
    
    weak var favController: ViewControllerFavorites?
    
    override func nextController(menuItem:MenuItem){
        
        self.favController?.showAddViewController(menuItem: menuItem)
        
    }
    

    

   
    override func populateMenuItems(){
        menuItems = [MenuItem(name:"Add Teams And Leagues", imageName: "plus.circle"), MenuItem(name:"Add Shows", imageName:"plus.circle"), MenuItem(name:"Cancel", imageName: "multiply.circle")]
           
       }
  
}

class ellipsesMenuFeed:Menu{
    
   
   weak var feedController: ViewControllerFeed?
    weak var myQuip:Quip?
    
    
  
 
    func setVars(feedController:ViewControllerFeed?, myQuip:Quip?){
        self.feedController = feedController
        self.myQuip = myQuip
        populateMenuItems()
    }
    
    override func nextController(menuItem:MenuItem){
        
            if let myQuip = myQuip{
            feedController?.showNextController(menuItem: menuItem, quip: myQuip)
            }
        
       }
    
    override func populateMenuItems(){
        if feedController?.uid == myQuip?.user{
        
     menuItems = [MenuItem(name:"Share Quip", imageName:"arrowshape.turn.up.right.circle"),MenuItem(name:"Delete Quip", imageName: "trash.circle"), MenuItem(name:"Cancel", imageName: "multiply.circle")]
        }else{
            
            menuItems = [MenuItem(name:"View User's Profile", imageName: "person.circle"),MenuItem(name:"Share Quip", imageName:"arrowshape.turn.up.right.circle"), MenuItem(name: "Report Quip", imageName: "flag.circle"),  MenuItem(name:"Cancel", imageName: "multiply.circle")]
            }
        collectionView.reloadData()
    }

}

class ellipsesMenuUser:Menu{

    weak var userController: ViewControllerUser?
    weak var myQuip: Quip?
    
    override func nextController(menuItem:MenuItem){
        userController?.showNextControllerEllipses(menuItem: menuItem, quip: myQuip)
       
    }
    
    func setVars(userController:ViewControllerUser?, myQuip:Quip?){
        self.userController = userController
        self.myQuip = myQuip
        populateMenuItems()
    }
    
    override func populateMenuItems(){
        if userController?.uid == userController?.uidProfile{
            menuItems = [MenuItem(name:"Share Quip", imageName:"arrowshape.turn.up.right.circle"),MenuItem(name:"Delete Quip", imageName: "trash.circle"), MenuItem(name:"Cancel", imageName: "multiply.circle")]
        }else{
            menuItems = [MenuItem(name:"Share Quip", imageName:"arrowshape.turn.up.right.circle"), MenuItem(name: "Report Quip", imageName: "flag.circle"), MenuItem(name:"Cancel", imageName: "multiply.circle")]
        }
       collectionView.reloadData()
           
       }
}


class ellipsesMenuQuip:Menu{
    
    weak var quipController: ViewControllerQuip?
    weak var myQuip:Quip?
    
    override func nextController(menuItem:MenuItem){
        
            if let myQuip = myQuip{
            quipController?.showNextControllerReply(menuItem: menuItem, quip: myQuip)
            }
        
    }
    
    func setVars(quipController:ViewControllerQuip?, myQuip:Quip?){
           self.quipController = quipController
           self.myQuip = myQuip
           populateMenuItems()
       }

    override func populateMenuItems(){
        if quipController?.uid == myQuip?.user{
        menuItems = [MenuItem(name:"Share Quip", imageName:"plus.circle"),MenuItem(name: "Delete Quip", imageName: "flag"),  MenuItem(name:"Cancel", imageName: "multiply.circle")]
        }else{
             menuItems = [MenuItem(name:"View User's Profile", imageName: "person.circle"),MenuItem(name:"Share Quip", imageName:"arrowshape.turn.up.right.circle"), MenuItem(name: "Report Quip", imageName: "flag.circle"),  MenuItem(name:"Cancel", imageName: "multiply.circle")]
        }
        collectionView.reloadData()
       }
}

class SettingsMenuQuip:Menu{
    
    weak var userController: ViewControllerUser?
    
    override func nextController(menuItem:MenuItem){
        
        userController?.showNextControllerSettings(menuItem: menuItem)
        
    }
    
    override func selectItem(index:Int){
       
        
        
              UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                             
                 self.blackView.alpha = 0
                 
                     let x = self.collectionView.frame.width
                            self.collectionView.frame = CGRect(x: -x, y: 0, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
                 
                     
                     
               }, completion: {(value:Bool) in
                 let menuItem = self.menuItems[index]
                 if menuItem.name != "Cancel" {
                     self.nextController(menuItem:menuItem)
                 }
               })
              
    }
    
    override func dismiss(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                       self.blackView.alpha = 0
                        
                            let x = self.collectionView.frame.width
                                   self.collectionView.frame = CGRect(x: -x, y: 0, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
                        
                    },completion:nil)
    }

    override func populateMenuItems(){
        menuItems = [MenuItem(name:"Edit Profile", imageName: "wrench"), MenuItem(name: "Privacy Policy", imageName: "doc.text"), MenuItem(name:"Report a Problem", imageName:"flag"), MenuItem(name:"Contact Us", imageName:"envelope"), MenuItem(name:"Cancel", imageName: "multiply")]
           
       }
}

class EllipsesMenuEvent:Menu{
    weak var feedController:ViewControllerFeed?
    
    override func nextController(menuItem:MenuItem){
        
        feedController?.shareEvent()
          
      }
      
     

      override func populateMenuItems(){
         
          menuItems = [MenuItem(name:"Share Event", imageName:"arrowshape.turn.up.right.circle"), MenuItem(name:"Cancel", imageName: "multiply.circle")]
          
          collectionView.reloadData()
         }
}
