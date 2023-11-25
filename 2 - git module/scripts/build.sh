#!/bin/bash
set -e

SCRIPT_DIR=$(readlink -f $(dirname $BASH_SOURCE))
ROOT_DIR=$(readlink -f "$SCRIPT_DIR/..")
BUILD_PATH="$ROOT_DIR/$BUILD_PATH"

source $ROOT_DIR/.env

echo "Building yamlcv"
$SCRIPT_DIR/generate_cv.sh

CV_YAML="$BUILD_PATH/$CV.yaml"
CV_HTML="$BUILD_PATH/$CV.html"
CV_PDF="$BUILD_PATH/$CV.pdf"

echo "Building HTML from $CV_YAML"
yaml-cv yaml-cv $CV_YAML > $BUILD_PATH/${CV}.html

echo "Building PDF from $CV"
yaml-cv yaml-cv $CV_YAML --pdf $BUILD_PATH/${CV}.pdf

echo "Check files in ./$BUILD_PATH directory"
