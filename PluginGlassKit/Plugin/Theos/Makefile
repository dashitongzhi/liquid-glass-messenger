TARGET ?= iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES ?= WeChat
ARCHS ?= arm64 arm64e
TWEAK_NAME ?= LiquidGlassMessengerPlugin

PLUGIN_RUNTIME_SOURCE_DIR ?= ../Sources
PLUGIN_GLASS_KIT_SOURCE_DIR ?= ../../Sources

PLUGIN_RUNTIME_FILES := \
    $(PLUGIN_RUNTIME_SOURCE_DIR)/LGWeChatPluginController.m

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
	@./smoke.sh

ifneq ($(filter smoke,$(MAKECMDGOALS)),smoke)

DEBUG ?= 0
export DEBUG
include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_FILES += Tweak.xm $(PLUGIN_RUNTIME_FILES) $(PLUGIN_GLASS_KIT_FILES)
$(TWEAK_NAME)_CFLAGS += -fobjc-arc -Wno-deprecated-declarations -I$(PLUGIN_RUNTIME_SOURCE_DIR) -I$(PLUGIN_GLASS_KIT_SOURCE_DIR)
$(TWEAK_NAME)_FRAMEWORKS += UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

endif
