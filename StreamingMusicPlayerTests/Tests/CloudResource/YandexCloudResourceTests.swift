import XCTest
import JASON
import OHHTTPStubs
@testable import StreamingMusicPlayer
import RxSwift
@testable import RxHttpClient

class YandexCloudResourceTests: XCTestCase {
	var bag: DisposeBag!
	var oauthResource: OAuthType!
	var httpClient: HttpClientType!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		bag = DisposeBag()
		httpClient = HttpClient()
		oauthResource = YandexOAuth(clientId: "fakeClientId", urlScheme: "fakeOauthResource", keychain: FakeKeychain(), authenticator: OAuthAuthenticator())
		(oauthResource as! YandexOAuth).keychain.setString("", forAccount: (oauthResource as! YandexOAuth).tokenKeychainId, synchronizable: false, background: false)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		bag = nil
	}
	
	func testReturnRootResource() {
		let root = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource)
		XCTAssertEqual(root.name, "disk")
		XCTAssertEqual(root.uid, "/")
		XCTAssertTrue((root as! YandexDiskCloudJsonResource).oAuthResource.clientId == oauthResource.clientId)
	}
	
	func testCheckTooManyRequestsError() {
		let jsonError: JSON = ["message": "Слишком много запросов", "error": "TooManyRequestsError", "description": "Too Many Requests"]
		let yandex = YandexDiskCloudJsonResource.getRootResource(oauth: oauthResource) as! YandexDiskCloudJsonResource
		let error = yandex.checkError(jsonError)
		XCTAssertEqual(YandexDiskError.tooManyRequests._code, error?._code)
	}
	
	func testCheckUnknownError() {
		let jsonError: JSON = ["message": "Слишком много запросов", "error": "StrangeError", "description": "Too Many Requests"]
		let yandex = YandexDiskCloudJsonResource.getRootResource(oauth: oauthResource) as! YandexDiskCloudJsonResource
		let error = yandex.checkError(jsonError)
		if case let YandexDiskError.unknown(title: errorTitle) = error! {
			XCTAssertEqual("StrangeError", errorTitle)
		} else {
			XCTFail("Did not return correct error")
		}
	}
	
	func testCreateRequest() {
		//let req = YandexDiskCloudJsonResource.createRequestForLoadRootResources(oauthResource, httpUtilities: utilities) as? FakeRequest
		let root = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource) as? YandexDiskCloudJsonResource
		let req = root?.createRequest()
		XCTAssertNotNil(req, "Should create request")
		XCTAssertEqual(NSURL(baseUrl: YandexDiskCloudJsonResource.resourcesApiUrl, parameters: ["path": "/"]), req?.URL, "Should create correct url")
		XCTAssertEqual(oauthResource.accessToken, req!.allHTTPHeaderFields!["Authorization"], "Should set one header with correct token")
	}
	
	func testNotCreateRequest() {
		let oauthResWithoutTokenId = YandexOAuth(clientId: "test", urlScheme: "fake", keychain: FakeKeychain(), authenticator: OAuthAuthenticator())
		//OAuthResourceBase(id: "fake", authUrl: "https://fake.com", clientId: nil, tokenId: nil)
		let root = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResWithoutTokenId) as? YandexDiskCloudJsonResource
		//let req = YandexDiskCloudJsonResource.createRequestForLoadRootResources(oauthResWithoutTokenId, httpUtilities: utilities) as? FakeRequest
		let req = root?.createRequest()
		XCTAssertNil(req, "Should not create request")
	}
	
	func testDeserializeJsonResponseFolder() {
		let root = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource) as? YandexDiskCloudJsonResource
		let first = root?.deserializeResponse(JSON.getJsonFromFile("YandexRoot")!).first
		//let first = YandexDiskCloudJsonResource.deserializeResponseData(JSON.getJsonFromFile("YandexRoot"), res: oauthResource)?.first
		XCTAssertNotNil(first)
		XCTAssertEqual(first?.name, "Documents")
		XCTAssertEqual(first?.uid, "disk:/Documents")
		XCTAssertEqual(first?.type, .Folder)
		XCTAssertTrue(first is YandexDiskCloudJsonResource)
		//XCTAssertNil(first?.mediaType)
		XCTAssertNil(first?.mimeType)
		//XCTAssertEqual(oauthResource.id, first?.oAuthResource.id)
		XCTAssertEqual((first?.getRequestHeaders())!, ["Authorization": oauthResource.accessToken!])
		XCTAssertEqual((first?.getRequestParameters())!, ["path": first!.uid])
	}
	
	func testNotDeserializeIncorrectJson() {
		let root = YandexDiskCloudJsonResource.getRootResource(httpClient, oauth: oauthResource) as! YandexDiskCloudJsonResource
		let json: JSON =  ["Test": "Value"]
		//let response = YandexDiskCloudJsonResource.deserializeResponseData(json, res: oauthResource)
		let response = root.deserializeResponse(json).first
		XCTAssertNil(response)
	}
	
	func testDownloadUrlWithRetry() {
		var attemptsCounter = 0
		
		let expectation = expectationWithDescription("Should return downloadUrl")
		
		// create audioResource with empty json (it doesn't need for this test)
		let audioResource = YandexDiskCloudAudioJsonResource(raw: ["path": "someResource"],
		                                                     httpClient: HttpClient(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration()),
		                                                     oauth: oauthResource)
		audioResource.downloadUrlErrorRetryDelayTime = 0.005
		
		stub({ $0.URL?.absoluteString == audioResource.downloadResourceUrl!.absoluteString	}) { _ in
			var sendData: NSData!
			if attemptsCounter < 3 {
				let jsonError: JSON = ["message": "Слишком много запросов \(attemptsCounter)", "error": "TooManyRequestsError", "description": "Too Many Requests"]
				sendData = jsonError.safeRawData()!
				attemptsCounter += 1
			} else {
				let linkJson: JSON = ["href": "https://link.com"]
				sendData = linkJson.safeRawData()!
			}
			
			return OHHTTPStubsResponse(data: sendData, statusCode: 200, headers: nil)
		}
		
		audioResource.downloadUrl.bindNext { url in
			XCTAssertEqual("https://link.com", url)
			expectation.fulfill()
		}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
	
	func testNotReturnDownloadUrlDueToErrors() {
		let expectation = expectationWithDescription("Should not return downloadUrl")
		
		// create audioResource with empty json (it doesn't need for this test)
		let audioResource = YandexDiskCloudAudioJsonResource(raw: ["path": "someResource"],
		                                                     httpClient: HttpClient(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration()),
		                                                     oauth: oauthResource)
		audioResource.downloadUrlErrorRetryDelayTime = 0.005
		
		stub({ $0.URL?.absoluteString == audioResource.downloadResourceUrl!.absoluteString	}) { _ in
			var sendData: NSData!
			let jsonError: JSON = ["message": "Слишком много запросов", "error": "TooManyRequestsError", "description": "Too Many Requests"]
			sendData = jsonError.safeRawData()!
			print("sending")
			return OHHTTPStubsResponse(data: sendData, statusCode: 200, headers: nil)
		}
		
		audioResource.downloadUrl.doOnCompleted { expectation.fulfill() }.bindNext { _ in
			XCTFail("Should not return url")
			}.addDisposableTo(bag)
		
		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
