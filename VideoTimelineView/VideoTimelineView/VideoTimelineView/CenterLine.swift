//
//  CenterLine.swift
//  Examplay
//
//  Created by Tomohiro Yamashita on 2020/03/09.
//  Copyright © 2020 Tom. All rights reserved.
//

import UIKit
import AVFoundation

class CenterLine: UIView {

    var mainView:VideoTimelineView!
    
    let timeLabel = UILabel()
    var parentView:TimelineView? = nil
    var duration:Float64 = 0
    var currentTime:Float64 = 0
    let margin:CGFloat = 6
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("CenterLine init(coder:) has not been implemented")
    }
    
    func configure(parent:TimelineView) {
        parentView = parent
        self.setNeedsDisplay()
        
        self.timeLabel.adjustsFontSizeToFitWidth = true
        self.timeLabel.textAlignment = .center
        
        self.timeLabel.text = String("00:00.00")
        

        self.addSubview(timeLabel)
    }
    
    func update() {
        self.setNeedsDisplay()
        let textMargin = margin + 3
        self.timeLabel.frame.size.width = self.bounds.size.width - textMargin * 2
        self.timeLabel.frame.origin = CGPoint(x:textMargin,y:0)
        self.timeLabel.textColor = UIColor(hue: 0.94, saturation:0.68, brightness:0.95, alpha: 0.94)
        setTimeText()
        timeLabel.font = UIFont(name:"HelveticaNeue-CondensedBold" ,size:timeLabel.frame.size.height * 0.9)

    }

    
    override func draw(_ rect: CGRect) {
        
        
        gradient()
        
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0,height: 0), blur: 6,  color: UIColor(hue: 0, saturation:0, brightness:0.0, alpha: 0.30).cgColor)
        
        UIColor(hue: 0, saturation:0, brightness:1, alpha: 0.92).setFill()
        
        let labelRect = CGRect(x: margin,y: 0.3,width: self.frame.size.width - margin * 2,height: timeLabel.frame.size.height + 1)
        let rectPath = UIBezierPath(roundedRect:labelRect, cornerRadius:timeLabel.frame.size.height)
        rectPath.fill()
        context.restoreGState()
        
        
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: self.frame.size.width / 2 , y:timeLabel.frame.size.height))
        path.addLine(to: CGPoint(x:self.frame.size.width / 2 , y:self.frame.size.height))
        path.lineWidth = 1.4
        UIColor(hue: 0, saturation:0, brightness:1.0, alpha: 0.7).setStroke()
        path.stroke()
        
    }
    

    func gradient() {
        let width = self.frame.size.width
        
        
        let context = UIGraphicsGetCurrentContext()!

        let startColor = UIColor(hue: 0, saturation:0, brightness:0.0, alpha: 0.06).cgColor
        let endColor = UIColor.clear.cgColor
        let colors = [startColor, endColor] as CFArray

        let locations = [0, 1] as [CGFloat]

        let space = CGColorSpaceCreateDeviceRGB()

        let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations)!
        context.drawLinearGradient(gradient, start: CGPoint(x:(width / 2) - 0.7, y:0), end: CGPoint(x: (width / 2) - 4, y: 0), options: [])
        context.drawLinearGradient(gradient, start: CGPoint(x:(width / 2) + 0.7, y:0), end: CGPoint(x: (width / 2) + 4, y: 0), options: [])
    }
    
    var ignoreSendScrollToParent = false
    func setScrollPoint(_ scrollPoint:CGFloat) {
        currentTime = Float64(scrollPoint) * duration
        setTimeText()
        if !ignoreSendScrollToParent {
            if let parent = parentView {
                parent.moved(currentTime)
            }
        }
        
        mainView!.currentTime = currentTime
        ignoreSendScrollToParent = false
    }
    
    func setTimeText() {
        let minute = Int(currentTime / 60)
        let second = (currentTime - Float64(minute) * 60)
        let milliSec = Int((second - Float64(Int(second))) * 100)
        let text = String(format: "%02d:%02d.%02d", minute, (Int(second)), milliSec)
        timeLabel.text = text
    }
}
