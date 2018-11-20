//
//  TimelineView.swift
//  VideoRecorder
//
//  Created by Evgeniy on 5/23/15.
//  Copyright (c) 2015 bizcorp. All rights reserved.
//

import UIKit
import AVFoundation

class TimelineView: UIView {
    var isDeleting: Bool {
        didSet {
            if isDeleting {
                blinkView.isHidden = true
                if imageViewsArray.count > 0 {
                    let imageView = imageViewsArray.last
                    imageView!.image = UIImage(named: "camera-progress-red-block")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 0, 0, 2))
                }
            } else {
                if imageViewsArray.count > 0 {
                    let imageView = imageViewsArray.last
                    imageView!.image = UIImage(named: "camera-progress-blue-block")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 0, 0, 2))
                }
            }
        }
    }
    
    fileprivate var isRecording = false
    
    let totalSecond: Float64 = 15
    let minimumTime: Float64 = 3
    
    /**
    Currently recorded time
    */
    fileprivate(set) var currentLength: Float64 = 0
    
    /**
    Max remaining time to record
    */
    var leftTime: Float64 {
        get {
            return max(0, totalSecond - currentLength)
        }
    }
    
    var minimumTimeRect: CGRect {
        get {
            return CGRect(x: Int(Float64(self.frame.size.width) * minimumTime / totalSecond), y: 1, width: 1, height: 6)
        }
    }
    
    // Private properties
    fileprivate var blinkView: UIView!
    fileprivate var blinkTimer: Timer!
    fileprivate var imageViewsArray: [UIImageView]!
    fileprivate var timeOffsets: [Float64]!
    
    // MARK: init
    override init(frame: CGRect) {
        isDeleting = false
        super.init(frame: frame)
        initView()
    }
    
    required init(coder aDecoder: NSCoder) {
        isDeleting = false
        super.init(coder: aDecoder)!
        initView()
    }
    
    func initView() {
        self.backgroundColor = UIColor.black
        blinkView = UIView(frame: CGRect(x: 0, y: 1, width: 6, height: 6))
        blinkView.backgroundColor = UIColor.white
        self.addSubview(blinkView)
        
        blinkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(TimelineView.blinkIndicator), userInfo: nil, repeats: true)
        
        imageViewsArray = [UIImageView]()
        timeOffsets = [Float64]()
        currentLength = 0
    }
    
    // MARK: Public methods
    func addSegment() {
        let imageView = UIImageView(image: UIImage(named: "camera-progress-blue-block")?.resizableImage(withCapInsets: UIEdgeInsetsMake(0, 0, 0, 2)))
        var x: CGFloat
        let lastImageView = imageViewsArray.last
        x =  CGFloat(currentLength) * self.frame.width / CGFloat(totalSecond)
        imageView.layer.anchorPoint = CGPoint.zero
        imageView.frame = CGRect(x: floor(x), y: 1, width: 0, height: 6)
        self.addSubview(imageView)
        self.sendSubview(toBack: imageView)
        imageViewsArray.append(imageView)
        
        isRecording = true
        blinkView.isHidden = false // show blink view
    }
    
    func updateSegment(_ time: Float64) {
        let imageView = imageViewsArray.last
        if let imageView = imageView {
            imageView.bounds = CGRect(x: 0, y: 0, width: floor(CGFloat(time * Float64(self.bounds.width) / totalSecond)), height: imageView.bounds.height)
            var x = imageView.frame.maxX
            x -= blinkView.frame.width
            x = x < 0 ? 0 : x
            if imageViewsArray.count > 1 {
                let prevlastImageView = imageViewsArray[imageViewsArray.count - 2]
                x = max(prevlastImageView.frame.maxX, x)
            }
            blinkView.frame = CGRect(x: x, y: blinkView.frame.minY, width: blinkView.frame.width, height: blinkView.frame.height)
        }
    }
    
    func endSegment(_ time: Float64) {
        let imageView = imageViewsArray.last
        if let imageView = imageView {
            currentLength += time
            imageView.frame = CGRect(x: floor(imageView.frame.minX), y: imageView.frame.minY, width: floor(CGFloat(currentLength) * self.frame.width / CGFloat(totalSecond)) - floor(imageView.frame.minX), height: imageView.bounds.height)
            timeOffsets.append(currentLength)
            blinkView.frame = CGRect(x: imageView.frame.maxX, y: blinkView.frame.minY, width: blinkView.frame.width, height: blinkView.frame.height)
        }
        
        isRecording = false
    }
    
    func removeSegment() {
        if imageViewsArray.count > 0 {
            let lastImageView = imageViewsArray.removeLast()
            lastImageView.removeFromSuperview()
            timeOffsets.removeLast()
            
            var x: CGFloat = 0
            if imageViewsArray.count > 0 {
                let lastImageView = imageViewsArray.last
                x = lastImageView!.frame.maxX
            }
            
            blinkView.frame = CGRect(x: x, y: blinkView.frame.minY, width: blinkView.frame.width, height: blinkView.frame.height)
            
            if timeOffsets.count > 0 {
                currentLength = timeOffsets.last!
            } else {
                currentLength = 0
            }
        }
        isDeleting = false
    }
    
    func removeAllSegments() {
        self.isDeleting = false
        currentLength = 0
        timeOffsets.removeAll(keepingCapacity: false)
        for imageView in imageViewsArray {
            imageView.removeFromSuperview()
        }
        imageViewsArray.removeAll(keepingCapacity: false)
        blinkView.frame = CGRect(x: 0, y: 1, width: 6, height: 6)
    }
    
    // MARK: Timer callback
    func blinkIndicator() {
        if isRecording { // when recording, show blink view always
            blinkView.isHidden = false
        } else if isDeleting { // when deleting, hide blink view
            blinkView.isHidden = true
        } else {    // toggle blink view hidden status
            blinkView.isHidden = !blinkView.isHidden
        }
    }
    
    // MARK: Override drawRect
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        let grayFactor: CGFloat = 51 / 255
        context?.setFillColor(red: grayFactor, green: grayFactor, blue: grayFactor, alpha: 1)
        context?.setLineWidth(0)
        context?.fill(minimumTimeRect)
    }
}
