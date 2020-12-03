//
//  VerifyViewController.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 11/23/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import MailchimpSDK
import Firebase

class VerifyViewController: myUIViewController {
    
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var textfield1: UITextField!
    @IBOutlet weak var textfield2: UITextField!
    @IBOutlet weak var textfield3: UITextField!
    @IBOutlet weak var textfield4: UITextField!
    @IBOutlet weak var textfield5: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = darktint
       addGesture()
        // Do any additional setup after loading the view.
        submitBtn.layer.cornerRadius = 20
        submitBtn.clipsToBounds = true
        textfield1.delegate = self
        textfield2.delegate = self
        textfield3.delegate = self
        textfield4.delegate = self
        textfield5.delegate = self
        textfield1.becomeFirstResponder()
    }
    

    @IBAction func submitClicked(_ sender: Any) {
        let userEnteredCode1 = (textfield1.text ?? "") + (textfield2.text ?? "") + (textfield3.text ?? "")
        let userEnteredCode2 = (textfield4.text ?? "") + (textfield5.text ?? "")
        let userCode = userEnteredCode1 + userEnteredCode2
        FirestoreService.sharedInstance.checkVerificationCode(uid: UserDefaults.standard.string(forKey: "UID")!, code: userCode) {[weak self] (isCorrect) in
            if isCorrect{
                guard let email = UserDefaults.standard.string(forKey: "Email") else {return }
                guard let uid = UserDefaults.standard.string(forKey: "UID") else { return  }
                UserDefaults.standard.set(email, forKey: "EmailConfirmed")
                if email == "matthewcapriotti4@gmail.com" || email == "jmichaelthompson96@gmail.com"{
                    UserDefaults.standard.set(true, forKey: "isAdmin")
                }
                
                //window?.rootViewController?.children[0].performSegue(withIdentifier: "passwordless", sender: nil)
                let components = email.components(separatedBy: "@")
                let schoolEmailEnd = components[1]
                Analytics.setUserProperty(schoolEmailEnd, forName: "School")
                Analytics.logEvent(AnalyticsEventSignUp, parameters: [
                AnalyticsParameterItemID: schoolEmailEnd,
                AnalyticsParameterItemName: "School",
                AnalyticsParameterContentType: "cont"
                ])
                UserDefaults.standard.removeObject(forKey: "HomeSchool")
                FirestoreService.sharedInstance.getUniversities {[weak self](schools) in
                    for school in schools{
                        if let schoolEmail = school.aemail{
                        if schoolEmailEnd == schoolEmail{
                            if Core.shared.isKeyPresentInUserDefaults(key: "invitedby") && !UserDefaults.standard.bool(forKey: "beenReferred"){
                                if let referer = UserDefaults.standard.string(forKey: "invitedby"){
                                FirebaseService.sharedInstance.addNutsForReferral(uid: referer)
                                    UserDefaults.standard.setValue(true, forKey: "beenReferred")
                                }
                            }
                            
                            UserDefaults.standard.set(school.channelName, forKey: "HomeSchool")
                            break
                        }
                    }
                    }
                }
                do{
                    try Mailchimp.initialize(token: "2059e91faea42aa5a8ea67c9b1874d82-us2")
                }
                catch{
                    print("error initializing mailchimp")
                }
                Mailchimp.addTag(name: "SignedUp", emailAddress: email)
                              
               
                self?.displayMsgBoxEmailLink(email: email)
            }else{
                self?.showMessagePrompt2(message: "The verification code you have entered is not correct.")
            }
        }
        
    }
    func displayMsgBoxEmailLink(email:String){
          let title = "Email Link Successful"
          let message = "\(email) has been successfully linked to your account."
          let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                switch action.style{
                case .default:
                      print("default")
                    self.navigationController?.popToRootViewController(animated: false)
                      
                case .cancel:
                      print("cancel")

                case .destructive:
                      print("destructive")


                @unknown default:
                  print("unknown action")
              }}))
           
        
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
      }
    func showMessagePrompt2(message:String){
          let title = "Alert"
          
          let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
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

extension VerifyViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !(string == "") {
            textField.text = string
            if textField == textfield1 {
                textfield2.becomeFirstResponder()
            }
            else if textField == textfield2 {
                textfield3.becomeFirstResponder()
            }
            else if textField == textfield3 {
                textfield4.becomeFirstResponder()
            }
            else if textField == textfield4 {
                textfield5.becomeFirstResponder()
            }
            else {
                textField.resignFirstResponder()
            }
            return false
        }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if (textField.text?.count ?? 0) > 0 {
            
        }
        return true
    }
}
