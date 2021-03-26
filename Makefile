FINALPACKAGE = 1
GO_EASY_ON_ME = 1
ARCHS = armv7 arm64 arm64e

TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DNDMyRecording

DNDMyRecording_FILES = Tweak.xm
DNDMyRecording_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
