import Foundation
import RxStreamPlayer
import RxSwift

extension YandexDiskCloudAudioJsonResource : StreamResourceIdentifier {
	public var streamResourceUid: String {
		return uid
	}
	
	public var streamResourceUrl: Observable<String> {
		return downloadUrl
	}
	
	public var streamResourceContentType: ContentType? {
		guard let mime = mimeType, type = ContentType(rawValue: mime) else { return nil }
		return type
	}
}