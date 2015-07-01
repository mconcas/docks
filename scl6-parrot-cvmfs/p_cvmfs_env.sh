#!/bin/bash
# basic wrapper script to enter in a cvmfs-aware environment
#

export WORKSPACE="${TOPDIR}/workspace"
export PARROT_ALLOW_SWITCHING_CVMFS_REPOSITORIES=yes
export PARROT_CVMFS_REPO="<default-repositories> \
  alice-ocdb.cern.ch:\
  url=http://cvmfs-stratum-one.cern.ch/cvmfs/alice-ocdb.cern.ch,\
  pubkey=$(pwd)/cern-it1.cern.ch.pub"
# export PARROT_OPTIONS="-d cvmfs"
export HTTP_PROXY="http://ca-proxy.cern.ch:3128;DIRECT"


PS1TMP=$PS1
export PS1='\033[32m(parrot_env)\033[0m [\u@\h \W]\$ '

# entry point
exec parrot_run bash --rcfile <( cat ~/.bashrc ; \
    echo -e "\nexport PS1='$PS1'\n" )
