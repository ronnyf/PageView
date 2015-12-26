//
//  PageView.swift
//  Version 1.0
//
//  Created by Ronny Falk on 2015-12-22.
//  Copyright © 2015 RFx Software Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
//  (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
//  publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished 
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public protocol PageViewDatasource: class {
    func pageBefore(page: UIView, reusablePage: UIView?) -> UIView
    func pageAfter(page: UIView, reusablePage: UIView?) -> UIView
}

/**
 The PageView class manages a list of content pages (UIView subclasses) and allows horizontal scrolling through those pages indefinitely. Only a single row layout is supported. 
 
 Pages are being dequeued by default. The user has the choice of reusing or instantiating new pages (reusing is however recommended). If multiple pages are being made available for reuse, only a small amount ~2 will be kept.
 
 When enbedded in a UITableView, it is recommended to call the 'prepareForReuse' function of the PageView in the respective function of the UITableView subclass. All content pages will be removed and the content offset will be reset to (0,0).
 
 - parameter pageSize: This defaults to CGSizeZero, which sizes the pages to the full size of the page view.
 - parameter datasource: Requires the implementation of the 'pageBefore:' and 'pageAfter:' functions, which must always return a UIView object.
 
*/
public class PageView: UIScrollView, UIScrollViewDelegate {
    
    public var pageSize: CGSize = CGSizeZero
    private var adjustedPageSize: CGSize {
        if pageSize.width == 0 && pageSize.height == 0 {
            return bounds.size
        }
        return pageSize
    }
    
    public weak var datasource: PageViewDatasource?
    private var contentView: UIView
    
    override init(frame: CGRect) {
        contentView = UIView()
        super.init(frame: frame)
        performInitialization()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        contentView = UIView()
        super.init(coder: aDecoder)
        performInitialization()
    }
    
    public func prepareForReuse() {
        removeAllPages()
    }
    
    deinit {
        removeAllPages()
    }
    
    private func performInitialization() {
        updateContentSize()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.userInteractionEnabled = false
        addSubview(contentView)

        let v = ["contentView": contentView]
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: v))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: v))
        
