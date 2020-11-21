.PHONY: get

# This should contain a variable 'analytics_id'
include Makefile.parameters

BUILD_COMMAND=flutter packages pub global run webdev build --output web:build
# BUILD_COMMAND=webdev build --output web:build

UPDATE_PACKAGES_COMMAND=flutter packages pub get
# UPDATE_PACKAGES_COMMAND=pub get

all:
	$(BUILD_COMMAND)
	cat build/ArrowLogo.html \
		| sed -e 's/___ANALYTICS_ID/$(analytics_id)/g' -\
		> /tmp/ArrowLogo.html -
	cp /tmp/ArrowLogo.html build/ArrowLogo.html

get:
	$(UPDATE_PACKAGES_COMMAND)
