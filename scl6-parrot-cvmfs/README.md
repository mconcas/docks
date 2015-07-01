How to test it
==============
Assuming you have a _working Docker installation_
Run:
---
```bash
   <...clone this repository and cd scl6-parrot-cvmfs...>
   $ docker build -t test:testing .
   <...pray your gods...>
   $ docker run --rm -ti test:testing /bin/bash

   \# su $TEST_USER
   testuser $ cd ~ && ./p_cvmfs_env.sh
   (parrot_env) [parrotester@258c4b3a67c7 ~]$ ls /cvmfs/alice.cern.ch

   bin  calibration  etc  x86_64-2.6-gnu-4.1.2  x86_64-2.6-gnu-4.7.2  x86_64-2.6-gnu-4.8.3  x86_64-2.6-gnu-4.8.4
```
