//
//  MasterViewController.swift
//  coreDataManager
//
//  Created by Jim on 2018/7/18.
//  Copyright © 2018年 Jim. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    
//    var dataManager : CoreDataManager<Friend>!
    var dataManager : friendDataManager!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        dataManager = friendDataManager(momdFilename: "Contacts", entityName: "Friend", sortKey: "name")
        dataManager.setAsSingleton()    //外掛的 單例模式
        
        //...
        
        let manager = friendDataManager.shared
        // Design Pattern ==> 設計模式
        
        
        // Demo how to search "Lee" at name field.
        guard let result = dataManager.searchBy(keyword: "Lee", field: "name") else {
            return  }
        
        print("Search Resulet: \(result.count)")
        for friend in result {
            print("\(friend.name ?? "" ), \(friend.telephone ?? "")")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func insertNewObject(_ sender: Any) {
        //step1
        editInfo(existObject: nil) { (success, object) in
        //step11
            guard success else{
                return //Do nothing since user press cancel.
            }//step12a
            
            self.dataManager.saveContext { (success) in
                self.tableView.reloadData()     //動作沒這麼快 還沒存完
            } //save it
        //12b
        }
    
        //step 13
    }
    //step 9
    
    // MARK: - Segues

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showDetail" {
//            if let indexPath = tableView.indexPathForSelectedRow {
//                let object = objects[indexPath.row] as! NSDate
//                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
//                controller.detailItem = object
//                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//                controller.navigationItem.leftItemsSupplementBackButton = true
//            }
//        }
//    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }//擋住自動跳轉的 Segue
    
    
    
    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.totalCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let friend = dataManager.fetchObject(at: indexPath.row)
        cell.textLabel?.text = friend?.name
        cell.detailTextLabel?.text = friend?.telephone
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let object = dataManager.fetchObject(at: indexPath.row) else{
                assertionFailure("Fail to fetch object.")
                return
            }
            dataManager.delete(object: object)
            dataManager.saveContext { (success) in
                self.tableView.reloadData()
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let friend = dataManager.fetchObject(at: indexPath.row) else {
            assertionFailure("Fail to get friend object.")
            return  }
        
        editInfo(existObject: friend ) { (success, friend) in
            guard success else{
                return //Do nothing since user press cancel.
            }
            
            self.dataManager.saveContext { (success) in
                self.tableView.reloadData()
            }
        }
        
        
    }
    
    
    //mark Helper methods.
    typealias EditDoneHandler = (_ success:Bool, _ result: Friend?) -> Void
    func editInfo(existObject: Friend?,
                  completion: @escaping EditDoneHandler) {
        //step2
        let title = (existObject == nil ? "New Contact" : "Edit Contact")
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        //step3
        alert.addTextField { (textField) in
            //...
            textField.placeholder = "Name"
//             不確定 型別 可以這樣用
//            textField.text = existObject?.value(forKey: "name") as? String
             textField.text = existObject?.name
        }
        //step4
        alert.addTextField { (textField) in
            textField.placeholder = "Telephone"
//            textField.text = existObject?.value(forKey: "telephone") as? String
            textField.text = existObject?.telephone
        }
        //step5
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            //10a
            completion(false,nil)
        }
        //step6
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            //10b
            var finalObject = existObject   //
            if finalObject == nil{
                finalObject = self.dataManager.createObject() 
            }
            if let name = alert.textFields?.first?.text{
                finalObject?.name = name
            }
            if let telephone = alert.textFields?.last?.text{
                finalObject?.name = telephone
            }
            completion(true,finalObject)
            //step 14   con  會回來這
        }
        //7
        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert,animated: true)
        //8
        
    }
    
    

}

