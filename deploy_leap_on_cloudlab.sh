#!/bin/bash

if [[ $1 = "1" ]]
then
    sudo apt update

    # kernel build deps, more expls here ` https://phoenixnap.com/kb/build-linux-kernel
    sudo apt-get install -y libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
    sudo apt-get install -y git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc
    sudo apt install -y htop
    # ccache for faster builds, clang-format for vim dev
    sudo apt install -y ccache clang-format


    # mosh for ssh sanity in case of bad networks
    sudo apt install -y mosh

    # ripgrep for fast grepping in kernel code
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb
    sudo dpkg -i ripgrep_12.1.1_amd64.deb
    rm ripgrep_12.1.1_amd64.deb

    sudo mkdir -p /mydata
    # needs to be after mkextrafs.pl since the above changes ownership to root
    sudo chown $USER /mydata
    pushd /mydata
    git clone --recursive git@github.com:Ngalstyan4/oblivious.git

    # needed for rmserver compilation (fastswap far memory daemon)
    sudo apt install -y libibverbs-dev
    sudo apt install -y librdmacm-dev

    # Download Leap code
    git clone --recursive https://github.com/SymbioticLab/Leap

    # Install dependency packages (for Leap; this repeats some packages from above but some are new)
    sudo apt install -y git build-essential kernel-package fakeroot libncurses5-dev libssl-dev ccache libelf-dev libqt4-dev pkg-config ncurses-dev

    # Get the config file, uncomment unnecessary device driveres to have a faster compilation.
    # cp /boot/config-`uname -r` .config
    cp ~/oblivious-experiments/cloudlab_leap_config Leap/.config

    cd Leap

    # Clean previous make
    make mrproper

    # Compile, install headers and modules, generate grub and reboot
    make -j`nproc --all`
    sudo make headers_install
    sudo make modules_install
    sudo make install

    popd
    sudo reboot
elif [[ $1 = "2" ]]
then
    ##########################################   STAGE 2   ########################################################
    # Installing Mellanox driver

    # Leap wants Mellanox OFED 4.1
    wget https://content.mellanox.com/ofed/MLNX_OFED-4.1-1.0.2.0/MLNX_OFED_LINUX-4.1-1.0.2.0-ubuntu16.04-x86_64.tgz
    tar zxf MLNX_OFED_LINUX-4.1-1.0.2.0-ubuntu16.04-x86_64.tgz
    pushd MLNX_OFED_LINUX-4.1-1.0.2.0-ubuntu16.04-x86_64
    sudo apt-get remove -y libibmad5 libibnetdisc5 libosmcomp3
    sudo ./mlnxofedinstall --add-kernel-support
    # sudo /etc/init.d/openibd restart
    popd
    popd

    sudo reboot
elif [[ $1 = "3" ]]
then
    #sudo apt -y install libibcm1 libibverbs1 ibverbs-utils librdmacm1 rdmacm-utils ibsim-utils ibutils libcxgb3-1 libibmad5 libibumad3 libmlx4-1 libmthca1 libnes1 infiniband-diags mstflint opensm perftest srptools libibverbs-dev librdmacm-dev
    sudo apt -y install libibcm1 libibverbs1 ibverbs-utils librdmacm1 ibutils libcxgb3-1 libibmad5 libibumad3 libmlx4-1 libmthca1 libnes1 infiniband-diags mstflint opensm perftest srptools libibverbs-dev librdmacm-dev
    sudo apt -y install libmthca-dev

    sudo modprobe rdma_cm
    sudo modprobe ib_uverbs
    sudo modprobe rdma_ucm
    sudo modprobe ib_ucm
    sudo modprobe ib_umad
    sudo modprobe ib_ipoib

    sudo modprobe mlx4_ib
    sudo modprobe mlx4_en
    sudo modprobe iw_cxgb3
    sudo modprobe iw_cxgb4
    sudo modprobe iw_nes
    sudo modprobe iw_c2
else
    echo "First argument should be 1, 2, or 3"
fi
