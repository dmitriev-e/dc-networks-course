# Документация по конфигурации Lab 04 - eBGP Underlay

## Цель
Настроить eBGP для Underlay сети с использованием автономных систем (AS) согласно best practices для Spine-Leaf архитектуры.

## Схема нумерации AS (Autonomous System Numbering)

### Принципы
- **Каждый Leaf имеет свою ASN** - обеспечивает изоляцию и гибкость маршрутизации
- **Все Spine имеют один номер ASN** - в двухуровневой топологии для упрощения конфигурации

### Таблица ASN

| Device   | ASN   | Router-ID | Описание |
|----------|-------|-----------|----------|
| Spine-01 | 65000 | 10.1.2.1  | Spine layer, общий ASN |
| Spine-02 | 65000 | 10.1.2.2  | Spine layer, общий ASN |
| Leaf-01  | 65001 | 10.1.1.1  | Leaf layer, уникальный ASN |
| Leaf-02  | 65002 | 10.1.1.2  | Leaf layer, уникальный ASN |
| Leaf-03  | 65003 | 10.1.1.3  | Leaf layer, уникальный ASN |
| Leaf-04  | 65004 | 10.1.1.4  | Leaf layer, уникальный ASN |

## Таблица адресов (Underlay eBGP)

Используется та же IP адресация, что и в Lab 03:

| Device   | Interface   | IP Address    | Subnet Mask/CIDR | Description/Connected To |
|----------|-------------|---------------|------------------|--------------------------|
| **Spine-01** | Loopback0 | 10.1.2.1      | /32              | Router-ID (анонсируется в BGP) |
|          | Ethernet1   | 10.101.1.1    | /31              | Link to Leaf-01          |
|          | Ethernet2   | 10.101.1.3    | /31              | Link to Leaf-02          |
|          | Ethernet3   | 10.101.1.5    | /31              | Link to Leaf-03          |
|          | Ethernet4   | 10.101.1.7    | /31              | Link to Leaf-04          |
| **Spine-02** | Loopback0 | 10.1.2.2      | /32              | Router-ID (анонсируется в BGP) |
|          | Ethernet1   | 10.101.2.1    | /31              | Link to Leaf-01          |
|          | Ethernet2   | 10.101.2.3    | /31              | Link to Leaf-02          |
|          | Ethernet3   | 10.101.2.5    | /31              | Link to Leaf-03          |
|          | Ethernet4   | 10.101.2.7    | /31              | Link to Leaf-04          |
| **Leaf-01**  | Loopback0 | 10.1.1.1      | /32              | Router-ID (анонсируется в BGP) |
|          | Ethernet1   | 10.101.1.0    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.0    | /31              | Link to Spine-02         |
| **Leaf-02**  | Loopback0 | 10.1.1.2      | /32              | Router-ID (анонсируется в BGP) |
|          | Ethernet1   | 10.101.1.2    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.2    | /31              | Link to Spine-02         |
| **Leaf-03**  | Loopback0 | 10.1.1.3      | /32              | Router-ID (анонсируется в BGP) |
|          | Ethernet1   | 10.101.1.4    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.4    | /31              | Link to Spine-02         |
| **Leaf-04**  | Loopback0 | 10.1.1.4      | /32              | Router-ID (анонсируется в BGP) |
|          | Ethernet1   | 10.101.1.6    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.6    | /31              | Link to Spine-02         |

## Детали конфигурации eBGP

### Основные параметры

- **Routing Protocol:** eBGP (External BGP) для Underlay
- **ASN Range:** 65000-65004 (Private AS range: 64512-65534)
- **BFD:** Enabled для всех BGP соседей (быстрое обнаружение отказов)
- **BGP Timers:** keepalive 3s, hold time 9s (агрессивные таймеры для быстрой сходимости в DC)
- **ECMP:** 
  - Spine: `maximum-paths 4 ecmp 4` (до 4 равноценных путей к каждому Leaf)
  - Leaf: `maximum-paths 2 ecmp 2` (2 пути через оба Spine)
- **Multi-agent routing model:** Включен для поддержки BGP

### Peer Groups

#### На Spine коммутаторах
```
neighbor LEAF peer group
neighbor LEAF bfd
neighbor LEAF timers 3 9
```
- Используется peer group **LEAF** для упрощения конфигурации
- BFD включен для быстрого обнаружения отказов линков
- Агрессивные BGP таймеры: keepalive 3s, hold 9s (по умолчанию 60/180)

