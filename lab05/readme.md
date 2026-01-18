# Документация по конфигурации Lab 05 - VxLAN EVPN L2 VNI

## Цель
Настроить Overlay на основе VxLAN EVPN для L2 связанности между клиентами поверх eBGP Underlay из Lab 04.

## Архитектура

### Компоненты
- **Underlay**: eBGP (из lab04) для IP связности между VTEP
- **Overlay**: BGP EVPN для передачи MAC/IP информации
- **Data Plane**: VxLAN для инкапсуляции L2 фреймов
- **VTEP**: Leaf коммутаторы (используют Loopback0 как source)

### L2 VNI (VLAN to VNI Mapping)

| VLAN | VNI   | Route Target | Описание | Подключенные хосты |
|------|-------|--------------|----------|--------------------|
| 10   | 10010 | 10:10010     | VLAN10   | VPC15 (Leaf-01), VPC16 (Leaf-02) |
| 20   | 10020 | 20:10020     | VLAN20   | VPC17, VPC18 (Leaf-03), VPC19, VPC20 (Leaf-04) |

**VNI Numbering:** VNI = 10000 + VLAN_ID (например, VLAN 10 → VNI 10010)

### VTEP Endpoints

| Device  | Loopback0 (VTEP IP) | VLANs    | VNIs         |
|---------|---------------------|----------|--------------|
| Leaf-01 | 10.1.1.1            | 10, 20   | 10010, 10020 |
| Leaf-02 | 10.1.1.2            | 10, 20   | 10010, 10020 |
| Leaf-03 | 10.1.1.3            | 10, 20   | 10010, 10020 |
| Leaf-04 | 10.1.1.4            | 10, 20   | 10010, 10020 |

## Детали конфигурации

### Spine

**Ключевые параметры:**
```
router bgp 65000
   neighbor LEAF send-community extended
   !
   address-family evpn
      neighbor LEAF activate
      neighbor LEAF next-hop-unchanged
```

**Важные моменты:**
- `send-community extended` - передача RT/RD (обязательно для EVPN)
- `address-family evpn` - активация EVPN AFI/SAFI
- `next-hop-unchanged` - сохранение оригинального next-hop (VTEP IP) при передаче маршрутов между Leaf

### Leaf (VTEP)

#### VxLAN Interface
```
interface Vxlan1
   vxlan source-interface Loopback0
   vxlan udp-port 4789
   vxlan vlan 10 vni 10010
   vxlan vlan 20 vni 10020
   vxlan learn-restrict any
```

**Параметры:**
- `source-interface Loopback0` - IP адрес VTEP (используется как source/destination для VxLAN туннелей)
- `udp-port 4789` - стандартный IANA порт для VxLAN
- `vxlan vlan X vni Y` - маппинг VLAN к VNI
- `vxlan learn-restrict any` - отключение data-plane learning (используем только control-plane EVPN)

#### BGP EVPN Configuration
```
router bgp 65001
   neighbor SPINE send-community extended
   !
   vlan 10
      rd 10.1.1.1:10010
      route-target both 10:10010
      redistribute learned
   !
   address-family evpn
      neighbor SPINE activate
```

**Параметры:**
- `send-community extended` - передача extended communities (RT/RD)
- `rd <ip>:<vni>` - Route Distinguisher (уникальный для каждого VTEP+VNI)
- `route-target both <vlan>:<vni>` - import/export RT (одинаковый для всех VTEP в одном L2 домене)
- `redistribute learned` - анонсирование MAC адресов, изученных локально
- `address-family evpn` - активация EVPN для соседей

### Route Distinguisher (RD) Strategy

**Формат:** `<VTEP_IP>:<VNI>`

| Leaf    | VLAN 10 RD      | VLAN 20 RD      |
|---------|-----------------|-----------------|
| Leaf-01 | 10.1.1.1:10010  | 10.1.1.1:10020  |
| Leaf-02 | 10.1.1.2:10010  | 10.1.1.2:10020  |
| Leaf-03 | 10.1.1.3:10010  | 10.1.1.3:10020  |
| Leaf-04 | 10.1.1.4:10010  | 10.1.1.4:10020  |

**Зачем нужен RD:**
- Делает EVPN маршруты уникальными в BGP таблице
- Позволяет отличить один и тот же MAC от разных VTEP
- Формат Type 0: `<ASN_or_IP>:<number>`

### Route Target (RT) Strategy

**Формат:** `<VLAN>:<VNI>`

| VLAN | Route Target | Применение |
|------|--------------|------------|
| 10   | 10:10010     | Import/Export на всех Leaf для VLAN 10 |
| 20   | 20:10020     | Import/Export на всех Leaf для VLAN 20 |

