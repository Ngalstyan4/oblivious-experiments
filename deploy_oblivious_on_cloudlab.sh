#!/bin/bash

if [[ $1 = "1" ]]
then
    # note: restart between stages. Most steps are optional for remote memory server but I have usually done them to
    # just make the environment symetric
    ##########################################   STAGE 1   ########################################################
    # Installing the kernel

    # 1) add cludlab login key to github as SSH credential
    # 2) copy cloudlab.pem as ~/.ssh/id_rsa

    sudo apt update

    git clone https://github.com/Ngalstyan4/dotfiles.git
    (cd dotfiles && ./setup.sh)

    # kernel build deps, more expls here ` https://phoenixnap.com/kb/build-linux-kernel
    sudo apt-get install -y libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
    sudo apt-get install -y git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc
    sudo apt install -y htop
    # ccache for faster builds
    sudo apt install -y ccache

    # mosh for ssh sanity in case of bad networks
    sudo apt install -y mosh

    sudo apt install -y perftest infiniband-diags

    sudo mkdir /mydata
    sudo chown $USER /mydata
    sudo /usr/local/etc/emulab/mkextrafs.pl /mydata
    pushd /mydata
    git clone --recursive git@github.com:Ngalstyan4/oblivious.git

    # needed for rmserver compilation (fastswap far memory daemon)
    sudo apt-get install libibverbs-dev
    sudo apt-get install librdmacm-dev
    pushd oblivious

    # https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html
    # in this kernel, need to explicitly disable cgrou_v1 for v2 to work
    # change grub boot param to force cgroup2. done here so after kernel update below, update-grub call
    # makes this change take effect
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="cgroup_no_v2=all"/' /etc/default/grub

    time KBUILD_BUILD_HOST='dev_fastswap' KBUILD_BUILD_VERSION=44 KBUILD_BUILD_TIMESTAMP='lunchtime' make CC="ccache gcc" -j`nproc --all`
    sudo make headers_install -j12 && sudo make INSTALL_MOD_STRIP=1 modules_install -j12 && sudo make install -j4
    echo "build successfull" > ~/status.txt
    popd
    popd
elif [[ $1 = "2" ]]
then
    ##########################################   STAGE 2   ########################################################
    # Installing Mellanox driver

    # choose compatible mlx driver version ` https://www.mellanox.com/support/mlnx-ofed-matrix
    # download appropriate versioned driver ` https://www.mellanox.com/products/infiniband-drivers/linux/mlnx_ofed
    cd ~
    wget https://content.mellanox.com/ofed/MLNX_OFED-4.2-1.2.0.0/MLNX_OFED_LINUX-4.2-1.2.0.0-ubuntu16.04-x86_64.tgz
    tar zxf MLNX_OFED_LINUX-4.2-1.2.0.0-ubuntu16.04-x86_64.tgz
    pushd MLNX_OFED_LINUX-4.2-1.2.0.0-ubuntu16.04-x86_64
    sudo apt-get remove -y libibmad5 libibnetdisc5 libosmcomp3
    sudo ./mlnxofedinstall --add-kernel-support
    sudo /etc/init.d/openibd restart
    popd
elif [[ $1 = "3" ]]
then
    ##########################################   STAGE 3   ########################################################
    # Installing dev env and eval env

    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh
    source ~/.bashrc
    # todo:: there are some others, that I think I forgot. Whoever runs experiments next, please add those
    pip install jupyter numpy pandas plotly

    # download torch library for lining with torch workloads
    pushd /mydata
    wget https://download.pytorch.org/libtorch/nightly/cpu/libtorch-shared-with-deps-latest.zip
    unzip libtorch-shared-with-deps-latest.zip
    popd

    # for torch compilation
    sudo apt install -y cmake

    # set swap file
    SWAP_PATH=/mydata/swapfile
    sudo fallocate -l 10G $SWAP_PATH
    sudo chmod 600 $SWAP_PATH
    sudo mkswap $SWAP_PATH
    sudo swapon $SWAP_PATH
elif [[ $1 = "4" ]]
then
    if [[ $HOSTNAME = node0* ]]
    then
        echo never | sudo tee  /sys/kernel/mm/transparent_hugepage/enabled
        echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
        echo "aslr : $(cat /proc/sys/kernel/randomize_va_space)"
        echo "transparent huge pages: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"

        sudo ifconfig ens1f1 10.0.0.1 netmask 255.0.0.0 up
        pushd /mydata/oblivious/syncswap/drivers
        make BACKEND=RDMA
        sudo insmod fastswap_rdma.ko sport=50000 sip="10.0.0.2" cip="10.0.0.1" nq=20
        sudo insmod fastswap.ko

        sudo mkdir -p /cgroup2
        sudo mount -t cgroup2 nodev /cgroup2
        # I got this from https://unix.stackexchange.com/questions/626352/how-can-i-unmount-cgroup-version-1/626353#626353
        mount -t cgroup | cut -f 3 -d ' ' | xargs sudo umount
        echo '+memory' | sudo tee /cgroup2/cgroup.subtree_control

        echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

        sudo mkdir -p /data/traces
    elif [[ $HOSTNAME = node1* ]]
    then
        sudo ifconfig eno50 10.0.0.2 netmask 255.0.0.0 up
    fi
else
    echo "First argument should be 1, 2, 3, or 4"
fi
