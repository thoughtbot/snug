APP := Snug
BUILD_DIR := build
DIST := dist
# Stable signing identity keeps TCC (camera/mic) grants across rebuilds.
# Until the cert exists, override with: make build SIGN_IDENTITY=-
SIGN_IDENTITY ?= Snug Dev
RELEASE_SIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE ?= snug-notary
RELEASE_APP := $(BUILD_DIR)/Build/Products/Release/$(APP).app

.PHONY: bootstrap gen build run test icon clean release release-build dmg notarize

bootstrap:
	@command -v xcodegen >/dev/null || brew install xcodegen
	@if security find-identity -p codesigning -v 2>/dev/null | grep -q "Snug Dev"; then \
		echo "'Snug Dev' signing identity present"; \
	else \
		echo "No 'Snug Dev' identity yet — see scripts/make-dev-cert.sh (ad-hoc builds: make build SIGN_IDENTITY=-)"; \
	fi

gen:
	xcodegen generate

build: gen
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) -configuration Debug \
		-derivedDataPath $(BUILD_DIR) -quiet \
		CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)" build

run:
	open $(BUILD_DIR)/Build/Products/Debug/$(APP).app

test: gen
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) -configuration Debug \
		-derivedDataPath $(BUILD_DIR) test

icon:
	swift scripts/make-icon.swift
	iconutil -c icns $(BUILD_DIR)/$(APP).iconset -o Support/AppIcon.icns

release-build: gen
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) -configuration Release \
		-derivedDataPath $(BUILD_DIR) -quiet \
		CODE_SIGN_IDENTITY="$(RELEASE_SIGN_IDENTITY)" build
	codesign --verify --strict --deep "$(RELEASE_APP)"
	@codesign -d --entitlements - "$(RELEASE_APP)" 2>/dev/null | grep -q "device.camera" \
		&& echo "entitlements OK" || (echo "MISSING camera entitlement" && exit 1)

dmg: release-build
	$(eval VERSION := $(shell defaults read "$(PWD)/$(RELEASE_APP)/Contents/Info" CFBundleShortVersionString))
	rm -rf $(DIST)/staging && mkdir -p $(DIST)/staging
	cp -R "$(RELEASE_APP)" $(DIST)/staging/
	ln -s /Applications $(DIST)/staging/Applications
	hdiutil create -volname $(APP) -srcfolder $(DIST)/staging -ov -format UDZO \
		"$(DIST)/$(APP)-$(VERSION).dmg"
	codesign --sign "$(RELEASE_SIGN_IDENTITY)" --timestamp "$(DIST)/$(APP)-$(VERSION).dmg"
	rm -rf $(DIST)/staging
	@echo "Created $(DIST)/$(APP)-$(VERSION).dmg"

notarize:
	$(eval DMG := $(shell ls -t $(DIST)/$(APP)-*.dmg | head -1))
	xcrun notarytool submit "$(DMG)" --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple "$(DMG)"
	spctl --assess --type open --context context:primary-signature -v "$(DMG)"
	@echo "Notarized and stapled: $(DMG)"

release: dmg notarize

clean:
	rm -rf $(BUILD_DIR) $(DIST) $(APP).xcodeproj Meet.xcodeproj
