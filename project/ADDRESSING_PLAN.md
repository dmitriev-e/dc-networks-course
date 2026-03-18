# Адресный план: Multi-DC SDN Overlay

Документ синхронизирован с фактическими конфигурациями из `project/configs/` и с capture `explain/double_overlay.png`.

## 1. Сводка ASN

| Сегмент | ASN |
|---|---|
| PoD1 spines | `65401` |
| PoD1 leafs | `65511-65514` |
| PoD1 BGW | `65515-65516` |
| PoD1 Linux servers (`evpn-rt`, PVE cluster) | `65501` |
| PoD1 hoster tenant AS наружу | `64501` |
| PoD2 spines | `65402` |
| PoD2 leafs | `65521-65524` |
| PoD2 BGW | `65525-65526` |
| PoD2 Linux servers (`evpn-rt`, PVE cluster) | `65502` |
| PoD2 hoster tenant AS наружу | `64502` |
| PoD3 spines | `65403` |
| PoD3 leafs | `65531-65534` |
| PoD3 BGW | `65535-65536` |
| PoD3 Linux servers (`evpn-rt`, PVE cluster) | `65503` |
| PoD3 hoster tenant AS наружу | `64503` |
| `interpod-rt-1/2` | `65012` |
| `city1-core-rt1/rt2` | `65011` |
| `city2-core-rt1/rt2` | `65021` |

### Комментарий по AS-path

Внешне фабрика каждого PoD представляется в наше ядро как отдельный tenant-AS:

- `PoD1 -> AS 64501`
- `PoD2 -> AS 64502`
- `PoD3 -> AS 64503`

Это видно в Arista BGW-конфигах через `local-as ... no-prepend replace-as`.

## 2. VRF и VNI-модель

### Hoster fabric

| PoD | Hoster VRF | Hoster L3VNI | RT import/export | Server aggregate |
|---|---|---|---|---|
| PoD1 | `TENANT-X` | `50001` | `1:50001` | `10.11.0.0/16` |
| PoD2 | `TENANT-Y` | `50002` | `1:50002` | `10.12.0.0/16` |
| PoD3 | `TENANT-Z` | `50003` | `1:50003` | `10.13.0.0/16` |

### Inner Proxmox overlay

| Overlay zone | Prefix | Подтверждённый inner VNI | VNet | L2VNI |
|---|---|---|---|---|
| `Zone1` | `192.168.10.0/23` | `10000` | `pod1-vnet10` / `pod1-vnet11` | `10010`, `10011` |
| `Zone2` | `192.168.20.0/23` | `20000` | `pod2-vnet20` / `pod2-vnet21` | `10020`, `10021` |
| `Zone3` | `192.168.30.0/23` | `30000` | `pod3-vnet30` / `pod3-vnet31` | `10030`, `10031` |

Примечания:

- Outer VNI `50001/50002/50003` подтверждаются конфигами leaf/BGW.
- Inner VNI `10000/20000/30000` подтверждаются `dcx-pod1-cl1-prox-1_frr.cfg` и capture `double_overlay.png`.
- В текущем варианте tenant VM-prefix не входят в BGW aggregate `10.11/10.12/10.13.0.0/16`; transport между PoD обеспечивается достижимостью Linux transport IP.

## 3. Hoster Fabric — Loopback0

### PoD1

| Устройство | Loopback0 |
|---|---|
| pod1-spine-01 | `10.1.0.1/32` |
| pod1-spine-02 | `10.1.0.2/32` |
| pod1-bgw-1 | `10.1.0.3/32` |
| pod1-bgw-2 | `10.1.0.4/32` |
| pod1-leaf-r1-1 | `10.1.0.11/32` |
| pod1-leaf-r1-2 | `10.1.0.12/32` |
| pod1-leaf-r2-1 | `10.1.0.21/32` |
| pod1-leaf-r2-2 | `10.1.0.22/32` |

### PoD2

| Устройство | Loopback0 |
|---|---|
| pod2-spine-01 | `10.2.0.1/32` |
| pod2-spine-02 | `10.2.0.2/32` |
| pod2-bgw-1 | `10.2.0.3/32` |
| pod2-bgw-2 | `10.2.0.4/32` |
| pod2-leaf-r1-1 | `10.2.0.11/32` |
| pod2-leaf-r1-2 | `10.2.0.12/32` |
| pod2-leaf-r2-1 | `10.2.0.21/32` |
| pod2-leaf-r2-2 | `10.2.0.22/32` |

