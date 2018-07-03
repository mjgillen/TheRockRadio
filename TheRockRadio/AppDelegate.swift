//
//  AppDelegate.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/11/18.
//  Copyright © 2018 On The Move Software. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		// Set up data source and delegate
//		MPPlayableContentManager.shared().dataSource = SrirockaContentManager.shared
//		MPPlayableContentManager.shared().delegate = SrirockaContentManager.shared

//		// Set Now Playing metadata in MPNowPlayingInfoCenter
//		let artwork = MPMediaItemArtwork.init(boundsSize: Common.defaultAlbumArtwork.size, requestHandler: { (size) -> UIImage in
//			
//			let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
//			UIGraphicsBeginImageContext(size)
//			Common.defaultAlbumArtwork.draw(in: rect)
//			let newImage = UIGraphicsGetImageFromCurrentImageContext()
//			UIGraphicsEndImageContext()
//			return newImage!
//		})
//		let nowPlayingInfo: [String: Any] = [MPMediaItemPropertyTitle: Common.defaultTrackTitle,
//										 MPMediaItemPropertyArtist: Common.defaultTrackArtist,
//										 MPNowPlayingInfoPropertyPlaybackRate: 1.0,
//										 MPMediaItemPropertyArtwork: artwork,
//										 MPNowPlayingInfoPropertyIsLiveStream: NSNumber(booleanLiteral: true),
//		]
//		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

		//		loggingText = loggingText.add(string: "didFinishLaunchingWithOptions")
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) // $TODO: May need to restart session after loss of wifi? Add movie playback?
			//try AVAudioSession.sharedInstance().setCategory(AVAudioSessionModeSpokenAudio
			try AVAudioSession.sharedInstance().setActive(true)
		} catch  {
			loggingText = loggingText.add(string: "AVAudioSession.sharedInstance().setCategory error = \(error)")
		}
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//		loggingText = loggingText.add(string: "applicationWillResignActive")
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//		loggingText = loggingText.add(string: "applicationDidEnterBackground")
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
//		loggingText = loggingText.add(string: "applicationWillEnterForeground")
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		loggingText = loggingText.add(string: "applicationDidBecomeActive")
//		NotificationCenter.default.post(name: NSNotification.Name("RestartStream"), object: nil)

		do {
			try AVAudioSession.sharedInstance().setActive(true)
		} catch  {
			loggingText = loggingText.add(string: "AVAudioSession.sharedInstance().setActive(true) error = \(error)")
		}
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//		loggingText = loggingText.add(string: "applicationWillTerminate")
	}
}

