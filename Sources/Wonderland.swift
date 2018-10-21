import Foundation
import UIKit
import AVFoundation

public class Wonderland: UIView {

    public enum TimeOfDay {
        case day
        case night
    }

    public enum WeatherType: Int {
        case normal = 0
        case raining = 1
        case rainbow = 2
    }

    fileprivate var evan: Evan?
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var effectAudioPlayer: AVAudioPlayer?

    // View's snap behaviour
    fileprivate var animator: UIDynamicAnimator?
    fileprivate var snapBehaviour: UISnapBehavior!
    var previouslyAnimatedView: UIView? // View that had been panned previously
    var originalViewLocation: CGPoint?  // Location of view when view started panning.

    // Views attached to Wonderland
    fileprivate var toggleDayNightButton: UIButton!
    fileprivate var weatherBox: WeatherBox!
    fileprivate var volumeSlider: UISlider!
    fileprivate var tree: Tree!
    fileprivate var groundImageView: UIImageView!

    fileprivate var playButton: UIButton?
    fileprivate var tapEffectView: UIImageView?

    fileprivate var longTapGesture: UILongPressGestureRecognizer?

    /// View on top for raining weather.
    fileprivate var weatherLayerView: UIView?

    /// Background view that everything else is added to, except for evan and volume controls.
    fileprivate var backgroundView: UIView!

