import Foundation
import UIKit
import AVFoundation

open class Tree: UIView {

    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var treeImageView: UIImageView!

    public init() {
        self.treeImageView = UIImageView(image: UIImage(named: "tree"))
        self.treeImageView.contentMode = .bottomRight
        super.init(frame: self.treeImageView.frame)
        self.addSubview(self.treeImageView)

        // Gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Tree.tapped(_:)))
        self.addGestureRecognizer(tapGesture)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tapped(_ sender: UITapGestureRecognizer) {
        // Init audioPlayer (if applicable) and then play.
        if self.audioPlayer == nil {
            if let soundFileURL = Bundle.main.url(forResource: "leaf", withExtension: "mp3") {
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
                    self.audioPlayer?.prepareToPlay()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        self.audioPlayer?.play()

        // Random animation.
        self.randomTreeBehaviour()
    }

    func randomTreeBehaviour() {
        // Randomize
        var frames: [UIImage] = []
        let randInt = Utils.randomInt(lowerBound: 0, upperBound: 2)
        if randInt == 0 {
            frames = self.creepFrames()
        } else {
            frames = self.snakeFrames()
        }

        self.treeImageView.animationImages = frames

        // Random duration. Between 0.5 to 1 seconds
        let duration = Utils.randomInt(lowerBound: 5, upperBound: 9)
        self.treeImageView.animationDuration = Double(duration / 10)

        self.treeImageView.animationRepeatCount = 1
        self.treeImageView.startAnimating()
    }

    private func creepFrames() -> [UIImage] {
        let frame0 = UIImage(named: "tree-creep-0")!
        let frame1 = UIImage(named: "tree-creep-1")!
        let frame2 = UIImage(named: "tree-creep-2")!

        let frames = [
            frame0,
            frame1, frame1,
            frame2, frame2,
            frame0
        ]
        return frames
    }

    private func snakeFrames() -> [UIImage] {
        let frame0 = UIImage(named: "tree-snake-0")!
        let frame1 = UIImage(named: "tree-snake-1")!
        let frame2 = UIImage(named: "tree-snake-2")!
        let frame3 = UIImage(named: "tree-snake-3")!
        let frame4 = UIImage(named: "tree-snake-4")!
        let frame5 = UIImage(named: "tree-snake-5")!
        let frame6 = UIImage(named: "tree-snake-6")!

        let frames = [
            frame0,
            frame1, frame2, frame3, frame4,
            frame5, frame6, frame5,
            frame4, frame3, frame2, frame1,
            frame0
        ]
        return frames
    }

}




