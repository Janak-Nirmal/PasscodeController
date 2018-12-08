//
//  LockerViewController.swift
//  PasscodeController
//
//  Created by Janak Nirmal on 08/12/18.
//  Copyright © 2018 Janak Nirmal. All rights reserved.
//

import UIKit
import AudioToolbox

class Indicator: UILabel {
    var isNeedClear = false
}

extension UIView {
    func shake(delegate: CAAnimationDelegate) {
        let animationKeyPath = "transform.translation.x"
        let shakeAnimation = "shake"
        let duration = 0.6
        let animation = CAKeyframeAnimation(keyPath: animationKeyPath)
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        animation.delegate = delegate
        layer.add(animation, forKey: shakeAnimation)
    }
}

public enum Constants {
    static let nibName = "LockerViewController"
    static let animationDuration = 0.3
    static let pinLength = 4
}

public enum PasscodeMode {
    case verify
    case change
    case create
    case deactivate
    
    var message : String {
        switch self {
        case .verify, .change, .deactivate:
            return "Enter your current passcode"
        case .create:
            return "This passcode will be used to unlock your Smart Safe"
        }
    }
}

public struct LockerAppearance {
    public var image : UIImage = UIImage(named: "face")!
    public var message : String = "Enter your passcode"
    public var messageTextColor : UIColor = UIColor.black
    public var viewBackgroundColor : UIColor = UIColor(red:0.93, green:0.94, blue:0.96, alpha:1.00)
    public var containerBackgroundColor : UIColor = UIColor.white
    public var containerBorderColor : UIColor = UIColor.white
    public var pinTextColor : UIColor = UIColor.black
    public var incorrectInputColor : UIColor = UIColor.red
    public init() {}
}


public class LockerViewController: UIViewController {

    /// Top Image to display
    @IBOutlet weak var topImageView: UIImageView!
    
    /// Message for user
    @IBOutlet weak var messageLabel: UILabel!

    /// StackView Containing Digits Container View
    @IBOutlet weak var digitsStackView: UIStackView!

    /// StackView Leading Constraint
    @IBOutlet weak var digitsLeadingConstraint: NSLayoutConstraint!
    
    /// StackView Trailing Constraint
    @IBOutlet weak var digitsTrailingConstraint: NSLayoutConstraint!
    
    /// Digits Container View
    @IBOutlet var pinIndicatorsContainer: [UIView]!

    /// Digits Container View
    @IBOutlet var pinIndicators: [Indicator]!

    /// Appearance instance
    var appearance : LockerAppearance! = nil

    /// Used for user input
    let textField : UITextField = UITextField(frame: CGRect.zero)

    /// Used for keeping keyboard open till this controller is on screen
    var isOnScreen : Bool = false

    /// Used verification or change pin
    private var savedPin: String? {  // Saved pin from keychain to confirm
        get {
            return "1212" //Read from Keychain
        }
        set {
            guard let newValue = newValue else { return }
            //Add code to save to keychain
        }
    }
    
    /// String containing current user input
    private var userEnteredPin = "" // Entered pincode

    /// String containing current user input in case of confirmation
    private var reservedPinForConfirm = ""
    
    /// Used to identify if user input is asked for first time - to conclude mode
    private var isFirstCreationStep = true
    
    /// Start Passcode Mode
    var startMode: PasscodeMode = .verify
    
    /// Maintain Current Mode of Passcode
    fileprivate var mode: PasscodeMode? {
        didSet {
            let mode = self.mode ?? .verify
            messageLabel.text = mode.message
            if mode == .verify {
                isFirstCreationStep = false
            }
        }
    }
    
    /// Configure appearance for elements
    private func configureAppearance(){
        self.view.backgroundColor = appearance.viewBackgroundColor
        messageLabel.text = appearance.message
        messageLabel.textColor = appearance.messageTextColor
        topImageView.image = appearance.image
        pinIndicators.forEach { view in
            view.textColor = appearance.pinTextColor
        }
        pinIndicatorsContainer.forEach { view in
            view.backgroundColor = appearance.containerBackgroundColor
            view.layer.borderColor = appearance.containerBorderColor.cgColor
        }
    }
    
    /// Configure text field for user input
    private func configureTextField(){
        textField.isSecureTextEntry = true
        textField.keyboardType = .numberPad
        textField.delegate = self
        view.addSubview(textField)
        textField.becomeFirstResponder()
    }
 
