#!/bin/bash
set -euo pipefail

BUN_VERSION=$1
BUILD_VERSION=$2

if [ -z "$BUN_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <bun_version> <build_version>"
    echo "Example: $0 1.2.23 1"
    exit 1
fi

PACKAGE_NAME="bun"
ORIG_TARBALL="${PACKAGE_NAME}_${BUN_VERSION}.orig.tar.gz"
BUILD_DIR="${PACKAGE_NAME}-${BUN_VERSION}"

echo "Creating Debian/Ubuntu source packages for bun ${BUN_VERSION}-${BUILD_VERSION}..."

# Download upstream source tarball (shared .orig.tar.gz across all distributions)
# GitHub archive of tag "bun-v{VERSION}" extracts to "bun-bun-v{VERSION}/" directory
# We rename it to bun-{VERSION}/ as dpkg-source expects
if [ ! -f "$ORIG_TARBALL" ]; then
    echo "Downloading upstream source from GitHub..."
    UPSTREAM_TAG="bun-v${BUN_VERSION}"
    UPSTREAM_DIR="bun-${UPSTREAM_TAG}"
    wget -q "https://github.com/oven-sh/bun/archive/refs/tags/${UPSTREAM_TAG}.tar.gz" -O "${UPSTREAM_DIR}.tar.gz"
    # Re-pack to match expected directory name bun-{VERSION}
    tar -xf "${UPSTREAM_DIR}.tar.gz"
    mv "${UPSTREAM_DIR}" "${BUILD_DIR}"
    tar -czf "$ORIG_TARBALL" "${BUILD_DIR}"
    rm -rf "${BUILD_DIR}" "${UPSTREAM_DIR}.tar.gz"
    echo "  Downloaded and repacked as $ORIG_TARBALL"
else
    echo "  Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local dist=$1
    local FULL_VERSION="${BUN_VERSION}-${BUILD_VERSION}~${dist}"

    echo "  Building source package for ${dist} (${FULL_VERSION})..."

    # Clean and recreate build directory from orig tarball
    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"

    # Copy Debian packaging directory
    cp -r debian "$BUILD_DIR/"

    # Generate distribution-specific changelog (overwrites placeholder)
    cat > "$BUILD_DIR/debian/changelog" << EOF
bun (${FULL_VERSION}) ${dist}; urgency=medium

  * New upstream release ${BUN_VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    # Build source package (.dsc + .debian.tar.xz); reuses existing .orig.tar.gz
    dpkg-source -b "$BUILD_DIR"

    rm -rf "$BUILD_DIR"
    echo "    ${FULL_VERSION}"
}

echo ""
echo "Building Debian source packages..."
DEBIAN_DISTS=("bookworm" "trixie" "forky" "sid")
for dist in "${DEBIAN_DISTS[@]}"; do
    build_source_package "$dist"
done

echo ""
echo "Building Ubuntu source packages..."
UBUNTU_DISTS=("jammy" "noble")
for dist in "${UBUNTU_DISTS[@]}"; do
    build_source_package "$dist"
done

echo ""
echo "Source packages created successfully!"
echo ""
echo "Generated files:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true
