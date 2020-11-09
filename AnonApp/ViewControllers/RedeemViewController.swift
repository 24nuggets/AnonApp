//
//  RedeemViewController.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 11/8/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class RedeemViewController: myUIViewController {
    
    
    @IBOutlet weak var nutsAvailableLbl: UILabel!
    @IBOutlet weak var nutsToRedeemTextField: UITextField!
    @IBOutlet weak var redeemBtn: UIButton!
    
    var nutsAvailable:Int = 0
    var auid:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGesture()
        self.view.backgroundColor = darktint
        hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
        redeemBtn.layer.cornerRadius = 20
        redeemBtn.clipsToBounds = true
        // Do any additional setup after loading the view.
        nutsAvailableLbl.text = "\(nutsAvailable)"
        Analytics.logEvent(AnalyticsEventSpendVirtualCurrency, parameters: nil)
    }
    
    @IBAction func redeemBtnClicked(_ sender: Any) {
        if let nutsToRedeem = Int(nutsToRedeemTextField.text ?? "0"){
            if nutsToRedeem > 0 && nutsToRedeem <= nutsAvailable{
        if let uid = auid{
        FirebaseService.sharedInstance.redeemNuts(uid: uid, nuts: nutsToRedeem) {[weak self] (isSuccess) in
            if isSuccess{
                FirestoreService.sharedInstance.enterNutsInRaffle(uid: uid, nuts: nutsToRedeem) {[weak self] (isSuccess) in
                    if isSuccess{
                        self?.displaySuccessRedeem(nuts: nutsToRedeem)
                        self?.updateNutsAvailable(nutsRedeemed: nutsToRedeem)
                    }else{
                        self?.displayErrorMsgBox()
                    }
                }
            }else{
                self?.displayErrorMsgBox()
            }
        }
        }
            }else{
                errorInvalidEntry()
            }
        }else{
            errorInvalidEntry()
        }
    }
    func updateNutsAvailable(nutsRedeemed:Int){
       nutsAvailable = nutsAvailable - nutsRedeemed
    nutsAvailableLbl.text = "\(nutsAvailable)"
        nutsToRedeemTextField.text = ""
    }
    
    func errorInvalidEntry(){
        let title = "Error"
        let message = "Please enter a valid number of nuts."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")
               
                    
              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


              @unknown default:
                print("unknown action")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func displayErrorMsgBox(){
        let title = "Error"
        let message = "There was error in redeeming your nuts, please try again. If the problem persists please contact us."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")
               
                    
              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


              @unknown default:
                print("unknown action")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    func displaySuccessRedeem(nuts:Int){
        let title = "Success"
        let message = "You have succesfully entered \(nuts) nuts in the raffle. Good luck!"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")
               
                    
              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


              @unknown default:
                print("unknown action")
            }}))
        self.present(alert, animated: true, completion: nil)
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
