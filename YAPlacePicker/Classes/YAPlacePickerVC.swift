//
//  YAPlacePickerVC.swift
//  YAPlacePicker
//
//  Created by Nikita Khudorozhkov on 24/07/2019.
//  Copyright © 2019 Nikita Khudorozhkov. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import RxSwift
import RxCocoa

public class YAPlacePickerVC: UIViewController {

    public static let storyboardId = "YAPlacePickerVC"
    public static let storyboardName = "YAPlacePickerStoryboard"
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchResultsBackgroundView: UIView!
    @IBOutlet weak var searchResultsView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBOutlet var searchResultsTableHeight: NSLayoutConstraint!
    @IBOutlet var searchResultsTableHeightZero: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    private let locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    let disposeBag = DisposeBag()
    
    var token: GMSAutocompleteSessionToken?
    
    public let loading: PublishSubject<Bool> = PublishSubject()
    public let searchResults = PublishSubject<[GMSAutocompletePrediction?]>()
    public let placeSubject: PublishSubject<GMSPlace?> = PublishSubject()
    public let eraseSubject: PublishSubject<Bool> = PublishSubject()
    
    private var placeInfoView: PlaceInfoView!
    
    private var placeMarker : GMSMarker?
    
    public var completion : YAPlacePickerOnComplete!
    
    public var searchPlaceholderText: String!
    public var chooseButtonText: String!
    public var chooseButtonColor: UIColor?
    
    private func initPlaceInfo() {
        placeInfoView = PlaceInfoView.instanceFromNib()
        placeInfoView.delegate = self
        placeInfoView.choosebutton.setTitle(chooseButtonText, for: .normal)
        if let bgColor = chooseButtonColor {
            placeInfoView.choosebutton.backgroundColor = bgColor
        }
        placeInfoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeInfoView)
        let left = NSLayoutConstraint(item: placeInfoView!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: placeInfoView!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: placeInfoView!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([left, right, bottom])
        placeInfoView.place = nil
    }
    
    override internal func viewDidLoad() {
        super.viewDidLoad()
        initPlaceInfo()
        customizeUI()
        mapView.delegate = self
        placesClient = GMSPlacesClient.shared()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //********************
        // SETUP ERASE SUBJECT
        //********************
        eraseSubject.subscribe(onNext: {[weak self] isErase in
            self?.eraseButton.isHidden = !isErase
            self?.cancelButton.isHidden = isErase
        }).disposed(by: disposeBag)
        
        
        //************************
        // SETUP LOADING INDICATOR
        //************************
        loading.subscribe(onNext: { isLoading in
            UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
        }).disposed(by: disposeBag)
        
        //********************************
        // SETUP SEARCH RESULTS TABLE VIEW
        //********************************
        searchResultsTableView.register(UINib(nibName: "ResultTableViewCell", bundle: nil), forCellReuseIdentifier: "ResultTableViewCell")
        searchResultsTableView.register(UINib(nibName: "PoweredByGoogleTableViewCell", bundle: nil), forCellReuseIdentifier: "PoweredByGoogleTableViewCell")
        searchResultsTableView.rowHeight = 50.0
        searchResults.bind(to: searchResultsTableView.rx.items){ (tv, row, item) -> UITableViewCell in
            if let item = item {
                let cell = tv.dequeueReusableCell(withIdentifier: "ResultTableViewCell") as! ResultTableViewCell
                cell.placeName.attributedText = item.attributedPrimaryText
                cell.placeDesc.attributedText = item.attributedSecondaryText
                return cell
            } else {
                return tv.dequeueReusableCell(withIdentifier: "PoweredByGoogleTableViewCell")!
            }
            }.disposed(by: disposeBag)
        
        searchResults.subscribe(onNext: {[weak self] predictions in
            var newHeight = 50.0 * CGFloat(predictions.count)
            if newHeight == 0 {
                newHeight = 1
            }
            self?.searchResultsTableHeight.constant = newHeight
            self?.searchResultsTableHeightZero.isActive = newHeight == 1
            UIView.animate(withDuration: 0.2, animations: {
                self?.view.layoutIfNeeded()
            })
        }).disposed(by: disposeBag)
        
        searchResultsTableView.rx.modelSelected(GMSAutocompletePrediction.self).subscribe(onNext: { [weak self] prediction in
            self?.searchTextField.endEditing(true)
            self?.loading.onNext(true)
            self?.placeIDSelected(placeID: prediction.placeID, moveCamera: true)
        }).disposed(by: disposeBag)
        
        searchResultsTableView.rx.itemSelected.subscribe(onNext: {[weak self] indexPath in
            self?.searchResultsTableView.deselectRow(at: indexPath, animated: false)
        }).disposed(by: disposeBag)
        
        //***********************
        //SETUP PLACE INFO SCREEN
        //***********************
        placeSubject.subscribe(onNext: {[weak self] place in
            self?.placeInfoView.place = place
            self?.view.layoutIfNeeded()
        }).disposed(by: disposeBag)
        
        //*******************
        //SETUP ERASE BUTTON
        //*******************
        eraseButton.rx.tap.bind { [weak self] in
            self?.searchTextField.text = nil
            self?.searchTextField.endEditing(true)
            self?.searchResults.onNext([])
            self?.placeInfoView.place = nil
            self?.token = nil
            self?.eraseSubject.onNext(false)
            self?.clearMarker()
        }.disposed(by: disposeBag)
        
        //*******************
        //SETUP CANCEL BUTTON
        //*******************
        cancelButton.rx.tap.bind { [weak self] in
            self?.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        //************************
        // SETUP SEARCH TEXT FIELD
        //************************
        searchTextField.rx.text.orEmpty.asObservable().subscribe(onNext: {[weak self] searchQuery in
            guard !searchQuery.isEmpty else {
                self?.token = nil
                self?.searchResultsTableHeight.constant = 0
                self?.eraseSubject.onNext(false)
                return
            }
            self?.eraseSubject.onNext(true)
            if self?.token == nil {
                self?.token = GMSAutocompleteSessionToken.init()
            }
            
            guard let token = self?.token else { return }
            
            let filter = GMSAutocompleteFilter()
            filter.type = .establishment
            self?.loading.onNext(true)
            self?.placesClient?.findAutocompletePredictions(fromQuery: searchQuery,
                                                      bounds: nil,
                                                      boundsMode: GMSAutocompleteBoundsMode.bias,
                                                      filter: filter,
                                                      sessionToken: token,
                                                      callback: {[weak self] (results, error) in
                                                        self?.loading.onNext(false)
                                                        if let error = error {
                                                            // TODO: Handle the error.
                                                            print("Autocomplete error \(error)")
                                                            return
                                                        }
                                                        
                                                        var predictions : [GMSAutocompletePrediction?] = []
                                                        
                                                        if let results = results {
                                                            predictions.append(contentsOf: results)
                                                        }
                                                        
                                                        if predictions.count > 0 {
                                                            predictions.append(nil)
                                                        }
                                                        
                                                        self?.searchResults.onNext(predictions)
            })
        }).disposed(by: disposeBag)
    }
    
    override internal func viewDidLayoutSubviews() {
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: placeInfoView.frame.height, right: 0)
    }
    
