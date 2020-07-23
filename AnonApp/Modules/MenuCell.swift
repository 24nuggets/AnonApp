//
//  MenuCell.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 5/27/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

class BaseCell:UICollectionViewCell{
    
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews(){
       
    }
    
}





class MenuCellWithIcon: BaseCell{
    
    override var isHighlighted: Bool{
        didSet{
            backgroundColor = isHighlighted ? .darkGray : .white
            nameLabel.textColor = isHighlighted ? .white : .darkGray
            iconImageView.tintColor = isHighlighted ? .white : .darkGray
        }
    }
    
    var MenuItem:MenuItem? {
        didSet{
            nameLabel.text = MenuItem?.name
            nameLabel.textColor = .darkGray
            if let imageName = MenuItem?.imageName{
                let image = UIImage(named: imageName)
                
                iconImageView.image = image?.withRenderingMode(.alwaysTemplate)
                iconImageView.tintColor = .darkGray
            }
        }
    }
    
    let nameLabel: UILabel = {
           let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
           return label
       }()
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(nameLabel)
        addSubview(iconImageView)
        
        addConstraintWithFormat(format: "H:|-10-[v0(20)]-8-[v1]|", views: iconImageView,nameLabel)
        addConstraintWithFormat(format: "V:|[v0]|", views: nameLabel)
        addConstraintWithFormat(format: "V:[v0(20)]", views: iconImageView)
        iconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
    }
}
