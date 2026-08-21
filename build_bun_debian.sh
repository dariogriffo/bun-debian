#!/bin/bash
BUN_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$BUN_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <bun_version> <build_version> [architecture]"
    echo "Example: $0 1.4.0 1 arm64"
    echo "Example: $0 1.4.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

UPSTREAM_URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}"

# Map a Debian architecture to the slug upstream uses in its asset names.
# Both Linux builds are glibc builds needing GLIBC_2.17 at most, so they run
# on every suite we target. Upstream publishes no armhf, i386 or riscv64
# binaries; the musl builds are for Alpine and are not packaged here.
get_bun_slug() {
    case "$1" in
        "amd64") echo "x64" ;;
        "arm64") echo "aarch64" ;;
        *)       echo "" ;;
    esac
}

# The completion scripts live in the source tree, not in the release assets,
# and are architecture independent.
fetch_completions() {
    if [ -s completions/bun.bash ] && [ -s completions/bun.fish ] && [ -s completions/bun.zsh ]; then
        echo "Using existing completions/"
        return 0
    fi

    echo "Downloading completions for bun-v${BUN_VERSION}..."
    rm -rf completions || true
    mkdir -p completions

    for f in bun.bash bun.fish bun.zsh; do
        if ! wget -q -O "completions/$f" \
            "https://raw.githubusercontent.com/oven-sh/bun/bun-v${BUN_VERSION}/completions/$f"; then
            echo "❌ Failed to download completions/$f"
            return 1
        fi
        if [ ! -s "completions/$f" ]; then
            echo "❌ completions/$f is empty"
            return 1
        fi
    done
    echo "✅ Completions downloaded"
}

# Stage one .deb built from a Dockerfile, then unpack the docker cp tar stream
# over itself so the file left behind is the .deb rather than the stream.
build_package() {
    local pkg=$1 dockerfile=$2 dist=$3 build_arch=$4 full_version=$5

    if ! docker build . -f "$dockerfile" -t "bun-$dist-$build_arch" \
        --build-arg BUN_VERSION="$BUN_VERSION" \
        --build-arg DEBIAN_DIST="$dist" \
        --build-arg BUILD_VERSION="$BUILD_VERSION" \
        --build-arg FULL_VERSION="$full_version" \
        --build-arg ARCH="$build_arch"; then
        echo "❌ Failed to build $pkg image for $dist on $build_arch"
        return 1
    fi

    local id
    id="$(docker create "bun-$dist-$build_arch")"
    if ! docker cp "$id:/${pkg}_${full_version}.deb" - > "./${pkg}_${full_version}.deb"; then
        echo "❌ Failed to extract ${pkg} .deb for $dist on $build_arch"
        return 1
    fi
    if ! tar -xf "./${pkg}_${full_version}.deb"; then
        echo "❌ Failed to extract ${pkg} .deb contents for $dist on $build_arch"
        return 1
    fi
}

build_architecture() {
    local build_arch=$1
    local slug

    slug=$(get_bun_slug "$build_arch")
    if [ -z "$slug" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    echo "Building for architecture: $build_arch using bun-linux-$slug"

    # Download each architecture once, not once per suite: the release zips are
    # around 100 MB each.
    rm -rf "dist/$build_arch" || true
    mkdir -p "dist/$build_arch/one" "dist/$build_arch/profile"

    if ! wget -q "${UPSTREAM_URL}/bun-linux-${slug}.zip" -O "dist/$build_arch/one/bun.zip"; then
        echo "❌ Failed to download bun-linux-${slug}.zip"
        return 1
    fi
    (cd "dist/$build_arch/one" && unzip -qo bun.zip && mv "bun-linux-${slug}/bun" . \
        && rm -rf "bun-linux-${slug}" bun.zip) || return 1

    if ! wget -q "${UPSTREAM_URL}/bun-linux-${slug}-profile.zip" -O "dist/$build_arch/profile/bun.zip"; then
        echo "❌ Failed to download bun-linux-${slug}-profile.zip"
        return 1
    fi
    (cd "dist/$build_arch/profile" && unzip -qo bun.zip \
        && mv "bun-linux-${slug}-profile/bun-profile" bun \
        && mv "bun-linux-${slug}-profile/bun-profile.linker-map" bun.linker-map \
        && rm -rf "bun-linux-${slug}-profile" bun.zip) || return 1

    for f in "dist/$build_arch/one/bun" "dist/$build_arch/profile/bun" \
             "dist/$build_arch/profile/bun.linker-map"; do
        if [ ! -s "$f" ]; then
            echo "❌ Unexpected archive layout for $build_arch (missing $f)"
            return 1
        fi
    done

    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$BUN_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        build_package bun-one one_Dockerfile "$dist" "$build_arch" "$FULL_VERSION" || return 1
        build_package bun-profile profile_Dockerfile "$dist" "$build_arch" "$FULL_VERSION" || return 1
        # bun: the meta package pointing at bun-one
        build_package bun meta_Dockerfile "$dist" "$build_arch" "$FULL_VERSION" || return 1
    done

    rm -rf "dist/$build_arch" || true
    echo "✅ Successfully built for $build_arch"
    return 0
}

if ! fetch_completions; then
    exit 1
fi

if [ "$ARCH" = "all" ]; then
    echo "🚀 Building bun $BUN_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la bun_*.deb bun-one_*.deb bun-profile_*.deb
else
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
