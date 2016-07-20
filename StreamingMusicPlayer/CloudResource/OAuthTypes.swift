import Foundation
import RxSwift
import RxHttpClient
import RxHttpClientJasonExtension

struct YandexOAuth {
	static let id = "YandexOAuthResource"
	let clientId: String
	let baseAuthUrl: String
	let urlScheme: String
	let urlParameters: [String: String]
	let keychain: KeychainType
	let authenticator: OAuthAuthenticatorType
	
	internal var tokenKeychainId: String {
		return "\(YandexOAuth.id)_accessToken"
	}
	
	internal var refreshTokenKeychainId: String {
		return "\(YandexOAuth.id)_refreshToken"
	}
	
	init(baseAuthUrl: String, urlParameters: [String: String], urlScheme: String, clientId: String, keychain: KeychainType,
	            authenticator: OAuthAuthenticatorType) {
		self.baseAuthUrl = baseAuthUrl
		self.urlParameters = urlParameters
		self.urlScheme = urlScheme
		self.clientId = clientId
		self.keychain = keychain
		self.authenticator = authenticator
	}
	
	init(clientId: String, urlScheme: String, keychain: KeychainType, authenticator: OAuthAuthenticatorType = OAuthAuthenticator.sharedInstance) {
		self.init(baseAuthUrl: "https://oauth.yandex.ru/authorize", urlParameters: ["response_type": "token"],
		          urlScheme: urlScheme, clientId:  clientId, keychain: keychain, authenticator: authenticator)
	}
}

extension YandexOAuth : OAuthType {
	var resourceDescription: String {
		return "Yandex Disk"
	}
	
	var oauthTypeId: String {
		return "\(YandexOAuth.id)_\(clientId)"
	}
	
	var authUrl: NSURL? {
		var params = urlParameters
		params["client_id"] = clientId
		return NSURL(baseUrl: baseAuthUrl, parameters: params)
	}
	
	var accessToken: String? {
		return keychain.stringForAccount(tokenKeychainId)
	}
	
	var refreshToken: String? {
		return keychain.stringForAccount(refreshTokenKeychainId)
	}
	
	func canParseCallbackUrl(url: String) -> Bool {
		if let schemeEnding = url.rangeOfString(":")?.first {
			return url.substringToIndex(schemeEnding) == urlScheme
		}
		return false
	}
	
	func authenticate(url: String) -> Observable<OAuthType> {
		return Observable.create { observer in
			if let start = url.rangeOfString("access_token=")?.endIndex {
				let substring = url.substringFromIndex(start)
				let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
				
				self.keychain.setString(substring.substringWithRange(substring.startIndex..<end), forAccount: self.tokenKeychainId, synchronizable: true, background: false)
				observer.onNext(self)
			}
			
			observer.onCompleted()
			
			return NopDisposable.instance
		}
	}
	
	func updateToken() -> Observable<OAuthType> {
		return Observable.empty()
	}
	
	func clearTokens() {
		keychain.setString(nil, forAccount: tokenKeychainId, synchronizable: true, background: false)
		keychain.setString(nil, forAccount: refreshTokenKeychainId, synchronizable: true, background: false)
		authenticator.sendAuthenticatedObject(self)
	}
}

struct GoogleOAuth {
	static let id = "GoogleOAuthResource"
	let clientId: String
	let baseAuthUrl: String
	let urlScheme: String
	let urlParameters: [String: String]
	let redirectUri: String
	let scopes: [String]
	let tokenUrl: String
	let keychain: KeychainType
	let authenticator: OAuthAuthenticatorType
	let httpClient: HttpClientType
	
	internal var tokenKeychainId: String {
		return "\(GoogleOAuth.id)_accessToken"
	}
	
	internal var refreshTokenKeychainId: String {
		return "\(GoogleOAuth.id)_refreshToken"
	}
	
