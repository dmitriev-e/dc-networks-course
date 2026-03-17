# Адресный план: Multi-DC SDN Overlay

## Сводка ASN

| Устройство | ASN |
|---|---|
| pod1-spine-01/02 | 65501 |
| pod1-leaf-r1-1 | 65511 |
| pod1-leaf-r1-2 | 65512 |
| pod1-leaf-r2-1 | 65513 |
| pod1-leaf-r2-2 | 65514 |
| pod1-bgw-1 | 65515 |
| pod1-bgw-2 | 65516 |
| pod2-spine-01/02 | 65502 |
| pod2-leaf-r1-1 | 65521 |
| pod2-leaf-r1-2 | 65522 |
| pod2-leaf-r2-1 | 65523 |
| pod2-leaf-r2-2 | 65524 |
| pod2-bgw-1 | 65525 |
| pod2-bgw-2 | 65526 |
| pod3-spine-01/02 | 65503 |
| pod3-leaf-r1-1 | 65531 |
| pod3-leaf-r1-2 | 65532 |
| pod3-leaf-r2-1 | 65533 |
| pod3-leaf-r2-2 | 65534 |
| pod3-bgw-1 | 65535 |
| pod3-bgw-2 | 65536 |
| dcX-pod1-evpn-rt-1/2 + PVE cluster1 | 65501 |
| dcX-pod2-evpn-rt-1/2 + PVE cluster2 | 65502 |
| dcY-pod3-evpn-rt-1/2 + PVE cluster3 | 65503 |
| interpod-rt-1/2 | 65012 |
| city1-core-rt1/rt2 | 65011 |
| city2-core-rt1/rt2 | 65021 |

> **Хостерские VRF AS — per-PoD** (согласно схеме OverOverlay EVPN VXLAN fabric):
> - **PoD1 хостер VRF:** AS 64501 — leaf/BGW PoD1 представляются серверам и inter-PoD как AS 64501 (`local-as 64501 no-prepend replace-as`).
> - **PoD2 хостер VRF:** AS 64502 — аналогично.
> - **PoD3 хостер VRF:** AS 64503 — аналогично.
> - **EVPN-RT / PVE:** `neighbor HOSTER-LEAF remote-as 64501/64502/64503` (в зависимости от PoD).
> - **`allowas-in` НЕ нужен** — у каждого PoD уникальный хостерский AS, поэтому маршруты из соседних PoD не содержат собственный AS BGW → нет ложного loop detection.
> - AS-path маршрутов через core: `[65011/65021] [65012] [64501] [65501]` (city-core, inter-PoD, hoster VRF, EVPN-RT).

---

## VRF TENANT / VNI модель

| PoD | VRF | L3VNI | EVPN RT import/export | L2VNI |
|---|---|---|---|---|
| PoD1 | TENANT | 50001 | 1:50001 | нет |
| PoD2 | TENANT | 50001 | 1:50001 | нет |
| PoD3 | TENANT | 50001 | 1:50001 | нет |

L2 между серверами отсутствует. Только L3VNI (Symmetric IRB). VTEP на каждом leaf и BGW.

---

## Hoster Fabric — Loopback0

### PoD1 (Arista, City1/DC-X)

| Устройство | Loopback0 |
|---|---|
| pod1-spine-01 | 10.1.0.1/32 |
| pod1-spine-02 | 10.1.0.2/32 |
| pod1-bgw-1 | 10.1.0.3/32 |
| pod1-bgw-2 | 10.1.0.4/32 |
| pod1-leaf-r1-1 | 10.1.0.11/32 |
| pod1-leaf-r1-2 | 10.1.0.12/32 |
| pod1-leaf-r2-1 | 10.1.0.21/32 |
| pod1-leaf-r2-2 | 10.1.0.22/32 |

### PoD2 (Arista, City1/DC-X)

| Устройство | Loopback0 |
|---|---|
| pod2-spine-01 | 10.2.0.1/32 |
| pod2-spine-02 | 10.2.0.2/32 |
| pod2-bgw-1 | 10.2.0.3/32 |
| pod2-bgw-2 | 10.2.0.4/32 |
| pod2-leaf-r1-1 | 10.2.0.11/32 |
| pod2-leaf-r1-2 | 10.2.0.12/32 |
| pod2-leaf-r2-1 | 10.2.0.21/32 |
| pod2-leaf-r2-2 | 10.2.0.22/32 |

### PoD3 (Arista, City2/DC-Y)

