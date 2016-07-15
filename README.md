# Heat V2 Kit Deploy

# Admin command to create port
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

# Phase 1 - Preparetion
```
$ bash deploy/preparetion-deploy.sh kitv2rc Create
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 386bfbd6-bcad-4b01-b6d7-d5340f41b834 | PreparetionStack | CREATE_IN_PROGRESS | 2016-07-15T14:35:03Z |
+--------------------------------------+------------------+--------------------+----------------------+
```
This phase is responsible of:
- TenantNetwork
- TenantSubnet
- TenantSecurityGroup
- AdminSecurityGroup

# Phase 2 - Environment file preparetion
This phase is the hand on part, which it requires a number of things:
- Make sure that the environment has the Imaga(s) and write it/them down in the common environment file (environment/common.yaml)
- Make sure that the environment has the Flavor(s) and write it/them down in the common environment file (environment/common.yaml)
- Make sure that each Unit Type has a dedicated CSV file per network (e.g. OMU has two CSV file, one for Admin and other one for Secure Zone - environment/omu/admin.csv environment/omu/sz.csv)

# Phase 3 - Create Unit Type
```
$ bash deploy/omu-deploy.sh kitv2rc Create environment/omu/admin.csv environment/omu/sz.csv
+--------------------------------------+------------------+--------------------+----------------------+
| id                                   | stack_name       | stack_status       | creation_time        |
+--------------------------------------+------------------+--------------------+----------------------+
| 386bfbd6-bcad-4b01-b6d7-d5340f41b834 | PreparetionStack | CREATE_COMPLETE    | 2016-07-15T14:35:03Z |
| 283220bb-e37c-46f1-9917-f9d8f66fc5e3 | omu1             | CREATE_IN_PROGRESS | 2016-07-15T14:36:43Z |
+--------------------------------------+------------------+--------------------+----------------------+
```
This phase is responsible of:
- Create the Unit Type for the given number of interfaces
