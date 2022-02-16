network:
  version: 2
  ethernets:
    eth0:
      match:
        macaddress: '${node_mac_address}'
      wakeonlan: true
      dhcp4: false
      addresses:
        - ${node_ip}
      gateway4: ${node_gateway}
      nameservers:
        search: ['${node_dns_search_domain}']
        addresses: [${node_dns}]
    eth1:
      match:
        macaddress: '${storage_node_mac_address}'
      wakeonlan: true
      dhcp4: false
      addresses:
        - ${storage_node_ip}
      gateway4: ${storage_node_gateway}
      nameservers:
        search: ['${storage_node_dns_search_domain}']
        addresses: [${storage_node_dns}]
      mtu: 9000

locale: en_US.UTF-8
timezone: Europe/Stockholm
local-hostname: ${node_hostname}
instance-id: ${node_hostname}