//
//  HomeScreenViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/12/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
import SystemConfiguration

// Logging
var loggingText = ""
var loggingLabel = UILabel()

// state flags
var avPlayerVCisReady = false
var assetIsReady = false
var isReachable = false
var retryCount = 0

class HomeScreenViewController: UIViewController {

	static let kReachabilityChangedNotification = "kNetworkReachabilityChangedNotification"

	static let presentPlayerViewControllerSegueID = "PresentPlayerViewControllerSegueIdentifier"
	static let defaultTrackTitle = "KEBF/KZSR\n"
	static let defaultTrackArtist = "97.3 / 107.9 The Rock Radio"
	static let defaultAlbumArtwork: UIImage = #imageLiteral(resourceName: "RockLogo")
	static let streamingURL = "https://streaming.radio.co/s96fbbec3a/listen"
	static let playlistURL = "https://public.radio.co/stations/s96fbbec3a/status"
	
	
	fileprivate var playerViewController: AVPlayerViewController?
	
	// UI in the player window
	var songLabel: UILabel!
	var currentTrackTitle = HomeScreenViewController.defaultTrackTitle
	var currentTrackArtist = HomeScreenViewController.defaultTrackArtist
	var albumArtwork: UIImageView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		loggingText = loggingText.add(string: "viewDidLoad")
		
		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
		
