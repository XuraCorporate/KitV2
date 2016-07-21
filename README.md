# Heat V2 Kit Deploy for Xura
This deployment kit has been developed based on some requirements.
One of them is the fully VM(s) isolation from the OpenStack API or not be able to call the OpenStack Metadata server.

# Requirements
In order to run this Kit a Linux box is required.
The following packages are required:
- git
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

# Phase 1 - Preparetion
## Phase 1.1 - Git
The Kit can be cloned by GitHub with the following command:
```
$ git clone git@github.com:XuraCorporate/KitV2.git
```
## Phase 1.2 - Preparetion Stack
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
- Anti-Affinity Group Creation

# Phase 2 - Environment file preparetion
This phase is the "hand on" part, which requires a number of things:
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

# Phase 3 - Understanding the Wrapper
The shell script "deploy/units-deploy.sh" is a Wrapper which calls Neutron, Nova and Heat to orchestrate various actions:
- Create
- Update
- Delete
- List
- Replace

The only action that is specific for one instance is the Replace action.

## Phase 3.1 - Create a Unit Type
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

## Phase 3.2 - List a Unit Type
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

## Phase 3.3 - Update a Unit Type
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

## Phase 3.4 - Replace a specific Unit
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

## Phase 3.5 - Delete a Unit Type
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
