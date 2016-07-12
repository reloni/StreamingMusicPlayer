# Copy frameworks that may be changed while development into dependencies folder, to allow Travis-CI use actual version for testing
if [ "${CONFIGURATION}" = "Debug" ]; then
	cp -R $1/Debug-iphonesimulator/RxHttpClient.framework ./Dependencies/iOS 2>/dev/null || :
	cp -R $1/Debug-iphonesimulator/RxHttpClientJasonExtension.framework ./Dependencies/iOS 2>/dev/null || :
	cp -R $1/Debug-iphonesimulator/RxStreamPlayer.framework ./Dependencies/iOS 2>/dev/null || :
fi
if [ "${CONFIGURATION}" = "Release" ]; then
	mkdir -p ./Dependencies/iOS/Release
	cp -LR $1/Release-iphoneos/RxHttpClient.framework ./Dependencies/iOS/Release
	cp -LR $1/Release-iphoneos/RxHttpClientJasonExtension.framework ./Dependencies/iOS/Release
	cp -LR $1/Release-iphoneos/RxStreamPlayer.framework ./Dependencies/iOS/Release
fi
exit 0