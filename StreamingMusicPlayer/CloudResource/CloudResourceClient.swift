import Foundation
import RxSwift
import RxHttpClient

public protocol CloudResourceClientType {
	var cacheProvider: CloudResourceCacheProviderType? { get }
	func loadChildResources(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]>
	func loadChildResourcesRecursive(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]>
}

public class CloudResourceClient {
	public internal(set) var cacheProvider: CloudResourceCacheProviderType?
	init(cacheProvider: CloudResourceCacheProviderType? = nil) {
		self.cacheProvider = cacheProvider
	}
	
	internal func internalLoadChildResourcesRecursive(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<CloudResource> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let serialScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.Utility)
			
			let disposable = object.loadChildResources(resource, loadMode: loadMode).observeOn(serialScheduler)
				.catchError { observer.onError($0); return Observable.empty() }
				/*.flatMap { result -> Observable<CloudResource> in
				if case Result.success(let box) = result {
					return box.value.toObservable()
				} else if case Result.error(let error) = result {
					observer.onNext(Result.error(error))
					observer.onCompleted()
					return Observable.empty()
				} else {
					observer.onCompleted()
					return Observable.empty()
				}
				}*/
				.flatMap { result -> Observable<CloudResource> in
					return result.toObservable()
				}
				.flatMap { e -> Observable<CloudResource> in
					return [e].toObservable().concat(object.internalLoadChildResourcesRecursive(e, loadMode: loadMode).observeOn(serialScheduler))
				}.bindTo(observer)
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
}

extension CloudResourceClient : CloudResourceClientType {
	public func loadChildResources(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]> {
		return Observable.create { [weak self] observer in
			// check cached data
			if loadMode == .CacheAndRemote || loadMode == .CacheOnly {
				if let cachedData = self?.cacheProvider?.getCachedChilds(resource) where cachedData.count > 0 {
					observer.onNext(cachedData)
				}
			}
			
			var remoteDisposable: Disposable?
			if loadMode == .CacheAndRemote || loadMode == .RemoteOnly {
				remoteDisposable = resource.loadChildResources().catchError { error in
					observer.onError(error)
					return Observable.empty()
					}.flatMapLatest { result -> Observable<CloudResource> in
							return resource.deserializeResponse(result).toObservable()
					}.toArray().doOnCompleted { observer.onCompleted() }.bindNext {
						self?.cacheProvider?.cacheChilds(resource, childs: $0)
						observer.onNext($0)
				}
			} else { observer.onCompleted() }
			
			return AnonymousDisposable {
				remoteDisposable?.dispose()
			}
		}
	}
	
	public func loadChildResourcesRecursive(resource: CloudResource, loadMode: CloudResourceLoadMode) -> Observable<[CloudResource]> {
		return Observable.create { [weak self] observer in
			guard let object = self else { observer.onCompleted(); return NopDisposable.instance }
			
			let disposable = object.internalLoadChildResourcesRecursive(resource, loadMode: loadMode)
				.catchError { observer.onError($0); return Observable.empty() }
				/*.flatMap { result -> Observable<CloudResource> in
				if case Result.success(let box) = result {
					return Observable.just(box.value)
				} else if case Result.error(let error) = result {
					observer.onNext(Result.error(error))
					observer.onCompleted()
					return Observable.empty()
				} else {
					observer.onCompleted()
					return Observable.empty()
				}
				}*/
					.toArray().bindNext { result in
					observer.onNext(result)
					observer.onCompleted()
			}
			
			return AnonymousDisposable {
				disposable.dispose()
			}
		}
	}
}