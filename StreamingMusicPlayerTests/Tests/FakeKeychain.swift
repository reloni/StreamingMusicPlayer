import Foundation
@testable import StreamingMusicPlayer

public class FakeKeychain : KeychainType {
	public var keychain: [String: NSData]
	init(keychain: [String: NSData] = [:]) {
		self.keychain = keychain
	}
	
	public func deleteAccount(account: String) {
		keychain[account] = nil
	}
	
	public func stringForAccount(account: String) -> String? {
		if let data = keychain[account] {
			return String(data: data, encoding: NSUTF8StringEncoding)
		}
		return nil
	}
	
	public func setData(data: NSData, forAccount account: String, synchronizable: Bool, background: Bool) {
		keychain[account] = data
	}
	
	public func setString(string: String?, forAccount account: String, synchronizable: Bool, background: Bool) {
		keychain[account] = string?.dataUsingEncoding(NSUTF8StringEncoding) ?? nil
	}
	
	public func dataForAccount(account: String) -> NSData? {
		return keychain[account]
	}
}