#### На Leaf коммутаторах
```
neighbor SPINE peer group
neighbor SPINE bfd
neighbor SPINE timers 3 9
```
- Используется peer group **SPINE** для упрощения конфигурации
- BFD включен для всех соединений со Spine
- Агрессивные BGP таймеры для быстрой реакции на изменения

### BGP Peering Matrix

| Leaf Device | Leaf ASN | Spine Device | Spine ASN | Peering IP (Leaf) | Peering IP (Spine) |
|-------------|----------|--------------|-----------|-------------------|-------------------|
| Leaf-01     | 65001    | Spine-01     | 65000     | 10.101.1.0        | 10.101.1.1        |
| Leaf-01     | 65001    | Spine-02     | 65000     | 10.101.2.0        | 10.101.2.1        |
| Leaf-02     | 65002    | Spine-01     | 65000     | 10.101.1.2        | 10.101.1.3        |
| Leaf-02     | 65002    | Spine-02     | 65000     | 10.101.2.2        | 10.101.2.3        |
| Leaf-03     | 65003    | Spine-01     | 65000     | 10.101.1.4        | 10.101.1.5        |
| Leaf-03     | 65003    | Spine-02     | 65000     | 10.101.2.4        | 10.101.2.5        |
| Leaf-04     | 65004    | Spine-01     | 65000     | 10.101.1.6        | 10.101.1.7        |
| Leaf-04     | 65004    | Spine-02     | 65000     | 10.101.2.6        | 10.101.2.7        |

**Итого:** 8 eBGP сессий (4 Leaf × 2 Spine)

### Анонсируемые сети

Каждое устройство анонсирует только свой Loopback0 в BGP:

```
address-family ipv4
   network <loopback-ip>/32
```

| Device   | Анонсируемая сеть |
|----------|-------------------|
| Spine-01 | 10.1.2.1/32       |
| Spine-02 | 10.1.2.2/32       |
| Leaf-01  | 10.1.1.1/32       |
| Leaf-02  | 10.1.1.2/32       |
| Leaf-03  | 10.1.1.3/32       |
| Leaf-04  | 10.1.1.4/32       |

**Важно:** P2P линки (10.101.x.x/31) являются connected сетями и автоматически доступны, их не анонсируем в BGP.

## Проверка конфигурации

### Spine-01

#### Проверка BGP соседей
```bash
spine-01#show ip bgp summary
BGP summary information for VRF default
Router identifier 10.1.2.1, local AS number 65000
Neighbor Status Codes: m - Under maintenance
  Description              Neighbor   V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  Leaf-01                  10.101.1.0 4 65001              9         8    0    0 00:01:44 Estab   1      1
  Leaf-02                  10.101.1.2 4 65002              9         8    0    0 00:01:14 Estab   1      1
  Leaf-03                  10.101.1.4 4 65003              9         8    0    0 00:00:47 Estab   1      1
  Leaf-04                  10.101.1.6 4 65004              9         8    0    0 00:00:21 Estab   1      1
```

#### Проверка BGP маршрутов
```bash
spine-01#show ip bgp
BGP routing table information for VRF default
Router identifier 10.1.2.1, local AS number 65000
Route status codes: s - suppressed contributor, * - valid, > - active, E - ECMP head, e - ECMP
                    S - Stale, c - Contributing to ECMP, b - backup, L - labeled-unicast
                    % - Pending best path selection
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI Origin Validation codes: V - valid, I - invalid, U - unknown
AS Path Attributes: Or-ID - Originator ID, C-LST - Cluster List, LL Nexthop - Link Local Nexthop

          Network                Next Hop              Metric  AIGP       LocPref Weight  Path
 * >      10.1.1.1/32            10.101.1.0            0       -          100     0       65001 i
 * >      10.1.1.2/32            10.101.1.2            0       -          100     0       65002 i
 * >      10.1.1.3/32            10.101.1.4            0       -          100     0       65003 i
 * >      10.1.1.4/32            10.101.1.6            0       -          100     0       65004 i
 * >      10.1.2.1/32            -                     -       -          -       0       i
```

