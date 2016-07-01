FROM alisw/slc6-cvmfs

ENV CONDOR_SECRET="@mycondorpassword@"

RUN curl -o /etc/yum.repos.d/htcondor-development-rhel6.repo \
    http://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-development-rhel6.repo && \
    rpm --rebuilddb && yum install -y condor

COPY files/os-release /etc/os-release
COPY files/cern-it1.cern.ch.pub /etc/cvmfs/keys/cern.ch/cern-it1.cern.ch.pub
COPY files/cvmfs-default.local /etc/cvmfs/default.local
COPY files/condor-container-pilot /tmp/condor-container-pilot

RUN mkdir -p /cvmfs/alice-ocdb.cern.ch && mkdir -p /cvmfs/alice.cern.ch
RUN chmod +x /tmp/condor-container-pilot
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
