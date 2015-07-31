#!/bin/bash

export CONDOR_CONFIG_DIR="/etc/condor/config.d/"
# Check if root

if [ `id -u` != "0" ]; then
    echo " Run this script as root."
    exit 1
fi
yum install -y wget &>/dev/null
echo -n "Condor initialization..."
wget https://gist.githubusercontent.com/mconcas/dd6d3dbf48519d71d07c/raw/ddbae134c647aa26283ef8f674e8c72d2db767b8/00-docker-worker.config -P$CONDOR_CONFIG_DIR &> /dev/null
wget https://gist.githubusercontent.com/mconcas/f2847b7c3b362b22a7cb/raw/f5f526a466059ab9c616883345dca54111b0c368/10-common-docker.config -P$CONDOR_CONFIG_DIR &> /dev/null
wget https://gist.githubusercontent.com/mconcas/6e9b6b5e729f4606459d/raw/3ad143367304af27d96c98afbce17a1a7fe2d2b4/20-common-schedd-docker.config -P$CONDOR_CONFIG_DIR &> /dev/null
wget https://gist.githubusercontent.com/mconcas/e5e1770248f4ee697587/raw/17a7c2ee3960894f4b97b7198b4d1b7e0c6aaa85/99-common-debug-docker.config -P$CONDOR_CONFIG_DIR &> /dev/null
echo " done"
echo "Starting condor service..."
service condor start &> /dev/null
echo "Copying credentials..."
condor_store_cred add -c -p mycondorpassword &> /dev/null
if [ "$?" -ne 0 ]; then
  echo "Operation failed. Exiting..."
  exit 1
else
  service condor restart $> /dev/null
fi
