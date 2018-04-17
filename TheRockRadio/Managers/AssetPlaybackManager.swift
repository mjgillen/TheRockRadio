/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 `AssetPlaybackManager` is the class that manages the playback of Assets in this sample using Key-value observing on various AVFoundation classes.
 */

import UIKit
import AVFoundation
import MediaPlayer

class AssetPlaybackManager: NSObject {
    
    // MARK: Properties
    
    /// Singleton for AssetPlaybackManager.
    static let sharedManager = AssetPlaybackManager()
    
    weak var delegate: AssetPlaybackDelegate?
    
    /// The instance of AVPlayer that will be used for playback of AssetPlaybackManager.playerItem.
    private let player = AVPlayer()
    
    /// A Bool tracking if the AVPlayerItem.status has changed to .readyToPlay for the current AssetPlaybackManager.playerItem.
    private var readyForPlayback = false
    
    /// The `NSKeyValueObservation` for the KVO on \AVPlayerItem.status.
    private var playerItemObserver: NSKeyValueObservation?
    
    /// The `NSKeyValueObservation` for the KVO on \AVURLAsset.isPlayable.
    private var urlAssetObserver: NSKeyValueObservation?
    
    /// The `NSKeyValueObservation` for the KVO on \AVPlayer.currentItem.
    private var playerObserver: NSKeyValueObservation?
	
	/// The AVPlayerItem associated with AssetPlaybackManager.asset.urlAsset
    private var playerItem: AVPlayerItem? {
        willSet {
            /// Remove any previous KVO observer.
            guard let playerItemObserver = playerItemObserver else {return }
            
            playerItemObserver.invalidate()
        }
        
        didSet {
            playerItemObserver = playerItem?.observe(\AVPlayerItem.status, options: [.new, .initial]) { [weak self] (item, _) in
                guard let strongSelf = self else { return }
                
                if item.status == .readyToPlay {
                    if !strongSelf.readyForPlayback {
                        strongSelf.readyForPlayback = true
                        strongSelf.delegate?.streamPlaybackManager(strongSelf, playerReadyToPlay: strongSelf.player)
                    }
                } else if item.status == .failed {
                    let error = item.error
                    
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    
    /// The Asset that is currently being loaded for playback.
    private var asset: Asset? {
        willSet {
            /// Remove any previous KVO observer.
            guard let urlAssetObserver = urlAssetObserver else { return }
            
            urlAssetObserver.invalidate()
        }
        
        didSet {
            if let asset = asset {
                urlAssetObserver = asset.urlAsset.observe(\AVURLAsset.isPlayable, options: [.new, .initial]) { [weak self] (urlAsset, _) in
                    guard let strongSelf = self, urlAsset.isPlayable == true else { return }
                    
                    strongSelf.playerItem = AVPlayerItem(asset: urlAsset)
                    strongSelf.player.replaceCurrentItem(with: strongSelf.playerItem)
					strongSelf.playerItem?.addObserver(strongSelf, forKeyPath: "timedMetadata", options: [.new], context: nil)
                }
            }
            else {
                playerItem = nil
                player.replaceCurrentItem(with: nil)
                readyForPlayback = false
            }
        }
    }
    
    // MARK: Intitialization
    
    override private init() {
        super.init()
		// metadata observer
        playerObserver = player.observe(\AVPlayer.currentItem, options: [.new]) { [weak self] (player, _) in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.streamPlaybackManager(strongSelf, playerCurrentItemDidChange: player)
        }
        
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
    }
    
    deinit {
        /// Remove any KVO observer.
        playerObserver?.invalidate()
    }
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		

		if keyPath != "timedMetadata" {
			print("not timedMetadata")
			return
		}
		
		print("observed Value for Keypath called")
		let observedPlayerItem: AVPlayerItem = self.playerItem!
		for metadata in observedPlayerItem.timedMetadata! {
			if let songName = metadata.value(forKey: "value") as? String {
				print("song name is '\(songName)'")
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SongName"), object: songName)				
				//			print(metadata.value ?? "fred")
				//			let description = metadata.key?.description ?? ""
				//			let keySpace = metadata.keySpace ?? nil
				//			let commonKey = metadata.commonKey ?? nil
				//			let stringValue = metadata.stringValue ?? ""
				//			print("\n key: \(description) \n keySpace: \(String(describing: keySpace)) \n commonKey: \(String(describing: commonKey)) \n value: \(stringValue)")
				//
				let nowPlaying = ["SongName": songName]
				MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
			}
		}
		let observedObject: AVPlayerItem = object as! AVPlayerItem
		print(observedObject.timedMetadata?.count ?? 0)
		for metadata in observedObject.timedMetadata! {
			print(metadata)
			print(metadata.commonKey)
			if let songName = metadata.value(forKey: "value") as? String {
				print("observedObject song name is '\(songName)'")
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: songName)
				//			let description = metadata.key?.description ?? ""
				//			let keySpace = metadata.keySpace ?? nil
				//			let commonKey = metadata.commonKey ?? nil
				//			let stringValue = metadata.stringValue ?? ""
				//			print("\n key: \(description) \n keySpace: \(String(describing: keySpace)) \n commonKey: \(String(describing: commonKey)) \n value: \(stringValue)")
				//
//				let nowPlaying = ["SongName": songName]
//				MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
			}
		}
	}

    
    /**
     Replaces the currently playing `Asset`, if any, with a new `Asset`. If nil
     is passed, `AssetPlaybackManager` will handle unloading the existing `Asset`
     and handle KVO cleanup.
     */
    func setAssetForPlayback(_ asset: Asset?) {
        self.asset = asset
    }
}

/// AssetPlaybackDelegate provides a common interface for AssetPlaybackManager to provide callbacks to its delegate.
protocol AssetPlaybackDelegate: class {
    
    /// This is called when the internal AVPlayer in AssetPlaybackManager is ready to start playback.
    func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer)
    
    /// This is called when the internal AVPlayer's currentItem has changed.
    func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerCurrentItemDidChange player: AVPlayer)
}
