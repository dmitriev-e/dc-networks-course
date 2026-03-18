Если мы назначаем exit-nodes для зоны, то это значит, что в этой зоне будут использоваться только эти exit-nodes для маршрутизации через GRT этих хостов

Пример конфигурации FRR для зоны Zone1 с exit-nodes:

```sh
!
frr version 10.4.1
frr defaults datacenter
hostname dcx-pod2-cl2-prox-1
log syslog informational
service integrated-vtysh-config
!
ip prefix-list only_default seq 1 permit 0.0.0.0/0
!
ipv6 prefix-list only_default_v6 seq 1 permit ::/0
!
route-map MAP_VTEP_IN deny 1
 match ip address prefix-list only_default
exit
!
route-map MAP_VTEP_IN deny 2
 match ipv6 address prefix-list only_default_v6
exit
!
route-map MAP_VTEP_IN permit 3
exit
!
route-map MAP_VTEP_OUT permit 1
exit
!
vrf vrf_Zone1
 ip route 192.168.20.0/24 Null0
 ip route 192.168.21.0/24 Null0
 ip route 192.168.30.0/24 Null0
 ip route 192.168.31.0/24 Null0
 vni 10000
exit-vrf
!
vrf vrf_Zone2
 vni 20000
exit-vrf
!
vrf vrf_Zone3
 vni 30000
exit-vrf
!
router bgp 65502
 bgp router-id 10.12.0.3
 no bgp hard-administrative-reset
 no bgp default ipv4-unicast
 coalesce-time 1000
 no bgp graceful-restart notification
 neighbor VTEP peer-group
 neighbor VTEP remote-as 65502
 neighbor VTEP bfd
 neighbor 10.12.0.1 peer-group VTEP
 neighbor 10.12.0.5 peer-group VTEP
 !
 address-family ipv4 unicast
  import vrf vrf_Zone1
 exit-address-family
 !
 address-family ipv6 unicast
  import vrf vrf_Zone1
 exit-address-family
 !
 address-family l2vpn evpn
  neighbor VTEP activate
  neighbor VTEP route-map MAP_VTEP_IN in
  neighbor VTEP route-map MAP_VTEP_OUT out
  advertise-all-vni
 exit-address-family
exit
!
router bgp 65502 vrf vrf_Zone1
 bgp router-id 10.12.0.3
 no bgp hard-administrative-reset
 no bgp graceful-restart notification
 !
 address-family ipv4 unicast
  redistribute connected
 exit-address-family
 !
 address-family ipv6 unicast
  redistribute connected
 exit-address-family
 !
 address-family l2vpn evpn
  default-originate ipv4
  default-originate ipv6
 exit-address-family
exit
!
router bgp 65502 vrf vrf_Zone2
 bgp router-id 10.12.0.3
 no bgp hard-administrative-reset
 no bgp graceful-restart notification
 !
 address-family ipv4 unicast
  redistribute connected
 exit-address-family
 !
 address-family ipv6 unicast
  redistribute connected
 exit-address-family
 !
 address-family l2vpn evpn
  advertise ipv4 unicast
  advertise ipv6 unicast
 exit-address-family
exit
!
router bgp 65502 vrf vrf_Zone3
 bgp router-id 10.12.0.3
 no bgp hard-administrative-reset
 no bgp graceful-restart notification
 !
 address-family ipv4 unicast
  redistribute connected
 exit-address-family
 !
 address-family ipv6 unicast
  redistribute connected
 exit-address-family
 !
 address-family l2vpn evpn
  advertise ipv4 unicast
  advertise ipv6 unicast
 exit-address-family
exit
!
end
```