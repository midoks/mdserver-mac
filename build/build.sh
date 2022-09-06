#!/bin/bash
# 打包

BUILD_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(dirname "$BUILD_DIR")

APP_NAME="mdserver"
APP_VER=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' $ROOT_DIR/mdserver/mdserver.xcodeproj/project.pbxproj)
APP_RELEASE=${BUILD_DIR}/release
APP_DEBUG=${BUILD_DIR}/debug

DMG_FINAL="${APP_NAME}.dmg"




function build(){
	mkdir -p $APP_RELEASE
	mkdir -p $APP_DEBUG

	echo "build mdserver."${APP_VER}

	echo "Building archive... please wait a minute"
    xcodebuild -project $ROOT_DIR/mdserver/mdserver.xcodeproj -config Release -scheme mdserver -archivePath ${APP_RELEASE} archive

    echo "Exporting archive..."
    xcodebuild -archivePath ${BUILD_DIR}/release.xcarchive -exportArchive -exportPath ${APP_RELEASE} -exportOptionsPlist $BUILD_DIR/build.plist

    echo "Building archive... please wait a minute"
    xcodebuild -project $ROOT_DIR/mdserver/mdserver.xcodeproj -config Debug -scheme mdserver -archivePath ${APP_DEBUG} archive

    echo "Exporting archive..."
    xcodebuild -archivePath ${BUILD_DIR}/release.xcarchive -exportArchive -exportPath ${APP_DEBUG} -exportOptionsPlist $BUILD_DIR/build.plist

}


echo $ROOT_DIR

build

echo 'done'
