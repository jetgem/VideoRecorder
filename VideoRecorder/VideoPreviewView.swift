//
//  VideoPreviewView.swift
//  VideoRecorder
//
//  Created by Evgeniy on 5/23/15.
//  Copyright (c) 2015 bizcorp. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPreviewView: UIView {
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playButtonView: UIImageView!
    
    // MARK: Init and Deinit
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
    }
    
    fileprivate func initialize() {
        playButtonView = UIImageView()
        self.addSubview(playButtonView)
        self.backgroundColor = UIColor.black
        playButtonView.alpha = 0
        playButtonView.translatesAutoresizingMaskIntoConstraints = false
        
        // Put play button in center
        self.addConstraint(NSLayoutConstraint(item: playButtonView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: playButtonView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        playButtonView.addConstraint(NSLayoutConstraint(item: playButtonView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 53))
        playButtonView.addConstraint(NSLayoutConstraint(item: playButtonView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 53))
        
        // Add event handler
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(VideoPreviewView.tapVideoView))
        self.addGestureRecognizer(recognizer)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Public player url setter
    var playURL: URL! {
        didSet {
            // Stop current playing
            stop()
            
            // Set player item to player and play
            playerItem = AVPlayerItem(url: playURL)
            player = AVPlayer(playerItem: playerItem)
            player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
            (self.layer as! AVPlayerLayer).player = player
            play()
            
            // Add observer
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewView.playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    }
    
    fileprivate func play() {
        if player != nil {
            player.play()
        }
    }
    
    fileprivate func stop() {
        if player != nil {
            player.pause()
            player = nil
            (self.layer as! AVPlayerLayer).player = nil
            playerItem = nil
        }
    }
    
    // Set current view layer as AVPlayerLayer
    override class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }
    
    // Notified when the player is reached to end
    func playerItemDidReachEnd(_ notification: Notification) {
        let p = notification.object as! AVPlayerItem
        p.seek(to: kCMTimeZero)
    }
    
    // Tap handler
    func tapVideoView() {
        playButtonView.image = UIImage(named: "video-play")
        
        if player.rate > 0 && player.error == nil {
            // current playing and needs to stop
            playButtonView.alpha = 0.8
            player.pause()
        } else {
            // paused, and play from the beginning
            playButtonView.alpha = 0
            playerItem.seek(to: kCMTimeZero)
            player.play()
        }
    }
}
