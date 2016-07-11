import Foundation

extension Float {
	var asTimeString: String {
		let minutes = Int(self / 60)
		return String(format: "%02d: %02d", minutes, Int(self) - minutes * 60)
	}
}