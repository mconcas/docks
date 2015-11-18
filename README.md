How to setup a CVMFS-aware container using parrot (from cctools)
================================================================

Author [Matteo Concas](mailto:matteo.concas@cern.ch)

Introduction
------------

This document will briefly describe how to get a CentOS 6 container customized
with additional softwares, in order to make it possible to access
a CVMFS repository without mounting any CVMFS filesystem on the host machine
nor installing additional kernel-modules.
This approach have some advantages
against the (for now) *only* disadvantage that each container will create its
own *local cache* accessing a CVMFS filesystem and a little more effort
in granting isolation and security between the host machine and the containers
running on it.

Furthermore this guide is in prevision that the host machines
(hereafter *nodes*) will lay under particular
conditions/prerequisites/restrictions:

*   They are all Linux x86_64 nodes.
*   Each node has a working [Docker v1.7.0](http://docker.io) container manager
    running correctly installed on it.
*   Each node has access to at least a proxy cvmfs-server resolved by its DNS.

Get the container image or build it locally
-------------------------------------------

There are two ways to obtain an image: to download it from an online container
host service like Dockerhub or to manually build it on your own host using a
*Dockerfile* and few more custom scripts.

### Get it from Dockerhub
This is the quick way.
Two dedicated
[DockerHub 1](https://hub-beta.docker.com/r/mconcas/centos6-autobuild-container/)
[DockerHub 2](https://hub-beta.docker.com/r/mconcas/scl6-autobuild-container/)
repositories are currently available.
Supposing that you have added your user to the *docker* group, in order to run
docker commands without specifying *sudo*, you can pull the image you prefer
choosing from the currently available in the repo.
You can choose whether use a **centos6-based** image or **scl6-based** one.
Then

    $ docker pull mconcas/centos6-autobuild-container:latest

or

    $ docker pull mconcas/scl6-autobuild-container:latest

### Build it locally
Otherwise can clone directly this [GitHub](https://github.com/mconcas/docks.git)
repository and build the image on your own.

    $ git clone https://github.com/mconcas/docks.git

To build your image, with a *Dockerfile* located in /path/to/Dockerfile, just
type (*note that this command accepts relative paths*):

    $ docker build --rm -t "<reponame>:<tag> /path/to/Dockerfile"

The alias <reponame> stands for a local repository you build on your local
machine whereas the <tag> alias specifies a tag for your own build.
It's *warmly* recommended to set these two parameters in order to ease
the images management.

Please notice that the DockerHub repository is kept in sync with the GitHub
one, since  the
[autobuild](https://docs.docker.com/docker-hub/builds/#creating-an-automated-build)
has been configured.  
That is the two procedures here described must lead, if successfully completed,
to the same results.

### Known name-resolving issue with Ubuntu Linux (14.10)
**Important: read below just in case during your building phase you container
can't reach the internet** (*e.g. yum update doesn't succeed*).

As far as i have understood in Ubuntu the /etc/resolv.conf is generated with a
different mechanism compared to, for example, RHEL-based distros.
Thus, in particular cases Docker isn't able to pass to his containers a
custom **DNS** ip-address.

(Manually edit the resolv.conf might not be the best choice or even not a
working one at all, since it will be overwritten by resolvconf).

I found the workaround to manually specify a --dns parameter uncommenting the
/etc/default/docker line:

    DOCKER_OPTS="--dns XXX.XXX.XXX.XXX --dns 8.8.8.8 --dns 8.8.4.4"

where XXX.XXX.XXX.XXX is obviously your DNS server ip-address. After that you
must restart your docker daemon and eventually rerun the command above adding a
'--no-cache parameter to rebuild your image from zero.

For further ways to configure your containers' resolv.conf please have a look
[here](https://docs.docker.com/articles/networking/#dns).


Run the containers
------------------

###List new containers
If the pull/build ran successfully Docker will add to your available images
database the specified tags, you can verify it running:

    $ docker images
    REPOSITORY            TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
    mconcas/parrotcvmfs   scl6                549ecbb16eaf        10 hours ago        1.56 GB
    mconcas/parrotcvmfs   centos6             fd8b26988d9c        10 hours ago        1.204 GB  

### Run an interactive shell into your container
You can try interactively your new container simply running a shell with *-it*
params (it supports TAB-autocompletion for the < reponame >:< tag > arg):

    $ docker run --rm -it <reponame>:<tag> /bin/bash
    bash-4.1#

### Try parrot_run
Login as a test-user, in order to use parrot_run in a user-environment.
You will find an environmental variable called TEST_USER.

    $ su $TEST_USER
    $ parrot_run -d all ls

For a debug run.
if the last lines are telling you **something different** from:

    parrot_run[9] process: ls exited normally with status 0

You are likely encountering some security problems related on what your MAC
allows processes to do or not.

#### Apparmor
**Don't disable your MACs, unless it's strictly unavoidable. They are good guys**

On Ubuntu or ubuntu-flavoured distros (e.g. Linux Mint) it's likely that apparmor won't let
you [*trace your processes*](http://linux.die.net/man/2/ptrace). 
I'm not intended to discuss pros and conts of this policy, or why, by default, docker containers 
aren't allowed to ptrace any process but their children. 
Here I just provide a canonic method to tell apparmor that you are aware of what are you doing 
and that `ptrace` can be enabled for the session.
Keeping in mind that run `--privileged` containers is even worse that set apparmor to 
complain mode.
If you are encountering something like this when debugging you `parrot_run` session, see the next 
paragraph to exit this *empasse*.

    2015/07/06 12:52:42.40 parrot_run[9] debug: tracer_attach (tracer.c:105):
    ptrace error: Permission denied  
    2015/07/06 12:52:42.40 parrot_run[9] fatal: could not trace child  
    2015/07/06 12:52:42.40 parrot_run[9] notice: received signal 15 (Terminated),
    killing all my children...  
    2015/07/06 12:52:42.40 parrot_run[9] notice: sending myself 15 (Terminated),
    goodbye!  
    Terminated

You can eventually tail your kernel log and spot the ptrace denial:

    $ dmesg | tail
    apparmor="DENIED" operation="ptrace" profile="docker-default" pid=2412 comm="parrot_run" requested_mask="trace" denied_mask="trace" peer="docker-default"

Long story short: this is because Apparmor does not allow to "setuid root"
processes to *ptrace* other processes.

In fact, although a simple user runs a *ptrace* call into a
container, the docker daemon forwards the request to the underlying host kernel
in common with the host OS. As we know the daemon runs under *setuid*
permissions, thus it can be a security issue if it won't be *canonically* and
securely solved.

#### Allow Docker container to call ptrace()
The goal is to create an apparmor profile for docker containers that is equivalent to the 
standard one automatically generated in `/etc/apparmor.d/docker` by docker daemon at startup, 
plus enabling `ptrace()`.
An example of vanilla docker-default profile template could be:

```
#include <tunables/global>


profile docker-default flags=(attach_disconnected,mediate_deleted) {

  #include <abstractions/base>


  network,
  capability,
  file,
  umount,

  deny @{PROC}/{*,**^[0-9*],sys/kernel/shm*} wkx,
  deny @{PROC}/sysrq-trigger rwklx,
  deny @{PROC}/mem rwklx,
  deny @{PROC}/kmem rwklx,
  deny @{PROC}/kcore rwklx,

  deny mount,

  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
  deny /sys/firmware/efi/efivars/** rwklx,
  deny /sys/kernel/security/** rwklx,
}

```
Notice that editing thi file is quite useless since it's autmatilly generated everytime the 
docker daemon starts up.
So create your dummy `docker-allow-ptrace` file and add the rule:

```
ptrace peer=@{profile_name}
```

obtaining something like:
```

#include <tunables/global>


profile docker-ptrace flags=(attach_disconnected,mediate_deleted) {

  #include <abstractions/base>


  network,
  capability,
  file,
  umount,
  ptrace peer=@{profile_name},

  deny @{PROC}/{*,**^[0-9*],sys/kernel/shm*} wkx,
  deny @{PROC}/sysrq-trigger rwklx,
  deny @{PROC}/mem rwklx,
  deny @{PROC}/kmem rwklx,
  deny @{PROC}/kcore rwklx,

  deny mount,

  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
  deny /sys/firmware/efi/efivars/** rwklx,
  deny /sys/kernel/security/** rwklx,
}
```

and parse it with

```bash
sudo apparmor_parser -r docker-allow-ptrace
```
Now, when you want to run a container with ptrace permissions you have to pass a `security-opt` paramter.
For example, in this case

```bash
docker run --rm -it --security-opt "apparmor:docker-ptrace" mconcas/centos6-autobuild-container /bin/bash
```

#### Selinux issues
Currently I don't have encountered a really effective Selinux block for  
*ptrace* calls. I bet I will, so for now i'll let this section blank.

### Access the CVMFS filesystem.
You can use the *p_cvmfs_env.sh* located in /home/$TEST_USER to enter an
environment properly configured with a working CVMFS implementation.

    # su $TEST_USER
    $ . /home/parrotester/p_cvmfs_env.sh
    (parrot_env) [parrotester@xxx ~]$
    (parrot_env) [parrotester@xxx ~]$ ls /cvmfs/alice.cern.ch
    bin  calibration  etc  x86_64-2.6-gnu-4.1.2  x86_64-2.6-gnu-4.7.2  x86_64-2.6-gnu-4.8.3  x86_64-2.6-gnu-4.8.4

### Configure a [Condor](http://research.cs.wisc.edu/htcondor/) worker node
