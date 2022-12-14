Nautobot
========

This Role will include the docker role, depends on the docker role to prepare the servers. That docker role relay on the [geerlingguy.docker role](https://github.com/geerlingguy/ansible-role-docker) to prepare the OS and install Docker on OS level.


Git as Data Source
==================

Read more: https://docs.nautobot.com/projects/core/en/v1.0.0/user-guides/git-data-source/
https://docs.nautobot.com/projects/core/en/v1.0.0/models/extras/configcontext/

Install Nautobot docker
=======================

Example playbook to install Nautobot on Docker container

Basic install: (Create/ use an inventory with group nautobot or change hosts)

Install pip requirementes on ansible host
`pip install -r requirements.txt` # NOTE .txt for Python install

First install requirements.yml file:

```
roles:
- name: bsmeding.docker
- name: bsmeding.nautobot_docker
```

Install the required roles:
`ansible-galaxy install -r requirements.yml`


Run playbook to install Docker and Nautobot
```
---
- name: Install Nautobot
  hosts: [nautobot]
  gather_facts: true
  become: yes
  tasks:
    - name: Check if docker is installed
      include_role:
        name: bsmeding.docker

    - name: Check if nautobot is installed
      include_role:
        name: bsmeding.nautobot_docker

```
After succesfull installation, Nautobot runs on port 8080 (default), login is admin/admin

To change the superuser login and or ports: (see all possible variables in ./defaults/main.yml)

```
---
- name: Install Nautobot
  hosts: [nautobot]
  gather_facts: true
  become: yes
  vars:
    nautobot__superuser_name: admin
    nautobot__superuser_password: mysupersecretpassword
    nautobot__port_http: 8888
    nautobot__superuser_api_token: "1234567890abcdefghijklmnopqrstuvwxyz0987"
    nautobot__napalm_username: cisco
    nautobot__napalm_password: cisco    
  tasks:
    - name: Check if docker is installed
      include_role:
        name: bsmeding.docker

    - name: Check if nautobot is installed
      include_role:
        name: bsmeding.nautobot_docker


```


Manual config tasks
===================
Some tasks needs to be set manual (at this moment, try to update repo so that this can be done automatically, but need to rely on the API possibilities of Nautobot)

Manual tasks:
* Add git repositories
* Add LDAP groups (when not synct from LDAP server)
* Add permission to group
* Add users to groups
* Add Git repositories for Golden config and job sync

* Add GraphQL queries so that the variables can be retreived in the Jinja templating (Extensibility -> GrpahSQL Queries)

Examplje GraphQL

````
query ($device_id: ID!) {
  device(id: $device_id) {
    config_context
    hostname: name
    position
    serial
    primary_ip4 {
      id
      primary_ip4_for {
        id
        name
      }
    }
    tenant {
      name
    }
    tags {
      name
      slug
    }
    device_role {
      name
    }
    platform {
      name
      slug
      manufacturer {
        name
      }
      napalm_driver
    }
    site {
      name
      slug
      vlans {
        id
        name
        vid
      }
      vlan_groups {
        id
      }
    }
    interfaces {
      description
      mac_address
      enabled
      name
      ip_addresses {
        address
        tags {
          id
        }
      }
      connected_circuit_termination {
        circuit {
          cid
          commit_rate
          provider {
            name
          }
        }
      }
      tagged_vlans {
        id
      }
      untagged_vlan {
        id
      }
      cable {
        termination_a_type
        status {
          name
        }
        color
      }
      tagged_vlans {
        site {
          name
        }
        id
      }
      tags {
        id
      }
    }
  }
}
````


* Configure golden-config plugin with Git repo, template path and SSot (GraphQL) query


# Error handling
When the stack doesnt start after a hard shutdown (nog containers shutdown but VM is hard shutdown) is it possible that Redis file is corrupt. You see the message `Bad file format reading the append only file appendonly.aof.1.incr.aof: make a backup of your AOF file, then use ./redis-check-aof --fix <filename.manifest>`
Then find the Docker path (`docker inspect nautobot-redis`) and go to this folder
Run the check command `sudo redis-check-aof --fix appendonly.aof.1.incr.aof`

# computed fields

## Ansible slug
To set correct ansible vnedor plugin, add a computed field, named: `Ansible Network OS` type `dcim|platform` and slug: `ansible_network_os`
content:
```
{% if obj.slug == 'arista_eos' %}
arista.eos.eos
{% elif obj.slug == 'cisco_asa' %}
cisco.asa.asa
{% elif obj.slug == 'cisco_ios' %}
cisco.ios.ios
{% elif obj.slug == 'cisco_xr' %}
cisco.iosxr.iosxr
{% elif obj.slug == 'cisco_xe' %}
cisco.ios.ios
{% elif obj.slug == 'cisco_nxos' %}
cisco.nxos.nxos
{% elif obj.slug == 'juniper_junos' %}
junipernetworks.junos.junos
{% else %}
{% endif %}
```


# TODO

* Add variables to readme
* Variable more the nautobot_config.py, now there are a lot of static config lines
* add uwsgi template to variables