| Устройство | Loopback0 |
|---|---|
| pod3-spine-01 | 10.3.0.1/32 |
| pod3-spine-02 | 10.3.0.2/32 |
| pod3-bgw-1 | 10.3.0.3/32 |
| pod3-bgw-2 | 10.3.0.4/32 |
| pod3-leaf-r1-1 | 10.3.0.11/32 |
| pod3-leaf-r1-2 | 10.3.0.12/32 |
| pod3-leaf-r2-1 | 10.3.0.21/32 |
| pod3-leaf-r2-2 | 10.3.0.22/32 |

---

## Hoster Fabric — P2P Underlay Links (/31)

### PoD1 Spine-01 (Eth1-6)

| Spine Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|
| Eth1 | 10.1.1.0/31 | Eth1 | 10.1.1.1/31 | pod1-leaf-r1-1 |
| Eth2 | 10.1.1.2/31 | Eth1 | 10.1.1.3/31 | pod1-leaf-r1-2 |
| Eth3 | 10.1.1.4/31 | Eth1 | 10.1.1.5/31 | pod1-leaf-r2-1 |
| Eth4 | 10.1.1.6/31 | Eth1 | 10.1.1.7/31 | pod1-leaf-r2-2 |
| Eth5 | 10.1.1.8/31 | Eth1 | 10.1.1.9/31 | pod1-bgw-1 |
| Eth6 | 10.1.1.10/31 | Eth1 | 10.1.1.11/31 | pod1-bgw-2 |

### PoD1 Spine-02 (Eth1-6)

| Spine Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|
| Eth1 | 10.1.2.0/31 | Eth2 | 10.1.2.1/31 | pod1-leaf-r1-1 |
| Eth2 | 10.1.2.2/31 | Eth2 | 10.1.2.3/31 | pod1-leaf-r1-2 |
| Eth3 | 10.1.2.4/31 | Eth2 | 10.1.2.5/31 | pod1-leaf-r2-1 |
| Eth4 | 10.1.2.6/31 | Eth2 | 10.1.2.7/31 | pod1-leaf-r2-2 |
| Eth5 | 10.1.2.8/31 | Eth2 | 10.1.2.9/31 | pod1-bgw-1 |
| Eth6 | 10.1.2.10/31 | Eth2 | 10.1.2.11/31 | pod1-bgw-2 |

### PoD2 Spine-01 / Spine-02 (аналогично, префикс 10.2.x.x)

| Spine | Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|---|
| S01 | Eth1 | 10.2.1.0/31 | Eth1 | 10.2.1.1/31 | pod2-leaf-r1-1 |
| S01 | Eth2 | 10.2.1.2/31 | Eth1 | 10.2.1.3/31 | pod2-leaf-r1-2 |
| S01 | Eth3 | 10.2.1.4/31 | Eth1 | 10.2.1.5/31 | pod2-leaf-r2-1 |
| S01 | Eth4 | 10.2.1.6/31 | Eth1 | 10.2.1.7/31 | pod2-leaf-r2-2 |
| S01 | Eth5 | 10.2.1.8/31 | Eth1 | 10.2.1.9/31 | pod2-bgw-1 |
| S01 | Eth6 | 10.2.1.10/31 | Eth1 | 10.2.1.11/31 | pod2-bgw-2 |
| S02 | Eth1 | 10.2.2.0/31 | Eth2 | 10.2.2.1/31 | pod2-leaf-r1-1 |
| S02 | Eth2 | 10.2.2.2/31 | Eth2 | 10.2.2.3/31 | pod2-leaf-r1-2 |
| S02 | Eth3 | 10.2.2.4/31 | Eth2 | 10.2.2.5/31 | pod2-leaf-r2-1 |
| S02 | Eth4 | 10.2.2.6/31 | Eth2 | 10.2.2.7/31 | pod2-leaf-r2-2 |
| S02 | Eth5 | 10.2.2.8/31 | Eth2 | 10.2.2.9/31 | pod2-bgw-1 |
| S02 | Eth6 | 10.2.2.10/31 | Eth2 | 10.2.2.11/31 | pod2-bgw-2 |

### PoD3 Spine-01 / Spine-02 (аналогично, префикс 10.3.x.x)

