//
//  TimelineMeasure.swift
//  Examplay
//
//  Created by Tomohiro Yamashita on 2020/03/08.
//  Copyright © 2020 Tom. All rights reserved.
//

import UIKit

class TimelineMeasure: UIView {

    var unitSize:CGFloat = 100
    var frameImagesView:FrameImagesView? = nil
    var parentScroller:TimelineScroller? = nil
    var parentView:TimelineView? = nil
    var stringColor:UIColor = UIColor(hue: 0.0, saturation:0.0, brightness:0.35, alpha: 1)
    var animating = false
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        self.isMultipleTouchEnabled = true
        self.isUserInteractionEnabled = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("TimelineMeasure init(coder:) has not been implemented")
    }
    
    
    
    override func draw(_ rect: CGRect) {
        
        if frameImagesView == nil {
            return
        }
        
        let max = frameImagesView!.maxWidth
        var width = frameImagesView!.frame.size.width
        if animating {
            if let layer = frameImagesView!.layer.presentation() {
                width = layer.frame.size.width
            }
        }
        if width == 0 {
            return
        }
        var unit = (width / max) * unitSize
        
        let unitWidth = CGFloat(80)
        var division = 0
        while (unit <= unitWidth) {
            unit *= 2
            division += 1
            if division > 1000 {
                break
            }
        }
        let unitLength = pow(2,Double(division + 1)) / 2
        func index(_ position:CGFloat) -> Int {
            return Int(position / unit)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: self.frame.size.height * 0.7)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: stringColor]

        var string = ""
        
        var visibleRect = rect
        if let parent = parentScroller {
            
            if animating {
                if let layer = parent.layer.presentation() {
                    let offset = layer.bounds.origin
                    visibleRect.origin = offset
                    visibleRect.size = parent.frame.size
                } else {
                    visibleRect = parent.visibleRect()
                }
            } else {
                visibleRect = parent.visibleRect()
            }
        }
        let startIndex = index(visibleRect.origin.x) - 10 * (division + 1)
        let endIndex = index(visibleRect.origin.x + visibleRect.size.width)
        
        for index in startIndex ... endIndex {
            if index < 0 {
                continue
            }
            let position = CGFloat(index) * unit - visibleRect.origin.x + (visibleRect.size.width / 2)
            if division == 0 {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: position + (unit / 2 ) - (unitWidth / 4) , y:(self.frame.size.height / 2)))
                path.addLine(to: CGPoint(x: position + (unit / 2) + (unitWidth / 4), y:(self.frame.size.height / 2)))
                path.lineWidth = 1
                stringColor.setStroke()
                path.stroke()
            } else {
                for i in 1 ... 3 {
                    let point = position + ((unit / 4 ) * CGFloat(i))
                    let r:CGFloat = 0.8
                    let pointRect = CGRect(x: point - r, y: (self.frame.size.height / 2) - r, width: r * 2,height: r * 2)
                    let path = UIBezierPath(ovalIn:pointRect)
                    stringColor.setFill()
                    path.fill()
                }
            }
            
            let length = unitLength * Double(index)
            let minute = Int(length / 60)
            let second = Int(length - Double(minute * 60))
            
            string = String(format: "%02d:%02d", minute, (Int(second)))
            
            string.draw(with: CGRect(x: position - (unitWidth / 2), y:0, width: unitWidth, height: self.frame.size.height), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            
        }
    }
    
    //MARK: - timer for animation
    var animationTimer = Timer()
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
    
    
    
    //MARK: - Touch Events
    var allTouches = [UITouch]()
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if !allTouches.contains(touch) {
                allTouches += [touch]
            }
            if !parentView!.allTouches.contains(touch) {
                parentView!.allTouches += [touch]
            }
        }
    }
    
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if parentView!.allTouches.count == 2 {
            if parentView!.pinching {
                parentView!.updatePinch()
            } else {
                parentView!.startPinch()
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if let index = allTouches.firstIndex(of:touch) {
                allTouches.remove(at: index)
            }
            if let index = parentView!.allTouches.firstIndex(of:touch) {
                parentView!.allTouches.remove(at: index)
            }
        }
        if parentView!.pinching && parentView!.allTouches.count < 2 {
            parentView!.endPinch()
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if let index = allTouches.firstIndex(of:touch) {
                allTouches.remove(at: index)
            }
            if let index = parentView!.allTouches.firstIndex(of:touch) {
                parentView!.allTouches.remove(at: index)
            }
        }
        
        if parentView!.pinching {
            parentView!.endPinch()
        }
    }
}

