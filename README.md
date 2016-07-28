# Heat V2 Kit Deploy for Xura
This deployment kit has been developed based on some requirements.
One of them is the fully VM(s) isolation from the OpenStack API or not be able to call the OpenStack Metadata server.

# Requirements
In order to run this Kit a Linux box is required.
The following packages are required:
- git
- dos2unix
- md5sum
- python-neutronclient
- python-openstackclient
- python-heatclient
- python-novaclient
- python-swiftclient
- python-ceilometerclient
- python-cinderclient
- python-keystoneclient
- python-glanceclient
The Linux box has to be able to call the OpenStack API.
When the Kit has been downloaded, it needs the read and the write permission on the Kit files.
An OpenStack environment file is required in order to authenticate the wrapper to the OpenStack API.
```
export OS_NO_CACHE=True
export COMPUTE_API_VERSION=1.1
export OS_USERNAME=kitv2
export no_proxy=,10.107.201.11
export OS_TENANT_NAME=kitv2
export OS_CLOUDNAME=overcloud
export OS_AUTH_URL=http://10.107.201.11:5000/v2.0/
export NOVA_VERSION=1.1
export OS_PASSWORD=kitv2
```
## API Requirements
The following are the required API in order to execure those Kits.
All of the OpenStack API can be found at the following link
http://developer.openstack.org/api-ref.html

### Nova
- List Servers - http://developer.openstack.org/api-ref/compute/?expanded=#list-servers
- Create Server - http://developer.openstack.org/api-ref/compute/?expanded=#create-server
- List Servers Detailed - http://developer.openstack.org/api-ref/compute/?expanded=#list-servers-detailed
- Show Server Details - http://developer.openstack.org/api-ref/compute/?expanded=#show-server-details
- Update Server - http://developer.openstack.org/api-ref/compute/?expanded=#update-server
- Delete Server - http://developer.openstack.org/api-ref/compute/?expanded=#delete-server
- Create Image (createImage Action) - http://developer.openstack.org/api-ref/compute/?expanded=#create-image-createimage-action
- Reboot Server (reboot Action) - http://developer.openstack.org/api-ref/compute/?expanded=#reboot-server-reboot-action
- Start Server (os-start Action) - http://developer.openstack.org/api-ref/compute/?expanded=#start-server-os-start-action
- Stop Server (os-start Action) - http://developer.openstack.org/api-ref/compute/?expanded=#stop-server-os-stop-action
- Show Console Output (Os-Getconsoleoutput Action) - http://developer.openstack.org/api-ref/compute/?expanded=#show-console-output-os-getconsoleoutput-action
- Get Vnc Console (os-getVNCConsole Action) - http://developer.openstack.org/api-ref/compute/?expanded=#get-vnc-console-os-getvncconsole-action
- List Ips - http://developer.openstack.org/api-ref/compute/?expanded=#list-ips
- Show Ip Details - http://developer.openstack.org/api-ref/compute/?expanded=#show-ip-details
- List All Metadata - http://developer.openstack.org/api-ref/compute/?expanded=#list-all-metadata
- Update Metadata Items - http://developer.openstack.org/api-ref/compute/?expanded=#update-metadata-items
- Create Or Replace Metadata Items - http://developer.openstack.org/api-ref/compute/?expanded=#create-or-replace-metadata-items
- Show Metadata Item Details - http://developer.openstack.org/api-ref/compute/?expanded=#show-metadata-item-details
- Create Or Update Metadata Item - http://developer.openstack.org/api-ref/compute/?expanded=#create-or-update-metadata-item
- Delete Metadata Item - http://developer.openstack.org/api-ref/compute/?expanded=#delete-metadata-item
- List volume attachments for an instance - http://developer.openstack.org/api-ref/compute/?expanded=#list-volume-attachments-for-an-instance
- Attach a volume to an instance - http://developer.openstack.org/api-ref/compute/?expanded=#attach-a-volume-to-an-instance
- Show a detail of a volume attachment - http://developer.openstack.org/api-ref/compute/?expanded=#show-a-detail-of-a-volume-attachment
- Update a volume attachment - http://developer.openstack.org/api-ref/compute/?expanded=#update-a-volume-attachment
- Detach a volume from an instance - http://developer.openstack.org/api-ref/compute/?expanded=#detach-a-volume-from-an-instance
- List Flavors - http://developer.openstack.org/api-ref/compute/?expanded=#list-flavors
- List Keypairs - http://developer.openstack.org/api-ref/compute/?expanded=#list-keypairs
- Create Or Import Keypair - http://developer.openstack.org/api-ref/compute/?expanded=#create-or-import-keypair
- Delete Keypair - http://developer.openstack.org/api-ref/compute/?expanded=#delete-keypair
- List Server Groups - http://developer.openstack.org/api-ref/compute/?expanded=#list-server-groups
- Create Server Group - http://developer.openstack.org/api-ref/compute/?expanded=#create-server-group
- Show Server Group Details - http://developer.openstack.org/api-ref/compute/?expanded=#show-server-group-details
- Delete Server Group - http://developer.openstack.org/api-ref/compute/?expanded=#delete-server-group

