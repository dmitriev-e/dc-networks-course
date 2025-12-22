# Документация по конфигурации Lab 02

## Таблица адресов (Underlay OSPF)

Ниже представлена сводная таблица IP-адресов, настроенных на интерфейсах коммутаторов согласно конфигурационным файлам.

| Device   | Interface   | IP Address    | Subnet Mask/CIDR | Description/Connected To |
|----------|-------------|---------------|------------------|--------------------------|
| **Spine-01** | Loopback0 | 10.1.2.1      | /32              | Router-ID                |
|          | Ethernet1   | 10.101.1.1    | /31              | Link to Leaf-01          |
|          | Ethernet2   | 10.101.1.3    | /31              | Link to Leaf-02          |
|          | Ethernet3   | 10.101.1.5    | /31              | Link to Leaf-03          |
|          | Ethernet4   | 10.101.1.7    | /31              | Link to Leaf-04          |
| **Spine-02** | Loopback0 | 10.1.2.2      | /32              | Router-ID                |
|          | Ethernet1   | 10.101.2.1    | /31              | Link to Leaf-01          |
|          | Ethernet2   | 10.101.2.3    | /31              | Link to Leaf-02          |
|          | Ethernet3   | 10.101.2.5    | /31              | Link to Leaf-03          |
|          | Ethernet4   | 10.101.2.7    | /31              | Link to Leaf-04          |
| **Leaf-01**  | Loopback0 | 10.1.1.1      | /32              | Router-ID                |
|          | Ethernet1   | 10.101.1.0    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.0    | /31              | Link to Spine-02         |
|          | Ethernet3   | -             | -                | Link to VPC15            |
| **Leaf-02**  | Loopback0 | 10.1.1.2      | /32              | Router-ID                |
|          | Ethernet1   | 10.101.1.2    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.2    | /31              | Link to Spine-02         |
|          | Ethernet3   | -             | -                | Link to VPC16            |
| **Leaf-03**  | Loopback0 | 10.1.1.3      | /32              | Router-ID                |
|          | Ethernet1   | 10.101.1.4    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.4    | /31              | Link to Spine-02         |
|          | Ethernet3   | -             | -                | Link to VPC17            |
|          | Ethernet4   | -             | -                | Link to VPC18            |
| **Leaf-04**  | Loopback0 | 10.1.1.4      | /32              | Router-ID                |
|          | Ethernet1   | 10.101.1.6    | /31              | Link to Spine-01         |
|          | Ethernet2   | 10.101.2.6    | /31              | Link to Spine-02         |
|          | Ethernet3   | -             | -                | Link to VPC19            |
|          | Ethernet4   | -             | -                | Link to VPC20            |

## Детали протоколов

- **Routing Protocol:** OSPF Area 0.0.0.1 (для PoD-01)
- **Router-ID:** Loopback0 IP
- **BFD:** Enabled globally (all-interfaces)
- **Passive Interface:** по-умолчанию все passiv

## Проверка конфигурации

- Spine01
```c
spine-01#show ip ospf database

            OSPF Router with ID(10.1.2.1) (Instance ID 1) (VRF default)


                 Router Link States (Area 0.0.0.1)

Link ID         ADV Router      Age         Seq#         Checksum Link count
10.1.1.1        10.1.1.1        737         0x800000e0   0x39a5   5
10.1.2.2        10.1.2.2        728         0x800000e6   0x78f6   9
10.1.2.1        10.1.2.1        1605        0x800000e1   0x720d   9
10.1.1.2        10.1.1.2        770         0x800000e0   0x6c67   5
10.1.1.4        10.1.1.4        755         0x800000e0   0xd2ea   5
10.1.1.3        10.1.1.3        717         0x800000e0   0x9f29   5

spine-01#show ip route ospf

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

 O        10.1.1.1/32 [110/20]
           via 10.101.1.0, Ethernet1
 O        10.1.1.2/32 [110/20]
           via 10.101.1.2, Ethernet2
 O        10.1.1.3/32 [110/20]
           via 10.101.1.4, Ethernet3
 O        10.1.1.4/32 [110/20]
           via 10.101.1.6, Ethernet4
 O        10.1.2.2/32 [110/30]
           via 10.101.1.0, Ethernet1
           via 10.101.1.2, Ethernet2
           via 10.101.1.4, Ethernet3
           via 10.101.1.6, Ethernet4
 O        10.101.2.0/31 [110/20]
           via 10.101.1.0, Ethernet1
 O        10.101.2.2/31 [110/20]
           via 10.101.1.2, Ethernet2
 O        10.101.2.4/31 [110/20]
           via 10.101.1.4, Ethernet3
 O        10.101.2.6/31 [110/20]
           via 10.101.1.6, Ethernet4
```

Видим что для DST Spine-02 (10.1.2.2) у нас доступно 4 маршрута через все 4 Leaf-коммутатора

Проверим OSPF на одном из Leaf-коммутаторе

- Leaf-01
```c
leaf-01#show ip ospf database

            OSPF Router with ID(10.1.1.1) (Instance ID 1) (VRF default)


                 Router Link States (Area 0.0.0.1)

Link ID         ADV Router      Age         Seq#         Checksum Link count
10.1.2.2        10.1.2.2        1104        0x800000e6   0x78f6   9
10.1.2.1        10.1.2.1        123         0x800000e2   0x700e   9
10.1.1.2        10.1.1.2        1148        0x800000e0   0x6c67   5
10.1.1.4        10.1.1.4        1133        0x800000e0   0xd2ea   5
10.1.1.3        10.1.1.3        1095        0x800000e0   0x9f29   5
10.1.1.1        10.1.1.1        1113        0x800000e0   0x39a5   5
leaf-01#
leaf-01#
leaf-01#
leaf-01#show ip route ospf

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

 O        10.1.1.2/32 [110/30]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 O        10.1.1.3/32 [110/30]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 O        10.1.1.4/32 [110/30]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 O        10.1.2.1/32 [110/20]
           via 10.101.1.1, Ethernet1
 O        10.1.2.2/32 [110/20]
           via 10.101.2.1, Ethernet2
 O        10.101.1.2/31 [110/20]
           via 10.101.1.1, Ethernet1
 O        10.101.1.4/31 [110/20]
           via 10.101.1.1, Ethernet1
 O        10.101.1.6/31 [110/20]
           via 10.101.1.1, Ethernet1
 O        10.101.2.2/31 [110/20]
           via 10.101.2.1, Ethernet2
 O        10.101.2.4/31 [110/20]
           via 10.101.2.1, Ethernet2
 O        10.101.2.6/31 [110/20]
           via 10.101.2.1, Ethernet2
```

Видим, что до Leaf-коммутаторов 02, 03, 04 доступно по 2 маршрута (через оба Spine-коммутатора)