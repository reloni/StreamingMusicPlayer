import UIKit
import Foundation

private func delegateClassName() -> String? {
	return NSClassFromString("XCTestCase") == nil ? NSStringFromClass(AppDelegate) : nil	
}

UIApplicationMain(Process.argc, Process.unsafeArgv, nil, delegateClassName())
