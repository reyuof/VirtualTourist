//
//  FilckrClinet.swift
//  VirtualTourist
//
//  Created by Tasheel on 20/11/1442 AH.
//

import Foundation

class FilckrClinet{
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/"
        static let apikey = "d9cfc6f5fe03af66fc8da2b08633f447"
        case getSearchPhoto(Double,Double)
        
        var stringValue : String {
            switch self {
            case .getSearchPhoto (let latitude, let longitude):
                return Endpoints.base + "?method=flickr.photos.search&api_key=" + Endpoints.apikey + "&lat=\(latitude)&lon=\(longitude)&page=\(Int.random(in: 1..<11))&per_page=30&format=json&nojsoncallback=1"

            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    //to do change the bool to data
    class func getPhotoByLocation(latitude : Double, longitude:Double, completion: @escaping ([FilckrPhotosData]? , Error?) -> Void){
        print(Endpoints.getSearchPhoto(latitude, longitude).url)
        let task = URLSession.shared.dataTask(with: Endpoints.getSearchPhoto(latitude, longitude).url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                print(data)
                let responseObject = try decoder.decode(FlickrPhotoResponse.self, from: data)
                
                DispatchQueue.main.async{
                    completion(responseObject.photos.photo, nil)
                }
            } catch {
                DispatchQueue.main.async{
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
        class func dowonloadPhoto(url:String , completion: @escaping (Data?,Error?) -> Void){
    
            let task = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
                DispatchQueue.main.async {
                    completion(data,error)
                }
            }
            task.resume()
        }
}
