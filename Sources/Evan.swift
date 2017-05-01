import Foundation
import UIKit
import AVFoundation

protocol EvanProtocol: class {
    func evanWalkingSpeedChanged(walkingSpeed: Evan.WalkingSpeed)
}

public class Evan: UIView {
    public enum WalkingSpeed: Int {
        case notWalking = 0
        case walking = 1
        case speedWalking = 2
    }
    weak var delegate: EvanProtocol?

    private var evanImageView: UIImageView!
    private var isSitting: Bool = false

    public private (set) var walkingSpeed: WalkingSpeed = .notWalking {
        didSet {
            self.isSitting = false

            // Notify delegate that Evan's position changed.
            self.delegate?.evanWalkingSpeedChanged(walkingSpeed: walkingSpeed)
        }
    }
    private var effectAudioPlayer: AVAudioPlayer?

    public init() {
        // Width height exactly same dimension as image
        let frame: CGRect = CGRect(x: 0, y: 0, width: 210, height: 350)
        super.init(frame: frame)

        self.evanImageView = UIImageView(frame: frame)
        self.evanImageView.contentMode = .top
        self.addSubview(self.evanImageView)

        // Add Gestures
        let evanTappedGesture = UITapGestureRecognizer(target: self, action: #selector(Evan.evanTapped(_:)))

        let swipeLeftGesture =  UISwipeGestureRecognizer(target: self, action: #selector(Evan.swipedLeft(_:)))
        swipeLeftGesture.direction = .left

        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(Evan.swipedRight(_:)))
        swipeRightGesture.direction = .right

        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(Evan.swipedDown(_:)))
        swipeDownGesture.direction = .down

        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(Evan.swipedUp(_:)))
        swipeUpGesture.direction = .up

        self.addGestureRecognizer(evanTappedGesture)
        self.addGestureRecognizer(swipeLeftGesture)
        self.addGestureRecognizer(swipeRightGesture)
        self.addGestureRecognizer(swipeDownGesture)
        self.addGestureRecognizer(swipeUpGesture)

        self.stop()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Commands Evan to walk forward.
     - parameters:
        - seconds: 
            Number of seconds evan should walk for.
            Setting it to a value less than or equals to 0 makes Evan walks indefinitely.
            Default value is 0.
     */
    public func walk(seconds: Double = 0) {
        self.evanImageView.image = UIImage.animatedImageNamed("walk-", duration: 1)
        self.walkingSpeed = .walking

        if seconds > 0 {
            Utils.delay(seconds, execute: { [weak self] in
                self?.stop()
            })
        }
    }

    /**
     Commands Evan to walk forward faster.
     - parameters:
     - seconds:
     Number of seconds evan should walk for.
     Setting it to a value less than or equals to 0 makes Evan walks indefinitely.
     Default value is 0.
     */
    public func speedWalk(seconds: Double = 0) {
        self.evanImageView.image = UIImage.animatedImageNamed("walk-", duration: 0.6)
        self.walkingSpeed = .speedWalking

        if seconds > 0 {
            Utils.delay(seconds, execute: { [weak self] in
                self?.stop()
            })
        }
    }

    /// Returns Evan to default behaviour.
    public func stop() {
        self.startsFeetTappingBehaviour()
        self.walkingSpeed = .notWalking
    }

    /// Makes evan sit down.
    public func sit() {
        // Unable to sit if evan is walking
        if self.walkingSpeed != .notWalking { return }

        self.isUserInteractionEnabled = false
        let frames = [
            UIImage(named: "jump-0")!,
            UIImage(named: "jump-1")!,
            UIImage(named: "jump-2")!,
            UIImage(named: "jump-3")!,
            UIImage(named: "jump-4")!,
            UIImage(named: "jump-5")!,
            UIImage(named: "jump-6")!
        ]
        let animationDuration = 0.5

        self.evanImageView.image = frames.last
        self.evanImageView.animationImages = frames
        self.evanImageView.animationDuration = animationDuration
        self.evanImageView.animationRepeatCount = 1
        self.evanImageView.startAnimating()

        Utils.delay(animationDuration) {
            self.isUserInteractionEnabled = true
            self.evanImageView.animationImages = nil
            self.startsSittingBehaviour()
        }
        self.isSitting = true
    }

