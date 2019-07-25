//
//  TableViewController.swift
//  PlaceManagement
//
//  Created by Michael Falgien on 4/23/19.
//  Copyright © 2019 edu.asu.bsse.mfalgien.PlaceManagement. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    
    var urlString:String = "http://127.0.0.1:8080"
    var places:[String]=[String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setURL()
        self.getPlaces()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func setURL () {
        if let infoPlist = Bundle.main.path(forResource: "ServerInfo", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: infoPlist) as? [String:AnyObject] {
                self.urlString = (dict["ServerURLString"] as? String)!
                NSLog("The default urlString from info.plist is \(self.urlString)")
            }
        } else{
            NSLog("error getting urlString from info.plist")
        }
    }
    
    func getPlaces() {
        let aConnect:PlaceCollectionStub = PlaceCollectionStub(urlString: self.urlString)
        let _:Bool = aConnect.getNames(callback: { (res: String, err: String?) -> Void in
            if err != nil {
                NSLog(err!)
            } else {
                NSLog(res)
                if let data: Data = res.data(using: String.Encoding.utf8) {
                    do {
                        let dict = try JSONSerialization.jsonObject(with: data,options:.mutableContainers) as?[String:AnyObject]
                        self.places = (dict!["result"] as? [String])!
                        self.places = Array(self.places).sorted()
                        if self.places.count > 0 {
                            NSLog("Got places successfully")
                            for element in self.places {
                                print(element)
                            }
                            self.tableView.reloadData()
                        }
                    } catch {
                        print("unable to convert to dictionary")
                    }
                }
                
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.places.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceDescriptionCell", for: indexPath)
        let nameParts = self.places[indexPath.row].split(separator: "-")
        let count = nameParts.count == 1 ? 1 : nameParts.count - 1
        cell.textLabel?.text = nameParts.prefix(count).joined(separator: " ")
        cell.detailTextLabel?.text = String(nameParts.last!)
        
        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    } */
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlaceDetail" {
            let viewController:ViewController = segue.destination as! ViewController
            let indexPath = self.tableView.indexPathForSelectedRow!
            viewController.places = self.places
            viewController.selectedName = self.places[indexPath.row]
        }
    }
    

}
