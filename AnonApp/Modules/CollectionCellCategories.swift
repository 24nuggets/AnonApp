//
//  collectionCell.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/2/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

class collectionCellLiveCategories:UICollectionViewCell, UITableViewDelegate, UITableViewDataSource, MyCellDelegate3{
   
    
   
    var myLiveEvents:[Channel]=[]
   var categoryController:ViewControllerCategories?
    var isFiltered = false
    
    
    @IBOutlet weak var categoriesTable: UITableView!
    
  override func awakeFromNib() {
     super.awakeFromNib()
     categoriesTable.delegate = self
     categoriesTable.dataSource = self
   
     getLive()
  }
    func getLive(){
          self.myLiveEvents=[]
          FirestoreService.sharedInstance.getLiveEvents { (myLiveEvents) in
              self.myLiveEvents = myLiveEvents
              self.categoriesTable.reloadData()
          }
             
         }
    
    func filterSearchResults(searchText:String){
           
       }
    
    func arrowTap(cell: ChannelCells) {
        categoriesTable.selectRow(at: categoriesTable.indexPath(for: cell), animated: true, scrollPosition: .none)
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myLiveEvents.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                  
                            if let cell = categoriesTable.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as? ChannelCells{
                                           
                                    cell.channelName?.text = self.myLiveEvents[indexPath.row].channelName
                                cell.delegate = self
                                           return cell
                            }
                            
                            
                            
                       
                      
                       return UITableViewCell()
       }
       
    
}

class collectionCellSportsCategories:UICollectionViewCell, UITableViewDelegate, UITableViewDataSource, MyCellDelegate2{
   
    
   
    var mySports:[Category]=[]
       private var allSports:[Category]=[]
    var filteredCats:[Category]=[]
    var isFiltered:Bool = false
    var categoryController:ViewControllerCategories?
    
    @IBOutlet weak var categoriesTable: UITableView!
    
    override func awakeFromNib() {
       super.awakeFromNib()
       categoriesTable.delegate = self
       categoriesTable.dataSource = self
      getSports()
    }
    
   
    
    func getSports(){
        self.allSports = []
        self.mySports = []
        FirestoreService.sharedInstance.getSports { (mySports, allSports) in
            self.mySports = mySports
            self.allSports = allSports
            self.categoriesTable.reloadData()
        }
        
    }
    
    func filterSearchResults(searchText:String){
           
          isFiltered = true
          filteredCats = allSports.filter{($0.categoryName?.contains(searchText) ?? false)}
           self.categoriesTable.reloadData()
       }
    
    func arrowTapped(cell: CategoryCells) {
          categoriesTable.selectRow(at: categoriesTable.indexPath(for: cell), animated: true, scrollPosition: .none)
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if isFiltered{
                      return filteredCats.count
                  }
                  else{
                     return mySports.count
                  }
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if let cell = categoriesTable.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryCells{
                                             if isFiltered  == false{
                                               cell.categoryName.text = self.mySports[indexPath.row].categoryName
                                                 
                                             }else{
                                                 cell.categoryName.text = self.filteredCats[indexPath.row].categoryName
                                             }
                                             
                                             cell.delegate = self
                                                       return cell
                                         
                                         }
                  return UITableViewCell()
       }
       
}
    

class collectionCellEntertainmentCategories:UICollectionViewCell, UITableViewDelegate, UITableViewDataSource, MyCellDelegate2{
   
    
   
    private var allEntertainment:[Category]=[]
    var myEntertainment:[Category]=[]
   var filteredCats:[Category]=[]
    var isFiltered:Bool = false
    var categoryController:ViewControllerCategories?
    
    @IBOutlet weak var categoriesTable: UITableView!
    
    
    override func awakeFromNib() {
       super.awakeFromNib()
       categoriesTable.delegate = self
       categoriesTable.dataSource = self
     getEntertainment()
    }
 
    func getEntertainment(){
           allEntertainment = []
              self.myEntertainment=[]
           FirestoreService.sharedInstance.getEntertainment { (myEntertainment, allEntertainment) in
               self.myEntertainment = myEntertainment
               self.allEntertainment = allEntertainment
                self.categoriesTable.reloadData()
           }
              
          }
    
    func filterSearchResults(searchText:String){
           isFiltered = true
               filteredCats = allEntertainment.filter{($0.categoryName?.contains(searchText) ?? false)}
           
           self.categoriesTable.reloadData()
       }
    
    func arrowTapped(cell: CategoryCells) {
           categoriesTable.selectRow(at: categoriesTable.indexPath(for: cell), animated: true, scrollPosition: .none)
       }
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltered{
            return filteredCats.count
        }
        else{
            return myEntertainment.count
        }
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                if let cell = categoriesTable.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryCells{
                                           if isFiltered == false{
                                       cell.categoryName.text = self.myEntertainment[indexPath.row].categoryName
                                           }else{
                                           cell.categoryName.text = self.filteredCats[indexPath.row].categoryName
                                           }
                                        cell.delegate = self
                                       return cell
                                   
                                       }
              return UITableViewCell()
       }
}
