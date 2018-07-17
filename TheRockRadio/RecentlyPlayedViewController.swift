//
//  RecentlyPlayedViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/17/18.
//  Copyright © 2018 Estero Bay Community Radio. All rights reserved.
//

import UIKit

class RecentlyPlayedViewController: UIViewController {

	@IBOutlet weak var titleHistory: UILabel!
	override func viewDidLoad() {
        super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(RecentlyPlayedViewController.handleNotification), name: NSNotification.Name(rawValue: "History"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
	}
	
	@objc func handleNotification(notification: NSNotification) {
		guard let historyDict = notification.userInfo as? [String: Any] else { return }
		var titleAttributes: [NSAttributedStringKey : Any] = [
			NSAttributedStringKey.foregroundColor : UIColor.black,
			NSAttributedStringKey.font : UIFont.systemFont(ofSize: 25)
		]
		let playlist = NSMutableAttributedString.init(string: "Recently Played\n", attributes: titleAttributes)
		titleAttributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: 18)
		titleAttributes[NSAttributedStringKey.foregroundColor] = UIColor.blue
		for dict in historyDict {
			if dict.key == "History" {
				let historyArray = dict.value as! [Any]
				for track in historyArray {
					let historyTrack = track as! History
					var song = historyTrack.title
					if !song.contains("KEBF") {
						song = song + "\n"
						playlist.append(NSAttributedString.init(string: song, attributes: titleAttributes))
					}
				}
			}
		}
		DispatchQueue.main.async {
			self.titleHistory.attributedText = playlist
		}
	}
}
