network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - ${node_ip}
      gateway4: ${node_gateway}
      nameservers:
        addresses:
          - ${node_dns}
        search:
        - '${node_dns_search_domain}'
    eth1:
      dhcp4: false
      addresses:
        - ${storage_node_ip}
      gateway4: ${storage_node_gateway}
      nameservers:
        addresses:
          - ${storage_node_dns}
        search:
        - '${storage_node_dns_search_domain}'

locale: en_US.UTF-8
timezone: Europe/Stockholm
local-hostname: ${node_hostname}
instance-id: ${node_hostname}