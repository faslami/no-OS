#!/bin/bash
# Copyright 2023(c) Analog Devices, Inc.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#     - Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     - Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     - Neither the name of Analog Devices, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#     - The use of this software may or may not infringe the patent rights
#       of one or more patent holders.  This license does not release you
#       from the requirement that you obtain separate licenses from these
#       patent holders to use this software.
#     - Use of the software either in source or binary form, must be run
#       on or directly connected to an Analog Devices Inc. component.
#
# THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED.
#
# IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
# RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#List of excluded driver folders for the documentation generation.

set -e

sudo apt-get update

TOP_DIR="$(pwd)"
DEPS_DIR="${TOP_DIR}/deps"

. ./ci/lib.sh

build_astyle() {
    . ./ci/astyle.sh
}

build_cppcheck() {
    . ./ci/cppcheck.sh
}

build_drivers() {
    sudo apt-get install gcc-arm-none-eabi libnewlib-arm-none-eabi
    git submodule update --init libraries/iio/libtinyiiod
    make -C ./drivers -f Makefile -j
}

build_doxygen() {
    sudo apt-get install -y graphviz python3-sphinx
    # Install a recent version of doxygen
	DOXYGEN_URL="https://sourceforge.net/projects/doxygen/files/rel-1.8.17/doxygen-1.8.17.src.tar.gz/"
	mkdir -p "${DEPS_DIR}"
	cd ${DEPS_DIR}
	[ -d "doxygen" ] || {
		mkdir doxygen && wget --quiet -O - ${DOXYGEN_URL} | tar --strip-components=1 -xz -C doxygen
	}

    # Install Doxygen
    cd doxygen
    patch ./src/docparser.cpp < ${TOP_DIR}/ci/patch_doxy.patch
    mkdir -p build && cd build
    cmake ..
    make -j${NUM_JOBS}
    sudo make install
    cd ../..

    #Generate *.dox files for drivers and projects
    . ${TOP_DIR}/ci/gen_dox.sh

    # Build Documentation
    cd ${TOP_DIR}/doc/doxygen
    mkdir -p build && cd build
    cmake ..
    cd ../../..

    . ./ci/doxygen.sh
}

build_${BUILD_TYPE}
