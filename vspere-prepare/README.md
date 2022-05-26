1. Create temporary admin user in VSphere (or use existing credentials, which is not good but ok if you feel so :), in my case - `k8s-okd-preinstaller@vsphere.local`.
2. Create the user that will be later used in OpenShift/OKD
3. Edit both vsphere-perms-govc-env.sh (connection parameters for govc) and vsphere-perms.sh (script that do the work), changes are straightforward I hope :)
4. Run ./vsphere-perms.sh
5. If you wish to delete created prmissions - run ./vsphere-perms.sh -d
6. Don't forget to delete temporary user created at step 1.
