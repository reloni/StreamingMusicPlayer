import Foundation
import RxSwift
import RxHttpClient
import JASON

public enum CloudResourceLoadMode {
	case CacheAndRemote
	case CacheOnly
	case RemoteOnly
}

public enum CloudResourceType {
	case Folder
	case File
	case Unknown
}

public protocol CloudResource {
	var resourceTypeIdentifier: String { get }
	var raw: JSON { get }
	var oAuthResource: OAuthType { get }
	var uid: String { get }
	var name: String { get }
	var type: CloudResourceType { get }
	var mimeType: String? { get }
	var rootUrl: String { get }
	var resourcesUrl: String { get }
	func getRequestHeaders() -> [String: String]?
	func getRequestParameters() -> [String: String]?
	func loadChildResources() -> Observable<JSON>
	func deserializeResponse(json: JSON) -> [CloudResource]
	func wrapRawData(json: JSON) -> CloudResource
}

public protocol CloudAudioResource : CloudResource {
	var downloadUrl: Observable<String> { get }
}
