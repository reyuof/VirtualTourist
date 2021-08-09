//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Tasheel on 18/11/1442 AH.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var isEditingEnabled = false
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressedOnView(sender:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        setupFetchedResultsController()
        loadPinsToMap()
        
        setMapToSavedLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setMapToSavedLocation() {
        if UserDefaults.standard.bool(forKey: "isLocationSaved") == true{
            var annotations = [MKPointAnnotation]()
            let lat = UserDefaults.standard.double(forKey: "latitude")
            let long = UserDefaults.standard.double(forKey: "longitude")
            let latitudeDelta = UserDefaults.standard.double(forKey: "latitudeDelta")
            let longitudeDelta = UserDefaults.standard.double(forKey: "longitudeDelta")
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
            
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            
            mapView.region = region
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    func addPin(coordinate : CLLocationCoordinate2D){
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        try? dataController.viewContext.save()
    }
    
    @objc func longPressedOnView(sender : UILongPressGestureRecognizer){
        //to add only one pin for click
        if sender.state != .began{
            return
        }
        
        let location = sender.location(in: mapView)
        let coordinateNew = mapView.convert(location, toCoordinateFrom: mapView)
        addPin(coordinate: coordinateNew)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinateNew
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
        
    }
    func loadPinsToMap(){
        if let pinsList = fetchedResultsController.fetchedObjects {
            var annotations = [MKPointAnnotation]()
            for pin in pinsList{
                let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            //Remove the old pins before add the new ones
            mapView.removeAnnotations(mapView.annotations)
            // When the array is complete, we add the annotations to the map.
            DispatchQueue.main.async {
                self.mapView.addAnnotations(annotations)
            }
            
        }
        
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        findLocation(searchLocation: searchBar.text ?? "")
    }
    //search
    @IBAction func findLocation(searchLocation :String) {
        
        let geocoder = CLGeocoder()
        activityIndicator.startAnimating()
        geocoder.geocodeAddressString(searchLocation , completionHandler: {(placemarks, error) -> Void in
            self.activityIndicator.stopAnimating()
            if error != nil{
                if !Reachability.isConnectedToNetwork(){
                    self.showAlertMessage(title: "No Interent Connection", message: "Please check your Internet connection and try again")
                } else {
                self.showAlertMessage(title: "Incorrect location ", message: "please try again with correct location")
                }
            }else{
                if let placemark = placemarks?.first {
                    
                    let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                    
                    let coordinate = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                    let region = MKCoordinateRegion(center: coordinate, span: span)
                    self.mapView.region = region
                    
                }
            }
        })
        
    }
    
    @IBAction func editPins(_ sender: Any) {
        isEditingEnabled = !isEditingEnabled
        editBtn.title = isEditingEnabled ? "Done" : "Edit"
        
    }
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.tintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if isEditingEnabled{
            //if edit button is enable delete pin from coredata and map when select pin on map
            let latitude = view.annotation?.coordinate.latitude
            let longitude = view.annotation?.coordinate.longitude
            let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
            
            let predicate = NSPredicate(format: "latitude == %lf", Double(latitude ?? 0.0))
            let longitudePredicate = NSPredicate(format: "longitude == %lf", Double(longitude ?? 0.0))
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, longitudePredicate])
            
            fetchedResultsController.delegate = self
            do {
                if let pins = try? dataController.viewContext.fetch(fetchRequest){
                    for pin in pins {
                        dataController.viewContext.delete(pin)
                        try? dataController.viewContext.save()
                    }
                    mapView.removeAnnotation(view.annotation!)
                }
            } catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
            
        }else{
            //if edit button is disable move to photo album view when select pin on map
            performSegue(withIdentifier: "PhotoAlbumView", sender: self)
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PhotoAlbumViewController {
            if let pins = fetchedResultsController.fetchedObjects {
                //selected pin at that moment
                let annotation = mapView.selectedAnnotations[0]
                //to get the indexpath by looking
                guard let indexPath = pins.firstIndex(where: { (pin) -> Bool in
                    //it return that location where this condition is met
                    pin.latitude == annotation.coordinate.latitude && pin.longitude == annotation.coordinate.longitude
                }) else {
                    return
                }
                viewController.longitude = pins[indexPath].longitude
                viewController.latitude = pins[indexPath].latitude
                viewController.pin = pins[indexPath]
                viewController.dataController = dataController
            }
            
            
        }
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if animated{
            UserDefaults.standard.set(true, forKey: "isLocationSaved")
            UserDefaults.standard.set(mapView.region.center.latitude, forKey: "latitude")
            UserDefaults.standard.set(mapView.region.center.longitude, forKey: "longitude")
            UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
            UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
            
        }
    }
}
