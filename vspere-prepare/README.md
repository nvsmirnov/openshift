1. Obtain govc: https://github.com/vmware/govmomi/tree/master/govc
2. Create temporary admin user in VSphere (or use existing credentials, which is not good but ok if you feel so :), in my case - `k8s-okd-preinstaller@vsphere.local`.
3. Create the user that will be later used in OpenShift/OKD.
4. Edit both vsphere-perms-govc-env.sh (connection parameters for govc) and vsphere-perms.sh (script that do the work), changes are straightforward I hope :)
5. Run ./vsphere-perms.sh
6. If you wish to delete created prmissions - run ./vsphere-perms.sh -d (does not deletes user created on step 2 and 3).
7. Don't forget to delete temporary user created at step 2 - it is not needed for OpenShift to operate.
