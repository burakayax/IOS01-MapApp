//
//  ViewController.swift
//  MapApp
//
//  Created by Burak Kaya on 3.02.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var isimTextLabel: UITextField!
    @IBOutlet weak var notTextLabel: UITextField!
    
    // Konum yoneticisi olusturmamiz gerekiyor.
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?
    
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        
        //Kullanici konumunu alma -> CoreLocation'u import etmemiz gerekiyor.
        
        //konumu alma -> ='den sonra kendi secimini yapabilirsin. Farkli varyasyonlar var.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //Kullanicidan konumu kullanmak icin izin istenmesi gerekiyor. Farkli varyasyonlari var. Genelde bu sectigimiz kullanilir.
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //Kullanici tikladigini algilamak. Burada kullandigimiz uzun basmak oldugu icin LongPress seciyoruz.
        let gestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(konumSec(gestureRecognizer:)))
        //Kullanici kac saniye bastiginda islem olsun
        gestureRecognizer.minimumPressDuration = 2
        //MapView'e jest algilayiciyi aktariyoruz.
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizerHiddenKeyboard = UITapGestureRecognizer(
            target: self,
            action: #selector(hiddenKeyboard))
        mapView.addGestureRecognizer(gestureRecognizerHiddenKeyboard)
        
        // Burada kontrol edilen diger taraftan yani ilk ViewControllerden veri gelip gelmedigi. Cunku eger veri geldiyse kullanici kayitli bir veriyi gormek icin gelmistir.
        //Eger veri gelmemisse yeni veri olusturmak icin + butonuna basarak gelmistir. Bu durumda bir sey yapmayiz.
        if secilenIsim != "" {
            // Core Data verilerini cek
            if let uuidString = secilenId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubTitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            isimTextLabel.text = annotationTitle
                                            notTextLabel.text = annotationSubTitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(
                                                latitudeDelta: 0.001,
                                                longitudeDelta: 0.001)
                                            
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } catch {
                    print("Hata")
                }
                
            }
        } else {
            // Kullanici yeni bir veri ekleyecek
        }
        
        
    }
    
    @objc func hiddenKeyboard() {
        view.endEditing(true)
    }
    
    // Pin'e button ekliyoruz
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //Pin'de buton gibi farkli bir aksesuar kullanilacagini soyluyoruz
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            //Normal buton ekleyip pin'e esitliyoruz fakat butonun tipini detailDisclosure yapiyoruz.
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    //Ekledigimiz butona tiklaninca ne olacagini ayarliyoruz.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        //Daha once kaydettigimiz bir yere baktigimiza emin oluyoruz
        if secilenIsim != "" {
            //Lokasyon verilerimizi aktariyoruz
            let requestLocation = CLLocation(
                latitude: annotationLatitude,
                longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        
                        let yeniPlaceMark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlaceMark)
                        item.name = self.annotationTitle
                        
                        //Navigasyonu acmak icin komutlar.
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
            
            
            
        }
    }
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer) {
        //Dokunma basladiysa eger ne yapilacagi
        if gestureRecognizer.state == .began {
            //Dokunulan noktayi degiskene aktariyoruz. Fakat bunu koordinata cevirmemiz gerekiyor
            let dokunulanNokta = gestureRecognizer.location(
                in: mapView)
            // Gelen noktayi koordinata cevirme
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            //Isaretleme
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextLabel.text!
            annotation.subtitle = notTextLabel.text!
            mapView.addAnnotation(annotation)
        }
    }
    
    
    //Konumu aldiktan sonra kullanmamiz icin fonksiyon yazmamiz gerekiyor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Konum olusturma
        
        if secilenIsim == "" {
            let location = CLLocationCoordinate2D(
                latitude: locations[0].coordinate.latitude,
                longitude: locations[0].coordinate.longitude)
            //ilk acildiginda zoom oranini ayarlar
            let span = MKCoordinateSpan(
                latitudeDelta: 0.001,
                longitudeDelta: 0.001)
            
            let region = MKCoordinateRegion(
                center: location,
                span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func kaydetTiklandi(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextLabel.text,
                         forKey: "isim")
        yeniYer.setValue(notTextLabel.text,
                         forKey: "not")
        yeniYer.setValue(secilenLatitude,
                         forKey: "latitude")
        yeniYer.setValue(secilenLongitude,
                         forKey: "longitude")
        yeniYer.setValue(UUID(),
                         forKey: "id")
        
        do {
            try context.save()
            print("Kayit Edildi")
        } catch {
            print("Hata Var")
        }
        //Tum isler bittikten sonra diger VC'ye islerin bittigine dair bir mesaj gonderiyoruz. Diger VC bu mesaji dinleyip ona gore gerekli islemleri yapacaktir.
        NotificationCenter.default.post(name: NSNotification.Name(
            rawValue: "VeriGirildi"),
            object: nil)
        //En sonunda diger VC'ye geri doner
        self.navigationController?.popViewController(
            animated: true)
    }
}

