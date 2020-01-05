//
//  HomeScreenViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/12/18.
//  Copyright © 2018 Estero Bay Community Radio. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
import SystemConfiguration
import GoogleMobileAds

//// Logging
//var loggingText = ""
//var loggingLabel = UILabel()

// state flags
var avPlayerVCisReady = true
var retryCount = 0
//var playbackStalled = false
var lastTimePaused: TimeInterval = Date.timeIntervalSinceReferenceDate

// Now Playing metadata
var trackTitle = Common.defaultTrackTitle
var trackArtist = Common.defaultTrackArtist
var albumArtwork: UIImage = Common.defaultNowPlayingAlbumArtwork
var playerRate: Float = 0.0

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
	
    // The Rock Ads
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var adButton: UIButton!
    let theRockAds = TheRockAds()
//    var hideAdsForTesting = true
    
	// UI in the player window
	var playerWindowSongLabel: UILabel!
	var playerWindowAlbumArtwork: UIImageView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
//		self.becomeFirstResponder()
//		Common.updateNowPlaying()

		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
		
		let notificationCenter = NotificationCenter.default
		// inter process commmunication
		notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleNewSongNotification), name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
		notificationCenter.addObserver(self, selector: #selector(reloadURL), name: NSNotification.Name(rawValue: "ReloadURL"), object: nil)
        
        // restart app
        notificationCenter.addObserver(self, selector: #selector(loadAd), name:UIApplication.didBecomeActiveNotification, object: nil)

		// handle interruptions
		DispatchQueue.main.async {
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance)
			notificationCenter.addObserver(self, selector: #selector(HomeScreenViewController.handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
		}
		
        // get The Rock Ads
//        self.theRockAds.get()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadAd()
        
// MJG not used... more complicated... could be a future
//        if let ad = self.theRockAds.ads.first {
//            self.theRockAds.show(ad)
//        }
    }

	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	override var prefersStatusBarHidden: Bool {
		return false
	}
	
//	override var canBecomeFirstResponder: Bool {
//		return true
//	}
	
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
	
    // MARK: - Ad Banner
    
    @objc func loadAd() {
        
//        self.hideAdsForTesting = !self.hideAdsForTesting
//        if self.hideAdsForTesting {
//            DispatchQueue.main.async {
//               self.adButton.setBackgroundImage(UIImage(), for: .normal)
//            }
//            return
//        }
        
        DispatchQueue.global().async {
            if let url = URL(string: Common.theRockAdImageURL) {
                if let data = try? Data( contentsOf: url)
                {
                  DispatchQueue.main.async {
                     self.adButton.setBackgroundImage(UIImage( data:data), for: .normal)
                  }
                 } else {
                     DispatchQueue.main.async {
                        self.adButton.setBackgroundImage(UIImage(), for: .normal)
                     }
                 }
            } else {
                DispatchQueue.main.async {
                   self.adButton.setBackgroundImage(UIImage(), for: .normal)
                }
            }
        }
    }
    
    @IBAction func onAdButton(_ sender: UIButton) {
        // Launch Safari
        if let link = URL(string: Common.theRockAdLinkURL) {
            UIApplication.shared.open(link)
        }
    }
    
	@objc func reloadURL() {
//		loggingText = loggingText.add(string: "reloadURL")
		
		// if not yet setup bail
		if !avPlayerVCisReady {
//			loggingText = loggingText.add(string: "reloadURL avPlayerVCisReady NOT ready")
			return
		}

		// Reactivate the Audio Session
		do {
//			loggingText = loggingText.add(string: "reloadURL-> AVAudioSession.setActive")
			try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
															mode: AVAudioSession.Mode.default,
															options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
			try AVAudioSession.sharedInstance().setActive(true)
			
//			loggingText = loggingText.add(string: "reloadURL-> AVAudioSession.setActive = TRUE")
			
			// Load the Asset to playback into AssetPlaybackManager.
//			loggingText = loggingText.add(string: "reloadURL reloading asset")
			let urlAsset = AVURLAsset.init(url: URL.init(string: Common.streamingURL)!)
			let stream = StreamListManager.shared.streams.first
			let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
			AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
			retryCount = 0
		} catch  {
//			loggingText = loggingText.add(string: "reloadURL-> AVAudioSession.sharedInstance().setCategory error = \(error)")
			if retryCount < 15 {
				retryCount += 1
//				loggingText = loggingText.add(string: "reloadURL-> retrying")
				self.perform(#selector(reloadURL), with: nil, afterDelay: 2.0)
			} else {
				retryCount = 0
//				loggingText = loggingText.add(string: "reloadURL error 15 RETRIES exhausted)")
			}
		}
	}
	
	@objc func handleNewSongNotification(notification: NSNotification) {
		getStationPlaylistInfo()
	}
	
	func getStationPlaylistInfo() {
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
		
//		loggingText = loggingText.add(string: "processJSON")
		(trackArtist, trackTitle) = sliceJSONSongString(songString: jsonData.currentTrack.title)
		if trackTitle == "Unknown" || trackTitle == "" {
			trackTitle = Common.defaultTrackTitle
			trackArtist = Common.defaultTrackArtist
		}
		
		if trackArtist == "" {
			trackArtist = Common.defaultTrackArtist
		}
		
		updateSongLabel()
		
		if jsonData.currentTrack.artwork_url.absoluteString.contains("images.radio.co/station_logos/s96fbbec3a") {
			DispatchQueue.main.async {
				self.playerWindowAlbumArtwork.image = Common.defaultNowPlayingAlbumArtwork
				albumArtwork = Common.defaultNowPlayingAlbumArtwork
				Common.updateNowPlaying()
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
//						loggingText = loggingText.add(string: "updating albumArtwork")
						self.playerWindowAlbumArtwork.image = dataImage
						albumArtwork = dataImage!
						Common.updateNowPlaying()
					}
				}
			}
			task.resume()
		}
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: ["History" : jsonData.history])
	}

	func sliceJSONSongString(songString: String) -> (String, String) {
		var trackArtist = ""
		var trackTitle = ""
		let stringSplit = songString.components(separatedBy: " - ")
		switch stringSplit.count {
		case 0,1:
			trackArtist = stringSplit.first!
		case 2:
			trackArtist = stringSplit.first!
			trackTitle = stringSplit.last!
		default: // more than two
			trackArtist = stringSplit.first!
			for index in 1..<stringSplit.count {
				if index == 1 {
					trackTitle = trackTitle + stringSplit[index]
				} else {
					trackTitle = trackTitle + " - " + stringSplit[index]
				}
			}
		}
		return (trackArtist, trackTitle)
	}
	
	func updateSongLabel() {
		let titleAttributes: [NSAttributedString.Key : Any] = [
			NSAttributedString.Key.foregroundColor : UIColor.black,
			NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20)
		]
		let displayString = NSMutableAttributedString.init(string: trackTitle + "\n", attributes: titleAttributes)
		let artistAttributes = [
			NSAttributedString.Key.foregroundColor : UIColor.red,
			NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20)
		]
		displayString.append(NSAttributedString.init(string: trackArtist, attributes: artistAttributes))
		
		DispatchQueue.main.async {
//			loggingText = loggingText.add(string: "updating songLabel")
			self.playerWindowSongLabel.attributedText = displayString
			Common.updateNowPlaying()
		}
	}

	func checkAndPlay() {
//		loggingText = loggingText.add(string: "checkAndPlay()")
		let now = Date.timeIntervalSinceReferenceDate
		let interval = now - lastTimePaused
//		loggingText = loggingText.add(string: String(format: "checkAndPlay() time was %.1f", interval))
		if interval > 5.0 {
//			loggingText = loggingText.add(string: "checkAndPlay() reloadingURL()")
			reloadURL()
		} else {
//			loggingText = loggingText.add(string: "checkAndPlay() player.play()")
			self.playerViewController?.player?.play()
		}
	}
	
	func handleClientError(_ error: Error) {
//		loggingText = loggingText.add(string: "handleClientError")
}
	func handleServerError(_ response: URLResponse?) {
//		loggingText = loggingText.add(string: "handleServerError")
	}

	@objc func handleInterruption(notification: Notification) { // kAudioSessionProperty_ServerDied
//		loggingText = loggingText.add(string: "handleInterruption notification")
		guard let userInfo = notification.userInfo,
			let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
				return
		}
		guard let playerViewController = playerViewController else { return }
		if type == .began {
			// Interruption began, take appropriate actions
//			loggingText = loggingText.add(string: "Interruption began")

			if playerViewController.player?.rate == 1.0 {
				playerViewController.player?.pause()
//				loggingText = loggingText.add(string: "Interruption pause()")
			}
		}
		else if type == .ended {
			if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
				let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
				if options.contains(.shouldResume) {
					// Interruption Ended - playback should resume
//					loggingText = loggingText.add(string: "Interruption Ended")

					if playerViewController.player?.rate == 0.0 {
						checkAndPlay()
//						loggingText = loggingText.add(string: "Interruption play()")
					}
				} else {
					// Interruption Ended - playback should NOT resume
//					loggingText = loggingText.add(string: "Interruption Ended DO NOT RESUME")
				}
			}
		}
