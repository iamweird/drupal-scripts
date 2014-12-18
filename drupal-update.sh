#!/bin/bash

download_and_unpack_here() {
  LINK="$1"

  if [ "$LINK" == "" ]; then
    return 1
  fi

  TEMPFILE="$(mktemp -u --suffix=.zip)"

  wget "$LINK" -O "$TEMPFILE"
  unzip "$TEMPFILE"
  rm "$TEMPFILE"
}

download_ckeditor() {
  DIR="$1"

  if [ -d "$DIR" ]; then
    pushd "$DIR"
      CKEDITOR="http://download.cksource.com/CKEditor/CKEditor/CKEditor%204.4.6/ckeditor_4.4.6_full.zip"
      download_and_unpack_here "$CKEDITOR"

      pushd "ckeditor/plugins"
        TABLERESIZE="http://download.ckeditor.com/tableresize/releases/tableresize_4.4.6.zip"
        download_and_unpack_here "$TABLERESIZE"
      popd
    popd
  else
    echo "CKeditor directory doesn't exist: $DIR"
  fi
}

DRUSH="/root/.drush/drush"
DRUPAL_DIR="$(pwd)"

$DRUSH vset maintenance_mode 1
$DRUSH ard
$DRUSH en -y update
$DRUSH up
$DRUSH en -y l10n_update
$DRUSH l10n-update-refresh
$DRUSH l10n-update

DRUPAL_VERSION="$($DRUSH st drupal-version --format=list | cut -d '.' -f 1)"
if [ "$DRUPAL_VERSION" -gt "6" ]; then
  $DRUSH en -y libraries
  LIBRARIES_DIR="$DRUPAL_DIR/sites/all/libraries"

  if [ ! -d "$LIBRARIES_DIR" ]; then
    mkdir -p "$LIBRARIES_DIR"
  fi

  download_ckeditor "$LIBRARIES_DIR"
elif [ "$DRUPAL_VERSION" -eq "6" ]; then
  CKEDITOR_DIR="$DRUPAL_DIR/sites/all/modules/ckeditor"
  download_ckeditor "$CKEDITOR_DIR"
else
  echo "Unsupported Drupal version: $DRUPAL_VERSION"
fi

$DRUSH cc all
$DRUSH cron
$DRUSH vset maintenance_mode 0


