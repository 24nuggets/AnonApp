//
//  ViewControllerAddFavsOne.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 6/13/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

class ViewControllerAddFavsOne: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
  
    
    private var myCats:[Category] = []
    private var filteredCats:[Category] = []
    var currentFavs:[String:Int] = [:]
    var isAddSports:Bool = false
    var myCurrentFavs:[Category] = []
    var isFiltered:Bool = false
    var uid:String?
    weak var parentVC: ViewControllerFavorites?
    
    
    @IBOutlet weak var addFavsTable: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        addFavsTable.delegate=self
        addFavsTable.dataSource=self
        searchBar.delegate=self
        loadUI()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
         parentVC?.onLoad()
    }
    func loadUI(){
        if isAddSports{
            navBar.topItem?.title = "Add Teams and Leagues"
            searchBar.placeholder = "Search Teams and Leagues"
            getSportsCategories()
        }else{
            navBar.topItem?.title = "Add Shows"
            searchBar.placeholder = "Search Shows"
           getEntertainmentCategories()
        }
    }
    
    func getEntertainmentCategories(){
        FirestoreService.sharedInstance.getEntertainment {[weak self]  (visibleEntertainment, allEntertainment) in
            self?.myCats=allEntertainment
            self?.addFavsTable.reloadData()
        }
    }
    
    func getSportsCategories(){
        FirestoreService.sharedInstance.getSports {[weak self] (visibleSports, allSports) in
            self?.myCats=allSports
            self?.addFavsTable.reloadData()
        }
    }
    
    @IBAction func doneClicked(_ sender: Any) {
       
        self.dismiss(animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
         if isSearchBarEmpty() == false{
            filterSearchResults(searchText: searchText)
             
         }else{
            isFiltered = false
            self.addFavsTable.reloadData()
         }
         
     }
     func filterSearchResults(searchText:String){
               
              isFiltered = true
              filteredCats = myCats.filter{($0.categoryName?.localizedCaseInsensitiveContains(searchText) ?? false)}
               self.addFavsTable.reloadData()
        }
    
     
     func isSearchBarEmpty()->Bool{
        return searchBar.text?.isEmpty ?? true
     }
     
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = indexPath.row
        if isFiltered{
            let aCat = filteredCats[row]
            if let auid = uid{
                if let aCatName = aCat.categoryName{
                    if let aBigCat = aCat.bigCat{
                        FirestoreService.sharedInstance.unfavoriteCatagory(aUid: auid, myCatName: aCatName, bigCategory: aBigCat)
                    }
                }
                
            }
            
            
        }else{
            let aCat = myCats[row]
                     if let auid = uid{
                         if let aCatName = aCat.categoryName{
                             if let aBigCat = aCat.bigCat{
                                 FirestoreService.sharedInstance.unfavoriteCatagory(aUid: auid, myCatName: aCatName, bigCategory: aBigCat)
                             }
                         }
                         
                     }
             
        }
        return indexPath
    }
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = indexPath.row
        if isFiltered{
            let aCat = filteredCats[row]
            if let auid = uid{
                if let aCatName = aCat.categoryName{
                    if let aBigCat = aCat.bigCat{
                        FirestoreService.sharedInstance.favoriteCatagory(aUid: auid, myCatName: aCatName, bigCategory: aBigCat)
                    }
                }
                
            }
        }else{
            let aCat = myCats[row]
            if let auid = uid{
                if let aCatName = aCat.categoryName{
                    if let aBigCat = aCat.bigCat{
                        FirestoreService.sharedInstance.favoriteCatagory(aUid: auid, myCatName: aCatName, bigCategory: aBigCat)
                    }
                }
                
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        if isFiltered{
            return filteredCats.count
        }else{
             return myCats.count
        }
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = addFavsTable.dequeueReusableCell(withIdentifier: "addFav", for: indexPath)
        var catName = ""
        if isFiltered{
            if let myCatName = filteredCats[indexPath.row].categoryName{
            catName=myCatName
            cell.textLabel?.text = filteredCats[indexPath.row].categoryName
            }
        }else{
            if let myCatName = myCats[indexPath.row].categoryName{
                catName = myCatName
                 cell.textLabel?.text = myCats[indexPath.row].categoryName
            }
        }
        if currentFavs[catName] != nil {
            self.addFavsTable.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        return cell
      }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
