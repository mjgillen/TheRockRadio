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
import UserNotifications

class HomeScreenViewController: UIViewController {

	static let presentPlayerViewControllerSegueID = "PresentPlayerViewControllerSegueIdentifier"
	
	fileprivate var playerViewController: AVPlayerViewController?
	
	// UI in the player window
	var songLabel: UILabel!
	var currentTrackTitle = "CurrentTrackTitle"
	var currentTrackArtist = "CurrentTrackArtist"
	var albumArtwork: UIImageView!
	
	var webView = UIWebView()
	private lazy var urlSession: URLSession = {
		let config = URLSessionConfiguration.background(withIdentifier: "MySession")
		config.isDiscretionary = true
		config.sessionSendsLaunchEvents = true
		return URLSession(configuration: config, delegate: self, delegateQueue: nil)
	}()

    override func viewDidLoad() {
        super.viewDidLoad()

		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
		NotificationCenter.default.addObserver(self, selector: #selector(HomeScreenViewController.handleNotification), name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
		// handle interruptions
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self,
									   selector: #selector(handleInterruption),
									   name: .AVAudioSessionInterruption,
									   object: nil)
		
//		let authorizationOptions: UNAuthorizationOptions = [.carPlay]
//		UNUserNotificationCenter.current().requestAuthorization(options: authorizationOptions) { (granted, error) in
//			// enable or disable app features based upon authorization
//			print(granted)
//		}
		
		MPPlayableContentManager.shared().dataSource = self
		MPPlayableContentManager.shared().delegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)		
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
			
			/*
			Grab a reference for the destinationViewController to use in later delegate callbacks from
			AssetPlaybackManager.
			*/
			playerViewController = seguePlayerViewController
			
//			// setup properties for the AVPlayer
//			playerViewController?.allowsPictureInPicturePlayback = false
//			playerViewController?.contentOverlayView?.backgroundColor = .gray
//			playerViewController?.updatesNowPlayingInfoCenter = true
//			playerViewController?.contentOverlayView?.isHidden = false
//
//			// setup the label
//			let offsetX = 10.0
//			let offsetY = Double(self.view.frame.height/2.0) - 125.0
//			var rect = CGRect(x: offsetX, y: offsetY, width: (Double(self.view.frame.width) - offsetX), height: 75.0)
//			songLabel = UILabel.init(frame: rect)
//			songLabel.textColor = .white
//			songLabel.text = ""
//			songLabel.font = UIFont.systemFont(ofSize: 30.0)
//			songLabel.numberOfLines = 2
//
//			// album artwork image
//			rect.origin.x = 0.0
//			rect.origin.y = 5.0
//			rect.size.width = self.view.frame.width
//			rect.size.height = self.view.frame.height / 4.0
//			albumArtwork = UIImageView.init(frame: rect)
//			albumArtwork.contentMode = .scaleAspectFit
//
//			playerViewController?.contentOverlayView?.addSubview(albumArtwork)
//			playerViewController?.contentOverlayView?.addSubview(songLabel)
			
			// Load the new Asset to playback into AssetPlaybackManager.
			let urlAsset = AVURLAsset.init(url: URL.init(string: "https://streaming.radio.co/s96fbbec3a/listen")!)
			let stream = StreamListManager.shared.streams.first
			let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
			AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
		}
	}
	
	@objc func handleNotification(notification: NSNotification) {
//		songLabel.text = notification.object as? String
		
		// Get the latest song "status" from the radio.io server
		// so we can populate the album artwork and play history list
		getStationPlaylistInfo()
	}
	
	func getStationPlaylistInfo() {
//		let config = URLSessionConfiguration.default
//		let request = URLRequest.init(url: URL.init(fileURLWithPath: "https://public.radio.co/stations/s96fbbec3a/status"), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
//		let urlSession = URLSession.init(configuration: config, delegate: self, delegateQueue: nil)
//		urlSession.downloadTask(with: request)
		
//		let radioURL = URL.init(fileURLWithPath: "https://public.radio.co/stations/s96fbbec3a/status")
//		let backgroundTask = urlSession.downloadTask(with: radioURL)
//		backgroundTask.earliestBeginDate = Date().addingTimeInterval(60 * 60)
//		backgroundTask.countOfBytesClientExpectsToSend = 200
//		backgroundTask.countOfBytesClientExpectsToReceive = 500 * 1024
//		backgroundTask.resume()
		
//		let url = URL(string: "https://www.example.com/")!
		let radioURL = URL.init(string: "https://public.radio.co/stations/s96fbbec3a/status")
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
			if let mimeType = httpResponse.mimeType, mimeType == "text/html",
				let data = data,
				let string = String(data: data, encoding: .utf8) {
				DispatchQueue.main.async {
					self.webView.loadHTMLString(string, baseURL: radioURL)
				}
			}
			else if let mimeType = httpResponse.mimeType, mimeType == "application/json",
				let data = data,
				let string = String(data: data, encoding: .utf8) {
				DispatchQueue.main.async {
					self.webView.loadHTMLString(string, baseURL: radioURL)
				}
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
				print(dict)
				let currentTrackDict = dict.value as! [String : Any]
				let artwork_url = currentTrackDict["artwork_url"] as! String
//				let artwork_url_large = currentTrackDict["artwork_url_large"] as! String
				let title = currentTrackDict["title"] as! String
				let tempString = title
				let separator = tempString.index(of: "-")!
				let artistSlice = tempString[..<separator]
				let afterSeparator = tempString.index(after: separator)
				let next = tempString.index(after: afterSeparator)
				let titleSlice = tempString.suffix(from: next)
				currentTrackArtist = String(artistSlice)
				currentTrackTitle = String(titleSlice)
//				let start_time = currentTrackDict["start_time"] as! String
				DispatchQueue.main.async {
					self.songLabel.text = self.currentTrackTitle + "\n" + self.currentTrackArtist
				}
				updateNowPlaying()
				
				let artworkURL = URL.init(string: artwork_url)
				let task = URLSession.shared.dataTask(with: artworkURL!) { data, response, error in
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
							if self.songLabel.text == "Unknown" {
								self.songLabel.text = title
							}
						}
					}
				}
				task.resume()
			}
			else if dict.key == "history" {
				print(dict)
			}
		}
	}
	
	func updateNowPlaying() {
		// Set Metadata to be Displayed in Now Playing Info Center
		let infoCenter = MPNowPlayingInfoCenter.default()
		infoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: currentTrackTitle,
									 MPMediaItemPropertyArtist: currentTrackArtist,
//									 MPMediaItemPropertyAlbumTitle: "",
//									 MPMediaItemPropertyGenre: "",
//									 MPMediaItemPropertyReleaseDate: "",
//									 MPMediaItemPropertyPlaybackDuration: 231,
//									 MPMediaItemPropertyArtwork: mediaItemArtwork,
//									 MPNowPlayingInfoPropertyElapsedPlayback: 53,
									 MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
									 MPNowPlayingInfoPropertyPlaybackRate: 1
//									 MPNowPlayingInfoPropertyPlaybackQueueCount: 13,
//									 MPNowPlayingInfoPropertyPlaybackQueueIndex: 3
		]
	}
	
	func handleClientError(_ error: Error) {
	}

	func handleServerError(_ response: URLResponse?) {
	}

	@objc func handleInterruption(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
				return
		}
		if type == .began {
			// Interruption began, take appropriate actions
		}
		else if type == .ended {
			if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
				let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
				if options.contains(.shouldResume) {
					// Interruption Ended - playback should resume
				} else {
					// Interruption Ended - playback should NOT resume
				}
			}
		}
	}
}

