ARCHS = armv7 arm64 arm64e
export TARGET = iphone:clang:10.3:7.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DNDMyRecording

DNDMyRecording_FILES = Tweak.xm
DNDMyRecording_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
