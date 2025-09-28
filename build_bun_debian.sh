BUN_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("bookworm" "trixie" "forky" "sid")
for i in "${arr[@]}"
do
  
  DEBIAN_DIST=$i
  FULL_VERSION=$BUN_VERSION-${BUILD_VERSION}+${DEBIAN_DIST}_amd64

  mkdir one
  cd one
  wget https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64.zip
  unzip bun-linux-x64.zip
  cd ..
  
  mv one/bun-linux-x64/bun .
  ls -la
  
  docker build . -t bun-$DEBIAN_DIST --build-arg BUN_VERSION=$BUN_VERSION --build-arg DEBIAN_DIST=$DEBIAN_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION -f one_Dockerfile
  id="$(docker create bun-$DEBIAN_DIST)"
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
  
  docker build . -t bun-$DEBIAN_DIST --build-arg BUN_VERSION=$BUN_VERSION --build-arg DEBIAN_DIST=$DEBIAN_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION -f profile_Dockerfile
  id="$(docker create bun-$DEBIAN_DIST)"
  docker cp $id:/bun-profile_$FULL_VERSION.deb - > ./bun-profile_$FULL_VERSION.deb
  tar -xf ./bun-profile_$FULL_VERSION.deb
  
  rm -fRd profile
  rm -f bun
  rm -f bun.linker-map
  
  docker build . -t bun-$DEBIAN_DIST --build-arg BUN_VERSION=$BUN_VERSION --build-arg DEBIAN_DIST=$DEBIAN_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION -f meta_Dockerfile
  id="$(docker create bun-$DEBIAN_DIST)"
  docker cp $id:/bun_$FULL_VERSION.deb - > ./bun_$FULL_VERSION.deb
  tar -xf ./bun_$FULL_VERSION.deb

done
