# Lab 08 — VXLAN EVPN Type-5, Multi-VRF через Border Gateway

## Цель

Реализовать в одной фабрике:

- north-south маршрутизацию в WAN через `bgw-leaf-1/2` и `Mikrotik-RT1`;
- экспорт маршрутов в overlay как **EVPN Type-5**;
- два tenant VRF (`TENANT1`, `TENANT2`);
- маршрутизацию **между TENANT1 и TENANT2 через внешнее устройство** (`Mikrotik-RT1`);
- NAT на WAN-интерфейсе Mikrotik (`ether1`), чтобы клиенты фабрики выходили наружу через один адрес.

![Схема сети](scheme.png)

---

## Архитектура

- **Spine-01/02 (AS 65000)** — underlay/EVPN транзит, `next-hop-unchanged` для EVPN.
- **Leaf-01..04 (AS 65001..65004)** — VTEP для клиентских VLAN/L2VNI и VRF/L3VNI.
- **bgw-leaf-1 (AS 65005), bgw-leaf-2 (AS 65006)** — border VTEP, оба обслуживают `TENANT1` и `TENANT2`.
- **Mikrotik-RT1 (AS 65100)** — внешний роутер: DHCP WAN + NAT + eBGP к обоим BGW по двум tenant transit VLAN.

---

## Адресация

### Loopback и ASN

| Device | Loopback | ASN |
|---|---|---|
| spine-01 | 10.1.2.1/32 | 65000 |
| spine-02 | 10.1.2.2/32 | 65000 |
| leaf-01 | 10.1.1.1/32 | 65001 |
| leaf-02 | 10.1.1.2/32 | 65002 |
| leaf-03 | 10.1.1.3/32 | 65003 |
| leaf-04 | 10.1.1.4/32 | 65004 |
| bgw-leaf-1 | 10.1.1.5/32 | 65005 |
| bgw-leaf-2 | 10.1.1.6/32 | 65006 |
| Mikrotik-RT1 | 10.1.3.1/32 | 65100 |

### Spine ↔ Leaf/BGW underlay

| Link | Subnet |
|---|---|
| spine-01 ↔ leaf-01 | 10.101.1.0/31 |
| spine-01 ↔ leaf-02 | 10.101.1.2/31 |
| spine-01 ↔ leaf-03 | 10.101.1.4/31 |
| spine-01 ↔ leaf-04 | 10.101.1.6/31 |
| spine-02 ↔ leaf-01 | 10.101.2.0/31 |
| spine-02 ↔ leaf-02 | 10.101.2.2/31 |
| spine-02 ↔ leaf-03 | 10.101.2.4/31 |
| spine-02 ↔ leaf-04 | 10.101.2.6/31 |
| spine-01 ↔ bgw-leaf-1 | 10.101.1.8/31 |
| spine-02 ↔ bgw-leaf-1 | 10.101.2.8/31 |
| spine-01 ↔ bgw-leaf-2 | 10.101.1.10/31 |
| spine-02 ↔ bgw-leaf-2 | 10.101.2.10/31 |

### BGW ↔ Mikrotik transit (802.1Q trunk)

| Tenant | VLAN | bgw-leaf-1 | bgw-leaf-2 | Mikrotik |
|---|---|---|---|---|
| TENANT1 | 10 | 100.1.1.0/31 (Eth3.10) | 100.2.1.0/31 (Eth3.10) | 100.1.1.1/31 (vlan10-ether3), 100.2.1.1/31 (vlan10-ether2) |
| TENANT2 | 20 | 100.1.2.0/31 (Eth3.20) | 100.2.2.0/31 (Eth3.20) | 100.1.2.1/31 (vlan20-ether3), 100.2.2.1/31 (vlan20-ether2) |

WAN:
- `Mikrotik ether1` — DHCP, внешняя сеть `10.64.164.0/23`

---

## Tenant и VNI модель

| VRF | L3VNI | RT |
|---|---|---|
| TENANT1 | 50001 | 1:50001 |
| TENANT2 | 50002 | 2:50002 |

| VLAN | Subnet | VNI | VRF |
|---|---|---|---|
| 10 | 192.168.10.0/24 | 10010 | TENANT1 |
| 20 | 192.168.20.0/24 | 10020 | TENANT1 |
| 30 | 192.168.30.0/24 | 10030 | TENANT1 |
| 40 | 192.168.40.0/24 | 10040 | TENANT1 |
| 50 | 192.168.50.0/24 | 10050 | TENANT2 |

---

## Проверка

### 1) EVPN соседства на Spine

