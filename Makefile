PREFIX?=
BUILD_DIR?=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)

ifeq ($(strip $(BUILD_DIR)),)
	BUILD_DIR=build
endif

DEFAULT_BUILDCONFIGURATION=Release-Debug

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

# Choose xcodebuild 
# currently used for build machines
# XCODEBUILD ?= $(shell if test -d /Xcode4; then echo "/Xcode4/usr/bin/xcodebuild"; else echo "xcodebuild"; fi)
XCODEBUILD ?= xcodebuild
#

CP=ditto --rsrc
RM=rm

.PHONY: all adium clean localizable-strings latest test astest install

adium:
	$(XCODEBUILD) -version
	$(XCODEBUILD) -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) CFLAGS="$(ADIUM_CFLAGS)" $(ADIUM_NIGHTLY_FLAGS) build

test:
	$(XCODEBUILD) -version
	$(XCODEBUILD) -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) CFLAGS="$(ADIUM_CFLAGS)" $(ADIUM_NIGHTLY_FLAGS) -target "Unit tests" build
astest:
	osascript unittest\ runner.applescript | tr '\r' '\n'

install:
	mkdir -p ~/Applications
	cp -R build/$(BUILDCONFIGURATION)/Adium.app ~/Applications/

clean:
	$(XCODEBUILD) -version
	$(XCODEBUILD) -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) $(ADIUM_NIGHTLY_FLAGS) clean

localizable-strings:
	mkdir tmp || true
	mv "Plugins/Purple Service" tmp
	genstrings -o Resources/en.lproj -s AILocalizedString Source/*.m Source/*.h Plugins/*/*.h Plugins/*/*.m Plugins/*/*/*.h Plugins/*/*/*.m
	genstrings -o tmp/Purple\ Service/en.lproj -s AILocalizedString tmp/Purple\ Service/*.h tmp/Purple\ Service/*.m
	genstrings -o Frameworks/AIUtilities\ Framework/Resources/en.lproj -s AILocalizedString Frameworks/AIUtilities\ Framework/Source/*.h Frameworks/AIUtilities\ Framework/Source/*.m
	genstrings -o Frameworks/Adium\ Framework/Resources/en.lproj -s AILocalizedString Frameworks/Adium\ Framework/Source/*.m Frameworks/Adium\ Framework/Source/*.h
	mv "tmp/Purple Service" Plugins
	rmdir tmp || true

latest:
	hg pull -u
	make adium
