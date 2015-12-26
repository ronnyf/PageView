//
//  TableViewController.swift
//  PageViewDemo
//
//  Created by Ronny Falk on 2015-12-22.
//  Copyright © 2015 RFx Software Inc. All rights reserved.
//

import UIKit

protocol PageConfigurable {
    func configureWithPage(page: UIView)
}

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 8
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Page", forIndexPath: indexPath) as! PageViewCell
//        cell.textLabel?.text = String(indexPath.row)
        cell.titleLabel.text = String(indexPath.row)
        cell.configureWithPage(newPage())
        return cell
    }
    
    private func newPage() -> UIView {
        let view = UIView()
        view.backgroundColor = randomColor()
        return view
    }
    
    private func randomColor() -> UIColor {
        let r = CGFloat(drand48())
        let g = CGFloat(drand48())
        let b = CGFloat(drand48())
        let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        return color
    }

}
