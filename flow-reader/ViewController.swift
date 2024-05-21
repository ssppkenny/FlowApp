//
//  ViewController.swift
//  TestViewer
//
//  Created by Sergey Mikhno on 26.08.18.
//  Copyright © 2018 Sergey Mikhno. All rights reserved.
//

import UIKit
import PDFKit
import CoreData
import TesseractOCR


class ViewController: UIViewController, UIGestureRecognizerDelegate{
    @IBAction func recognize(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        self.recognizeItem = sender
        self.hasText = false
        self.imageView.isHidden = false
        self.flow = true
        self.view.setNeedsLayout()
        
    }
    
    @IBAction func original(_ sender: UIBarButtonItem) {
        self.flow = false
        self.scale = 2.0
        recognizeItem.isEnabled = true
        self.view.setNeedsLayout()
    }
    
    @IBAction func zoomOut(_ sender: UIBarButtonItem) {
        if (self.scale > 1.0) {
            sender.isEnabled = false
            zoomOutItem = sender
            self.flow = true
            self.scale *= 0.77
            self.view.setNeedsLayout()
        }
        
    }
    @IBAction func zoomIn(_ sender: UIBarButtonItem) {
        if (self.scale < 6.0) {
            sender.isEnabled = false
            zoomInItem = sender
            self.flow = true
            self.scale *= 1.3
            self.view.setNeedsLayout()
        }
        
    }
    @IBOutlet var scrollView: UIScrollView!
    var filePath : String?
    
    @IBOutlet var zoomOutItem: UIBarButtonItem!
    @IBOutlet var zoomInItem: UIBarButtonItem!
    
    @IBOutlet var recognizeItem: UIBarButtonItem!
    @IBOutlet var toolbar: UIToolbar!
    var pageNo : Int32 = 0
    
    var pageWidth : CGFloat  = 0
    
    var scale : CGFloat = 2.0
    
    var startPanLocation: CGPoint?
    
    var frameOrigin: CGRect?
    
    var nextPage : UIImage?
    
    var  prevPage : UIImage?
    
    var numberOfPages : Int32 = 0;
    
    var context: NSManagedObjectContext?;
    
    var flow : Bool = false;
    
    var hasText : Bool = false;
    
    var image: UIImage!;
    
    @IBOutlet var imageView: UIImageView!
    
    var container: CircleLoader?
    
    
    @objc
    func respondsToPanGesture(sender: UIPanGestureRecognizer) {
        let currentLocation = sender.location(in: self.view)
        
        switch sender.state {
        case .began:
            startPanLocation = currentLocation
            frameOrigin = imageView.frame
            break
        case .ended:
            
            if let pos = startPanLocation {
                
                let deltax = currentLocation.x - pos.x
                let deltay = currentLocation.y - pos.y
                
                if (abs(deltay) / abs(deltax) < 0.5) {
                    if (deltax > 0 && self.pageNo < self.numberOfPages - 1) {
                        self.pageNo += 1
                        //loadPage(scale: 1.0, size: size, flow:false)
                    } else if (deltax < 0 && self.pageNo > 0) {
                        self.pageNo -= 1
                        //loadPage(scale: 1.0, size: size, flow: false)
                    }
                    
                    
                    self.view.setNeedsLayout()
                }
                
                // reset image position
                if let origin = self.frameOrigin {
                    self.imageView.frame = origin
                }
                
                
            }
            
            break
        default:
            
            // move image as we move fingers
            if let pos = startPanLocation {
                let deltax = currentLocation.x - pos.x
                let deltay = currentLocation.y - pos.y
                imageView.frame = CGRect(x:deltax, y:deltay, width:imageView.frame.width, height:imageView.frame.height)
            }
            break;
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated);
        if let context = self.context {
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ManagedMat")
            do {
                
                let result = try context.fetch(request) as! [NSManagedObject]
                for r in result {
                    print(r)
                }
            } catch {
                print("error")
            }
        }
    }
    
