ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Chroma
Chroma_FILES = Tweak.xm
Chroma_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += chromaprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
