#!/bin/sh
rm -Rf deploy/*
mkdir -p deploy/web
mkdir -p deploy/web/packages/browser
cp packages/browser/dart.js deploy/web/packages/browser/dart.js
cp web/*.css web/*.dart web/*.js deploy/web/
#cp web/ArrowLogoDeploy.html deploy/web/ArrowLogo.html
cp web/ArrowLogo.html deploy/web/ArrowLogo.html
cp web/ArrowLogoRedirect.html deploy/ArrowLogo.html
cp -r jslib deploy/
# for easy testing
cp util/miniwebserver.dart deploy/