| Spine | Eth | Spine IP | Leaf/BGW Eth | Leaf/BGW IP | Устройство |
|---|---|---|---|---|---|
| S01 | Eth1 | 10.3.1.0/31 | Eth1 | 10.3.1.1/31 | pod3-leaf-r1-1 |
| S01 | Eth2 | 10.3.1.2/31 | Eth1 | 10.3.1.3/31 | pod3-leaf-r1-2 |
| S01 | Eth3 | 10.3.1.4/31 | Eth1 | 10.3.1.5/31 | pod3-leaf-r2-1 |
| S01 | Eth4 | 10.3.1.6/31 | Eth1 | 10.3.1.7/31 | pod3-leaf-r2-2 |
| S01 | Eth5 | 10.3.1.8/31 | Eth1 | 10.3.1.9/31 | pod3-bgw-1 |
| S01 | Eth6 | 10.3.1.10/31 | Eth1 | 10.3.1.11/31 | pod3-bgw-2 |
| S02 | Eth1 | 10.3.2.0/31 | Eth2 | 10.3.2.1/31 | pod3-leaf-r1-1 |
| S02 | Eth2 | 10.3.2.2/31 | Eth2 | 10.3.2.3/31 | pod3-leaf-r1-2 |
| S02 | Eth3 | 10.3.2.4/31 | Eth2 | 10.3.2.5/31 | pod3-leaf-r2-1 |
| S02 | Eth4 | 10.3.2.6/31 | Eth2 | 10.3.2.7/31 | pod3-leaf-r2-2 |
| S02 | Eth5 | 10.3.2.8/31 | Eth2 | 10.3.2.9/31 | pod3-bgw-1 |
| S02 | Eth6 | 10.3.2.10/31 | Eth2 | 10.3.2.11/31 | pod3-bgw-2 |

---

## Серверные ESI-LAG /31 (VRF TENANT, anycast на парах leaf)

Leaf выставляет `ip address virtual` на Port-Channel — оба leaf в паре имеют одинаковый anycast IP.  
Серверы (EVPN-RT и PVE) получают второй адрес /31 на bond0.

**Диапазоны:** PoD1 = `10.11.0.0/16`, PoD2 = `10.12.0.0/16`, PoD3 = `10.13.0.0/16`.  
Весь этот /16 анонсируется BGW в InterPoD/Core. Хостерский underlay (10.1.x.x/10.2.x.x/10.3.x.x) остаётся внутри PoD-фабрики.

> BGP-пиринг между EVPN-RT и PVE устанавливается через bond0 IP (не через лупбэки) с маршрутизацией через хостерский leaf в VRF TENANT. Прямого физического линка между EVPN-RT и PVE нет — leaf перенаправляет трафик между двумя /31-подсетями (PC1 и PC2). Leaf передаёт обе подключённые сети в eBGP (`redistribute connected`), поэтому каждый сервер знает маршрут к bond0 IP соседа.

### PoD1

| Стойка | Сервер | Port-Channel | Leaf anycast IP | Server bond0 IP | ESI |
|---|---|---|---|---|---|
| rack1 | dcX-pod1-evpn-rt-1 | PC2 | 10.11.0.0/31 | 10.11.0.1/31 | 0000:0000:0001:0001:0001 |
| rack1 | dcX-pod1-pve-1 | PC1 | 10.11.0.2/31 | 10.11.0.3/31 | 0000:0000:0001:0001:0002 |
| rack2 | dcX-pod1-evpn-rt-2 | PC2 | 10.11.0.4/31 | 10.11.0.5/31 | 0000:0000:0001:0002:0001 |
| rack2 | dcX-pod1-pve-2 | PC1 | 10.11.0.6/31 | 10.11.0.7/31 | 0000:0000:0001:0002:0002 |

PC1 members: Eth3 (PVE). PC2 members: Eth4 (EVPN-RT).

### PoD2

| Стойка | Сервер | PC | Leaf anycast IP | Server bond0 IP | ESI |
|---|---|---|---|---|---|
| rack1 | dcX-pod2-evpn-rt-1 | PC2 | 10.12.0.0/31 | 10.12.0.1/31 | 0000:0000:0002:0001:0001 |
| rack1 | dcX-pod2-pve-1 | PC1 | 10.12.0.2/31 | 10.12.0.3/31 | 0000:0000:0002:0001:0002 |
| rack2 | dcX-pod2-evpn-rt-2 | PC2 | 10.12.0.4/31 | 10.12.0.5/31 | 0000:0000:0002:0002:0001 |
| rack2 | dcX-pod2-pve-2 | PC1 | 10.12.0.6/31 | 10.12.0.7/31 | 0000:0000:0002:0002:0002 |

### PoD3

| Стойка | Сервер | PC | Leaf anycast IP | Server bond0 IP | ESI |
|---|---|---|---|---|---|
| rack1 | dcY-pod3-evpn-rt-1 | PC2 | 10.13.0.0/31 | 10.13.0.1/31 | 0000:0000:0003:0001:0001 |
| rack1 | dcY-pod3-pve-1 | PC1 | 10.13.0.2/31 | 10.13.0.3/31 | 0000:0000:0003:0001:0002 |
| rack2 | dcY-pod3-evpn-rt-2 | PC2 | 10.13.0.4/31 | 10.13.0.5/31 | 0000:0000:0003:0002:0001 |
| rack2 | dcY-pod3-pve-2 | PC1 | 10.13.0.6/31 | 10.13.0.7/31 | 0000:0000:0003:0002:0002 |

