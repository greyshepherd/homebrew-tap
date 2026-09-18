#!/bin/bash
#
# Writes the latest published release of greyshepherd/hazmat into
# Casks/hazmat.rb: the version, and the digest of the disk image that version
# names. The new version is printed when the cask changed; nothing is printed
# when it already names it, so a caller can tell whether there is work to commit.
#
# The release is the source of truth for both values. The digest the release
# publishes is checked against the image's bytes, and the asset is checked
# against the name the cask's URL builds, so a release that carries something
# else is refused here rather than committed as a cask that installs another
# build.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASK="$ROOT/Casks/hazmat.rb"
REPO="greyshepherd/hazmat"

fail() {
    echo "error: $*" >&2
    exit 1
}

note() {
    echo "   $*" >&2
}

# The value of the one line the cask carries under this name.
cask_field() {
    local name="$1" count
    count="$(grep -c "^  $name \"" "$CASK" || true)"
    [ "$count" = "1" ] || fail "$CASK carries $count $name lines, not one"
    sed -n "s/^  $name \"\(.*\)\"\$/\1/p" "$CASK"
}

# Whether the first version is greater than the second, field by field.
is_ahead() {
    [ "$1" != "$2" ] \
        && [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | tail -1)" = "$1" ]
}

# MARK: - What the cask names

CASK_VERSION="$(cask_field version)"
CASK_SHA="$(cask_field sha256)"

# MARK: - What the release carries

RELEASE="$(gh api "repos/$REPO/releases/latest" 2>/dev/null)" \
    || fail "no published release answers for $REPO"

TAG="$(printf '%s' "$RELEASE" | jq -r '.tag_name')"
VERSION="${TAG#v}"
printf '%s' "$VERSION" | grep -Eq '^[0-9]+(\.[0-9]+)*$' \
    || fail "the latest release is tagged '$TAG', which names no version"

if [ "$VERSION" = "$CASK_VERSION" ]; then
    note "the cask already names $VERSION"
    exit 0
fi

# A cask ahead of the latest release is not this bump's to undo.
if is_ahead "$CASK_VERSION" "$VERSION"; then
    note "the cask names $CASK_VERSION, ahead of the latest release"
    exit 0
fi

# One disk image, named as the cask's URL builds it. The count arrives alone, so
# a release carrying none or several is reported with what it carried.
IMAGE="$(printf '%s' "$RELEASE" | jq -r '
    [.assets[] | select(.name | endswith(".dmg"))]
    | if length == 1 then .[0] | "\(.name) \(.browser_download_url) \(.digest // "none")"
      else "\(length)" end
')"
case "$IMAGE" in
    *" "*) read -r ASSET_NAME ASSET_URL ASSET_DIGEST <<<"$IMAGE" ;;
    *) fail "the latest release carries $IMAGE disk images, not one" ;;
esac

EXPECTED_NAME="Hazmat-$VERSION.dmg"
[ "$ASSET_NAME" = "$EXPECTED_NAME" ] \
    || fail "the release carries $ASSET_NAME, but the cask's URL names $EXPECTED_NAME"

# MARK: - The bytes the cask will name

note "hashing $ASSET_NAME"
COMPUTED_SHA="$(curl --silent --show-error --fail --location "$ASSET_URL" | shasum -a 256 | awk '{print $1}')"
printf '%s' "$COMPUTED_SHA" | grep -Eq '^[0-9a-f]{64}$' \
    || fail "the image at $ASSET_URL did not hash"

PUBLISHED_SHA="${ASSET_DIGEST#sha256:}"
if [ "$PUBLISHED_SHA" != "none" ] && [ "$PUBLISHED_SHA" != "$COMPUTED_SHA" ]; then
    fail "the release publishes $PUBLISHED_SHA for its image, but the image hashes to $COMPUTED_SHA"
fi

# MARK: - Writing those two lines, and only those

WRITTEN="$(mktemp)"
trap 'rm -f "$WRITTEN"' EXIT
awk -v version="$VERSION" -v sha="$COMPUTED_SHA" '
    /^  version "/ { print "  version \"" version "\""; next }
    /^  sha256 "/  { print "  sha256 \"" sha "\""; next }
    { print }
' "$CASK" > "$WRITTEN"

CHANGED="$(diff "$CASK" "$WRITTEN" | grep -c '^[<>]' || true)"
[ "$CHANGED" = "4" ] || fail "the cask would change in $CHANGED lines, not the two it should"

mv "$WRITTEN" "$CASK"
trap - EXIT

[ "$(cask_field version)" = "$VERSION" ] || fail "the cask does not carry $VERSION"
[ "$(cask_field sha256)" = "$COMPUTED_SHA" ] || fail "the cask does not carry the image's digest"

printf '%s\n' "$VERSION"