/**
Extend `AssetListTableViewController` to conform to the `AssetPlaybackDelegate` protocol.
*/
extension HomeScreenViewController: AssetPlaybackDelegate {
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
		player.play()
		playerViewController?.player = player
		
		// setup properties for the AVPlayerViewController
		playerViewController?.allowsPictureInPicturePlayback = false
		playerViewController?.contentOverlayView?.backgroundColor = .gray
		playerViewController?.updatesNowPlayingInfoCenter = true
		
		// setup the label
		let pvcWidth = Double((playerViewController?.contentOverlayView?.frame.width)!)
		let pvcHeight = Double((playerViewController?.contentOverlayView?.frame.height)!)
		let offsetX = 10.0
		let offsetY = pvcHeight - 125.0
		var rect = CGRect(x: offsetX, y: offsetY, width: pvcWidth - offsetX, height: 75.0)
		songLabel = UILabel.init(frame: rect)
		songLabel.textColor = .white
		songLabel.text = ""
		songLabel.font = UIFont.systemFont(ofSize: 30.0)
		songLabel.numberOfLines = 2
//		songLabel.backgroundColor = .red
		
		// album artwork image
		rect.origin.x = 0.0
		rect.origin.y = 5.0
		rect.size.width = CGFloat(pvcWidth / 2.0)
		rect.size.height = CGFloat(pvcHeight / 2.0)
		albumArtwork = UIImageView.init(frame: rect)
		albumArtwork.contentMode = .scaleAspectFit
		albumArtwork.center.x = (playerViewController?.contentOverlayView?.center.x)!
		
		playerViewController?.contentOverlayView?.addSubview(albumArtwork)
		playerViewController?.contentOverlayView?.addSubview(songLabel)
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PlayerStartedPlaying"), object: nil)
	}
	
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager,
							   playerCurrentItemDidChange player: AVPlayer) {
		guard let playerViewController = playerViewController, player.currentItem != nil else { return }
		
		playerViewController.player = player
	}
}

extension HomeScreenViewController: URLSessionDelegate {
	func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//		DispatchQueue.main.async {
//			guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//				let backgroundCompletionHandler =
//				appDelegate.backgroundCompletionHandler else {
//					return
//			}
//			backgroundCompletionHandler()
//		}
	}
	
	func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
	}
	
//	func application(_ application: UIApplication,
//					 handleEventsForBackgroundURLSession identifier: String,
//					 completionHandler: @escaping () -> Void) {
//		backgroundCompletionHandler = completionHandler
//	}
}

extension HomeScreenViewController: MPPlayableContentDelegate {
	func playableContentManager(_ contentManager: MPPlayableContentManager, didUpdate context: MPPlayableContentManagerContext) {
		print("Ribbet1")
	}
	
	func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
		print("Ribbet2")
	}
	
	func playableContentManager(_ contentManager: MPPlayableContentManager, initializePlaybackQueueWithContentItems contentItems: [Any]?, completionHandler: @escaping (Error?) -> Void) {
		print("Ribbet3")
	}
	func playableContentManager(_ contentManager: MPPlayableContentManager, initializePlaybackQueueWithCompletionHandler completionHandler: @escaping (Error?) -> Void) {
		print("Ribbet4")
	}
}
extension HomeScreenViewController: MPPlayableContentDataSource {
	
	func numberOfChildItems(at indexPath: IndexPath) -> Int {
		return 0
	}
	
	func contentItem(at indexPath: IndexPath) -> MPContentItem? {
		let item = MPContentItem(identifier: "The Rock Radio")
		item.isContainer = false
		item.isExplicitContent = false
		item.isPlayable = true
		item.isStreamingContent = true
		item.subtitle = "Lucy"
		item.title = currentTrackTitle
		
		return item
	}
}


