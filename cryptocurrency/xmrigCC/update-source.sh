#!/bin/bash

if [ -d /etc/xmrigCC ]; then
    git -C /etc/xmrigCC fetch
    release="1.8.12"
else
    exit 1
fi

[ -f /etc/systemd/system/xmrigdash.service ] && {
    sudo service xmrigdash stop
}

# stop xmrigcc
[ -f /etc/systemd/system/xmrigcc.service ] && {
    sudo service xmrigcc stop*
}

##################################
# Install gcc7 or gcc8 from PPA
##################################
# gcc7 for nginx stable on Ubuntu 16.04 LTS
# gcc8 for nginx mainline on Ubuntu 16.04 LTS & 18.04 LTS

# Checking lsb_release package
if [ ! -x /usr/bin/lsb_release ]; then
    sudo apt-get -y install lsb-release | sudo tee -a /tmp/nginx-ee.log 2>&1
fi

# install gcc-7

if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-"$(lsb_release -sc)".list ]; then
    apt-get install software-properties-common -y
    add-apt-repository -y ppa:jonathonf/gcc
    apt-get update
fi
if [ ! -x /usr/bin/gcc-7 ]; then
    apt-get install gcc-7 g++-7 -y
fi
export CC="/usr/bin/gcc-7"
export CXX="/usr/bin/gc++-7"

if [ ! -d /etc/boost ]; then
    cd /etc || exit 1
    curl -sL https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.bz2 | /bin/tar xjf - -C /etc
    rm -f boost_1_67_0.tar.bz2
    mv boost_1_67_0 boost
    cd /etc/boost || exit 1
    ./bootstrap.sh --with-libraries=system
    ./b2 --toolset=gcc-7
fi

cd /etc/xmrigCC || exit 1

# get the last release
git checkout $release

# compile xmrigcc
make clean
cmake . -DCMAKE_C_COMPILER=gcc-7 -DCMAKE_CXX_COMPILER=g++-7 -DBOOST_ROOT=/etc/boost
make -j"$(nproc)"

# restart xmrigcc
sudo service xmrigcc start

if [ -f /etc/systemd/system/xmrigdash.service ]; then
    sudo service xmrigdash start
fi
