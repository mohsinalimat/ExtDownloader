//
//  Utility2.swift
//  ExtDownloader
//
//  Created by Amir Abbas on 93/10/26.
//  Copyright (c) 1393 Mousavian. All rights reserved.
//

import UIKit
import LocalAuthentication

extension Utility {
    // MARK: - User interface and interaction functions
    struct UI {
        static func alertShow(message: String, withTitle title: String, viewController: UIViewController) {
            if (NSClassFromString("UIAlertController") != nil) {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert);
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil);
                
                alert.addAction(defaultAction);
                viewController.presentViewController(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
                alert.show();
            }
        }
        
        enum AnchorView {
            case BarButtonItem(button: UIBarButtonItem)
            case View(view: UIView, frame: CGRect)
        }
        
        enum ActionButtonType {
            case Default
            case Destructive
        }
        
        struct ActionButton {
            let buttonTitle: String;
            let buttonType: ActionButtonType;
            let buttonHandler: (() -> Void)?;
            
            init(title: String, buttonType: ActionButtonType = .Default, buttonHandler: (() -> Void)? = nil) {
                self.buttonTitle = title;
                self.buttonType = buttonType;
                self.buttonHandler = buttonHandler;
            }
        }
        
        static func askAction(message: String, withTitle title: String, viewController: UIViewController, anchor: Utility.UI.AnchorView, buttons: [ActionButton]) {
            var resultText = "";
            if NSClassFromString("UIAlertController") != nil {
                let simplePrompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                    simplePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                }
                
                for button in buttons {
                    let style:UIAlertActionStyle = (button.buttonType == .Destructive) ? .Destructive : .Default
                    simplePrompt.addAction(UIAlertAction(title: button.buttonTitle, style: style, handler: { (_) -> Void in
                        button.buttonHandler?()
                        return
                    }))

                }
                
                Utility.UI.presentViewController(simplePrompt, parentViewController: viewController, anchor: anchor, size: nil, push: false);
            } else {
                let promptDelegate = ActionSheetHandler();
                var destructiveIndex = -1
                for (i, button) in enumerate(buttons) {
                    if button.buttonType == .Destructive {
                        destructiveIndex = i
                    }
                }
                let simplePrompt = UIActionSheet(title: "\(title)\n\(message)", delegate: promptDelegate, cancelButtonTitle: nil, destructiveButtonTitle: nil)
                for button in buttons {
                    simplePrompt.addButtonWithTitle(button.buttonTitle)
                }
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                    let i = simplePrompt.addButtonWithTitle("Cancel")
                    simplePrompt.cancelButtonIndex = i;
                }
                simplePrompt.destructiveButtonIndex = destructiveIndex;
                promptDelegate.completionHandler = { (actionSheet: UIActionSheet, buttonIndex: Int) -> Void in
                    if buttonIndex == simplePrompt.cancelButtonIndex {
                        promptDelegate.completionHandler = nil;
                        return
                    }
                    buttons[buttonIndex].buttonHandler?()
                    promptDelegate.completionHandler = nil;
                }
                switch anchor {
                case .BarButtonItem(button: let button): simplePrompt.showFromBarButtonItem(button, animated: true)
                case .View(view: let view, frame: let frame): simplePrompt.showFromRect(frame, inView: view, animated: true)
                }
            }
        }
        
        static func askPlain(message: String, withTitle title: String, placeHolder: String, viewController: UIViewController,completionHandler: (text: String) -> Void, defaultText: String = "") {
            var resultText = "";
            if NSClassFromString("UIAlertController") != nil {
                let simplePrompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                simplePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    textField.placeholder = placeHolder;
                    textField.text = defaultText
                })
                
                simplePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                simplePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {action in
                    resultText = (simplePrompt.textFields![0] as UITextField).text;
                    completionHandler(text: resultText)
                }))
                
                viewController.presentViewController(simplePrompt, animated: true, completion: nil);
            } else {
                let promptDelegate = AlertViewHandler()
                let simplePrompt = UIAlertView(title: title, message: message, delegate: promptDelegate, cancelButtonTitle: "Cancel", otherButtonTitles: "OK");
                simplePrompt.alertViewStyle = UIAlertViewStyle.PlainTextInput;
                simplePrompt.textFieldAtIndex(0)?.placeholder = placeHolder;
                simplePrompt.textFieldAtIndex(0)?.text = defaultText;
                promptDelegate.firstOtherHandler = { (alertView: UIAlertView) -> Void in
                    resultText = simplePrompt.textFieldAtIndex(0)!.text;
                    completionHandler(text: resultText)
                    promptDelegate.firstOtherHandler = nil;
                }
                simplePrompt.show();
            }
        }
        
        static func askUserPass(message: String, withTitle title: String, viewController: UIViewController,completionHandler: (user: String, pass: String) -> Void ) {
            var user = "", pass = "";
            if NSClassFromString("UIAlertController") != nil {
                let passwordPrompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    textField.placeholder = "User Name"
                })
                passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    textField.placeholder = "Password"
                    textField.secureTextEntry = true
                })
                
                passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {action in
                    user = (passwordPrompt.textFields![0] as UITextField).text;
                    pass = (passwordPrompt.textFields![1] as UITextField).text;
                    completionHandler(user: user, pass: pass)
                }))
                
                viewController.presentViewController(passwordPrompt, animated: true, completion: nil);
            } else {
                let promptDelegate = AlertViewHandler()
                let passwordPrompt = UIAlertView(title: title, message: message, delegate: promptDelegate, cancelButtonTitle: "Cancel", otherButtonTitles: "OK");
                passwordPrompt.alertViewStyle = UIAlertViewStyle.LoginAndPasswordInput;
                promptDelegate.firstOtherHandler = { (alertView: UIAlertView) -> Void in
                    user = passwordPrompt.textFieldAtIndex(0)!.text;
                    pass = passwordPrompt.textFieldAtIndex(1)!.text;
                    completionHandler(user: user, pass: pass)
                    promptDelegate.firstOtherHandler = nil;
                }
                passwordPrompt.show();
            }
        }
        
        static func presentViewController(viewController: UIViewController, parentViewController parentVC: UIViewController, anchor: AnchorView, size: CGSize?, push: Bool) {
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                let popOver = UIPopoverController(contentViewController: viewController);
                if size != nil {
                    viewController.preferredContentSize = size!;
                }
                switch anchor {
                case .BarButtonItem(button: let button): popOver.presentPopoverFromBarButtonItem(button, permittedArrowDirections: .Any, animated: true)
                case .View(view: let view, frame: let frame): popOver.presentPopoverFromRect(frame, inView: view, permittedArrowDirections: .Any, animated: true)
                }
            } else {
                if push {
                    parentVC.navigationController?.pushViewController(viewController, animated: true)
                } else {
                    parentVC.presentViewController(viewController, animated: true, completion: nil)
                }
            }
        }
        
        static var touchID: (available: Bool, error: LAError?) {
            if (NSClassFromString("LAContext") == nil) {
                return (false, LAError.TouchIDNotAvailable);
            }
            let myContext = LAContext()
            var authError: NSError?
            let available = myContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &authError);
            if authError == nil {
                return (available, nil)
            } else {
                return (available, LAError(rawValue: authError!.code))
            }
        }
        
        static func touchAuthenticate(reason: String, successHandler:(() -> Void), failureHandler: ((error: LAError) -> Void), localizedFallbackTitle: String = "") {
            if (NSClassFromString("LAContext") == nil) {
                return
            }
            let myContext = LAContext()
            var authError: NSError?
            let available = myContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &authError);
            if available {
                myContext.localizedFallbackTitle = localizedFallbackTitle;
                myContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: { (success, error) -> Void in
                    if success {
                        successHandler();
                    } else {
                        failureHandler(error: LAError(rawValue: error.code)!);
                    }
                })
            } else {
                failureHandler(error: LAError.TouchIDNotAvailable);
            }
        }
    }
}
