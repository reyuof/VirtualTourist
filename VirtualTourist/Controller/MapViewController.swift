//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Tasheel on 18/11/1442 AH.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressedOnView(sender:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        setupFetchedResultsController()
        loadPinsToMap()
        print(UserDefaults.standard.bool(forKey: "isLocationSaved"))
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
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
    func showMap(){
        
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.tintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoViewController  = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        let latitude = view.annotation?.coordinate.latitude
        let longitude = view.annotation?.coordinate.longitude
        photoViewController.dataController = dataController
        photoViewController.latitude = latitude
        photoViewController.longitude = longitude
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()

        let predicate = NSPredicate(format: "latitude == %lf", Double(latitude ?? 0.0))
        let longitudePredicate = NSPredicate(format: "longitude == %lf", Double(longitude ?? 0.0))
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, longitudePredicate])

        fetchedResultsController.delegate = self
        do {
            if let result = try? dataController.viewContext.fetch(fetchRequest){
                photoViewController.pin = result.first
                        
                    }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        self.navigationController?.pushViewController(photoViewController, animated: true)
        
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