---

## Серверные Loopback (VXLAN VTEP источник)

Лупбэки находятся внутри серверного /16 — покрываются BGW-агрегатом.  
Используются как VTEP-source для VXLAN-туннелей SDN overlay.  
Для cross-PoD BGP EVPN (EVPN-RT ↔ EVPN-RT) используются эти же лупбэки (маршрутизируются через хостерскую фабрику + core).

| Устройство | Loopback0 |
|---|---|
| dcX-pod1-evpn-rt-1 | 10.11.20.1/32 |
| dcX-pod1-evpn-rt-2 | 10.11.20.2/32 |
| dcX-pod1-pve-1 | 10.11.20.11/32 |
| dcX-pod1-pve-2 | 10.11.20.12/32 |
| dcX-pod2-evpn-rt-1 | 10.12.20.1/32 |
| dcX-pod2-evpn-rt-2 | 10.12.20.2/32 |
| dcX-pod2-pve-1 | 10.12.20.11/32 |
| dcX-pod2-pve-2 | 10.12.20.12/32 |
| dcY-pod3-evpn-rt-1 | 10.13.20.1/32 |
| dcY-pod3-evpn-rt-2 | 10.13.20.2/32 |
| dcY-pod3-pve-1 | 10.13.20.11/32 |
| dcY-pod3-pve-2 | 10.13.20.12/32 |

---

## Proxmox SDN VM Networks (Zones и VNets)

Согласно схеме: 1 Zone = 1 /23-префикс, содержащий 2 VNet (/24 каждая).  
EVPN-RT анонсирует Zone-prefix (/23) в хостерскую фабрику → BGW → inter-PoD/core.

| PoD | Zone | Zone-prefix | VNet | VNet-prefix |
|---|---|---|---|---|
| PoD1 | pod1-zone1 | 192.168.10.0/23 | pod1-vnet10 | 192.168.10.0/24 |
| PoD1 | pod1-zone1 | 192.168.10.0/23 | pod1-vnet11 | 192.168.11.0/24 |
| PoD2 | pod2-zone2 | 192.168.20.0/23 | pod2-vnet20 | 192.168.20.0/24 |
| PoD2 | pod2-zone2 | 192.168.20.0/23 | pod2-vnet21 | 192.168.21.0/24 |
| PoD3 | pod3-zone3 | 192.168.30.0/23 | pod3-vnet30 | 192.168.30.0/24 |
| PoD3 | pod3-zone3 | 192.168.30.0/23 | pod3-vnet31 | 192.168.31.0/24 |

Zone L3VNI: pod1-zone1 = 10001, pod2-zone2 = 10002, pod3-zone3 = 10003.  
VNet L2VNI: vnet10=10010, vnet11=10011, vnet20=10020, vnet21=10021, vnet30=10030, vnet31=10031.

---

## BGW — InterPoD/Core P2P Links

### PoD1 BGW <-> InterPoD

| BGW | BGW Eth | BGW IP | InterPoD Iface | InterPoD IP | InterPoD устройство |
|---|---|---|---|---|---|
| pod1-bgw-1 | Eth3 | 172.16.1.1/31 | GE1/0/0 | 172.16.1.0/31 | interpod-rt-1 |
| pod1-bgw-1 | Eth4 | 172.16.1.3/31 | GE1/0/0 | 172.16.1.2/31 | interpod-rt-2 |
| pod1-bgw-2 | Eth3 | 172.16.1.5/31 | GE1/0/1 | 172.16.1.4/31 | interpod-rt-1 |
| pod1-bgw-2 | Eth4 | 172.16.1.7/31 | GE1/0/1 | 172.16.1.6/31 | interpod-rt-2 |

### PoD2 BGW <-> InterPoD

| BGW | BGW Eth | BGW IP | InterPoD Iface | InterPoD IP | InterPoD устройство |
|---|---|---|---|---|---|
| pod2-bgw-1 | Eth3 | 172.16.2.1/31 | GE1/0/2 | 172.16.2.0/31 | interpod-rt-1 |
| pod2-bgw-1 | Eth4 | 172.16.2.3/31 | GE1/0/2 | 172.16.2.2/31 | interpod-rt-2 |
| pod2-bgw-2 | Eth3 | 172.16.2.5/31 | GE1/0/3 | 172.16.2.4/31 | interpod-rt-1 |
| pod2-bgw-2 | Eth4 | 172.16.2.7/31 | GE1/0/3 | 172.16.2.6/31 | interpod-rt-2 |

