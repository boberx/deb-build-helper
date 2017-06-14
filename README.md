# deb-build-helper
# Description
Helper tool for building Debian packages  
It is a wrong way to building Debian packages, but I'm so used to it  
# How to use
1. The best way to build your package's is in a clean chroot environment
 * Install the required packages

      ```sh
      apt-get install coreutils bash debootstrap
      ```
 * Setting up a chroot (example for debian jessie)

      ```sh
      CHROOTDIR="/storage/jessie-chroot_amd64"; LC="ru_RU.UTF-8";
      mkdir -p "${CHROOTDIR}" && \
      debootstrap --arch=amd64 --variant=minbase --include=locales,apt-utils,dialog,findutils,file,sed,gawk,bzip2 \
        jessie "${CHROOTDIR}" http://mirror.mephi.ru/debian/ && \
      echo "LANG="${LC}"" > "${CHROOTDIR}"/etc/default/locale && \
      sed -i 's/# "${LC}" UTF-8/"${LC}" UTF-8/' "${CHROOTDIR}"/etc/locale.gen && \
      chroot "${CHROOTDIR}" /bin/bash -c "su - -c \"locale-gen\"";
      ```
2. Creating a new directory for the package
    ```sh
    mkdir "${CHROOTDIR}"/package_name;
    ```
3. This helper script should be is in the same directory as the config files
    ```sh
    cp build_package.sh "${CHROOTDIR}"/package_name;
    ```
4. Create package configurations files

    ```sh
    cd "${CHROOTDIR}"/package_name;
    ```
    Run, and then follow the instructions

    ```sh
    ./build_package.sh -a
    ```
5. Edit configuration files using text editor
 1. The main configuration file is `build_config.sh` Configuration file options  
     `APP_PCKG_MAINTAINER` The package's maintainer name and email address  
     `APP_DEB_PCKG` list of packages to build  
     `APP_SRC_ARCH`  
     `APP_SRC_DIR`  
     `APP_VERSION`  The version number of a package  
     `APP_REQ_PCKGAV`  
     `APP_CFG_OPTS`  
     `APP_CFLAGS`  
     `APP_HOMEPAGE` The URL of the web site for this package  
 2. Package configuration files is `build_config_packagename.sh` Configuration file options  
    `APP_DEB_PCKG_packagename_DESCRIPTION`  
    `APP_DEB_PCKG_packagename_ARCH` Architecture
    `APP_DEB_PCKG_packagename_DEPENDS`  
6. Enter the chroot environment to begin building

    ```sh
    chroot "${CHROOTDIR}";
    ```
7. Building Debian package

    ```sh
    cd package_name
    ```
    ```sh
    ./build_package.sh
    ```
