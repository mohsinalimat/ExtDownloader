//
//  Utility2.swift
//  ExtDownloader
//
//  Created by Amir Abbas on 93/10/26.
//  Copyright (c) 1393 Mousavian. All rights reserved.
//

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
            var placeHolder: String;
            var defaultValue: String;
            var textInputTraits: UITextInputTraits;
            var selectedRange: Range<Int>? = nil;
            
            init(placeHolder: String = "", defaultValue: String = "", textInputTraits: UITextInputTraits = TextInputTraits()) {
                self.placeHolder = placeHolder;
                self.defaultValue = defaultValue;
                self.textInputTraits = textInputTraits;
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
        
        static func isRegularPad(viewController: UIViewController) -> Bool {
            if #available(iOS 8, *) {
                return UIDevice.currentDevice().userInterfaceIdiom == .Pad && viewController.traitCollection.horizontalSizeClass != .Compact
            } else {
                return  UIDevice.currentDevice().userInterfaceIdiom == .Pad
            }
        }
        
        static func askAction(message: String, withTitle title: String, viewController: UIViewController, anchor: Utility.UI.AnchorView, buttons: [ActionButton]) {
            if #available(iOS 8, *) {
                let simplePrompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
                if !isRegularPad(viewController) {
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
                for (i, button) in buttons.enumerate() {
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
            if #available(iOS 8, *) {
                let simplePrompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                var textFieldsUI: [UITextField] = []
                if buttons.count == 0 {
                    simplePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                }
                
                if let textFields = textFields {
                    for textFieldItem in textFields {
                        simplePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField) in
                            textField.placeholder = textFieldItem.placeHolder;
                            textField.text = textFieldItem.defaultValue;
                            textField.secureTextEntry = textFieldItem.textInputTraits.secureTextEntry ?? false
                            textField.keyboardType = textFieldItem.textInputTraits.keyboardType ?? .Default
                            textField.returnKeyType = textFieldItem.textInputTraits.returnKeyType ?? .Default
                            textField.keyboardAppearance = textFieldItem.textInputTraits.keyboardAppearance ?? .Default
                            textField.spellCheckingType = textFieldItem.textInputTraits.spellCheckingType ?? .Default
                            textField.autocapitalizationType = textFieldItem.textInputTraits.autocapitalizationType ?? .None
                            textField.autocorrectionType = textFieldItem.textInputTraits.autocorrectionType ?? .Default
                            textField.enablesReturnKeyAutomatically = textFieldItem.textInputTraits.enablesReturnKeyAutomatically ?? false
                            textFieldsUI.append(textField)
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
                        if let textFields = simplePrompt.textFields {
                            textInputs = textFields.map { $0.text ?? "" }
                        }
                        button.buttonHandler?(textInputs: textInputs)
                        return
                    }))
                }
                
                viewController.presentViewController(simplePrompt, animated: true, completion: {
                    for (i, textFieldItem) in (textFields ?? []).enumerate() {
                        if let range = textFieldItem.selectedRange, start = textFieldsUI[i].positionFromPosition(textFieldsUI[i].beginningOfDocument, offset: range.startIndex), end = textFieldsUI[i].positionFromPosition(start, offset: range.endIndex) {
                            textFieldsUI[i].selectedTextRange = textFieldsUI[i].textRangeFromPosition(start, toPosition: end)
                        }
                    }
                })
                
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
                for (i, button) in buttons.enumerate() {
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
                    if textFields.count == 1 && textFields[0].textInputTraits.secureTextEntry == false {
                        alertType = .PlainTextInput
                        textFieldsCount = 1
                    }
                    if textFields.count == 1 && textFields[0].textInputTraits.secureTextEntry == true {
                        alertType = .SecureTextInput
                        textFieldsCount = 1
                    }
                    if textFields.count == 2 && textFields[0].textInputTraits.secureTextEntry == false && textFields[1].textInputTraits.secureTextEntry == true {
                        alertType = .LoginAndPasswordInput
                        textFieldsCount = 2
                    }
                    simplePrompt.alertViewStyle = alertType ?? .Default
                    for i in 0...(textFieldsCount - 1) {
                        if let textField = simplePrompt.textFieldAtIndex(i) {
                            let textFieldItem = textFields[i]
                            textField.text = textFieldItem.defaultValue
                            textField.placeholder = textFieldItem.placeHolder
                            textField.secureTextEntry = textFieldItem.textInputTraits.secureTextEntry ?? false
                            textField.keyboardType = textFieldItem.textInputTraits.keyboardType ?? .Default
                            textField.returnKeyType = textFieldItem.textInputTraits.returnKeyType ?? .Default
                            textField.keyboardAppearance = textFieldItem.textInputTraits.keyboardAppearance ?? .Default
                            textField.spellCheckingType = textFieldItem.textInputTraits.spellCheckingType ?? .Default
                            textField.autocapitalizationType = textFieldItem.textInputTraits.autocapitalizationType ?? .None
                            textField.autocorrectionType = textFieldItem.textInputTraits.autocorrectionType ?? .Default
                            textField.enablesReturnKeyAutomatically = textFieldItem.textInputTraits.enablesReturnKeyAutomatically ?? false
                            if let range = textFields[i].selectedRange, start = textField.positionFromPosition(textField.beginningOfDocument, offset: range.startIndex), end = textField.positionFromPosition(start, offset: range.endIndex - range.startIndex) {
                                textField.selectedTextRange = textField.textRangeFromPosition(start, toPosition: end)
                            }
                        }
                        
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
            let textFields = [AlertTextField(placeHolder: placeHolder, defaultValue: defaultText)]
            askAlert(message, withTitle: title, viewController: viewController, buttons: [cancelBtn, okBtn], textFields: textFields)
        }
        
        static func askUserPass(message: String, withTitle title: String, viewController: UIViewController,completionHandler: (user: String, pass: String) -> Void ) {
            let cancelBtn = AlertButton(title: "Cancel", buttonType: ButtonType.Cancel, buttonHandler: nil)
            let okBtn = AlertButton(title: "OK", buttonType: ButtonType.Default, buttonHandler: { (textInputs) -> Void in
                completionHandler(user: textInputs[0], pass: textInputs[1])
            })
            let textFields = [AlertTextField(placeHolder: "User Name"), AlertTextField(placeHolder: "Password", defaultValue: "", textInputTraits: TextInputTraits.secretInput())]
            askAlert(message, withTitle: title, viewController: viewController, buttons: [cancelBtn, okBtn], textFields: textFields)
        }
        
        static func presentViewController(viewController: UIViewController, parentViewController parentVC: UIViewController, anchor: AnchorView, size: CGSize?, navigationPush: Bool) -> UIPopoverController? {
            if isRegularPad(parentVC) {
                if #available(iOS 8, *) {
                    viewController.modalPresentationStyle = UIModalPresentationStyle.Popover
                    parentVC.presentViewController(viewController, animated: true, completion: nil)
                    let popOver = viewController.popoverPresentationController;
                    popOver?.permittedArrowDirections = .Any
                    switch anchor {
                    case .BarButtonItem(button: let button):
                        popOver?.barButtonItem = button
                    case .View(view: let view, frame: let frame):
                        popOver?.sourceView = view
                        popOver?.sourceRect = frame
                    }
                    return nil
                } else {
                    let popOver = UIPopoverController(contentViewController: viewController);
                    if size != nil {
                        viewController.preferredContentSize = size!;
                    }
                    switch anchor {
                    case .BarButtonItem(button: let button):
                        popOver.presentPopoverFromBarButtonItem(button, permittedArrowDirections: .Any, animated: true)
                    case .View(view: let view, frame: let frame):
                        popOver.presentPopoverFromRect(frame, inView: view, permittedArrowDirections: .Any, animated: true)
                    }
                    return popOver;
                }
            } else {
                if navigationPush {
                    parentVC.navigationController?.pushViewController(viewController, animated: true)
                } else {
                    parentVC.presentViewController(viewController, animated: true, completion: nil)
                }
                return nil;
            }
        }
        
        static func showCommentOnView(view: UIView, comment: String = "") {
            while let commentView = view.viewWithTag(1001) {
                commentView.removeFromSuperview();
            }
            if !comment.isEmpty {
                // Comment View
                let commentView = UIView();
                commentView.tag = 1001;
                commentView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(commentView);
                view.bringSubviewToFront(commentView)
                view.addConstraint(NSLayoutConstraint(item: commentView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
                view.addConstraint(NSLayoutConstraint(item: commentView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
                view.addConstraint(NSLayoutConstraint(item: commentView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
                view.addConstraint(NSLayoutConstraint(item: commentView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
                // Comment Label
                let commentLabel = UILabel();
                commentLabel.text = comment
                commentLabel.textAlignment = NSTextAlignment.Center;
                commentLabel.textColor = UIColor.grayColor();
                commentLabel.numberOfLines = 0;
                commentLabel.lineBreakMode = .ByWordWrapping
                commentLabel.tag = 1001;
                commentLabel.translatesAutoresizingMaskIntoConstraints = false
                commentView.addSubview(commentLabel);
                commentView.addConstraint(NSLayoutConstraint(item: commentLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: commentView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 20))
                commentView.addConstraint(NSLayoutConstraint(item: commentLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: commentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
                commentView.addConstraint(NSLayoutConstraint(item: commentLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: commentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
                commentView.addConstraint(NSLayoutConstraint(item: commentLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: commentView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 20))
            }
        }
        
        @available(iOS 8.0, *)
        static var touchID: (available: Bool, error: LAError?) {
            let myContext = LAContext()
            var authError: NSError?
            let available: Bool
            if myContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &authError) {
                available = true
            } else {
                available = false
            };
            if let authError = authError {
                return (available, LAError(rawValue: authError.code))
            } else {
                return (available, nil)
            }
        }
        
        @available(iOS 8.0, *)
        static func touchAuthenticate(reason: String, successHandler:(() -> Void), failureHandler: ((error: LAError) -> Void), localizedFallbackTitle: String = "") {
            let myContext = LAContext()
            var authError: NSError?
            if  myContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &authError) {
                myContext.localizedFallbackTitle = localizedFallbackTitle;
                myContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: { (success, error) -> Void in
                    if success {
                        successHandler();
                    } else {
                        failureHandler(error: LAError(rawValue: authError?.code ?? 0) ?? LAError.TouchIDNotAvailable);
                    }
                })
            } else {
                failureHandler(error: LAError.TouchIDNotAvailable);
            };
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
