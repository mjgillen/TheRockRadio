//
//  InfoViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/17/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

	@IBOutlet weak var titleLabel: UILabel!
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		NotificationCenter.default.addObserver(self, selector: #selector(InfoViewController.handleNotification), name: NSNotification.Name(rawValue: "SongName"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@objc func handleNotification(notification: NSNotification) {
		titleLabel.text = notification.object as? String
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
