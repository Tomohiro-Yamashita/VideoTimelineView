//
//  TrimView.swift
//  Examplay
//
//  Created by Tomohiro Yamashita on 2020/03/12.
//  Copyright © 2020 Tom. All rights reserved.
//

import UIKit

class TrimView: UIView {
    var mainView:VideoTimelineView!
    
    var timelineView:TimelineView!
    var parentScroller:TimelineScroller!
    var startKnob = TrimKnob()
    var endKnob = TrimKnob()
    var movieDuration:Float64 = 0
    
    let canPassThroughEachKnobs = true
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("TrimView init(coder:) has not been implemented")
    }
    
    func configure(_ timeline:TimelineView, scroller:TimelineScroller) {
        timelineView = timeline
        parentScroller = scroller
        self.frame = timeline.frame
        startKnob.configure(timeline, trimmer:self)
        endKnob.configure(timeline, trimmer:self)
        
        timelineView.addSubview(startKnob)
        timelineView.addSubview(endKnob)
    }
    
    
    func reset(duration:Float64) {
        movieDuration = duration
        startKnob.knobTimePoint = 0
        endKnob.knobTimePoint = 3
        if duration < endKnob.knobTimePoint {
            endKnob.knobTimePoint = duration
        }
        layout()
    }
    
     
    
    let knobWidth:CGFloat = 20
    let knobWidthExtend:CGFloat = 5
    func layout() {
        if self.isHidden {
            return
        }
        
        swapKnobs()
        
        let knobPositions = knobPositionsAsVisible()
        let startPosition = knobPositions.start
        let endPosition = knobPositions.end
        
        startKnob.knobPositionOnScreen = startPosition
        endKnob.knobPositionOnScreen = endPosition
        startKnob.isOutOfScreen = knobPositions.startFixed
        endKnob.isOutOfScreen = knobPositions.endFixed
        
        startKnob.frame = CGRect(x:startPosition - knobWidth - knobWidthExtend, y:self.frame.origin.y, width:knobWidth + knobWidthExtend * 2, height:self.frame.size.height)
        endKnob.frame = CGRect(x:endPosition - knobWidthExtend, y:self.frame.origin.y, width:knobWidth + knobWidthExtend * 2, height:self.frame.size.height)
        
        self.setNeedsDisplay()
    }
    
    //MARK: - draw
    
    override func draw(_ rect: CGRect) {
        
        
        var startRect = startKnob.frame
        var endRect = endKnob.frame
        if startRect.size.height <= 0 {
            return
        }
        if animating {
            if let layer = startKnob.layer.presentation() {
                startRect = layer.frame
            }
            if let layer = endKnob.layer.presentation() {
                endRect = layer.frame
            }
        }
        startRect.origin.x += knobWidthExtend
        startRect.size.width -= knobWidthExtend * 2
        endRect.origin.x += knobWidthExtend
        endRect.size.width -= knobWidthExtend * 2
        if startRect.origin.x > endRect.origin.x + endRect.size.width {
            let swapRect = startRect
            startRect = endRect
            endRect = swapRect
        }
        
        
        let beamWidth:CGFloat = 3
        var outerRect = CGRect(x: startRect.origin.x,y: 0,width: endRect.origin.x + endRect.size.width - startRect.origin.x,height:startRect.size.height)
        var innerRect = CGRect(x:startRect.origin.x + startRect.size.width,y:beamWidth,width: endRect.origin.x - startRect.origin.x - startRect.size.width,height:startRect.size.height - (beamWidth * 2))
        
        let screenLeft = cgToTime(screenToTimelinePosition(0))
        let screenRight = cgToTime(screenToTimelinePosition(timelineView.frame.size.width))
        var color = UIColor(hue: 0.1, saturation:0.8, brightness:1, alpha: 1)
        let outColor = UIColor(hue: 0.1, saturation:0.8, brightness:1, alpha: 0.3)
        if  (endKnob.knobTimePoint < screenLeft || startKnob.knobTimePoint > screenRight) {
            color = outColor
        } else {
            let addition = knobWidth + 10
            let knobWidthTime = cgToTime(knobWidth)
            if endKnob.knobTimePoint + knobWidthTime * 0.9 > screenRight {
                outerRect.size.width += addition
                innerRect.size.width += addition
                let outRect = CGRect(x: timelineView.frame.size.width - knobWidth, y: beamWidth,width: knobWidth, height: endRect.size.height - beamWidth * 2)
                let path = UIBezierPath(rect:outRect)
                outColor.setFill()
                path.fill()
            }
            if startKnob.knobTimePoint - knobWidthTime * 0.9 < screenLeft {
                outerRect.origin.x -= addition
                innerRect.origin.x -= addition
                outerRect.size.width += addition
                innerRect.size.width += addition
                let outRect = CGRect(x: 0, y: beamWidth,width: knobWidth, height: endRect.size.height - beamWidth * 2)
                let path = UIBezierPath(rect:outRect)
                outColor.setFill()
                path.fill()
            }
        }
        
        let path = UIBezierPath(roundedRect:outerRect, cornerRadius:5)
        path.usesEvenOddFillRule = true
        let innerPath = UIBezierPath(roundedRect:innerRect, cornerRadius:2)
        path.append(innerPath)
        color.setFill()
        path.fill()
    }
    
    
    
    //MARK: - timer for animation
    var animationTimer = Timer()
    var animating = false
    func startAnimation() {
        animationTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.animate(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(animationTimer, forMode:RunLoop.Mode.common)
        animating = true
    }
    
    func stopAnimation() {
        animating = false
        self.setNeedsDisplay()
        animationTimer.invalidate()
    }
    
    @objc func animate(_ timer:Timer) {
        if animating == false {
            return
        }
        self.setNeedsDisplay()
    }
    
    
    //MARK: - positioning
    func swapKnobs() {
        if startKnob.knobTimePoint > endKnob.knobTimePoint {
            if canPassThroughEachKnobs {
                //timelineView.swapTrimKnobs()
            } else {
                let start = endKnob.knobTimePoint
                endKnob.knobTimePoint = startKnob.knobTimePoint
                startKnob.knobTimePoint = start
            }
        }
    }
    
    func anotherKnob(_ knob:TrimKnob) -> TrimKnob {
        if knob == startKnob {
            return endKnob
        }
        return startKnob
    }
    
    func knobOnScreen(_ knob:TrimKnob) -> CGFloat {
        let maxWidth = scrollMaxWidth()
        let offset = scrollOffset()
        let position = CGFloat(knob.knobTimePoint / movieDuration) * maxWidth
        return position - offset + (timelineView.frame.size.width / 2)
    }
    
    func knobsMinDistanceTime() -> Float64 {
        return Float64(0.1)
    }
    
    func knobsMinDistanceFloat() -> CGFloat {
        return timeToCG(knobsMinDistanceTime())
    }
    
    func timeToCG(_ time:Float64) -> CGFloat {
        return CGFloat(time / movieDuration) * scrollMaxWidth()
    }
    
    func cgToTime(_ cgFloat:CGFloat) -> Float64 {
        return Float64(cgFloat / scrollMaxWidth()) * movieDuration
    }
    
    func screenToTimelinePosition(_ onScreen:CGFloat) -> CGFloat {
        return onScreen + scrollOffset() - (timelineView.frame.size.width / 2)
    }
    
    func timelineToScreenPosition(_ position:CGFloat) -> CGFloat {
        return position - scrollOffset() + (timelineView.frame.size.width / 2)
    }
    
    func knobPositionsAsVisible() -> (start:CGFloat, end:CGFloat, startFixed:Bool, endFixed:Bool) {
        
        let positionStart = knobOnScreen(startKnob)
        let positionEnd = knobOnScreen(endKnob)
        var resultStart = positionStart
        var resultEnd = positionEnd
        var startFixed:Bool = false
        var endFixed:Bool = false
        let screenRight = timelineView.frame.size.width// + offset
        let minDistance = knobsMinDistanceFloat()
        
        if positionStart < knobWidth {
            if (positionEnd - minDistance - knobWidth) < 0 {
                resultStart = positionEnd - minDistance
            } else {
                resultStart = knobWidth
            }
            startFixed = true
        } else if positionStart > screenRight {
            resultStart = screenRight
            startFixed = true
        }
        if positionEnd < 0 {
            resultEnd = 0
            endFixed = true
        } else if positionEnd + knobWidth > screenRight {
            if positionStart + minDistance + knobWidth > screenRight {
                resultEnd = positionStart + minDistance
            } else {
                resultEnd = screenRight - knobWidth
            }
        }
        if true {
            let distance = abs(resultStart - resultEnd)
            if distance < minDistance {
                let value = (minDistance - distance) / 2
                resultStart -= value
                resultEnd += value
                startFixed = true
                endFixed = true
            }
        }
        return (resultStart, resultEnd, startFixed, endFixed)
    }
    
    func scrollOffset() -> CGFloat {
        return parentScroller.contentOffset.x
    }
    
    func scrollMaxWidth() -> CGFloat {
        return parentScroller.frameImagesView.frame.size.width
    }
    
    func knobTimeOnScreen(_ knob:TrimKnob) -> Float64 {
        let offset = scrollOffset()
        let position = offset + knob.knobPositionOnScreen - (timelineView.frame.size.width / 2)
        let maxWidth = scrollMaxWidth()
        let time = Float64(position / maxWidth) * movieDuration
        return time
    }
    
    
    func knobMoveRange(_ knob:TrimKnob) -> (min:Float64, max:Float64) {
        var min:Float64 = 0
        var max:Float64 = movieDuration
        let minDistance = knobsMinDistanceTime()
        if canPassThroughEachKnobs {
            if knob == startKnob {
                max -= minDistance
            } else if knob == endKnob {
                min += minDistance
            }
        } else {
            if knob == startKnob {
                max = endKnob.knobTimePoint - minDistance
            } else if knob == endKnob {
                min = startKnob.knobTimePoint + minDistance
            }
        }
        return (min, max)
    }
    
    func visibleKnobMoveLimit(_ knob:TrimKnob, margin:CGFloat) -> (min:Bool, max:Bool) {
        let range = knobMoveRange(knob)
        let minOnScreen = timelineToScreenPosition(timeToCG(range.min))
        let maxOnScreen = timelineToScreenPosition(timeToCG(range.max))
        var resultMin = false
        var resultMax = false
        if minOnScreen >= margin && minOnScreen <= timelineView.frame.width - margin {
            resultMin = true
        }
        if maxOnScreen >= margin && maxOnScreen <= timelineView.frame.width - margin {
            resultMax = true
        }
        return (resultMin , resultMax )
    }
    
    func directionReachesEnd(_ knob:TrimKnob, direction:CGFloat) -> Bool {
        let visibleLimit = visibleKnobMoveLimit(knob, margin:knobWidth)
        if direction > 0 {
            if visibleLimit.max {
                return true
            }
        } else if direction < 0 {
            if visibleLimit.min {
                return true
            }
        }
        return false
    }
    
    func fixKnobPoint(_ knob:TrimKnob, move:CGFloat, startKnobPoint:Float64) -> (knobPoint:Float64, fixed:Bool) {

        var timePoint = startKnobPoint + cgToTime(move)

        let moveRange = knobMoveRange(knob)
        var fixed = false
        if timePoint < moveRange.min {
            timePoint = moveRange.min
            fixed = true
        }
        if timePoint > moveRange.max {
            timePoint = moveRange.max
            fixed = true
        }
        return (timePoint, fixed)
    }
    
    func updateKnob(_ knob:TrimKnob, timePoint:Float64) {
        knob.knobTimePoint = timePoint
        layout()
        
        timelineView.moved(knob.knobTimePoint)
    }
    
    func resetSeek(_ time:Float64) {
        if edgeScrolled {
            moveToTimeWithAnimation(time)
        } else {
            mainView!.accurateSeek(time, scrub:true)
        }
        edgeScrolled = false
    }
    
    func moveToTimeWithAnimation(_ time:Float64) {
        moveToTimeAndTrimWithAnimation(time, trim:nil)
    }
    
    func moveToTimeAndTrimWithAnimation(_ time:Float64, trim:VideoTimelineTrim?) {
        let player = mainView!.player
        if player == nil {
            return
        }
        if player!.timeControlStatus == .playing {
            player!.pause()
        }
        timelineView.animating = true
        mainView!.isUserInteractionEnabled = false
        timelineView.startAnimation()
        
        UIView.animate(withDuration: 0.2,delay:Double(0.0),options:UIView.AnimationOptions.curveEaseOut, animations: { () -> Void in
            if let pinnedTrim = trim {
                self.timelineView.setTrim(start:pinnedTrim.start,end:pinnedTrim.end)
            }
            self.timelineView.setCurrentTime(time,force:false)
        },completion: { finished in
            
            self.mainView!.isUserInteractionEnabled = true
            if self.mainView!.playing {
                self.mainView!.accurateSeek(time, scrub:false)
                player!.play()
            } else {
                self.mainView!.accurateSeek(time, scrub:true)
            }
            self.timelineView.animating = false
            self.timelineView.setManualScrolledAfterEnd()
            self.timelineView.stopAnimation()
            if let receiver = self.mainView!.playStatusReceiver {
                receiver.videoTimelineMoved()
            }
        })
    }
    
    //MARK: - edgeScroll
    var edgeScrollTimer = Timer()
    var edgeScrolled = false
    var edgeScrollingKnob:TrimKnob? = nil
    var edgeScrollStrength:CGFloat = 0
    var edgeScrollingKnobPosition:CGFloat = 0
    var edgeScrollLastChangedTime:Date = Date()
    var edgeScrollLastChangedPosition:CGFloat = 0
    
    
    func updateEdgeScroll(_ knob:TrimKnob, strength:CGFloat, position:CGFloat) {
        var changed = false
        if edgeScrollStrength != strength {
            edgeScrollStrength = strength
            changed = true
        }
        if edgeScrolling() == false {
            startEdgeScroll(knob)
            edgeScrolled = true
        } else if changed {
            edgeScrollLastChangedPosition = scrollOffset()
            edgeScrollLastChangedTime = Date()
        }
        edgeScrollingKnobPosition = position
        edgeScrollingKnob = knob
    }
    
    func startEdgeScroll(_ knob:TrimKnob) {
        edgeScrollTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.edgeScrollTimer(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(edgeScrollTimer, forMode:RunLoop.Mode.common)
        edgeScrollLastChangedTime = Date()
        edgeScrollLastChangedPosition = scrollOffset()
    }
    
    @objc func edgeScrollTimer(_ timer:Timer) {
        if let knob = edgeScrollingKnob {
            let movedPosition = currentEdgeScrollMovedPosition()
            let destination = currentEdgeScrollPosition(movedPosition)
            let moveRange = knobMoveRange(knob)
            var knobPoint = cgToTime(edgeScrollingKnobPosition - (timelineView.frame.size.width / 2) + destination)
                
            var overLimit:Float64 = 0
            if knobPoint > moveRange.max {
                overLimit = knobPoint - moveRange.max
                knobPoint = moveRange.max
                
            } else if knobPoint < moveRange.min {
                overLimit = knobPoint - moveRange.min
                knobPoint = moveRange.min
                
            }
            updateKnob(knob, timePoint:knobPoint)
            if (knob == startKnob && knobPoint > endKnob.knobTimePoint) || (knob == endKnob && knobPoint < startKnob.knobTimePoint) {
                timelineView.swapTrimKnobs()
            }
            timelineView.setCurrentTime(cgToTime(destination) - overLimit,force:true)
        }
    }
    
    func stopEdgeScrollTimer() {
        edgeScrollTimer.invalidate()
        edgeScrollStrength = 0
        edgeScrollingKnob = nil
    }
    
    func edgeScrolling() -> Bool {
        return edgeScrollTimer.isValid
    }
    
    func currentEdgeScrollPosition(_ moved:CGFloat) -> CGFloat {
        var result:CGFloat = 0
        
        let maxWidth = scrollMaxWidth()
        result = edgeScrollLastChangedPosition + moved
        if result < 0 {
            result = 0
        } else if result > maxWidth {
            result = maxWidth
        }
        return result
    }
    
    func currentEdgeScrollMovedPosition() -> CGFloat {
        let pastTime = -edgeScrollLastChangedTime.timeIntervalSinceNow
        return CGFloat(pastTime) * edgeScrollStrength * 5
    }
}


//MARK: - TrimKnob
class TrimKnob:UIView {
    var timelineView:TimelineView!
    var knobPositionOnScreen:CGFloat = 0
    var trimView:TrimView!
    var knobTimePoint:Float64 = 0
    var isOutOfScreen:Bool = false
    
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        self.isMultipleTouchEnabled = true
        self.isUserInteractionEnabled = true
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("TrimKnob init(coder:) has not been implemented")
    }
    
    func configure(_ timeline:TimelineView, trimmer:TrimView) {
        timelineView = timeline
        trimView = trimmer
    }
    
    //MARK: - Touch Events
    var allTouches = [UITouch]()
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if !allTouches.contains(touch) {
                allTouches += [touch]
            }
            if !timelineView!.allTouches.contains(touch) {
                timelineView!.allTouches += [touch]
            }
        }
        if timelineView!.allTouches.count == 1 && allTouches.count == 1 {
            if dragging == false {
                startDrag()
            }
            evaluateTap = true
        } else {
            evaluateTap = false
        }
    }
    
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if timelineView!.allTouches.count > 1 {
            if dragging {
                cancelDrag()
            }
        }
        if timelineView!.allTouches.count == 2 {
            if timelineView!.pinching {
                timelineView!.updatePinch()
            } else {
                timelineView!.startPinch()
            }
        }
        if dragging && timelineView!.allTouches.count == 1 && allTouches.count == 1 {
            updateDrag()
        }
        evaluateTap = false
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if let index = allTouches.firstIndex(of:touch) {
                allTouches.remove(at: index)
            }
            if let index = timelineView!.allTouches.firstIndex(of:touch) {
                timelineView!.allTouches.remove(at: index)
            }
        }
        if timelineView!.pinching && timelineView!.allTouches.count < 2 {
            timelineView!.endPinch()
        }
        if dragging {
            endDrag()
        }
        
        if evaluateTap && timelineView!.allTouches.count == 0 {
            tapped()
        }
        evaluateTap = false
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if let index = allTouches.firstIndex(of:touch) {
                allTouches.remove(at: index)
            }
            if let index = timelineView!.allTouches.firstIndex(of:touch) {
                timelineView!.allTouches.remove(at: index)
            }
        }
        
        if timelineView!.pinching {
            timelineView!.endPinch()
        }
        if dragging {
            endDrag()
        }
        evaluateTap = false
    }
    
    
    //MARK: - actions
    
    var dragging:Bool = false
    var dragStartPoint = CGPoint.zero
    var startKnobTimePoint:Float64 = 0
    var dragStartOffset:CGFloat = 0
    var startTimeOutOfScreen:Float64 = 0
    var scrolling = false
    var startCurrentTime:Float64 = 0
    var evaluateTap:Bool = false
    var ignoreEdgeScroll = false

    func startDrag() {
        
        dragging = true
        let touch = allTouches[0]
        dragStartPoint = touch.location(in: timelineView)
        startKnobTimePoint = knobTimePoint
        dragStartOffset = trimView.scrollOffset()
        startTimeOutOfScreen = trimView.knobTimeOnScreen(self) - startKnobTimePoint
        
        
        startCurrentTime = timelineView.mainView!.currentTime
        
        if edgeScrollStrength(dragStartPoint.x) != 0 {
            ignoreEdgeScroll = true
        } else {
            ignoreEdgeScroll = false
        }
    }
    
    func updateDrag() {
        let touch = allTouches[0]
        let currentPoint = touch.location(in: timelineView)
        let scrolled = trimView.scrollOffset() - dragStartOffset
        let move = currentPoint.x - dragStartPoint.x + scrolled
        let startKnobPoint = startKnobTimePoint + startTimeOutOfScreen
        
        let timePoint = startKnobPoint + trimView.cgToTime(move)
        let dragPoint = trimView.cgToTime(trimView.screenToTimelinePosition(currentPoint.x))
        let onKnob = trimView.timeToCG(timePoint - dragPoint)
        let anotherKnob = trimView.anotherKnob(self)
        let anotherTimePoint = anotherKnob.knobTimePoint
        let knobWidth = trimView.knobWidth
        var swapping:CGFloat = 0
        
        
        if  anotherTimePoint < timePoint && startKnobPoint < anotherTimePoint
        {
            swapping = trimView.timeToCG(anotherTimePoint - timePoint)
            if -swapping > knobWidth {
                swapping = -knobWidth
            }
        } else if  anotherTimePoint > timePoint && startKnobPoint > anotherTimePoint
        {
            swapping = trimView.timeToCG(anotherTimePoint - timePoint)
            if swapping > knobWidth {
                swapping = knobWidth
            }
        }
        var rangeOut = false
        let range = trimView.knobMoveRange(self)
        if timePoint > range.max || timePoint < range.min {
            rangeOut = true
        }
        
        if rangeOut == false && ((self == trimView.startKnob && dragPoint > anotherTimePoint) || (self == trimView.endKnob && dragPoint < anotherTimePoint)) {
                timelineView.swapTrimKnobs()
        }
        
        
        let strength = edgeScrollStrength(currentPoint.x)
        let reachedEnd = trimView.directionReachesEnd(self, direction:strength)
        if strength != 0 && ignoreEdgeScroll == false && reachedEnd == false {
            trimView.updateEdgeScroll(self, strength:strength, position:currentPoint.x + onKnob + swapping)
        } else {
            let fixedKnobPoint = trimView.fixKnobPoint(self, move:move + swapping, startKnobPoint:startKnobPoint)

            trimView.updateKnob(self, timePoint:fixedKnobPoint.knobPoint)
            if strength == 0 {
                ignoreEdgeScroll = false
                
            }
            if strength == 0 || reachedEnd {
                if trimView.edgeScrolling() {
                    trimView.stopEdgeScrollTimer()
                }
            }
        }
        
        guard let mainView = (timelineView.mainView) else { return }
        if let receiver = mainView.playStatusReceiver {
            receiver.videoTimelineTrimChanged()
        }
    }
    
    func endDrag() {
        let anotherKnob = trimView.anotherKnob(self)
        let distance = abs(anotherKnob.knobTimePoint - knobTimePoint)
        let minDistance = trimView.knobsMinDistanceTime()
        if distance < minDistance {
            if self == trimView.startKnob {
                knobTimePoint -= (minDistance - distance)
            } else if self == trimView.endKnob {
                knobTimePoint += (minDistance - distance)
            }
            
            trimView.timelineView.animating = true
            trimView.startAnimation()
            UIView.animate(withDuration: 0.2,delay:Double(0.0),options:UIView.AnimationOptions.curveEaseOut, animations: { () -> Void in
                
                self.trimView.layout()
                
            },completion: { finished in
                self.trimView.stopAnimation()
                self.timelineView.animating = false
            })
        }
        timelineView.setManualScrolledAfterEnd()
        trimView.resetSeek(startCurrentTime)
        dragging = false
        trimView.stopEdgeScrollTimer()
        
        if evaluateTap == false {
            guard let mainView = (timelineView.mainView) else { return }
            if let receiver = mainView.playStatusReceiver {
                receiver.videoTimelineTrimChanged()
            }
        }
    }
    
    func cancelDrag() {
        knobTimePoint = startKnobTimePoint
        
        timelineView.setManualScrolledAfterEnd()
        dragging = false
        trimView.layout()
        trimView.resetSeek(startCurrentTime)
        trimView.stopEdgeScrollTimer()
    }
    
    func tapped() {
        trimView.moveToTimeWithAnimation(knobTimePoint)
        timelineView.setManualScrolledAfterEnd()
    }
    
    
    func edgeScrollStrength(_ position:CGFloat) -> CGFloat {
        var strength:CGFloat = 0
        let edgeWidth:CGFloat = 40
        if position >= timelineView.frame.size.width - edgeWidth {
            strength = position + edgeWidth - timelineView.frame.size.width
        } else if position <= edgeWidth {
            strength = position - edgeWidth
        }
        return strength
    }
    
    
    
}