    // Public variables
    public var groundColor: UIColor = UIColor.brown {
        didSet {
            self.groundImageView?.tintColor = groundColor
        }
    }
    public var skyColor: UIColor = UIColor(red: 135/255, green: 206/255, blue: 250/255, alpha: 1) {
        didSet {
            self.backgroundView?.backgroundColor = skyColor
        }
    }
    /// Tells whether or not it is day or night. 
    /// Changing this variable effects the behaviour of certain elements of Wonderland, 
    /// such as bg music, tapGestures, and so on.
    public private (set) var timeOfDay: TimeOfDay = .day

    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 400))
        self.backgroundColor = UIColor.black

        self.backgroundView = UIView(frame: self.frame)
        self.backgroundView.clipsToBounds = true
        self.backgroundView.backgroundColor = skyColor
        self.addSubview(self.backgroundView)

        // Sets up bg image view
        let groundFrame = CGRect(x: 0, y: self.frame.height - 70,
                                 width: self.frame.width, height: 70)
        self.groundImageView = UIImageView(frame: groundFrame)
        self.groundImageView.contentMode = .scaleAspectFill
        self.groundImageView.image = UIImage(named: "ground")?.withRenderingMode(.alwaysTemplate)
        self.groundImageView.tintColor = self.groundColor
        self.backgroundView.addSubview((self.groundImageView))

        // Animator
        self.animator = UIDynamicAnimator(referenceView: self)

        // Tree
        self.tree = Tree()
        self.tree.frame.origin = CGPoint(x: self.frame.width - tree.frame.width - 30,
                                    y: self.frame.height - self.groundImageView.frame.height - tree.frame.height + 15)
        let treePanGesture = UIPanGestureRecognizer(target: self, action: #selector(Wonderland.stickyViewPanned(_:)))
        self.tree.addGestureRecognizer(treePanGesture)
        self.backgroundView.addSubview(self.tree)

        // Button to toggle day/night
        self.toggleDayNightButton = UIButton(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        self.toggleDayNightButton.setBackgroundImage(UIImage(named: "mode-day"), for: .normal)
        let dayNightPanGesture = UIPanGestureRecognizer(target: self, action: #selector(Wonderland.stickyViewPanned(_:)))
        self.toggleDayNightButton.addGestureRecognizer(dayNightPanGesture)
        self.toggleDayNightButton.addTarget(self, action: #selector(Wonderland.toggleDayNight(_:)), for: .touchUpInside)
        self.addSubview(self.toggleDayNightButton)

        // Setup volume controls on top right
        let volumeWidth: CGFloat = 200
        let volumeHeight: CGFloat = 50
        let sliderFrame = CGRect(x: self.frame.width - volumeWidth - 8, y: 8, width: volumeWidth, height: volumeHeight)
        self.volumeSlider = UISlider(frame: sliderFrame)
        self.volumeSlider.maximumValueImage = UIImage(named: "volume_high")
        self.volumeSlider.minimumValueImage = UIImage(named: "volume_mute")
        self.volumeSlider.setValue(0.5, animated: true)
        self.volumeSlider.addTarget(self, action: #selector(Wonderland.volumeChanged(_:)), for: .valueChanged)
        self.addSubview(self.volumeSlider) // Added to superview instead of backgroundView

        // Setup toolbox on the left of volume controls
        let weatherboxWidth = self.frame.width - self.volumeSlider.frame.width - self.toggleDayNightButton.frame.width - 56
        let weatherboxHeight = self.toggleDayNightButton.frame.height

        self.weatherBox = WeatherBox(image: UIImage(named: "toolbox"))
        self.weatherBox.delegate = self
        self.weatherBox.frame = CGRect(x: self.toggleDayNightButton.frame.width + 32,
                                    y: 10,
                                    width: weatherboxWidth, height: weatherboxHeight)
        self.addSubview(self.weatherBox)

        let normalWeatherView = UIImageView(image: UIImage(named: "weather-normal"))
        normalWeatherView.tag = WeatherType.normal.rawValue
        self.weatherBox.addItem(view: normalWeatherView)

        let rainingWeatherView = UIImageView(image: UIImage(named: "weather-rain"))
        rainingWeatherView.tag = WeatherType.raining.rawValue
        self.weatherBox.addItem(view: rainingWeatherView)

        let rainbowWeatherView = UIImageView(image: UIImage(named: "weather-rainbow"))
        rainbowWeatherView.tag = WeatherType.rainbow.rawValue
        self.weatherBox.addItem(view: rainbowWeatherView)

        // Setup tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Wonderland.tapped(_:)))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)

        // For flashlight use
        self.longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(Wonderland.longTapped(_:)))
        self.longTapGesture!.minimumPressDuration = 0.1
        self.addGestureRecognizer(self.longTapGesture!)

        // Default is day time
        self.toDayTime()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Gestures / user inputs
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        // Show default tap effect
        if let tapEffectView = self.tapEffectView {
            // View already exist, remove it.
            tapEffectView.removeFromSuperview()
            self.tapEffectView = nil
        }

        var frames: [UIImage] = []

        if self.timeOfDay == .day {
            frames = [
                UIImage(named: "pop-0")!.with(tint: .black),
                UIImage(named: "pop-1")!.with(tint: .black),
                UIImage(named: "pop-2")!.with(tint: .black),
                UIImage(named: "pop-3")!.with(tint: .black),
                UIImage(named: "pop-4")!.with(tint: .black)
            ]
        } else {
            frames = [
                UIImage(named: "pop-0")!.with(tint: .white),
                UIImage(named: "pop-1")!.with(tint: .white),
                UIImage(named: "pop-2")!.with(tint: .white),
                UIImage(named: "pop-3")!.with(tint: .white),
                UIImage(named: "pop-4")!.with(tint: .white)
            ]
        }

        let effectView = UIImageView(image: UIImage(named: "pop-5"))
        effectView.tintColor = tintColor
        effectView.animationImages = frames
        effectView.animationRepeatCount = 1
        effectView.animationDuration = 0.2
        effectView.center = sender.location(in: self)

        self.addSubview(effectView)
        effectView.startAnimating()
        self.tapEffectView = effectView

        // Play sound
        if self.effectAudioPlayer == nil {
            if let soundFileURL = Bundle.main.url(forResource: "tap-sound", withExtension: "mp3") {
                do {
                    self.effectAudioPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
                    self.effectAudioPlayer?.prepareToPlay()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        self.effectAudioPlayer?.play()
    }

    /// Show torch light
    @objc func longTapped(_ sender: UILongPressGestureRecognizer) {
        if self.timeOfDay != .night { return } // Gesture only works at night

        let location = sender.location(in: self.backgroundView)

        let maskImage = UIImage(named: "lightbeam")
        let mask = CALayer()
        mask.contents = maskImage?.cgImage
        mask.contentsGravity  = CALayerContentsGravity.resizeAspect
        mask.bounds = CGRect(x: 0, y: 0, width: 500, height: 230)
        mask.anchorPoint = CGPoint(x: 1, y: 0.5)

        let targetAnchor = CGPoint(x: 100, y: self.backgroundView.center.y + 50)
        mask.position = targetAnchor

        let target = backgroundView.center
        let angle = atan2(target.y - location.y, target.x - location.x)
        mask.transform = CATransform3DMakeRotation(angle, 0, 0, 1)

        switch sender.state {
        case .began:
            for darkview in self.backgroundView.subviews where darkview.restorationIdentifier == DarkViewIdentifier {
                darkview.alpha = 0
            }
            self.backgroundView.layer.mask = mask
        case .changed:
            self.backgroundView.layer.mask = mask
        default:
            for darkview in self.backgroundView.subviews where darkview.restorationIdentifier == DarkViewIdentifier {
                darkview.alpha = 1
                self.backgroundView.layer.mask = nil
            }
        }
    }

    @objc func volumeChanged(_ sender: UISlider) {
        self.audioPlayer?.volume = sender.value
    }

    @objc func stickyViewPanned(_ sender: UIPanGestureRecognizer) {
        self.animator?.removeAllBehaviors()
        if let view = sender.view {
            if sender.state == .began {
                // If the previous animated view is the same as this one, 
                // resets view position (in case view is still animating.)
                // Prevents spamming the same view
                if previouslyAnimatedView == view {
                    view.center = originalViewLocation ?? view.center
                }
                originalViewLocation = view.center
            }
            if sender.state == .changed {
                view.center = sender.location(in: self)

            }
            if sender.state == .ended {
                let snapBehaviour = UISnapBehavior(item: view, snapTo: originalViewLocation!)
                snapBehaviour.damping = 1

                // Store reference of the view that had just been animated.
                previouslyAnimatedView = view
                self.animator?.addBehavior(snapBehaviour)
            }
        }
    }

    @objc func toggleDayNight(_ sender: UIButton) {
        switch self.timeOfDay {
        case .day:
            self.toNightTime()
        case .night:
            self.toDayTime()
        }
    }

    @objc func play(_ sender: UIButton?) {
        self.hidePlayButton()

        // Disables interaction with Evan when story starts.
        self.evan?.isUserInteractionEnabled = false

        let duration: Double = 5
        self.evan?.walk(seconds: duration)
        self.toNightTime(animated: true, animationDuration: duration)

        // Re-anables interaction once finished animation to night time.
        Utils.delay(duration) { [weak self] in
            self?.evan?.isUserInteractionEnabled = true
            // Introduce the torch light used to light up the area.
        }
    }

    // MARK: - Func
    public func showEvan() -> Evan {
        if let evan = self.evan {
            return evan
        } else {
            self.evan = Evan()
            self.evan?.delegate = self
            self.addSubview(self.evan!)

            // Reposition evan
            let originX = CGFloat(20)
            let originY = self.frame.height - self.evan!.frame.height
            self.evan!.frame.origin = CGPoint(x: originX, y: originY)
            return self.evan!
        }
    }

    /// Play bg music continuously. 
    /// (Volume can be controlled with volume slider
    func playMusic(url: URL) {
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.volume = self.volumeSlider.value
            self.audioPlayer?.numberOfLoops = -1

            if self.audioPlayer?.prepareToPlay() == true {
                self.audioPlayer?.play()
            }
        } catch {
            print("\(error.localizedDescription)")
        }
    }

    // MARK: - Animations
    public func showPlayButton(animated: Bool = true) {
        let width: CGFloat = 80
        let height: CGFloat = 80
        let buttonFrame = CGRect(x: self.frame.width - width - 8,
                                 y: self.frame.height - height - 8,
                                 width: width, height: height)
        self.playButton = UIButton(frame: buttonFrame)
        self.playButton!.setBackgroundImage(UIImage(named: "play"), for: UIControl.State.normal)
        self.playButton!.alpha = 0
        self.playButton!.addTarget(self, action: #selector(Wonderland.play(_:)), for: .touchUpInside)
        self.addSubview(self.playButton!)

        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: { 
                self.playButton?.alpha = 1
            }, completion: nil)
        } else {
            self.playButton?.alpha = 0
        }
    }

    private func hidePlayButton(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.playButton?.alpha = 0
            }, completion: nil)
        } else {
            self.playButton?.alpha = 0
        }
    }

    private let DarkViewIdentifier = "DarkView"
    public func toNightTime(animated: Bool = true, animationDuration duration: Double = 3) {
        for darkView in self.backgroundView.subviews where darkView.restorationIdentifier == DarkViewIdentifier {
            darkView.removeFromSuperview()
        }

        // Alpha value. 1 Being completely dark, 0 being completely bright (Day time)
        let nightTimeDarkness: CGFloat = 1

        let darkView = UIView(frame: self.backgroundView.frame)
        darkView.backgroundColor = UIColor.black
        darkView.alpha = 0
        darkView.restorationIdentifier = DarkViewIdentifier

        self.backgroundView.addSubview(darkView)

        if animated {
            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { 
                darkView.alpha = nightTimeDarkness
            }, completion: { success in
            })
        } else {
            darkView.alpha = nightTimeDarkness
        }

        if let soundFileURL = Bundle.main.url(forResource: "night", withExtension: "mp3") {
            self.playMusic(url: soundFileURL)
        }

        self.timeOfDay = .night
        self.weatherBox.image = UIImage(named: "toolbox-white")

        self.longTapGesture?.isEnabled = true // Only enabled at night.
        self.toggleDayNightButton?.setBackgroundImage(UIImage(named: "mode-dark"), for: .normal)
    }

    public func toDayTime(animated: Bool = true, animationDuration duration: Double = 3) {
        for darkView in self.backgroundView.subviews where darkView.restorationIdentifier == DarkViewIdentifier {
            if animated {
                UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                    darkView.alpha = 0
                }, completion: { success in
                    darkView.removeFromSuperview()
                })
            } else {
                darkView.removeFromSuperview()
            }
        }

        if let soundFileURL = Bundle.main.url(forResource: "day", withExtension: "mp3") {
            self.playMusic(url: soundFileURL)
        }

        self.timeOfDay = .day
        self.weatherBox.image = UIImage(named: "toolbox")

        self.longTapGesture?.isEnabled = false // Only enabled at night.
        self.toggleDayNightButton?.setBackgroundImage(UIImage(named: "mode-day"), for: .normal)
    }
}

