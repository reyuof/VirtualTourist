//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Tasheel on 25/12/1442 AH.
//

import UIKit

class PhotoViewController: UIViewController {

    @IBOutlet weak var photoImgView: UIImageView!
    var photoImg : UIImage!
    override func viewDidLoad() {
        super.viewDidLoad()
        photoImgView.image = photoImg
    }
    

}
