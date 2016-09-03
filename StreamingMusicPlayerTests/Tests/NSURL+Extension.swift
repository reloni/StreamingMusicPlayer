import Foundation

extension NSURL {
	public func isEqualsToUrl(url: NSURL) -> Bool {
		if let params1 = query, params2 = url.query {
			let par1 = params1.characters.split { $0 == "&" }.map(String.init)
			let par2 = params2.characters.split { $0 == "&" }.map(String.init)
			if par1.sort() == par2.sort() {
				return absoluteString.stringByReplacingOccurrencesOfString(params1, withString: "") ==
					url.absoluteString.stringByReplacingOccurrencesOfString(params2, withString: "")
			} else {
				return false
			}
		}
		return self == url
	}
}