    private func placeIDSelected(placeID: String, moveCamera: Bool) {
        if token == nil {
            token = GMSAutocompleteSessionToken.init()
        }
        let fields: GMSPlaceField = GMSPlaceField(rawValue:
            UInt(GMSPlaceField.all.rawValue))!
        loading.onNext(true)
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: token, callback: {[weak self] (place, error) in
            self?.token = nil
            self?.loading.onNext(false)
            self?.placeSubject.onNext(place)
            if place != nil {
                self?.searchResults.onNext([])
                self?.eraseSubject.onNext(true)
                self?.searchTextField.text = place?.name
            }
            if moveCamera {
                if let viewport = place?.viewport, let cameraPosition = self?.mapView.camera(for: viewport, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
                    self?.mapView.animate(to: cameraPosition)
                }
            } else {
                if let coordinate = place?.coordinate {
                    self?.mapView.animate(toLocation: coordinate)
                }
            }
            
            self?.clearMarker()
            
            if let coordinate = place?.coordinate {
                let marker = GMSMarker()
                marker.isDraggable = false
                marker.position = coordinate
                marker.map = self?.mapView
                self?.placeMarker = marker
            }
        })
    }
    
    private func clearMarker() {
        if let marker = placeMarker {
            marker.map = nil
            placeMarker = nil
        }
    }
    
    private func customizeUI() {
        searchView.layer.cornerRadius = 5
        searchView.layer.shadowColor = UIColor.black.cgColor
        searchView.layer.shadowRadius = 1
        searchView.layer.shadowOpacity = 1
        searchView.layer.shadowOffset = CGSize(width : 1, height: 1)
        
        searchResultsBackgroundView.layer.cornerRadius = 5
        searchResultsBackgroundView.layer.shadowColor = UIColor.black.cgColor
        searchResultsBackgroundView.layer.shadowRadius = 1
        searchResultsBackgroundView.layer.shadowOpacity = 1
        searchResultsBackgroundView.layer.shadowOffset = CGSize(width : 1, height: 1)
        
        searchTextField.placeholder = searchPlaceholderText
    }
}

extension YAPlacePickerVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        locationManager.stopUpdatingLocation()
    }
}

extension YAPlacePickerVC: PlaceInfoViewDelegate {
    func placeChoosen(place: GMSPlace) {
        completion(place)
    }
}

extension YAPlacePickerVC: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
        placeIDSelected(placeID: placeID, moveCamera: false)
    }
}
