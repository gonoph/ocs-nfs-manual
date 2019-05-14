.PNONY: all help storageclass clean

TEST_PROJECT=test-storage
help:
	@echo " ** You must be logged in to the OCP cluster **"
	@echo " ** You must be CLUSTER ADMIN to create PVs and StorageClass's **"
	@echo " ** You must create a project named [$(TEST_PROJECT)] **"
	@echo "Usage: make (files | storageclass | pv-class | pv-default | change)" TEST_PROJECT=PROJECT_NAME
	@echo
	@echo "    files        - creates the scripts and yaml for the NFS directories and PVs"
	@echo "    storageclass - this will create the storage class needed for NFS"
	@echo "    pv-class     - used to test the PV creation with a declared class"
	@echo "    pv-default   - tests the PV creation without declaring a storage class"
	@echo "    change       - change the default to [nfs-storage]"
	@echo
	@echo "    TEST_PROJECT - the name of the project namespace to perform the tests and sample app"

files:
	./mkcreate.sh

storageclass:
	oc create -f nfs-storage-class.yml

pv-class:
	oc project $(TEST_PROJECT)
	oc create -f sample-claim-with-class.yml
	@echo checking;for i in `seq 1 5` ; do oc get pvc claim1 && sleep 1 ; done
	@echo "when done, run:" ; echo "    oc delete pvc/claim1"
	@echo "** CHANGES CLUSTER WARNING: After you run [make change], you can run [make pv-default]"

pv-default:
	oc project $(TEST_PROJECT)
	oc create -f sample-claim-with-default-class.yml
	@echo checking;for i in `seq 1 5` ; do oc get pvc claim1 && sleep 1 ; done
	@echo "** when done, run:" ; echo "    oc delete pvc/claim1"

change:
	oc project $(TEST_PROJECT)
	./change-default.sh nfs-storage
	@echo "To run the service catalog you need to install:"
	@echo "    yum install atomic-enterprise-service-catalog-svcat"
	@echo
	@echo "Now you can run the sample app: ./sample-app.sh"
	@echo "Or you can test the storage class: make pv-default"

clean:
	rm -f create-dirs.sh create-pvs.yml
