include Makefile.parameters

all:
	webdev build --output web:build
	cat build/ArrowLogo.html \
		| sed -e 's/___ANALYTICS_ID/$(analytics_id)/g' -\
		> /tmp/ArrowLogo.html -
	cp /tmp/ArrowLogo.html build/ArrowLogo.html

