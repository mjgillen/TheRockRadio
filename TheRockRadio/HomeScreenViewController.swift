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
var retryCount = 0
//var playbackStalled = false
var lastTimePaused: TimeInterval = Date.timeIntervalSinceReferenceDate

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
	
	fileprivate var playerViewController: AVPlayerViewController?
	
	// Common
	let nowPlayingManager = NowPlayingManager()
	
	// UI in the player window
	var songLabel: UILabel!
	var currentTrackTitle = Common.defaultTrackTitle
	var currentTrackArtist = Common.defaultTrackArtist
	var currentAlbumArtwork: UIImage = Common.defaultAlbumArtwork
	var albumArtwork: UIImageView!
	var albumArtworkURLString = Common.defaultAlbumArtworkURLString
	
	var mediaItemArtwork: MPMediaItemArtwork?
	
    override func viewDidLoad() {
        super.viewDidLoad()
//		loggingText = loggingText.add(string: "viewDidLoad")
		
//		nowPlayingManager.updateNowPlayingWith(title: Common.defaultTrackTitle, artist: Common.defaultTrackArtist, artWork: Common.defaultAlbumArtwork)

		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
		
		let notificationCenter = NotificationCenter.default
		// inter process commmunication
		notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleNewSongNotification), name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(restartStream), name: NSNotification.Name(rawValue: "RestartStream"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(reloadURL), name: NSNotification.Name(rawValue: "ReloadURL"), object: nil)

		// handle interruptions
		DispatchQueue.main.async {
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleInterruption), name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance)
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleRouteChange), name: .AVAudioSessionRouteChange, object: nil)
		}
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
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if segue.identifier == HomeScreenViewController.presentPlayerViewControllerSegueID {
			guard let seguePlayerViewController = segue.destination as? AVPlayerViewController else { return }
//			loggingText = loggingText.add(string: "prepare(for segue: AVPlayerViewController")
			//Grab a reference for the destinationViewController to use in later delegate callbacks from
			//AssetPlaybackManager.
			playerViewController = seguePlayerViewController
			
			// Load the new Asset to playback into AssetPlaybackManager.
			let urlAsset = AVURLAsset.init(url: URL.init(string: Common.streamingURL)!)
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
		checkAndPlay()
		getStationPlaylistInfo()
	}
	
	@objc func reloadURL() {
		loggingText = loggingText.add(string: "reloadURL")
		
		// if not yet setup bail
		if !avPlayerVCisReady {
			loggingText = loggingText.add(string: "reloadURL avPlayerVCisReady NOT ready")
			return
		}

		// Reactivate the Audio Session
		do {
			loggingText = loggingText.add(string: "reloadURL-> AVAudioSession.setActive")
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
			try AVAudioSession.sharedInstance().setActive(true)
			
			loggingText = loggingText.add(string: "reloadURL-> AVAudioSession.setActive = TRUE")
			
			// Load the Asset to playback into AssetPlaybackManager.
			loggingText = loggingText.add(string: "reloadURL reloading asset")
			let urlAsset = AVURLAsset.init(url: URL.init(string: Common.streamingURL)!)
			let stream = StreamListManager.shared.streams.first
			let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
			AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
			retryCount = 0
		} catch  {
			loggingText = loggingText.add(string: "reloadURL-> AVAudioSession.sharedInstance().setCategory error = \(error)")
			if retryCount < 15 {
				retryCount += 1
				loggingText = loggingText.add(string: "reloadURL-> retrying")
				self.perform(#selector(reloadURL), with: nil, afterDelay: 2.0)
			} else {
				retryCount = 0
				loggingText = loggingText.add(string: "reloadURL error 15 RETRIES exhausted)")
			}
		}
	}
	
	@objc func handleNewSongNotification(notification: NSNotification) {
//		loggingText = loggingText.add(string: "handleNewSongNotification")
		getStationPlaylistInfo()
	}
	
	func getStationPlaylistInfo() {
//		loggingText = loggingText.add(string: "getStationPlaylistInfo")
		let radioURL = URL.init(string: Common.playlistURL)
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
	
	func processJSON(_ jsonData: RadioJSON) {
		
		loggingText = loggingText.add(string: "processJSON")
		(currentTrackTitle, currentTrackArtist) = sliceJSONSongString(songString: jsonData.currentTrack.title)
		if currentTrackTitle == "Unknown" || currentTrackTitle == "" {
			currentTrackTitle = Common.defaultTrackTitle
			currentTrackArtist = Common.defaultTrackArtist
		}
		
		if currentTrackArtist == "" {
			currentTrackArtist = Common.defaultTrackArtist
		}
		
		updateSongLabel()
		
		if jsonData.currentTrack.artwork_url.absoluteString.contains("images.radio.co/station_logos/s96fbbec3a") {
			DispatchQueue.main.async {
				self.albumArtwork.image = Common.defaultAlbumArtwork
				self.currentAlbumArtwork = Common.defaultAlbumArtwork
				self.albumArtworkURLString = Common.defaultAlbumArtworkURLString
			}
		} else {
			albumArtworkURLString = jsonData.currentTrack.artwork_url.absoluteString
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
						loggingText = loggingText.add(string: "updating albumArtwork")
						self.albumArtwork.image = dataImage
						self.currentAlbumArtwork = dataImage!
					}
				}
			}
			task.resume()
		}
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: ["History" : jsonData.history])
	}

	func sliceJSONSongString(songString: String) -> (String, String) {
		var trackTitle = ""
		var trackArtist = ""
		let stringSplit = songString.components(separatedBy: " - ")
		switch stringSplit.count {
		case 0,1:
			trackTitle = stringSplit.first!
		case 2:
			trackTitle = stringSplit.first!
			trackArtist = stringSplit.last!
		default: // more than two
			trackTitle = stringSplit.first!
			for index in 1..<stringSplit.count {
				if index == 1 {
					trackArtist = trackArtist + stringSplit[index]
				} else {
					trackArtist = trackArtist + " - " + stringSplit[index]
				}
			}
		}
		return (trackTitle, trackArtist)
	}
	
	func updateSongLabel() {
		let titleAttributes: [NSAttributedStringKey : Any] = [
			NSAttributedStringKey.foregroundColor : UIColor.black,
			NSAttributedStringKey.font : UIFont.systemFont(ofSize: 30)
		]
		let displayString = NSMutableAttributedString.init(string: currentTrackTitle + "\n", attributes: titleAttributes)
		let artistAttributes = [
			NSAttributedStringKey.foregroundColor : UIColor.red,
			NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20)
		]
		displayString.append(NSAttributedString.init(string: currentTrackArtist, attributes: artistAttributes))
		
		DispatchQueue.main.async {
			loggingText = loggingText.add(string: "updating songLabel")
			self.songLabel.attributedText = displayString
		}
	}

	func checkAndPlay() {
		loggingText = loggingText.add(string: "checkAndPlay()")
		let now = Date.timeIntervalSinceReferenceDate
		let interval = now - lastTimePaused
		loggingText = loggingText.add(string: String(format: "checkAndPlay() time was %.1f", interval))
		if interval > 5.0 {
			loggingText = loggingText.add(string: "checkAndPlay() reloadingURL()")
			reloadURL()
		} else {
			loggingText = loggingText.add(string: "checkAndPlay() player.play()")
			self.playerViewController?.player?.play()
		}
	}
	
	func handleClientError(_ error: Error) {
		loggingText = loggingText.add(string: "handleClientError")
}
	func handleServerError(_ response: URLResponse?) {
		loggingText = loggingText.add(string: "handleServerError")
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
						checkAndPlay()
						loggingText = loggingText.add(string: "Interruption play()")
					}
				} else {
					// Interruption Ended - playback should NOT resume
					loggingText = loggingText.add(string: "Interruption Ended DO NOT RESUME")
				}
			}
		}
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
}