//		Common.updateNowPlaying()
	}
	
	@objc func handleRouteChange(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
			let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
				return
		}
//		loggingText = loggingText.add(string: "handleRouteChange")
		switch reason {
		case .newDeviceAvailable:
			
			// do not automatically start playing.
//			loggingText = loggingText.add(string: "handleRouteChange newDeviceAvailable")

//			let session = AVAudioSession.sharedInstance()
//			for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//				headphonesConnected = true
//				break
//			}
//			for output in session.currentRoute.outputs {
//				loggingText = loggingText.add(string: "handleRouteChange output = \(output.portType)")
//				break
//			}
			break
		case .oldDeviceUnavailable:
			break
//			loggingText = loggingText.add(string: "handleRouteChange oldDeviceUnavailable")

//			if let previousRoute =
//				userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
//				for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
//					headphonesConnected = false
//					break
//				}
//			}
		default: ()
//			loggingText = loggingText.add(string: "handleRouteChange default")
		}
	}
}

extension HomeScreenViewController: AssetPlaybackDelegate {
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
		
//		loggingText = loggingText.add(string: "streamPlaybackManager: playerReadyToPlay")

		// $TODO: do we need to tell CarPlay we are ready?
		playerViewController?.player = player
		
		// setup properties for the AVPlayerViewController
		playerViewController?.allowsPictureInPicturePlayback = false
		playerViewController?.updatesNowPlayingInfoCenter = true
		playerViewController?.contentOverlayView?.backgroundColor = .white
		