**Объяснение:**
- Прямые маршруты к Loopback всех Leaf (10.1.1.x/32) через соответствующие линки
- Spine не пирятся между собой - это стандартная практика в Spine-Leaf топологии
- Каждый Leaf получает анонсы от обоих Spine и делает ECMP балансировку

#### Проверка таблицы маршрутизации
```bash
spine-01#show ip route bgp

VRF: default
Source Codes:
       C - connected, S - static, K - kernel,
       O - OSPF, IA - OSPF inter area, E1 - OSPF external type 1,
       E2 - OSPF external type 2, N1 - OSPF NSSA external type 1,
       N2 - OSPF NSSA external type2, B - Other BGP Routes,
       B I - iBGP, B E - eBGP, R - RIP, I L1 - IS-IS level 1,
       I L2 - IS-IS level 2, O3 - OSPFv3, A B - BGP Aggregate,
       A O - OSPF Summary, NG - Nexthop Group Static Route,
       V - VXLAN Control Service, M - Martian,
       DH - DHCP client installed default route,
       DP - Dynamic Policy Route, L - VRF Leaked,
       G  - gRIBI, RC - Route Cache Route,
       CL - CBF Leaked Route

 B E      10.1.1.1/32 [200/0]
           via 10.101.1.0, Ethernet1
 B E      10.1.1.2/32 [200/0]
           via 10.101.1.2, Ethernet2
 B E      10.1.1.3/32 [200/0]
           via 10.101.1.4, Ethernet3
 B E      10.1.1.4/32 [200/0]
           via 10.101.1.6, Ethernet4
```

**Важно:** 
- `B E` означает eBGP маршрут
- AD (Administrative Distance) для eBGP = 20 (Arista показывает 200)
- Spine-01 имеет прямые маршруты ко всем 4 Leaf loopback адресам
- **Нет маршрута к Spine-02**: Spine не пирятся между собой

### Leaf-01

#### Проверка BGP соседей
```bash
leaf-01#show ip bgp summary
BGP summary information for VRF default
Router identifier 10.1.1.1, local AS number 65001
Neighbor Status Codes: m - Under maintenance
  Description              Neighbor   V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  Spine-01                 10.101.1.1 4 65000             14        15    0    0 00:06:50 Estab   4      4
  Spine-02                 10.101.2.1 4 65000             14        14    0    0 00:06:50 Estab   4      4
```

**Объяснение:**
- 2 BGP соседа (оба Spine с ASN 65000)
- Получено по 4 префикса от каждого Spine:
  - 1 Loopback Spine-а (10.1.2.1 или 10.1.2.2)
  - 3 Loopback других Leaf (10.1.1.2, 10.1.1.3, 10.1.1.4)

#### Проверка BGP маршрутов
```bash
leaf-01#show ip bgp
BGP routing table information for VRF default
Router identifier 10.1.1.1, local AS number 65001
Route status codes: s - suppressed contributor, * - valid, > - active, E - ECMP head, e - ECMP
                    S - Stale, c - Contributing to ECMP, b - backup, L - labeled-unicast
                    % - Pending best path selection
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI Origin Validation codes: V - valid, I - invalid, U - unknown
AS Path Attributes: Or-ID - Originator ID, C-LST - Cluster List, LL Nexthop - Link Local Nexthop

          Network                Next Hop              Metric  AIGP       LocPref Weight  Path
 * >      10.1.1.1/32            -                     -       -          -       0       i
 * >Ec    10.1.1.2/32            10.101.2.1            0       -          100     0       65000 65002 i
 *  ec    10.1.1.2/32            10.101.1.1            0       -          100     0       65000 65002 i
 * >Ec    10.1.1.3/32            10.101.2.1            0       -          100     0       65000 65003 i
 *  ec    10.1.1.3/32            10.101.1.1            0       -          100     0       65000 65003 i
 * >Ec    10.1.1.4/32            10.101.2.1            0       -          100     0       65000 65004 i
 *  ec    10.1.1.4/32            10.101.1.1            0       -          100     0       65000 65004 i
 * >      10.1.2.1/32            10.101.1.1            0       -          100     0       65000 i
 * >      10.1.2.2/32            10.101.2.1            0       -          100     0       65000 i
```

**Объяснение AS Path:**
- `10.1.1.2/32`: путь `65000 65002` (через Spine-01 ASN 65000 к Leaf-02 ASN 65002)
- `10.1.2.1/32`: путь `65000` (прямо от Spine-01)
- Все маршруты к удаленным устройствам имеют 2 пути (ECMP через оба Spine)