### PoD3

| Устройство | Loopback0 |
|---|---|
| pod3-spine-01 | `10.3.0.1/32` |
| pod3-spine-02 | `10.3.0.2/32` |
| pod3-bgw-1 | `10.3.0.3/32` |
| pod3-bgw-2 | `10.3.0.4/32` |
| pod3-leaf-r1-1 | `10.3.0.11/32` |
| pod3-leaf-r1-2 | `10.3.0.12/32` |
| pod3-leaf-r2-1 | `10.3.0.21/32` |
| pod3-leaf-r2-2 | `10.3.0.22/32` |

## 4. Hoster Fabric — P2P underlay /31

### PoD1 Spine-01

| Spine Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|
| Eth1 | `10.1.1.0/31` | Eth1 | `10.1.1.1/31` | pod1-leaf-r1-1 |
| Eth2 | `10.1.1.2/31` | Eth1 | `10.1.1.3/31` | pod1-leaf-r1-2 |
| Eth3 | `10.1.1.4/31` | Eth1 | `10.1.1.5/31` | pod1-leaf-r2-1 |
| Eth4 | `10.1.1.6/31` | Eth1 | `10.1.1.7/31` | pod1-leaf-r2-2 |
| Eth5 | `10.1.1.8/31` | Eth1 | `10.1.1.9/31` | pod1-bgw-1 |
| Eth6 | `10.1.1.10/31` | Eth1 | `10.1.1.11/31` | pod1-bgw-2 |

### PoD1 Spine-02

| Spine Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|
| Eth1 | `10.1.2.0/31` | Eth2 | `10.1.2.1/31` | pod1-leaf-r1-1 |
| Eth2 | `10.1.2.2/31` | Eth2 | `10.1.2.3/31` | pod1-leaf-r1-2 |
| Eth3 | `10.1.2.4/31` | Eth2 | `10.1.2.5/31` | pod1-leaf-r2-1 |
| Eth4 | `10.1.2.6/31` | Eth2 | `10.1.2.7/31` | pod1-leaf-r2-2 |
| Eth5 | `10.1.2.8/31` | Eth2 | `10.1.2.9/31` | pod1-bgw-1 |
| Eth6 | `10.1.2.10/31` | Eth2 | `10.1.2.11/31` | pod1-bgw-2 |

### PoD2 Spine-01 / Spine-02

| Spine | Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|---|
| S01 | Eth1 | `10.2.1.0/31` | Eth1 | `10.2.1.1/31` | pod2-leaf-r1-1 |
| S01 | Eth2 | `10.2.1.2/31` | Eth1 | `10.2.1.3/31` | pod2-leaf-r1-2 |
| S01 | Eth3 | `10.2.1.4/31` | Eth1 | `10.2.1.5/31` | pod2-leaf-r2-1 |
| S01 | Eth4 | `10.2.1.6/31` | Eth1 | `10.2.1.7/31` | pod2-leaf-r2-2 |
| S01 | Eth5 | `10.2.1.8/31` | Eth1 | `10.2.1.9/31` | pod2-bgw-1 |
| S01 | Eth6 | `10.2.1.10/31` | Eth1 | `10.2.1.11/31` | pod2-bgw-2 |
| S02 | Eth1 | `10.2.2.0/31` | Eth2 | `10.2.2.1/31` | pod2-leaf-r1-1 |
| S02 | Eth2 | `10.2.2.2/31` | Eth2 | `10.2.2.3/31` | pod2-leaf-r1-2 |
| S02 | Eth3 | `10.2.2.4/31` | Eth2 | `10.2.2.5/31` | pod2-leaf-r2-1 |
| S02 | Eth4 | `10.2.2.6/31` | Eth2 | `10.2.2.7/31` | pod2-leaf-r2-2 |
| S02 | Eth5 | `10.2.2.8/31` | Eth2 | `10.2.2.9/31` | pod2-bgw-1 |
| S02 | Eth6 | `10.2.2.10/31` | Eth2 | `10.2.2.11/31` | pod2-bgw-2 |

### PoD3 Spine-01 / Spine-02

