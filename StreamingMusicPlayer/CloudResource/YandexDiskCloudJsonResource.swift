import Foundation
import RxSwift
import RxHttpClient
import JASON

public enum YandexDiskError : ErrorType {
	case tooManyRequests
	case unknown(title: String)
}

public class YandexDiskCloudJsonResource {
	public static func getRootResource(httpClient: HttpClientType = HttpClient(),
	                                   oauth: OAuthType) -> CloudResource {
		return YandexDiskCloudJsonResource(raw: JSON(["name": "disk", "path": "/"]), httpClient: httpClient, oauth: oauth)
	}
	
	public static let apiUrl = "https://cloud-api.yandex.net:443/v1/disk"
	public static let resourcesApiUrl = apiUrl + "/resources"
	public static let typeIdentifier = "YandexDiskCloudResource"
	public internal (set) var httpClient: HttpClientType
	public let oAuthResource: OAuthType
	public var raw: JSON
	
	public var rootUrl: String = {
		return YandexDiskCloudJsonResource.apiUrl
	}()
	
	public var resourcesUrl: String = {
		return YandexDiskCloudAudioJsonResource.resourcesApiUrl
	}()
	
	init (raw: JSON, httpClient: HttpClientType, oauth: OAuthType) {
		self.raw = raw
		//self.parent = parent
		self.oAuthResource = oauth
		self.httpClient = httpClient
	}
	
	internal func createRequest() -> NSURLRequestType? {
		guard oAuthResource.accessToken != nil else { return nil }
		guard let url = NSURL(baseUrl: resourcesUrl, parameters: getRequestParameters()) else { return nil }
		return httpClient.createUrlRequest(url, headers: getRequestHeaders())
	}
}

extension YandexDiskCloudJsonResource : CloudResource {
	public var resourceTypeIdentifier: String {
		return YandexDiskCloudJsonResource.typeIdentifier
	}
	
	public var name: String {
		return raw["name"].stringValue
	}
	
	public var uid: String {
		return raw["path"].stringValue
	}
	
	public var type: CloudResourceType {
		switch (raw["type"].stringValue) {
		case "file": return .File
		case "dir": return .Folder
		default: return .Unknown
		}
	}
	
	public var mimeType: String? {
		return raw["mime_type"].string
	}
	
	public func getRequestHeaders() -> [String : String]? {
		return ["Authorization": oAuthResource.accessToken ?? ""]
	}
	
	public func getRequestParameters() -> [String : String]? {
		return ["path": uid]
	}
	
	public func loadChildResources() -> Observable<JSON> {
		guard let request = createRequest() else {
			return Observable.empty()
		}

		return httpClient.loadJsonData(request)
	}
		
	public func deserializeResponse(json: JSON) -> [CloudResource] {
		guard let items = json["_embedded"]["items"].array else {
			return [CloudResource]()
		}
		
		return items.map { item -> CloudResource in
			return wrapRawData(JSON(item))
		}
	}
	
	internal func checkError(response: JSON) -> YandexDiskError? {
		guard let errorTitle = response["error"].string else { return nil }
		
		switch errorTitle {
			case "TooManyRequestsError": return YandexDiskError.tooManyRequests
			default: return YandexDiskError.unknown(title: errorTitle)
		}
	}
	
	public func wrapRawData(json: JSON) -> CloudResource {
		if json["media_type"].stringValue == "audio" {
			return YandexDiskCloudAudioJsonResource(raw: json, httpClient: httpClient, oauth: oAuthResource)
		} else {
			return YandexDiskCloudJsonResource(raw: json, httpClient: httpClient, oauth: oAuthResource)
		}
	}
}