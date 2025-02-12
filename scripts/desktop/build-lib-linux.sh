#!/bin/bash

set -e

function readlink() {
  echo "$(cd "$(dirname "$1")"; pwd -P)"
}

OS=linux
ARCH=${1:-`uname -a | rev | cut -d' ' -f2 | rev`}
GHC_VERSION=9.6.3

if [ "$ARCH" == "aarch64" ]; then
    COMPOSE_ARCH=arm64
else
    COMPOSE_ARCH=x64
fi

root_dir="$(dirname "$(dirname "$(readlink "$0")")")"
cd $root_dir
BUILD_DIR=dist-newstyle/build/$ARCH-$OS/ghc-${GHC_VERSION}/simplex-chat-*

rm -rf $BUILD_DIR
cabal build lib:simplex-chat --ghc-options='-optl-Wl,-rpath,$ORIGIN -flink-rts -threaded'
cd $BUILD_DIR/build
#patchelf --add-needed libHSrts_thr-ghc${GHC_VERSION}.so libHSsimplex-chat-*-inplace-ghc${GHC_VERSION}.so
#patchelf --add-rpath '$ORIGIN' libHSsimplex-chat-*-inplace-ghc${GHC_VERSION}.so
mkdir deps 2> /dev/null || true
ldd libHSsimplex-chat-*-inplace-ghc${GHC_VERSION}.so | grep "ghc" | cut -d' ' -f 3 | xargs -I {} cp {} ./deps/

cd -

rm -rf apps/multiplatform/common/src/commonMain/cpp/desktop/libs/$OS-$ARCH/
rm -rf apps/multiplatform/desktop/build/cmake

mkdir -p apps/multiplatform/common/src/commonMain/cpp/desktop/libs/$OS-$ARCH/
cp -r $BUILD_DIR/build/deps/* apps/multiplatform/common/src/commonMain/cpp/desktop/libs/$OS-$ARCH/
cp $BUILD_DIR/build/libHSsimplex-chat-*-inplace-ghc${GHC_VERSION}.so apps/multiplatform/common/src/commonMain/cpp/desktop/libs/$OS-$ARCH/
scripts/desktop/prepare-vlc-linux.sh

links_dir=apps/multiplatform/build/links
mkdir -p $links_dir
cd $links_dir
ln -sfT ../../common/src/commonMain/cpp/desktop/libs/$OS-$ARCH/ $OS-$COMPOSE_ARCH
