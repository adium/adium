PREFIX?=
BUILD_DIR?=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)

ifeq ($(strip $(BUILD_DIR)),)
	BUILD_DIR=build
endif

DEFAULT_BUILDCONFIGURATION=Release-Debug

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

CP=ditto --rsrc
RM=rm

.PHONY: all adium clean localizable-strings latest test astest install

adium:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) CFLAGS="$(ADIUM_CFLAGS)" build

test:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) CFLAGS="$(ADIUM_CFLAGS)" -target "Unit tests" build
astest:
	osascript unittest\ runner.applescript | tr '\r' '\n'

install:
	cp -R build/$(BUILDCONFIGURATION)/Adium.app ~/Applications/

clean:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION)  clean

localizable-strings:
	mkdir tmp || true
	mv "Plugins/Purple Service" tmp
	mv "Plugins/WebKit Message View" tmp
	mv "Plugins/Twitter Plugin" tmp
	genstrings -o Resources/en.lproj -s AILocalizedString Source/*.m Source/*.h Plugins/*/*.h Plugins/*/*.m Plugins/*/*/*.h Plugins/*/*/*.m tmp/WebKit\ Message\ View/*.h tmp/WebKit\ Message\ View/*.m tmp/Twitter\ Plugin/*.h tmp/Twitter\ Plugin/*.m
	genstrings -o tmp/Purple\ Service/en.lproj -s AILocalizedString tmp/Purple\ Service/*.h tmp/Purple\ Service/*.m
	genstrings -o Frameworks/AIUtilities\ Framework/Resources/en.lproj -s AILocalizedString Frameworks/AIUtilities\ Framework/Source/*.h Frameworks/AIUtilities\ Framework/Source/*.m
	genstrings -o Frameworks/Adium\ Framework/Resources/en.lproj -s AILocalizedString Frameworks/Adium\ Framework/Source/*.m Frameworks/Adium\ Framework/Source/*.h
	mv "tmp/Purple Service" Plugins
	mv "tmp/WebKit Message View" Plugins
	mv "tmp/Twitter Plugin" Plugins
	rmdir tmp || true

latest:
	hg pull -u
	make adium
