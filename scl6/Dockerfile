# DockerFile for SCL6 with a working parrot+cvmfs implementation.
#
# See: github.com/cvmfs/cvmfs and cernvm.cern.ch/portal/filesystem
# See: github.com/cooperative-computing-lab/cctools and
#      http://ccl.cse.nd.edu/software/manuals/parrot.html

FROM hepsw/slc-base:latest
MAINTAINER Matteo Concas mconcas@cern.ch

# Environmental variables.
ENV TEST_USER="parrotester" TEST_USER_HOME="/home/parrotester"
ENV \
# CVMFS environment
    CVMFS_GIT_REPO="https://github.com/cvmfs/cvmfs.git" \
    CVMFS_BRANCH="libcvmfs-stable" \
    CVMFS_PATH=/opt/cvmfs CVMFS_BUILD_PATH=/opt/cvmfs/build \
    CVMFS_REQ="libattr-devel zlib-devel openssl-devel libuuid-devel \
    fuse-devel python-devel" \
# CCTOOLS environment
    CCTOOLS_GIT_REPO="https://github.com/cooperative-computing-lab/cctools.git" \
    CCTOOLS_BRANCH="master" \
# Personal choice...
    CCTOOLS_PATH=/opt/cctools \
    # CCTOOLS_BUILD_PATH=opt/cctools/build \

# Generic prerequisites
    GEN_REQ="git cmake tar unzip gcc gcc-c++ patch " \
    MJ=9 \
# Software-specific prerquisites
# from dberzano.github.io/alice/install-aliroot/cvmfs/#install_aliroot_requirements
    ALIROOT_REQ="gcc-gfortran libXpm compat-libgfortran-41 tcl \
    compat-libtermcap redhat-lsb-core"

ENV CCTOOLS_BUILD_PATH=$CCTOOLS_PATH/build


LABEL branch.cvmfs=$CVMFS_BRANCH branch.cctools=$CCTOOLS_BRANCH
# Adding custom debug scripts
COPY p_cvmfs_env.sh /home/$TEST_USER/p_cvmfs_env.sh

# Installing prerequisites.
RUN yum update -y && yum install -y $GEN_REQ                                && \
# Downloading and compiling CVMFS
    yum install -y $CVMFS_REQ                                               && \
    mkdir -p $CVMFS_PATH                                                    && \
    git clone $CVMFS_GIT_REPO $CVMFS_PATH                                   && \
    git --git-dir=$CVMFS_PATH/.git checkout $CVMFS_BRANCH                   && \
    mkdir -p $CVMFS_BUILD_PATH                                              && \
    cmake -B$CVMFS_BUILD_PATH -H$CVMFS_PATH/                                && \
    make -j$MJ -C$CVMFS_BUILD_PATH                                          && \
    make -C$CVMFS_BUILD_PATH install                                        && \
# I found that cmake leaves some trashes all around, let's remove them...
    rm -Rf /CMakeLists.txt /externals /cvmfs                                && \
# Fix for a parrot_run complain
    mkdir -p /cvmfs/.modulerc                                               && \
# Setting up a test user
    useradd -d $TEST_USER_HOME $TEST_USER                                   && \
# Downloading and compiling CCTOOLS
    mkdir -p $CCTOOLS_BUILD_PATH                                            && \
    git clone $CCTOOLS_GIT_REPO $CCTOOLS_BUILD_PATH                         && \
    git --git-dir=$CCTOOLS_BUILD_PATH/.git checkout $CCTOOLS_BRANCH         && \
    chown -R $TEST_USER $CCTOOLS_PATH                                       && \
    runuser -l $TEST_USER -c "cd $CCTOOLS_BUILD_PATH && ./configure \
      --prefix=$CCTOOLS_PATH --with-cvmfs-path=/usr/ "                      && \
    runuser -l $TEST_USER -c "cd $CCTOOLS_BUILD_PATH && \
      make -j$MJ && make install"                                           && \
    chown -R $TEST_USER $TEST_USER_HOME                                     && \
    runuser -l $TEST_USER -c"echo \"export PATH=\$PATH:$CCTOOLS_PATH/bin\" \
    >> $TEST_USER_HOME/.bashrc"

# AliRoot things
RUN yum install -y $ALIROOT_REQ
# This tricks the alienv script...
COPY os-release /etc/os-release