### Cinder
- List volumes - http://developer.openstack.org/api-ref-blockstorage-v2.html#listVolumes
- Creates a volume - http://developer.openstack.org/api-ref-blockstorage-v2.html#createVolume
- List volumes with details - http://developer.openstack.org/api-ref-blockstorage-v2.html#listVolumesDetail
- Shows details for a volume - http://developer.openstack.org/api-ref-blockstorage-v2.html#showVolume
- Delete a volume - http://developer.openstack.org/api-ref-blockstorage-v2.html#deleteVolume

### Neutron
- List networks - http://developer.openstack.org/api-ref/networking/v2/?expanded=list-networks-detail#list-networks
- Show network details - http://developer.openstack.org/api-ref/networking/v2/?expanded=show-network-details-detail#show-network-details
- List subnets - http://developer.openstack.org/api-ref/networking/v2/?expanded=list-subnets-detail#show-network-details
- Show subnets details - http://developer.openstack.org/api-ref/networking/v2/?expanded=show-subnet-details-detail#show-network-details
- List ports - http://developer.openstack.org/api-ref/networking/v2/?expanded=list-ports-detail#show-network-details
- Show ports details - http://developer.openstack.org/api-ref/networking/v2/?expanded=list-ports-detail,show-port-details-detail#show-network-details
- Update port - http://developer.openstack.org/api-ref/networking/v2/?expanded=update-port-detail#show-network-details
- List security groups - http://developer.openstack.org/api-ref/networking/v2-ext/?expanded=list-security-groups-detail
- Create security group - http://developer.openstack.org/api-ref/networking/v2-ext/?expanded=create-security-group-detail
- Delete security group - http://developer.openstack.org/api-ref/networking/v2-ext/?expanded=delete-security-group-detail
- Show security group - http://developer.openstack.org/api-ref/networking/v2-ext/?expanded=show-security-group-detail
- Update security group - http://developer.openstack.org/api-ref/networking/v2-ext/?expanded=update-security-group-detail

### Glance
- Lists public virtual machine (VM) images - http://developer.openstack.org/api-ref-image-v2.html#listImages-v2
- Shows details for an image - http://developer.openstack.org/api-ref-image-v2.html#showImage-v2
- Creates a virtual machine (VM) image - http://developer.openstack.org/api-ref-image-v2.html#createImage-v2

### Heat
- Create stack - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_create
- List stack data - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_list
- Preview stack - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_preview
- Preview stack update - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_update_preview
- Find stack - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_find
- Find stack resources - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_resources_find
- Show stack details - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_show
- Update stack - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_update
- Delete stack - http://developer.openstack.org/api-ref-orchestration-v1.html#stack_delete
- List resources - http://developer.openstack.org/api-ref-orchestration-v1.html#resource_list
- Show resource data - http://developer.openstack.org/api-ref-orchestration-v1.html#resource_show
- Show resource metadata - http://developer.openstack.org/api-ref-orchestration-v1.html#resource_metadata

# Phase 1 - Preparetion
## Phase 1.1 - Git
The Kit can be cloned by GitHub with the following command:
```
$ git clone git@github.com:XuraCorporate/KitV2.git
```

