import Foundation

extension YandexOAuth {
	init() {
		self.init(clientId: "6556b9ed6fb146ea824d2e1f0d98f09b", urlScheme: "oauthyandex", keychain: Keychain())
	}
}

extension GoogleOAuth {
	init() {
		self.init(clientId: "904693090582-807d6m390ms26lis6opjfbrjnr0qns7k.apps.googleusercontent.com",
		          urlScheme: "com.antonefimenko.cloudmusicplayer",
		          redirectUri: "com.antonefimenko.cloudmusicplayer:/redirect.com", scopes: ["https://www.googleapis.com/auth/drive.readonly"], keychain: Keychain())
	}
}