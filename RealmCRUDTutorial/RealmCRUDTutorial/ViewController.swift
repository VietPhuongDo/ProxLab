//
//  ViewController.swift
//  RealmCRUDTutorial
//
//  Created by PhuongDo on 13/12/2023.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    
    var names: Results<Example>?
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        loadItems()
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        let newName = Example()
        newName.name = textField.text!
        
        do{
            try realm.write{
                realm.add(newName)
            }
        }
        catch{
            print("Error saving \(error)")
        }
        textField.text = ""
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NameCell", for: indexPath)
        cell.textLabel?.text = names?[indexPath.row].name ?? "No name added yet"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Options", message: "Choose an action", preferredStyle: .alert)

        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] (action) in
            self?.showUpdateAlert(at: indexPath)
        }

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (action) in
            self?.deleteItem(at: indexPath)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alert.addAction(updateAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    func showUpdateAlert(at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Update", message: "", preferredStyle: .alert)
        var updateTextfield = UITextField()

        alert.addTextField { (alertTextfield) in
            alertTextfield.placeholder = "Update name"
            updateTextfield = alertTextfield
        }

        let action = UIAlertAction(title: "Update Name", style: .default) { [weak self] (action) in
            if let name = self?.names?[indexPath.row] {
                do {
                    try self?.realm.write {
                        name.name = updateTextfield.text!
                        self?.loadItems()
                    }
                } catch {
                    print("Error saving to Realm")
                }
            }
        }

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    func deleteItem(at indexPath: IndexPath) {
        if let name = names?[indexPath.row] {
            do {
                try realm.write {
                    realm.delete(name)
                    loadItems()
                }
            } catch {
                print("Error deleting from Realm")
            }
        }
    }

    func loadItems(){
        names = realm.objects(Example.self)
        tableView.reloadData()
    }
    
}