# Phase 1.1 - Environment file preparetion
This phase is the "hand on" part, which requires a number of things (most of them has to be configure in environment/common.yaml)
- Make sure that the Tenant in OpenStack environment has the right Image(s). To see them
```
$ glance image-list
+--------------------------------------+------------------------------------+-------------+------------------+-------------+--------+
| ID                                   | Name                               | Disk Format | Container Format | Size        | Status |
+--------------------------------------+------------------------------------+-------------+------------------+-------------+--------+
| 1f4027b2-5290-4abc-9e26-845e8cfc9052 | Fedora23                           | qcow2       | bare             | 234363392   | active |
| bc303413-3e8e-424b-a76a-48f214a709df | RHEL_6.7_x64                       | qcow2       | bare             | 337575936   | active |
| 9dd7da23-3af9-4946-b342-1c0131981b50 | RHEL_6.8_x64                       | qcow2       | bare             | 366673920   | active |
+--------------------------------------+------------------------------------+-------------+------------------+-------------+--------+
```
- Write the Images' Name and the Images' ID down in the common environment file (environment/common.yaml)
- Make sure that the Tenant in OpenStack environment has the right Volume(s). To see them
```
cinder list
+--------------------------------------+-----------+--------------+------+-------------+----------+-------------+
|                  ID                  |   Status  | Display Name | Size | Volume Type | Bootable | Attached to |
+--------------------------------------+-----------+--------------+------+-------------+----------+-------------+
| d8842665-3408-42d6-9ae8-78468b8b39a9 | available |      -       |  10  |      -      |  false   |             |
+--------------------------------------+-----------+--------------+------+-------------+----------+-------------+
```
- Write the Volumes' ID down and the desired deployment size in the common environment file (environment/common.yaml)
- To make a golden volume from a running VM
```
$ nova show 1c8a864f-4995-455d-82b7-9de284c5f4d0
+--------------------------------------+----------------------------------------------------------+
| Property                             | Value                                                    |
+--------------------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig                    | AUTO                                                     |
| OS-EXT-AZ:availability_zone          | nova                                                     |
| OS-EXT-SRV-ATTR:host                 | localization-ai1                                         |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | localization-ai1.xura.com                                |
| OS-EXT-SRV-ATTR:instance_name        | instance-000000ac                                        |
| OS-EXT-STS:power_state               | 1                                                        |
| OS-EXT-STS:task_state                | -                                                        |
| OS-EXT-STS:vm_state                  | active                                                   |
| OS-SRV-USG:launched_at               | 2016-07-28T14:08:08.000000                               |
| OS-SRV-USG:terminated_at             | -                                                        |
| accessIPv4                           |                                                          |
| accessIPv6                           |                                                          |
| config_drive                         |                                                          |
| created                              | 2016-07-28T14:07:59Z                                     |
| flavor                               | m1.tiny (1)                                              |
| hostId                               | ad26c73d2d74c8f674d72558802717a0894f36fbe1a9dcbf5afb047d |
| id                                   | 1c8a864f-4995-455d-82b7-9de284c5f4d0                     |
| image                                | Attempt to boot from volume - no image supplied          |
| key_name                             | -                                                        |
| metadata                             | {}                                                       |
| name                                 | VolVM                                                    |
| os-extended-volumes:volumes_attached | [{"id": "2ae0a16c-dcaa-46fb-af05-3f4850a619ec"}]         |
| private network                      | 10.0.0.70                                                |
| progress                             | 0                                                        |
| security_groups                      | default                                                  |
| status                               | ACTIVE                                                   |
| tenant_id                            | d3d042add50946ad9bf0ac48652878ed                         |
| updated                              | 2016-07-28T14:08:09Z                                     |
| user_id                              | b287ed94a53d4a66adb4ff6c5f2e7e1c                         |
+--------------------------------------+----------------------------------------------------------+
$ cinder create --source-volid 2ae0a16c-dcaa-46fb-af05-3f4850a619ec 1
+---------------------+--------------------------------------+
|       Property      |                Value                 |
+---------------------+--------------------------------------+
|     attachments     |                  []                  |
|  availability_zone  |                 nova                 |
|       bootable      |                false                 |
|      created_at     |      2016-07-28T14:09:12.986773      |
| display_description |                 None                 |
|     display_name    |                 None                 |
|      encrypted      |                False                 |
|          id         | b85aab4e-984a-4058-9552-f98b606f2aa3 |
|       metadata      |                  {}                  |
|     multiattach     |                false                 |
|         size        |                  1                   |
|     snapshot_id     |                 None                 |
|     source_volid    | 2ae0a16c-dcaa-46fb-af05-3f4850a619ec |
|        status       |               creating               |
|     volume_type     |                 lvm2                 |
+---------------------+--------------------------------------+
$ cinder list
+--------------------------------------+----------+--------------+------+-------------+----------+--------------------------------------+
|                  ID                  |  Status  | Display Name | Size | Volume Type | Bootable |             Attached to              |
+--------------------------------------+----------+--------------+------+-------------+----------+--------------------------------------+
| 2ae0a16c-dcaa-46fb-af05-3f4850a619ec |  in-use  |      -       |  1   |     lvm2    |   true   | 1c8a864f-4995-455d-82b7-9de284c5f4d0 |
| b85aab4e-984a-4058-9552-f98b606f2aa3 | creating |      -       |  1   |     lvm2    |  false   |                                      |
+--------------------------------------+----------+--------------+------+-------------+----------+--------------------------------------+
$ cinder list
+--------------------------------------+-----------+--------------+------+-------------+----------+--------------------------------------+
|                  ID                  |   Status  | Display Name | Size | Volume Type | Bootable |             Attached to              |
+--------------------------------------+-----------+--------------+------+-------------+----------+--------------------------------------+
| 2ae0a16c-dcaa-46fb-af05-3f4850a619ec |   in-use  |      -       |  1   |     lvm2    |   true   | 1c8a864f-4995-455d-82b7-9de284c5f4d0 |
| b85aab4e-984a-4058-9552-f98b606f2aa3 | available |      -       |  1   |     lvm2    |   true   |                                      |
+--------------------------------------+-----------+--------------+------+-------------+----------+--------------------------------------+
```
- Make sure that the Tenant in OpenStack environment has the Flavor(s). To see them
```
$ nova flavor-list
+--------------------------------------+-------------------------+-----------+------+-----------+------+-------+-------------+-----------+
| ID                                   | Name                    | Memory_MB | Disk | Ephemeral | Swap | VCPUs | RXTX_Factor | Is_Public |
+--------------------------------------+-------------------------+-----------+------+-----------+------+-------+-------------+-----------+
| 1                                    | m1.tiny                 | 512       | 1    | 0         |      | 1     | 1.0         | True      |
| 2                                    | m1.small                | 2048      | 20   | 0         |      | 1     | 1.0         | True      |
+--------------------------------------+-------------------------+-----------+------+-----------+------+-------+-------------+-----------+
```
- Write the Flavors' Name down in the common environment file (environment/common.yaml)
- Make sure that the environment has the Network required for each Unit Type (Admin, SecureZone, SIP Internal and Media). To see them
```
$ neutron net-list
+--------------------------------------+------------------+------------------------------------------------------+
| id                                   | name             | subnets                                              |
+--------------------------------------+------------------+------------------------------------------------------+
| 72a404d0-6ab9-45f4-8e91-fc819a75a7ec | provider-vlan724 | 70a96e1c-a944-4ffb-832a-dbfa5d2daa9d 10.107.204.0/24 |
| a18d2731-eb61-4e7f-b58e-65df64c96494 | provider-vlan723 | dd487738-8f93-431c-b485-e3dc65450acb 10.107.203.0/24 |
+--------------------------------------+------------------+------------------------------------------------------+
```
- Eventually make sure that the environment has the Subnet for each Network (Admin, SecureZone, SIP Internal and Media). To see them
```
$ neutron subnet-list
+--------------------------------------+---------------------+-----------------+-----------------------------------------------------+
| id                                   | name                | cidr            | allocation_pools                                    |
+--------------------------------------+---------------------+-----------------+-----------------------------------------------------+
| 70a96e1c-a944-4ffb-832a-dbfa5d2daa9d | subnet-provider-724 | 10.107.204.0/24 | {"start": "10.107.204.2", "end": "10.107.204.254"}  |
| dd487738-8f93-431c-b485-e3dc65450acb | subnet-provider-723 | 10.107.203.0/24 | {"start": "10.107.203.2", "end": "10.107.203.254"}  |
+--------------------------------------+---------------------+-----------------+-----------------------------------------------------+

```
- Make sure that the environment has all of the required Neutron Ports for each Network for each Unit Type. To see them
```
$ neutron port-list
+--------------------------------------+------+-------------------+---------------------------------------------------------------------------------------+
| id                                   | name | mac_address       | fixed_ips                                                                             |
+--------------------------------------+------+-------------------+---------------------------------------------------------------------------------------+
| 11a0cf62-3ec3-4bd9-8cfd-3cdf0110b930 |      | fa:16:3e:a4:c1:41 | {"subnet_id": "70a96e1c-a944-4ffb-832a-dbfa5d2daa9d", "ip_address": "10.107.204.201"} |
| 624d74c2-3a73-4d76-905b-82692622f39f |      | fa:16:3e:35:8e:e3 | {"subnet_id": "70a96e1c-a944-4ffb-832a-dbfa5d2daa9d", "ip_address": "10.107.204.200"} |
| a5b544f6-2ca7-44f3-814b-4ec466700b02 |      | fa:16:3e:80:30:09 | {"subnet_id": "dd487738-8f93-431c-b485-e3dc65450acb", "ip_address": "10.107.203.201"} |
| c5f4aca6-2706-4cad-9dcb-968652edeca2 |      | fa:16:3e:52:cc:cf | {"subnet_id": "dd487738-8f93-431c-b485-e3dc65450acb", "ip_address": "10.107.203.200"} |
+--------------------------------------+------+-------------------+---------------------------------------------------------------------------------------+
```
- Write Ports' ID and the Port's Mac Address down in the related CSV file for the Unit Type (e.g. environment/omu/admin.csv environment/omu/sz.csv)
- If the Fixed IP Address is displayed write it down in the related CSV file for the Unit Type
- If the Fixed IP Address is NOT displayed it has to come from the Customer. It has to be written down in the related CSV file for the unit Type
  - Each CSV file must have the following format
    - <Neutron Port ID>,<vNIC MAC Address>,<vNIC Fixed IP Address>
