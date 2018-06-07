//
//  HomeScreenViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/12/18.
//  Copyright © 2018 On The Move Software. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
import SystemConfiguration

// Logging
var loggingText = ""
var loggingLabel = UILabel()

// state flags
var avPlayerVCisReady = true
var assetIsReady = false
var isReachable = false
var retryCount = 0
var playbackStalled = false

// JSON structure
struct Collaborator: Decodable {
	let id: String
	let name: String
	let status: String
}

struct Source: Decodable {
	let type: String
	let collaborator: Collaborator
	let relay: String?
}

struct CurrentTrack: Decodable {
	let title: String
	let start_time: String
	let artwork_url: URL
	let artwork_url_large: URL
}

struct History: Decodable {
	var title: String
}

struct Outputs: Decodable {
	let name: String
	let format: String
	let bitrate: Int
}

public struct RadioJSON {
	let status: String
	let source: Source
	let collaborators: [Collaborator]
	let relays: [String]
	let currentTrack: CurrentTrack
	var history: [History]
	let logoURL: URL
	let streamingHostname: String
	let outputs: [Outputs]
}

extension RadioJSON: Decodable {
	
	enum CodingKeys: String, CodingKey {
		case status					= "status"
		case source					= "source"
		case collaborators			= "collaborators"
		case relays					= "relays"
		case current_track			= "current_track"
		case history				= "history"
		case logo_url				= "logo_url"
		case streaming_hostname		= "streaming_hostname"
		case outputs				= "outputs"
	}
	
	public init(from decoder: Decoder) throws {
		
		let container 			= try decoder.container(keyedBy: CodingKeys.self)
		
		self.status 			= try container.decode(String.self,					forKey: .status)
		self.source 			= try container.decode(Source.self,					forKey: .source)
		self.collaborators	 	= try container.decode([Collaborator].self,			forKey: .collaborators)
		self.relays 			= try container.decode([String].self,				forKey: .relays)
		self.currentTrack 		= try container.decode(CurrentTrack.self,			forKey: .current_track)
		self.history 			= try container.decode([History].self,				forKey: .history)
		self.logoURL 			= try container.decode(URL.self,					forKey: .logo_url)
		self.streamingHostname	= try container.decode(String.self,					forKey: .streaming_hostname)
		self.outputs			= try container.decode([Outputs].self,				forKey: .outputs)
	}
}

class HomeScreenViewController: UIViewController {

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
	
	// Reachability
	var reachability: Reachability?
	var networkStatus = UILabel()
	var hostNameLabel = UILabel()
	let hostNames = [nil, "apple.com", "invalidhost"]
	var hostIndex = 0

	
    override func viewDidLoad() {
        super.viewDidLoad()
//		loggingText = loggingText.add(string: "viewDidLoad")
		
		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
		
		let notificationCenter = NotificationCenter.default
		// inter process commmunication
		notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleNewSongNotification), name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(restartStream), name: NSNotification.Name(rawValue: "RestartStream"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(reloadURL), name: NSNotification.Name(rawValue: "ReloadURL"), object: nil)

		// handle interruptions
		DispatchQueue.main.async {
			// and another one: // AVPlayerItemPlaybackStalledNotification the call player.seekToTime(player.currentTime) instead of player.play()
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleInterruption), name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance)
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleRouteChange), name: .AVAudioSessionRouteChange, object: nil)
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleMediaReset), name: .AVAudioSessionMediaServicesWereReset, object: nil)
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handlePlaybackStalled), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
		}
		
//		UIApplication.shared.beginReceivingRemoteControlEvents()
//		notificationCenter.addObserver(self, selector: #selector(handleRemoteControlEvent), name: NSNotification.Name(rawValue: "TogglePlay"), object: nil)
//		notificationCenter.addObserver(self, selector: #selector(handleRemoteControlEvent), name: NSNotification.Name(rawValue: "TogglePause"), object: nil)
		
		
		// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
//		notificationCenter.addObserver(self, selector:#selector(reachabilityChanged), name:NSNotification.Name(rawValue: HomeScreenViewController.kReachabilityChangedNotification), object:nil)
		
		// Reachability
