# bsrv-debian
This Repository contains a Makefile to build `.deb` packages for [bsrv](https://github.com/alx-g/bsrv) for installation on debian-based systems.

# Installation

Clone this repository, then run

```bash
make install
```

in this folder to download and install the latest version of [bsrv](https://github.com/alx-g/bsrv). This will build `.deb` packages and install them including all dependencies using `apt`.
This will also install the tray icon including a Qt5 dependency.

If you wish to only install the service and cli, run

```bash
make install-noqt
```
