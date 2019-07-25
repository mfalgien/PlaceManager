/*
 * Copyright 2019 Michael Falgien,
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Purpose: Swift client for a Java place collection JsonRPC server.
 *
 * @author Michael Falgien michael.falgien@asu.edu | mfalgien@gmail.com
 * @version April 2019
 */

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var descriptionTF: UITextField!
    @IBOutlet weak var categoryTF: UITextField!
    @IBOutlet weak var titleTF: UITextField!
    @IBOutlet weak var streetTF: UITextField!
    @IBOutlet weak var elevationTF: UITextField!
    @IBOutlet weak var latitudeTF: UITextField!
    @IBOutlet weak var longitudeTF: UITextField!
    @IBOutlet weak var namePicker: UIPickerView!
    
    var selectedName:String=""
    var places:[String]=[String]()
    
    
    var urlString:String = "http://localhost:8080"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.descriptionTF.delegate = self
        self.categoryTF.delegate = self
        self.titleTF.delegate = self
        self.streetTF.delegate = self
        self.elevationTF.delegate = self
        self.latitudeTF.delegate = self
        self.longitudeTF.delegate = self
        self.nameTF.delegate = self
        
        self.namePicker.removeFromSuperview()
        self.namePicker.delegate = self
        self.nameTF.inputView = self.namePicker
        
        
        self.urlString = self.setURL()
        self.callGetNamesNUpdatePlacePicker()
        
    }
    
    
    func setURL () -> String {
        var serverhost:String = "localhost"
        var jsonrpcport:String = "8080"
        var serverprotocol:String = "http"
        // access and log all of the app settings from the settings bundle resource
        if let path = Bundle.main.path(forResource: "ServerInfo", ofType: "plist"){
            // defaults
            if let dict = NSDictionary(contentsOfFile: path) as? [String:AnyObject] {
                serverhost = (dict["server_host"] as? String)!
                jsonrpcport = (dict["jsonrpc_port"] as? String)!
                serverprotocol = (dict["server_protocol"] as? String)!
            }
        }
        print("setURL returning: \(serverprotocol)://\(serverhost):\(jsonrpcport)")
        return "\(serverprotocol)://\(serverhost):\(jsonrpcport)"
    }
    
    // get names via call to server and populate PickerView with names
    func callGetNamesNUpdatePlacePicker() {
        let aConnect:PlaceCollectionStub = PlaceCollectionStub(urlString: urlString)
        let _:Bool = aConnect.getNames(callback: { (res: String, err: String?) -> Void in
            if err != nil {
                NSLog(err!)
            }else{
                NSLog(res)
                if let data: Data = res.data(using: String.Encoding.utf8){
                    do{
                        let dict = try JSONSerialization.jsonObject(with: data,options:.mutableContainers) as?[String:AnyObject]
                        self.places = (dict!["result"] as? [String])!
                        self.places = Array(self.places).sorted()
                        print("PLACES ARE \(self.places)")
                        self.nameTF.text = ((self.places.count>0) ? self.places[0] : "")
                        self.namePicker.reloadAllComponents()
                        if self.places.count > 0 {
                            self.callGetNPopulateUIFields(self.places[0])
                        }
                    } catch {
                        print("unable to convert to dictionary")
                    }
                }
                
            }
        })  // end of method call to getNames
    }
    
    //Updates the text fields to display information about the place
    func callGetNPopulateUIFields(_ name: String){
        let aConnect:PlaceCollectionStub = PlaceCollectionStub(urlString: urlString)
        let _:Bool = aConnect.get(name: name, callback: { (res: String, err: String?) -> Void in
            if err != nil {
                NSLog(err!)
            }else{
                NSLog(res)
                if let data: Data = res.data(using: String.Encoding.utf8){
                    do{
                        let dict = try JSONSerialization.jsonObject(with: data,options:.mutableContainers) as?[String:AnyObject]
                        let aDict:[String:AnyObject] = (dict!["result"] as? [String:AnyObject])!
                        let aPlace:PlaceDescription = PlaceDescription(dict: aDict)
                        //self.nameTF.text = "\(aPlace.name)"
                        self.nameLabel.text = aPlace.name
                        self.descriptionTF.text = aPlace.description
                        self.categoryTF.text = aPlace.category
                        self.titleTF.text = aPlace.addressTitle
                        self.streetTF.text = aPlace.addressStreet
                        self.elevationTF.text = aPlace.elevation.description
                        self.latitudeTF.text = aPlace.latitude.description
                        self.longitudeTF.text = aPlace.longitude.description
                        self.namePicker.reloadAllComponents()
                    
                    } catch {
                        NSLog("unable to convert to dictionary")
                    }
                }
            }
        })
    }
    

    //add a new PlaceDescription on the server
    @IBAction func addPlace(_ sender: Any) {
        let promptND = UIAlertController(title: "New Place Name", message: "Enter Name of Place", preferredStyle: UIAlertController.Style.alert)
        // if the user cancels, we don't want to add an annotation or pin
        promptND.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        // setup the OK action and the closure to be executed when/if OK selected
        promptND.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            //print("you entered title: \(promptND.textFields?[0].text)")
            let newPlaceName = (promptND.textFields?[0].text)!
            if !self.places.contains(newPlaceName) {
                let aPlace:PlaceDescription = PlaceDescription(dict:["name":newPlaceName, "description": self.descriptionTF.text!, "category": self.categoryTF.text!, "address-title": self.titleTF.text!, "address-street": self.streetTF.text!, "elevation": Double(self.elevationTF.text!), "latitude" : Double(self.latitudeTF.text!), "longitude" : Double(self.longitudeTF.text!)])
                let aConnect:PlaceCollectionStub = PlaceCollectionStub(urlString: self.urlString)
                let _:Bool = aConnect.add(place: aPlace,callback: { _,_  in
                    print("\(aPlace.name) added as: \(aPlace.toJsonString())")
                    self.callGetNamesNUpdatePlacePicker()})
            }
        }))
        promptND.addTextField(configurationHandler: {(textField: UITextField!) in textField.placeholder = "Place"})
        present(promptND, animated: true, completion: nil)
        let placeName:String = self.nameTF.text!
        let aPlace:PlaceDescription = PlaceDescription(dict:["name": placeName, "description": self.descriptionTF.text!, "category": self.categoryTF.text!, "address-title": self.titleTF.text!, "address-street": self.streetTF.text!, "elevation": Double(self.elevationTF.text!), "latitude" : Double(self.latitudeTF.text!), "longitude" : Double(self.longitudeTF.text!)])
        let aConnect:PlaceCollectionStub = PlaceCollectionStub(urlString: urlString)
        let _:Bool = aConnect.add(place: aPlace,callback: { _,_  in
            self.places.append(placeName)
            self.namePicker.reloadAllComponents()
            self.callGetNPopulateUIFields(placeName)
        })
    }
    
    //Remove a PlaceDescription from the server
    @IBAction func removePlace(_ sender: Any) {
        let aConnect:PlaceCollectionStub = PlaceCollectionStub(urlString: urlString)
        let _:Bool = aConnect.remove(place: nameLabel.text!,callback: { _,_  in
            self.callGetNamesNUpdatePlacePicker()
        })
    }
    
    // touch events on this view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.nameTF.resignFirstResponder()
        self.descriptionTF.resignFirstResponder()
        self.categoryTF.resignFirstResponder()
        self.titleTF.resignFirstResponder()
        self.streetTF.resignFirstResponder()
        self.elevationTF.resignFirstResponder()
        self.latitudeTF.resignFirstResponder()
        self.longitudeTF.resignFirstResponder()
        
    }
    
    // UITextFieldDelegate Method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nameTF.resignFirstResponder()
        self.descriptionTF.resignFirstResponder()
        self.categoryTF.resignFirstResponder()
        self.titleTF.resignFirstResponder()
        self.streetTF.resignFirstResponder()
        self.elevationTF.resignFirstResponder()
        self.latitudeTF.resignFirstResponder()
        self.longitudeTF.resignFirstResponder()
        return true
    }
    
    // Update UI based on pickerView entity selected
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.selectedName = places[row]
            self.nameTF.text = self.selectedName
            self.nameTF.resignFirstResponder()
            self.callGetNPopulateUIFields(self.selectedName)
    }
    
    //Number of columns in pickerView
    func numberOfComponentsInPickerView(_ pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //Number of "rows" in pickerView
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return ((pickerView == namePicker) ? places.count : places.count)
        return self.places.count
    }
    
    //String of pickerView entry selected
    func pickerView (_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //return ((pickerView == namePicker) ? places[row] : places[row])
        return self.places[row]
    }
    
    
}


