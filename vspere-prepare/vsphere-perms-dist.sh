#!/bin/bash

# this script creates (or deletes if they are exist) roles, and assigns them to user and objects for installing OKD/OpenShift on VSphere
# this sample is for variant of installing to existing vm folder, without specifying resource pool
# ref: https://docs.okd.io/4.10/installing/installing_vsphere/installing-vsphere-installer-provisioned-network-customizations.html
# 2022, Nikita Smirnov, nsmirnov@gmail.com

# run with -d for "delete only" mode: delete previously created roles

# you need govc tool
# you need a user in VCenter with Admin privilege (as for me, I created temporary one-time user)

# you need to change this:
# OKD_VCENTER_USER_NAME - user that you created manually in VSphere
# DATACENTER_OBJECTS, DVS_OBJECTS, CLUSTER_OBJECTS, DATASTORE_OBJECTS, PORTGROUP_OBJECTS, VMFOLDER_OBJECTS
# to fgure all them out, use govc ls / and so on (except PORTGROUP, for this, use govc find / -type DistributedVirtualPortgroup)

OKD_VCENTER_USER_NAME='k8s-okd-do@vsphere.local'

VCENTER_OBJECTS=("/")
DATACENTER_OBJECTS=("/DataCenterName")
DVS_OBJECTS=("/DataCenterName/network/ESXXenDesDVi")
CLUSTER_OBJECTS=("/DataCenterName/host/AMD01")
DATASTORE_OBJECTS=("/DataCenterName/datastore/datastore_01")
PORTGROUP_OBJECTS=("/DataCenterName/network/VLAN_XXXX")  # to find it: govc find / -type DistributedVirtualPortgroup
VMFOLDER_OBJECTS=("/DataCenterName/vm/k8s/sandbox")

set -e

. govc-env.sh

DELETEONLY=
if [ "$1" == "-d" ]; then
  DELETEONLY=true
fi

VCENTER_PRIVS_INHERIT=false
VCENTER_PRIVS=(
Cns.Searchable
InventoryService.Tagging.AttachTag
InventoryService.Tagging.CreateCategory
InventoryService.Tagging.CreateTag
InventoryService.Tagging.DeleteCategory
InventoryService.Tagging.DeleteTag
InventoryService.Tagging.EditCategory
InventoryService.Tagging.EditTag
Sessions.ValidateSession
StorageProfile.Update
StorageProfile.View
)

DATACENTER_PRIVS_INHERIT=false
DATACENTER_PRIVS=(
# by default, here will be System.Anonymous, System.Read, System.View
# it is required for varian "Existing folder"
)

DVS_PRIVS_INHERIT=false
DVS_PRIVS=(
System.Read
)

CLUSTER_PRIVS_INHERIT=true
CLUSTER_PRIVS=(
Resource.AssignVMToPool
VApp.AssignResourcePool
VApp.Import
VirtualMachine.Config.AddNewDisk
#Host.Config.Storage # nsmirnov: it looks that it is not needed for me
)

DATASTORE_PRIVS_INHERIT=false
DATASTORE_PRIVS=(
Datastore.AllocateSpace
Datastore.Browse
Datastore.FileManagement
InventoryService.Tagging.AttachTag
)

PORTGROUP_PRIVS_INHERIT=false
PORTGROUP_PRIVS=(
Network.Assign
)

VMFOLDER_PRIVS_INHERIT=true
VMFOLDER_PRIVS=(
Resource.AssignVMToPool
VApp.Import
VirtualMachine.Config.AddExistingDisk
VirtualMachine.Config.AddNewDisk
VirtualMachine.Config.AddRemoveDevice
VirtualMachine.Config.AdvancedConfig
VirtualMachine.Config.Annotation
VirtualMachine.Config.CPUCount
VirtualMachine.Config.DiskExtend
VirtualMachine.Config.DiskLease
VirtualMachine.Config.EditDevice
VirtualMachine.Config.Memory
VirtualMachine.Config.RemoveDisk
VirtualMachine.Config.Rename
VirtualMachine.Config.ResetGuestInfo
VirtualMachine.Config.Resource
VirtualMachine.Config.Settings
VirtualMachine.Config.UpgradeVirtualHardware
VirtualMachine.Interact.GuestControl
VirtualMachine.Interact.PowerOff
VirtualMachine.Interact.PowerOn
VirtualMachine.Interact.Reset
VirtualMachine.Inventory.Create
VirtualMachine.Inventory.CreateFromExisting
VirtualMachine.Inventory.Delete
VirtualMachine.Provisioning.Clone
VirtualMachine.Provisioning.MarkAsTemplate
VirtualMachine.Provisioning.DeployTemplate
)

# just test connection, so -e could stop further progress
govc about

OBJECTS=(
VCENTER
DATACENTER
CLUSTER
DATASTORE
PORTGROUP
VMFOLDER
DVS
)
for OBJ in "${OBJECTS[@]}"; do
  eval "OBJ_LIST=( $(for _n in "\${${OBJ}_OBJECTS[@]}"; do echo '"'"$_n"'"'; done) )"
  eval "OBJ_PRIVS=( $(for _n in "\${${OBJ}_PRIVS[@]}"; do if [ -n "$_n" ]; then echo '"'"$_n"'"'; fi; done) )"
  eval "PROPAGATE=\"\${${OBJ}_PRIVS_INHERIT}\""
  #echo -n "$OBJ:"
  #for _n in "${OBJ_LIST[@]}"; do
  #  echo -n " '$_n'"
  #done
  #echo
  ROLE_NAME="k8s-okd-$OBJ"
  if govc role.ls "$ROLE_NAME" >/dev/null 2>&1; then
    echo "$0: Role $ROLE_NAME exists, deleting it first..."
    govc role.remove -force "$ROLE_NAME"
  fi
  if [ "$DELETEONLY" != "true" ]; then
    echo "$0: Creating role '$ROLE_NAME'"
    govc role.create "$ROLE_NAME" "${OBJ_PRIVS[@]}"
    for _OBJNAME in "${OBJ_LIST[@]}"; do 
      echo "$0: Granting '$ROLE_NAME' to '$OKD_VCENTER_USER_NAME' on '$_OBJNAME' (propagate=$PROPAGATE)"
      govc permissions.set "-propagate=$PROPAGATE" -principal "$OKD_VCENTER_USER_NAME" -role "$ROLE_NAME" "$_OBJNAME"
    done
  fi
done