extension Wonderland: EvanProtocol {

    internal func evanWalkingSpeedChanged(walkingSpeed: Evan.WalkingSpeed) {
        // Move background props accordingly
        let animatableBgViews: [UIView] = [
            self.tree
        ]

        // Stops previous animation
        self.stopBackgroundViews(animatableBgViews)

        // Speed in meters per second.
        var speed: Double = 0
        switch walkingSpeed {
        case .notWalking:
            return
        case .walking:
            speed = Double(self.frame.width) / 2 // (Takes tree aprox 2 seconds to completed the frame's width)
        case .speedWalking:
            speed = Double(self.frame.width) / 1
        }

        self.movesBackgroundViews(animatableBgViews, withSpeed: speed)
    }

    /// Moves background object when Evan is walking.
    /// Speed should be a double indicating meters per second.
    /// If object travels 100m/s, speed is 100
    private func movesBackgroundViews(_ views: [UIView], withSpeed speed: Double) {
        for view in views {
            // Leftover distance needs to be travelled by tree
            let leftoverDistance = view.frame.origin.x + view.frame.width
            let duration = Double(leftoverDistance) / speed

            // Animate tree view offscreen to the left
            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                view.frame.origin.x = self.frame.origin.x - view.frame.width
            }) { [weak self] success in
                // On completion resets tree position and begin again
                if success {
                    view.frame.origin.x = self?.frame.width ?? 0
                    self?.movesBackgroundViews(views, withSpeed: speed)
                }
            }
        }
    }

    private func stopBackgroundViews(_ views: [UIView]) {
        for view in views {
            if let viewFrame = view.layer.presentation()?.frame {
                view.frame = viewFrame
            }
            view.layer.removeAllAnimations()
        }
    }
}