    private func startsFeetTappingBehaviour() {
        // Feet tapping behaviour
        let frames = [
            UIImage(named: "tap-0")!,
            UIImage(named: "tap-1")!,
            UIImage(named: "tap-2")!,
            UIImage(named: "tap-0")!,
            UIImage(named: "tap-0")!,
            UIImage(named: "tap-0")!,
            UIImage(named: "tap-0")!,
            UIImage(named: "tap-0")!
        ]
        self.evanImageView.image = UIImage.animatedImage(with: frames, duration: 1)
    }

    private func startsSittingBehaviour() {
        let frames = [
            UIImage(named: "sit-0")!,
            UIImage(named: "sit-1")!,
            UIImage(named: "sit-2")!,
            UIImage(named: "sit-0")!,
            UIImage(named: "sit-0")!,
            UIImage(named: "sit-0")!,
            UIImage(named: "sit-0")!,
            UIImage(named: "sit-0")!
        ]
        self.evanImageView.image = UIImage.animatedImage(with: frames, duration: 1)
    }

    // MARK: - Gestures
    private var previousWalkingSpeed: WalkingSpeed?
    func evanTapped(_ sender: UILongPressGestureRecognizer) {
        // Store reference of the original image
        previousWalkingSpeed = self.walkingSpeed

        // Disable interaction until process is finished.
        self.isUserInteractionEnabled = false

        // Stop evan, change image, and play "ouch" sound
        self.stop()
        self.evanImageView.image = UIImage(named: "poke-0")
        if let ouchURL = Bundle.main.url(forResource: "ouch", withExtension: "mp3") {
            self.playSoundEffect(fromUrl: ouchURL)
        }
        // Adds short delay, and then returns to previous walking
        Utils.delay(0.1, execute: { [weak self] in
            self?.isUserInteractionEnabled = true

            if let previousWalkingSpeed = self?.previousWalkingSpeed {
                switch previousWalkingSpeed {
                case .notWalking:
                    self?.stop()
                case .walking:
                    self?.walk()
                case .speedWalking:
                    self?.speedWalk()
                }
            }
            self?.previousWalkingSpeed = nil
        })
    }

    /// Slows down Evan
    func swipedLeft(_ sender: UISwipeGestureRecognizer) {
        switch self.walkingSpeed {
        case .speedWalking:
            self.walk()
        case .walking:
            self.stop()
        case .notWalking:
            return
        }
    }

    /// Speeds up Evan
    func swipedRight(_ sender: UISwipeGestureRecognizer) {
        switch self.walkingSpeed {
        case .notWalking:
            self.walk()
        case .walking:
            self.speedWalk()
        case .speedWalking:
            return
        }
    }

    /// Makes evan sit on the ground
    func swipedDown(_ sender: UISwipeGestureRecognizer) {
        if self.walkingSpeed == .notWalking {
            self.sit()
        }
    }

    /// Returns to standing position if Evan is sitting.
    func swipedUp(_ sender: UISwipeGestureRecognizer) {
        if self.isSitting {
            self.stop()
        }
    }

    // MARK: - Utilities
    private func playSoundEffect(fromUrl url: URL) {
        // If audio player is already loaded with the sound url, play again
        if url == self.effectAudioPlayer?.url {
            self.effectAudioPlayer?.play()
        } else {
            do {
                self.effectAudioPlayer = try AVAudioPlayer(contentsOf: url)
                if self.effectAudioPlayer?.prepareToPlay() == true {
                    self.effectAudioPlayer?.play()
                }
            } catch {
                print("\(error.localizedDescription)")
            }
        }
    }
}

extension Evan: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}




