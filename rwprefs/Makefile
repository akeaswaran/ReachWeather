TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.1
ARCHS = armv7 arm64
THEOS_BUILD_DIR = debs
DEBUG = 1
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

BUNDLE_NAME = RWPrefs
RWPrefs_FILES = RWPrefs.mm
RWPrefs_INSTALL_PATH = /Library/PreferenceBundles
RWPrefs_FRAMEWORKS = UIKit
RWPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/RWPrefs.plist$(ECHO_END)