// Weather
extension Wonderland: WeatherBoxDelegate {

    func didSelect(_ view: UIView) {
        if let weatherType = WeatherType(rawValue: view.tag) {
            self.weatherLayerView?.removeFromSuperview()
            self.weatherLayerView = nil

            // Soundtrack based on weather.
            var soundFileURL: URL?
            switch self.timeOfDay {
            case .day:
                soundFileURL = Bundle.main.url(forResource: "day", withExtension: "mp3")
            case .night:
                soundFileURL = Bundle.main.url(forResource: "night", withExtension: "mp3")
            }

            switch weatherType {
            case .normal:
                break
            case .raining:
                let rainingView = UIImageView(image: UIImage.animatedImageNamed("rain-", duration: 0.3))
                self.weatherLayerView = rainingView
                self.addSubview(rainingView)
                soundFileURL = Bundle.main.url(forResource: "rain", withExtension: "mp3")
            case .rainbow:
                let rainbowView = UIView(frame: self.frame)
                rainbowView.isUserInteractionEnabled = false
                rainbowView.alpha = 0.3

                let gradient = CAGradientLayer()
                gradient.frame = rainbowView.bounds
                gradient.colors = [UIColor.red.cgColor, UIColor.orange.cgColor,
                                   UIColor.yellow.cgColor, UIColor.green.cgColor, UIColor.blue.cgColor,
                                   UIColor(red: 75/255, green: 0, blue: 130/255, alpha: 1).cgColor,
                                   UIColor.purple.cgColor]
                gradient.startPoint = CGPoint.zero
                gradient.endPoint = CGPoint(x: 1, y: 1)
                rainbowView.layer.insertSublayer(gradient, at: 0)

                self.weatherLayerView = rainbowView
                self.addSubview(rainbowView)
                soundFileURL = Bundle.main.url(forResource: "rainbow", withExtension: "mp3")
            }

            // Play appropriate music.
            if let url = soundFileURL { self.playMusic(url: url) }
        }
    }

}

extension Wonderland: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}







