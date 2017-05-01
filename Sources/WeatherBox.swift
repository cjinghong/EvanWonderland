import Foundation
import UIKit

protocol WeatherBoxDelegate: class {
    func didSelect(_ view: UIView)
}

public class WeatherBox: UIImageView {

    weak var delegate: WeatherBoxDelegate?

    private let itemSelectedColour = UIColor(red: 68/255, green: 108/255, blue: 179/255, alpha: 1)
    private let itemDeselectedColour = UIColor.white

    public override init(image: UIImage?) {
        super.init(image: image)
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleToFill
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Max 3 items
    public var items: [UIView] = [] {
        didSet {
            // only keep max of 3 items
            if items.count > 3 {
                items.removeSubrange(0...2)
            }
        }
    }

    /// Ask if an item can be removed.
    public var canAddItem: Bool {
        get {
            return items.count < 3
        }
    }

    // Frames for each item respectively.
    private func itemsFrames() -> [CGRect] {
        let height = self.frame.height - 16

        let frame1 = CGRect(x: 6, y: 7,
                            width: self.frame.width * 0.3, height: height)
        let frame2 = CGRect(x: frame1.origin.x + frame1.width + 6, y: frame1.origin.y,
                            width: self.frame.width * 0.266, height: height)
        let frame3 = CGRect(x: frame2.origin.x + frame2.width + 8, y: frame2.origin.y,
                            width: self.frame.width * 0.283, height: height)

        let frames = [
            frame1,
            frame2,
            frame3

        ]
        return frames
    }

    /// Adds a subview to Toolbox. The frame of the view given WILL be changed to 
    /// fit within the custom bounds of toolbox. Fits maximum of 3 items.
    public func addItem(view: UIView) {
        if self.canAddItem {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(WeatherBox.viewTapped(_:)))
            view.addGestureRecognizer(tapGesture)
            view.isUserInteractionEnabled = true

            self.items.append(view)
            self.items.last?.frame = self.itemsFrames()[self.items.count-1]
            self.addSubview(view)

            // First item always selected by default.
            self.setViewSelected(view: self.items.first!)
        }
    }

    private func setViewSelected(view: UIView) {
        // Deselect other views
        for item in self.items {
            if item != view {
                item.backgroundColor = self.itemDeselectedColour
            }
        }
        // Sets selected view bg color
        view.backgroundColor = self.itemSelectedColour
    }

    public func removeItem(atIndex index: Int) {
        self.items[index].removeFromSuperview()
        self.items.remove(at: index)
    }

    // MARK: - Gestures
    func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        // Trigger selection if view isnt already selected.
        if view.backgroundColor == self.itemDeselectedColour {
            self.setViewSelected(view: view)
            // Trigger the action
            self.delegate?.didSelect(view)
        }
    }

}



