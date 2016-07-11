import Foundation
import RxStreamPlayer
import JASON

class CloudResourceLoader {
	internal let cacheProvider: CloudResourceCacheProviderType
	internal let rootCloudResources: [String: CloudResource]
	init(cacheProvider: CloudResourceCacheProviderType, rootCloudResources: [String: CloudResource]) {
		self.cacheProvider = cacheProvider
		self.rootCloudResources = rootCloudResources
	}
}

extension CloudResourceLoader : StreamResourceLoaderType {
	func loadStreamResourceByUid(uid: String) -> StreamResourceIdentifier? {
		guard let rawData = cacheProvider.getRawCachedResource(uid) else { return nil }//, resource = rootCloudResources[rawData.resourceTypeIdentifier] else { return nil }
		
		guard let resource = rootCloudResources[rawData.resourceTypeIdentifier] else { return nil }
		
		return resource.wrapRawData(JSON(rawData.rawData)) as? StreamResourceIdentifier
	}
}