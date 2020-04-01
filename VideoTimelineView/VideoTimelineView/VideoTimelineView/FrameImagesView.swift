//
//  FrameImagesView.swift
//  Examplay
//
//  Created by Tomohiro Yamashita on 2020/03/01.
//  Copyright © 2020 Tom. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation



class FrameImage: UIImageView {
    var tolerance:Float64? = nil
}


// MARK: - FrameImagesView
class FrameImagesView: UIScrollView {
    
    
    var mainView:VideoTimelineView!
    
    var frameImagesArray:[FrameImage] = []
    
    
    var thumbnailFrameSize:CGSize = CGSize(width: 640,height: 480)
    let preferredTimescale:Int32 = 100
    var timeTolerance = CMTimeMakeWithSeconds(10 , preferredTimescale:100)

    var maxWidth:CGFloat = 0
    var minWidth:CGFloat = 0
    
    var parentScroller:TimelineScroller? = nil
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        self.isScrollEnabled = false
        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor(hue: 0, saturation:0, brightness:0.0, alpha: 0.02)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("FrameImagesView init(coder:) has not been implemented")
    }
    
    
    
    
    func reset() {
        discardAllFrameImages()
        cancelImageGenerator()
        
        prepareFrameViews()
        layout()
        requestVisible(depth:0, wide:2, direction:0)
    }
    
    //MARK: - timer for animation
    var animationTimer = Timer()
    var animating = false
    func startAnimation() {
        animating = true
        displayFrames()
        animationTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.animate(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(animationTimer, forMode:RunLoop.Mode.common)
        
    }
    
    func stopAnimation() {
        animationTimer.invalidate()
        animating = false
        
        
        if let parent = parentScroller {
            frame.origin = CGPoint(x: parent.frame.size.width / 2, y: parent.measureHeight)
            parent.addSubview(self)
        }
        displayFrames()
    }
    
    @objc func animate(_ timer:Timer) {
        if animating == false {
            return
        }
        displayFrames()
    }
    
    //MARK: - layout


    var uponFrames = Set<Int>()
    var belowFrames = Set<Int>()
    var deepFrames = Set<Int>()
    var hiddenFrames = Set<Int>()
    
    
    func layout() {
        setThumnailFrameSize()
        let coordinated = coordinateFrames()
        uponFrames = coordinated.upon
        belowFrames = coordinated.below
        hiddenFrames = coordinated.hidden
        deepFrames = coordinated.deep
        displayFrames()
    }
    
    func displayFrames() {
        
        var baseView:UIView = self
        var offset:CGPoint = CGPoint.zero
        
        if let parent = parentScroller {
            let visibleHalf = parent.frame.size.width / 2
            
            if animating {
                    if let layer = parent.layer.presentation() {
                        offset.x = visibleHalf - layer.bounds.origin.x
                        offset.y = parent.frame.origin.y + parent.measureHeight
                        frame.origin = offset
                        mainView!.timelineView.viewForAnimate.addSubview(self)
                    }
            }
        }
        
        let visibleSide = indexOfVisibleSide()
        func locate(_ index:Int, visible:Bool) {
            if frameImagesArray.count > index && index >= 0 {
                let frameImg = frameImagesArray[index]
                if index >= visibleSide.left && index <= visibleSide.right {
                    let position = positionWithIndex(index)
                    frameImg.frame = CGRect(x: position, y:0, width: thumbnailFrameSize.width, height: thumbnailFrameSize.height)
                    if visible {
                        self.addSubview(frameImg)
                    } else {
                        frameImg.removeFromSuperview()
                    }
                } else {
                    frameImg.removeFromSuperview()
                }
                
            }
        }
        for element in belowFrames {//do addSubview under the upon
            locate(element, visible:true)
        }
        for element in uponFrames {
            locate(element, visible:true)
        }
        for element in hiddenFrames {// includes deep
            locate(element, visible:false)
        }
        
    }
    
    func positionWithIndex(_ index:Int) -> CGFloat {
        let position = frame.size.width * (CGFloat(index) / CGFloat(thumbnailCountFloat()))
        return position
    }
    
    func coordinateFrames() -> (upon:Set<Int>, below:Set<Int>, hidden:Set<Int>, deep:Set<Int>) {
        
        let keyDivision = Int(pow(2,Double(Int(log2(maxWidth * 2 / (self.frame.size.width + 1))))))
        if keyDivision <= 0 {
            return (Set<Int>(), Set<Int>(), Set<Int>(), Set<Int>())
        }
        let keyCount = ((frameImagesArray.count - 1) / keyDivision) + 1
        
        
        var visibleIndexes = Set<Int>()
        var uponElements = Set<Int>()
        for index in 0 ... (keyCount - 1) {
            let uponIndex = index * keyDivision
            uponElements.insert(uponIndex)
            visibleIndexes.insert(uponIndex)
        }
        var belowElements = Set<Int>()
        let belowDivision = keyDivision / 2
        if belowDivision >= 1 {
            for index in 0 ..< (keyCount - 1) {
                let belowIndex = (index * keyDivision) + (keyDivision / 2)
                belowElements.insert(belowIndex)
                visibleIndexes.insert(belowIndex)
            }
        }
        var deepElements = Set<Int>()
        let deepDivision = belowDivision / 2
        if deepDivision >= 1 {
            if let max = visibleIndexes.max() {
                for index in visibleIndexes {
                    if max > index {
                        deepElements.insert(index + deepDivision)
                    }
                }
            }
        }
        var hiddenElements = Set<Int>()
        for index in 0 ..< frameImagesArray.count {
            if !visibleIndexes.contains(index) {
                let hiddenIndex = index
                hiddenElements.insert(hiddenIndex)
            }
        }
        return (uponElements,belowElements,hiddenElements, deepElements)
    }
    
    
    func setThumnailFrameSize() {
        if let asset = mainView!.asset {
            var frameSize = CGSize(width: 640,height: 480)
            let tracks:Array = asset.tracks(withMediaType:AVMediaType.video)
            if tracks.count > 0 {
                let track = tracks[0]
                frameSize = track.naturalSize.applying(track.preferredTransform)
                frameSize.width = abs(frameSize.width)
                frameSize.height = abs(frameSize.height)
            }
            thumbnailFrameSize = mainView!.resizeHeightKeepRatio(frameSize, height:self.frame.size.height)
        }
    }
    
    func assetDuration() -> Float64? {
        if let asset = mainView!.asset {
            return CMTimeGetSeconds(asset.duration)
        }
        return nil
    }
    
    func prepareFrameViews() {
        frameImagesArray = []
        for _ in 0 ... Int(thumbnailCountFloat()) {
            let view = FrameImage()
            view.alpha = 0
            frameImagesArray += [view]
        }
    }
    
    
    
    func thumbnailCountFloat() -> CGFloat {
        return maxWidth / thumbnailFrameSize.width
    }

    
    func indexWithTime(_ time:Float64) -> Int? {
        if let assetDuration = assetDuration() {
            let value = time / (assetDuration / Float64(thumbnailCountFloat()))
            var intValue = Int(value)
            if value - Float64(intValue) >= 0.5 {
                intValue += 1
            }
            return intValue
        }
        return nil
    }
    
    func timeWithIndex(_ index:Int) -> Float64 {
        if let assetDuration = assetDuration() {
            return assetDuration * ((Float64(index)) / Float64(thumbnailCountFloat()))
        }
        return 0
    }
    
    
    
    
    //MARK: - frame images
    func cancelImageGenerator() {
        if let asset = mainView!.asset {
            let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.cancelAllCGImageGeneration()
        }
    }
    
    func discardAllFrameImages() {
    
        for index in 0 ..< frameImagesArray.count {
            let view = frameImagesArray[index]
            UIView.animate(withDuration: 0.5,delay:Double(0.0),options:UIView.AnimationOptions.curveEaseOut, animations: { () -> Void in
                
                view.alpha = 0
                
            },completion: { finished in
                
                view.image = nil
                view.removeFromSuperview()
                view.tolerance = nil
            })
        }
        frameImagesArray = []
    }
    
    
    
    func requestAll(){

        var timesArray = [NSValue]()
        for index in 0 ..< frameImagesArray.count {
            timesArray += [NSValue(time:CMTimeMakeWithSeconds(timeWithIndex(index) , preferredTimescale:preferredTimescale))]
        }
        requestImageGeneration(timesArray:timesArray)
    }
    
    
    var requesting = Set<Int>()
    func requestVisible(depth:Int, wide:Float, direction:Float) {
        var timesArray = [NSValue]()
        func request(_ index:Int) {
            
            if self.requesting.count > 0 && self.requesting.contains(index) {
                return
            }
            
            if frameImagesArray.count > index {
                let imageView = frameImagesArray[index]
                var needsUpdate = false
                if let tolerance = imageView.tolerance {
                    if tolerance > CMTimeGetSeconds(timeTolerance) * 1.2 {
                        needsUpdate = true
                    }
                }
                if imageView.image == nil || needsUpdate {
                    timesArray += [NSValue(time:CMTimeMakeWithSeconds(timeWithIndex(index) , preferredTimescale:preferredTimescale))]
                    self.requesting.insert(index)
                }
            }
        }
        let visibleSide = indexOfVisibleSide()
        let width = visibleSide.right - visibleSide.left
        var additionLeft = Int(Float(width) * wide)
        var additionRight = additionLeft
        if direction > 0 {
            additionLeft = Int(Float(-width) * direction)
        } else if direction < 0 {
            additionRight = Int(Float(width) * direction)
        }
        
        
        for index in uponFrames {
            if index >= visibleSide.left - additionLeft && index <= visibleSide.right + additionRight {
                request(index)
            }
        }
        let belowAddLeft = Int(Float(additionLeft) * 0.5) - Int(Float(width) * 0.7)
        let belowAddRight = Int(Float(additionRight) * 0.5) - Int(Float(width) * 0.7)
        if depth > 0 {
            for index in belowFrames {
                if index >= visibleSide.left - belowAddLeft && index <= visibleSide.right + belowAddRight {
                    request(index)
                }
            }
        }
        let deepAddLeft = Int(Float(additionLeft) * 0.2) - Int(Float(width) * 0.4)
        let deepAddRight = Int(Float(additionRight) * 0.2) - Int(Float(width) * 0.4)
        if depth > 1 {
            for index in deepFrames {
                if index >= visibleSide.left - deepAddLeft && index <= visibleSide.right + deepAddRight {
                    request(index)
                }
            }
        }
        if timesArray.count > 0 {
            requestImageGeneration(timesArray:timesArray)
        }
    }
    
    func indexOfVisibleSide() -> (left:Int, right:Int) {
        func indexWithPosition(_ position:CGFloat) -> Int{
            let index = position * CGFloat(thumbnailCountFloat()) / frame.size.width
            var indexInt = Int(index)
            if index - CGFloat(indexInt) > 0.5 {
                indexInt += 1
            }
            return indexInt
        }
        var visibleLeft = indexWithPosition(-(parentScroller!.frame.width / 2) + parentScroller!.contentOffset.x - thumbnailFrameSize.width) - 1
        var visibleRight = indexWithPosition(parentScroller!.contentOffset.x + (parentScroller!.frame.size.width * 0.5) + thumbnailFrameSize.width)
        if visibleLeft < 0 {
            visibleLeft = 0
        }
        let max = frameImagesArray.count - 1
        if visibleRight > max {
            visibleRight = max
        }
        return (visibleLeft, visibleRight)
    }
   
    func updateTolerance() {
        if mainView!.asset == nil {
            return
        }
        let thumbDuration = Float64(thumbnailFrameSize.width / self.frame.size.width) * mainView!.duration * 2
                timeTolerance = CMTimeMakeWithSeconds(thumbDuration , preferredTimescale:100)
        
        
    }

    func requestImageGeneration(timesArray:[NSValue]) {
        
        if let asset = mainView!.asset {
            let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            let maxsize = CGSize(width: thumbnailFrameSize.width * 1.5,height: thumbnailFrameSize.height * 1.5)
            assetImgGenerate.maximumSize = maxsize
            assetImgGenerate.requestedTimeToleranceAfter = timeTolerance
            assetImgGenerate.requestedTimeToleranceBefore = timeTolerance
            
            assetImgGenerate.generateCGImagesAsynchronously(forTimes: timesArray,
                                                            completionHandler:
                { time,resultImage,actualTime,result,error  in
                    
                    let timeValue = CMTimeGetSeconds(time)
                    if let image = resultImage {
                        DispatchQueue.main.async {
                            self.setFrameImage(image:UIImage(cgImage:image), time:timeValue)
                        }
                    }
                    if let index = self.indexWithTime(timeValue) {
                        self.requesting.remove(index)
                    }
            })
        }
    }
    
    
    func setFrameImage(image:UIImage, time:Float64) {
         
        if let index = indexWithTime(time) {
            if frameImagesArray.count > index && index >= 0 {
                let imageView = frameImagesArray[index]

                imageView.image = image
                imageView.tolerance = CMTimeGetSeconds(timeTolerance)
                UIView.animate(withDuration: 0.2,delay:Double(0),options:UIView.AnimationOptions.curveEaseOut, animations: { () -> Void in
                    
                    imageView.alpha = 1
                    
                },completion: { finished in
                    
                    
                })
                imageView.alpha = 1
                imageView.backgroundColor = .red
            }
        }
    }
}


