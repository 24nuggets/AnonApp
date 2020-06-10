//
//  CollectionViewCellChannel.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/3/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

class CollectionViewCellChannelLive: UICollectionViewCell, MyCellDelegate3, UITableViewDelegate, UITableViewDataSource{
    
    
    
    @IBOutlet weak var channelTable: UITableView!
    
    var activeChannels:[Channel] = []
    var bigCategory:String?
    var categoryName:String?
    
    override func awakeFromNib() {
          super.awakeFromNib()
          channelTable.delegate = self
          channelTable.dataSource = self
         
       }
    
    func getActive(){
           
           self.activeChannels=[]
           
           if let aGenCat = bigCategory{
               if let aCatName = categoryName{
                   FirestoreService.sharedInstance.getActive(aGenCat: aGenCat, aCatName: aCatName) { (activeChannels) in
                       self.activeChannels = activeChannels
                         self.channelTable.reloadData()
                   }
           }
           }
           
       }
    
    func arrowTap(cell: ChannelCells) {
        channelTable.selectRow(at: channelTable.indexPath(for: cell), animated: true, scrollPosition: .none)
          }
    
    // MARK: - TableView Functions
      
      
      //gets number of sections for tableview
      func numberOfSections(in tableView: UITableView) -> Int {
          return 1
      }
      
      //returns how many cells are in table
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          
         
        return activeChannels.count
          
      }
      
      
      //populate cells in table view
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
                
         
            if  let cell = channelTable.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as? ChannelCells{
          
              if activeChannels.count > 0 {
                  cell.channelName?.text = self.activeChannels[indexPath.row].channelName
                  cell.delegate = self
              }
              return cell
              
          }
            return UITableViewCell()
      }
    
}

class CollectionViewCellChannelPast: UICollectionViewCell, MyCellDelegate3, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var channelTable: UITableView!
    
    var pastChannels:[Channel] = []
    var bigCategory:String?
    var categoryName:String?
    
    override func awakeFromNib() {
           super.awakeFromNib()
           channelTable.delegate = self
           channelTable.dataSource = self
         
        }
    
    func getPast(){
        self.pastChannels=[]
               if let aGenCat = bigCategory{
                          if let aCatName = categoryName{
                            FirestoreService.sharedInstance.getPast(aGenCat: aGenCat, aCatName: aCatName) { (pastChannels) in
                                self.pastChannels = pastChannels
                            }
                      }
                      }
        
    }
    
    func arrowTap(cell: ChannelCells) {
    channelTable.selectRow(at: channelTable.indexPath(for: cell), animated: true, scrollPosition: .none)
      }
    
    // MARK: - TableView Functions
      
      
      //gets number of sections for tableview
      func numberOfSections(in tableView: UITableView) -> Int {
          return 1
      }
      
      //returns how many cells are in table
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          
        
        return pastChannels.count
          
      }
      
      
      //populate cells in table view
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
                
        
        if let cell = channelTable.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as? ChannelCells{
         
              if pastChannels.count > 0{
                   cell.channelName?.text = self.pastChannels[indexPath.row].channelName
                  cell.delegate = self
              }
              return cell
          
          }
            return UITableViewCell()
      }
    
}

class CollectionViewCellChannelUpcoming: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var channelTable: UITableView!
    
     var upcomingChannels:[Channel] = []
    var bigCategory:String?
       var categoryName:String?
    
    override func awakeFromNib() {
           super.awakeFromNib()
           channelTable.delegate = self
           channelTable.dataSource = self
          
        }
    
    func getUpcoming(){
           self.upcomingChannels=[]
           if let aGenCat = bigCategory{
                      if let aCatName = categoryName{
                       FirestoreService.sharedInstance.getUpcoming(aGenCat: aGenCat, aCatName: aCatName) { (upcomingChannels) in
                           self.upcomingChannels = upcomingChannels
                           self.channelTable.reloadData()

                       }
                  }
                  }
           
       }
    
    
    
    
    // MARK: - TableView Functions
      
      
      //gets number of sections for tableview
      func numberOfSections(in tableView: UITableView) -> Int {
          return 1
      }
      
      //returns how many cells are in table
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          
          
        return upcomingChannels.count
          
      }
      
      
      //populate cells in table view
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
                
         
        if let cell = channelTable.dequeueReusableCell(withIdentifier: "upcomingChannelCell", for: indexPath) as? UpcomingChannelCells{
              if upcomingChannels.count > 0 {
                  cell.channelName?.text = self.upcomingChannels[indexPath.row].channelName
                  cell.startDate?.text = "Start: Date"
                  cell.selectionStyle = .none
              }
              return cell
        }
            return UITableViewCell()
      }
    
}
