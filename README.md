How to setup a CVMFS-aware container based on CentOS 6 and cctools-parrot
================================================================================

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
A dedicated [Dockerhub](mconcas/parrotcvmfs) repo is currently available.
Supposing that you have added your user to the *docker* group, in order to run
docker commands without specifying *sudo*, you can pull the image you prefer
choosing from the currently available in the repo.
You can choose whether use a **centos6-based** image or **scl6-based** one.
Then

'''bash
$ docker pull mconcas/parrotcvmfs:centos6
'''

or

'''bash
$ docker pull mconcas/parrotcvmfs:scl6
'''

### Build it locally
Otherwise can clone directly this [Github](https://github.com/mconcas/docks.git)
repository and build the image on your own.

'''bash
$ git clone https://github.com/mconcas/docks.git

'''

To build your image, with a *Dockerfile* located in /path/to/Dockerfile, just
type (*note that this command accepts relative paths*):

'''bash
docker build --rm -t "<reponame>:<tag> /path/to/Dockerfile"
'''

The alias <reponame> stands for a local repository you build on your local
machine whereas the <tag> alias specifies a tag for your own build.
It's *warmly* recommended to set these two parameters in order to ease
the images management.  

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

'''
DOCKER_OPTS="--dns XXX.XXX.XXX.XXX --dns 8.8.8.8 --dns 8.8.4.4"
'''

where XXX.XXX.XXX.XXX is obviously your DNS server ip-address. After that you
must restart your docker daemon and eventually rerun the command above adding a
'''--no-cache''' parameter to rebuild your image from zero.

For further ways to configure your containers' resolv.conf please have a look
[here](https://docs.docker.com/articles/networking/#dns).


Run the containers
------------------

###List new containers
If the pull/build ran successfully Docker will add to your available images
database the specified tags, you can verify it running:

'''bash
$ docker images
REPOSITORY             TAG        IMAGE ID         CREATED          VIRTUAL SIZE
mconcas/parrotcvmfs    scl6       549ecbb16eaf     3 hours ago      1.56 GB
mconcas/parrotcvmfs    centos6    fd8b26988d9c     3 hours ago      1.204 GB
'''

### Run an interactive shell into your container
You can try interactively your new container simply running a shell with *-it*
params (it supports TAB-autocompletion for the <reponame>:<tag> arg):

'''bash
$ docker run --rm -it <reponame>:<tag> /bin/bash
bash-4.1#

'''

### Try parrot_run
*...and eventually trigger your Mandatory Access Controllers*
Login as a test-user, in order to use parrot_run in a user-environment,
as it was thought.
You will find an environmental variable called TEST_USER.
So, '''$ su $TEST_USER''' and try '''$ parrot_run -d all ls''' for a debug run.
if the last lines are telling you **something different** from:

'''parrot_run[9] process: ls exited normally with status 0'''

You are likely encountering some security problems related on what your MAC
allows processes to do or not.

#### Set Ubuntu Apparmor into complain mode
<span style="color:red"> Please, notice that the following workaround
is **temporary** and may low the security of your computer. I'm currently
looking for a more elegant solution. </span>

On Ubuntu nodes it may happen that the last 4 lines of the output are:
'''
2015/07/06 12:52:42.40 parrot_run[9] debug: tracer_attach (tracer.c:105):
ptrace error: Permission denied  
2015/07/06 12:52:42.40 parrot_run[9] fatal: could not trace child  
2015/07/06 12:52:42.40 parrot_run[9] notice: received signal 15 (Terminated),
killing all my children...  
2015/07/06 12:52:42.40 parrot_run[9] notice: sending myself 15 (Terminated),
goodbye!  
Terminated  
'''

You can eventually tail your kernel log: '''$ dmesg | tail -n1'''

'''<span style="color:red">apparmor="DENIED"</span> operation="ptrace"
profile="docker-default" pid=2412 comm="parrot_run" requested_mask="trace"
denied_mask="trace" peer="docker-default"'''

Long story short: this is because Apparmor does not allow to "setuid root"
processes to *ptrace* other processes.

In fact, although a simple user runs a *ptrace* call into a
container, the docker daemon forwards the request to the underlying host kernel
in common with the host OS. As we know the daemon runs under *setuid*
permissions, thus it can be a security issue if it won't be *canonically* and
securely solved.

But until then the main goal is to setup a minimum ecosystem capable to do
fundamental things, in a controlled test sandbox.
To do this you have to
Install the apparmor-utils:

'''$ sudo apt-get install apparmor-utils'''

Now you must specify a profile to apply every time the docker daemon starts.
A custom profile needs to be named as *path.to.docker.binary*.
We are copying the default one /etc/apparmor.d/doker and renaming in the form
we need.  

'''bash
sudo cp /etc/apparmor.d/docker /etc/apparmor.d/`which docker |
sed 's:/:.:g' | cut -c2-`
'''

Then we have to force apparmor to a complain mode, in that way it will log
every *naughty* operation but it won't block that.

'''bash
$ sudo aa-complain usr.bin.docker
$ Setting /etc/apparmor.d/usr.bin.docker to complain mode.
$ sudo service docker restart
'''
Now docker would be able to do **any** operation.

#### Selinux issue
Currently I don't have encountered a really effective Selinux block for  
*ptrace* calls. I bet I will, so for now i'll let this section blank.

### Access the CVMFS filesystem.
You can use the *p_cvmfs_env.sh* located in /home/$TEST_USER to enter an
environment properly configured with a working CVMFS implementation.

'''bash
# su $TEST_USER
$ . /home/parrotester/p_cvmfs_env.sh
<span style="color:green">(parrot_env)</span> [parrotester@094fd6a51907 ~]$
<span style="color:green">(parrot_env)</span> [parrotester@094fd6a51907 ~]$
ls /cvmfs/alice.cern.ch

bin  calibration  etc  x86_64-2.6-gnu-4.1.2  x86_64-2.6-gnu-4.7.2  
x86_64-2.6-gnu-4.8.3  x86_64-2.6-gnu-4.8.4

'''

