BUN_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("jammy" "noble")
for i in "${arr[@]}"
do
  UBUNTU_DIST=$i
  FULL_VERSION=$BUN_VERSION-${BUILD_VERSION}+${UBUNTU_DIST}_amd64_ubu

  mkdir one
  cd one
  wget https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64.zip
  unzip bun-linux-x64.zip
  cd ..

  mv one/bun-linux-x64/bun .
  ls -la

  docker build . -f one_Dockerfile.ubu -t bun-ubuntu-$UBUNTU_DIST --build-arg BUN_VERSION=$BUN_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create bun-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/bun-one_$FULL_VERSION.deb - > ./bun-one_$FULL_VERSION.deb
  tar -xf ./bun-one_$FULL_VERSION.deb

  rm -fRd one
  rm -f bun

  mkdir profile
  cd profile
  wget https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64-profile.zip
  unzip bun-linux-x64-profile.zip
  cd ..
  mv profile/bun-linux-x64-profile/bun-profile .
  mv profile/bun-linux-x64-profile/bun-profile.linker-map .
  mv bun-profile bun
  mv bun-profile.linker-map bun.linker-map

  docker build . -f profile_Dockerfile.ubu -t bun-ubuntu-$UBUNTU_DIST --build-arg BUN_VERSION=$BUN_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create bun-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/bun-profile_$FULL_VERSION.deb - > ./bun-profile_$FULL_VERSION.deb
  tar -xf ./bun-profile_$FULL_VERSION.deb

  rm -fRd profile
  rm -f bun
  rm -f bun.linker-map

  docker build . -f meta_Dockerfile.ubu -t bun-ubuntu-$UBUNTU_DIST --build-arg BUN_VERSION=$BUN_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create bun-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/bun_$FULL_VERSION.deb - > ./bun_$FULL_VERSION.deb
  tar -xf ./bun_$FULL_VERSION.deb

done
