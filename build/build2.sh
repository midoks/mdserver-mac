#!/bin/bash
# 打包
cd mdserver && xcodebuild -project mdserver.xcodeproj -scheme mdserver -configuration Debug build 
cd ../host && xcodebuild -project host.xcodeproj -scheme host -configuration Debug build 
cd ../ss && xcodebuild -project ss.xcodeproj -scheme ss -configuration Debug build 