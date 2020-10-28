//
//  ViewControllerCreateAccount.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 8/26/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class ViewControllerCreateAccount: myUIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet var topView: UIView!
    
    @IBOutlet weak var linkEmailButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGesture()
        topView.backgroundColor = darktint
        hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
        linkEmailButton.layer.cornerRadius = 20
        linkEmailButton.clipsToBounds = true
    }
    override func viewDidAppear(_ animated: Bool) {
        emailTextField.becomeFirstResponder()
        emailTextField.selectedTextRange = emailTextField.textRange(from: emailTextField.beginningOfDocument, to: emailTextField.beginningOfDocument)
        emailTextField.textColor = .label
        //take this out after testing
        DynamicLinks.performDiagnostics(completion: nil)
    }
    
    
    @IBAction func createAccountClicked(_ sender: Any) {
        if let email1 = emailTextField.text{
            
            let email = email1.trimmingCharacters(in: .whitespacesAndNewlines)
       UserDefaults.standard.set(email, forKey: "Email")
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://anonapp.page.link")
        // The sign-in operation has to always be completed in the app.
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        Auth.auth().sendSignInLink(toEmail:email,
                                   actionCodeSettings: actionCodeSettings) { error in
          // ...
            if let error = error {
                self.showMessagePrompt(message:error.localizedDescription)
              return
            }
            // The link was successfully sent. Inform the user.
            // Save the email locally so you don't need to ask the user for it again
            // if they open the link on the same device.
            
            Analytics.logEvent(AnalyticsEventLogin, parameters: [:])
            self.showMessagePrompt(message:"Check your email for link. If it does not show up in 1 minute, check your junk folder.")
           
        }
            
        }else {
            self.showMessagePrompt(message:"Email can't be empty")
        }
        
    }
    
    func showMessagePrompt(message:String){
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
    
    func displayMsgBoxPasswordMisMatch(){
       let title = "Password Mismatch"
       let message = "The passwords do not match."
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
