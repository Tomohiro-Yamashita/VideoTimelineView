# VideoTimelineView
Video timeline UI for iOS Apps
- With trimmer
- Zoom in/out with pinch
- Scrub with sound
- Repeat playing in the trim

## Usage
Copy the VideoTimelineView folder in this project to yours


- To setup
    ```
    let videoTimelineView = VideoTimelineView()
    videoTimelineView.frame = timelineRect
    videoTimelineView.new(asset:AVAsset(url:videoURL))
    view.addSubview(videoTimelineView)
    ```


- To get actions from VideoTimelineView
    Add TimelinePlayStatusReceiver protocol in your ViewController
    ```
    class ViewController: UIViewController, TimelinePlayStatusReceiver {
    ```
    And set viewController as receiver
    ```
    videoTimelineView.playStatusReceiver = self
    ```

- Get actions
    Implement these functions in your viewController
    ```
    func videoTimelineStopped()
    func videoTimelineMoved()
    func videoTimelineTrimChanged()
    ```

    To get values of the trimmer
    ```
    let trim = videoTimelineView.currentTrim()
    print("start time: \(trim.start)")
    print("end time: \(trim.end)")
    ```


- To control
    ```
     //Repeat in the trimmer
    videoTimelineView.repeatOn = true
    
     //If set in false, the trimmer will be ignored
    videoTimelineView.setTrimIsEnabled(true)
    
     //Hide trimmer
    videoTimelineView.setTrimmerIsHidden(true)
    
     //Go to 0s with animation
    videoTimelineView.moveTo(0, animate:true)
    
     //Set trimmer from 5 to 10 with animation and move to 3
    videoTimelineView.setTrim(start:5, end:10, seek:3, animate:true)
    ```
## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)

## Contact
[E-mail](tomo_dev@sockettv.org), [twitter](https://twitter.com/DevYamashita), [Facebook](https://www.facebook.com/TomohiroYamashitaApps/)