extension HomeScreenViewController: AssetPlaybackDelegate {
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
		
		loggingText = loggingText.add(string: "streamPlaybackManager: playerReadyToPlay")

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
		songLabel.text = ""
		songLabel.font = UIFont.systemFont(ofSize: 30.0)
		songLabel.numberOfLines = 2
		songLabel.lineBreakMode = .byTruncatingMiddle
		songLabel.textAlignment = .center
		updateSongLabel()
		
		// album artwork image
		rect.origin.x = 0.0
		rect.origin.y = 5.0
		rect.size.width = CGFloat(pvcWidth / 2.0)
		rect.size.height = CGFloat(pvcHeight / 2.0)
		albumArtwork = UIImageView.init(frame: rect)
		albumArtwork.contentMode = .scaleAspectFit
		albumArtwork.center.x = (playerViewController?.contentOverlayView?.center.x)!
		albumArtwork.image = Common.defaultAlbumArtwork

		// add them to the view
		playerViewController?.contentOverlayView?.addSubview(albumArtwork)
		playerViewController?.contentOverlayView?.addSubview(songLabel)
		
		// start playing the stream
		loggingText = loggingText.add(string: "playerReadyToPlay: start playing the stream")
		player.play()
		// tell everyone it started playing
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PlayerStartedPlaying"), object: nil)

		// setup CarPlay Remote Command Events
//		let isCarPlay = (UI_USER_INTERFACE_IDIOM() == .carPlay)
//		loggingText = loggingText.add(string: "isCarPlay = \(isCarPlay)")
//		loggingText = loggingText.add(string: "setup CarPlay Remote Command Events")
		// Enable Remote Command events
		MPRemoteCommandCenter.shared().playCommand.isEnabled = true
		MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
		let commandCenter = MPRemoteCommandCenter.shared()
		commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
			loggingText = loggingText.add(string: "commandCenter.playCommand")
			if self.playerViewController?.player?.rate == 0.0 {
				self.checkAndPlay()
			}
			return MPRemoteCommandHandlerStatus.success
		}
		
		commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
			loggingText = loggingText.add(string: "commandCenter.pauseCommand")
			if self.playerViewController?.player?.rate == 1.0 {
				self.playerViewController?.player?.pause()
			}
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
			let oldWidth = loggingLabel.frame.size.width
			loggingLabel.text = newString
			loggingLabel.sizeToFit()
			loggingLabel.frame.size.width = oldWidth
		}
		print("MJG ------------------------------------------------------------------->>> \(string)")
		return newString
	}
}

