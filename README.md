Nautobot
========

Nautobot is an network CMDB tool created for and by network automation specialist from NetworkToCode. It is an fork from Netbox (2.x) and added with a lot af nice features to create a Single Source of Trouth for your automation platform.

This role will install Nautobot as docker container. If you need docker aswell, so you can build the whole application at once please consider the Ansible role `bsmeding.docker` that will prepare you're server and install docker.

Support for version 1.x and 2.x. Default version 2 will be installed and tested:
![test status](https://github.com/bsmeding/ansible_role_nautobot_docker/actions/workflows/ci.yml/badge.svg) 
Role is tested on, Ubuntu with Docker installed via my role bsmeding.docker on Linux distribution.

Git as Data Source
==================

Read more https://docs.nautobot.com/projects/core/en/v1.0.0/user-guides/git-data-source/
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
When the stack doesn't start after a hard shutdown of the VM (no containers shutdown but VM is hard shutdown) is it possible that Redis file is corrupt. You see the message `Bad file format reading the append only file appendonly.aof.1.incr.aof: make a backup of your AOF file, then use ./redis-check-aof --fix <filename.manifest>`
Then find the Docker path (`docker inspect nautobot-redis`) and go to this folder
Run the check command `sudo redis-check-aof --fix appendonly.aof.1.incr.aof`

# computed fields

## Ansible slug
To set correct ansible vendor plugin, add a computed field, named: `Ansible Network OS` type `dcim|platform` and slug: `ansible_network_os`
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

# Install plugins
To install plugins, set the variable `nautobot__plugins` with the desired plugins to install, example:

```
nautobot__plugins:
  - plugin_name: nautobot_device_onboarding
    plugin_config: {
          "nautobot_device_onboarding": {
            "default_ip_status": "Active",
            "default_device_role": "onboarding",
            "skip_device_type_on_update": True,
          }
        }
  - plugin_name: nautobot-ssot
    plugin_config: {}
  - plugin_name: nautobot-plugin-nornir
    plugin_config: {
      "nautobot_plugin_nornir": {
        "use_config_context": {"secrets": False, "connection_options": True},
        # Optionally set global connection options.
        "connection_options": {
            "napalm": {
                "extras": {
                    "optional_args": {"global_delay_factor": 1},
                },
            },
            "netmiko": {
                "extras": {
                    "global_delay_factor": 1,
                },
            },
        },
        "nornir_settings": {
            "credentials": "nautobot_plugin_nornir.plugins.credentials.env_vars.CredentialsEnvVars",
            "runner": {
                "plugin": "threaded",
                "options": {
                    "num_workers": 20,
                },
            },
        },
      }
    }
  - plugin_name: nautobot-golden-config
    plugin_config: {
        "nautobot_golden_config": {
          "per_feature_bar_width": 0.15,
          "per_feature_width": 13,
          "per_feature_height": 4,
          "enable_backup": False,
          "enable_compliance": False,
          "enable_intended": True,
          "enable_sotagg": True,
          "sot_agg_transposer": None,
          "enable_postprocessing": False,
          "postprocessing_callables": [],
          "postprocessing_subscribed": [],
          "platform_slug_map": None,
          # "get_custom_compliance": "my.custom_compliance.func"
        }
    }
  - plugin_name: nautobot-device-lifecycle-mgmt
    plugin_config: {
        "nautobot_device_lifecycle_mgmt": {
            "barchart_bar_width": float(0.1)),
            "barchart_width": int(12),
            "barchart_height": int(5),
        }
    }
  - plugin_name: nautobot-firewall-models
    plugin_config: {
        "nautobot_firewall_models": {
            "default_status": "active"
        }
    }
  - plugin_name: nautobot-ssot
    plugin_config: {
        "nautobot_ssot": {
            "hide_example_jobs": True,
        }
  }
```

# TODO

* Add variables to readme
* Variable more the nautobot_config.py, now there are a lot of static config lines
* add uwsgi template to variables
