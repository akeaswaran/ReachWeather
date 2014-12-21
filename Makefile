TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.1
ARCHS = armv7 arm64
THEOS_BUILD_DIR = debs
DEBUG = 0
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

TWEAK_NAME = ReachWeather
ReachWeather_FILES = Tweak.xm RWWeatherController.m RWActivatorListener.m RWForecast.m HexColor.m
ReachWeather_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += rwprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"