//
//  UIViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Tasheel on 25/12/1442 AH.
//

import Foundation
import UIKit
extension UIViewController{
    
    func showAlertMessage(title:String,message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated:true,completion:nil)
        }
    }
    
}
