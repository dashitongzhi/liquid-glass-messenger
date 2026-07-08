TARGET ?= iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES ?= WeChat
ARCHS ?= arm64 arm64e
TWEAK_NAME ?= LiquidGlassDemo

# Drop-in knob: when copying this example into a WCDuang/wctodo-style tweak,
# point this at the folder that contains LGGlassFloatingBar.h and the .m files.
PLUGIN_GLASS_KIT_SOURCE_DIR ?= ../../Sources

PLUGIN_GLASS_KIT_FILES := \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassStyle.m \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassView.m \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassButton.m \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassFloatingBar.m

ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
else
    unexport THEOS_PACKAGE_SCHEME
endif

.PHONY: smoke
smoke:
	@env bash ./smoke.sh

ifneq ($(filter smoke,$(MAKECMDGOALS)),smoke)

DEBUG ?= 0
export DEBUG
include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_FILES += Tweak.xm $(PLUGIN_GLASS_KIT_FILES)
$(TWEAK_NAME)_CFLAGS += -fobjc-arc -Wno-deprecated-declarations -I$(PLUGIN_GLASS_KIT_SOURCE_DIR)
$(TWEAK_NAME)_FRAMEWORKS += UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

endif