		let notificationCenter = NotificationCenter.default
		// inter process commmunication
		notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleNewSongNotification), name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(restartStream), name: NSNotification.Name(rawValue: "RestartStream"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(reloadURL), name: NSNotification.Name(rawValue: "ReloadURL"), object: nil)

		// handle interruptions
		notificationCenter.addObserver(self, selector: #selector(handleInterruption), name: .AVAudioSessionInterruption, object: nil)
		notificationCenter.addObserver(self, selector: #selector(handleRouteChange), name: .AVAudioSessionRouteChange, object: nil)
		notificationCenter.addObserver(self, selector: #selector(handleMediaReset), name: .AVAudioSessionMediaServicesWereReset, object: nil)
		
//		UIApplication.shared.beginReceivingRemoteControlEvents()
//		notificationCenter.addObserver(self, selector: #selector(handleRemoteControlEvent), name: NSNotification.Name(rawValue: "TogglePlay"), object: nil)
//		notificationCenter.addObserver(self, selector: #selector(handleRemoteControlEvent), name: NSNotification.Name(rawValue: "TogglePause"), object: nil)
		
//		// Reachability
//		if Reachability.isConnectedToNetwork() {
//			loggingText = loggingText.add(string: "Internet Connection Available!")
//			isReachable = true
//		} else {
//			loggingText = loggingText.add(string: "Internet Connection not Available!")
//			isReachable = false
//		}
		
		// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
		notificationCenter.addObserver(self, selector:#selector(reachabilityChanged), name:NSNotification.Name(rawValue: HomeScreenViewController.kReachabilityChangedNotification), object:nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		loggingText = loggingText.add(string: "viewWillAppear")
		super.viewWillAppear(animated)
//		NotificationCenter.default.post(name: NSNotification.Name("RestartStream"), object: nil)
	}

	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override var prefersStatusBarHidden: Bool {
		return false
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if segue.identifier == HomeScreenViewController.presentPlayerViewControllerSegueID {
			guard let seguePlayerViewController = segue.destination as? AVPlayerViewController else { return }
			loggingText = loggingText.add(string: "prepare(for segue: AVPlayerViewController")
			//Grab a reference for the destinationViewController to use in later delegate callbacks from
			//AssetPlaybackManager.
			playerViewController = seguePlayerViewController
			
			// Load the new Asset to playback into AssetPlaybackManager.
			let urlAsset = AVURLAsset.init(url: URL.init(string: HomeScreenViewController.streamingURL)!)
			let stream = StreamListManager.shared.streams.first
			let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
			AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
		}
	}
	
	@objc func restartStream(notification: NSNotification) {
		loggingText = loggingText.add(string: "restartStream")

		// if not yet setup bail
		if !avPlayerVCisReady {
			loggingText = loggingText.add(string: "restartStream avPlayerVCisReady NOT ready")
			return
		}
		// if we have a player then try to hit the play button
		guard playerViewController?.player != nil else {
			loggingText = loggingText.add(string: "restartStream playerViewController?.player is nil")
			loggingText = loggingText.add(string: "restartStream calling reloadURL")
			reloadURL()
			return
		}
		loggingText = loggingText.add(string: "restartStream player.play()")
		playerViewController?.player?.play()
		getStationPlaylistInfo()
	}
	
	@objc func reloadURL() {
		loggingText = loggingText.add(string: "reloadURL")
		
		// if not yet setup bail
		if !avPlayerVCisReady {
			loggingText = loggingText.add(string: "reloadURL avPlayerVCisReady NOT ready")
			return
		}

		// Load the Asset to playback into AssetPlaybackManager.
		loggingText = loggingText.add(string: "reloadURL reloading asset")
		let urlAsset = AVURLAsset.init(url: URL.init(string: HomeScreenViewController.streamingURL)!)
		let stream = StreamListManager.shared.streams.first
		let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
		AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
	}

	@objc func handleNewSongNotification(notification: NSNotification) {
		loggingText = loggingText.add(string: "handleNewSongNotification")
		getStationPlaylistInfo()
	}
	
	func getStationPlaylistInfo() {
		loggingText = loggingText.add(string: "getStationPlaylistInfo")
		let radioURL = URL.init(string: HomeScreenViewController.playlistURL)
		let task = URLSession.shared.dataTask(with: radioURL!) { data, response, error in
			if let error = error {
				self.handleClientError(error)
				return
			}
			guard let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode) else {
					self.handleServerError(response)
					return
			}
			if let mimeType = httpResponse.mimeType, mimeType == "application/json",
				let data = data {
				do {
					let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
					self.processJSON(jsonData)
				}
				catch {
					print(error)
				}
			}
		}
		task.resume()
	}
	
	func processJSON(_ jsonData: [String : Any]) {
		for dict in jsonData {
			if dict.key == "current_track" {
				guard let currentTrackDict = dict.value as? [String : Any] else { return }
				if let title = currentTrackDict["title"] as? String {
					
					let tempString = title
//					let tempString = "Fred" // For testing
					if tempString.contains("-") {
						let separator = tempString.index(of: "-")!
						let artistSlice = tempString[..<separator]
						if separator < tempString.endIndex {
							let afterSeparator = tempString.index(after: separator)
							if afterSeparator < tempString.endIndex {
								let next = tempString.index(after: afterSeparator)
								let titleSlice = tempString.suffix(from: next)
								currentTrackTitle = String(titleSlice)
								currentTrackTitle = currentTrackTitle + "\n"
								currentTrackArtist = String(artistSlice)
							}
							else {
								currentTrackTitle = tempString + "\n"
								currentTrackArtist = HomeScreenViewController.defaultTrackArtist
							}
						}
						else {
							currentTrackTitle = tempString + "\n"
							currentTrackArtist = HomeScreenViewController.defaultTrackArtist
						}
					}
					else {
						currentTrackTitle = tempString + "\n"
						currentTrackArtist = HomeScreenViewController.defaultTrackArtist
					}
				}
				else {
					currentTrackTitle = HomeScreenViewController.defaultTrackTitle
					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
				}
				
//$TODO: Needed?				let start_time = currentTrackDict["start_time"] as! String
				if currentTrackTitle == "Unknown" || currentTrackTitle == "" {
					currentTrackTitle = HomeScreenViewController.defaultTrackTitle
					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
				}
				
				if currentTrackArtist == "" {
					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
				}
				
				let titleAttributes: [NSAttributedStringKey : Any] = [
					NSAttributedStringKey.foregroundColor : UIColor.black,
					NSAttributedStringKey.font : UIFont.systemFont(ofSize: 30)
				]
				let displayString = NSMutableAttributedString.init(string: currentTrackTitle, attributes: titleAttributes)
				let artistAttributes = [
					NSAttributedStringKey.foregroundColor : UIColor.red,
					NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20)
				]
				displayString.append(NSAttributedString.init(string: currentTrackArtist, attributes: artistAttributes))
				
				DispatchQueue.main.async {
					self.songLabel.attributedText = displayString
				}
				updateNowPlaying()
				
				if let artwork_url = currentTrackDict["artwork_url"] as? String,
					let artworkURL = URL.init(string: artwork_url) {
					if artwork_url.contains("images.radio.co/station_logos/s96fbbec3a") {
						DispatchQueue.main.async {
							self.albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork
						}
					} else {

						let task = URLSession.shared.dataTask(with: artworkURL) { data, response, error in
							if let error = error {
								self.handleClientError(error)
								return
							}
							guard let httpResponse = response as? HTTPURLResponse,
								(200...299).contains(httpResponse.statusCode) else {
									self.handleServerError(response)
									return
							}
							
							if let data = data {
								let dataImage = UIImage.init(data: data)
								DispatchQueue.main.async {
									self.albumArtwork.image = dataImage
								}
							}
						}
						task.resume()
					}
				}
				else {
					DispatchQueue.main.async {
						self.albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork
					}
				}
			}
			else if dict.key == "history" {
// $TODO: Fix when we can
//				let historyArray = dict.value as! [Any]
//				var songArray: [[String: Any]] = [[:]]
//				for track in historyArray {
////					print(track)
//					let x = track as! [String : Any]
//					let song = x["title"] as? String
//					print(song)
//					songArray.append(x)
//				}
//				print("test")
//				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: dict.value as? [AnyHashable : Any])
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: jsonData)
			}
		}
	}
	
	func updateNowPlaying() {
		// Set Metadata to be Displayed in Now Playing Info Center
		let playerRate = playerViewController?.player?.rate ?? 0.0
		let infoCenter = MPNowPlayingInfoCenter.default()
		infoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: currentTrackTitle,
									 MPMediaItemPropertyArtist: currentTrackArtist,
									 MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
									 MPNowPlayingInfoPropertyPlaybackRate: playerRate
//									 MPMediaItemPropertyPersistentID: ???
//									 MPMediaItemPropertyAlbumTitle: "",
//									 MPMediaItemPropertyGenre: "",
//									 MPMediaItemPropertyReleaseDate: "",
//									 MPMediaItemPropertyPlaybackDuration: 231,
//									 MPMediaItemPropertyArtwork: mediaItemArtwork,
//									 MPNowPlayingInfoPropertyElapsedPlayback: 53,
//									 MPNowPlayingInfoPropertyPlaybackQueueCount: 13,
//									 MPNowPlayingInfoPropertyPlaybackQueueIndex: 3
		]
	}
	
	func handleClientError(_ error: Error) {
		loggingText = loggingText.add(string: "handleClientError")
}
	func handleServerError(_ response: URLResponse?) {
		loggingText = loggingText.add(string: "handleServerError")
	}

	@objc func handleInterruption(notification: Notification) {
		loggingText = loggingText.add(string: "handleInterruption notification")
		guard let userInfo = notification.userInfo,
			let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
				return
		}
		guard let playerViewController = playerViewController else { return }
		if type == .began {
			// Interruption began, take appropriate actions
			loggingText = loggingText.add(string: "Interruption began")

			if playerViewController.player?.rate == 1.0 {
				playerViewController.player?.pause()
				loggingText = loggingText.add(string: "Interruption pause()")
			}
		}
		else if type == .ended {
			if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
				let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
				if options.contains(.shouldResume) {
					// Interruption Ended - playback should resume
					loggingText = loggingText.add(string: "Interruption Ended")

					if playerViewController.player?.rate == 0.0 {
						playerViewController.player?.play()
						loggingText = loggingText.add(string: "Interruption play()")
					}
				} else {
					// Interruption Ended - playback should NOT resume
					loggingText = loggingText.add(string: "Interruption Ended DO NOT RESUME")
				}
			}
		}
		updateNowPlaying()
	}
	
	@objc
	func handleRouteChange(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
			let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
				return
		}
		loggingText = loggingText.add(string: "handleRouteChange")
		switch reason {
		case .newDeviceAvailable:
			
			// do not automatically start playing.
			loggingText = loggingText.add(string: "handleRouteChange newDeviceAvailable")

//			let session = AVAudioSession.sharedInstance()
//			for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//				headphonesConnected = true
//				break
//			}
		case .oldDeviceUnavailable:
			loggingText = loggingText.add(string: "handleRouteChange oldDeviceUnavailable")

//			if let previousRoute =
//				userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
//				for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//					headphonesConnected = false
//					break
//				}
//			}
		default: ()
			loggingText = loggingText.add(string: "handleRouteChange default")
		}
	}

	@objc
	func handleMediaReset(notification: Notification) {
		guard let userInfo = notification.userInfo else { return }
		
		print("MJG ------------------------------------------------------------------->>> handleMediaReset with reason = \(userInfo)")
		loggingText = loggingText.add(string: "handleMediaReset with reason = \(userInfo)")

//		switch reason {
//		case .newDeviceAvailable:
//			let session = AVAudioSession.sharedInstance()
//			for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//				//				headphonesConnected = true
//				break
//			}
//		case .oldDeviceUnavailable:
//			if let previousRoute =
//				userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
//				for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//					//					headphonesConnected = false
//					break
//				}
//			}
//		default: ()
//		}
	}

	@objc
	func handleRemoteControlEvent(notification: Notification) {
//		guard let userInfo = notification.userInfo,
//			let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
//			let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
//				return
//		}
	}
	
	/*!
	* Called by Reachability whenever status changes.
	*/
	@objc func reachabilityChanged(notification: NSNotification) {
//	Reachability* curReach = [note object];
//	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	}

}

