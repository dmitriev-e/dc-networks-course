ASN - номер автономной системы
Если нет отдельной конфигурации BGP на ноде, то по-умолчанию создаётся iBGP соседство с Peers в рамках одной ASN.

Peers - iBGP соседи для **address-family l2vpn evpn**
Обычно создаётся peer-group VTEP

```sh
!
router bgp 65501
 bgp router-id 10.11.0.3
 no bgp hard-administrative-reset
 no bgp default ipv4-unicast
 coalesce-time 1000
 no bgp graceful-restart notification
 neighbor VTEP peer-group
 neighbor VTEP remote-as 65501
 neighbor VTEP bfd
 neighbor 10.11.0.1 peer-group VTEP
 neighbor 10.11.0.5 peer-group VTEP
 !
 address-family l2vpn evpn
  neighbor VTEP activate
  neighbor VTEP route-map MAP_VTEP_IN in
  neighbor VTEP route-map MAP_VTEP_OUT out
  advertise-all-vni
 exit-address-family
exit
```