```bash
spine-01#show bgp evpn summary

BGP summary information for VRF default
Router identifier 10.1.2.1, local AS number 65000
Neighbor Status Codes: m - Under maintenance
  Description              Neighbor    V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  Leaf-01                  10.101.1.0  4 65001          67343     67358    0    0    1d23h Estab   6      6
  Leaf-02                  10.101.1.2  4 65002          67375     67376    0    0    1d23h Estab   6      6
  Leaf-03                  10.101.1.4  4 65003          67368     67398    0    0    1d23h Estab   7      7
  Leaf-04                  10.101.1.6  4 65004          67382     67324    0    0    1d23h Estab   9      9
  bgw-leaf-1               10.101.1.8  4 65005          67347     67385    0    0    1d23h Estab   16     16
  bgw-leaf-2               10.101.1.10 4 65006          67463     67426    0    0    1d23h Estab   16     16
```

**Результат**: 6 соседей (`leaf-01..04`, `bgw-leaf-1/2`) в `Estab`.

### 2) BGP в TENANT1/TENANT2 на BGW

```bash
bgw-leaf-1#show ip bgp summary vrf TENANT1
BGP summary information for VRF TENANT1
Router identifier 100.1.1.0, local AS number 65005
Neighbor Status Codes: m - Under maintenance
  Description              Neighbor  V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  Mikrotik-RT1-TENANT1     100.1.1.1 4 65100          56563     66365    0    0 00:04:22 Estab   8      8
bgw-leaf-1#
bgw-leaf-1#
bgw-leaf-1#show ip bgp summary vrf TENANT2
BGP summary information for VRF TENANT2
Router identifier 100.1.2.0, local AS number 65005
Neighbor Status Codes: m - Under maintenance
  Description              Neighbor  V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
  Mikrotik-RT1-TENANT2     100.1.2.1 4 65100             98       113    0    0 00:04:31 Estab   8      8

```

**Результат**: все соседи с Mikrotik в `Estab`.

### 3) Маршрутизация VRF на BGW Leafs

```bash
bgw-leaf-1#show ip route vrf TENANT1

VRF: TENANT1
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

Gateway of last resort:
 B E      0.0.0.0/0 [200/0]
           via 100.1.1.1, Ethernet3.10

 B E      10.1.3.1/32 [200/0]
           via 100.1.1.1, Ethernet3.10
 B E      10.64.164.0/23 [200/0]
           via 100.1.1.1, Ethernet3.10
 C        100.1.1.0/31
           directly connected, Ethernet3.10
 B E      100.1.2.0/31 [200/0]
           via 100.1.1.1, Ethernet3.10
 B E      100.2.1.0/31 [200/0]
           via 100.1.1.1, Ethernet3.10
 B E      100.2.2.0/31 [200/0]
           via 100.1.1.1, Ethernet3.10
 B E      192.168.10.0/24 [200/0]
           via VTEP 10.1.1.2 VNI 50001 router-mac 50:00:00:cb:38:c2 local-interface Vxlan1
           via VTEP 10.1.1.1 VNI 50001 router-mac 50:00:00:d7:ee:0b local-interface Vxlan1
 B E      192.168.20.0/24 [200/0]
           via VTEP 10.1.1.3 VNI 50001 router-mac 50:00:00:d5:5d:c0 local-interface Vxlan1
           via VTEP 10.1.1.4 VNI 50001 router-mac 50:00:00:03:37:66 local-interface Vxlan1
 B E      192.168.30.0/24 [200/0]
           via VTEP 10.1.1.3 VNI 50001 router-mac 50:00:00:d5:5d:c0 local-interface Vxlan1
           via VTEP 10.1.1.4 VNI 50001 router-mac 50:00:00:03:37:66 local-interface Vxlan1
 B E      192.168.40.0/24 [200/0]
           via VTEP 10.1.1.3 VNI 50001 router-mac 50:00:00:d5:5d:c0 local-interface Vxlan1
           via VTEP 10.1.1.4 VNI 50001 router-mac 50:00:00:03:37:66 local-interface Vxlan1

bgw-leaf-1#
bgw-leaf-1#
bgw-leaf-1#
bgw-leaf-1#
bgw-leaf-1#show ip route vrf TENANT2

VRF: TENANT2
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

Gateway of last resort:
 B E      0.0.0.0/0 [200/0]
           via 100.1.2.1, Ethernet3.20

 B E      10.1.3.1/32 [200/0]
           via 100.1.2.1, Ethernet3.20
 B E      10.64.164.0/23 [200/0]
           via 100.1.2.1, Ethernet3.20
 B E      100.1.1.0/31 [200/0]
           via 100.1.2.1, Ethernet3.20
 C        100.1.2.0/31
           directly connected, Ethernet3.20
 B E      100.2.1.0/31 [200/0]
           via 100.1.2.1, Ethernet3.20
 B E      100.2.2.0/31 [200/0]
           via 100.1.2.1, Ethernet3.20
 B E      192.168.50.0/24 [200/0]
           via VTEP 10.1.1.4 VNI 50002 router-mac 50:00:00:03:37:66 local-interface Vxlan1
```