**Зачем нужен RT:**
- Определяет, какие маршруты import/export
- Все VTEP с одинаковым RT формируют один L2 домен
- `route-target both` = одновременно import и export

## EVPN Route Types

### Type 2: MAC/IP Advertisement Route

Самый важный тип для L2 VNI - анонсирует MAC адреса хостов.

**Структура:**
```
[2]:[0]:[48]:[MAC]:[0]:[0.0.0.0]
```

**Поля:**
- Route Type: 2 (MAC/IP Advertisement)
- Ethernet Segment Identifier: 0 (single-homed)
- MAC Address Length: 48 bits
- MAC Address: MAC хоста
- IP Address Length: 0 (для чистого L2)
- IP Address: 0.0.0.0 (для чистого L2)

### Type 3: Inclusive Multicast Ethernet Tag Route

Используется для BUM (Broadcast, Unknown unicast, Multicast) трафика.

**Структура:**
```
[3]:[0]:[32]:[VTEP_IP]
```

**Поля:**
- Route Type: 3 (IMET)
- Ethernet Tag ID: 0
- IP Address Length: 32
- Originating Router IP: VTEP Loopback IP

**Назначение:**
- Каждый VTEP анонсирует Type 3 маршрут для каждого VNI
- Другие VTEP используют эти маршруты для построения списка для BUM репликации
- При получении BUM фрейма, VTEP реплицирует его ко всем VTEP из Type 3 маршрутов

## Проверка конфигурации

### Spine-01

#### Проверка BGP EVPN соседей
```bash
spine-01#show bgp evpn summary
BGP summary information for VRF default
Router identifier 10.1.2.1, local AS number 65000
Neighbor Status Codes: m - Under maintenance
  Description              Neighbor   V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  Leaf-01                  10.101.1.0 4 65001            214       211    0    0 00:05:36 Estab   2      2
  Leaf-02                  10.101.1.2 4 65002            212       213    0    0 00:05:08 Estab   2      2
  Leaf-03                  10.101.1.4 4 65003            216       208    0    0 00:04:52 Estab   2      2
  Leaf-04                  10.101.1.6 4 65004            208       211    0    0 00:04:32 Estab   2      2
```

**Объяснение:**
- Все 4 Leaf установили EVPN сессии
- PfxRcd: каждый Leaf анонсирует 2 Type 3 маршрута (по одному на VNI 10010 и 10020)

#### Проверка EVPN маршрутов
```bash
spine-01#show bgp evpn
BGP routing table information for VRF default
Router identifier 10.1.2.1, local AS number 65000
Route status codes: * - valid, > - active, S - Stale, E - ECMP head, e - ECMP
                    c - Contributing to ECMP, % - Pending best path selection
Origin codes: i - IGP, e - EGP, ? - incomplete
AS Path Attributes: Or-ID - Originator ID, C-LST - Cluster List, LL Nexthop - Link Local Nexthop

          Network                Next Hop              Metric  LocPref Weight  Path
 * >      RD: 10.1.1.1:10010 imet 10.1.1.1
                                 10.1.1.1              -       100     0       65001 i
 * >      RD: 10.1.1.1:10020 imet 10.1.1.1
                                 10.1.1.1              -       100     0       65001 i
 * >      RD: 10.1.1.2:10010 imet 10.1.1.2
                                 10.1.1.2              -       100     0       65002 i
 * >      RD: 10.1.1.2:10020 imet 10.1.1.2
                                 10.1.1.2              -       100     0       65002 i
 * >      RD: 10.1.1.3:10010 imet 10.1.1.3
                                 10.1.1.3              -       100     0       65003 i
 * >      RD: 10.1.1.3:10020 imet 10.1.1.3
                                 10.1.1.3              -       100     0       65003 i
 * >      RD: 10.1.1.4:10010 imet 10.1.1.4
                                 10.1.1.4              -       100     0       65004 i
 * >      RD: 10.1.1.4:10020 imet 10.1.1.4
                                 10.1.1.4              -       100     0       65004 i
```

**Важно:**
- `imet` = Inclusive Multicast Ethernet Tag (Type 3)
- Next-hop = VTEP IP (Loopback0 Leaf)
- Spine сохраняет оригинальный next-hop благодаря `next-hop-unchanged`

### Leaf-01

