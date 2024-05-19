#!/bin/bash
#git clone https://github.com/dibelogrivaya/DjVuLibre.git
#git clone https://smikhno@bitbucket.org/smikhno/djvulibrary.git
#git clone https://smikhno@bitbucket.org/smikhno/djvuviewerapp.git

cd ../DjVuLibre

xcodebuild -destination "platform=iOS Simulator,name=iPhone 8,OS=latest" -scheme LibDjvu CONFIGURATION_BUILD_DIR=./build -derivedDataPath . clean
xcodebuild -quiet -destination "platform=iOS Simulator,name=iPhone 8,OS=latest" -scheme LibDjvu CONFIGURATION_BUILD_DIR=./build -derivedDataPath .
cp build/libLibDjvu.a ../djvuviewerapp/

cd ../djvulibrary
xcodebuild -destination "platform=iOS Simulator,name=iPhone 8,OS=latest" -scheme StaticLibrary CONFIGURATION_BUILD_DIR=./build -derivedDataPath . clean
xcodebuild -quiet -destination "platform=iOS Simulator,name=iPhone 8,OS=latest" -scheme StaticLibrary CONFIGURATION_BUILD_DIR=./build -derivedDataPath .
cp build/libStaticLibrary.a ../djvuviewerapp/flow-reader/StaticLibrary/lib/

cd ../djvuviewerapp
xcodebuild -quiet -destination "platform=iOS Simulator,name=iPhone 8,OS=latest" -scheme flow-reader -derivedDataPath . 

UUID=`xcrun simctl list | egrep "iPhone 8 \(.*-.*-.*\)" | head -1 | perl -ne '/.*(iPhone 8).*\((.*-.*-.*)\)\s+\(/ && print $2 . "\n"'`

DEVICE_STATE=`xcrun simctl list | egrep "iPhone 8 \(.*-.*-.*\)" | head -1 | perl -ne '/.*(iPhone 8).*\((.*-.*-.*)\)\s+\((.*)\)/ && print $3 . "\n"'`

if [ $DEVICE_STATE = "Shutdown" ]; then
    xcrun simctl boot $UUID 
fi 

xcrun simctl install $UUID build/Products/Debug-iphonesimulator/flow-reader.app 
xcrun simctl launch $UUID build/Products/Debug-iphonesimulator/flow-reader.app



