//
//  ViewController.swift
//  YAPlacePicker
//
//  Created by 7633277@gmail.com on 07/27/2019.
//  Copyright (c) 2019 7633277@gmail.com. All rights reserved.
//

import UIKit
import YAPlacePicker

class ViewController: UIViewController {

    public static let gmsApiKey = ""
    
    @IBAction func pickPlacePressed(_ sender: Any) {
        if ViewController.gmsApiKey.isEmpty {
            fatalError("Plese fill APIKEY")
        }
        YAPlacePickerBuilder(baseVC: self, gmsApiKey: ViewController.gmsApiKey, completion: { place in
            print(place)
        }).show()
    }
}

