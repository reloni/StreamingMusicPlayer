import Foundation
import RxSwift

internal class SettingsViewModel {
	init() { }
	
	internal var isYandexSetUp: Observable<Bool> {
		return Observable.create { observer in
			let oauth = YandexOAuth()
			
			observer.onNext(oauth.accessToken != nil)
			
			return OAuthAuthenticator.sharedInstance.processedAuthentications.filter {
				if oauth.oauthTypeId == $0.oauthTypeId {
					return true
				} else {
					return false
				}
			}.flatMap { return Observable.just($0.accessToken != nil) }.bindTo(observer)
		}
	}
	
	internal var isGoogleSetUp: Observable<Bool> {
		return Observable.create { observer in
			let oauth = GoogleOAuth()
			
			observer.onNext(oauth.accessToken != nil)
			
			return OAuthAuthenticator.sharedInstance.processedAuthentications.filter {
				if oauth.oauthTypeId == $0.oauthTypeId {
					return true
				} else {
					return false
				}
				}.flatMap { return Observable.just($0.accessToken != nil) }.bindTo(observer)
		}
	}
}