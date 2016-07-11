import Foundation
import RxSwift

class CloudResourcesViewModel {
	var resources: [CloudResource]?
	var parent: CloudResource?
	let bag = DisposeBag()
}