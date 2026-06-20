import UIKit

extension UIImage {
    /// VLM 入力用に長辺を `maxDimension` ピクセルに抑えてリサイズする。
    /// 既に小さい場合はそのまま返す。
    func resizedForVLM(maxDimension: CGFloat) -> UIImage {
        let pixelW = size.width * scale
        let pixelH = size.height * scale
        let longest = max(pixelW, pixelH)
        guard longest > maxDimension else { return self }
        let ratio = maxDimension / longest
        let targetSize = CGSize(width: pixelW * ratio, height: pixelH * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
