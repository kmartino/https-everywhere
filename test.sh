#!/bin/bash -ex
cd "`dirname $0`"

# dummy Jetpack addon that contains tests
TEST_ADDON_PATH=./https-everywhere-tests/
LATEST_SDK_VERSION=1.16

# We'll create a Firefox profile here and install HTTPS Everywhere into it.
PROFILE_DIRECTORY="$(mktemp -d)"
trap 'rm -r "$PROFILE_DIRECTORY"' EXIT
HTTPSE_INSTALL_DIRECTORY=$PROFILE_DIRECTORY/extensions/https-everywhere@eff.org

# Build the XPI to run all the validations in makexpi.sh, and to ensure that
# we test what is actually getting built.
./makexpi.sh
XPI_NAME="pkg/`ls -tr pkg/ | tail -1`"

# Set up a skeleton profile and then install into it.
# The skeleton contains a few files required to trick Firefox into thinking
# that the extension was fully installed rather than just unpacked.
rsync -a https-everywhere-tests/test_profile_skeleton/ $PROFILE_DIRECTORY
unzip -qd $HTTPSE_INSTALL_DIRECTORY $XPI_NAME

die() {
  echo "$@"
  exit 1
}

if [ ! -f "addon-sdk/bin/activate" ]; then
  die "Addon SDK not available. Run git submodule update."
fi

if [ ! -d "$HTTPSE_INSTALL_DIRECTORY" ]; then
  die "Firefox profile does not have HTTPS Everywhere installed"
fi

# Activate the Firefox Addon SDK.
pushd addon-sdk
source bin/activate
popd

if ! type cfx > /dev/null; then
  die "Addon SDK failed to activiate."
fi

if ! cfx --version | grep -q "$LATEST_SDK_VERSION"; then
  die "Please use the latest stable SDK version or edit this script to the current version."
fi

cd $TEST_ADDON_PATH

# If you just want to run Firefox with the latest code:
if [ "$1" == "--justrun" ]; then
  echo "running firefox"
  firefox -no-remote -profile "$PROFILE_DIRECTORY" "$@"
else
  echo "running tests"
  cfx test --profiledir="$PROFILE_DIRECTORY" --verbose
fi