```
11a0cf62-3ec3-4bd9-8cfd-3cdf0110b930,fa:16:3e:a4:c1:41,10.107.204.201
```
- Eventually write down Network VLAN (environment/common.yaml)
- Eventually write down the Domain Name (environment/common.yaml)
- Configure the affinity/anti-affinity policy (environment/common.yaml)
- Enable/Disable the development mode (environment/common.yaml)
- Choose the Boot from Local Disk vs Boot from Volume

## Phase 2 - Preparetion Stack
```
$ bash deploy/preparetion-deploy.sh kitv2rc Create
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_IN_PROGRESS | 2016-07-19T11:33:41Z |
+--------------------------------------+------------------+--------------------+----------------------+
```
This phase is responsible of:
- Admin Security Group Creation
- (Anti-)Affinity Group Creation

# Phase 3 - Understanding the Wrapper
The shell script "deploy/units-deploy.sh" is a Wrapper which calls Neutron, Nova and Heat to orchestrate various actions:
- Create
- Update
- Delete
- List
- Replace

For each of those actions will be perform various checks about consistency, correct input data, available data, etc

The only action that is specific for one instance is the Replace action.

## Phase 3.1 - (Anti-)Affinity Rules
In OpenStack until the Mitaka version the Affinity and the Anti-Affinity rules were mandatory actions.
Mandatory means that all of the VM in the same server group MUST stay (Affinity) other or MUST not stay (Anti-Affinity) together.