#### Проверка таблицы маршрутизации
```bash
leaf-01#show ip route bgp
VRF: default
Source Codes:
       C - connected, S - static, K - kernel,
       O - OSPF, IA - OSPF inter area, E1 - OSPF external type 1,
       E2 - OSPF external type 2, N1 - OSPF NSSA external type 1,
       N2 - OSPF NSSA external type2, B - Other BGP Routes,
       B I - iBGP, B E - eBGP, R - RIP, I L1 - IS-IS level 1,
       I L2 - IS-IS level 2, O3 - OSPFv3, A B - BGP Aggregate,
       A O - OSPF Summary, NG - Nexthop Group Static Route,
       V - VXLAN Control Service, M - Martian,
       DH - DHCP client installed default route,
       DP - Dynamic Policy Route, L - VRF Leaked,
       G  - gRIBI, RC - Route Cache Route,
       CL - CBF Leaked Route

 B E      10.1.1.2/32 [200/0]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 B E      10.1.1.3/32 [200/0]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 B E      10.1.1.4/32 [200/0]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 B E      10.1.2.1/32 [200/0]
           via 10.101.1.1, Ethernet1
 B E      10.1.2.2/32 [200/0]
           via 10.101.2.1, Ethernet2
```

**Важно:** Все удаленные Loopback адреса доступны через оба Spine (ECMP load balancing).

#### Проверка BFD
```bash
leaf-01#show bfd peers
VRF name: default
-----------------
DstAddr        MyDisc    YourDisc  Interface/Transport    Type          LastUp
---------- ----------- ----------- -------------------- ------- ---------------
10.101.1.1 2368808137  2263381293        Ethernet1(17)  normal  01/18/26 21:00
10.101.2.1 2799630726  3292365014        Ethernet2(19)  normal  01/18/26 21:00

   LastDown            LastDiag    State
-------------- ------------------- -----
         NA       No Diagnostic       Up
         NA       No Diagnostic       Up
```

### Тестирование связности

#### Ping между Loopback адресами
```bash
leaf-01#ping 10.1.1.2 source 10.1.1.1
PING 10.1.1.2 (10.1.1.2) from 10.1.1.1 : 72(100) bytes of data.
80 bytes from 10.1.1.2: icmp_seq=1 ttl=63 time=10.1 ms
80 bytes from 10.1.1.2: icmp_seq=2 ttl=63 time=5.19 ms
80 bytes from 10.1.1.2: icmp_seq=3 ttl=63 time=4.59 ms
80 bytes from 10.1.1.2: icmp_seq=4 ttl=63 time=4.99 ms
80 bytes from 10.1.1.2: icmp_seq=5 ttl=63 time=5.10 ms

--- 10.1.1.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 38ms
rtt min/avg/max/mdev = 4.591/6.003/10.148/2.082 ms, ipg/ewma 9.584/8.005 ms


leaf-01#ping 10.1.2.1 source 10.1.1.1
PING 10.1.2.1 (10.1.2.1) from 10.1.1.1 : 72(100) bytes of data.
80 bytes from 10.1.2.1: icmp_seq=1 ttl=64 time=4.77 ms
80 bytes from 10.1.2.1: icmp_seq=2 ttl=64 time=2.18 ms
80 bytes from 10.1.2.1: icmp_seq=3 ttl=64 time=2.14 ms
80 bytes from 10.1.2.1: icmp_seq=4 ttl=64 time=2.11 ms
80 bytes from 10.1.2.1: icmp_seq=5 ttl=64 time=2.25 ms

--- 10.1.2.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 18ms
rtt min/avg/max/mdev = 2.110/2.690/4.774/1.043 ms, ipg/ewma 4.375/3.697 ms
```

#### Traceroute для проверки пути
```bash
leaf-01#traceroute 10.1.1.3 source 10.1.1.1
traceroute to 10.1.1.3 (10.1.1.3), 30 hops max, 60 byte packets
 1  10.101.2.1 (10.101.2.1)  6.858 ms  7.882 ms  7.810 ms
 2  10.1.1.3 (10.1.1.3)  17.106 ms  18.579 ms  18.511 ms
```
- Hop 1: Spine-01
- Hop 2: Leaf-03 (destination)
