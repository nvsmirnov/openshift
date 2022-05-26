# use these parameters to connect to VSphere
# give a user with Admin privileges
# this user needed only once, when creating permissions, then it should be blocked/removed from VCenter.
# as for me, I created temporary user for this
export GOVC_URL=vsphere.name.tld
export GOVC_USERNAME='vsphere.local\k8s-okd-preinstaller'
export GOVC_PASSWORD='XXXX'
export GOVC_INSECURE=1