Here the implementation blueprint which explains what has changed and the reasons.
https://blueprints.launchpad.net/nova/+spec/soft-affinity-for-server-group
```
As a tenant I would like to schedule instances on the same host if possible,
so that I can achieve colocation. However if it is not possible to schedule
some instance to the same host then I still want that the subsequent
instances are scheduled together on another host. In this way I can express
a good-to-have relationship between a group of instances.

As a tenant I would like to schedule instances on different hosts if possible.
However if it is not possible I still want my instances to be scheduled even
if it means that some of them are placed on a host where another instances
are runnig from the same group.

End User might want to have a less strict affinity and anti-affinity
rule than what is today available in server-group API extension.
With the proposed good-to-have affinity rule the End User can request nova
to schedule the instance to the same host if possible. However if it is not
possible (e.g. due to resource limitations) then End User still wants to keep
the instances on a small amount of different host.
With the proposed good-to-have anti-affinity rule the End User can request
nova to spread the instances in the same group as much as possible.
```

So since this Kit has been designed to run on OpenStack Kilo and OpenStack Liberty, a way has to be found in order to have (Anti-)Affinity less strict policies. 
The designed solutions has been implementated as following:
- In the environment file (environment/common.yaml) has been written the Server Group policy to be used ("affinity" or "anti-affinity") for each unit type.
- In the environment file (environment/common.yaml) has been written how many Server Group to be created for each unit type.
- The Preparetion script will create those
- The Unit Deploy script will use a mathematical function called modulo (the %) that will assign for each unit a specific (Anti-)Affinity group - choosing from one previously created

