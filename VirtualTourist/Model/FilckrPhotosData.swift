//
//  FilckrPhotos.swift
//  VirtualTourist
//
//  Created by Tasheel on 20/11/1442 AH.
//

import Foundation

struct FilckrPhotosData : Codable {
    let id : String
    let owner : String
    let secret : String
    let server : String
    let farm : Int
    let title :String
    let ispublic : Int
    let isfriend : Int
    let isfamily : Int
    
    
}
