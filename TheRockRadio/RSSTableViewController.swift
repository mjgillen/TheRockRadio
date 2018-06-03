//
//  RSSTableViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 5/28/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit

struct rssCell {
	var item = "item"
	var title = "Title"
	var link = "link"
	var description = "description of the new event"
	var pubDate = "pubDate"
	var guid = "guid"
	var read = false
}

enum rssElement {
	case item
	case title
	case link
	case description
	case pubDate
	case guid
}

extension RSSTableViewController: XMLParserDelegate {
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		switch elementName {
			
		case "item":
			currentElement = .item
		case "title":
			xTitle = ""
			currentElement = .title
		case "link":
			xLink = ""
			currentElement = .link
		case "description":
			xDescription = ""
			currentElement = .description
		case "pubDate":
			xPubDate = ""
			currentElement = .pubDate
		case "guid":
			currentElement = .guid
		default:
			break
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		switch elementName {
			
		case "item":
			break
		case "title":
			break
		case "link":
			break
		case "description": // , "pubDate":
			var newEntry = rssCell()
			newEntry.title = xTitle
			newEntry.link = xLink
			newEntry.description = xDescription
			newEntry.pubDate = xPubDate
			rssArray.append(newEntry)
			resetEntry()
		case "guid":
			break
		default:
			break
		}
	}
	
	func resetEntry() {
		xTitle = ""
		xLink = ""
		xDescription = ""
		xPubDate = ""
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		switch currentElement {
		case .item:
			break
		case .title:
			xTitle = xTitle + string
		case .link:
			xLink = xLink + string
		case .description:
			xDescription = xDescription + string
		case .pubDate:
			xPubDate = xPubDate + string
		case .guid:
			break
		default:
			break
		}
	}
	func parserDidEndDocument(_ parser: XMLParser) {
		self.tableView.reloadData()
	}
}

class RSSTableViewController: UITableViewController {

	var currentElement: rssElement!
	var xTitle = ""
	var xLink = ""
	var xDescription = ""
	var xPubDate = ""
	var rssData: [String : String] = [:]
	var rssArray: [rssCell] = []

	static let rssFeedURL = "https://AnimalRadio.com/TheRockApp/TheRockCommunityRadio-WhatsUp.xml"

    override func viewDidLoad() {
        super.viewDidLoad()
		readRSSFeed()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
	}
	
	func readRSSFeed() {
		let parser = XMLParser(contentsOf: URL(string: RSSTableViewController.rssFeedURL)!)
		parser?.delegate = self
		parser?.shouldResolveExternalEntities = false
		parser?.parse()
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rssArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RSSTableViewCell", for: indexPath)
		let rssRow = rssArray[indexPath.row]
		cell.detailTextLabel?.text = rssRow.description
		cell.textLabel?.text = rssRow.title
		if rssRow.read {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .disclosureIndicator
		}
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//		let storyboard = UIStoryboard(name: "Main", bundle: nil)
//		guard let detailsVC = storyboard.instantiateViewController(withIdentifier: "RSSDetailsViewController") as? RSSDetailsViewController else { return }
//		var rssData = rssArray[indexPath.row]
//		detailsVC.rssData = rssData
//		rssData.read = true
//		self.navigationController?.pushViewController(detailsVC, animated: true)
		
		var rssData = rssArray[indexPath.row]
		rssData.read = true
		let webVC = BasicWebViewController()
//		let backItem = UIBarButtonItem()
//		backItem.title = NSLocalizedString("Back", comment: "Back");
//		navigationItem.backBarButtonItem = backItem
//		webVC.webTitle = rssData.title
//		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.navigationController?.pushViewController(webVC, animated: true)

		let urlString = rssData.link.replacingOccurrences(of: " |\n", with: "", options: .regularExpression)
		webVC.loadURL(url: urlString)
	}

	func OLDtableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		guard let detailsVC = storyboard.instantiateViewController(withIdentifier: "RSSDetailsViewController") as? RSSDetailsViewController else { return }
		detailsVC.rssData = rssArray[indexPath.row]
		rssArray[indexPath.row].read = true
		self.navigationController?.pushViewController(detailsVC, animated: true)
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