This approch has the following advantages
- Mitigate the current OpenStack (Anti-)Affinity limitation
- Reduce as much as possible the failoure domain if the Anti-Affinity has been chosen
- The OpenStack (Anti-)Affinity is per unit type
- The algorithm uses a random function and it will use all of the Groups equally
  - e.g. 8 omu and 4 host => 2 omu per host
  - e.g. 4 omu and 4 host => 1 omu per host
  - e.g. 10 omu and 1 host => 10 omu per host

Below an example
- Number of CMS to be created = 10 each
- Number of OMU to be created = 5 each
- Number of LVU to be created = 3 each
- Number of MAU to be created = 7 each
- Number of VM-ASU to be created = 4 each
- Number fo physical host available = 4
- Number of Anti-Affinity groups per unit type = 2

```
Unit	Server Group		Hypervisor hostname
CMS1	ServerGroupCMS1		overcloud-compute-0
CMS2	ServerGroupCMS2		overcloud-compute-0
CMS3	ServerGroupCMS1		overcloud-compute-1
CMS4	ServerGroupCMS2		overcloud-compute-1
CMS5	ServerGroupCMS1		overcloud-compute-2
CMS6	ServerGroupCMS2		overcloud-compute-2
CMS7	ServerGroupCMS1		overcloud-compute-3
CMS8	ServerGroupCMS2		overcloud-compute-3
CMS9	ServerGroupCMS1		overcloud-compute-4
CMS10	ServerGroupCMS2		overcloud-compute-4
OMU1	ServerGroupOMU1		overcloud-compute-0
OMU2	ServerGroupOMU2		overcloud-compute-0
OMU3	ServerGroupOMU1		overcloud-compute-1
OMU4	ServerGroupOMU2		overcloud-compute-1
OMU5	ServerGroupOMU1		overcloud-compute-2
LVU1	ServerGroupLVU1		overcloud-compute-0
LVU2	ServerGroupLVU2		overcloud-compute-0
LVU3	ServerGroupLVU1		overcloud-compute-1
MAU1	ServerGroupMAU1		overcloud-compute-0
MAU2	ServerGroupMAU2		overcloud-compute-0
MAU3	ServerGroupMAU1		overcloud-compute-1
MAU4	ServerGroupMAU2		overcloud-compute-1
MAU5	ServerGroupMAU1		overcloud-compute-2
MAU6	ServerGroupMAU2		overcloud-compute-2
MAU7	ServerGroupMAU1		overcloud-compute-3
VM-ASU1	ServerGroupVM-ASU1	overcloud-compute-0
VM-ASU2	ServerGroupVM-ASU2	overcloud-compute-0
VM-ASU3	ServerGroupVM-ASU1	overcloud-compute-1
VM-ASU4	ServerGroupVM-ASU2	overcloud-compute-1
```
So the right formula to calculate the number of required Anti-Affinity groups is the following one
```
<Total number of VMs>/<Total Number of hosts> = The result to round up to the next integer (aka 3.7 -> 4)
```
In our case: (4+8)/3 = 4

In general:
- A high number of Anti-Affinity is less safe since less VM will be in the same Anti-Affinity group and so potentially all together in the same hypervisor
- A low number of Anti-Affinity is ideal but the Nova Schedule could fail to find a valid hypervisor for the VM
- About 99.9% of the time the mathematics functiona will work as expected but something it can do something different, so the above schema is theoretical but not too far from the reality

Limitations:
- If you want to create one VM per each unit type all of the VMs will be in the same physical host
- Given the previous limitation, with the current implementation, all of the VM with the same index (aka OMU1 -> 1 is the index) will be always together

