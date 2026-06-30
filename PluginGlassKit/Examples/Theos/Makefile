TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = WeChat
ARCHS = arm64 arm64e

ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
else
    unexport THEOS_PACKAGE_SCHEME
endif

export DEBUG = 0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LiquidGlassDemo

LiquidGlassDemo_FILES = Tweak.xm ../../Sources/LGGlassStyle.m ../../Sources/LGGlassView.m ../../Sources/LGGlassButton.m ../../Sources/LGGlassFloatingBar.m
LiquidGlassDemo_CFLAGS += -fobjc-arc -Wno-deprecated-declarations
LiquidGlassDemo_FRAMEWORKS += UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
