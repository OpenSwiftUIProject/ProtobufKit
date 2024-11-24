#!/bin/bash

# A `realpath` alternative using the default C implementation.
filepath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PACKAGE_ROOT="$(dirname $(dirname $(filepath $0)))"

UPSTREAM_REPO_URL="https://github.com/OpenSwiftUIProject/OpenSwiftUI"
UPSTREAM_COMMIT_HASH="2bb0f9d626f04ea193b2a377282455657fdfc909"

REPO_DIR="$PACKAGE_ROOT/.repos/OpenSwiftUI"
PATCHES_DIR="$PACKAGE_ROOT/Patches"

SOURCE_DIR="$REPO_DIR/Sources/OpenSwiftUICore/Data/Protobuf"
SOURCE_DES="$PACKAGE_ROOT/Sources/ProtobufKit"

TEST_DIR="$REPO_DIR/Tests/OpenSwiftUICoreTests/Data/Protobuf"
TEST_DEST="$PACKAGE_ROOT/Tests/ProtobufKitTests"

rm -rf $REPO_DIR

git clone $UPSTREAM_REPO_URL $REPO_DIR
cd $REPO_DIR
git -c advice.detachedHead=false checkout $UPSTREAM_COMMIT_HASH

cd $PACKAGE_ROOT

if [ -d "$PATCHES_DIR" ]; then
    for patch in $(ls $PATCHES_DIR/*.patch | sort); do
        [ -e "$patch" ] || continue
        echo "Applying patch $patch"
        git -C $REPO_DIR apply $patch -3
    done
fi

mkdir -p $SOURCE_DES
cp -r $SOURCE_DIR/* $SOURCE_DES/

mkdir -p $TEST_DEST
cp -r $TEST_DIR/* $TEST_DEST/
