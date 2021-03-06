//
//  VideoTimelineView.swift
//  VideoTimelineView
//
//  Created by Tomohiro Yamashita on 2020/03/28.
//  Copyright © 2020 Tom. All rights reserved.
//

import UIKit
import AVFoundation

protocol TimelinePlayStatusReceiver: class {
    func videoTimelineStopped()
    func videoTimelineMoved()
    func videoTimelineTrimChanged()
}


struct VideoTimelineTrim {
    var start:Float64
    var end:Float64
}

class VideoTimelineView: UIView {
    
    public private(set) var asset:AVAsset? = nil
    var player:AVPlayer? = nil
    
    weak var playStatusReceiver:TimelinePlayStatusReceiver? = nil
    
    var repeatOn:Bool = false
    
    public private(set) var trimEnabled:Bool = false
    
    
    
    var currentTime:Float64 = 0
    public private(set) var duration:Float64 = 0
    
    public private(set) var audioPlayer:AVPlayer!
    public private(set) var audioPlayer2:AVPlayer!
    
    let timelineView = TimelineView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        timelineView.mainView = self
        timelineView.centerLine.mainView = self
        timelineView.scroller.frameImagesView.mainView = self
        timelineView.scroller.trimView.mainView = self
        
        self.addSubview(timelineView)
    }
    
    required init(coder aDecoder: NSCoder) {
       fatalError("MainView init(coder:) has not been implemented")
    }
    
    
    func viewDidLayoutSubviews() {
        coordinate()
    }
    
    func coordinate() {
        timelineView.coordinate()
    }
    
    func new(asset newAsset:AVAsset?) {
        if let new = newAsset {
            asset = new
            duration = CMTimeGetSeconds(new.duration)
            player = AVPlayer(playerItem: AVPlayerItem(asset: asset!))
            audioPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset!))
            audioPlayer.volume = 1.0
            audioPlayer2 = AVPlayer(playerItem: AVPlayerItem(asset: asset!))
            audioPlayer2.volume = 1.0
            timelineView.newMovieSet()
        }
    }

    
    func setTrim(start:Float64, end:Float64, seek:Float64?, animate:Bool) {
        
        var seekTime = currentTime
        if let time = seek {
            seekTime = time
        }
        if animate {
            timelineView.setTrimWithAnimation(trim:VideoTimelineTrim(start:start, end:end), time:seekTime)
        } else {
            timelineView.setTrim(start:start, end:end)
            if seek != nil {
                moveTo(seek!, animate:animate)
            }
        }
    }
    
    func setTrimIsEnabled(_ enabled:Bool) {
        trimEnabled = enabled
        timelineView.setTrimmerStatus(enabled:enabled)
    }
    
    func setTrimmerIsHidden(_ hide:Bool) {
        timelineView.setTrimmerVisible(!hide)
    }
    
    func currentTrim() -> (start:Float64, end:Float64) {
        let trim = timelineView.currentTrim()
        return (trim.start,trim.end)
    }
    
    func moveTo(_ time:Float64, animate:Bool) {
        if animate {
            
        } else {
            accurateSeek(time, scrub:false)
            timelineView.setCurrentTime(time, force:true)
        }
    }
    
    //MARK: - seeking
    var previousSeektime:Float64 = 0
    func timelineIsMoved(_ currentTime:Float64, scrub:Bool) {
        let move = abs(currentTime - previousSeektime)
        let seekTolerance = CMTimeMakeWithSeconds(move, preferredTimescale:100)
        
        if player != nil {
            player!.seek(to:CMTimeMakeWithSeconds(currentTime , preferredTimescale:100), toleranceBefore:seekTolerance,toleranceAfter:seekTolerance)
        }
        previousSeektime = currentTime
        if scrub {
            audioScrub()
        }
    }
    
    func accurateSeek(_ currentTime:Float64, scrub:Bool) {
        previousSeektime = currentTime
        timelineIsMoved(currentTime, scrub:scrub)
    }
    
    var scrubed1 = Date()
    var scrubed2 = Date()
    var canScrub1 = true
    var canScrub2 = true
    func audioScrub() {
        if player == nil {
            return
        }
        if scrubed2.timeIntervalSinceNow < -0.16 && canScrub1 {
            canScrub1 = false
            self.scrubed1 = Date()
            DispatchQueue.main.async {
                if self.audioPlayer.timeControlStatus == .playing {
                    self.audioPlayer.pause()
                    self.canScrub1 = true
                } else {
                    self.audioPlayer.seek(to: self.player!.currentTime())
                    self.audioPlayer.play()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        self.audioPlayer.pause()
                        self.audioPlayer.seek(to: self.player!.currentTime())
                        self.canScrub1 = true
                    }
                }
                
            }
        }
        if scrubed1.timeIntervalSinceNow < -0.16 && canScrub2 {
            canScrub2 = false
             self.scrubed2 = Date()
            DispatchQueue.main.async {
                if self.audioPlayer2.timeControlStatus == .playing {
                    self.audioPlayer2.pause()
                    self.canScrub2 = true
                } else {
                    self.audioPlayer2.seek(to: self.player!.currentTime())
                    self.audioPlayer2.play()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        self.audioPlayer2.pause()
                        self.audioPlayer2.seek(to: self.player!.currentTime())
                        self.canScrub2 = true
                    }
                }
            }
        }
    }
    
    
    //MARK: - play
    var playerTimer = Timer()
    @objc dynamic var playing = false
    func play() {
        if asset == nil {
            return
        }
        let currentTime = timelineView.centerLine.currentTime
        let reached = timeReachesEnd(currentTime)
        
        if reached.trimEnd {
            accurateSeek(timelineView.currentTrim().start, scrub:false)
            timelineView.manualScrolledAfterEnd = false
        } else if reached.movieEnd {
            accurateSeek(0, scrub:false)
            timelineView.manualScrolledAfterEnd = false
        }
        if player != nil {
            player!.play()
        }
        playerTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.playerTimerAction(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(playerTimer, forMode:RunLoop.Mode.common)
        playing = true
    }
    
    func stop() {
        playing = false
        if asset == nil || player == nil {
            return
        }
        player!.pause()
        playerTimer.invalidate()
        
        if let receiver = playStatusReceiver {
            receiver.videoTimelineStopped()
        }
    }
    
    var reachFlg = false
    @objc func playerTimerAction(_ timer:Timer) {
        if player == nil {
            return
        }
        var currentPlayerTime = CMTimeGetSeconds(player!.currentTime())
        
        let trim = timelineView.currentTrim()
        let reached = timeReachesEnd(currentPlayerTime)
        if timelineView.inAction() {
            if player!.timeControlStatus == .playing {
                player!.pause()
            }
        } else if reached.reached {
            if repeatOn && reached.trimEnd {
                
                if player!.timeControlStatus == .playing {
                    player!.pause()
                }
                currentPlayerTime = trim.start
                accurateSeek(currentPlayerTime, scrub:false)
                reachFlg = true
                
            } else {
                stop()
            }
            timelineView.setCurrentTime(currentPlayerTime,force:false)
            timelineView.manualScrolledAfterEnd = false
        } else if timelineView.animating == false {
            timelineView.setCurrentTime(currentPlayerTime,force:false)
            if player!.timeControlStatus == .paused {
                player!.play()
            }
            if reachFlg {
                if let receiver = playStatusReceiver {
                    receiver.videoTimelineMoved()
                }
                reachFlg = false
            }
        }
    }
    
    func timeReachesEnd(_ time:Float64) -> (reached:Bool, trimEnd:Bool, movieEnd:Bool) {
        var reached = false
        var trimEnd = false
        var movieEnd = false
        if asset != nil {
            let duration = CMTimeGetSeconds(asset!.duration)
            let trimTimeEnd = timelineView.currentTrim().end
            if (time >= trimTimeEnd && timelineView.manualScrolledAfterEnd == false && trimEnabled) {
                trimEnd = true
                reached = true
            }
            if time >= duration {
                if trimTimeEnd < duration {
                    trimEnd = false
                }
                movieEnd = true
                reached = true
            }
        }
        return (reached, trimEnd, movieEnd)
    }

    
    //MARK: - 
    func resizeHeightKeepRatio(_ size:CGSize, height:CGFloat) -> CGSize {
        var result = size
        let ratio = size.width / size.height
        result.height = height
        result.width = height * ratio
        return result
    }
}
