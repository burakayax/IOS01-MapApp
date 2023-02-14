//
//  ViewController.swift
//  MapApp
//
//  Created by Burak Kaya on 4.02.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenYerIsmi = ""
    var secilenYerID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        veriAl()
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiButonuTiklandi))
    }
    //Uygulama sayfasi her geldiginde calisacak olan kisim. Yani Farkli bir sayfaya gectiginde geri gelirsen bu kodlar calisir.
    override func viewWillAppear(_ animated: Bool) {
        //Dinleme objesi yaratip diger VC'den eger "veriGirildi" text'ini alirsak selector ile ne yapilacagini seciyoruz. Burada veriAl fonksiyonu veriyoruz ki diger sayfadan tekrar bu sayfaya gelince kayit ettigimiz aninda yansisin. Cunku verdigimiz fonksiyonun sonunca textView.reloadData() yazarak verilerimizi yeniliyoruz.
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name(rawValue: "VeriGirildi"), object: nil)
    }
    
    @objc func veriAl() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do {
            let sonuclar = try context.fetch(request)
            
            if sonuclar.count > 0 {
                
                //sonuclari cekmeden once tanimladigimiz dizilerin iclerini bosaltiyoruz.
                isimDizisi.removeAll()
                idDizisi.removeAll()
                
                for sonuc in sonuclar as! [NSManagedObject] {
                    if let isim = sonuc.value(forKey: "isim") as? String {
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                //eger gelen ver 0'dan buyukse tableView'i guncelliyoruz.
                tableView.reloadData()
            }
        } catch {
            print("Hata")
        }
    }
    
    @objc func artiButonuTiklandi() {
        secilenYerIsmi = ""
        performSegue(
            withIdentifier: "toMapsVC",
            sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerID = idDizisi[indexPath.row]
        performSegue(
            withIdentifier: "toMapsVC",
            sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC" {
            //MapsViewControlleri degisken gibi tanimlayip destinationVC'ye esitliyoruz ki diger taraftaki degiskenlere erisebilelim.
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerID
        }
            
    }
}