#### Проверка VxLAN интерфейса
```bash
leaf-01#show interfaces vxlan 1
Vxlan1 is up, line protocol is up (connected)
  Hardware is Vxlan
  Source interface is Loopback0 and is active with 10.1.1.1
  Listening on UDP port 4789
  Replication/Flood Mode is headend with Flood List Source: EVPN
  Remote MAC learning via EVPN
  VNI mapping to VLANs
  Static VLAN to VNI mapping is
    [10, 10010]       [20, 10020]
  Note: All Dynamic VLANs used by VCS are internal VLANs.
        Use 'show vxlan vni' for details.
  Static VRF to VNI mapping is not configured
  Headend replication flood vtep list is:
    10 10.1.1.3        10.1.1.4        10.1.1.2
    20 10.1.1.3        10.1.1.4        10.1.1.2
  Shared Router MAC is 0000.0000.0000
```

**Объяснение:**
- VTEP IP: 10.1.1.1 (source для туннелей)
- Flood Mode: headend (Ingress Replication) - BUM трафик реплицируется на каждый VTEP отдельно
- MAC learning: через EVPN (control-plane)
- VNI mapping: VLAN 10 → VNI 10010, VLAN 20 → VNI 10020

#### Проверка VxLAN VTEPs
```bash
leaf-01#show vxlan vtep
Remote VTEPS for Vxlan1:

VTEP           Tunnel Type(s)
-------------- --------------
10.1.1.2       flood
10.1.1.3       flood
10.1.1.4       flood

Total number of remote VTEPS:  3
```

**Объяснение:**
- Leaf-01 знает о 3 удаленных VTEP (Leaf-02, 03, 04)
- Информация получена из EVPN Type 3 маршрутов
- flood: для BUM трафика, unicast: для известных MAC

#### Проверка BGP EVPN маршрутов
```bash
leaf-01#show bgp evpn route-type imet detail
BGP routing table information for VRF default
Router identifier 10.1.1.1, local AS number 65001
BGP routing table entry for imet 10.1.1.1, Route Distinguisher: 10.1.1.1:10010
 Paths: 1 available
  Local
    - from - (0.0.0.0)
      Origin IGP, metric -, localpref -, weight 0, tag 0, valid, local, best
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.1
BGP routing table entry for imet 10.1.1.1, Route Distinguisher: 10.1.1.1:10020
 Paths: 1 available
  Local
    - from - (0.0.0.0)
      Origin IGP, metric -, localpref -, weight 0, tag 0, valid, local, best
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.1
BGP routing table entry for imet 10.1.1.2, Route Distinguisher: 10.1.1.2:10010
 Paths: 2 available
  65000 65002
    10.1.1.2 from 10.101.2.1 (10.1.2.2)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP head, ECMP, best, ECMP contributor
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.2
  65000 65002
    10.1.1.2 from 10.101.1.1 (10.1.2.1)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP, ECMP contributor
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.2
BGP routing table entry for imet 10.1.1.2, Route Distinguisher: 10.1.1.2:10020
 Paths: 2 available
  65000 65002
    10.1.1.2 from 10.101.2.1 (10.1.2.2)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP head, ECMP, best, ECMP contributor
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.2
  65000 65002
    10.1.1.2 from 10.101.1.1 (10.1.2.1)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP, ECMP contributor
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.2
BGP routing table entry for imet 10.1.1.3, Route Distinguisher: 10.1.1.3:10010
 Paths: 2 available
  65000 65003
    10.1.1.3 from 10.101.2.1 (10.1.2.2)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP head, ECMP, best, ECMP contributor
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.3
  65000 65003
    10.1.1.3 from 10.101.1.1 (10.1.2.1)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP, ECMP contributor
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.3
BGP routing table entry for imet 10.1.1.3, Route Distinguisher: 10.1.1.3:10020
 Paths: 2 available
  65000 65003
    10.1.1.3 from 10.101.2.1 (10.1.2.2)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP head, ECMP, best, ECMP contributor
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.3
  65000 65003
    10.1.1.3 from 10.101.1.1 (10.1.2.1)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP, ECMP contributor
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.3
BGP routing table entry for imet 10.1.1.4, Route Distinguisher: 10.1.1.4:10010
 Paths: 2 available
  65000 65004
    10.1.1.4 from 10.101.1.1 (10.1.2.1)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP head, ECMP, best, ECMP contributor
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.4
  65000 65004
    10.1.1.4 from 10.101.2.1 (10.1.2.2)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP, ECMP contributor
      Extended Community: Route-Target-AS:10:10010 TunnelEncap:tunnelTypeVxlan
      VNI: 10010
      PMSI Tunnel: Ingress Replication, MPLS Label: 10010, Leaf Information Required: false, Tunnel ID: 10.1.1.4
BGP routing table entry for imet 10.1.1.4, Route Distinguisher: 10.1.1.4:10020
 Paths: 2 available
  65000 65004
    10.1.1.4 from 10.101.1.1 (10.1.2.1)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP head, ECMP, best, ECMP contributor
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.4
  65000 65004
    10.1.1.4 from 10.101.2.1 (10.1.2.2)
      Origin IGP, metric -, localpref 100, weight 0, tag 0, valid, external, ECMP, ECMP contributor
      Extended Community: Route-Target-AS:20:10020 TunnelEncap:tunnelTypeVxlan
      VNI: 10020
      PMSI Tunnel: Ingress Replication, MPLS Label: 10020, Leaf Information Required: false, Tunnel ID: 10.1.1.4
```

