#!/bin/sh
set -e

# Options
BOOTSTRAP_OPTIONS=""
B2_OPTIONS=""
CMAKE_OPTIONS=""
RUN_TESTS=false
while [ "$#" -gt 0 ]; do
key="$1"
case $key in
    --with-toolset=gcc)
	BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --with-toolset=gcc"
	B2_OPTIONS="$B2_OPTIONS toolset=gcc"
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++"
    ;;
    --with-toolset=clang)
	BOOTSTRAP_OPTIONS="$BOOTSTRAP_OPTIONS --with-toolset=clang"
	B2_OPTIONS="$B2_OPTIONS toolset=clang"
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++"
    ;;
    --enable-cuda)
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_CUDA=ON"
    ;;
    --disable-cuda)
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_CUDA=OFF"
    ;;
    --enable-opencl)
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_OPENCL=ON"
    ;;
    --disable-opencl)
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_OPENCL=OFF"
    ;;
    --enable-cuda-des-multiple-kernels-mode)
	CMAKE_OPTIONS="$CMAKE_OPTIONS -DENABLE_CUDA_DES_MULTIPLE_KERNELS_MODE=ON"
    ;;
    --run-tests)
	RUN_TESTS=true
	;;
    --rebuild)
	rm -rf CLRadeonExtender/CLRX-mirror-master/build BoostPackages/boost_1_61_0 CMakeBuild/
	;;
   	*)
	echo "Unknown option: $key"
    ;;
esac
shift
done

# CLRadeonExtender
cd CLRadeonExtender/
echo Extracting CLRadeonExtender...
7z x -y CLRadeonExtender-*.zip > /dev/null
cd CLRX-mirror-master/
mkdir -p build/
cd build/
cmake $CMAKE_OPTIONS ../
make
cd ../../../

# Boost
cd BoostPackages/
echo Extracting boost_1_61_0.7z...
7z x -y boost_1_61_0.7z > /dev/null
cp sp_counted_base_gcc_x86.hpp boost_1_61_0/boost/smart_ptr/detail
cd boost_1_61_0
OS="`uname`"
case $OS in
  'FreeBSD' | 'Darwin')
    find boost -type f -exec sed -i '.original' '/pragma.*deprecated/d' {} \;
    ;;
  *) 
    find boost -type f -exec sed -i '/pragma.*deprecated/d' {} \;
    ;;
esac
./bootstrap.sh $BOOTSTRAP_OPTIONS
case $OS in
  'FreeBSD')
	./b2 $B2_OPTIONS link=static -j 8
    ;;
  *) 
	./b2 $B2_OPTIONS link=static runtime-link=static -j 8
    ;;
esac
cd ../../

mkdir -p CMakeBuild/
cd CMakeBuild/
cmake $CMAKE_OPTIONS ../SourceFiles/
make

if [ "$RUN_TESTS" = true ]
then
	echo "#regex" > patterns.txt
	echo "^TEST." >> patterns.txt
	echo Testing MerikensTripcodeEngine...
	if ! ./MerikensTripcodeEngine -l 10 -u 60 > /dev/null
	then
		echo >&2 \"MerikensTripcodeEngine -l 10\" failed.
		exit 1
	fi
	if ! ./MerikensTripcodeEngine -l 12 -u 60 > /dev/null
	then
		echo >&2 \"MerikensTripcodeEngine -l 12\" failed.
		exit 1
	fi
	echo Tests were successful.
fi

