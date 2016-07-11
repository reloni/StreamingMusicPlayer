import Foundation

class CloudAccountsModel {
	let allAccounts: [(oauth: OAuthType, root: CloudResource)]
	
	init() {
		allAccounts = [(oauth: YandexOAuth(), root: YandexDiskCloudJsonResource.getRootResource(oauth: YandexOAuth()))]
	}
	
	var loggedAccounts: [(oauth: OAuthType, root: CloudResource)] {
		return allAccounts.filter { $0.oauth.accessToken != nil }
	}
	
	var notLoggedAccounts: [(oauth: OAuthType, root: CloudResource)] {
		return allAccounts.filter { $0.oauth.accessToken == nil }
	}
}