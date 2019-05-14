# ocs-nfs-manual
Repository to walk someone through manually creating NFS mounts for OCS using a simple StorageClass

## Purpose

This project is a collection of shell scripts and yaml that attempt to walk someone through a process
of creating NFS mounts to use as container storage. There's not much fancy here, except pre-provisioning
a bunch of subdirectories on an already configured NFS mount. Some of the best practices you should
probably follow include:

* Adding supplemental groups to all pods (possibly namespaces) that will use this storage.
* Ensuring containers that use this storage create their own subdirectory with restrictive permissions.
* Somehow enforcing quotas across these storage pools.
* There is nothing inherit in the NFS storage driver that enforces any access modes `ReadWriteMany`, `ReadWriteOnce`, `ReadOnlyMany`.

## Steps

1. Create a bunch of directories on your NFS mount
2. Assign proper permissions to those directories
3. Create a "NFS" StorageClass that uses the `no-provisioner` provider
4. Create multiple PVs pointing to the NFS target and subdirectories
5. Test it with a PVC with a declared `storageClassName`
6. Change the Default StorageClass to the NFS storage class
7. Test it with a PVC without a declared class
8. Test it with an App.
9. Test that the PVs are reclaimed (currently k8s defaults to `rm -rf *` in the PV mount)

Simple enough

## Makefile

In order to do the steps above, I created a few scripts and a Makefile to make it easier.

### Prerequisites

* You will need to be a Cluster Admin
* You will need a sample namespace / project (defaults to `test-storage`)
* You will need a NFS target (ex: mynfs.server.domain.com:/exports/mounts)
* You will need access to that NFS target as a mount with the same name (ex: /exports/mounts)
* You CAN copy the `create-dirs.sh` to a remote system that has NFS access and run it from there
* You will need access to the Openshift CLI
* You CAN copy run everything from the OCP master if it has GNUMake
* You can OPTIONALLY run the `sample-app.sh`
* IF you run the sample-app, you WILL need the Service Catalog CLI (`svcat`)

### Makefile Help

```
 ** You must be logged in to the OCP cluster **
 ** You must be CLUSTER ADMIN to create PVs and StorageClass's **
 ** You must create a project named [test-storage] **
Usage: make (files | storageclass | pv-class | pv-default | change) TEST_PROJECT=PROJECT_NAME

    files        - creates the scripts and yaml for the NFS directories and PVs
    storageclass - this will create the storage class needed for NFS
    pv-class     - used to test the PV creation with a declared class
    pv-default   - tests the PV creation without declaring a storage class
    change       - change the default to [nfs-storage]

    TEST_PROJECT - the name of the project namespace to perform the tests and sample app
```

### Create the dirs, set permissions, and create the PVs

At first, you need to create the files:

```
make files
./mkcreate.sh
###########################
This script will generate a PV yaml file and shell script for Openshift to
pregenerate NFS subdirectories that can be used for provisioning persistent
storage for containers.
###########################
Enter EXPORT_SERVER (the NFS endpoint): [192.168.26.91]
Enter EXPORT_DIR (parent path exported on NFS): [/exports/volumes]
###########################
Main NFS Mount is: 192.168.26.91:/exports/volumes
###########################
Press ENTER to continue, or CTRL-C to abort.
```

After this, it will generate the files, and you can then do this if you haven't mounted the NFS, yet:

```bash
mkdir -p /exports/volumes
mount -t nfs 192.168.26.91:/exports/volumes /exports/volumes
./create-dirs.sh
```

Then you can create the PVs

```bash
oc login https://consoleurl:8443
oc create -f /Users/flushy/src/kube-pods/ocp/create-pvs.sh
```

### Create the StorageClass

```bash
make storageclass
```

That's all there is to this part.

### Test a PVC with a declared StorageClass

```
make pv-class
```

This will create a PVC (Persistent Volume Claim), and show you it's bound. When done:

```bash
oc delete pvc/claim1
```

### Change the default storage class

You can run the simple script that automatically changes the default storage class
to whatever storage class you give as a command line parameter.

```bash
./change-default.sh nfs-storage
```

### Test a PVC with the default StorageClass

After you change/update the default StorageClass, you can then run the next test:

```bash
make pv-default
```

Again, when done, delete it:

```bash
oc delete pvc/claim1
```

### Sample App

And finally, if you're done testing, try provisioning a postgresql project
(you will need the `svcat` command in order to do this). This assumes you're
running it from a OCP node/master.

```bash
yum install -y atomic-enterprise-service-catalog-svcat
./sample-app.sh
```
