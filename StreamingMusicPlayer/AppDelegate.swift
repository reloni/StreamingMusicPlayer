import UIKit
import CoreData
import AVFoundation
import RxSwift
import MediaPlayer
import RxStreamPlayer
import RxHttpClient

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	let bag = DisposeBag()


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		#if DEBUG
			NSLog("Documents Path: %@", NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first ?? "")
		#endif
		
		let downloadManager = DownloadManager(saveData: true,
		                                      fileStorage: LocalNsUserDefaultsStorage(persistInformationAboutSavedFiles: true),
		                                      httpClient: HttpClient())
		let player = RxPlayer(repeatQueue: false,
		                      shuffleQueue: false,
		                      downloadManager: downloadManager)
		
		let cloudResourceClient = CloudResourceClient(cacheProvider: RealmCloudResourceCacheProvider())
		let cloudResourceLoader = CloudResourceLoader(cacheProvider: cloudResourceClient.cacheProvider!,
		                                              rootCloudResources: [YandexDiskCloudJsonResource.typeIdentifier:
																										YandexDiskCloudJsonResource.getRootResource(HttpClient(), oauth: YandexOAuth())])
		player.streamResourceLoaders.append(cloudResourceLoader)
		
		MainModel.sharedInstance = MainModel(player: player, userDefaults: NSUserDefaults.standardUserDefaults(), cloudResourceClient: cloudResourceClient)
		
		MainModel.sharedInstance.loadPlayerState()
		
		MainModel.sharedInstance.player.playerEvents.bindNext { event in
			switch event {
			case PlayerEvents.Stopped: fallthrough
			case PlayerEvents.Paused: fallthrough
			case PlayerEvents.Started: fallthrough
			case PlayerEvents.Resumed:
				MainModel.sharedInstance.savePlayerState()
				
				guard let info = MainModel.sharedInstance.player.getCurrentItemMetadataForNowPlayingCenter() else {
					MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
					break
				}
				MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
			default: break
			}
			}.addDisposableTo(bag)
		
		
		//		Observable<Int>.interval(1, scheduler: MainScheduler.instance).bindNext { _ in
		//			print("Resource count: \(RxSwift.resourceCount)")
		//		}.addDisposableTo(bag)
		
		becomeFirstResponder()
		UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
		
		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let initialController = storyboard.instantiateViewControllerWithIdentifier("RootTabBarController")
		window?.rootViewController = initialController
		window?.makeKeyAndVisible()
		
		return true
	}
	
	
	
	override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
	override func remoteControlReceivedWithEvent(event: UIEvent?) {
		if event?.type == .RemoteControl {
			switch event!.subtype {
			case UIEventSubtype.RemoteControlPlay: MainModel.sharedInstance.player.resume(true)
			case UIEventSubtype.RemoteControlStop: MainModel.sharedInstance.player.pause()
			case UIEventSubtype.RemoteControlPause: MainModel.sharedInstance.player.pause()
			case UIEventSubtype.RemoteControlTogglePlayPause: print("remote control toggle play/pause")
			case UIEventSubtype.RemoteControlNextTrack: MainModel.sharedInstance.player.toNext(true)
			case UIEventSubtype.RemoteControlPreviousTrack: MainModel.sharedInstance.player.toPrevious(true)
			default: super.remoteControlReceivedWithEvent(event)
			}
		} else {
			super.remoteControlReceivedWithEvent(event)
		}
	}
	
	// вызывается при вызове приложения по URL схеме
	// настраивается в  Info.plist в разделе URL types/URL Schemes
	func application(application: UIApplication,
	                 openURL url: NSURL, options: [String: AnyObject]) -> Bool {
		OAuthAuthenticator.sharedInstance.processCallbackUrl(url.absoluteString).doOnCompleted {
			print("oauth authorization completed")
			}.doOnNext { oauth in
				print("type: \(oauth.oauthTypeId) new token: \(oauth.accessToken) refresh token: \(oauth.refreshToken)")
			}.subscribe().addDisposableTo(bag)
		
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

