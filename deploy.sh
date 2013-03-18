#!/bin/sh
rm -Rf deploy/*
mkdir -p deploy/web
cp web/*.css web/*.dart web/*.js deploy/web/
cp web/ArrowLogoDeploy.html deploy/web/ArrowLogo.html
cp web/ArrowLogoRedirect.html deploy/ArrowLogo.html
cp -r jslib deploy/

