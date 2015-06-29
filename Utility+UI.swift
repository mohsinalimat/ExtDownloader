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
        enum AnchorView {
            case BarButtonItem(button: UIBarButtonItem)
            case View(view: UIView, frame: CGRect)
        }
        
        enum ButtonType {
            case Default
            case Destructive
            case Cancel
        }
        
        struct ActionButton {
            let buttonTitle: String;
            let buttonType: ButtonType;
            let buttonHandler: (() -> Void)?;
            
            init(title: String, buttonType: ButtonType = .Default, buttonHandler: (() -> Void)? = nil) {
                self.buttonTitle = title;
                self.buttonType = buttonType;
                self.buttonHandler = buttonHandler;
            }
        }
        
        struct AlertTextField {
            let placeHolder: String;
            let defaultValue: String;
            let secret: Bool;
            
            init(placeHolder: String = "", defaultValue: String = "", secret: Bool = false) {
                self.placeHolder = placeHolder;
                self.defaultValue = defaultValue;
                self.secret = secret;
            }
            
        }
        
        struct AlertButton {
            let buttonTitle: String;
            let buttonType: ButtonType;
            let buttonHandler: ((textInputs: [String]) -> Void)?;
            
            init(title: String, buttonType: ButtonType = .Default, buttonHandler: ((textInputs: [String]) -> Void)? = nil) {
                self.buttonTitle = title;
                self.buttonType = buttonType;
                self.buttonHandler = buttonHandler;
            }
        }
        
        static func askAction(message: String, withTitle title: String, viewController: UIViewController, anchor: Utility.UI.AnchorView, buttons: [ActionButton]) {
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
                
                Utility.UI.presentViewController(simplePrompt, parentViewController: viewController, anchor: anchor, size: nil, navigationPush: false);
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
                promptDelegate.cancelHandler = { (actionSheet: UIActionSheet) -> Void in
                    promptDelegate.cancelHandler = nil;
                }

                switch anchor {
                case .BarButtonItem(button: let button): simplePrompt.showFromBarButtonItem(button, animated: true)
                case .View(view: let view, frame: let frame): simplePrompt.showFromRect(frame, inView: view, animated: true)
                }
            }
        }
        
        // Please notice complicated text field combination is not suported on iOS7
        static func askAlert(message: String, withTitle title: String, viewController: UIViewController, buttons: [AlertButton], textFields : [AlertTextField]? = nil) -> Bool {
            if NSClassFromString("UIAlertController") != nil {
                let simplePrompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                if buttons.count == 0 {
                    simplePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                }
                
                if let textFields = textFields {
                    for textFieldItem in textFields {
                        simplePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                            textField.placeholder = textFieldItem.placeHolder;
                            textField.text = textFieldItem.defaultValue;
                            textField.secureTextEntry = textFieldItem.secret;
                        })
                    }
                }

                for button in buttons {
                    var style: UIAlertActionStyle;
                    switch button.buttonType {
                    case .Default: style = .Default
                    case .Destructive: style = .Destructive
                    case .Cancel:  style = .Cancel
                    }
                    simplePrompt.addAction(UIAlertAction(title: button.buttonTitle, style: style, handler: { (_) -> Void in
                        var textInputs: [String] = []
                        if let textFields = simplePrompt.textFields as? [UITextField] {
                            textInputs = textFields.map { $0.text }
                        }
                        button.buttonHandler?(textInputs: textInputs)
                        return
                    }))
                }
                
                viewController.presentViewController(simplePrompt, animated: true, completion: nil)
            } else {
                let promptDelegate = AlertViewHandler();
                let simplePrompt = UIAlertView(title: title, message: (message), delegate: promptDelegate, cancelButtonTitle: nil)
                
                if buttons.count == 0 {
                    simplePrompt.addButtonWithTitle("OK")
                }
                
                for button in buttons {
                    simplePrompt.addButtonWithTitle(button.buttonTitle)
                }
                
                var cancelIndex = -1
                for (i, button) in enumerate(buttons) {
                    if button.buttonType == .Cancel {
                        cancelIndex = i
                    }
                }
                simplePrompt.cancelButtonIndex = cancelIndex;
                
                var alertType: UIAlertViewStyle? = nil
                var textFieldsCount = 0
                
                if let textFields = textFields {
                    if textFields.count == 0 {
                        alertType = .Default
                    }
                    if textFields.count == 1 && textFields[0].secret == false {
                        alertType = .PlainTextInput
                        textFieldsCount = 1
                    }
                    if textFields.count == 1 && textFields[0].secret == true {
                        alertType = .SecureTextInput
                        textFieldsCount = 1
                    }
                    if textFields.count == 2 && textFields[0].secret == false && textFields[1].secret == true {
                        alertType = .LoginAndPasswordInput
                        textFieldsCount = 2
                    }
                    simplePrompt.alertViewStyle = alertType ?? .Default
                    for i in 0...(textFieldsCount - 1) {
                        simplePrompt.textFieldAtIndex(i)?.text = textFields[i].defaultValue
                        simplePrompt.textFieldAtIndex(i)?.placeholder = textFields[i].placeHolder
                    }

                }
                
                promptDelegate.completionHandler = { (alertView: UIAlertView, buttonIndex: Int) -> Void in
                    if buttonIndex == simplePrompt.cancelButtonIndex {
                        promptDelegate.completionHandler = nil;
                        return
                    }
                    var textInputs: [String] = []
                    for i in 0..<(textFields?.count ?? 0) {
                        if let textInput = simplePrompt.textFieldAtIndex(i)?.text {
                            textInputs.append(textInput);
                        } else {
                            textInputs.append("")
                        }
                    }
                    if buttonIndex < buttons.count {
                        buttons[buttonIndex].buttonHandler?(textInputs: textInputs)
                    }
                    promptDelegate.completionHandler = nil;
                }
                promptDelegate.cancelHandler = { (alertView: UIAlertView) -> Void in
                    promptDelegate.cancelHandler = nil;
                }
                
                simplePrompt.show()
            }
            return true;
        }
        
        static func alertShow(message: String, withTitle title: String, viewController: UIViewController) {
            askAlert(message, withTitle: title, viewController: viewController, buttons: [], textFields: nil)
        }
        
        static func askPlain(message: String, withTitle title: String, placeHolder: String, viewController: UIViewController, defaultText: String, completionHandler: (text: String) -> Void) {
            let cancelBtn = AlertButton(title: "Cancel", buttonType: ButtonType.Cancel, buttonHandler: nil)
            let okBtn = AlertButton(title: "OK", buttonType: ButtonType.Default, buttonHandler: { (textInputs) -> Void in
                completionHandler(text: textInputs[0])
            })
            let textFields = [AlertTextField(placeHolder: placeHolder, defaultValue: defaultText, secret: false)]
            askAlert(message, withTitle: title, viewController: viewController, buttons: [cancelBtn, okBtn], textFields: textFields)
        }
        
        static func askUserPass(message: String, withTitle title: String, viewController: UIViewController,completionHandler: (user: String, pass: String) -> Void ) {
            let cancelBtn = AlertButton(title: "Cancel", buttonType: ButtonType.Cancel, buttonHandler: nil)
            let okBtn = AlertButton(title: "OK", buttonType: ButtonType.Default, buttonHandler: { (textInputs) -> Void in
                completionHandler(user: textInputs[0], pass: textInputs[1])
            })
            let textFields = [AlertTextField(placeHolder: "User Name", defaultValue: "", secret: false), AlertTextField(placeHolder: "Password", defaultValue: "", secret: true)]
            askAlert(message, withTitle: title, viewController: viewController, buttons: [cancelBtn, okBtn], textFields: textFields)
        }
        
        static func presentViewController(viewController: UIViewController, parentViewController parentVC: UIViewController, anchor: AnchorView, size: CGSize?, navigationPush: Bool) -> UIPopoverController? {
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                let popOver = UIPopoverController(contentViewController: viewController);
                if size != nil {
                    viewController.preferredContentSize = size!;
                }
                switch anchor {
                case .BarButtonItem(button: let button): popOver.presentPopoverFromBarButtonItem(button, permittedArrowDirections: .Any, animated: true)
                case .View(view: let view, frame: let frame): popOver.presentPopoverFromRect(frame, inView: view, permittedArrowDirections: .Any, animated: true)
                }
                return popOver;
            } else {
                if navigationPush {
                    parentVC.navigationController?.pushViewController(viewController, animated: true)
                } else {
                    parentVC.presentViewController(viewController, animated: true, completion: nil)
                }
                return nil;
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
            if NSClassFromString("LAContext") == nil {
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
        
        static var appInBackground: Bool {
            return UIApplication.sharedApplication().applicationState == .Inactive || UIApplication.sharedApplication().applicationState == .Background
        }
    }
}


