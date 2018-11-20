//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Evgeniy on 5/21/17.
//  Copyright (c) 2015 bizcorp. All rights reserved.
//

import UIKit
import PBJVision
import AVFoundation
import MBProgressHUD
import AMPopTip

class ViewController: UIViewController, PBJVisionDelegate {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var timelineView: TimelineView!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var controlBar: UIView!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var maskView: UIView!
    
    // MARK: Private properties
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!
    fileprivate var currentVideo: [AnyHashable: Any]?
    fileprivate var videoPaths: [String]!
    fileprivate var popTip: AMPopTip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        PBJVision.sharedInstance().outputFormat = PBJOutputFormat.square
        PBJVision.sharedInstance().captureSessionPreset = AVCaptureSessionPreset1280x720
        PBJVision.sharedInstance().videoBitRate = 1140000
        
        
        // Initialize preview view
        previewLayer = PBJVision.sharedInstance().previewLayer
        previewView.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = previewView.bounds;
        
        // Remove and Next button is disabled at start as we have no clips
        removeButton.isEnabled = false
        nextButton.isEnabled = false
        
        // Initialize video paths array
        videoPaths = [String]()
        
        // Add long press recognizer
        removeButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPressRemoveButton)))
        
        // Customize AMPopTip
        let appearance = AMPopTip.appearance()
        appearance.font = UIFont.boldSystemFont(ofSize: 14)
        appearance.textColor = UIColor.darkGray
        appearance.popoverColor = UIColor(white: 238/255, alpha: 1)
        appearance.borderWidth = 1
        appearance.borderColor = UIColor(white: 0, alpha: 0.3)
        appearance.edgeInsets = UIEdgeInsetsMake(7, 10, 7, 10)
        appearance.edgeMargin = 7
        appearance.arrowSize = CGSize(width: 20, height: 10)
        appearance.shouldDismissOnTap = true
        
        // Mask view hidden at first
        maskView.isHidden = true
        
        // Add long press gesture recognizer to record button
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.recordButtonDown(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        recordButton.addGestureRecognizer(gestureRecognizer)
        
        let focusRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleFocusTap(_:)))
        previewView.addGestureRecognizer(focusRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        previewLayer.frame = previewView.bounds;
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetCapture()
        PBJVision.sharedInstance().startPreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        PBJVision.sharedInstance().stopPreview()
    }
    
    func recordButtonDown(_ sender: AnyObject) {
        if !PBJVision.sharedInstance().isRecording {
            // Dismiss pop tip if shown
            if popTip != nil && popTip!.isVisible {
                popTip!.hide()
            }
            
            startCapture()
            timelineView.addSegment()
        }
    }
    
    @IBAction func recordButtonUpInside(_ sender: AnyObject) {
        if PBJVision.sharedInstance().isRecording {
            endCapture()
        } else {
            if popTip != nil && popTip!.isVisible {
                return
            }
            popTip = AMPopTip()
            popTip!.offset = 13
            popTip!.showText("Press and hold to record", direction: AMPopTipDirection.up, maxWidth: 306, in: self.view, fromFrame: self.view.convert(recordButton.frame, from: controlBar), duration: 2)
        }
    }
    
    @IBAction func recordButtonDragExit(_ sender: AnyObject) {
        if PBJVision.sharedInstance().isRecording {
            endCapture()
        } else {
            if popTip != nil && popTip!.isVisible {
                return
            }
            popTip = AMPopTip()
            popTip!.offset = 13
            popTip!.showText("Press and hold to record", direction: AMPopTipDirection.up, maxWidth: 306, in: self.view, fromFrame: self.view.convert(recordButton.frame, from: controlBar), duration: 2)
        }
    }
    
    @IBAction func finishRecording(_ sender: AnyObject) {
        if videoPaths.count == 0 {
            return
        }
        
        // Dismiss pop tip if shown
        if popTip != nil && popTip!.isVisible {
            popTip!.hide()
        }
        
        if timelineView.currentLength < 3 { // show alert
            if popTip != nil && popTip!.isVisible {
                return
            }
            popTip = AMPopTip()
            popTip!.offset = 4
            popTip!.showText("Record at least to here", direction: AMPopTipDirection.up, maxWidth: 306, in: self.view, fromFrame: self.view.convert(timelineView.minimumTimeRect, from: timelineView), duration: 2)
            
            return;
        }
        
        let fileManger = FileManager.default
        
        let composition = AVMutableComposition()
        
        let track = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))

        var totalTime = kCMTimeZero
        for path in videoPaths {
            let asset = AVURLAsset(url: URL(fileURLWithPath: path), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
            let assetTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
            do {
                try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, assetTrack.timeRange.duration), of: assetTrack, at: totalTime)
            } catch {
                
            }

            totalTime = CMTimeAdd(totalTime, assetTrack.timeRange.duration)
        }
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)
        
        let outputPath = NSTemporaryDirectory().appending("capture.mp4")
        
        if(FileManager.default.fileExists(atPath: outputPath)) {
            do {
                try FileManager.default.removeItem(atPath: outputPath)
            } catch {
                
            }
        }
        
        exporter?.outputURL = URL(fileURLWithPath: outputPath)
        exporter?.outputFileType = AVFileTypeMPEG4
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.labelText = "Exporting..."
        
        exporter?.exportAsynchronously { [unowned self] () -> Void in
            hud?.hide(true)
            self.performSegue(withIdentifier: "Next", sender: self)
        }
    }
    
    @IBAction func flipCamera(_ sender: AnyObject) {
        let vision = PBJVision.sharedInstance()
        
        // Switch Back to/from Front
        vision.cameraDevice = vision.cameraDevice == PBJCameraDevice.back ? PBJCameraDevice.front : PBJCameraDevice.back
    }
    
    @IBAction func removeClip(_ sender: AnyObject) {
        // Dismiss pop tip if shown
        if popTip != nil && popTip!.isVisible {
            popTip!.hide()
        }
        
        if videoPaths.count > 0 {
            if timelineView.isDeleting {
                // Remove path
                let path = videoPaths.removeLast()
                
                var error: NSError?
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    
                }
                
                // Remove last clip in timeline
                timelineView.removeSegment()
                
                if timelineView.leftTime > 0.01 {
                    recordButton.isEnabled = true
                }
                
                // Update remove button image
                removeButton.setImage(UIImage(named: "camera-undo"), for: UIControlState())
                
                // Remove mask view
                maskView.isHidden = true
                
                // Disable Remove and Next button if no clips
                if videoPaths.count == 0 {
                    removeButton.isEnabled = false
                    nextButton.isEnabled = false
                }
            } else {
                // Mark as the user wants to delete
                timelineView.isDeleting = true
                
                // Update remove button image
                removeButton.setImage(UIImage(named: "camera-delete"), for: UIControlState())
            }
        }
    }
    
    //MARK: Capture start/stop
    func startCapture() {
        
        // Enable idle timer
        UIApplication.shared.isIdleTimerDisabled = true
        
        // If marked as deleting, remove it
        if timelineView.isDeleting {
            timelineView.isDeleting = false
        }
        
        let leftTime = timelineView.leftTime
        
        // Set max recording time
        PBJVision.sharedInstance().maximumCaptureDuration = CMTimeMake(Int64(leftTime * 10000), 10000)
        
        // Start capturing
        PBJVision.sharedInstance().startVideoCapture()
    }
    
    func resumeCapture() {
        PBJVision.sharedInstance().resumeVideoCapture()
    }
    
    func pauseCapture() {
        PBJVision.sharedInstance().pauseVideoCapture()
        
        print("duration:\(PBJVision.sharedInstance().capturedVideoSeconds)")
    }
    
    func resetCapture() {
        let vision = PBJVision.sharedInstance()
        vision.delegate = self
        vision.cameraMode = PBJCameraMode.video
        vision.focusMode = PBJFocusMode.continuousAutoFocus
        vision.isVideoRenderingEnabled = true
        vision.additionalCompressionProperties = [AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel]
    }
    
    func endCapture() {
        // End capturing
        PBJVision.sharedInstance().endVideoCapture()
    }
    
    // MARK: PBJVisionDelegate
    func visionDidStartVideoCapture(_ vision: PBJVision) {
        
    }
    
    func vision(_ vision: PBJVision, capturedVideo videoDict: [AnyHashable: Any]?, error: Error?) {
        
        // Diable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
        
        if error != nil {
            if (error! as NSError).domain == PBJVisionErrorDomain && (error! as NSError).code == PBJVisionErrorType.cancelled.rawValue {
                print("recording session cancelled")
            } else {
                print("encounted an error in video capture (\(String(describing: error))")
            }
            
            return
        }
        
        let duration = Float64((videoDict![NSString(string: PBJVisionVideoCapturedDurationKey)] as! NSNumber).doubleValue)
        
        if(duration < 0.3) { // if less than 0.3s, ignore
            timelineView.endSegment(duration)
            timelineView.removeSegment()
            
            if popTip != nil && popTip!.isVisible {
                return
            }
            popTip = AMPopTip()
            popTip!.offset = 13
            popTip!.showText("Press and hold to record", direction: AMPopTipDirection.up, maxWidth: 306, in: self.view, fromFrame: self.view.convert(recordButton.frame, from: controlBar), duration: 2)
            
            return;
        }
        
        if(duration >= timelineView.leftTime) { // reached limit
            recordButton.isEnabled = false
            
            if popTip != nil && popTip!.isVisible {
                return
            }
            popTip = AMPopTip()
            popTip!.offset = 0
            popTip!.showText("Tap to continue", direction: AMPopTipDirection.down, maxWidth: 306, in: self.view, fromFrame: self.view.convert(nextButton.frame, from: topBar), duration: 2)
            
            // Mask preview view
            maskView.isHidden = false
        }
        
        // Mark end of the clip with the length
        timelineView.endSegment(duration)
        
        if(timelineView.leftTime < 0.5) { // If left time is less than 1 sec, disable record
            recordButton.isEnabled = false
            
            if popTip != nil && popTip!.isVisible {
                return
            }
            popTip = AMPopTip()
            popTip!.offset = 0
            popTip!.showText("Tap to continue", direction: AMPopTipDirection.down, maxWidth: 306, in: self.view, fromFrame: self.view.convert(nextButton.frame, from: topBar), duration: 2)
            
            // Mask preview view
            maskView.isHidden = false
        }
        
        // Enable Remove and Next button as we have clips
        removeButton.isEnabled = true
        nextButton.isEnabled = true
        
        currentVideo = videoDict
        
        let videoPath = currentVideo![PBJVisionVideoPathKey] as! String
        videoPaths.append(videoPath)
        
    }
    
    func vision(_ vision: PBJVision, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        timelineView.updateSegment(vision.capturedVideoSeconds)
    }
    
    func visionDidEndVideoCapture(_ vision: PBJVision) {
        print(#function)
    }
    
    // MARK: Long press gesture recognizer
    func longPressRemoveButton() {
        let alert: UIAlertController = UIAlertController(title: "Discard Clips", message: "Would you like to discard all clips? This cannot be undone", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Discard", style: UIAlertActionStyle.default, handler: { [unowned self] (action) -> Void in
            // Remove files at paths first
            for path in self.videoPaths {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    
                }
            }
            
            // Remove all paths
            self.videoPaths.removeAll(keepingCapacity: false)
            
            // Remove all segments
            self.timelineView.removeAllSegments()
            
            // Disable Remove and Next button
            self.removeButton.isEnabled = false
            self.nextButton.isEnabled = false
            
            // Enable record button
            self.recordButton.isEnabled = true
            
            // Hide dim view
            self.maskView.isHidden = true
            
            // Update remove button image
            self.removeButton.setImage(UIImage(named: "camera-undo"), for: UIControlState())
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Focus
    func handleFocusTap(_ recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: previewView)
        let adjustPoint = PBJVisionUtilities.convertToPointOfInterest(fromViewCoordinates: touchPoint, inFrame: previewView.frame);
        PBJVision.sharedInstance().focus(atAdjustedPointOfInterest: adjustPoint)
    }
}

