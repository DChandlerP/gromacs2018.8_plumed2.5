#The version of gromacs asked for won't work with newer versions of Linux. There's an issue with hwloc.
FROM ubuntu:18.04

RUN cat /etc/apt/sources.list
#install dependencies
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get update && apt-get install -y libfftw3-dev git cmake g++ gcc libblas-dev xxd openmpi-bin libopenmpi-dev && apt-get clean

#get plumed
RUN git clone -b v2.5 https://github.com/plumed/plumed2 /srv/plumed
WORKDIR /srv/plumed
RUN ./configure --enable-modules=all --prefix=/usr/share && make -j4 && make install && make clean

ENV PATH="/usr/share/bin/:$PATH"
ENV LIBRARY_PATH="/usr/share/lib/:$LIBRARY_PATH"
ENV LD_LIBRARY_PATH="/usr/share/lib/:$LD_LIBRARY_PATH"
ENV PLUMED_KERNEL="/usr/share/lib/libplumedKernel.so"

#get gromacs
RUN git clone https://github.com/gromacs/gromacs /srv/gromacs
WORKDIR /srv/gromacs
RUN git fetch --tags && git checkout v2018.8
#2 is for 2018.8 but there may be an option that uses plumed patch -e with the full name of the version.
RUN /bin/bash -c "source /srv/plumed/sourceme.sh";\
    echo 2 | plumed patch -p;\
    mkdir build build_mpi;\
    cd /srv/gromacs/build;\
    cmake .. && make -j4 install && make clean;\
    ln -s /usr/local/gromacs/bin/gmx /usr/bin/gmx;\
    cd ../build_mpi;\
    cmake .. -DGMX_MPI=on -DGMX_SIMD=AVX2_256 && make -j4 install && make clean;\
    ln -s /usr/local/gromacs/bin/gmx_mpi /usr/bin/gmx_mpi;