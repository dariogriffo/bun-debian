![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/bun-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/bun-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/bun-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/bun-debian)

<h1>
   <p align="center">
     <a href="https://github.com/oven-sh/bun/"><img src="https://github.com/dariogriffo/bun-debian/blob/main/bun-logo.png" alt="Bun Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/bun-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>Bun for Debian
   </p>
</h1>
<p align="center">
 👻 Bun is an all-in-one toolkit for JavaScript and TypeScript apps. It ships as a single executable called bun.
</p>

# Bun for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [Bun](https://github.com/oven-sh/bun) hosted at [debian.griffo.io](https://debian.griffo.io)

Currently supported debian distros are:
- Bookworm
- Trixie
- Sid

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the Bun source code, see
[bun](https://github.com/oven-sh/bun).

## Install/Update

### The Debian way

```sh
curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list
sudo apt install bun
```

If you want you can also install bun-profile as an alternative:
```sh
sudo apt install bun-profile
```

Then chose which one you want to use as default:
```sh
sudo update-alternatives --config bun
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/bun-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Contributing

I want to have an easy-to-install Bun package for Debian, so I'm doing what
I can to make it happen.
If you want to test locally, you should be able to run
[build_bun_debian.sh](https://github.com/dariogriffo/bun-debian/blob/main/build_bun_debian.sh)
on your own Debian system, only requirement is docker.

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates

## Disclaimer

- This repo is not open for issues related to bun. This repo is only for _unofficial_ Debian packaging.
- This repository is based on the amazing work of [Mike Kasberg](https://github.com/mkasberg) and his [Bun Ubuntu](https://github.com/mkasberg/ghostty-ubuntu) packages