// in case you'd want to NOT use autolayout, set translatesAutoresizingMaskIntoConstraints to true before un-commenting below
//        var frame = bounds
//        frame.size = size
//        contentView.frame = frame
        
        delegate = self
        showsHorizontalScrollIndicator = false
    }
    
    //WWDC 2011 - 104; excellent talk
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateContentSize()
        adjustPageSizes()
        recenterIfNecessary()
        
        let visibleBounds = convertRect(bounds, toView: contentView)
        let minimumVisibleX = CGRectGetMinX(visibleBounds)
        let maximumVisibleX = CGRectGetMaxX(visibleBounds)
        
        tilePages(minimumVisibleX, max: maximumVisibleX)
    }
    
    private lazy var reusablePages = { Set<UIView>() }()
    
    private func updateContentSize() {
        //32 is pretty arbitrary here - we never keep more that visiblePages + 1 around, so it shouldnt matter how large this number is, it just determines when we will have a page shift / offset reset
        let width = bounds.width * 32
        if contentSize.width != width {
            let size = CGSizeMake(width, bounds.height)
            contentSize = size
        }
    }
    
    private func adjustPageSizes() {
        var origin: CGPoint = CGPointZero
        for page in visiblePages {
            
            var frame = page.frame
            if frame.width == adjustedPageSize.width && frame.height == adjustedPageSize.height { return }
            frame.size = adjustedPageSize
            frame.origin = origin
            page.frame = frame
            
            origin.x += frame.width
        }
        
        //in case the device is rotated, let's keep the first page visible
        if let firstPage = visiblePages.first {
            contentOffset = CGPointMake(firstPage.frame.origin.x, contentOffset.y)
        }
    }
    
    //WWDC 2011 - 104; really great talk
    private func tilePages(min: CGFloat, max: CGFloat) {
        //do nothing unless we actually have something to show
        if visiblePages.count == 0 {
            return
        }
        
        //add missing pages to the right
        if let lastPage = visiblePages.last {
            var rightEdge = CGRectGetMaxX(lastPage.frame);
            while rightEdge < max {
                let newRightEdge = addNextPageForPage(lastPage, rightEdge: rightEdge)
                if newRightEdge == CGFloat.max { break }
                rightEdge = newRightEdge
            }
        }
        
        //add missing pages to the left
        if let firstPage = visiblePages.first {
            var leftEdge = CGRectGetMinX(firstPage.frame)
            while leftEdge > min {
                let newLeftEdge = addPreviousPageForPage(firstPage, leftEdge: leftEdge)
                if newLeftEdge == CGFloat.max { break }
                leftEdge = newLeftEdge
            }
        }
        
        //remove pages that have fallen off the left edge
        if var firstPage = visiblePages.first {
            while CGRectGetMaxX(firstPage.frame) < min {
                reusablePages.insert(firstPage)
                firstPage.removeFromSuperview()
                visiblePages.removeAtIndex(0)
                guard let newFirst = visiblePages.first else { break }
                firstPage = newFirst
            }
        }
        
        //remove pages that have fallen off the right edge
        if var lastPage = visiblePages.last {
            while lastPage.frame.origin.x > max {
                reusablePages.insert(lastPage)
                lastPage.removeFromSuperview()
                visiblePages.removeLast()
                guard let newLast = visiblePages.last else { break }
                lastPage = newLast
            }
        }

        trimReusables()
//        print("visible pages count: \(visiblePages.count), reusable: \(reusablePages.count)")
    }
    
    private func addNextPageForPage(page: UIView, rightEdge: CGFloat) -> CGFloat {
        let reusable = reusablePages.first
        guard let nextPage = datasource?.pageAfter(page, reusablePage: reusable) else { return CGFloat.max }
        
        var frame = page.frame
        frame.size = adjustedPageSize
        frame.origin.x = rightEdge
        nextPage.frame = frame
        
        contentView.addSubview(nextPage)
        visiblePages.append(nextPage)
        
        if reusablePages.contains(nextPage) == true {
            reusablePages.remove(nextPage)
        }
        
        return CGRectGetMaxX(frame)
    }
    
    private func addPreviousPageForPage(page: UIView, leftEdge: CGFloat) -> CGFloat {
        let reusable = reusablePages.first
        guard let previousPage = datasource?.pageBefore(page, reusablePage: reusable) else { return CGFloat.max }
        
        var frame = page.frame
        frame.size = adjustedPageSize
        frame.origin.x = leftEdge - frame.size.width
        previousPage.frame = frame
        
        contentView.addSubview(previousPage)
        visiblePages.insert(previousPage, atIndex: 0)
        
        if reusablePages.contains(previousPage) {
            reusablePages.remove(previousPage)
        }
        
        return CGRectGetMinX(frame)
    }
    
    private func trimReusables() {
        while reusablePages.count > 2 {
            reusablePages.removeFirst()
        }
    }
    
    //WWDC 2011 - 104; great talk
    private func recenterIfNecessary() {
        let currentOffset = contentOffset
        let contentWidth = contentSize.width
        
        let xOffset  = (contentWidth - bounds.width) / 2.0
        let distanceFromCenter = fabs(currentOffset.x - xOffset);
        
        if distanceFromCenter > (contentWidth / 4.0) {
            let newOffset = CGPointMake(xOffset, currentOffset.y);
            self.contentOffset = newOffset
            
            // move content by the same amount so it appears to stay still
            for page in visiblePages {
                var center = contentView.convertPoint(page.center, toView:self)
                let delta = (xOffset - currentOffset.x)
                center.x += delta
                page.center = convertPoint(center, toView: contentView)
                
//                let pageFrame = page.frame
//                let px = pageFrame.origin.x % pageFrame.width
//                print("px: \(px)") //this means the theoretical first page has a slight x-offset - we need to use that later when we calculate the target offset
            }
        }
    }
    
    private(set) var visiblePages: [UIView] = [UIView]()
    
    //MARK: - public methods
    
    ///
    public func setPage(page: UIView?) {
        removeAllPages()
        
        guard let newPage = page else { return }
        
        visiblePages.append(newPage)
        newPage.frame = CGRectMake(0, 0, adjustedPageSize.width, adjustedPageSize.height)
        contentView.addSubview(newPage)
        //addSubview should trigger a layout cycle (calling layoutSubviews)
    }
    
    public func removeAllPages() {
        visiblePages.removeAll(keepCapacity: false)
        reusablePages.removeAll(keepCapacity: false)
        
        for page in contentView.subviews {
            page.removeFromSuperview()
        }
        
        setContentOffset(CGPointZero, animated: false)
    }
    
    //MARK: - scroll view delegate
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var target = targetContentOffset.memory

        guard let firstPage = visiblePages.first else { return }
        
        let firstFrameOrigin = firstPage.frame.origin
        let firstPageVisibleWidth = firstFrameOrigin.x % adjustedPageSize.width //given the current layout, how much of the first page is actually visible
        let delta = firstPageVisibleWidth - adjustedPageSize.width //the x offset of the very first page in the given content size
        
        let targetPageOrigin = target.x / adjustedPageSize.width
        let roundedNewXOffset = round(targetPageOrigin) * adjustedPageSize.width + delta
        
        let co = scrollView.contentOffset
        
        switch velocity.x {
        case 0.0:
            //user has stopped, snap to closest
            let ffo = firstPage.frame.origin
            let xOffset = co.x - ffo.x
            if xOffset < adjustedPageSize.width / 2.0 {
                target.x = ffo.x
            } else {
                target.x = ffo.x + adjustedPageSize.width
            }
        default:
            target.x = roundedNewXOffset
        }
        
        targetContentOffset.memory = target
    }

}
