# Mikrotik-RT1 RouterOS 7 configuration
# Lab 08 - Border Router for DC Fabric
# AS: 65100
# Interfaces:
#   ether1 - WAN (DHCP, NAT masquerade) - 10.64.164.0/23
#   ether3 - trunk to bgw-leaf-1 (VLAN10=TENANT1, VLAN20=TENANT2)
#   ether2 - trunk to bgw-leaf-2 (VLAN10=TENANT1, VLAN20=TENANT2)
#   loopback - 10.1.3.1/32

# --- Loopback ---
/interface bridge
add name=loopback comment="Router Loopback"

/ip address
add address=10.1.3.1/32 interface=loopback comment="Loopback"

# --- WAN (ether1) ---
/ip dhcp-client
add interface=ether1 disabled=no comment="WAN DHCP"

# --- Internal transit VLANs to BGW (per-tenant) ---
/interface vlan
add name=vlan10-ether3 interface=ether3 vlan-id=10 comment="TENANT1 -> bgw-leaf-1"
add name=vlan20-ether3 interface=ether3 vlan-id=20 comment="TENANT2 -> bgw-leaf-1"
add name=vlan10-ether2 interface=ether2 vlan-id=10 comment="TENANT1 -> bgw-leaf-2"
add name=vlan20-ether2 interface=ether2 vlan-id=20 comment="TENANT2 -> bgw-leaf-2"

/ip address
add address=100.1.1.1/31 interface=vlan10-ether3 comment="TENANT1 link to bgw-leaf-1"
add address=100.1.2.1/31 interface=vlan20-ether3 comment="TENANT2 link to bgw-leaf-1"
add address=100.2.1.1/31 interface=vlan10-ether2 comment="TENANT1 link to bgw-leaf-2"
add address=100.2.2.1/31 interface=vlan20-ether2 comment="TENANT2 link to bgw-leaf-2"

# --- NAT masquerade for all fabric traffic going to WAN ---
/ip firewall nat
add chain=srcnat out-interface=ether1 action=masquerade comment="NAT MSQ for DC fabric"

# --- BGP ---
/routing bgp template
add name=default as=65100 router-id=10.1.3.1

# Peer with bgw-leaf-1 TENANT1
/routing bgp connection
add name=to-bgw-leaf-1-t1 \
    as=65100 \
    router-id=10.1.3.1 \
    remote.address=100.1.1.0 \
    remote.as=65005 \
    local.address=100.1.1.1 \
    local.role=ebgp \
    output.default-originate=always \
    output.redistribute=connected,static \
    comment="BGP to bgw-leaf-1 TENANT1"

# Peer with bgw-leaf-1 TENANT2
/routing bgp connection
add name=to-bgw-leaf-1-t2 \
    as=65100 \
    router-id=10.1.3.1 \
    remote.address=100.1.2.0 \
    remote.as=65005 \
    local.address=100.1.2.1 \
    local.role=ebgp \
    output.default-originate=always \
    output.redistribute=connected,static \
    comment="BGP to bgw-leaf-1 TENANT2"

# Peer with bgw-leaf-2 TENANT1
/routing bgp connection
add name=to-bgw-leaf-2-t1 \
    as=65100 \
    router-id=10.1.3.1 \
    remote.address=100.2.1.0 \
    remote.as=65006 \
    local.address=100.2.1.1 \
    local.role=ebgp \
    output.default-originate=always \
    output.redistribute=connected,static \
    comment="BGP to bgw-leaf-2 TENANT1"

# Peer with bgw-leaf-2 TENANT2
/routing bgp connection
add name=to-bgw-leaf-2-t2 \
    as=65100 \
    router-id=10.1.3.1 \
    remote.address=100.2.2.0 \
    remote.as=65006 \
    local.address=100.2.2.1 \
    local.role=ebgp \
    output.default-originate=always \
    output.redistribute=connected,static \
    comment="BGP to bgw-leaf-2 TENANT2"
