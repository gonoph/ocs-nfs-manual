#!/bin/bash

set -e

DEFAULT_EXPORT_SERVER=192.168.26.91
DEFAULT_EXPORT_DIR=/exports/volumes

cat<<HEADER
###########################
This script will generate a PV yaml file and shell script for Openshift to
pregenerate NFS subdirectories that can be used for provisioning persistent
storage for containers.
###########################
HEADER

read -p "Enter EXPORT_SERVER (the NFS endpoint): [$DEFAULT_EXPORT_SERVER] " EXPORT_SERVER
read -p "Enter EXPORT_DIR (parent path exported on NFS): [$DEFAULT_EXPORT_DIR] " EXPORT_DIR

: ${EXPORT_SERVER:=$DEFAULT_EXPORT_SERVER}
: ${EXPORT_DIR:=$DEFAULT_EXPORT_DIR}

cat<<INFO
###########################
Main NFS Mount is: $EXPORT_SERVER:$EXPORT_DIR
###########################
INFO

read -p "Press ENTER to continue, or CTRL-C to abort." ENTER

T=$(mktemp)
TT=$(mktemp)
trap "rm -f $T $TT" EXIT

exec 3>$T
exec 4>$TT

cat<<EOF>&3
#!/bin/bash

set -e
echo "make dir script for $EXPORT_DIR"
cd $EXPORT_DIR
echo -n "Creating: "
EOF
echo "Generating scripts and yaml: "
for i in $(seq 0 255) ; do
	DD=$(printf "%2.2x %x %x" $i $[ $i / 16 ] $[ $i % 16 ])
	set $DD
	D=$1
	D1=$2
	D2=$3
	echo -n "$D "
	cat<<EOF>&3
echo -n "$D " && mkdir -p $D1/$D2/$D && chmod 777 $D1/$D2/$D
EOF
	cat<<EOF>&4
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-$D
  labels:
    creation: manual
    location: dc1
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs-storage
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: $EXPORT_DIR/$D1/$D2/$D
    server: $EXPORT_SERVER
EOF
done

echo

cat<<EOF>&3
echo
echo Done
EOF

echo "Creating: create-dirs.sh"
mv -f $T create-dirs.sh
echo "Creating: create-pvs.sh"
mv -f $TT create-pvs.yml
echo "Making create-dirs.sh executable."
chmod +x create-dirs.sh

cat<<FOOTER
###########################
ALL DONE

create-dirs.sh - should be ran on a server with access to NFS mount

    mkdir -p $EXPORT_DIR
    mount -t nfs $EXPORT_SERVER:$EXPORT_DIR $EXPORT_DIR
    $(dirname `realpath $0`)/create-dirs.sh

create-pvs.yml - should be ran against the OCP master:

    oc login https://consoleurl:8443
    oc create -f $(dirname `realpath $0`)/create-pvs.yml

###########################
FOOTER
