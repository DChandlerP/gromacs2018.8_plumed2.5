
FROM registry.gsc.wustl.edu/cpohl/intel-parallel-studio-xe:latest as build

RUN yum install -y centos-release-scl \
    wget && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum install -y devtoolset-9 && \
    yum clean all
RUN wget -qO- "https://cmake.org/files/v3.18/cmake-3.18.4-Linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr/local
ENV PATH="/usr/share/bin/:$PATH"
ENV LIBRARY_PATH="/usr/share/lib/:/opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/lib/release/:$LIBRARY_PATH"
ENV LD_LIBRARY_PATH="/usr/share/lib/:/opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/lib/release/:$LD_LIBRARY_PATH"
ENV CPATH="/opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/lib/release/:/opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/lib"
ENV I_MPI_CC=icc
ENV I_MPI_CXX=icpc
ENV I_MPI_FC=ifort
ENV I_MPI_F90=ifort
ENV CFLAGS="-static-intel"
ENV CXXFLAGS="-static-intel"

#get plumed
RUN git clone -b v2.5 https://github.com/plumed/plumed2 /srv/plumed
WORKDIR /srv/plumed
RUN make clean
RUN ./configure --enable-modules=all --prefix=/usr/share && make -j 4 && make install && make clean

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
    echo 2 | plumed patch -p;

RUN source scl_source enable devtoolset-9 && \
    . /opt/intel/bin/compilervars.sh -arch intel64 -platform linux && \
    . /opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/bin/mpivars.sh && \
    . /opt/intel/compilers_and_libraries_2020.2.254/linux/mkl/bin/mklvars.sh intel64 && \
    mkdir build && \
    cd /srv/gromacs/build && \
    cmake .. -DGMX_BUILD_SHARED_EXE=OFF -DBUILD_SHARED_LIBS=OFF -DGMX_PREFER_STATIC_LIBS=ON -DGMX_FFT_LIBRARY=mkl -DMKL_LIBRARIES=/opt/intel/compilers_and_libraries_2020.2.254/linux/mkl/lib/intel64_lin -DMKL_INCLUDE_DIR=/opt/intel/compilers_and_libraries_2020.2.254/linux/mkl/include -DGMX_SIMD=AVX_512 -DGMX_BUILD_MDRUN_ONLY=on -DGMX_DEFAULT_SUFFIX=OFF -DGMX_BINARY_SUFFIX=_cpu -DCMAKE_C_COMPILER=mpiicc -DCMAKE_CXX_COMPILER=mpiicpc -DGMX_MPI=on -DCMAKE_INSTALL_PREFIX=/srv/gromacs/install -DGMX_OPENMP=off  && \
    make -j4 install && \
    make clean

FROM centos:7.8.2003
RUN mkdir -p -p /opt/intel/lib64
COPY --from=build /srv/gromacs /srv/gromacs
RUN ln -s /srv/gromacs/install/bin/mdrun_cpu /usr/bin/mdrun