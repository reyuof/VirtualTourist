//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Tasheel on 21/11/1442 AH.
//
//"https://farm\(photo["farm"].stringValue).staticflickr.com/\(photo["server"].stringValue)/\(photo["id"])_\(photo["secret"]).jpg"
import UIKit
import CoreData
import MapKit
class PhotoAlbumViewController: UIViewController , MKMapViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var pin : Pin!
    var latitude :Double?
    var longitude  :Double?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    
       
        setLocation()
        setUpFetchResultsController()
        if fetchedResultsController.sections?[0].numberOfObjects == 0{
            newCollectionButton.isUserInteractionEnabled = false
        loadImage()
        }else{
            newCollectionButton.isUserInteractionEnabled = true
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchResultsController()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    func loadImage(){
       
        newCollectionButton.isUserInteractionEnabled = false
        FilckrClinet.getPhotoByLocation(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0) { (photos, error) in
            guard let photos = photos else {
                debugPrint(error)
                return
            }
            //add method for adding photo to core data
            for photo in photos{
                self.addPhoto(photoData: photo)
            }
            
            DispatchQueue.main.async {
                self.setUpFetchResultsController()
                self.collectionView.reloadData()
            }
            self.newCollectionButton.isUserInteractionEnabled = true
        }
    }
    fileprivate func setUpFetchResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "photoURL", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("the fetch could not be performd: \(error.localizedDescription) ")
        }
    }
    func setLocation(){
        mapView.removeAnnotations(mapView.annotations)
        var annotations = [MKPointAnnotation]()
        if let latitude = latitude,let longitude = longitude{
            let lat =  latitude
            let long = longitude
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
            self.mapView.addAnnotations(annotations)
            mapView.showAnnotations(mapView.annotations, animated: true)
            mapView.isUserInteractionEnabled = false
        }
    }
    func addPhoto(photoData: FilckrPhotosData) {
        let photo = Photo(context: dataController.viewContext)
        photo.image = nil
        photo.photoURL = "https://farm\(photoData.farm).staticflickr.com/\(photoData.server)/\(photoData.id)_\(photoData.secret).jpg"
        photo.pin = pin
        try? dataController.viewContext.save()//need to handel the error in production application
        
    
    }
    func deletePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        setUpFetchResultsController()
        collectionView.reloadData()
    }
    
    func deleteAllPhoto(){
        if let photos = fetchedResultsController.fetchedObjects{
            for photo in photos{
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
        }
    }
    
    @IBAction func reloadNewCollection(_ sender: Any) {
        deleteAllPhoto()
        loadImage()
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(fetchedResultsController.sections?[section].numberOfObjects ?? 0)
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionViewCell
        cell.photoImageView.image = UIImage(named: "placeholder_large")
        if photo.image == nil {
            FilckrClinet.dowonloadPhoto(url: photo.photoURL ?? "") { (data, error) in
                if let data = data{
                    let photoData = UIImage(data: data)
                    cell.photoImageView.image = photoData
                    photo.image = data
                    try? self.dataController.viewContext.save()
                }
            }
        }else{
            if let data = photo.image{
                let photoData = UIImage(data: data)
                cell.photoImageView.image = photoData
            }
        }
        //cell.imageView.image = memes[indexPath.row].memedImage
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deletePhoto(at: indexPath)
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
    
}

