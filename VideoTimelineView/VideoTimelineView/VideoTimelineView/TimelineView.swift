//
//  TimelineView.swift
//  Examplay
//
//  Created by Tomohiro Yamashita on 2020/02/18.
//  Copyright © 2020 Tom. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class TimelineView: UIView, UIScrollViewDelegate {
    var mainView:VideoTimelineView? = nil
    let scroller = TimelineScroller()
    let centerLine = CenterLine()
    let viewForAnimate = UIScrollView()
    
    let durationPerHeight:Float64 = 0.35
    var animating = false
    
    override init (frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(hue: 0, saturation:0, brightness:0.0, alpha: 0.05)
        
        viewForAnimate.frame.origin = CGPoint.zero
        viewForAnimate.isScrollEnabled = false
        viewForAnimate.isUserInteractionEnabled = false
        self.addSubview(viewForAnimate)
        
        self.addSubview(scroller)
        scroller.delegate = self
        
        self.addSubview(scroller.measure)
        scroller.configure(parent: self)
        centerLine.configure(parent:self)
        coordinate()
        
        self.addSubview(scroller.trimView)
        self.addSubview(centerLine)
        
        scroller.measure.parentView = self
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("TimelineView init(coder:) has not been implemented")
    }

    
    //MARK: - coordinate
    func coordinate() {
        if mainView == nil {
            return
        }
        frame = mainView!.bounds
        viewForAnimate.frame.size = self.frame.size
        
        scroller.frame = self.bounds
        scroller.frameImagesView.frame.size.height = scroller.frame.size.height
        scroller.measure.frame = scroller.frame
        scroller.measure.frame.size.height = 20
        scroller.coordinate()
        
        centerLine.timeLabel.frame.size.height = scroller.measure.frame.size.height - 2
        let centerLineWidth:CGFloat = scroller.measure.frame.size.height * 5
        centerLine.frame = CGRect(x: (self.frame.size.width - centerLineWidth) / 2,y: 0,width: centerLineWidth,height: self.frame.size.height)
        
        centerLine.update()
        
        guard let view = (mainView) else { return }
        guard let _ = (view.asset) else { return }
        if scroller.frameImagesView.frame.size.width <= 0 {
            return
        }
        let previousThumbSize = scroller.frameImagesView.thumbnailFrameSize
        scroller.frameImagesView.setThumnailFrameSize()
        let thumbSize = scroller.frameImagesView.thumbnailFrameSize
        let unit = (thumbSize.height / CGFloat(durationPerHeight))
        scroller.measure.unitSize = unit
        let contentMaxWidth = (unit * CGFloat(centerLine.duration))
        scroller.frameImagesView.maxWidth = contentMaxWidth
        let defineMin = scroller.frame.size.width * 0.8
        var contentMinWidth:CGFloat
        
        if scroller.frameImagesView.maxWidth <= defineMin {
            contentMinWidth = scroller.frameImagesView.maxWidth
        } else {
            contentMinWidth = snapWidth(defineMin, max:scroller.frameImagesView.maxWidth)
        }
        
        scroller.frameImagesView.minWidth = contentMinWidth
        
        var currentWidth = snapWidth((scroller.frameImagesView.thumbnailFrameSize.width / previousThumbSize.width) * scroller.frameImagesView.frame.size.width, max:scroller.frameImagesView.maxWidth)
        if currentWidth < scroller.frameImagesView.minWidth {
            currentWidth = scroller.frameImagesView.minWidth
        } else if currentWidth > scroller.frameImagesView.maxWidth {
            currentWidth = scroller.frameImagesView.maxWidth
        }
        
        scroller.setContentWidth(currentWidth)
        
        scroller.reset()
        
        scroller.trimView.layout()
        if view.currentTime <= view.duration {
            setCurrentTime(view.currentTime, force:false)
        }
    }
    
    func snapWidth(_ width:CGFloat, max:CGFloat) -> CGFloat {
        let n = log2((2 * max) / width)
        var intN = CGFloat(Int(n))
        if n - intN >= 0.5 {
            intN += 1
        }
        let result = (2 * max) / (pow(2,intN))
        return result
    }
    
    func scrollPoint() -> CGFloat {
        return scroller.contentOffset.x / scroller.frameImagesView.frame.size.width
    }
    
    
    
    //MARK: new movie set
    func newMovieSet() {

        coordinate()
        if let asset = mainView!.asset{
            scroller.frameImagesView.setThumnailFrameSize()
            
            let duration = asset.duration
            let durationFloat = CMTimeGetSeconds(duration)
            centerLine.duration = durationFloat
            
            let detailThumbSize = scroller.frameImagesView.thumbnailFrameSize
            
            let unit = (detailThumbSize.height / CGFloat(durationPerHeight))
            scroller.measure.unitSize = unit
            
            
            let contentMaxWidth = (unit * CGFloat(centerLine.duration))
            scroller.frameImagesView.maxWidth = contentMaxWidth
            

            let defineMin = scroller.frame.size.width * 0.8
            var contentMinWidth:CGFloat
            
            if scroller.frameImagesView.maxWidth <= defineMin {
                contentMinWidth = scroller.frameImagesView.maxWidth
            } else {
                contentMinWidth = snapWidth(defineMin, max:scroller.frameImagesView.maxWidth)
            }
            scroller.frameImagesView.minWidth = contentMinWidth
            scroller.setContentWidth(scroller.frameImagesView.minWidth)
            
            scroller.reset()
            scroller.trimView.reset(duration:durationFloat)
        }
    }
    
    //MARK: - currentTime
    func setCurrentTime(_ currentTime:Float64, force:Bool) {
        if inAction() && force == false {
            return
        }
        if mainView!.asset == nil {
            return
        }
        var scrollPoint:CGFloat = 0
        scrollPoint = CGFloat(currentTime / mainView!.duration)
        
        centerLine.ignoreSendScrollToParent = true
            centerLine.setScrollPoint(scrollPoint)
        scroller.ignoreScrollViewDidScroll = true
        scroller.setScrollPoint(scrollPoint)
        
        scroller.frameImagesView.requestVisible(depth:0, wide:0, direction:0)
        
        scroller.frameImagesView.displayFrames()
        scroller.measure.setNeedsDisplay()
    }
    
    func moved(_ currentTime:Float64) {
        mainView!.timelineIsMoved(currentTime, scrub:true)
    }
    
    
    //MARK: - TrimViews
    func setTrimmerStatus(enabled:Bool) {
        if enabled {
            scroller.trimView.alpha = 1
            scroller.trimView.startKnob.isUserInteractionEnabled = true
            scroller.trimView.alpha = 1
            scroller.trimView.endKnob.isUserInteractionEnabled = true

        } else {
            scroller.trimView.alpha = 0.5
            scroller.trimView.startKnob.isUserInteractionEnabled = false
            scroller.trimView.alpha = 0.5
            scroller.trimView.endKnob.isUserInteractionEnabled = false
        }
    }
    
    func setTrimmerVisible(_ visible:Bool) {
        scroller.trimView.isHidden = !visible
    }

    
    func setTrim(start:Float64?, end:Float64?) {
        var changed = false
        if start != nil {
            scroller.trimView.startKnob.knobTimePoint = start!
            changed = true
        }
        if end != nil {
            scroller.trimView.endKnob.knobTimePoint = end!
            changed = true
        }
        if changed {
            scroller.trimView.layout()
        }
    }
    
    func setTrimWithAnimation(trim:VideoTimelineTrim, time:Float64) {
        scroller.trimView.moveToTimeAndTrimWithAnimation(time, trim:trim)
    }
    
    
    var manualScrolledAfterEnd = false
    func setTrimViewInteraction(_ active:Bool) {
        if mainView!.trimEnabled == false && active {
            return
        }
        
        scroller.trimView.startKnob.isUserInteractionEnabled = active
        scroller.trimView.endKnob.isUserInteractionEnabled = active
        
        if active {
            setManualScrolledAfterEnd()
        }
    }
    
    func setManualScrolledAfterEnd() {
        let trim = currentTrim()
        if mainView!.asset != nil {
            let currentTime = mainView!.currentTime
            if currentTime >= trim.end {
                manualScrolledAfterEnd = true
            } else {
                manualScrolledAfterEnd = false
            }
        }
    }
    
    func currentTrim() -> (start:Float64, end:Float64) {
        var start = scroller.trimView.startKnob.knobTimePoint
        var end = scroller.trimView.endKnob.knobTimePoint
        if mainView!.asset != nil {
            if end > mainView!.duration {
                end = mainView!.duration
            }
            if start < 0 {
                start = 0
            }
        }
        return (start, end)
    }
    

    func swapTrimKnobs() {
        let knob = scroller.trimView.endKnob
       scroller.trimView.endKnob = scroller.trimView.startKnob
        scroller.trimView.startKnob = knob
    }
    
    //MARK: - animation
    func startAnimation() {
        scroller.frameImagesView.startAnimation()
        scroller.measure.startAnimation()
        scroller.trimView.startAnimation()
    }
    
    func stopAnimation() {
        scroller.frameImagesView.stopAnimation()
        scroller.measure.stopAnimation()
        scroller.trimView.stopAnimation()
    }
    
    

    
    
    //MARK: - Gestures
    func inAction() -> Bool {
        if allTouches.count > 0 || scroller.isTracking || scroller.isDecelerating {
            return true
        } else {
            return false
        }
    }
    
    //MARK: - Scrolling

    var allTouches = [UITouch]()
    var pinching:Bool = false
    
    func scrollViewDidScroll(_ scrollView:UIScrollView) {
        scroller.trimView.layout()
        if scroller.ignoreScrollViewDidScroll {
            scroller.ignoreScrollViewDidScroll = false
            return
        }
        scroller.measure.setNeedsDisplay()
        scroller.frameImagesView.displayFrames()
        setTrimViewInteraction(false)
        let scrollPoint = scroller.contentOffset.x / scroller.frameImagesView.frame.size.width
        self.centerLine.setScrollPoint(scrollPoint)
        
        guard let mView = (mainView) else { return }
        if let receiver = mView.playStatusReceiver {
            receiver.videoTimelineMoved()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scroller.frameImagesView.requestVisible(depth:0, wide:0, direction:0)
        setTrimViewInteraction(true)
        let scrollPoint = scroller.contentOffset.x / scroller.frameImagesView.frame.size.width
        self.centerLine.setScrollPoint(scrollPoint)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                  willDecelerate decelerate: Bool) {
        scroller.frameImagesView.requestVisible(depth:0, wide:0, direction:0)
        if decelerate == false {
            setTrimViewInteraction(true)
        }
        let scrollPoint = scroller.contentOffset.x / scroller.frameImagesView.frame.size.width
        self.centerLine.setScrollPoint(scrollPoint)
    }
    
    
    
    //MARK: - Zooming
    
    var pinchCenterInContent:CGFloat = 0
    var pinchStartDistance:CGFloat = 0
    var pinchStartContent:(x:CGFloat,width:CGFloat) = (0,0)
    func pinchCenter(_ pointA:CGPoint, pointB:CGPoint) -> CGPoint {
        return CGPoint(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
    }
    func pinchDistance(_ pointA:CGPoint, pointB:CGPoint) -> CGFloat {
        return sqrt(pow((pointA.x - pointB.x),2) + pow((pointA.y - pointB.y),2));
    }
    func startPinch() {
        pinching = true
        scroller.isScrollEnabled = false
        
        let touch1 = allTouches[0]
        let touch2 = allTouches[1]
        let center = pinchCenter(touch1.location(in: self),pointB: touch2.location(in: self))
        
        pinchStartDistance = pinchDistance(touch1.location(in: self),pointB: touch2.location(in: self))
        let framewidth = scroller.frame.size.width
        pinchStartContent = ((framewidth / 2) - scroller.contentOffset.x,scroller.contentSize.width - framewidth)
        pinchCenterInContent = (center.x - pinchStartContent.x) / pinchStartContent.width
    }
    
    func updatePinch() {
        let touch1 = allTouches[0]
        let touch2 = allTouches[1]
        let center = pinchCenter(touch1.location(in: self), pointB:touch2.location(in: self))
        var sizeChange = (1 * pinchDistance(touch1.location(in: self), pointB: touch2.location(in: self))) / pinchStartDistance
        
        var contentWidth = pinchStartContent.width * sizeChange
        
        let sizeMin = scroller.frameImagesView.minWidth
        let sizeMax = scroller.frameImagesView.maxWidth
        
        if contentWidth < sizeMin {
            let sizeUnit = sizeMin / pinchStartContent.width
            sizeChange = ((pow(sizeChange/sizeUnit,2)/4) + 0.75) * sizeUnit
            contentWidth = pinchStartContent.width * sizeChange
            contentWidth = sizeMin
        } else if contentWidth > sizeMax {
            sizeChange = sizeMax
            contentWidth = sizeMax
        } else {
            let startRatio = pinchStartContent.width / sizeMax
            let currentRatio = startRatio * sizeChange
            let effect = ((sin(CGFloat.pi * 2 * log2(2/currentRatio)) * 0.108) - (sin(CGFloat.pi * 6 * log2(2/currentRatio)) * 0.009)) * currentRatio
            let resultWidth = sizeMax * (currentRatio + effect)
            contentWidth = resultWidth
        }
        let contentOrigin = center.x - (contentWidth * pinchCenterInContent)
        scroller.contentOffset.x = (scroller.frame.size.width / 2) - contentOrigin
        scroller.setContentWidth(contentWidth)
        scroller.frameImagesView.layout()
        
        scroller.frameImagesView.requestVisible(depth:2, wide:0, direction:0)
        self.centerLine.setScrollPoint(scroller.contentOffset.x / scroller.frameImagesView.frame.size.width)
        scroller.trimView.layout()
    }
    
    func endPinch() {
        scroller.frameImagesView.requestVisible(depth:0, wide:1, direction:0)
        
        let width = snapWidth(scroller.frameImagesView.frame.size.width, max:scroller.frameImagesView.maxWidth)
        
        let offset = self.resizedPositionWithKeepOrigin(width:scroller.frameImagesView.frame.size.width, origin:scroller.contentOffset.x, destinationWidth:width)
        //startAnimation()
        
        UIView.animate(withDuration: 0.1,delay:Double(0.0),options:UIView.AnimationOptions.curveEaseOut, animations: { () -> Void in
            
            self.scroller.setContentWidth(width, setOrigin:false)
            self.scroller.contentOffset.x = offset
            self.scroller.frameImagesView.layout()
            self.scroller.trimView.layout()
        },completion: { finished in
            self.pinching = false
            self.scroller.isScrollEnabled = true
        })
        
        self.scroller.frameImagesView.updateTolerance()
        
        self.centerLine.setScrollPoint(scroller.contentOffset.x / scroller.frameImagesView.frame.size.width)
        
        setTrimViewInteraction(true)
        
        guard let mView = (mainView) else { return }
        if let receiver = mView.playStatusReceiver {
            receiver.videoTimelineMoved()
        }
    }
    
    func resizedPositionWithKeepOrigin(width:CGFloat, origin:CGFloat, destinationWidth:CGFloat) -> CGFloat {
        let originPoint = origin / width
        let result = originPoint * destinationWidth
        return result
    }
    
    
}













