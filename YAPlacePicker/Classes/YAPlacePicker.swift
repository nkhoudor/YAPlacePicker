//
//  YAPlacePicker.swift
//  YAPlacePicker
//
//  Created by Nikita Khudorozhkov on 24/07/2019.
//  Copyright © 2019 Nikita Khudorozhkov. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces

typealias YAPlacePickerOnComplete = (GMSPlace?) -> ()

class YAPlacePicker {
    weak var baseVC: UIViewController?
    var completion: YAPlacePickerOnComplete!
    private(set) var searchPlaceholder: String! = "Search for place"
    private(set) var chooseButtonTitle: String! = "Choose"
    private(set) var chooseButtonColor: UIColor! = UIColor(red: 0.0, green: 150.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    private(set) var gmsApiKey : String!
    
    init(baseVC: UIViewController, gmsApiKey: String, completion: @escaping YAPlacePickerOnComplete) {
        self.baseVC = baseVC
        self.gmsApiKey = gmsApiKey
        self.completion = completion
    }
    
    public func searchPlaceholder(_ value: String) -> YAPlacePicker {
        searchPlaceholder = value
        return self
    }
    
    public func chooseButtonTitle(_ value: String) -> YAPlacePicker {
        chooseButtonTitle = value
        return self
    }
    
    public func chooseButtonColor(_ value: UIColor) -> YAPlacePicker {
        chooseButtonColor = value
        return self
    }
    
    public func show() {
        let storyboard = UIStoryboard(name: YAPlacePickerVC.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: YAPlacePickerVC.storyboardId) as! YAPlacePickerVC
        GMSServices.provideAPIKey(gmsApiKey)
        GMSPlacesClient.provideAPIKey(gmsApiKey)
        vc.completion = completion
        vc.searchPlaceholderText = searchPlaceholder
        vc.chooseButtonText = chooseButtonTitle
        vc.chooseButtonColor = chooseButtonColor
        baseVC?.present(vc, animated: true)
    }
}
