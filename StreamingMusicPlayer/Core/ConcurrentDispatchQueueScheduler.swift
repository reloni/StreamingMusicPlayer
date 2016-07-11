import Foundation
import RxSwift

extension ConcurrentDispatchQueueScheduler {
	static var utility: ConcurrentDispatchQueueScheduler {
		return ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
	}
}