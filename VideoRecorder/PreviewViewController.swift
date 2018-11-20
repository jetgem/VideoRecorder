//
//  PreviewViewController.swift
//  VideoRecorder
//
//  Created by Evgeniy on 5/23/15.
//  Copyright (c) 2015 bizcorp. All rights reserved.
//

import UIKit
import AssetsLibrary

class PreviewViewController: UIViewController {

    @IBOutlet weak var previewView: VideoPreviewView!
    
    // MARK: Private properties
    fileprivate var assetLibrary: ALAssetsLibrary!
    fileprivate var outputURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize asset library
        assetLibrary = ALAssetsLibrary()
        
        let outputPath = NSTemporaryDirectory().appending("capture.mp4")
        outputURL = URL(fileURLWithPath: outputPath)
        previewView.playURL = (outputURL as! NSURL) as URL!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func save(_ sender: AnyObject) {
        self.assetLibrary.writeVideoAtPath(toSavedPhotosAlbum: outputURL, completionBlock: { (assetURL, error1) -> Void in
            let alert = UIAlertController(title: "Success", message: "Saved to photo album", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }

    @IBAction func back(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