**Результат**:
- в TENANT2 есть маршрут до `C 192.168.50.0/24` на Leaf-04 через VNI `50002`.

### 4) Type-5 маршруты

```bash
leaf-01#show bgp evpn route-type ip-prefix ipv4
BGP routing table information for VRF default
Router identifier 10.1.1.1, local AS number 65001
Route status codes: * - valid, > - active, S - Stale, E - ECMP head, e - ECMP
                    c - Contributing to ECMP, % - Pending best path selection
Origin codes: i - IGP, e - EGP, ? - incomplete
AS Path Attributes: Or-ID - Originator ID, C-LST - Cluster List, LL Nexthop - Link Local Nexthop

          Network                Next Hop              Metric  LocPref Weight  Path
 * >Ec    RD: 10.1.1.5:50001 ip-prefix 0.0.0.0/0
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 *  ec    RD: 10.1.1.5:50001 ip-prefix 0.0.0.0/0
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 * >Ec    RD: 10.1.1.5:50002 ip-prefix 0.0.0.0/0
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 *  ec    RD: 10.1.1.5:50002 ip-prefix 0.0.0.0/0
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 * >Ec    RD: 10.1.1.6:50001 ip-prefix 0.0.0.0/0
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 *  ec    RD: 10.1.1.6:50001 ip-prefix 0.0.0.0/0
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 * >Ec    RD: 10.1.1.6:50002 ip-prefix 0.0.0.0/0
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 *  ec    RD: 10.1.1.6:50002 ip-prefix 0.0.0.0/0
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 * >Ec    RD: 10.1.1.5:50001 ip-prefix 10.1.3.1/32
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 *  ec    RD: 10.1.1.5:50001 ip-prefix 10.1.3.1/32
                                 10.1.1.5              -       100     0       65000 65005 65100 i

...

 * >Ec    RD: 10.1.1.5:50001 ip-prefix 10.64.164.0/23
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 *  ec    RD: 10.1.1.5:50001 ip-prefix 10.64.164.0/23
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 * >Ec    RD: 10.1.1.5:50002 ip-prefix 10.64.164.0/23
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 *  ec    RD: 10.1.1.5:50002 ip-prefix 10.64.164.0/23
                                 10.1.1.5              -       100     0       65000 65005 65100 i
 * >Ec    RD: 10.1.1.6:50001 ip-prefix 10.64.164.0/23
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 *  ec    RD: 10.1.1.6:50001 ip-prefix 10.64.164.0/23
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 * >Ec    RD: 10.1.1.6:50002 ip-prefix 10.64.164.0/23
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 *  ec    RD: 10.1.1.6:50002 ip-prefix 10.64.164.0/23
                                 10.1.1.6              -       100     0       65000 65006 65100 i
 * >Ec    RD: 10.1.1.5:50001 ip-prefix 100.1.1.0/31

...

 * >Ec    RD: 10.1.1.4:50002 ip-prefix 192.168.50.0/24
                                 10.1.1.4              -       100     0       65000 65004 i
 *  ec    RD: 10.1.1.4:50002 ip-prefix 192.168.50.0/24
                                 10.1.1.4              -       100     0       65000 65004 i

```

**Результат**:
- присутствуют `0.0.0.0/0`, `10.64.164.0/23` с RD/RT TENANT1 и TENANT2;
- next-hop — VTEP BGWs.

### 5) Mikrotik BGP/NAT

