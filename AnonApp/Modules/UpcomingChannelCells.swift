//
//  UpcomingChannelCells.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 4/11/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

protocol MyCellDelegate: AnyObject {
    func btnUpTapped(cell: QuipCells)
    func btnDownTapped(cell: QuipCells)
    func btnSharedTapped(cell: QuipCells)
}

class UpcomingChannelCells: UITableViewCell {

    @IBOutlet weak var channelName: UILabel!
    

}

class QuipCells:UITableViewCell{
    
    @IBOutlet weak var quipText: UILabel!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var timePosted: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    weak var delegate: MyCellDelegate?
    
    @IBAction func btnUpTapped(_ sender: Any) {
        
        delegate?.btnUpTapped(cell: self)
    }
    
    @IBAction func btnDownTapped(_ sender: Any) {
        
         delegate?.btnDownTapped(cell: self)
    }
    
    @IBAction func btnSharedTapped(_ sender: Any) {
        
         delegate?.btnSharedTapped(cell: self)
    }
    
    
    
    
}

