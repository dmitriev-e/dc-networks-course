Создание Subnet'а для VNet - это создание подсети в зоне, которая будет использоваться для VNet.

Внутри системы создаётся bridge интерфейс для подсети.

```sh
9: vnet10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1300 qdisc noqueue master vrf_Zone1 state UP group default qlen 1000
    link/ether bc:24:11:50:dd:53 brd ff:ff:ff:ff:ff:ff
    inet 192.168.10.1/24 scope global vnet10
       valid_lft forever preferred_lft forever
    inet6 fe80::be24:11ff:fe50:dd53/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

В этот bridge подключется соответствующий vxlan интерфейс.

```sh
$ brctl show
bridge name     bridge id               STP enabled     interfaces
vnet10          8000.bc241150dd53       no              vxlan_vnet10
```
