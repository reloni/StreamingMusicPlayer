import XCTest
import JASON
@testable import StreamingMusicPlayer
import RxSwift
import Realm
import RealmSwift
@testable import RxHttpClient
import OHHTTPStubs

class CloudResourceClientYandexTests: XCTestCase {
	
	var bag: DisposeBag!
	var oauthResource: OAuthType!
	var httpClient: HttpClientType!
	var rootResource: CloudResource!
	let authKey = "fake_auth_key"
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
		
		bag = DisposeBag()
		httpClient = HttpClient()
		oauthResource = YandexOAuth(clientId: "fakeClientId", urlScheme: "fakeOauthResource", keychain: FakeKeychain(), authenticator: OAuthAuthenticator())
		(oauthResource as! YandexOAuth).keychain.setString(authKey, forAccount: (oauthResource as! YandexOAuth).tokenKeychainId, synchronizable: false, background: false)
		rootResource = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
	}
	
	func testLoadRootData() {
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=/" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let json = JSON.getJsonFromFile("YandexRoot")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		
		let expectation = expectationWithDescription("Should return correct json data from YandexRoot file")

		let client = CloudResourceClient()
		
		//YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?.bindNext { result in
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).bindNext { result in
			if result.count == 9 {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	
	func testErrorWhileLoadRootData() {
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=/" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			return OHHTTPStubsResponse(error: NSError(domain: "TestDomain", code: 1, userInfo: nil))
		}
		
		let expectation = expectationWithDescription("Should return error")
		
		let client = CloudResourceClient()
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).doOnError { e in
			guard case HttpClientError.ClientSideError(let error) = e else { return }
			if error.code == 1 {
				expectation.fulfill()
			}
			}.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testTerminateWhileLoadRootData() {
		let expectation = expectationWithDescription("Should cancel task")
		
		let fakeSession = FakeSession()
		fakeSession.task = FakeDataTask(resumeClosure: {
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
				for _ in 0...10 {
					sleep(1)
				}
			}
		}, cancelClosure: { expectation.fulfill() })
		
		let fakeClient = HttpClient(session: fakeSession)
		let fakeResource = YandexDiskCloudJsonResource.getRootResource(fakeClient, oauth: oauthResource)
		
		let client = CloudResourceClient()
		//let request = YandexDiskCloudJsonResource.loadRootResources(oauthResource, httpRequest: httpClient)?
		let request = client.loadChildResources(fakeResource, loadMode: .CacheAndRemote)
			.bindNext { _ in
		}
		request.dispose()
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testLoadChilds() {
		let expectation = expectationWithDescription("Should return childs")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource)
		
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=disk:/Music" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let json = JSON.getJsonFromFile("YandexMusicFolderContents")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		var loadedChilds: [CloudResource]?
		
		let cliet = CloudResourceClient()
		cliet.loadChildResources(item, loadMode: .CacheAndRemote).bindNext { result in
			loadedChilds = result
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertNotNil(loadedChilds)
		XCTAssertEqual(4, loadedChilds?.count)
		
		let first = loadedChilds?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.uid, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(item.uid, first?.parent?.uid)
		
		let audioItem = loadedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(item.uid, audioItem?.parent?.uid)
	}

	func testReceiveErrorWhileLoadingChilds() {
		let expectation = expectationWithDescription("Should receive error")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			XCTFail("Fail to load json from file")
			return
		}
		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource)
		
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=disk:/Music" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			return OHHTTPStubsResponse(error: NSError(domain: "TestDomain", code: 1, userInfo: nil))
		}
		
		let client = CloudResourceClient()
		client.loadChildResources(item, loadMode: .CacheAndRemote).doOnError { e in
			guard case HttpClientError.ClientSideError(let error) = e else { return }
			XCTAssertEqual(error.code, 1)
			expectation.fulfill()
			}.subscribe().addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testGetDownloadUrl() {
		let expectation = expectationWithDescription("Should return download url")
		
		guard let audioItem = JSON.getJsonFromFile("YandexAudioItem"),
			sendJson = JSON.getJsonFromFile("YandexAudioDownloadResponse"), href = sendJson["href"].string else {
				waitForExpectationsWithTimeout(1, handler: nil)
				return
		}
		let item = YandexDiskCloudAudioJsonResource(raw: audioItem, httpClient: httpClient, oauth: oauthResource)
		
		stub({ request in
			guard request.URL!.isEqualsToUrl(item.downloadResourceUrl!) else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			return OHHTTPStubsResponse(data: sendJson.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		item.downloadUrl.bindNext { result in
			if result == href {
				expectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testNotReturnDownloadUrl() {
		let expectation = expectationWithDescription("Should not return download url")
		
		let audioItem = JSON.getJsonFromFile("YandexAudioItem")!
		
		let item = YandexDiskCloudAudioJsonResource(raw: audioItem, httpClient: httpClient, oauth: oauthResource)
		
		stub({ request in
			guard request.URL!.isEqualsToUrl(item.downloadResourceUrl!) else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let sendingJson = JSON([  "method": "GET", "templated": false])
			return OHHTTPStubsResponse(data: sendingJson.safeRawData()!, statusCode: 200, headers: nil)
		}

		item.downloadUrl.doOnCompleted { expectation.fulfill() }.bindNext { result in
			XCTFail("Should not return data")
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}

	func testLoadCachedChilds() {
		let actualChildsexpectation = expectationWithDescription("Should return actual childs")
		let cachedChildsExpectation = expectationWithDescription("Should return cached childs")
		
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let cachedJson = JSON.getJsonFromFile("YandexMusicFolderContents_Cached")

		let item = YandexDiskCloudJsonResource(raw: rootItem, httpClient: httpClient, oauth: oauthResource)
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(item, childs: item.deserializeResponse(cachedJson!))
		
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=disk:/Music" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let json = JSON.getJsonFromFile("YandexMusicFolderContents")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		var loadedChilds: [CloudResource]?
		var cachedChilds: [CloudResource]?
		
		var responseCount = 0
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		//item.loadChildResources().bindNext { childs in
		client.loadChildResources(item, loadMode: .CacheAndRemote).bindNext { result in
			if responseCount == 0 {
				// first responce should be with locally cached data
				cachedChilds = result
				responseCount += 1
				cachedChildsExpectation.fulfill()
			} else if responseCount == 1 {
				// second responce should be with actual data
				loadedChilds = result
				responseCount += 1
				actualChildsexpectation.fulfill()
			} else { responseCount += 1 }
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		// check cached items
		XCTAssertNotNil(cachedChilds)
		XCTAssertEqual(2, cachedChilds?.count)
		
		var first = cachedChilds?.first
		XCTAssertEqual(first?.name, "Apocalyptica")
		XCTAssertEqual(first?.uid, "disk:/Music/Apocalyptica")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(item.uid, first?.parent?.uid)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		var audioItem = cachedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "CachedTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/CachedTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		// check loaded items
		XCTAssertNotNil(loadedChilds)
		XCTAssertEqual(4, loadedChilds?.count)
		
		first = loadedChilds?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.uid, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(item.uid, first?.parent?.uid)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		audioItem = loadedChilds?.last as? CloudAudioResource
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(item.uid, audioItem?.parent?.uid)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}

	
	func testCacheRootResources() {
		let expectation = expectationWithDescription("Should return childs")
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=/" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let json = JSON.getJsonFromFile("YandexRoot")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).doOnError { _ in XCTFail("Request failed") }.bindNext { _ in
			expectation.fulfill()
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		let realm = try! Realm()
		XCTAssertEqual(10, realm.objects(RealmCloudResource).count)
	}

	func testLoadCachedRootData() {
		let actualRootsexpectation = expectationWithDescription("Should return actual root items")
		let cachedRootExpectation = expectationWithDescription("Ahould return cached root items")
		
		let cachedJson = JSON.getJsonFromFile("YandexRoot")!
		let yandexRoot = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource)
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(yandexRoot, childs: yandexRoot.deserializeResponse(cachedJson))
		
		stub({ request in
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=/" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let json = JSON.getJsonFromFile("YandexRoot")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		var responseCount = 0
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		client.loadChildResources(rootResource, loadMode: .CacheAndRemote).bindNext { childs in
			if responseCount == 0 {
				// first responce should be with locally cached data
				responseCount += 1
				cachedRootExpectation.fulfill()
			} else if responseCount == 1 {
				// second responce should be with actual data
				responseCount += 1
				actualRootsexpectation.fulfill()
			}
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
		
		XCTAssertEqual(2, responseCount, "Check receive two responses")
	}

	func testLoadCacheOnly() {
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let musicResource = rootResource.wrapRawData(rootItem) as! YandexDiskCloudJsonResource
		let cachedJson = JSON.getJsonFromFile("YandexMusicFolderContents_Cached")!
		let musicChilds = musicResource.deserializeResponse(cachedJson)

		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(musicResource, childs: musicChilds)
		
		stub({ request in
			print(request.URL)
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=disk:/Music" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			XCTFail("Should not invoke HTTP request")
			let json = JSON.getJsonFromFile("YandexMusicFolderContents")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		let response = try! client.loadChildResources(musicResource, loadMode: .CacheOnly).toBlocking().toArray()
		
		// check responded only with cached data
		XCTAssertEqual(1, response.count, "Check responded once")
		
		// check return correct cached data
		let first = response.first?.first
		XCTAssertEqual(first?.name, "Apocalyptica")
		XCTAssertEqual(first?.uid, "disk:/Music/Apocalyptica")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(musicResource.uid, first?.parent?.uid)
		//XCTAssertTrue(first?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		let audioItem = response.first?.last
		XCTAssertEqual(audioItem?.name, "CachedTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/CachedTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertTrue(audioItem?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertEqual(musicResource.uid, audioItem?.parent?.uid)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}

	func testLoadRemoteOnly() {
		guard let rootItem = JSON.getJsonFromFile("YandexMusicDirItem") else {
			waitForExpectationsWithTimeout(1, handler: nil)
			return
		}
		
		let musicResource = rootResource.wrapRawData(rootItem) as! YandexDiskCloudJsonResource
		let cachedJson = JSON.getJsonFromFile("YandexMusicFolderContents_Cached")!
		let musicChilds = musicResource.deserializeResponse(cachedJson)
		
		let cacheProvider = RealmCloudResourceCacheProvider()
		cacheProvider.cacheChilds(musicResource, childs: musicChilds)
		//let item = YandexDiskCloudJsonResource(raw: rootItem, oAuthResource: oauthResource, parent: nil, httpClient: httpClient, cacheProvider: cacheProvider)
		
		stub({ request in
			print(request.URL)
			guard request.URL?.absoluteString == "https://cloud-api.yandex.net:443/v1/disk/resources?path=disk:/Music" else { return false }
			guard let key = request.allHTTPHeaderFields?["Authorization"] where key == self.authKey else { return false }
			return true
		}) { _ in
			let json = JSON.getJsonFromFile("YandexMusicFolderContents")!
			return OHHTTPStubsResponse(data: json.safeRawData()!, statusCode: 200, headers: nil)
		}
		
		let client = CloudResourceClient(cacheProvider: cacheProvider)
		let response = try! client.loadChildResources(musicResource, loadMode: .RemoteOnly).toBlocking().toArray()
		
		// check responded only with cached data
		XCTAssertEqual(1, response.count, "Check responded once")
		
		// check return correct cached data
		//let first = response.first?.first
		//guard case Result.success(let box) = response.first! else { XCTFail("Incorrect response returned"); return }
		let first = response.first?.first
		XCTAssertEqual(first?.name, "David Arkenstone")
		XCTAssertEqual(first?.uid, "disk:/Music/David Arkenstone")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertEqual(musicResource.uid, first?.parent?.uid)
		//XCTAssertTrue(first?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertTrue((first as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
		
		//let audioItem = response.last?.last as? CloudAudioResource
		//guard case Result.success(let box2) = response.last! else { XCTFail("Incorrect response returned"); return }
		let audioItem = response.first?.last
		XCTAssertEqual(audioItem?.name, "TestTrack.mp3")
		XCTAssertEqual(audioItem?.uid, "disk:/Music/TestTrack.mp3")
		XCTAssertEqual(audioItem?.type, .File)
		XCTAssertTrue(audioItem is YandexDiskCloudAudioJsonResource)
		//XCTAssertEqual(musicResource.uid, audioItem?.parent?.uid)
		//XCTAssertTrue(audioItem?.parent as? YandexDiskCloudJsonResource === musicResource)
		//XCTAssertTrue((audioItem as! YandexDiskCloudJsonResource).cacheProvider as! CloudResourceNsUserDefaultsCacheProvider === cacheProvider)
	}
}