extension HomeScreenViewController: AssetPlaybackDelegate {
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
		
		loggingText = loggingText.add(string: "streamPlaybackManager: playerReadyToPlay")
		assetIsReady = true

		// $TODO: do we need to tell CarPlay we are ready?
		playerViewController?.player = player
		
		// setup properties for the AVPlayerViewController
		playerViewController?.allowsPictureInPicturePlayback = false
		playerViewController?.updatesNowPlayingInfoCenter = true
		playerViewController?.contentOverlayView?.backgroundColor = .white
		
		// setup the label
		let pvcWidth = Double((playerViewController?.contentOverlayView?.frame.width)!)
		let pvcHeight = Double((playerViewController?.contentOverlayView?.frame.height)!)
		let offsetX = 10.0
		let offsetY = pvcHeight - 125.0
		var rect = CGRect(x: offsetX, y: offsetY, width: pvcWidth - offsetX, height: 75.0)
		songLabel = UILabel.init(frame: rect)
		songLabel.text = HomeScreenViewController.defaultTrackTitle
		songLabel.font = UIFont.systemFont(ofSize: 30.0)
		songLabel.numberOfLines = 2
		songLabel.lineBreakMode = .byTruncatingMiddle
		songLabel.textAlignment = .center
		
		// album artwork image
		rect.origin.x = 0.0
		rect.origin.y = 5.0
		rect.size.width = CGFloat(pvcWidth / 2.0)
		rect.size.height = CGFloat(pvcHeight / 2.0)
		albumArtwork = UIImageView.init(frame: rect)
		albumArtwork.contentMode = .scaleAspectFit
		albumArtwork.center.x = (playerViewController?.contentOverlayView?.center.x)!
		albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork

