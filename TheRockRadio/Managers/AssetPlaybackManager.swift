/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 `AssetPlaybackManager` is the class that manages the playback of Assets in this sample using Key-value observing on various AVFoundation classes.
 */

import UIKit
import AVFoundation
import MediaPlayer

private var PlayerContext = 0
private var PlayerRateContext = 0
private var TimedMetadataContext = 0

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
	
	/// The `NSKeyValueObservation` for the KVO on \AVPlayer
	private var playerPlayerObserver: NSKeyValueObservation?
//
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
				loggingText = loggingText.add(string: "playerItemObserver item.status = \(item.status.rawValue)")
                if item.status == .readyToPlay {
                    if !strongSelf.readyForPlayback {
//						loggingText = loggingText.add(string: "playerItem readyToPlay")
                        strongSelf.readyForPlayback = true
						retryCount = 0
                        strongSelf.delegate?.streamPlaybackManager(strongSelf, playerReadyToPlay: strongSelf.player)
                    }
                } else if item.status == .failed {
                    let error = item.error
					loggingText = loggingText.add(string: "playerItemObserver item.status = .failed")
					loggingText = loggingText.add(string: "playerItemObserver error loading asset = \(String(describing: error?.localizedDescription))")
					// try to recover
					if retryCount < 15 {
						retryCount += 1
						loggingText = loggingText.add(string: "playerItemObserver error retrying)")
						self?.perform(#selector(self?.postReloadNotification), with: nil, afterDelay: Double(retryCount))
					} else {
						// $TODO: retried a bunch now what?
						loggingText = loggingText.add(string: "playerItemObserver error 15 RETRIES exhausted)")
					}
                }
			}
        }
    }
	
	// send message to mainVC to reload the URL due to error conditions
	@objc func postReloadNotification() {
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReloadURL"), object: nil)
	}
	
    /// The Asset that is currently being loaded for playback.
    private var asset: Asset? {
        willSet {
            /// Remove any previous KVO observer.
            guard let urlAssetObserver = urlAssetObserver else { return }
            urlAssetObserver.invalidate()
        }
        didSet {
//			loggingText = loggingText.add(string: "var asset didSet")
            if let asset = asset {
                urlAssetObserver = asset.urlAsset.observe(\AVURLAsset.isPlayable, options: [.new, .initial]) { [weak self] (urlAsset, _) in
                    guard let strongSelf = self, urlAsset.isPlayable == true else { return }
                    
					strongSelf.playerItem = nil
					strongSelf.player.replaceCurrentItem(with: nil)
					strongSelf.readyForPlayback = false
                    strongSelf.playerItem = AVPlayerItem(asset: urlAsset)
                    strongSelf.player.replaceCurrentItem(with: strongSelf.playerItem)
					DispatchQueue.main.async {
						if TimedMetadataContext == 0 {
							loggingText = loggingText.add(string: "addObserver forKeyPath: timedMetadata")
							strongSelf.playerItem?.addObserver(strongSelf, forKeyPath: "timedMetadata", options: [.new], context: &TimedMetadataContext)
						}
						if PlayerContext == 0 {
							loggingText = loggingText.add(string: "addObserver forKeyPath: status")
							strongSelf.player.addObserver(strongSelf, forKeyPath: "status", options: [.new], context: &PlayerContext)
						}
						if PlayerRateContext == 0 {
							loggingText = loggingText.add(string: "addObserver forKeyPath: rate")
							strongSelf.player.addObserver(strongSelf, forKeyPath: "rate", options: [.new], context: &PlayerRateContext)
						}
					}
//					loggingText = loggingText.add(string: "var asset didSet new PlayerItem")
                }
            }
            else {
                playerItem = nil
                player.replaceCurrentItem(with: nil)
                readyForPlayback = false
				loggingText = loggingText.add(string: "var asset didSet FAILED")
				// $TODO: put up an alert to try again.
            }
        }
    }
    
    // MARK: Intitialization
    override private init() {
        super.init()
		loggingText = loggingText.add(string: "AssetPlaybackManager init()")
		// metadata observer
        playerObserver = player.observe(\AVPlayer.currentItem, options: [.new]) { [weak self] (player, _) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.streamPlaybackManager(strongSelf, playerCurrentItemDidChange: player)
        }
		//        player.usesExternalPlaybackWhileExternalScreenIsActive = true $TODO: MJG ??? was true
    }
    
    deinit {
		loggingText = loggingText.add(string: "AssetPlaybackManager deinit")
        /// Remove any KVO observer.
        playerObserver?.invalidate()
			if TimedMetadataContext != 0 {
				loggingText = loggingText.add(string: "removeObserver forKeyPath: timedMetadata")
				self.playerItem?.removeObserver(self, forKeyPath: "timedMetadata", context: &TimedMetadataContext)
			}
			if PlayerContext != 0 {
				loggingText = loggingText.add(string: "removeObserver forKeyPath: status")
				self.player.removeObserver(self, forKeyPath: "status", context: &PlayerContext)
			}
			if PlayerRateContext != 0 {
				loggingText = loggingText.add(string: "removeObserver forKeyPath: rate")
				self.player.removeObserver(self, forKeyPath: "rate", context: &PlayerRateContext)
			}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		
		if context == &TimedMetadataContext {
			loggingText = loggingText.add(string: "observeValue TimedMetadataContext")
			guard let observedObject: AVPlayerItem = object as? AVPlayerItem else { return }
			guard (observedObject.timedMetadata != nil) else { return }
			for metadata in observedObject.timedMetadata! {
				if let songName = metadata.value(forKey: "value") as? String {
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: songName)
				}
			}
		} else
		if context == &PlayerContext {
			loggingText = loggingText.add(string: "observeValue PlayerContext")
			guard let thePlayer: AVPlayer = object as? AVPlayer else {
				loggingText = loggingText.add(string: "observeValue PlayerContext could not get object as AVPlayer")
				return
			}
			let status = thePlayer.status
			if status == .failed {
				loggingText = loggingText.add(string: "observeValue PlayerContext status = .failed")
			}
		} else if context == &PlayerRateContext {
			loggingText = loggingText.add(string: "observeValue PlayerRateContext")
			guard let thePlayer: AVPlayer = object as? AVPlayer else {
				loggingText = loggingText.add(string: "observeValue PlayerRate could not get object as AVPlayer")
				return
			}
			let playerRate = thePlayer.rate
			loggingText = loggingText.add(string: "observeValue PlayerRate rate = \(playerRate)")
			if playerRate == 0.0 {
				lastTimePaused = Date.timeIntervalSinceReferenceDate
			}
		}
	}
	
    /**
     Replaces the currently playing `Asset`, if any, with a new `Asset`. If nil
     is passed, `AssetPlaybackManager` will handle unloading the existing `Asset`
     and handle KVO cleanup.
     */
    func setAssetForPlayback(_ asset: Asset?) {
//		loggingText = loggingText.add(string: "setAssetForPlayback")
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