| Spine | Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|---|
| S01 | Eth1 | `10.3.1.0/31` | Eth1 | `10.3.1.1/31` | pod3-leaf-r1-1 |
| S01 | Eth2 | `10.3.1.2/31` | Eth1 | `10.3.1.3/31` | pod3-leaf-r1-2 |
| S01 | Eth3 | `10.3.1.4/31` | Eth1 | `10.3.1.5/31` | pod3-leaf-r2-1 |
| S01 | Eth4 | `10.3.1.6/31` | Eth1 | `10.3.1.7/31` | pod3-leaf-r2-2 |
| S01 | Eth5 | `10.3.1.8/31` | Eth1 | `10.3.1.9/31` | pod3-bgw-1 |
| S01 | Eth6 | `10.3.1.10/31` | Eth1 | `10.3.1.11/31` | pod3-bgw-2 |
| S02 | Eth1 | `10.3.2.0/31` | Eth2 | `10.3.2.1/31` | pod3-leaf-r1-1 |
| S02 | Eth2 | `10.3.2.2/31` | Eth2 | `10.3.2.3/31` | pod3-leaf-r1-2 |
| S02 | Eth3 | `10.3.2.4/31` | Eth2 | `10.3.2.5/31` | pod3-leaf-r2-1 |
| S02 | Eth4 | `10.3.2.6/31` | Eth2 | `10.3.2.7/31` | pod3-leaf-r2-2 |
| S02 | Eth5 | `10.3.2.8/31` | Eth2 | `10.3.2.9/31` | pod3-bgw-1 |
| S02 | Eth6 | `10.3.2.10/31` | Eth2 | `10.3.2.11/31` | pod3-bgw-2 |

## 5. Server ESI-LAG /31

Leaf-пары отдают одинаковый anycast IP на соответствующем `Vlan`/`Port-Channel`, а Linux-ноды получают второй адрес `/31` на `bond0`.

### PoD1

| Стойка | Сервер | Port-Channel | Leaf anycast IP | Server bond0 IP | ESI |
|---|---|---|---|---|---|
| rack1 | dcX-pod1-evpn-rt-1 | PC2 | `10.11.0.0/31` | `10.11.0.1/31` | `0000:0000:0001:0001:0001` |
| rack1 | dcX-pod1-pve-1 | PC1 | `10.11.0.2/31` | `10.11.0.3/31` | `0000:0000:0001:0001:0002` |
| rack2 | dcX-pod1-evpn-rt-2 | PC2 | `10.11.0.4/31` | `10.11.0.5/31` | `0000:0000:0001:0002:0001` |
| rack2 | dcX-pod1-pve-2 | PC1 | `10.11.0.6/31` | `10.11.0.7/31` | `0000:0000:0001:0002:0002` |

### PoD2

| Стойка | Сервер | Port-Channel | Leaf anycast IP | Server bond0 IP | ESI |
|---|---|---|---|---|---|
| rack1 | dcX-pod2-evpn-rt-1 | PC2 | `10.12.0.0/31` | `10.12.0.1/31` | `0000:0000:0002:0001:0001` |
| rack1 | dcX-pod2-pve-1 | PC1 | `10.12.0.2/31` | `10.12.0.3/31` | `0000:0000:0002:0001:0002` |
| rack2 | dcX-pod2-evpn-rt-2 | PC2 | `10.12.0.4/31` | `10.12.0.5/31` | `0000:0000:0002:0002:0001` |
| rack2 | dcX-pod2-pve-2 | PC1 | `10.12.0.6/31` | `10.12.0.7/31` | `0000:0000:0002:0002:0002` |

### PoD3

| Стойка | Сервер | Port-Channel | Leaf anycast IP | Server bond0 IP | ESI |
|---|---|---|---|---|---|
| rack1 | dcY-pod3-evpn-rt-1 | PC2 | `10.13.0.0/31` | `10.13.0.1/31` | `0000:0000:0003:0001:0001` |
| rack1 | dcY-pod3-pve-1 | PC1 | `10.13.0.2/31` | `10.13.0.3/31` | `0000:0000:0003:0001:0002` |
| rack2 | dcY-pod3-evpn-rt-2 | PC2 | `10.13.0.4/31` | `10.13.0.5/31` | `0000:0000:0003:0002:0001` |
| rack2 | dcY-pod3-pve-2 | PC1 | `10.13.0.6/31` | `10.13.0.7/31` | `0000:0000:0003:0002:0002` |

## 6. Linux transport endpoints, используемые сейчас

### Общая схема

