# Copy RxHttpClient.framework, because it's used as submodule and may be changed while development
cp -R ./XCodeBuild/Products/Debug-iphonesimulator/RxHttpClient.framework ./Dependencies/iOS
cp -R ./XCodeBuild/Products/Debug-iphonesimulator/RxHttpClientJasonExtension.framework ./Dependencies/iOS
cp -R ./XCodeBuild/Products/Debug-iphonesimulator/RxStreamPlayer.framework ./Dependencies/iOS
exit 0