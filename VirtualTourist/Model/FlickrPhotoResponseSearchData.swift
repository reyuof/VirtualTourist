//
//  FlickrPhotoResponse.swift
//  VirtualTourist
//
//  Created by Tasheel on 20/11/1442 AH.
//

import Foundation

struct  FlickrPhotoResponseSearchData :Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo : [FilckrPhotosData]
    
}
