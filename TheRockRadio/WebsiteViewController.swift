//
//  WebsiteViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 5/5/18.
//  Copyright © 2018 On The Move Software. All rights reserved.
//

import UIKit
import MessageUI

class WebsiteViewController: UIViewController {

	@IBOutlet weak var callButton: UIButton!
	@IBOutlet weak var websiteButton: UIButton!
	@IBOutlet weak var contactButton: UIButton!
	@IBOutlet weak var donateButton: UIButton!
	
	var mailDelegate:           MFMailComposeViewControllerDelegate!

	
	@IBAction func onCallButton(_ sender: Any) {
		guard let number = URL(string: "tel://8057722037") else { return }
		UIApplication.shared.open(number)	}
	
	@IBAction func onWebsiteButton(_ sender: Any) {
//		// Launch Safari
//		if let link = URL(string: "https://www.esterobayradio.org") {
//			UIApplication.shared.open(link)
//		}
		
		// Embed in App
		let webVC = BasicWebViewController()
		self.navigationController?.pushViewController(webVC, animated: true)
		webVC.loadURL(url: "https://www.esterobayradio.org")
	}
	
	@IBAction func onContactButton(_ sender: Any) {
		sendFeedbackEmail()
	}
	
	@IBAction func onDonateButton(_ sender: Any) {
		if let link = URL(string: "https://www.esterobayradio.org/support-the-rock") {
			UIApplication.shared.open(link)
		}
		
// new way doesn't work with PayPal
//		 Embed in App
//		let webVC = BasicWebViewController()
//		self.navigationController?.pushViewController(webVC, animated: true)
//		webVC.loadURL(url: "https://www.esterobayradio.org/support-the-rock")
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func sendFeedbackEmail() {
		let emailAddress = "YourVoice@CentralCoastRadio.org"
		if MFMailComposeViewController.canSendMail() {
			mailDelegate = MailDelegate()
			let mail = MFMailComposeViewController()
			mail.mailComposeDelegate = self.mailDelegate
			let versionNumber = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
			let buildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
			let appVersion = versionNumber + buildNumber
			let emailAddress = "YourVoice@CentralCoastRadio.org"
			mail.setToRecipients([emailAddress])
			mail.setSubject("The Rock Community Radio App v\(appVersion) Feedback")
			let messageBody = "\n\n"
			mail.setMessageBody(messageBody, isHTML: false)
			present(mail, animated: true)
		} else {
			if let url = URL(string: "mailto:\(emailAddress)") {
				UIApplication.shared.open(url)
			}
		}
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true)
	}
}

class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true)
	}
}