	init(baseAuthUrl: String,
	     urlParameters: [String: String],
	     urlScheme: String,
	     redirectUri: String,
	     scopes: [String],
	     tokenUrl: String,
	     clientId: String,
	     keychain: KeychainType,
	     authenticator: OAuthAuthenticatorType, httpClient: HttpClientType) {
		self.baseAuthUrl = baseAuthUrl
		self.urlParameters = urlParameters
		self.urlScheme = urlScheme
		self.redirectUri = redirectUri
		self.scopes = scopes
		self.clientId = clientId
		self.tokenUrl = tokenUrl
		self.keychain = keychain
		self.authenticator = authenticator
		self.httpClient = httpClient
	}
	
	init(clientId: String,
	     urlScheme: String,
	     redirectUri: String,
	     scopes: [String],
	     keychain: KeychainType,
	     authenticator: OAuthAuthenticatorType = OAuthAuthenticator.sharedInstance,
	     httpClient: HttpClientType = HttpClient(urlSession: NSURLSession.sharedSession())) {
		self.init(baseAuthUrl: "https://accounts.google.com/o/oauth2/v2/auth", urlParameters: ["response_type": "code"],
		          urlScheme: urlScheme, redirectUri: redirectUri, scopes: scopes, tokenUrl: "https://www.googleapis.com/oauth2/v4/token",
		          clientId:  clientId, keychain: keychain, authenticator: authenticator, httpClient: httpClient)
	}
}

extension GoogleOAuth : OAuthType {
	var resourceDescription: String {
		return "Google Drive"
	}
	
	var oauthTypeId: String {
		return "\(GoogleOAuth.id)_\(clientId)"
	}
	
	var authUrl: NSURL? {
		var params = urlParameters
		params["client_id"] = clientId
		params["redirect_uri"] = redirectUri
		params["scope"] = scopes.joinWithSeparator(" ")
		return NSURL(baseUrl: baseAuthUrl, parameters: params)
	}
	
	var accessToken: String? {
		return keychain.stringForAccount(tokenKeychainId)
	}
	
	var refreshToken: String? {
		return keychain.stringForAccount(refreshTokenKeychainId)
	}
	
	func canParseCallbackUrl(url: String) -> Bool {
		if let schemeEnding = url.rangeOfString(":")?.first {
			return url.substringToIndex(schemeEnding) == urlScheme
		}
		return false
	}
	
	func authenticate(url: String) -> Observable<OAuthType> {
		if let start = url.rangeOfString("code=")?.endIndex {
			let substring = url.substringFromIndex(start)
			let end = substring.rangeOfString("&")?.startIndex ?? substring.endIndex
			let code = substring.substringWithRange(substring.startIndex..<end)
			
			// perform second request in order to finally receive access token
			if let tokenUrl = NSURL(baseUrl: self.tokenUrl,
			                        parameters: ["code": code, "client_id": self.clientId, "redirect_uri": self.redirectUri, "grant_type": "authorization_code"]) {
				let request = httpClient.createUrlRequest(tokenUrl)
				request.setHttpMethod("POST")
				return httpClient.loadJsonData(request).flatMapLatest { result -> Observable<OAuthType> in
					guard case Result.success(let box) = result else { return Observable.empty() }
					let response = box.value
					if let accessToken = response["access_token"].string {
						self.keychain.setString(accessToken, forAccount: self.tokenKeychainId, synchronizable: true, background: false)
					}
					if let refreshToken = response["refresh_token"].string {
						self.keychain.setString(refreshToken, forAccount: self.refreshTokenKeychainId, synchronizable: true, background: false)
					}
					return Observable.just(self)
				}
			}
		}
		
		return Observable.empty()
	}
	
	func updateToken() -> Observable<OAuthType> {
		// SMP_Warning: implement refresh request for Google
		return Observable.empty()
	}
	
	func clearTokens() {
		keychain.setString(nil, forAccount: tokenKeychainId, synchronizable: true, background: false)
		keychain.setString(nil, forAccount: refreshTokenKeychainId, synchronizable: true, background: false)
		authenticator.sendAuthenticatedObject(self)
	}
}