    /// Update UI when user input value
    private func updateUI(isNeedClear: Bool, tag: Int? = nil) { // Fill or cancel fill for indicators
        let results = pinIndicators.filter { $0.isNeedClear == isNeedClear }
        let pinView = isNeedClear ? results.last : results.first
        pinView?.isNeedClear = !isNeedClear
        
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            pinView?.text = isNeedClear ? "" : String(describing: tag!)
        }) { _ in
            isNeedClear ? self.userEnteredPin = String(self.userEnteredPin.dropLast()) : self.pincodeChecker(tag ?? 0)
        }
    }
    
    /// Check current input and decide next step
    private func pincodeChecker(_ pinNumber: Int) {
        if userEnteredPin.count < Constants.pinLength {
            userEnteredPin.append("\(pinNumber)")
            if userEnteredPin.count == Constants.pinLength {
                switch mode ?? .verify {
                case .create:
                    createModeAction()
                case .change:
                    changeModeAction()
                case .deactivate:
                    deactiveModeAction()
                case .verify:
                    validateModeAction()
                }
            }
        }
    }
    
    /// Create Passcode Mode action
    private func createModeAction() {
        if isFirstCreationStep {
            isFirstCreationStep = false
            reservedPinForConfirm = userEnteredPin
            clearView()
            messageLabel.text = "Confirm your pincode"
            textField.text = ""
        } else {
            confirmPin()
        }
    }
    
    /// Change Passcode Mode action
    private func changeModeAction() {
        userEnteredPin == savedPin ? precreateSettings() : incorrectPinAnimation()
    }
    
    /// Deactivate Passcode Mode action
    private func deactiveModeAction() {
        userEnteredPin == savedPin ? removePin() : incorrectPinAnimation()
    }
    
    /// Remove Passcode Mode action
    private func removePin() {
        // Add code to remove from Keychain
        dismissController()
    }
    
    /// Validate Passcode Mode action
    private func validateModeAction() {
        userEnteredPin == savedPin ? dismissController() : incorrectPinAnimation()
    }
    
    /// Dismiss controller once finished
    private func dismissController(){
        isOnScreen = false
        textField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    /// Reset function when mode is changed
    private func precreateSettings () {
        mode = .create
        clearView()
        textField.text = ""
    }
    
    /// Clear current user input and on screen input
    fileprivate func clearView() {
        userEnteredPin = ""
        pinIndicators.forEach { view in
            view.isNeedClear = false
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                view.backgroundColor = .clear
                view.text = ""
            })
        }
    }
    
    /// Confirm pin for create passcode
    private func confirmPin() {
        if userEnteredPin == reservedPinForConfirm {
            savedPin = userEnteredPin
            dismissController()
        } else {
            incorrectPinAnimation()
        }
    }
    
    /// User entered incorrect passcode
    private func incorrectPinAnimation() {
        textField.text = ""
        
        messageLabel.text = "Unable to verify passcode, Please try again."
        messageLabel.textColor = appearance.incorrectInputColor
        
        pinIndicators.forEach { view in
            view.text = ""
            view.backgroundColor = .clear
        }
        
        pinIndicatorsContainer.forEach { view in
            view.layer.borderColor = appearance.incorrectInputColor.cgColor
            view.layer.borderWidth = 0.5
            view.shake(delegate: self)
        }
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        initOnce()
        // Do any additional setup after loading the view.
    }
    
    private func initOnce(){
        isOnScreen = true
        self.mode = self.startMode
        configureAppearance()
        configureTextField()
        clearView()
    }
}

// MARK: - CAAnimationDelegate
extension LockerViewController: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        clearView()
    }
}


extension LockerViewController : UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if isOnScreen {
            return false
        }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, let range = Range(range, in: text) {
            let userInputString = text.replacingCharacters(in: range, with: string)
            print("full string->\(userInputString)")
            updateUI(isNeedClear: false, tag: Int(string))
            if userInputString.count > Constants.pinLength {
                return false
            }
        }
        return true
    }
}

// MARK: - Present
public extension LockerViewController {
    // Present Lock Screen
    class func present(with mode: PasscodeMode, and appearance: LockerAppearance? = nil) {
        guard let root = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        let locker = LockerViewController(nibName: String(describing: LockerViewController.self), bundle: nil)
        locker.appearance = appearance ?? LockerAppearance()
        locker.startMode = mode
        root.present(locker, animated: true, completion: nil)
    }
}