**Важно:**
- Локальный Type 3 маршрут (10.1.1.1) анонсируется в EVPN
- Удаленные Type 3 маршруты получены через оба Spine (ECMP)
- Extended Community содержит RT (10:10010) и Tunnel Type (VxLAN)
- PMSI Tunnel: Ingress Replication с Tunnel ID = VTEP IP

#### Проверка MAC адресов
```bash
leaf-01#show vxlan address-table
          Vxlan Mac Address Table
----------------------------------------------------------------------

VLAN  Mac Address     Type      Prt  VTEP             Moves   Last Move
----  -----------     ----      ---  ----             -----   ---------
  10  0050.7966.6810  EVPN      Vx1  10.1.1.2         1       0:01:51 ago
Total Remote Mac Addresses for this criterion: 1

leaf-02#show vxlan address-table
          Vxlan Mac Address Table
----------------------------------------------------------------------

VLAN  Mac Address     Type      Prt  VTEP             Moves   Last Move
----  -----------     ----      ---  ----             -----   ---------
  10  0050.7966.680f  EVPN      Vx1  10.1.1.1         1       0:06:49 ago
Total Remote Mac Addresses for this criterion: 1

```

**Объяснение:**
- MAC адреса изучены через EVPN (Type 2 маршруты)
- VTEP column показывает, на каком удаленном VTEP находится хост
- Moves: количество перемещений MAC между VTEP
- Интерфейс Vx1 = VxLAN tunnel

#### Проверка локальных MAC
```bash
leaf-01#show mac address-table vlan 10
          Mac Address Table
------------------------------------------------------------------

Vlan    Mac Address       Type        Ports      Moves   Last Move
----    -----------       ----        -----      -----   ---------
  10    0050.7966.680f    DYNAMIC     Et3        1       0:10:16 ago
  10    0050.7966.6810    DYNAMIC     Vx1        1       0:02:59 ago
Total Mac Addresses for this criterion: 2

          Multicast Mac Address Table
------------------------------------------------------------------

Vlan    Mac Address       Type        Ports
----    -----------       ----        -----
Total Mac Addresses for this criterion: 0
```

**Объяснение:**
- MAC 0050.7966.680f изучен на физическом интерфейсе Et3
- Этот MAC будет анонсирован в EVPN как Type 2 маршрут
- MAC 0050.7966.6810 изучен как удалённый адрес доступный через VXLAN интерфейс

### Проверка связности

#### Ping между хостами в одном VLAN

**Сценарий:** VPC15 (Leaf-01, VLAN 10) → VPC16 (Leaf-02, VLAN 10)

```bash
VPC15> ping 192.168.10.16

84 bytes from 192.168.10.16 icmp_seq=1 ttl=64 time=10.384 ms
84 bytes from 192.168.10.16 icmp_seq=2 ttl=64 time=9.926 ms
84 bytes from 192.168.10.16 icmp_seq=3 ttl=64 time=11.032 ms
```

**Что происходит:**
1. VPC15 отправляет Ethernet фрейм с DST MAC = VPC16
2. Leaf-01 ищет DST MAC в VXLAN MAC table
3. Находит: MAC VPC16 находится на VTEP 10.1.1.2
4. Leaf-01 инкапсулирует фрейм в VxLAN (VNI 10010) и отправляет к 10.1.1.2
5. Underlay (eBGP) маршрутизирует пакет через Spine к 10.1.1.2
6. Leaf-02 декапсулирует VxLAN и отправляет фрейм на Et3 (VPC16)


#### Проверка BUM трафика (Broadcast)

При отправке ARP request:
```bash
leaf-01#show vxlan flood vtep
          VXLAN Flood VTEP Table
--------------------------------------------------------------------------------

VLANS                            Ip Address
-----------------------------   ------------------------------------------------
10,20                           10.1.1.2        10.1.1.3        10.1.1.4
```

**Объяснение:**
- Для каждого VNI есть список VTEP для flood (BUM) трафика
- При получении broadcast/unknown unicast, Leaf-01 реплицирует на все VTEP в списке
- Список построен из EVPN Type 3 маршрутов
