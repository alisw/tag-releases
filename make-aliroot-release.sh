#!/bin/sh -e
# Create a release based on the configuration file passed
# as a first argument.
CONFIG=$1
if [ "X$1" = X ]; then
  echo "Please provide configuration file as first argument"
  exit 1
fi

. $CONFIG

require() {
  VAR=
  eval "VAR=\$${1}"
  if [ "X$VAR" = X ]; then
    echo $1 required in config file
    exit 1
  fi
  echo $1:$VAR
}

ALIROOT_UPSTREAM=${ALIROOT_UPSTREAM:-https://github.com/alisw/AliRoot }
ALIPHYSICS_UPSTREAM=${ALIPHYSICS_UPSTREAM:-https://github.com/alisw/AliPhysics}
OLD_ALIPHYSICS=${OLD_ALIPHYSICS:-$OLD_ALIROOT-01}
NEW_ALIPHYSICS=${NEW_ALIPHYSICS:-$NEW_ALIROOT-01}
MIRROR_DIR=${MIRROT_DIR:-mirror}

require OLD_ALIROOT
require NEW_ALIROOT
require OLD_ALIPHYSICS
require NEW_ALIPHYSICS
require ALIROOT_UPSTREAM
require ALIPHYSICS_UPSTREAM
require MIRROR_DIR

set -x
mkdir -p $MIRROR_DIR
[ -d $MIRROR_DIR/AliRoot ] || git clone --mirror https://github.com/alisw/AliRoot $MIRROR_DIR/AliRoot
[ -d $MIRROR_DIR/AliPhysics ] || git clone --mirror https://github.com/alisw/AliPhysics $MIRROR_DIR/AliPhysics
GIT_DIR=$MIRROR_DIR/AliRoot git fetch
GIT_DIR=$MIRROR_DIR/AliPhysics git fetch

export WORKDIR=$PWD
rm -rf $WORKDIR/AliRoot $WORKDIR/AliPhysics
# Create a tag for AliRoot
git clone -b $OLD_ALIROOT $MIRROR_DIR/AliRoot $WORKDIR/AliRoot
cd $WORKDIR/AliRoot
git reset --hard $OLD_ALIROOT
[ ! "X$ALIROOT_CHERRY_PICKS" = "X" ] && git cherry-pick $ALIROOT_CHERRY_PICKS
git tag $NEW_ALIROOT
git log -n 10

# Create a tag for AliPhysics
git clone -b $OLD_ALIPHYSICS $MIRROR_DIR/AliPhysics $WORKDIR/AliPhysics
cd $WORKDIR/AliPhysics
git reset --hard $OLD_ALIPHYSICS
[ ! "X$ALIPHYSICS_CHERRY_PICKS" = "X" ] && git cherry-pick $ALIPHYSICS_CHERRY_PICKS
git tag $NEW_ALIPHYSICS
git log -n 10

cd $WORKDIR
if [ "X$PUSH_TAGS" = X ]; then
  exit 0
fi

set +x
echo GIT_DIR=$WORKDIR/AliRoot/.git git push $FORCE $ALIROOT_UPSTREAM $NEW_ALIROOT
echo GIT_DIR=$WORKDIR/AliPhysics/.git git push $FORCE $ALIPHYSICS_UPSTREAM $NEW_ALIPHYSICS
