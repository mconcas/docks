#!/bin/bash
# wrapper script to enter in an interactive cvmfs-aware environment using parrot_run
#

export PARROT_ALLOW_SWITCHING_CVMFS_REPOSITORIES=yes
export CERN_S1="http://cvmfs-stratum-one.cern.ch/cvmfs"
export DESY_S1="http://grid-cvmfs-one.desy.de:8000/cvmfs"
export PARROT_CVMFS_REPO="<default-repositories> \
 alice-ocdb.cern.ch:url=${CERN_S1}/alice-ocdb.cern.ch,pubkey=/etc/cvmfs/keys/cern.ch/cern-it1.cern.ch.pub \
 ilc.desy.de:url=${DESY_S1}/ilc.desy.de,pubkey=/etc/cvmfs/keys/desy.de/desy.de.pub"


#export PARROT_CVMFS_REPO="<default-repositories> \
#  alice-ocdb.cern.ch:\
#  url=http://cvmfs-stratum-one.cern.ch/cvmfs/alice-ocdb.cern.ch,\
#  pubkey=$(pwd)/cern-it1.cern.ch.pub"
# export PARROT_OPTIONS="-d cvmfs"

export HTTP_PROXY="http://ca-proxy.cern.ch:3128;DIRECT"


PS1TMP=$PS1
export PS1='\033[32m(parrot_env)\033[0m [\u@\h \W]\$ '

# entry point
exec parrot_run bash --rcfile <( cat ~/.bashrc ; \
    echo -e "\nexport PS1='$PS1'\n" )
