#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
echo "SCRIPT_DIR $SCRIPT_DIR"

cd $SCRIPT_DIR
GITCOMMIT="$(git rev-parse HEAD)"
echo $GITCOMMIT

# Fetch the Build-PowerShell-DSC-for-Linux repository for dependencies to build from
git config --global 'url.https://github.com/.insteadOf' 'git@github.com:'
git clone --recursive 'https://github.com/Microsoft/Build-PowerShell-DSC-for-Linux.git' "$SCRIPT_DIR/bld-dsc"

echo "Changind directories"
# Master branch for all submodules
cd "$SCRIPT_DIR/bld-dsc"

git submodule foreach git checkout master
echo "Submodules checkouted"

# Patch in the version of PowerShell-DSC-for-Linux that Travis gave to us
PS_DIR="$SCRIPT_DIR/bld-dsc"
DSC_DIR=$(cd $PS_DIR/dsc; pwd -P)
OMI_ROOT=$(cd $PS_DIR/omi/Unix; pwd -P)

echo $PS_DIR
echo $DSC_DIR
echo $OMI_ROOT

cd $DSC_DIR
git checkout $GITCOMMIT

# BUILD default DSC 
cd ${DSC_DIR}/build
./configure --noenable-ulinux
make local
cd ../omi*
sudo make install
cd ../
sudo make reg
  # Build DSC for OMS
  #- docker pull abenbachir/oms-centos6-x64:latest || true
  # - docker run --rm -t -v ${PS_DIR}:/OMS abenbachir/oms-centos6-x64:latest /bin/sh -c "cd /OMS/omi/Unix; ./configure --enable-microsoft --enable-ulinux; make all"
  # - docker run --rm -t -v ${PS_DIR}:/OMS abenbachir/oms-centos6-x64:latest /bin/sh -c "cd /OMS/dsc; ./configure --oms; ln -fs /OMS/omi/Unix /OMS/dsc/omi-1.0.8; cd /OMS/omi/Unix; rm -rf output; ln -s output_openssl_1.0.0 output"
  # - docker run --rm -t -v ${PS_DIR}:/OMS abenbachir/oms-centos6-x64:latest /bin/sh -c "cd /OMS/omi/Unix; make -C /OMS/dsc dsc100"
  # - docker run --rm -t -v ${PS_DIR}:/OMS abenbachir/oms-centos6-x64:latest /bin/sh -c "cd /OMS/omi/Unix; make -C /OMS/dsc dsckit100"
  # - docker run --rm -t -v ${PS_DIR}:/OMS abenbachir/oms-centos6-x64:latest /bin/sh -c "cd /OMS/dsc; make distclean"
# Python tests for 2.6x-2.7x
cd /opt/omi-*/share/dsc/Scripts/2.6x-2.7x/Scripts/Tests/
sudo python ./test_nxProviders.py 2> /dev/null

# Python tests for 3.x
cd /opt/omi-*/share/dsc/Scripts/3.x/Scripts/Tests/
sudo python3 ./test_nxProviders.py 2> /dev/null

# Python tests for 2.4x-2.5x
cd /tmp
wget -q https://www.python.org/ftp/python/2.4.6/Python-2.4.6.tgz
tar -xzf Python-2.4.6.tgz
cd Python-2.4.6
./configure  &> /dev/null
sed -i "s/#zlib/zlib/" Modules/Setup
sed -i "s/#_socket/_socket/" Modules/Setup
sed -i "s/#_ssl _ssl/_ssl _ssl/" Modules/Setup
sed -i "s/#\t-DUSE_SSL/\t-DUSE_SSL/" Modules/Setup
sed -i "s/#\t-L\$(SSL)/\t-L\$(SSL)/" Modules/Setup
sed -i "s/#md5/md5/" Modules/Setup
sed -i "s/#sha/sha/" Modules/Setup
make &> /dev/null
sudo make altinstall &> /dev/null
cd ..
wget -q https://sourceforge.net/projects/ctypes/files/ctypes/1.0.2/ctypes-1.0.2.tar.gz
tar -xzf ctypes-1.0.2.tar.gz
cd ctypes-1.0.2
sudo python2.4 ./setup.py build install &> /dev/null
cd /opt/omi-*/share/dsc/Scripts/2.4x-2.5x/Scripts/Tests/
sudo python2.4 ./test_nxProviders.py 2> /dev/null