		let pvcWidth = Double((playerViewController?.contentOverlayView?.frame.width)!)
		let pvcHeight = Double((playerViewController?.contentOverlayView?.frame.height)!)
		let offsetX = 10.0
		let offsetY = pvcHeight - 125.0
		var rect = CGRect(x: offsetX, y: offsetY, width: pvcWidth - offsetX, height: 75.0)
		
		if playerWindowSongLabel == nil {
			// setup the label
			playerWindowSongLabel = UILabel.init(frame: rect)
			playerWindowSongLabel.text = ""
			playerWindowSongLabel.font = UIFont.systemFont(ofSize: 30.0)
			playerWindowSongLabel.numberOfLines = 2
			playerWindowSongLabel.lineBreakMode = .byTruncatingMiddle
			playerWindowSongLabel.textAlignment = .center
			// add to the view
			playerViewController?.contentOverlayView?.addSubview(playerWindowSongLabel)
			updateSongLabel()
		}
		if playerWindowAlbumArtwork == nil {
			// album artwork image
			rect.origin.x = 0.0
			rect.origin.y = 5.0
			rect.size.width = CGFloat(pvcWidth / 2.0)
			rect.size.height = CGFloat(pvcHeight / 2.0)
			playerWindowAlbumArtwork = UIImageView.init(frame: rect)
			playerWindowAlbumArtwork.contentMode = .scaleAspectFit
			playerWindowAlbumArtwork.center.x = (playerViewController?.contentOverlayView?.center.x)!
			playerWindowAlbumArtwork.image = Common.defaultNowPlayingAlbumArtwork
			// add to the view
			playerViewController?.contentOverlayView?.addSubview(playerWindowAlbumArtwork)
		}
		
		// start playing the stream
//		loggingText = loggingText.add(string: "playerReadyToPlay: start playing the stream")
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
//			loggingText = loggingText.add(string: "commandCenter.playCommand")
			if self.playerViewController?.player?.rate == 0.0 {
				self.checkAndPlay()
			}
//			Common.updateNowPlaying()
			return MPRemoteCommandHandlerStatus.success
		}
		
		commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//			loggingText = loggingText.add(string: "commandCenter.pauseCommand")
			if self.playerViewController?.player?.rate == 1.0 {
				self.playerViewController?.player?.pause()
			}
//			Common.updateNowPlaying()
			return MPRemoteCommandHandlerStatus.success
		}
//		Common.updateNowPlaying()
	}
	
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager,
							   playerCurrentItemDidChange player: AVPlayer) {
//		loggingText = loggingText.add(string: "playerCurrentItemDidChange")
		guard let playerViewController = playerViewController, player.currentItem != nil else { return }
		playerViewController.player = player
	}
}

//// add strings together = append. this is a continuous logging string
//extension String {
//	func add(string: String) -> String {
//		let dateFormatter = DateFormatter()
//		dateFormatter.dateFormat = "h:mm"
//		let dateString = dateFormatter.string(from: Date())
//		var newString = self + "  " + dateString
//		newString = newString + " " + string + "\n"
//		DispatchQueue.main.async {
//			let oldWidth = loggingLabel.frame.size.width
//			loggingLabel.text = newString
//			loggingLabel.sizeToFit()
//			loggingLabel.frame.size.width = oldWidth
//		}
//		print("MJG ------------------------------------------------------------------->>> \(string)")
//		return newString
//	}
//}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
