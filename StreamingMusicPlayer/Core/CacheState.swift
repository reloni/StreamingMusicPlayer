import Foundation
import UIKit
import RxStreamPlayer

extension CacheState {
	func getImage() -> UIImage {
		switch self {
		case .notExisted: return MainModel.sharedInstance.itemInCloudImage
		case .inPermanentStorage: return MainModel.sharedInstance.itemInPermanentStorageImage
		case .inTempStorage: return MainModel.sharedInstance.itemInTempStorageImage
		}
	}
}