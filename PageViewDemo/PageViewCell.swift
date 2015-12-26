//
//  PageViewCell.swift
//  PageViewDemo
//
//  Created by Ronny Falk on 2015-12-22.
//  Copyright © 2015 RFx Software Inc. All rights reserved.
//

import UIKit

class PageViewCell: UITableViewCell, PageViewDatasource, PageConfigurable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pageView: PageView! {
        didSet {
            pageView.datasource = self
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        pageView.prepareForReuse()
    }
    
    func sizeForPage(page: UIView) -> CGSize {
        return CGSizeMake(pageView.bounds.width, pageView.bounds.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("page size: \(pageView.bounds.size)")
    }

    func pageBefore(page: UIView, reusablePage: UIView?) -> UIView {
        guard let reusable = reusablePage else {
            return newPage()
        }
        reusable.backgroundColor = randomColor()
        return reusable
    }
    
    func pageAfter(page: UIView, reusablePage: UIView?) -> UIView {
        guard let reusable = reusablePage else {
            return newPage()
        }
        reusable.backgroundColor = randomColor()
        return reusable
    }
    
    func configureWithPage(page: UIView) {
        pageView.setPage(page)
    }
    
    private func newPage() -> UIView {
        let view = UIView()
        print("creating new page")
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
