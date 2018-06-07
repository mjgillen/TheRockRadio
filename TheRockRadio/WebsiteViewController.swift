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
		if let link = URL(string: "https://www.esterobayradio.org") {
			UIApplication.shared.open(link)
		}
	}
	
	@IBAction func onContactButton(_ sender: Any) {
		sendFeedbackEmail()
//		if let link = URL(string: "https://www.esterobayradio.org/contact") {
//			UIApplication.shared.open(link)
//		}
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
	
	func sendFeedbackEmail() {
		if MFMailComposeViewController.canSendMail() {
			mailDelegate = MailDelegate()
			let mail = MFMailComposeViewController()
			mail.mailComposeDelegate = self.mailDelegate
			let appVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
			mail.setToRecipients(["mmgillen@me.com"])
			mail.setSubject("The Rock App v\(appVersion) Feedback")
//			let deviceModel = UIDevice.current.model
//			let systemVersion = UIDevice.current.systemVersion
//			let userId = (UIApplication.shared.delegate as? AppDelegate)?.driveNetworkingSession.email
//			let sdkVersion = DriveCore.WrappedSDK.version.sdk

			let messageBody = "\n\n"
//				"App Version: \(Constants.appVersion)\n" +
//				"SDK Version: \(sdkVersion)\n" +
//				"Device Model: \(deviceModel)\n" +
//				"Type: iOS\n" +
//				"OS: \(systemVersion)\n" +
//			"UserId: \(userId ?? "")\n"
			
			mail.setMessageBody(messageBody, isHTML: false)
			
//			if let filePath = SleepLogService.shared.filePath {
//				do {
//					let sleepLogData = try Data(contentsOf: filePath)
//					mail.addAttachmentData(sleepLogData, mimeType: "text/plain", fileName: "SleepLog.txt")
//				} catch { }
//			}
			
			present(mail, animated: true)
		} else {
			let email = "mmgillen@me.com"
			if let url = URL(string: "mailto:\(email)") {
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
