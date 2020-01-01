//
//  TheRockAds.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 12/30/19.
//  Copyright © 2019 On The Move Software. All rights reserved.
//

import UIKit

public struct AdJSON {
    let adURL: URL!
    let adImage: URL!
    let priority: Int32!
    let id: Int32!
}

extension AdJSON: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case adURL                    = "adURL"
        case adImage                    = "adImage"
        case priority            = "priority"
        case id                    = "id"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container             = try decoder.container(keyedBy: CodingKeys.self)
        
        self.adURL             = try container.decode(URL.self,                    forKey: .adURL)
        self.adImage             = try container.decode(URL.self,                    forKey: .adImage)
        self.priority         = try container.decode(Int32.self,            forKey: .priority)
        self.id             = try container.decode(Int32.self,                forKey: .id)
    }
}


class AD {
    var adURL: URL!
    var adImage: UIImage!
    var priority: Int32!
    var id: Int32!
}

class TheRockAds: NSObject {

    var ads: [AD] = []
    var adDuration: Int32!
    
    func get() {
        let adURL = URL.init(string: Common.theRockAdsURL)
        let task = URLSession.shared.dataTask(with: adURL!) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print(response ?? "Fred")
                    return
            }
            if let mimeType = httpResponse.mimeType, mimeType == "application/json",
                let data = data {
                do {
                    let decoder = JSONDecoder()
                    let adData = try decoder.decode(AdJSON.self, from: data)
                    self.processAdJSON(adData)
                }
                catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    func add(_ ad: AD) {
        self.ads.append(ad)
    }
    
    func show(_ ad: AD) {
        
    }
    
    func remove(_ adToRemove: AD) {
        for i in 0..<self.ads.count {
            let ad = self.ads[i]
            if ad.id == adToRemove.id {
                self.ads.remove(at: i)
                return
            }
        }
    }
    
    func processAdJSON(_ adData: AdJSON) {
        let newAd = AD()
        newAd.adURL = adData.adURL
        newAd.priority = adData.priority
        newAd.id = adData.id
        DispatchQueue.global().async {
            if let data = try? Data( contentsOf: URL(fileURLWithPath: "https://animalradio.com/images/RBPP-687-Animal-Radio-Banner-Ad-Mobile-App-020819.jpg")) // adData.adImage)
           {
             DispatchQueue.main.async {
                newAd.adImage = UIImage( data:data)
             }
           }
        }
    }
}
