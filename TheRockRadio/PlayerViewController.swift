//
//  PlayerViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/29/18.
//  Copyright © 2018 On The Move Software. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {

	var player: AVPlayer?
	var isPlaying = false
	
	@IBOutlet weak var playPauseButton: UIButton!
	@IBAction func onPlayPauseButton(_ sender: Any) {
		
		if isPlaying {
			player?.pause()
			playPauseButton.setImage(#imageLiteral(resourceName: "PlayButton"), for: .normal)
		}
		else {
			player?.play()
			playPauseButton.setImage(#imageLiteral(resourceName: "PauseButton"), for: .normal)
		}
		isPlaying = !isPlaying
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.startedPlaying), name: NSNotification.Name(rawValue: "PlayerStartedPlaying"), object: nil)
    }
	@objc func startedPlaying(notification: NSNotification) {
		playPauseButton.setImage(#imageLiteral(resourceName: "PauseButton"), for: .normal)
		self.isPlaying = true
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
