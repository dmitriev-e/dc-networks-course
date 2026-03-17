Zone - L3VNI - отдельный VRF
VNet - L2VNI - по сути это bridge (у которого master-ом является L3VNI (Zone/VRF) в котором он работает). С этим bridge бриджуеется VXLAN интерфейс, который отвечает за L2VNI внутри этого L2-домена.

VRF-VXLAN TAG - это VNI для L3VNI



Advertise Subnets
добавляет в каждый VRF анонс Type-5 маршрутов с каждой ноды

```sh
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
```


MTU - устанавливает MTU на Vnet-ы зоны и vxlan-интерфейсы для них

```sh
9: vnet10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1300 qdisc noqueue master vrf_Zone1 state UP group default qlen 1000
    link/ether bc:24:11:a5:a9:8c brd ff:ff:ff:ff:ff:ff
    inet 192.168.10.1/24 scope global vnet10
       valid_lft forever preferred_lft forever
    inet6 fe80::be24:11ff:fea5:a98c/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

10: vrf_Zone1: <NOARP,MASTER,UP,LOWER_UP> mtu 65575 qdisc noqueue state UP group default qlen 1000
    link/ether 76:7d:42:ab:84:51 brd ff:ff:ff:ff:ff:ff

12: vnet11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1300 qdisc noqueue master vrf_Zone1 state UP group default qlen 1000
    link/ether bc:24:11:a5:a9:8c brd ff:ff:ff:ff:ff:ff
    inet 192.168.11.1/24 scope global vnet11
       valid_lft forever preferred_lft forever
    inet6 fe80::be24:11ff:fea5:a98c/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

...

38: vxlan_vnet10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1300 qdisc noqueue master vnet10 state UNKNOWN group default qlen 1000
    link/ether 1a:ab:9d:8e:42:f5 brd ff:ff:ff:ff:ff:ff
39: vxlan_vnet11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1300 qdisc noqueue master vnet11 state UNKNOWN group default qlen 1000
    link/ether 7e:e6:82:d8:a7:e8 brd ff:ff:ff:ff:ff:ff

```