```bash
[admin@MikroTik] /routing/bgp/session/print 
Flags: E - established 
 0 E name="to-bgw-leaf-1-t2-1" 
     remote.address=100.1.2.0 .as=65005 .id=100.1.2.0 .capabilities=mp,rr,gr,as4,ap,err .afi=ip .hold-time=9s .messages=19 .bytes=436 .gr-time=300 .eor="" 
     local.address=100.1.2.1 .as=65100 .id=10.1.3.1 .cluster-id=10.1.3.1 .capabilities=mp,rr,gr,as4 .afi=ip .messages=17 .bytes=472 .eor="" 
     output.procid=20 .default-originate=always 
     input.procid=20 ebgp 
     hold-time=9s keepalive-time=3s uptime=39s440ms last-started=2026-03-05 20:21:00 prefix-count=1 

 1 E name="to-bgw-leaf-1-t1-1" 
     remote.address=100.1.1.0 .as=65005 .id=100.1.1.0 .capabilities=mp,rr,gr,as4,ap,err .afi=ip .hold-time=9s .messages=23 .bytes=596 .gr-time=300 .eor=ip 
     local.address=100.1.1.1 .as=65100 .id=10.1.3.1 .cluster-id=10.1.3.1 .capabilities=mp,rr,gr,as4 .afi=ip .messages=15 .bytes=344 .eor="" 
     output.procid=21 .default-originate=always 
     input.procid=21 ebgp 
     hold-time=9s keepalive-time=3s uptime=39s440ms last-started=2026-03-05 20:21:00 prefix-count=5 

 2 E name="to-bgw-leaf-2-t2-1" 
     remote.address=100.2.2.0 .as=65006 .id=100.2.2.0 .capabilities=mp,rr,gr,as4,ap,err .afi=ip .hold-time=9s .messages=20 .bytes=539 .gr-time=300 .eor="" 
     local.address=100.2.2.1 .as=65100 .id=10.1.3.1 .cluster-id=10.1.3.1 .capabilities=mp,rr,gr,as4 .afi=ip .messages=17 .bytes=472 .eor="" 
     output.procid=22 .default-originate=always 
     input.procid=22 ebgp 
     hold-time=9s keepalive-time=3s uptime=39s360ms last-started=2026-03-05 20:21:00 prefix-count=1 

 3 E name="to-bgw-leaf-2-t1-1" 
     remote.address=100.2.1.0 .as=65006 .id=100.2.2.0 .capabilities=mp,rr,gr,as4,ap,err .afi=ip .hold-time=9s .messages=23 .bytes=680 .gr-time=300 .eor=ip 
     local.address=100.2.1.1 .as=65100 .id=10.1.3.1 .cluster-id=10.1.3.1 .capabilities=mp,rr,gr,as4 .afi=ip .messages=17 .bytes=472 .eor="" 
     output.procid=23 .default-originate=always 
     input.procid=23 ebgp 
     hold-time=9s keepalive-time=3s uptime=39s360ms last-started=2026-03-05 20:21:00 prefix-count=5 

```

**Результат**:
- 4 BGP сессии established;

---

## Тест-план

```bash
VPC15> ping 8.8.8.8
84 bytes from 8.8.8.8 icmp_seq=1 ttl=114 time=43.502 ms
84 bytes from 8.8.8.8 icmp_seq=2 ttl=114 time=22.994 ms
84 bytes from 8.8.8.8 icmp_seq=3 ttl=114 time=22.662 ms

VPC15> trace 8.8.8.8
trace to 8.8.8.8, 8 hops max, press Ctrl+C to stop
 1     *  *  *
 2   100.2.1.0   13.943 ms  8.755 ms  8.941 ms
 3   100.1.1.1   13.249 ms  10.994 ms  10.646 ms
 4   10.64.164.1   11.847 ms  12.295 ms  11.066 ms
 5   w.w.w.66   14.252 ms  14.674 ms  14.617 ms
 6   z.z.z.93   14.908 ms  14.281 ms  14.726 ms
 7   y.y.y.238   15.712 ms  15.496 ms  15.382 ms
 8   x.x.x.48   16.068 ms  15.006 ms  15.647 ms

VPC15> trace 192.168.50.20 
trace to 192.168.50.20, 8 hops max, press Ctrl+C to stop
 1     *  *  *
 2   100.1.1.0   11.663 ms  7.838 ms  7.054 ms
 3   100.1.1.1   8.595 ms  8.762 ms  8.391 ms
 4   100.1.2.0   10.632 ms  10.680 ms  10.627 ms
 5   192.168.50.1   26.625 ms  19.136 ms  37.667 ms
 6   *192.168.50.20   22.444 ms (ICMP type:3, code:3, Destination port unreachable)

---

VPC20> ip 192.168.50.20/24 192.168.50.1
Checking for duplicate address...
VPC20 : 192.168.50.20 255.255.255.0 gateway 192.168.50.1
VPC20> 
VPC20> 
VPC20> ping 8.8.8.8
84 bytes from 8.8.8.8 icmp_seq=1 ttl=112 time=65.702 ms
84 bytes from 8.8.8.8 icmp_seq=2 ttl=112 time=50.830 ms
84 bytes from 8.8.8.8 icmp_seq=3 ttl=112 time=47.988 ms

VPC20> trace 192.168.10.15
trace to 192.168.10.15, 8 hops max, press Ctrl+C to stop
 1     *  *  *
 2   100.1.2.0   13.113 ms  9.163 ms  8.981 ms
 3   100.1.2.1   10.662 ms  10.371 ms  10.202 ms
 4   100.1.1.0   16.253 ms  20.887 ms  12.064 ms
 5   192.168.40.1   23.325 ms  20.198 ms  18.544 ms
 6   *192.168.10.15   24.011 ms (ICMP type:3, code:3, Destination port unreachable)
```

**Результат**:

Трафик между VRF проходит через Mikrotik-RT1 (`100.1.1.1` и `100.1.2.1`)