## Phase 3.2 - Create a Unit Type Group
```
$ bash deploy/units-deploy.sh kitv2rc Create OMU
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: 624d74c2-3a73-4d76-905b-82692622f39f
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| a389e59c-dbe6-485e-892a-187623d28eaa | omu1             | CREATE_IN_PROGRESS | 2016-07-19T16:37:15Z |
+--------------------------------------+------------------+--------------------+----------------------+
Updated port: a5b544f6-2ca7-44f3-814b-4ec466700b02
Updated port: a5b544f6-2ca7-44f3-814b-4ec466700b02
Updated port: 11a0cf62-3ec3-4bd9-8cfd-3cdf0110b930
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| a389e59c-dbe6-485e-892a-187623d28eaa | omu1             | CREATE_IN_PROGRESS | 2016-07-19T16:37:15Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | CREATE_IN_PROGRESS | 2016-07-19T16:37:25Z |
+--------------------------------------+------------------+--------------------+----------------------+

```
Action performed by the Wrapper:
- Read the CSV files
- Update the Security Group of each Port
- Create OMU Unit Types for each Port available

## Phase 3.3 - List a Unit Type Group
```
$ bash deploy/units-deploy.sh kitv2rc List OMU
+---------------+--------------------------------------+------------------+-----------------+----------------------+-----------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status | updated_time         | parent_resource |
+---------------+--------------------------------------+------------------+-----------------+----------------------+-----------------+
| omu_unit      | 0df76423-ce88-4413-8b54-9c5a53a572c5 | OS::Nova::Server | CREATE_COMPLETE | 2016-07-19T16:37:15Z |                 |
+---------------+--------------------------------------+------------------+-----------------+----------------------+-----------------+
+---------------+--------------------------------------+------------------+-----------------+----------------------+-----------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status | updated_time         | parent_resource |
+---------------+--------------------------------------+------------------+-----------------+----------------------+-----------------+
| omu_unit      | 45a4afe9-c660-4413-ae45-2319e2a54eb3 | OS::Nova::Server | CREATE_COMPLETE | 2016-07-19T16:37:25Z |                 |
+---------------+--------------------------------------+------------------+-----------------+----------------------+-----------------+
```
Action performed by the Wrapper:
- Display the resource status for each Heat Stack (Each Unit has a dedicated Heat Stack in order to accomplish the requirement to have static Port assignment)

## Phase 3.4 - Update a Unit Type Group
```
$ bash deploy/units-deploy.sh kitv2rc Update OMU
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: 624d74c2-3a73-4d76-905b-82692622f39f
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| a389e59c-dbe6-485e-892a-187623d28eaa | omu1             | UPDATE_IN_PROGRESS | 2016-07-19T16:37:15Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | CREATE_COMPLETE    | 2016-07-19T16:37:25Z |
+--------------------------------------+------------------+--------------------+----------------------+
Updated port: a5b544f6-2ca7-44f3-814b-4ec466700b02
Updated port: a5b544f6-2ca7-44f3-814b-4ec466700b02
Updated port: 11a0cf62-3ec3-4bd9-8cfd-3cdf0110b930
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| a389e59c-dbe6-485e-892a-187623d28eaa | omu1             | UPDATE_COMPLETE    | 2016-07-19T16:37:15Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | UPDATE_IN_PROGRESS | 2016-07-19T16:37:25Z |
+--------------------------------------+------------------+--------------------+----------------------+
```
Action performed by the Wrapper:
- Read the CSV files
- Update the Security Group of each Port
- Update OMU Unit Types for each Port available

