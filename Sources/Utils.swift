import Foundation
import UIKit

public class Utils {
    public class func randomInt(lowerBound: Int, upperBound: Int) -> Int {
        let randInt: Int = Int(arc4random_uniform(UInt32(upperBound)) + UInt32(lowerBound))
        return randInt
    }

    public class func delay(_ seconds: Double, execute: @escaping (() -> Void)) {
        let millis: Int = Int(seconds * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millis)) {
            execute()
        }
    }
}

extension UIImage {
    func with(tint: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.setBlendMode(.normal)
            let rect = CGRect(origin: .zero, size: size)
            context.clip(to: rect, mask: self.cgImage!)
            tint.setFill()
            context.fill(rect)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
