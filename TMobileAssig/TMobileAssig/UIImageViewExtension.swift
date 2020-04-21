//
//  UIImageViewExtension.swift
//  TMobileAssig
//
//  Created by sai kumar madasu on 4/11/20.
//  Copyright © 2020 sai kumar madasu. All rights reserved.
//

import UIKit
import ObjectiveC
import Foundation
import AVFoundation

let imageCache = NSCache<NSString, UIImage>()
private var activityIndicatorAssociationKey: UInt8 = 0

extension UIImage {
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        let size = self.size
        let aspectRatio =  size.width/size.height
        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {
                width = dimension
                height = dimension / aspectRatio
            } else {
                height = dimension
                width = dimension * aspectRatio
            }
        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image { (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
    
}


extension UIImageView {
    
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
    
    func downloadImageFromUrl(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async {
                self.image = image
            }
            }.resume()
    }
    
    func loadImageUsingCache(from link: String, folder: String, name: String, shouldSaveCache: Bool = true) {
        self.showActivityIndicator()
        let url = URL(string: link)
        self.image = nil
        
        if let cachedImage = imageCache.object(forKey: link as NSString) {
            let height = self.frame.size.height > 0 ? self.frame.size.height : 200
            let resizedImage = cachedImage.resizeImage(height, opaque: false)
            self.image = resizedImage
            self.saveImageToLocalFile(image: resizedImage, folder: folder, name: name)
            self.hideActivityIndicator()
            return
        }
        
        if let offlineImage = self.getImageFromLocal(folder: folder, name: name) {
            self.image = offlineImage
            self.hideActivityIndicator()
            return
        }
        
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                self.hideActivityIndicator()
                print(error!)
                return
            }
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    let height = self.frame.size.height > 0 ? self.frame.size.height : 200
                    let resizedImage = image.resizeImage(height, opaque: false)
                    self.image = resizedImage
                    self.hideActivityIndicator()
                    if shouldSaveCache == true {
                        imageCache.setObject(image, forKey: link as NSString)
                        self.saveImageToLocalFile(image: resizedImage, folder: folder, name: name)
                    }
                }
            }
        }).resume()
    }
    

    func downloadImage(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit, folder: String, name: String, shouldSaveCache: Bool = true) {
        loadImageUsingCache(from: link, folder: folder, name: name, shouldSaveCache: shouldSaveCache)
    }
    
    var activityIndicator: UIActivityIndicatorView! {
        get {
            return objc_getAssociatedObject(self, &activityIndicatorAssociationKey) as? UIActivityIndicatorView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &activityIndicatorAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func showActivityIndicator() {
        if self.activityIndicator == nil {
            let container: UIView = UIView()
            container.bounds = self.bounds
            container.frame = self.bounds
            container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
            container.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            container.tag = 500
            self.addSubview(container)
            self.activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
            self.activityIndicator.hidesWhenStopped = true
            self.activityIndicator.frame = self.bounds
            self.activityIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.activityIndicator.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
            self.activityIndicator.isUserInteractionEnabled = false
            self.addSubview(self.activityIndicator)
            self.activityIndicator.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        OperationQueue.main.addOperation({ () -> Void in
            if let containerview = self.viewWithTag(500) {
                containerview.removeFromSuperview()
                self.activityIndicator.stopAnimating()
            }
        })
    }
    func generateThumbnail(path: URL) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: path)
            let assetImgGenerate: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            let time = CMTimeMake(value: 0, timescale: 1)
            let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            if img != nil {
                let frameImg  = UIImage(cgImage: img!)
                DispatchQueue.main.async(execute: {
                    // assign your image to UIImageView
                    self.image = frameImg
                })
            }
        }
    }
    
    func saveImageToLocalFile(image: UIImage, folder: String, name: String) {
        do {
            createDirectory(folder: folder)
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let folderPath =  documentsURL.appendingPathComponent("\(folder)")
            let filePath = folderPath.appendingPathComponent("\(name).png")
            if let pngImageData = image.pngData() {
                try pngImageData.write(to: filePath, options: .atomic)
            }
        } catch { }
    }
    
    func getImageFromLocal(folder: String, name: String) -> UIImage? {
        createDirectory(folder: folder)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderPath =  documentsURL.appendingPathComponent("\(folder)")
        let filePath = folderPath.appendingPathComponent("\(name).png").path
        if FileManager.default.fileExists(atPath: filePath) {
            return UIImage(contentsOfFile: filePath)
        }
        return nil
    }
    
    func createDirectory(folder: String) {
        
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(folder)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(filePath)")
        }
    }
    
}


