#!/bin/bash

export CONDOR_CONFIG_DIR="/etc/condor/config.d/"
pilot_sleep_s=120

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
echo "Copying credentials..."
condor_store_cred add -c -p mycondorpassword &> /dev/null

#### From her it's all MERELY COPYED FROM:
#### https://github.com/dberzano/cernvm-alice-docker/blob/master/condor-cvm-docker-pilot
#### All credits to <dberzano@cern.ch>

# Start Condor
echo -n 'Starting Condor...'
service condor start > /dev/null 2>&1
echo 'done'

# Wait one second and check if we have the PID
echo -n "Fetching Condor Master's PID..."
sleep 1
condor_master_pidfile=/var/run/condor/condor.pid
condor_master_pid=$( cat "$condor_master_pidfile" 2> /dev/null )

# Turn off exit-on-error (we have some ifs)
set +e

# Check if PID is valid
if [[ $condor_master_pid -le 0 ]] ; then
  # Bash maps invalid strings to 0 so if $condor_head is invalid, it is -eq 0 (but not == 0)
  echo "FATAL: this PID is invalid: ${condor_master_pid}"
  exit 1
else
  echo "${condor_master_pid}"
fi

# Check if we can ping the process
echo -n 'Checking if the Condor Master is running for real...'
if ! kill -0 $condor_master_pid > /dev/null 2>&1 ; then
  echo "FATAL: no process with PID ${condor_master_pid}"
  exit 2
else
  echo 'yes'
fi

# Wait a bit before invoking the condor_off. Pilot waits for things to come!

echo -n "Waiting ${pilot_sleep_s} seconds for jobs to come"
for (( i=0 ; i<$pilot_sleep_s ; i++ )) ; do
  sleep 1
  echo -n '.'
done
echo 'done waiting'

# Peacefully turning the master off. Master controls startd. "Peacefully" means that no turn off
# will occur until every running job has finished. So, if no job is running, exit immediately
echo -n 'Request a peaceful shutdown to the Condor Master...'
set -e
condor_off -daemon master -peaceful > /dev/null 2>&1
set +e
echo 'request sent'

# Begin the wait...
while [[ 1 ]] ; do
  echo -n "Condor Master status (every ${condor_master_ping_s} s)..."
  kill -0 $condor_master_pid > /dev/null 2>&1
  if [[ $? == 0 ]] ; then
    echo 'still alive'
  else
    echo 'terminated, bye!'
    break
  fi
  sleep $condor_master_ping_s
done

exit 0