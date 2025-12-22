# Документация по конфигурации Lab 03

## Таблица адресов (Underlay IS-IS)

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

## Детали протокола IS-IS

### Основные параметры

- **Routing Protocol:** IS-IS Level-1 для изоляции маршрутизации внутри одного PoD.
- **IS-IS Instance:** UNDERLAY
- **Area:** 49.0001 (для PoD-01)
- **BFD:** Enabled globally (all-interfaces)
- **Network Type:** Point-to-Point на всех interconnect интерфейсах
- **Passive Interface:** Loopback0 на всех устройствах

### NET (Network Entity Title) адреса

IS-IS использует NET адреса в формате: **49.AAAA.BBBB.CCCC.DDDD.00**
- **49** - приватный AFI (Authority and Format Identifier)
- **AAAA** - Area ID (0001 для PoD-01)
- **BBBB.CCCC.DDDD** - System ID (формируется из последних 3 октетов Loopback IP)
- **00** - NSEL (Network Selector, всегда 00 для маршрутизаторов)

| Device     | Loopback IP | NET Address                     | System ID           |
|------------|-------------|---------------------------------|---------------------|
| Spine-01   | 10.1.2.1    | 49.0001.0001.0002.0001.00      | 0001.0002.0001     |
| Spine-02   | 10.1.2.2    | 49.0001.0001.0002.0002.00      | 0001.0002.0002     |
| Leaf-01    | 10.1.1.1    | 49.0001.0001.0001.0001.00      | 0001.0001.0001     |
| Leaf-02    | 10.1.1.2    | 49.0001.0001.0001.0002.00      | 0001.0001.0002     |
| Leaf-03    | 10.1.1.3    | 49.0001.0001.0001.0003.00      | 0001.0001.0003     |
| Leaf-04    | 10.1.1.4    | 49.0001.0001.0001.0004.00      | 0001.0001.0004     |

### Преобразование IP в System ID (упрощенный метод)

Формат System ID: **BBBB.CCCC.DDDD** где B, C, D - это 2-й, 3-й и 4-й октеты IP в decimal с padding

**Правило:** Берем последние 3 октета IP адреса и преобразуем каждый в 4-значное число с нулями слева.

**Примеры:**
- `10.1.2.1` → октеты: **1**, **2**, **1** → System ID: **0001.0002.0001**
- `10.1.1.3` → октеты: **1**, **1**, **3** → System ID: **0001.0001.0003**
- `10.1.2.2` → октеты: **1**, **2**, **2** → System ID: **0001.0002.0002**

**Полный NET:**
- `10.1.2.1` → `49.0001` + `0001.0002.0001` + `00` = **49.0001.0001.0002.0001.00**

## Проверка конфигурации

### Spine-01

```c
spine-01#show isis database
Legend:
H - hostname conflict
U - node unreachable

IS-IS Instance: UNDERLAY VRF: default
  IS-IS Level 1 Link State Database
    LSPID                   Seq Num  Cksum  Life Length IS  Received LSPID        Flags
    leaf-01.00-00                 3  62641  1117    123 L1  0001.0001.0001.00-00  <>
    leaf-02.00-00                 3  12903  1118    123 L1  0001.0001.0002.00-00  <>
    leaf-03.00-00                 3  28445  1114    123 L1  0001.0001.0003.00-00  <>
    leaf-04.00-00                 3  44242  1114    123 L1  0001.0001.0004.00-00  <>
    spine-01.00-00                5   3981  1108    172 L1  0001.0002.0001.00-00  <>
    spine-02.00-00                5  62363  1118    172 L1  0001.0002.0002.00-00  <>

spine-01#show isis neighbors

Instance  VRF      System Id        Type Interface          SNPA              State Hold time   Circuit Id
UNDERLAY  default  leaf-01          L1   Ethernet1          P2P               UP    30          11
UNDERLAY  default  leaf-02          L1   Ethernet2          P2P               UP    29          12
UNDERLAY  default  leaf-03          L1   Ethernet3          P2P               UP    27          14
UNDERLAY  default  leaf-04          L1   Ethernet4          P2P               UP    25          10
spine-01#show ip ro isis

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

 I L1     10.1.1.1/32 [115/20]
           via 10.101.1.0, Ethernet1
 I L1     10.1.1.2/32 [115/20]
           via 10.101.1.2, Ethernet2
 I L1     10.1.1.3/32 [115/20]
           via 10.101.1.4, Ethernet3
 I L1     10.1.1.4/32 [115/20]
           via 10.101.1.6, Ethernet4
 I L1     10.1.2.2/32 [115/30]
           via 10.101.1.0, Ethernet1
           via 10.101.1.2, Ethernet2
           via 10.101.1.4, Ethernet3
           via 10.101.1.6, Ethernet4
 I L1     10.101.2.0/31 [115/20]
           via 10.101.1.0, Ethernet1
 I L1     10.101.2.2/31 [115/20]
           via 10.101.1.2, Ethernet2
 I L1     10.101.2.4/31 [115/20]
           via 10.101.1.4, Ethernet3
 I L1     10.101.2.6/31 [115/20]
           via 10.101.1.6, Ethernet4
```

