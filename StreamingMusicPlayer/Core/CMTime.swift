import Foundation
import AVFoundation

extension CMTime {
	var asString: String {
		guard let sec: Float64 = self.safeSeconds else { return "0: 00" }
		let minutes = Int(sec / 60)
		return String(format: "%02d: %02d", minutes, Int(sec) - minutes * 60)
	}
	
	var safeSeconds: Float64? {
		let sec = CMTimeGetSeconds(self)
		return isnan(sec) ? nil : sec
	}
}