class AlertViewHandler: NSObject, UIAlertViewDelegate {
//    var firstOtherHandler: ((alertView: UIAlertView) -> Void)? = nil
    var cancelHandler: ((alertView: UIAlertView) -> Void)? = nil
    var completionHandler: ((alertView: UIAlertView, buttonIndex: Int) -> Void)? = nil
    
    
    func alertViewCancel(alertView: UIAlertView) {
        if cancelHandler !=  nil {
            cancelHandler!(alertView: alertView)
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        completionHandler?(alertView: alertView, buttonIndex: buttonIndex)
        if buttonIndex == alertView.cancelButtonIndex {
            if cancelHandler !=  nil {
                cancelHandler!(alertView: alertView)
            }
        }
    }
}

class ActionSheetHandler: NSObject, UIActionSheetDelegate {
    var completionHandler: ((actionSheet: UIActionSheet, buttonIndex: Int) -> Void)? = nil
    var cancelHandler: ((actionSheet: UIActionSheet) -> Void)? = nil
    
    func actionSheetCancel(actionSheet: UIActionSheet) {
        if cancelHandler != nil {
            cancelHandler!(actionSheet: actionSheet);
        }
        cancelHandler = nil
    }
    
    func actionSheet(actionSheet: UIActionSheet, willDismissWithButtonIndex buttonIndex: Int) {
        if completionHandler != nil {
            completionHandler!(actionSheet: actionSheet, buttonIndex: buttonIndex);
        }
    }
}
