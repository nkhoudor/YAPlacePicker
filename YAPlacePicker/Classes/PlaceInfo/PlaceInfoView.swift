//
//  PlaceInfoView.swift
//  YAPP
//
//  Created by Nikita Khudorozhkov on 25/07/2019.
//  Copyright © 2019 rocket. All rights reserved.
//

import UIKit
import GooglePlaces
import RxSwift
import RxCocoa

protocol PlaceInfoViewDelegate : class {
    func placeChoosen(place: GMSPlace)
}

class PlaceInfoView: UIView {
    
    public var delegate : PlaceInfoViewDelegate?

    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var placeAddress: UITextView!
    @IBOutlet weak var ratingValue: UILabel!
    @IBOutlet weak var ratingCount: UILabel!
    @IBOutlet weak var star1: UIImageView!
    @IBOutlet weak var star2: UIImageView!
    @IBOutlet weak var star3: UIImageView!
    @IBOutlet weak var star4: UIImageView!
    @IBOutlet weak var star5: UIImageView!
    @IBOutlet var heightZero: NSLayoutConstraint!
    @IBOutlet weak var choosebutton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    private lazy var yellowStar : UIImage = {
        let bundle = Bundle(for: PlaceInfoView.self)
        return UIImage(named: "star_y.png", in: bundle, compatibleWith: nil)!
    }()
    
    private lazy var greyStar : UIImage = {
        let bundle = Bundle(for: PlaceInfoView.self)
        return UIImage(named: "star_g.png", in: bundle, compatibleWith: nil)!
    }()
    
    var place : GMSPlace? {
        didSet {
            heightZero.isActive = place == nil
            placeName.text = place?.name
            placeAddress.text = place?.formattedAddress
            if let rating = place?.rating {
                ratingValue.text = "\(rating)"
                star1.image = rating >= 0.6 ? yellowStar : greyStar
                star2.image = rating >= 1.6 ? yellowStar : greyStar
                star3.image = rating >= 2.6 ? yellowStar : greyStar
                star4.image = rating >= 3.6 ? yellowStar : greyStar
                star5.image = rating >= 4.6 ? yellowStar : greyStar
            } else {
                ratingValue.text = nil
            }
            if let ratingTotal = place?.userRatingsTotal {
                ratingCount.text = "(\(ratingTotal))"
            } else {
                ratingCount.text = nil
            }
        }
    }
    
    override func awakeFromNib() {
        choosebutton.layer.cornerRadius = 20
        choosebutton.layer.shadowColor = UIColor.black.cgColor
        choosebutton.layer.shadowRadius = 1
        choosebutton.layer.shadowOpacity = 1
        choosebutton.layer.shadowOffset = CGSize(width : 1, height: 1)
        
        choosebutton.rx.tap.bind { [weak self] in
            guard let place = self?.place else { return }
            self?.delegate?.placeChoosen(place: place)
            }.disposed(by: disposeBag)
    }
    
    class func instanceFromNib() -> PlaceInfoView {
        let bundle = Bundle(for: PlaceInfoView.self)
        return UINib(nibName: "PlaceInfoView", bundle: bundle).instantiate(withOwner: nil, options: nil)[0] as! PlaceInfoView
    }
}