    @objc
    func respondsToPinchGesture(sender: UIPinchGestureRecognizer) {
        
        if sender.state == .ended  {
            let scaleToSet = self.scale * (sender.scale > 1 ? 1.1 : 0.91)
            if scaleToSet <= 5.0 && scaleToSet >= 1.0 {
                self.scale = scaleToSet
                self.flow = true
                loadPage(scale: self.scale, size: self.imageView.frame.size, flow: true)
                self.view.setNeedsLayout()
            }
        }
    }
    
    @objc
    func respondsToTapGesture(sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.view)
        
        if location.x < self.scrollView.frame.width/2 {
            if self.pageNo > 0 {
                self.pageNo-=1
                loadPage(scale: 1.0, size: self.imageView.frame.size,  flow: false)
                self.view.setNeedsLayout()
            }
        } else {
            if (self.pageNo < self.numberOfPages - 1) {
                self.pageNo+=1
                loadPage(scale: 1.0, size: self.imageView.frame.size, flow: false)
                self.view.setNeedsLayout()
            }
            
        }
        
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
    
    func loadPage(scale: CGFloat,  size: CGSize, flow: Bool) {
        
        DispatchQueue.main.async {
            
            self.image = FlowLib.getPage(self.filePath, for: self.pageNo,  with: self.context, width: Int32(self.pageWidth), newScale: CGFloat(scale), flow: flow )
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    
    override func viewDidLoad() {
        
        container = CircleLoader.createGeometricLoader()
        
        super.viewDidLoad()
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.respondsToPinchGesture))
        view.addGestureRecognizer(pinchRecognizer)
        view.isUserInteractionEnabled = true
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.respondsToPanGesture))
        view.addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.respondsToTapGesture))
        tapRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapRecognizer)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        
        if filePath != nil {
            DispatchQueue.main.async {
                self.loadPage(scale: 1.0, size: self.imageView.frame.size, flow: false)
                self.numberOfPages = FlowLib.getNumberOfPages(self.filePath)
            }
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        
     
       // self.scrollView.sendSubviewToBack(self.textView)
        
          
            DispatchQueue.main.async {
        
      //  self.flow = true
        
                self.image = FlowLib.getPage(self.filePath, for: self.pageNo, with: self.context, width: Int32(self.imageView.frame.size.width * UIScreen.main.scale), newScale: CGFloat(self.scale), flow: self.flow )
                  
                  /*
                  if (self.flow) {
                      if let tesseract = G8Tesseract(language: "rus") {
                          tesseract.engineMode = .tesseractOnly
                          tesseract.pageSegmentationMode = .auto
                          tesseract.image = self.image!
                          tesseract.recognize()
                          var s = tesseract.recognizedText
                          let trimmed = s?.replacingOccurrences(of: "\n", with: "")
                      
                          // In Swift 1.2 (Xcode 6.3):
                          self.scrollView.sendSubviewToBack(self.imageView)
                          self.textView.text = trimmed
                      }
                  }
                  */
                  
                  self.numberOfPages = FlowLib.getNumberOfPages(self.filePath)
                  
                  self.pageWidth = self.image!.size.width
                  
                  self.imageView.contentMode = UIView.ContentMode.topLeft
                  
                  
                  let frameWidth = self.view.frame.width
                  
                  let imageHeight = self.image.size.height
                  let imageWidth = self.image.size.width
                  let ratio = imageWidth/frameWidth
                  
                  let scaledImage = self.scaleUIImageToSize(image: self.image!, size: CGSize(width: frameWidth, height: imageHeight / ratio))
                  
                  self.imageView.image = scaledImage
                  
                  self.scrollView.contentSize = scaledImage.size
                  
                  
                  //UIView.transition(with: self.imageView,
                  //                          duration:1,
                  //                          options: .transitionCrossDissolve,
                  //                          animations: { self.imageView.image = scaledImage },
                  //                          completion: nil)
                  
                  self.container!.stopAnimation()
                
                self.imageView.isHidden = false
                
                  if let zoomInItem = self.zoomInItem {
                      zoomInItem.isEnabled = true
                     self.imageView.isHidden = false
                  }
                  
                  if let zoomOutItem = self.zoomOutItem {
                      zoomOutItem.isEnabled = true
                     self.imageView.isHidden = false
                  }
                  
           
                  
                  self.view.setNeedsDisplay()
                  
    
       }
        
      //  container!.startAnimation()
  
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

