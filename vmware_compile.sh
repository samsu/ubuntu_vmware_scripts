#!/usr/bin/env bash

#vmware version
vmware=$1
vmware=${vmware:-'workstation-17.0.2'}
# compile the missing modules
codes=$2
codes=${codes:-'/home/samsu/workshop/codes'}

function _help {
cat << EOM
After upgrading the Ubuntu kernel, you may encounter an error with VMware Workstation
 or VMware Player that states: 'the module vmmon is not found or not loaded.'
To resolve this issue, this script automates the process of recompiling the vmmon and vmnet modules.

Usage:
vmware.sh [VMware Workstation|Player version] [Path to download VMware host modules]

Example:
sudo bash vmware.sh workstation-17.0.2 /tmp

EOM
    exit 1
}

if [[ ! -d "$codes" ]]; then
    _help
fi

# update and upgrade installed libs/modules to the latest
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git

repo='vmware-host-modules'

set -x
echo -e "download compile the modules: vmmon and vmnet\n"
if [[ -d "$codes/$repo" ]]; then
    cd "$codes/$repo"
    rm -rf vmnet-only vmmon-only
    git checkout .
    git remote update
else
    cd "$codes"
    git clone "https://github.com/mkubecek/$repo"
    cd "$repo"
fi


if ! git checkout $vmware; then
    echo -e "\nError: cannot find the version: '$vmware'\n"
    _help
fi
git pull

set -x


if diff /sys/kernel/btf/vmlinux /usr/lib/modules/`uname -r`/build/vmlinux; then
    sudo cp /sys/kernel/btf/vmlinux /usr/lib/modules/`uname -r`/build/
fi

#sudo make
sudo make && sudo make install

#sign complied VMware modules if security boot enabled
mokutil --sb-state | grep enabled
_new_key=false
if mokutil --sb-state | grep enabled; then
    if [[ ! -f $codes/MOK.der ]]; then
      # Generate a key pair using the openssl to sign vmmon and vmnet modules
      openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=VMware/"
      _new_key=true
    fi
    for modfile in $(modinfo -n vmmon vmnet); do
        echo "Signing $modfile"
        sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 $codes/MOK.priv $codes/MOK.der "$modfile"
    done
fi

# check whether missing any libs
libs=$(sudo ldd /usr/sbin/vmware-authdlauncher |grep 'not found'|awk '{print $1}')

if [ ! -z "$libs" ]; then
    # fix the errors which cannot find libs
    lib_path="/etc/ld.so.conf.d/"
    lib_conf="vmware-authdlauncher.conf"
    # update the path for missing libs
    > "/tmp/$lib_conf"
    for lib in $libs; do
        echo "/usr/lib/vmware/lib/$lib" >> "/tmp/$lib_conf"
    done
    sudo mv "/tmp/$lib_conf" "$lib_path$lib_conf"
    # update the config
    sudo ldconfig
fi

if [[ "$_new_key" == true ]]; then
    echo "# 1. import the public key to the system's MOK(Machine Owner Key) list"
    echo "#    and set a password for this MOK enrollment request"
    echo "# 2. reboot and add it into bios"
    mokutil --import MOK.der
fi

sudo systemctl restart vmware
sudo systemctl status vmware