## Phase 3.5 - Replace a specific Unit Type in a Group
```
$ bash deploy/units-deploy.sh kitv2rc Replace OMU 1
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| a389e59c-dbe6-485e-892a-187623d28eaa | omu1             | DELETE_IN_PROGRESS | 2016-07-19T16:37:15Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | UPDATE_COMPLETE    | 2016-07-19T16:37:25Z |
+--------------------------------------+------------------+--------------------+----------------------+
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status    | updated_time         |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| omu_unit      | 0df76423-ce88-4413-8b54-9c5a53a572c5 | OS::Nova::Server | DELETE_IN_PROGRESS | 2016-07-19T16:37:15Z |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status    | updated_time         |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| omu_unit      | 0df76423-ce88-4413-8b54-9c5a53a572c5 | OS::Nova::Server | DELETE_IN_PROGRESS | 2016-07-19T16:37:15Z |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status    | updated_time         |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| omu_unit      | 0df76423-ce88-4413-8b54-9c5a53a572c5 | OS::Nova::Server | DELETE_IN_PROGRESS | 2016-07-19T16:37:15Z |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status    | updated_time         |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| omu_unit      | 0df76423-ce88-4413-8b54-9c5a53a572c5 | OS::Nova::Server | DELETE_IN_PROGRESS | 2016-07-19T16:37:15Z |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| resource_name | physical_resource_id                 | resource_type    | resource_status    | updated_time         |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
| omu_unit      | 0df76423-ce88-4413-8b54-9c5a53a572c5 | OS::Nova::Server | DELETE_IN_PROGRESS | 2016-07-19T16:37:15Z |
+---------------+--------------------------------------+------------------+--------------------+----------------------+
Stack not found: omu1
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: 624d74c2-3a73-4d76-905b-82692622f39f
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | UPDATE_COMPLETE    | 2016-07-19T16:37:25Z |
| b580a641-903e-4600-aa6a-5446d1e375ed | omu1             | CREATE_IN_PROGRESS | 2016-07-19T16:42:15Z |
+--------------------------------------+------------------+--------------------+----------------------+
```
Action performed by the Wrapper:
- Read the CSV files
- Delete the related Unit
- Wait unitl has been deleted
- Update the Security Group of each Port
- Create OMU Unit Types for each Port available

## Phase 3.6 - Delete a Unit Type Group
```
$ bash deploy/units-deploy.sh kitv2rc Delete OMU
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | DELETE_IN_PROGRESS | 2016-07-19T16:37:25Z |
| b580a641-903e-4600-aa6a-5446d1e375ed | omu1             | CREATE_COMPLETE    | 2016-07-19T16:42:15Z |
+--------------------------------------+------------------+--------------------+----------------------+
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 96961593-cde7-4c4e-b895-b3f405412a03 | PreparetionStack | CREATE_COMPLETE    | 2016-07-19T11:33:44Z |
| 7d62a0a4-1334-4fb7-a40c-0e1273a7ad12 | omu2             | DELETE_IN_PROGRESS | 2016-07-19T16:37:25Z |
| b580a641-903e-4600-aa6a-5446d1e375ed | omu1             | DELETE_IN_PROGRESS | 2016-07-19T16:42:15Z |
+--------------------------------------+------------------+--------------------+----------------------+
Updated port: c5f4aca6-2706-4cad-9dcb-968652edeca2
Updated port: a5b544f6-2ca7-44f3-814b-4ec466700b02
```
Action performed by the Wrapper:
- Read the CSV files
- Delete all of the OMU Unit Type

# Admin command to create the Neutron Ports for users
```
$ neutron port-create --fixed-ip ip_address=10.107.203.250 --tenant-id 4507ca536d42408093e0fb10d336c275 provider-vlan723
Created a new port:
+-----------------------+---------------------------------------------------------------------------------------+
| Field                 | Value                                                                                 |
+-----------------------+---------------------------------------------------------------------------------------+
| admin_state_up        | True                                                                                  |
| allowed_address_pairs |                                                                                       |
| binding:host_id       |                                                                                       |
| binding:profile       | {}                                                                                    |
| binding:vif_details   | {}                                                                                    |
| binding:vif_type      | unbound                                                                               |
| binding:vnic_type     | normal                                                                                |
| device_id             |                                                                                       |
| device_owner          |                                                                                       |
| fixed_ips             | {"subnet_id": "dd487738-8f93-431c-b485-e3dc65450acb", "ip_address": "10.107.203.250"} |
| id                    | a5b544f6-2ca7-44f3-814b-4ec466700b02                                                  |
| mac_address           | fa:16:3e:80:30:09                                                                     |
| name                  |                                                                                       |
| network_id            | a18d2731-eb61-4e7f-b58e-65df64c96494                                                  |
| security_groups       | 134ddb86-6a66-48f4-8fe1-cc6f1274a728                                                  |
| status                | DOWN                                                                                  |
| tenant_id             | 4507ca536d42408093e0fb10d336c275                                                      |
+-----------------------+---------------------------------------------------------------------------------------+
```
