#!/bin/sh
DEST=deploy

${DART2JS} web/arrowlogo.dart -o web/arrowlogo.dart.js
rm -Rf ${DEST}/*
mkdir -p ${DEST}/web
mkdir -p ${DEST}/web/packages/browser
cp packages/browser/dart.js ${DEST}/web/packages/browser/dart.js
cp packages/browser/interop.js ${DEST}/web/packages/browser/interop.js
cp web/*.css web/*.dart web/*.js ${DEST}/web/
cp web/ArrowLogo.html ${DEST}/web/ArrowLogo.html
# for easy testing
cp util/miniwebserver.dart ${DEST}/
chmod -R uog+r ${DEST}/

