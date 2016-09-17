#SDK=iphonesimulator9.3
SDK=iphoneos

carthage checkout

carthage update realm-cocoa --platform iOS
carthage update OHHTTPStubs --platform iOS
carthage update JASON --platform iOS

#build RxSwift
(cd ./Carthage/Checkouts/RxSwift && set -o pipefail && xcodebuild -scheme "RxSwift-iOS" -workspace "Rx.xcworkspace" -sdk "$SDK" -configuration Release ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)
(cd ./Carthage/Checkouts/RxSwift && set -o pipefail && xcodebuild -scheme "RxCocoa-iOS" -workspace "Rx.xcworkspace" -sdk "$SDK" -configuration Release ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)
(cd ./Carthage/Checkouts/RxSwift && set -o pipefail && xcodebuild -scheme "RxTests-iOS" -workspace "Rx.xcworkspace" -sdk "$SDK" -configuration Release ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)
(cd ./Carthage/Checkouts/RxSwift && set -o pipefail && xcodebuild -scheme "RxBlocking-iOS" -workspace "Rx.xcworkspace" -sdk "$SDK" -configuration Release ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)

#copy RxSwift into root Carthage folder
#cp -R -f ./Build/Release-iphonesimulator/ ./Carthage/Build/iOS
#rm -rf ./Build/Release-iphonesimulator
cp -R -f ./Build/Release-iphoneos/ ./Carthage/Build/iOS
rm -rf ./Build/Release-iphoneos

##Build RxHttpClient
mkdir -p ./Carthage/Checkouts/RxHttpClient/Carthage
(cd ./Carthage/Checkouts/RxHttpClient/Carthage && ln -s ../../../Build Build)
(cd ./Carthage/Checkouts/RxHttpClient && set -o pipefail && xcodebuild -scheme "RxHttpClient" -project "RxHttpClient.xcodeproj" -sdk "$SDK" -configuration Debug ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)
#copy RxHttpClient framework to Carthage folder
#cp -R -f ./Build/Debug-iphonesimulator/ ./Carthage/Build/iOS
#rm -rf ./Build/Debug-iphonesimulator
cp -R -f ./Build/Debug-iphoneos/ ./Carthage/Build/iOS
rm -rf ./Build/Debug-iphoneos

##Build RxHttpClientJasonExtension
mkdir -p ./Carthage/Checkouts/RxHttpClientJasonExtension/Carthage
(cd ./Carthage/Checkouts/RxHttpClientJasonExtension/Carthage && ln -s ../../../Build Build)
(cd ./Carthage/Checkouts/RxHttpClientJasonExtension && set -o pipefail && xcodebuild -scheme "RxHttpClientJasonExtension" -project "RxHttpClientJasonExtension.xcodeproj" -sdk "$SDK" -configuration Release ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)
#cp -R -f ./Build/Debug-iphonesimulator/ ./Carthage/Build/iOS
#rm -rf ./Build/Debug-iphonesimulator
cp -R -f ./Build/Release-iphoneos/ ./Carthage/Build/iOS
rm -rf ./Build/Release-iphoneos

##Build RxStreamPlayer
mkdir -p ./Carthage/Checkouts/RxStreamPlayer/Carthage
(cd ./Carthage/Checkouts/RxStreamPlayer/Carthage && ln -s ../../../Build Build)
(cd ./Carthage/Checkouts/RxStreamPlayer && set -o pipefail && xcodebuild -scheme "RxStreamPlayer" -project "RxStreamPlayer.xcodeproj" -sdk "$SDK" -configuration Release ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build OBJROOT=../../../ObjRoot SYMROOT=../../../Build)
#cp -R -f ./Build/Debug-iphonesimulator/ ./Carthage/Build/iOS
#rm -rf ./Build/Debug-iphonesimulator
cp -R -f ./Build/Release-iphoneos/ ./Carthage/Build/iOS
rm -rf ./Build/Release-iphoneos

#build other frameworks
#carthage update realm-cocoa --platform iOS
#carthage update OHHTTPStubs --platform iOS
#carthage update JASON --platform iOS
#carthage update RxHttpClient --platform iOS --configuration Debug
#carthage update RxHttpClientJasonExtension --platform iOS
#carthage update RxStreamPlayer --platform iOS
