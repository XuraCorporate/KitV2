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
bash deploy/preparetion-deploy.sh kitv2rc Create
```