### PoD3 BGW <-> City2-Core

| BGW | BGW Eth | BGW IP | Core Iface | Core IP | Core устройство |
|---|---|---|---|---|---|
| pod3-bgw-1 | Eth3 | 172.16.3.1/31 | GE1/0/0 | 172.16.3.0/31 | city2-core-rt1 |
| pod3-bgw-1 | Eth4 | 172.16.3.5/31 | GE1/0/0 | 172.16.3.4/31 | city2-core-rt2 |
| pod3-bgw-2 | Eth3 | 172.16.3.3/31 | GE1/0/1 | 172.16.3.2/31 | city2-core-rt1 |
| pod3-bgw-2 | Eth4 | 172.16.3.7/31 | GE1/0/1 | 172.16.3.6/31 | city2-core-rt2 |

---

## Core Network P2P Links

### InterPoD <-> City1-Core

Нет прямого линка между interpod-rt-1 и interpod-rt-2 — они независимы.

| Устройство A | Iface | IP A | IP B | Iface | Устройство B |
|---|---|---|---|---|---|
| interpod-rt-1 | GE1/0/8 | 172.16.10.3/31 | 172.16.10.2/31 | GE1/0/0 | city1-core-rt1 |
| interpod-rt-1 | GE1/0/9 | 172.16.10.5/31 | 172.16.10.4/31 | GE1/0/0 | city1-core-rt2 |
| interpod-rt-2 | GE1/0/8 | 172.16.10.7/31 | 172.16.10.6/31 | GE1/0/1 | city1-core-rt1 |
| interpod-rt-2 | GE1/0/9 | 172.16.10.9/31 | 172.16.10.8/31 | GE1/0/1 | city1-core-rt2 |
| city1-core-rt1 | GE1/0/3 | 172.16.10.10/31 | 172.16.10.11/31 | GE1/0/3 | city1-core-rt2 (iBGP) |

### Inter-DC (City1 <-> City2, прямые линки)

Только два прямых линка: rt1↔rt1 и rt2↔rt2.

| Устройство A | Iface | IP A | IP B | Iface | Устройство B |
|---|---|---|---|---|---|
| city1-core-rt1 | GE1/0/9 | 172.16.100.0/31 | 172.16.100.1/31 | GE1/0/9 | city2-core-rt1 |
| city1-core-rt2 | GE1/0/9 | 172.16.100.6/31 | 172.16.100.7/31 | GE1/0/9 | city2-core-rt2 |

### City2-Core iBGP peer link

| Устройство A | Iface | IP A | IP B | Iface | Устройство B |
|---|---|---|---|---|---|
| city2-core-rt1 | GE1/0/3 | 172.16.3.8/31 | 172.16.3.9/31 | GE1/0/3 | city2-core-rt2 |

---

## Core Loopbacks

| Устройство | Loopback0 |
|---|---|
| city1-core-rt1 | 172.16.255.1/32 |
| city1-core-rt2 | 172.16.255.2/32 |
| interpod-rt-1 | 172.16.255.3/32 |
| interpod-rt-2 | 172.16.255.4/32 |
| city2-core-rt1 | 172.16.255.5/32 |
| city2-core-rt2 | 172.16.255.6/32 |

---

## Сводная таблица PoD-агрегатов (анонсируемые на BGW)

BGW анонсирует **только серверный /16** в InterPoD/Core через eBGP в VRF TENANT.  
Хостерский underlay (10.1.x.x / 10.2.x.x / 10.3.x.x) остаётся внутри PoD-фабрики.  
EVPN-RT также анонсирует Zone-prefix (/23 VM-сети) через хостерскую фабрику — попадает в BGW aggregate /16.

| PoD | Хостерский VRF AS | Хостерский underlay (внутри PoD) | BGW aggregate (наружу) | Содержит |
|---|---|---|---|---|
| PoD1 | 64501 | 10.1.0.0/16 | **10.11.0.0/16** | ESI-LAG /31 (bond0), серверные лупбэки (VTEP), Zone1 192.168.10.0/23 |
| PoD2 | 64502 | 10.2.0.0/16 | **10.12.0.0/16** | ESI-LAG /31 (bond0), серверные лупбэки (VTEP), Zone2 192.168.20.0/23 |
| PoD3 | 64503 | 10.3.0.0/16 | **10.13.0.0/16** | ESI-LAG /31 (bond0), серверные лупбэки (VTEP), Zone3 192.168.30.0/23 |
