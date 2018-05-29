//
//  WebsiteViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 5/5/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit

class WebsiteViewController: UIViewController {

	@IBOutlet weak var callButton: UIButton!
	@IBOutlet weak var websiteButton: UIButton!
	@IBOutlet weak var contactButton: UIButton!
	@IBOutlet weak var donateButton: UIButton!
	
	
	
	@IBAction func onCallButton(_ sender: Any) {
		guard let number = URL(string: "tel://8057722037") else { return }
		UIApplication.shared.open(number)	}
	
	@IBAction func onWebsiteButton(_ sender: Any) {
		if let link = URL(string: "https://www.esterobayradio.org") {
			UIApplication.shared.open(link)
		}
	}
	
	@IBAction func onContactButton(_ sender: Any) {
		if let link = URL(string: "https://www.esterobayradio.org/contact") {
			UIApplication.shared.open(link)
		}
	}
	
	@IBAction func onDonateButton(_ sender: Any) {
		if let link = URL(string: "https://www.esterobayradio.org/support-the-rock") {
			UIApplication.shared.open(link)
		}
	}
	
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
