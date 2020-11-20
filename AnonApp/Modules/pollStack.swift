//
//  pollStack.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 11/10/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit

class pollStack: UIStackView {

    
    var votesData:[Double]?
    var total:Double = 0
    var button1:UIButton?
    var button2:UIButton?
    var button3:UIButton?
    var button4:UIButton?
    var selectedBtnInt:Int?
    var crackKey:String?
    var voteOptions:[String]?
  
    
    
    func addOptions(options:[String]){
        let count = options.count
        voteOptions = options
        var isCached = false
        if let cachePoll = pollCache.object(forKey: crackKey! as NSString) as? Poll{
            isCached = true
            
        }
        if count > 0{
           
            button1 = UIButton()
            if !isCached{
            button1?.backgroundColor = .quaternaryLabel
            }
            button1?.setTitle(options[0], for: .normal)
            button1?.setTitleColor(.label, for: .normal)
         
            button1?.layer.cornerRadius = 10
            button1?.clipsToBounds = true
            button1?.addTarget(self, action: #selector(self.buttonClicked(_:)), for: .touchUpInside)
           
            self.addArrangedSubview(button1!)
            
        }
        if count > 1{
            button2 = UIButton()
            if !isCached{
            button2?.backgroundColor = .quaternaryLabel
            }
            button2?.setTitle(options[1], for: .normal)
            button2?.setTitleColor(.label, for: .normal)
          
            button2?.layer.cornerRadius = 10
            button2?.clipsToBounds = true
            button2?.addTarget(self, action: #selector(self.buttonClicked(_:)), for: .touchUpInside)
            self.addArrangedSubview(button2!)
        }
        if count > 2{
            button3 = UIButton()
            if !isCached{
            button3?.backgroundColor = .quaternaryLabel
            }
            button3?.setTitle(options[2], for: .normal)
            button3?.setTitleColor(.label, for: .normal)
           
            button3?.layer.cornerRadius = 10
            button3?.clipsToBounds = true
            button3?.addTarget(self, action: #selector(self.buttonClicked(_:)), for: .touchUpInside)
            self.addArrangedSubview(button3!)
        }
        if count > 3{
            button4 = UIButton()
            if !isCached{
            button4?.backgroundColor = .quaternaryLabel
            }
            button4?.setTitle(options[3], for: .normal)
            button4?.setTitleColor(.label, for: .normal)
         
            button4?.layer.cornerRadius = 10
            button4?.clipsToBounds = true
            button4?.addTarget(self, action: #selector(self.buttonClicked(_:)), for: .touchUpInside)
            self.addArrangedSubview(button4!)
        }
        if let cachePoll = pollCache.object(forKey: crackKey! as NSString) as? Poll{
            let selectedBtn = cachePoll.selected
            self.votesData = cachePoll.votes
            if selectedBtn == 1 {
                self.selectButton(selectedBtn: (button1)!, isCached: true)
            }else if selectedBtn == 2{
                self.selectButton(selectedBtn: (button2)!,  isCached: true)
            }else if selectedBtn == 3 {
                self.selectButton(selectedBtn: (button3)!,  isCached: true)
            }else if selectedBtn == 4 {
                self.selectButton(selectedBtn: (button4)!,  isCached: true)
            }
            
        }
        
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
  @objc func buttonClicked(_ sender: AnyObject?) {
   
      if sender === button1 {
        selectedBtnInt = 1
        selectButton(selectedBtn: button1!, isCached:false)
       // button1?.layer.insertSublayer(gradient1!, at: 0)
        
        // do something
      } else if sender === button2 {
        selectedBtnInt = 2
        selectButton(selectedBtn: button2!, isCached:false)
        
        // do something
      } else if sender === button3 {
        selectedBtnInt = 3
        selectButton(selectedBtn: button3!,isCached:false)
        
        // do something
      } else if sender === button4 {
        selectedBtnInt = 4
        selectButton(selectedBtn: button4!,isCached: false)
        
        
      }
    
    }
    
    func selectButton(selectedBtn:UIButton, isCached: Bool){
        
       
        if var myVotes = votesData{
            if let currentSelection = selectedBtnInt{
                button1?.isEnabled = false
                button2?.isEnabled = false
                button3?.isEnabled = false
                button4?.isEnabled = false
                myVotes[currentSelection - 1] = myVotes[currentSelection - 1] + 1
                if let acrackKey = crackKey{
                   
                DynamoService.sharedInstance.addUserVote(key: acrackKey, uid: UserDefaults.standard.string(forKey: "UID")!, vote: currentSelection)
                }
            }
            
        for x in myVotes{
            total = total + x
        }
            DispatchQueue.main.async {
                if self.button1 != nil{
                    let dataValue = myVotes[0] / self.total
      
                    self.setGradient(dataValue: dataValue, button: self.button1!, isCache: isCached, buttonIndex: 0)
            
        }
        
                if self.button2 != nil{
                    let dataValue = myVotes[1] / self.total
           
                    self.setGradient(dataValue: dataValue, button: self.button2!,isCache: isCached, buttonIndex: 1)
        }
            
                if self.button3 != nil{
                    let dataValue = myVotes[2] / self.total
           
                    self.setGradient(dataValue: dataValue, button: self.button3!,isCache: isCached, buttonIndex: 2)
        }
        
                if self.button4 != nil{
                    let dataValue = myVotes[3] / self.total
           
                    self.setGradient(dataValue: dataValue, button: self.button4!,isCache: isCached, buttonIndex: 3)
        }
 
        
            selectedBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            selectedBtn.layer.borderWidth = 2
            selectedBtn.layer.borderColor = UIColor(hexString: "ffaf46").cgColor
                var selection = 0
                if selectedBtn == self.button1{
                    selection = 1
                }else if selectedBtn == self.button2{
                    selection = 2
                }else if selectedBtn == self.button3{
                    selection = 3
                }else if selectedBtn == self.button4{
                    selection = 4
                }
                let data = Poll(avotes: myVotes, aselected: selection)
                pollCache.setObject(data, forKey: self.crackKey! as NSString)
                
            }
        }
    }
    
    func setGradient(dataValue:Double, button:UIButton, isCache: Bool, buttonIndex:Int){
        let gradient1 = CAGradientLayer()
        let newColors = [
            UIColor(hexString: "ffaf46").cgColor,
            UIColor(hexString: "ffaf46").cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor
           
        ]
        
        gradient1.colors = newColors

        /* repeat the central location to have solid colors */
        gradient1.locations = [0, NSNumber(value: dataValue), NSNumber(value: dataValue), 1.0]
        
        /* make it horizontal */
        gradient1.frame = self.bounds
        gradient1.startPoint = CGPoint.zero
        gradient1.endPoint = CGPoint(x: 1, y: 0)
        button.backgroundColor = .clear
        if !isCache{
        let animation = CABasicAnimation(keyPath: "position")
        let buttonWidth = (self.bounds.width)
        animation.fromValue = [0, button.bounds.height / 2]
       
        animation.toValue = [buttonWidth / 2, button.bounds.height / 2]
        animation.isRemovedOnCompletion = true
        animation.duration = 0.5
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        gradient1.add(animation, forKey: "myAnimation")
        }
        button.layer.insertSublayer(gradient1, at: 0)
        
        let formattedValue = String(format: "%.1f", dataValue * 100)
        let amount = formattedValue + "%"
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        var i = 1
        button.setTitle(voteOptions?[buttonIndex], for: .normal)
        let origTitle = (button.title(for: .normal))!
        while true {
           
            var paddedString = String(repeating: " ", count: i) + amount
            var newTitle = origTitle + paddedString
            button.setTitle(newTitle, for: .normal)
            
            if countLabelLines(button: button) > button.titleLabel!.numberOfLines{
                if i - 4 < 0 {
                paddedString = String(repeating: " ", count: 0) + amount
                }else{
                paddedString = String(repeating: " ", count: i - 4) + amount
                }
                newTitle = origTitle + paddedString
                
                button.setTitle(newTitle, for: .normal)
                break
            }
            i = i + 1
        }
        
    }
    
    func countLabelLines(button:UIButton) -> Int {
        // Call self.layoutIfNeeded() if your view is uses auto layout
        let myText = (button.titleLabel?.text!)! as NSString
        let attributes = [NSAttributedString.Key.font : button.titleLabel!.font]

        let labelSize = myText.boundingRect(with: CGSize(width: button.bounds.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes as [NSAttributedString.Key : Any], context: nil)
        return Int(ceil(CGFloat(labelSize.height) / button.titleLabel!.font.lineHeight))
    }
    
}
