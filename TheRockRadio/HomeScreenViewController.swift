//
//  HomeScreenViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/12/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit
//import AVFoundation
import AVKit

class HomeScreenViewController: UIViewController {

	static let presentPlayerViewControllerSegueID = "PresentPlayerViewControllerSegueIdentifier"
	
	fileprivate var playerViewController: AVPlayerViewController?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
//		self.performSegue(withIdentifier: HomeScreenViewController.presentPlayerViewControllerSegueID, sender: self)
		
//		if playerViewController != nil {
//			// The view reappeared as a results of dismissing an AVPlayerViewController.
//			// Perform cleanup.
//			AssetPlaybackManager.sharedManager.setAssetForPlayback(nil)
//			playerViewController?.player = nil
//			playerViewController = nil
//		}
	}

	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == HomeScreenViewController.presentPlayerViewControllerSegueID {
			guard let playerViewControler = segue.destination as? AVPlayerViewController else { return }
			
			/*
			Grab a reference for the destinationViewController to use in later delegate callbacks from
			AssetPlaybackManager.
			*/
			playerViewController = playerViewControler
			
			// Load the new Asset to playback into AssetPlaybackManager.
			let urlAsset = AVURLAsset.init(url: URL.init(string: "https://streaming.radio.co/s96fbbec3a/listen")!)
			let stream = StreamListManager.shared.streams.first
			let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
			AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
		}
	}
}
/**
Extend `AssetListTableViewController` to conform to the `AssetPlaybackDelegate` protocol.
*/
extension HomeScreenViewController: AssetPlaybackDelegate {
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
		player.play()
	}
	
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager,
							   playerCurrentItemDidChange player: AVPlayer) {
		guard let playerViewController = playerViewController, player.currentItem != nil else { return }
		
		playerViewController.player = player
	}
}


