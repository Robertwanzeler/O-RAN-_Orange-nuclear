#!/usr/bin/env bash
set -u

cat <<'COMMANDS'
# Este script apenas imprime comandos. Nada será executado.

export ORAN_DEBUG_ROOT="$HOME/orange_nuclear_debug_runtime"
mkdir -p "$ORAN_DEBUG_ROOT"
cd "$ORAN_DEBUG_ROOT"

sudo apt update
sudo apt install -y git g++ cmake ninja-build build-essential \
  libgsl-dev libxml2-dev libsctp-dev autoconf automake libtool \
  libboost-all-dev python3 python3-dev python3-pip \
  libsqlite3-dev libeigen3-dev gdb valgrind pkg-config

git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git flexric
cd flexric
git checkout oie-ric-taap-xapps
sed -i 's/# add_subdirectory(examples)/add_subdirectory(examples)/g' CMakeLists.txt
sed -i 's/add_subdirectory(xApp)/# add_subdirectory(xApp)/g' examples/CMakeLists.txt
mkdir build
cd build
cmake .. -DE2AP_VERSION=E2AP_V1 -DKPM_VERSION=KPM_V3_00 -G Ninja
ninja
sudo ninja install
sudo ldconfig

cd "$ORAN_DEBUG_ROOT"
git clone https://github.com/Orange-OpenSource/ns-O-RAN-flexric.git ns-O-RAN-flexric
cd ns-O-RAN-flexric
git submodule update --init --recursive
cd mmwave-LENA-oran
./ns3 clean
./ns3 configure --disable-examples --disable-tests \
  --enable-modules=nr,mmwave,oran-interface,lte,energy
./ns3 build -j"$(nproc)"

# Terminal 1
cd "$ORAN_DEBUG_ROOT/flexric/build/examples/ric"
./nearRT-RIC

# Terminal 2
cd "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric/mmwave-LENA-oran"
./ns3 run scratch/scenario-zero-with_parallel_loging
COMMANDS
