#!/bin/bash

DRUSH="/root/.drush/drush"
DRUPAL_DIR="$(pwd)"
SITES_DIR="$DRUPAL_DIR/sites"

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

backup_single_site() {
  SITE_DIR="$1"

  if [ ! -d "$SITE_DIR" ]; then
    return 1
  fi
  if [ "$SITE_DIR" == "all/" ] || [ "$SITE_DIR" == "default/" ]; then
    return 0
  fi

  pushd "$SITES_DIR/$SITE_DIR"
    $DRUSH vset maintenance_mode 1
    $DRUSH ard
    $DRUSH vset maintenance_mode 0
  popd
}

update_single_site() {
  SITE_DIR="$1"

  if [ ! -d "$SITE_DIR" ]; then
    return 1
  fi
  if [ "$SITE_DIR" == "all/" ] || [ "$SITE_DIR" == "default/" ]; then
    return 0
  fi

  pushd "$SITES_DIR/$SITE_DIR"
    $DRUSH vset maintenance_mode 1
    $DRUSH en -y update
    $DRUSH upc
    $DRUSH updb
    $DRUSH en -y libraries l10n_update
    $DRUSH l10n-update-refresh
    $DRUSH l10n-update

    $DRUSH cron
    $DRUSH vset maintenance_mode 0
  popd
}

pushd "$SITES_DIR"
  for SITE in */ ; do
    if [ "$SITE" != "all/" ] && [ "$SITE" != "default/" ]; then
      backup_single_site "$SITE"
    fi
  done
popd

pushd "$SITES_DIR"
  for SITE in */ ; do
    if [ "$SITE" != "all/" ] && [ "$SITE" != "default/" ]; then
      update_single_site "$SITE"
    fi
  done
popd

LIBRARIES_DIR="$DRUPAL_DIR/sites/all/libraries"
if [ ! -d "$LIBRARIES_DIR" ]; then
  mkdir -p "$LIBRARIES_DIR"
fi

pushd "$LIBRARIES_DIR"
  CKEDITOR="http://download.cksource.com/CKEditor/CKEditor/CKEditor%204.4.6/ckeditor_4.4.6_full.zip"
  download_and_unpack_here "$CKEDITOR"

  pushd "ckeditor/plugins"
    TABLERESIZE="http://download.ckeditor.com/tableresize/releases/tableresize_4.4.6.zip"
    download_and_unpack_here "$TABLERESIZE"
  popd
popd



