//
//  ViewController.swift
//  PasscodeController
//
//  Created by Janak Nirmal on 08/12/18.
//  Copyright © 2018 Janak Nirmal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func btnLockerTapped(_ sender: Any) {
        self.openLocker()
    }
    
    func openLocker(){
        var appearance = LockerAppearance()
        appearance.image = UIImage(named: "face")!
        appearance.message = "Enter your passcode"
        LockerViewController.present(with: .change, and: appearance)
    }
}

