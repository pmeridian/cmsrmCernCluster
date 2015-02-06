#!/bin/bash

master=27
pcList="24 25 26 28 29" 
mountPoint="24 25 26 27 28 29 30 31" 

restartServers=no
remount=no

set -- $(getopt mcr "$@")
while [ $# -gt 0 ]
do
    case "$1" in
    (-r) restartServers=yes;;
    (-c) checkServers=yes;;
    (-m) remount=yes;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*)  break;;
    esac
    shift
done

if [ "${checkServers}" == "yes" ]; then
    for pc in ${pcList} ${master}; do
	echo "+++ Checking if pccmsrm${pc} is alive +++"
	ping -q -c 2 pccmsrm${pc} > /dev/null
	if  [ "$?" != 0 ]; then
	    echo "+++ pccmsrm${pc} is NOT alive. Please REBOOT IT manually and then launch again this script +++"
	    exit -1
	fi
	ssh pccmsrm${pc} ls > /dev/null
	if  [ "$?" != 0 ]; then
	    echo "+++ CanNOT connect to pccmsrm${pc}. Please REBOOT IT manually and then launch again this script +++"
	    exit -1
	fi
    done
fi

if [ "${restartServers}" == "yes" ]; then
    for pc in ${pcList}; do
	echo "+++ Restarting xrootd servers onto pccmsrm${pc} +++"
	ssh pccmsrm${pc} /etc/init.d/cmsd restart
	ssh pccmsrm${pc} /etc/init.d/xrootd restart
    done

    echo "+++ Sleeping 10 +++"
    sleep 10

    echo "+++ Restarting master redirector onto pccmsrm${master} +++"
    ssh pccmsrm${master} /etc/init.d/cmsd restart
    ssh pccmsrm${master} /etc/init.d/xrootd restart
fi

if [ "${remount}" == "yes" ]; then
    for pc in ${mountPoint}; do
	echo "+++ Remounting xrootdfs onto pccmsrm${pc} +++"
	ssh pccmsrm${pc} umount -ff /xrootdfs/cms
	ssh pccmsrm${pc} mount /xrootdfs/cms
	ssh pccmsrm${pc} df -h
    done
fi
