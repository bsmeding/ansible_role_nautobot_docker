import ipaddress

from django_jinja import library

@library.filter
def get_hostmask(address):
    ip_address = ipaddress.ip_network(address, False)
    return str(ip_address.hostmask)

@library.filter
def get_netmask(address):
    ip_address = ipaddress.ip_network(address, False)
    return str(ip_address.netmask)

@library.filter
def get_subnet(address):
    ip_address = ipaddress.IPv4Network(address, False)
    return str(ip_address[0])

@library.filter
def get_first_ip(address):
    ip_address = ipaddress.ip_network(address, False)
    return str(ip_address[1]) 