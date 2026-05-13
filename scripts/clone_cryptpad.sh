#!/bin/bash

# Commit hash to checkout (single source of truth)
CRYPTPAD_COMMIT="e7bdaa0b08fa6bd798dc0877d5dd907911ef058d"

# Clone cryptpad repository
rm -rf cryptpad
# TODO: switch to upstream cryptpad once https://github.com/cryptpad/cryptpad/pull/2051 is merged
git clone --depth 1 https://github.com/Scille/cryptpad.git --single-branch --no-checkout cryptpad_tmp
mkdir -p cryptpad
mv cryptpad_tmp/.git cryptpad/.git
rmdir cryptpad_tmp
pushd cryptpad
git fetch --depth 1 origin $CRYPTPAD_COMMIT
git checkout -f $CRYPTPAD_COMMIT
rm -rf .git
popd
