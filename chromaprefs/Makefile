ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ChromaPrefs
ChromaPrefs_FILES = ChromaPrefs.mm ColorPicker/HRBrightnessCursor.m ColorPicker/HRBrightnessSlider.m ColorPicker/HRAlphaSlider.m ColorPicker/HRBrightnessSlider.m ColorPicker/HRAlphaCursor.m ColorPicker/HRColorCursor.m ColorPicker/HRColorInfoView.m ColorPicker/HRColorMapView.m ColorPicker/HRColorPickerView.m ColorPicker/HRHSVColorUtil.m ColorPicker/UIImage+CoreGraphics.m CircleViews.mm
ChromaPrefs_INSTALL_PATH = /Library/PreferenceBundles
ChromaPrefs_FRAMEWORKS = UIKit Social MessageUI CoreGraphics QuartzCore
ChromaPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ChromaPrefs.plist$(ECHO_END)
