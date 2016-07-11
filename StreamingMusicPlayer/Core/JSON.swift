import Foundation
import JASON

extension JSON {
	func safeRawData() -> NSData? {
		guard let object = object else { return nil }
		return try? NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(rawValue: 0))
	}
}