		// add them to the view
		playerViewController?.contentOverlayView?.addSubview(albumArtwork)
		playerViewController?.contentOverlayView?.addSubview(songLabel)
		
		// start playing the stream
		player.play()
		// tell everyone it started playing
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PlayerStartedPlaying"), object: nil)

		// setup CarPlay Remote Command Events
		let commandCenter = MPRemoteCommandCenter.shared()
		commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
			loggingText = loggingText.add(string: "commandCenter.playCommand")
			if self.playerViewController?.player?.rate == 0.0 {
				self.playerViewController?.player?.play()
			}
			self.updateNowPlaying()
			return MPRemoteCommandHandlerStatus.success
		}
		
		commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
			loggingText = loggingText.add(string: "commandCenter.pauseCommand")
			if self.playerViewController?.player?.rate == 1.0 {
				self.playerViewController?.player?.pause()
			}
			self.updateNowPlaying()
			return MPRemoteCommandHandlerStatus.success
		}
	}
	
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager,
							   playerCurrentItemDidChange player: AVPlayer) {
		loggingText = loggingText.add(string: "playerCurrentItemDidChange")
		guard let playerViewController = playerViewController, player.currentItem != nil else { return }
		playerViewController.player = player
	}
}

// add strings together = append. this is a continuous logging string
extension String {
	func add(string: String) -> String {
		let newString = self + "  " + string + "\n"
		DispatchQueue.main.async {
			loggingLabel.text = newString
			loggingLabel.sizeToFit()
		}
		print("MJG ------------------------------------------------------------------->>> \(string)")
		return newString
	}
}