| PoD | EVPN-RT-1 | PVE-1 | EVPN-RT-2 | PVE-2 |
|---|---|---|---|---|
| PoD1 | `10.11.0.1` | `10.11.0.3` | `10.11.0.5` | `10.11.0.7` |
| PoD2 | `10.12.0.1` | `10.12.0.3` | `10.12.0.5` | `10.12.0.7` |
| PoD3 | `10.13.0.1` | `10.13.0.3` | `10.13.0.5` | `10.13.0.7` |

### Кто с кем пирится

- `PVE -> local EVPN-RT` по `bond0`-адресам внутри PoD.
- `EVPN-RT -> remote EVPN-RT` по `bond0`-адресам между PoD.
- В текущих FRR-конфигах именно эти адреса используются как BGP peer endpoints и router-id.

## 7. Service loopback адреса Linux-узлов

Эти адреса присутствуют в `interfaces` как service/VTEP loopback, но в текущих FRR-конфигах они не используются как BGP peer endpoints.

| Устройство | Loopback |
|---|---|
| dcX-pod1-evpn-rt-1 | `10.11.20.1/32` |
| dcX-pod1-evpn-rt-2 | `10.11.20.2/32` |
| dcX-pod1-pve-1 | `10.11.20.11/32` |
| dcX-pod1-pve-2 | `10.11.20.12/32` |
| dcX-pod2-evpn-rt-1 | `10.12.20.1/32` |
| dcX-pod2-evpn-rt-2 | `10.12.20.2/32` |
| dcX-pod2-pve-1 | `10.12.20.11/32` |
| dcX-pod2-pve-2 | `10.12.20.12/32` |
| dcY-pod3-evpn-rt-1 | `10.13.20.1/32` |
| dcY-pod3-evpn-rt-2 | `10.13.20.2/32` |
| dcY-pod3-pve-1 | `10.13.20.11/32` |
| dcY-pod3-pve-2 | `10.13.20.12/32` |

## 8. Tenant VM networks в Proxmox SDN

| Zone | Prefix | Gateway | VNet | Prefix VNet | L2VNI |
|---|---|---|---|---|---|
| Zone1 | `192.168.10.0/23` | `192.168.10.1`, `192.168.11.1` | `pod1-vnet10` | `192.168.10.0/24` | `10010` |
| Zone1 | `192.168.10.0/23` | `192.168.10.1`, `192.168.11.1` | `pod1-vnet11` | `192.168.11.0/24` | `10011` |
| Zone2 | `192.168.20.0/23` | `192.168.20.1`, `192.168.21.1` | `pod2-vnet20` | `192.168.20.0/24` | `10020` |
| Zone2 | `192.168.20.0/23` | `192.168.20.1`, `192.168.21.1` | `pod2-vnet21` | `192.168.21.0/24` | `10021` |
| Zone3 | `192.168.30.0/23` | `192.168.30.1`, `192.168.31.1` | `pod3-vnet30` | `192.168.30.0/24` | `10030` |
| Zone3 | `192.168.30.0/23` | `192.168.30.1`, `192.168.31.1` | `pod3-vnet31` | `192.168.31.0/24` | `10031` |

## 9. BGW <-> InterPoD/Core p2p-links

### PoD1 BGW <-> InterPoD

| BGW | BGW Eth | BGW IP | InterPoD Iface | InterPoD IP | Устройство |
|---|---|---|---|---|---|
| pod1-bgw-1 | Eth3 | `172.16.1.1/31` | GE1/0/0 | `172.16.1.0/31` | interpod-rt-1 |
| pod1-bgw-1 | Eth4 | `172.16.1.3/31` | GE1/0/0 | `172.16.1.2/31` | interpod-rt-2 |
| pod1-bgw-2 | Eth3 | `172.16.1.5/31` | GE1/0/1 | `172.16.1.4/31` | interpod-rt-1 |
| pod1-bgw-2 | Eth4 | `172.16.1.7/31` | GE1/0/1 | `172.16.1.6/31` | interpod-rt-2 |

### PoD2 BGW <-> InterPoD

| BGW | BGW Eth | BGW IP | InterPoD Iface | InterPoD IP | Устройство |
|---|---|---|---|---|---|
| pod2-bgw-1 | Eth3 | `172.16.2.1/31` | GE1/0/2 | `172.16.2.0/31` | interpod-rt-1 |
| pod2-bgw-1 | Eth4 | `172.16.2.3/31` | GE1/0/2 | `172.16.2.2/31` | interpod-rt-2 |
| pod2-bgw-2 | Eth3 | `172.16.2.5/31` | GE1/0/3 | `172.16.2.4/31` | interpod-rt-1 |
| pod2-bgw-2 | Eth4 | `172.16.2.7/31` | GE1/0/3 | `172.16.2.6/31` | interpod-rt-2 |

