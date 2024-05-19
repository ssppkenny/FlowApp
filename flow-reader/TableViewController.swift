//
//  TableViewController.swift
//  TestViewer
//
//  Created by Sergey Mikhno on 01.09.18.
//  Copyright © 2018 Sergey Mikhno. All rights reserved.
//


import UIKit
import CoreData



func myfiles() -> [String] {
    var files : [String] = []
    do {
        let fileManager : FileManager = FileManager.default
        let documentFolderURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let fileURLs : [URL] = try fileManager.contentsOfDirectory(at: documentFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        files = fileURLs.filter{ (url: URL) -> Bool in return (url.pathExtension == "djvu" || url.pathExtension == "pdf" || url.pathExtension == "png" || url.pathExtension == "jpg")}.map {
            (url : URL) -> String in
            return url.path
        }
    } catch {
        print("error")
    }
    
    return files
};




class TableViewController: UITableViewController {
    
    var context: NSManagedObjectContext?;
    
    var reloading : Bool = true;
    
    
    private let myRefreshControl = UIRefreshControl()
    var filePath : String = ""
    
    // Data model: These strings will be the data for the table view cells
    var files: [String] = myfiles()
    
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scaleUIImageToSize(image: UIImage, size: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.draw(in: CGRect(origin: CGPoint(x:0,y:0), size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    
    @objc
    func refresh(sender:AnyObject) {
        // Code to refresh table view
        
        files  = myfiles()
        self.reloading = true
        self.tableView.reloadData()
        self.reloading = false
        myRefreshControl.endRefreshing()
    }
    
    @objc
    func update() {
        
        DispatchQueue.main.async {
            self.files = myfiles()
            self.tableView.reloadData()
            self.reloading = false
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the table view cell class and its reuse id
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        // (optional) include this line if you want to remove the extra empty cell divider lines
        // self.tableView.tableFooterView = UIView()
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        tableView.delegate = self
        tableView.dataSource = self
        
        myRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        myRefreshControl.addTarget(self, action: #selector(TableViewController.refresh), for: UIControl.Event.valueChanged)
        tableView.addSubview(myRefreshControl) // not required when using UITableViewController
        
        
        //update()
        //Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(TableViewController.update), userInfo: nil, repeats: false)
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DjvuViewer" {
            if let destination = segue.destination as? ViewController {
                
                // here get saved pageNo
                
                let entityName = "ManagedMat"
                
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                
                let matentity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)!
                
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:entityName)
                
                let theFileName = (filePath as NSString).lastPathComponent
                
                let predicate = NSPredicate(format: "filename = %@", theFileName)
                fetchRequest.predicate = predicate
                
                do {
                    let result = try managedContext.fetch(fetchRequest)
                    if result.count == 1 {
                        // use pageNo
                        
                        for data in result as! [NSManagedObject] {
                            let pageNo = data.value(forKey: "pageNo") as! Int32
                            destination.pageNo = pageNo
                        }
                        
                    } else {
                        // write pageNo == 0
                        let managedMat = NSManagedObject(entity: matentity, insertInto: managedContext)
                        managedMat.setValue(0, forKey: "pageNo")
                        managedMat.setValue(theFileName, forKey: "filename")
                        try managedContext.save()
                        
                    }
                    
                } catch let error as NSError {
                    print(error)
                }
                
                destination.filePath = filePath
                //destination.context = managedContext
            }
        }
    }
    
    
    
}

extension TableViewController  {
    
    func createThumbnail(cell:UITableViewCell, filepath: String) {
        do {
            
            let filename = (filepath as NSString).lastPathComponent
            cell.textLabel?.text = filename
            let fileManager : FileManager = FileManager.default
            let documentFolderURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            
            let onlyname = (filename as NSString).deletingPathExtension
            let fileUrl = documentFolderURL.appendingPathComponent(onlyname)
            
            if fileManager.fileExists(atPath: fileUrl.path) {
                let img = UIImage(contentsOfFile: fileUrl.path)
                cell.imageView?.image = img
            } else {
                
                let image : UIImage = FlowLib.getPage(filepath, for: 0, with: self.context, width: 0, newScale: CGFloat(0.2), flow: false )
                
                cell.imageView?.image = scaleUIImageToSize(image: image, size: CGSize(width: 45.0, height: 60.0))
                let data = image.pngData()
                try! data!.write(to: fileUrl)
                
            }
            
        } catch {
            print("error")
            
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 61.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Library"
    }
    
    // number of rows in table view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    // create a cell for each table view row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!
        
        // set the text from the data model
        
        let filepath = self.files[indexPath.row]
        createThumbnail(cell: cell, filepath: filepath)
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // method to run when table view cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        filePath = files[indexPath.row]
        performSegue(withIdentifier: "DjvuViewer", sender: self)
    }
}