Видим, что для DST Spine-02 (10.1.2.2) у нас доступно 4 маршрута через все 4 Leaf-коммутатора с метрикой 30 (по умолчанию cost IS-IS = 10 на каждый hop).

### Leaf-01

```c
leaf-01#show isis database
Legend:
H - hostname conflict
U - node unreachable

IS-IS Instance: UNDERLAY VRF: default
  IS-IS Level 1 Link State Database
    LSPID                   Seq Num  Cksum  Life Length IS  Received LSPID     s
    leaf-01.00-00                 3  62641  1162    123 L1  0001.0001.0001.00-0>
    leaf-02.00-00                 3  12903  1164    123 L1  0001.0001.0002.00-0>
    leaf-03.00-00                 3  28445  1159    123 L1  0001.0001.0003.00-0>
    leaf-04.00-00                 3  44242  1159    123 L1  0001.0001.0004.00-0>
    spine-01.00-00                5   3981  1154    172 L1  0001.0002.0001.00-0>
    spine-02.00-00                5  62363  1164    172 L1  0001.0002.0002.00-0>

leaf-01#
leaf-01#
leaf-01#show isis database
Legend:
H - hostname conflict
U - node unreachable

IS-IS Instance: UNDERLAY VRF: default
  IS-IS Level 1 Link State Database
    LSPID                   Seq Num  Cksum  Life Length IS  Received LSPID        Flags
    leaf-01.00-00                 3  62641  1156    123 L1  0001.0001.0001.00-00  <>
    leaf-02.00-00                 3  12903  1157    123 L1  0001.0001.0002.00-00  <>
    leaf-03.00-00                 3  28445  1153    123 L1  0001.0001.0003.00-00  <>
    leaf-04.00-00                 3  44242  1153    123 L1  0001.0001.0004.00-00  <>
    spine-01.00-00                5   3981  1147    172 L1  0001.0002.0001.00-00  <>
    spine-02.00-00                5  62363  1157    172 L1  0001.0002.0002.00-00  <>

leaf-01#show isis neighbors

Instance  VRF      System Id        Type Interface          SNPA              State Hold time   Circuit Id
UNDERLAY  default  spine-01         L1   Ethernet1          P2P               UP    24          1C
UNDERLAY  default  spine-02         L1   Ethernet2          P2P               UP    25          13
leaf-01#
leaf-01#show ip ro isis

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

 I L1     10.1.1.2/32 [115/30]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 I L1     10.1.1.3/32 [115/30]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 I L1     10.1.1.4/32 [115/30]
           via 10.101.1.1, Ethernet1
           via 10.101.2.1, Ethernet2
 I L1     10.1.2.1/32 [115/20]
           via 10.101.1.1, Ethernet1
 I L1     10.1.2.2/32 [115/20]
           via 10.101.2.1, Ethernet2
 I L1     10.101.1.2/31 [115/20]
           via 10.101.1.1, Ethernet1
 I L1     10.101.1.4/31 [115/20]
           via 10.101.1.1, Ethernet1
 I L1     10.101.1.6/31 [115/20]
           via 10.101.1.1, Ethernet1
 I L1     10.101.2.2/31 [115/20]
           via 10.101.2.1, Ethernet2
 I L1     10.101.2.4/31 [115/20]
           via 10.101.2.1, Ethernet2
 I L1     10.101.2.6/31 [115/20]
           via 10.101.2.1, Ethernet2
```

Видим, что до Leaf-коммутаторов 02, 03, 04 доступно по 2 маршрута (через оба Spine-коммутатора) с метрикой 30.

## Примечания

- Все P2P линки используют /31 подсети (RFC 3021) для экономии адресов
- Loopback интерфейсы используют /32 маски
- Все устройства находятся в одной IS-IS area (49.0001)
- Используется **Level-1** для изоляции маршрутизации внутри PoD-01
- При расширении до нескольких PoD потребуется настроить L1/L2 роутеры на границах
- Passive interface на Loopback0 предотвращает отправку Hello пакетов
- Point-to-point тип сети на всех interconnect линках исключает выборы DIS (Designated IS)
