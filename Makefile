framework:
	swift package generate-xcodeproj --skip-extra-files
	xcodebuild -project mcDesktopCapture.xcodeproj -scheme mcDesktopCapture-Package -configuration Release -sdk macosx CONFIGURATION_BUILD_DIR=Build

conv:
	ffmpeg -i Video/unity.mov -pix_fmt yuv420p Video/unity.mp4

