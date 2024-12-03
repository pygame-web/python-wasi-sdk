*#!/bin/bash

export SDKROOT=${SDKROOT:-/tmp/sdk}

pushd ${SDKROOT}
    . ${CONFIG:-config}
    . wasm32-bi-emscripten-shell.sh
popd

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > getrust
bash ./getrust -y -t wasm32-unknown-unknown --default-toolchain nightly

. $SDKROOT/rust/env


rustup target add wasm32-unknown-unknown
rustup target add wasm32-unknown-emscripten
rustup target add wasm32-wasip1

# error on crate `time` caused by an API change in Rust 1.80.0; update `time` to version `>=0.3.35`
# LLVM_CONFIG_PATH=${SDKROOT}/wasisdk/upstream/bin/llvm-config cargo install c2rust