//		startHost(at: 0)
	}

	override func viewWillAppear(_ animated: Bool) {
//		loggingText = loggingText.add(string: "viewWillAppear")
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
	
	deinit {
		stopNotifier()
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if segue.identifier == HomeScreenViewController.presentPlayerViewControllerSegueID {
			guard let seguePlayerViewController = segue.destination as? AVPlayerViewController else { return }
//			loggingText = loggingText.add(string: "prepare(for segue: AVPlayerViewController")
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
		guard playerViewController?.player != nil else {
			loggingText = loggingText.add(string: "restartStream playerViewController?.player is nil")
			loggingText = loggingText.add(string: "restartStream calling reloadURL")
			reloadURL()
			return
		}
		loggingText = loggingText.add(string: "restartStream player.play()")
		if playbackStalled {
			reloadURL()
		} else {
			playerViewController?.player?.play()
			getStationPlaylistInfo()
		}
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
		playbackStalled = false
	}

	@objc func handleNewSongNotification(notification: NSNotification) {
//		loggingText = loggingText.add(string: "handleNewSongNotification")
		getStationPlaylistInfo()
	}
	
	func getStationPlaylistInfo() {
//		loggingText = loggingText.add(string: "getStationPlaylistInfo")
		let radioURL = URL.init(string: HomeScreenViewController.playlistURL)
		let task = URLSession.shared.dataTask(with: radioURL!) { data, response, error in
			if let error = error {
				print(error)
				return
			}
			guard let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode) else {
					print(response ?? "Fred")
					return
			}
			if let mimeType = httpResponse.mimeType, mimeType == "application/json",
				let data = data {
				do {
					let decoder = JSONDecoder()
					let radioData = try decoder.decode(RadioJSON.self, from: data)
					self.processJSON(radioData)
				}
				catch {
					print(error)
				}
			}
		}
		task.resume()
	}
	
	func sliceJSONTitle(title: String) -> (String, String) {
		var trackTitle = ""
		var trackArtist = ""
		
		return (trackTitle, trackArtist)
	}
	
	func processJSON(_ jsonData: RadioJSON) {
		
		currentTrackTitle = jsonData.currentTrack.title
		if currentTrackTitle == "Unknown" || currentTrackTitle == "" {
			currentTrackTitle = HomeScreenViewController.defaultTrackTitle
			currentTrackArtist = HomeScreenViewController.defaultTrackArtist
		}
		
		currentTrackArtist = jsonData.currentTrack.title
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
		
		if jsonData.currentTrack.artwork_url.absoluteString.contains("images.radio.co/station_logos/s96fbbec3a") {
			DispatchQueue.main.async {
				self.albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork
			}
		} else {
			
			let task = URLSession.shared.dataTask(with: jsonData.currentTrack.artwork_url) { data, response, error in
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
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: ["History" : jsonData.history])
	}


//	func OLDgetStationPlaylistInfo() {
////		loggingText = loggingText.add(string: "getStationPlaylistInfo")
//		let radioURL = URL.init(string: HomeScreenViewController.playlistURL)
//		let task = URLSession.shared.dataTask(with: radioURL!) { data, response, error in
//			if let error = error {
//				self.handleClientError(error)
//				return
//			}
//			guard let httpResponse = response as? HTTPURLResponse,
//				(200...299).contains(httpResponse.statusCode) else {
//					self.handleServerError(response)
//					return
//			}
//			if let mimeType = httpResponse.mimeType, mimeType == "application/json",
//				let data = data {
//				do {
//					let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
//					self.processJSON(jsonData)
//				}
//				catch {
//					print(error)
//				}
//			}
//		}
//		task.resume()
//	}
//
//	func OLDprocessJSON(_ jsonData: [String : Any]) {
//		for dict in jsonData {
//			if dict.key == "current_track" {
//				guard let currentTrackDict = dict.value as? [String : Any] else { return }
//				if let title = currentTrackDict["title"] as? String {
//
//					let tempString = title
////					let tempString = "Fred" // For testing
//					if tempString.contains("-") {
//						let separator = tempString.index(of: "-")!
//						let artistSlice = tempString[..<separator]
//						if separator < tempString.endIndex {
//							let afterSeparator = tempString.index(after: separator)
//							if afterSeparator < tempString.endIndex {
//								let next = tempString.index(after: afterSeparator)
//								let titleSlice = tempString.suffix(from: next)
//								currentTrackTitle = String(titleSlice)
//								currentTrackTitle = currentTrackTitle + "\n"
//								currentTrackArtist = String(artistSlice)
//							}
//							else {
//								currentTrackTitle = tempString + "\n"
//								currentTrackArtist = HomeScreenViewController.defaultTrackArtist
//							}
//						}
//						else {
//							currentTrackTitle = tempString + "\n"
//							currentTrackArtist = HomeScreenViewController.defaultTrackArtist
//						}
//					}
//					else {
//						currentTrackTitle = tempString + "\n"
//						currentTrackArtist = HomeScreenViewController.defaultTrackArtist
//					}
//				}
//				else {
//					currentTrackTitle = HomeScreenViewController.defaultTrackTitle
//					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
//				}
//
////$TODO: Needed?				let start_time = currentTrackDict["start_time"] as! String
//				if currentTrackTitle == "Unknown" || currentTrackTitle == "" {
//					currentTrackTitle = HomeScreenViewController.defaultTrackTitle
//					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
//				}
//
//				if currentTrackArtist == "" {
//					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
//				}
//
//				let titleAttributes: [NSAttributedStringKey : Any] = [
//					NSAttributedStringKey.foregroundColor : UIColor.black,
//					NSAttributedStringKey.font : UIFont.systemFont(ofSize: 30)
//				]
//				let displayString = NSMutableAttributedString.init(string: currentTrackTitle, attributes: titleAttributes)
//				let artistAttributes = [
//					NSAttributedStringKey.foregroundColor : UIColor.red,
//					NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20)
//				]
//				displayString.append(NSAttributedString.init(string: currentTrackArtist, attributes: artistAttributes))
//
//				DispatchQueue.main.async {
//					self.songLabel.attributedText = displayString
//				}
//				updateNowPlaying()
//
//				if let artwork_url = currentTrackDict["artwork_url"] as? String,
//					let artworkURL = URL.init(string: artwork_url) {
//					if artwork_url.contains("images.radio.co/station_logos/s96fbbec3a") {
//						DispatchQueue.main.async {
//							self.albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork
//						}
//					} else {
//
//						let task = URLSession.shared.dataTask(with: artworkURL) { data, response, error in
//							if let error = error {
//								self.handleClientError(error)
//								return
//							}
//							guard let httpResponse = response as? HTTPURLResponse,
//								(200...299).contains(httpResponse.statusCode) else {
//									self.handleServerError(response)
//									return
//							}
//
//							if let data = data {
//								let dataImage = UIImage.init(data: data)
//								DispatchQueue.main.async {
//									self.albumArtwork.image = dataImage
//								}
//							}
//						}
//						task.resume()
//					}
//				}
//				else {
//					DispatchQueue.main.async {
//						self.albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork
//					}
//				}
//			}
//			else if dict.key == "history" {
//// $TODO: Fix when we can
////				let historyArray = dict.value as! [Any]
////				var songArray: [[String: Any]] = [[:]]
////				for track in historyArray {
//////					print(track)
////					let x = track as! [String : Any]
////					let song = x["title"] as? String
////					print(song)
////					songArray.append(x)
////				}
////				print("test")
////				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: dict.value as? [AnyHashable : Any])
//				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: jsonData)
//			}
//		}
//	}
	
	func updateNowPlaying() {
//		loggingText = loggingText.add(string: "updateNowPlaying")
		// Set Metadata to be Displayed in Now Playing Info Center
		let playerRate = playerViewController?.player?.rate ?? 0.0
		let infoCenter = MPNowPlayingInfoCenter.default()
		if currentTrackTitle == "" {
			currentTrackTitle = HomeScreenViewController.defaultTrackTitle
		}
		if currentTrackArtist == "" {
			currentTrackArtist = HomeScreenViewController.defaultTrackArtist
		}
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
//		loggingText = loggingText.add(string: "handleClientError")
}
	func handleServerError(_ response: URLResponse?) {
//		loggingText = loggingText.add(string: "handleServerError")
	}

	@objc func handleInterruption(notification: Notification) { // kAudioSessionProperty_ServerDied
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
						if playbackStalled {
							reloadURL()
						} else {
							playerViewController.player?.play() // $TODO: work around
//							playerViewController.player?.seek(to: (playerViewController.player?.currentTime())!)
							loggingText = loggingText.add(string: "Interruption play()")
						}
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

			let session = AVAudioSession.sharedInstance()
//			for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//				headphonesConnected = true
//				break
//			}
			for output in session.currentRoute.outputs {
				loggingText = loggingText.add(string: "handleRouteChange output = \(output.portType)")
				break
			}
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
		loggingText = loggingText.add(string: "handleMediaReset AVAudioSessionMediaServicesWereReset with reason = \(userInfo)")
		reloadURL()
	}

	@objc
	func handlePlaybackStalled(notification: Notification) {
		
		loggingText = loggingText.add(string: "handlePlaybackStalled")
		playbackStalled = true
	}

//	@objc
//	func handleRemoteControlEvent(notification: Notification) {
//		print("MJG ------------------------------------------------------------------->>> handleRemoteControlEvent")
//		loggingText = loggingText.add(string: "handleRemoteControlEvent")
//	}
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
			if playbackStalled {
				self.reloadURL()
			} else if self.playerViewController?.player?.rate == 0.0 {
				
				do {
					try AVAudioSession.sharedInstance().setActive(true)
				} catch  {
					loggingText = loggingText.add(string: "AVAudioSession.sharedInstance().setActive(true) error = \(error)")
				}
//				if Reachability.isConnectedToNetwork() {
					loggingText = loggingText.add(string: "commandCenter.playCommand play()")
					DispatchQueue.main.async {
						self.playerViewController?.player?.play() // $TODO: work-around
//						self.playerViewController?.player?.seek(to: (self.playerViewController?.player?.currentTime())!)
					}
//				} else {
//					loggingText = loggingText.add(string: "commandCenter.playCommand NOT connected to network")
//					loggingText = loggingText.add(string: "commandCenter.playCommand reloading URL()")
//					self.reloadURL()
//					return MPRemoteCommandHandlerStatus.commandFailed
//				}
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
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "h:mm"
		let dateString = dateFormatter.string(from: Date())
		var newString = self + "  " + dateString
		newString = newString + " " + string + "\n"
		DispatchQueue.main.async {
			loggingLabel.text = newString
			loggingLabel.sizeToFit()
		}
		print("MJG ------------------------------------------------------------------->>> \(string)")
		return newString
	}
}

// Reachability
extension HomeScreenViewController {

	func startHost(at index: Int) {
		stopNotifier()
		setupReachability(hostNames[index], useClosures: true)
		startNotifier()
		DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
			self.startHost(at: (index + 1) % 3)
		}
	}

	func setupReachability(_ hostName: String?, useClosures: Bool) {
		let reachability: Reachability?
		if let hostName = hostName {
			reachability = Reachability(hostname: hostName)
			hostNameLabel.text = hostName
		} else {
			reachability = Reachability()
			hostNameLabel.text = "No host name"
		}
		self.reachability = reachability
		print("--- set up with host name: \(hostNameLabel.text!)")
		
		if useClosures {
			reachability?.whenReachable = { reachability in
				self.updateLabelColourWhenReachable(reachability)
			}
			reachability?.whenUnreachable = { reachability in
				self.updateLabelColourWhenNotReachable(reachability)
			}
		} else {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(reachabilityChanged(_:)),
				name: .reachabilityChanged,
				object: reachability
			)
		}
	}
	
	func startNotifier() {
		print("--- start notifier")
		do {
			try reachability?.startNotifier()
		} catch {
			networkStatus.textColor = .red
			networkStatus.text = "Unable to start\nnotifier"
			return
		}
	}
	
	func stopNotifier() {
		print("--- stop notifier")
		reachability?.stopNotifier()
		NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
		reachability = nil
	}
	
	func updateLabelColourWhenReachable(_ reachability: Reachability) {
		print("\(reachability.description) - \(reachability.connection)")
		if reachability.connection == .wifi {
			self.networkStatus.textColor = .green
		} else {
			self.networkStatus.textColor = .blue
		}
		
		self.networkStatus.text = "\(reachability.connection)"
	}
	
	func updateLabelColourWhenNotReachable(_ reachability: Reachability) {
		print("\(reachability.description) - \(reachability.connection)")
		
		self.networkStatus.textColor = .red
		
		self.networkStatus.text = "\(reachability.connection)"
	}
	
	@objc func reachabilityChanged(_ note: Notification) {
		let reachability = note.object as! Reachability
		
		if reachability.connection != .none {
			updateLabelColourWhenReachable(reachability)
		} else {
			updateLabelColourWhenNotReachable(reachability)
		}
	}
}

