#! /bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will configure, build and install a GCC cross-compiler.
# It assumes that all packages have been downloaded using download.sh before this file is run.
# Customize the variables (INSTALL_PATH, TARGET, etc.) in vars.sh to your liking before running.
# If you get an error and need to resume the script from some point in the middle,
# just delete/comment the preceding lines before running it again.
#
# See: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
#
# This script requires gnu-sed, not the normal sed that comes with OSX.  If you don't want to
# mess with the normal sed, perhaps add to the front of PATH the path to gnu-sed before you
# run this script?  e.g. export PATH=/path/to/gnu-sed-directory/bin:$PATH
#
# This script should be run in a case-sensitive partition which you can make using OSX's disk 
# utility.
#-------------------------------------------------------------------------------------------

source ./vars.sh

# extra flags and env variables are needed to get this to compile on OSX
export BUILD_ALL_BASE_DIR=`pwd`
export HOST_EXTRACFLAGS="-I$BUILD_ALL_BASE_DIR/endian"

# these are needed for gettext and assuming that it was installed using brew
export BUILD_CPPFLAGS='-I/opt/local/include'
export BUILD_LDFLAGS='-L/opt/local/lib -lintl'

# Step 1. Binutils
echo -e "\nStep 1 - building binutils...\n" && sleep 2
mkdir -p build-binutils
cd build-binutils
../$BINUTILS_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET $CONFIGURATION_OPTIONS
make $PARALLEL_MAKE
make install
cd ..

# Step 2. Linux Kernel Headers
echo -e "\nStep 2 - Linux kernel headers...\n" && sleep 2
if [ $USE_NEWLIB -eq 0 ]; then
    cd $LINUX_KERNEL_VERSION
    make V=1 ARCH=$LINUX_ARCH INSTALL_HDR_PATH=$INSTALL_PATH/$TARGET headers_install
    cd ..
fi

# Step 3. C/C++ Compilers
echo -e "\nStep 3 - C/C++ compilers...\n" && sleep 2
mkdir -p build-gcc
cd build-gcc
if [ $USE_NEWLIB -ne 0 ]; then
    NEWLIB_OPTION=--with-newlib
fi
../$GCC_VERSION/configure --prefix=$INSTALL_PATH --target=$TARGET --enable-languages=c,c++ $CONFIGURATION_OPTIONS $NEWLIB_OPTION
make $PARALLEL_MAKE gcc_cv_libc_provides_ssp=yes all-gcc
make install-gcc
cd ..

if [ $USE_NEWLIB -ne 0 ]; then
    # Steps 4-6: Newlib
    echo -e "\nSteps 4-6 - newlib...\n" && sleep 2
    mkdir -p build-newlib
    cd build-newlib
    ../newlib-master/configure --prefix=$INSTALL_PATH --target=$TARGET $CONFIGURATION_OPTIONS
    make $PARALLEL_MAKE
    make install
    cd ..
else
    # Step 4. Standard C Library Headers and Startup Files
    echo -e "\nStep 4 - standard lib headers...\n" && sleep 2
    mkdir -p build-glibc
    cd build-glibc
    ../$GLIBC_VERSION/configure --prefix=$INSTALL_PATH/$TARGET --build=$MACHTYPE --host=$TARGET --target=$TARGET --with-headers=$INSTALL_PATH/$TARGET/include $CONFIGURATION_OPTIONS libc_cv_forced_unwind=yes
    make install-bootstrap-headers=yes install-headers
    make $PARALLEL_MAKE csu/subdir_lib
    install csu/crt1.o csu/crti.o csu/crtn.o $INSTALL_PATH/$TARGET/lib
    $TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $INSTALL_PATH/$TARGET/lib/libc.so
    touch $INSTALL_PATH/$TARGET/include/gnu/stubs.h
    cd ..

    # Step 5. Compiler Support Library
    echo -e "\nStep 5 - building libgcc...\n" && sleep 2
    cd build-gcc
    make $PARALLEL_MAKE all-target-libgcc
    make install-target-libgcc
    cd ..

    # Step 6. Standard C Library & the rest of Glibc
    echo -e "\nStep 6 - standard C library and the rest of glibc...\n" && sleep 2
    cd build-glibc
    make $PARALLEL_MAKE
    make install
    cd ..
fi

# Step 7. Standard C++ Library & the rest of GCC
echo -e "\nStep 7 - building C++ library and rest of gcc\n"  && sleep 2
cd build-gcc
make $PARALLEL_MAKE all
make install
cd ..

trap - EXIT
echo 'Success!'