### PoD3 BGW <-> City2-Core

| BGW | BGW Eth | BGW IP | Core Iface | Core IP | Устройство |
|---|---|---|---|---|---|
| pod3-bgw-1 | Eth3 | `172.16.3.1/31` | GE1/0/0 | `172.16.3.0/31` | city2-core-rt1 |
| pod3-bgw-1 | Eth4 | `172.16.3.5/31` | GE1/0/0 | `172.16.3.4/31` | city2-core-rt2 |
| pod3-bgw-2 | Eth3 | `172.16.3.3/31` | GE1/0/1 | `172.16.3.2/31` | city2-core-rt1 |
| pod3-bgw-2 | Eth4 | `172.16.3.7/31` | GE1/0/1 | `172.16.3.6/31` | city2-core-rt2 |

## 10. Core network p2p-links

### InterPoD <-> City1-Core

| Устройство A | Iface | IP A | IP B | Iface | Устройство B |
|---|---|---|---|---|---|
| interpod-rt-1 | GE1/0/8 | `172.16.10.3/31` | `172.16.10.2/31` | GE1/0/0 | city1-core-rt1 |
| interpod-rt-1 | GE1/0/9 | `172.16.10.5/31` | `172.16.10.4/31` | GE1/0/0 | city1-core-rt2 |
| interpod-rt-2 | GE1/0/8 | `172.16.10.7/31` | `172.16.10.6/31` | GE1/0/1 | city1-core-rt1 |
| interpod-rt-2 | GE1/0/9 | `172.16.10.9/31` | `172.16.10.8/31` | GE1/0/1 | city1-core-rt2 |
| city1-core-rt1 | GE1/0/3 | `172.16.10.10/31` | `172.16.10.11/31` | GE1/0/3 | city1-core-rt2 |

### Inter-DC

| Устройство A | Iface | IP A | IP B | Iface | Устройство B |
|---|---|---|---|---|---|
| city1-core-rt1 | GE1/0/9 | `172.16.100.0/31` | `172.16.100.1/31` | GE1/0/9 | city2-core-rt1 |
| city1-core-rt2 | GE1/0/9 | `172.16.100.6/31` | `172.16.100.7/31` | GE1/0/9 | city2-core-rt2 |

### City2-Core iBGP link

| Устройство A | Iface | IP A | IP B | Iface | Устройство B |
|---|---|---|---|---|---|
| city2-core-rt1 | GE1/0/3 | `172.16.3.8/31` | `172.16.3.9/31` | GE1/0/3 | city2-core-rt2 |

## 11. Core loopbacks

| Устройство | Loopback0 |
|---|---|
| city1-core-rt1 | `172.16.255.1/32` |
| city1-core-rt2 | `172.16.255.2/32` |
| interpod-rt-1 | `172.16.255.3/32` |
| interpod-rt-2 | `172.16.255.4/32` |
| city2-core-rt1 | `172.16.255.5/32` |
| city2-core-rt2 | `172.16.255.6/32` |

## 12. Сводка по маршрутизации

| PoD | Hoster underlay | Server aggregate наружу | Что реально транспортируется ядром |
|---|---|---|---|
| PoD1 | `10.1.0.0/16` | `10.11.0.0/16` | Linux transport endpoints `10.11.0.x` и service loopbacks `10.11.20.x` |
| PoD2 | `10.2.0.0/16` | `10.12.0.0/16` | Linux transport endpoints `10.12.0.x` и service loopbacks `10.12.20.x` |
| PoD3 | `10.3.0.0/16` | `10.13.0.0/16` | Linux transport endpoints `10.13.0.x` и service loopbacks `10.13.20.x` |

Ключевые выводы:

- Хостерский underlay `10.1/10.2/10.3.0.0/16` остаётся внутри PoD.
- BGW-конфиги явно подтверждают экспорт `10.11.0.0/16`, `10.12.0.0/16`, `10.13.0.0/16`.
- Tenant VM-сети `192.168.x.x` живут во внутреннем Proxmox overlay.
- В текущих Linux-конфигах peering и transport идут по `bond0`, а не по loopback.
- Для PoD1 capture подтверждает double overlay: `inner VNI 10000` внутри `outer VNI 50001`.
