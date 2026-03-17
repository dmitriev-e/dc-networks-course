# Выпускной проект: Multi-DC SDN Overlay

## Цель

Разработать и реализовать решение для построения собственных Overlay-сетей поверх хостерских EVPN VXLAN IP-фабрик, к которым компания не имеет административного доступа.

**Постановка задачи:**
- Компания арендует стойки в PoD-ах трёх разных дата-центров (2 города)
- Хостер предоставляет EVPN VXLAN CLOS-фабрику внутри каждого PoD, но без управления и без связности между PoD-ами
- Необходимо построить собственный SDN-оверлей (Proxmox SDN EVPN) поверх хостерской инфраструктуры
- Обеспечить связность VM между стойками внутри PoD, между PoD-ами одного ДЦ и между городами

## Схема сети

![Схема сети](scheme.png)

## Архитектура

```
                    ┌─────────────────────────────────────────────────────────┐
                    │  City1 / DC-X (AS 65101)                                │
                    │  city1-core-rt1/rt2 (NE40) — межгородская связность     │
                    │         │                                                │
                    │  interpod-rt-1/2 (CE12000, AS 65102) — межPoD-связность │
                    │    ┌────┤────────────────────────────────────────┐       │
                    │  PoD1 (Arista, AS 65501+)   PoD2 (Arista, AS 65502+)   │
                    └─────────────────────────────────────────────────────────┘
                                      │ WAN
                    ┌─────────────────────────────────────────────────────────┐
                    │  City2 / DC-Y (AS 65201)                                │
                    │  city2-core-rt1/rt2 (NE40)                              │
                    │  PoD3 (Arista, AS 65503+)                               │
                    └─────────────────────────────────────────────────────────┘
```

### Уровни

| Уровень | Устройства | Роль |
|---|---|---|
| Хостерская фабрика | Arista Spine/Leaf/BGW | EVPN VXLAN CLOS, изолированная внутри PoD |
| BGW | Arista BGW | Граница фабрики, eBGP к InterPoD/Core в VRF TENANT |
| InterPoD | Huawei CE12000 | Маршрутизация агрегатов между PoD1/PoD2 и ядром |
| Core | Huawei NE40 | Межгородская WAN-маршрутизация |
| EVPN-RT | Linux FRR | Route Reflector для Proxmox SDN, VTEP, BGP к leaf |
| Proxmox PVE | Linux | Гипервизор + SDN EVPN клиент (VXLAN VTEP для VM) |

---

## Структура файлов

```
project/
├── ADDRESSING_PLAN.md       — полный адресный план
├── README.md                — этот файл
├── scheme.png               — схема сети
└── configs/
    ├── pod1/                — 8 конфигов Arista EOS (PoD1, City1)
    ├── pod2/                — 8 конфигов Arista EOS (PoD2, City1)
    ├── pod3/                — 8 конфигов Arista EOS (PoD3, City2)
    ├── core/                — 6 конфигов Huawei VRP
    ├── evpn-routers/        — 6 конфигов FRR (Linux)
    └── proxmox/             — сетевые конфиги + Proxmox SDN
```

---

## Инвентарь конфигураций

### Хостерские фабрики (Arista EOS)

| Файл | Устройство | Роль | ASN |
|---|---|---|---|
| `pod1/pod1-spine-01.cfg` | pod1-spine-01 | Spine, EVPN route reflector | 65501 |
| `pod1/pod1-spine-02.cfg` | pod1-spine-02 | Spine, EVPN route reflector | 65501 |
| `pod1/pod1-bgw-1.cfg` | pod1-bgw-1 | Border Gateway, eBGP к interpod | 65515 |
| `pod1/pod1-bgw-2.cfg` | pod1-bgw-2 | Border Gateway, eBGP к interpod | 65516 |
| `pod1/pod1-leaf-r1-1.cfg` | pod1-leaf-r1-1 | Leaf rack1, ESI-LAG к PVE-1/EVPN-RT-1 | 65511 |
| `pod1/pod1-leaf-r1-2.cfg` | pod1-leaf-r1-2 | Leaf rack1, ESI-LAG к PVE-1/EVPN-RT-1 | 65512 |
| `pod1/pod1-leaf-r2-1.cfg` | pod1-leaf-r2-1 | Leaf rack2, ESI-LAG к PVE-2/EVPN-RT-2 | 65513 |
| `pod1/pod1-leaf-r2-2.cfg` | pod1-leaf-r2-2 | Leaf rack2, ESI-LAG к PVE-2/EVPN-RT-2 | 65514 |

PoD2 и PoD3 — аналогичная структура (`pod2/`, `pod3/`) с ASN 65502+/65503+ и адресами 10.2.x.x/10.3.x.x.  
Отличие PoD3: BGW-leaf подключены к `city2-core-rt1/rt2` вместо `interpod-rt-1/2`.

### Ядро сети (Huawei VRP)

| Файл | Устройство | Роль | ASN |
|---|---|---|---|
| `core/interpod-rt-1.cfg` | interpod-rt-1 | CE12000, InterPoD rack1 | 65102 |
| `core/interpod-rt-2.cfg` | interpod-rt-2 | CE12000, InterPoD rack2 | 65102 |
| `core/city1-core-rt1.cfg` | city1-core-rt1 | NE40, City1 Core primary | 65101 |
| `core/city1-core-rt2.cfg` | city1-core-rt2 | NE40, City1 Core secondary | 65101 |
| `core/city2-core-rt1.cfg` | city2-core-rt1 | NE40, City2 Core primary | 65201 |
| `core/city2-core-rt2.cfg` | city2-core-rt2 | NE40, City2 Core secondary | 65201 |

### EVPN Route Reflectors (Linux FRR)

| Файл | Устройство | Роль | ASN |
|---|---|---|---|
| `evpn-routers/dcx-pod1-evpn-rt-1.conf` | dcX-pod1-evpn-rt-1 | PoD1 rack1 RR | 65111 |
| `evpn-routers/dcx-pod1-evpn-rt-2.conf` | dcX-pod1-evpn-rt-2 | PoD1 rack2 RR | 65111 |
| `evpn-routers/dcx-pod2-evpn-rt-1.conf` | dcX-pod2-evpn-rt-1 | PoD2 rack1 RR | 65112 |
| `evpn-routers/dcx-pod2-evpn-rt-2.conf` | dcX-pod2-evpn-rt-2 | PoD2 rack2 RR | 65112 |
| `evpn-routers/dcy-pod3-evpn-rt-1.conf` | dcY-pod3-evpn-rt-1 | PoD3 rack1 RR | 65113 |
| `evpn-routers/dcy-pod3-evpn-rt-2.conf` | dcY-pod3-evpn-rt-2 | PoD3 rack2 RR | 65113 |

### Proxmox SDN

| Файл | Устройство |
|---|---|
| `proxmox/dcx-pod1-pve-1-interfaces` | dcX-pod1-pve-1 /etc/network/interfaces |
| `proxmox/dcx-pod1-pve-2-interfaces` | dcX-pod1-pve-2 /etc/network/interfaces |
| `proxmox/dcx-pod2-pve-1-interfaces` | dcX-pod2-pve-1 /etc/network/interfaces |
| `proxmox/dcx-pod2-pve-2-interfaces` | dcX-pod2-pve-2 /etc/network/interfaces |
| `proxmox/dcy-pod3-pve-1-interfaces` | dcY-pod3-pve-1 /etc/network/interfaces |
| `proxmox/dcy-pod3-pve-2-interfaces` | dcY-pod3-pve-2 /etc/network/interfaces |
| `proxmox/proxmox-sdn.cfg` | Proxmox SDN (controller/zone/vnet/subnet) |

---

## Ключевые технические решения

### 1. ESI-LAG с /31 anycast IP (Leaf → Server)

Каждый Proxmox-сервер и EVPN-RT подключён к двум leaf-коммутаторам стойки через LACP bond (ESI-LAG). Оба leaf имеют **одинаковый anycast IP** на Port-Channel (VRF TENANT), сервер получает второй адрес /31.

```
leaf-r1-1 Port-Channel2 ip address virtual 10.11.0.0/31  ─┐
                                                            ├── evpn-rt-1 bond0: 10.11.0.1/31
leaf-r1-2 Port-Channel2 ip address virtual 10.11.0.0/31  ─┘
```

Благодаря EVPN DF-election только один leaf активен в каждый момент. EVPN-RT видит consistent AS 65501 от обоих leaf (через `local-as ... no-prepend replace-as`).

### 2. Чистый L3VNI (без L2VNI)

Между серверами **нет L2 связности**. VRF TENANT использует только L3VNI = 50001. Это упрощает фабрику и исключает BUM-флуд.

### 3. Двухуровневый BGP для серверов

```
PVE ──(iBGP EVPN)──► EVPN-RT (RR) ──(eBGP IPv4)──► Leaf (VRF TENANT) ──(EVPN Type-5)──► BGW ──► InterPoD/Core
```

- **iBGP EVPN** между PVE и EVPN-RT (через прямой линк e2): обмен MAC/IP/IMET маршрутами для SDN VM сетей
- **eBGP IPv4** между EVPN-RT и leaf (через bond0 / anycast): обмен IP-маршрутами (лупбэки VTEP, VM-подсети)
- **EVPN Type-5** в хостерской фабрике: распространение IP-префиксов между PoD и к BGW

### 4. Cross-PoD BGP EVPN

EVPN-RT серверы разных PoD-ов пирятся напрямую (eBGP между AS 65111/65112/65113). Транспорт — IP путь через хостерскую фабрику: лупбэки EVPN-RT достижимы через VRF TENANT → BGW → InterPoD/Core.

### 5. PoD-агрегация на BGW

BGW анонсирует в InterPoD/Core **серверный** агрегат:
- PoD1 → `10.11.0.0/16`
- PoD2 → `10.12.0.0/16`
- PoD3 → `10.13.0.0/16`

Хостерский underlay (10.1.x.x / 10.2.x.x / 10.3.x.x) остаётся внутри PoD-фабрики и наружу не анонсируется. В серверный /16 входят: /31 ESI-LAG линки, e2-линки EVPN-RT↔PVE, лупбэки EVPN-RT/PVE (VTEP), VM-подсети.

### 6. BGP PVE ↔ EVPN-RT через e2-линк (не лупбэки)

iBGP EVPN между Proxmox-хостом и EVPN-RT устанавливается по прямому e2-линку (10.11.0.8/9 и т.д.), а не по лупбэкам. Причина: хостерская фабрика не знает адресов серверных лупбэков до установления BGP-сессий. Адреса e2-линков физически достижимы без маршрутизации.

---

## Адресация (краткая сводка)

Полный план: [ADDRESSING_PLAN.md](ADDRESSING_PLAN.md)

| PoD | Хостерский underlay | BGW aggregate (наружу) | Server ESI-LAG /31 | e2-линки | VTEP loopbacks | VM network |
|---|---|---|---|---|---|---|
| PoD1 | 10.1.0.0/16 (внутри PoD) | **10.11.0.0/16** | 10.11.0.0–7/31 | 10.11.0.8–11/31 | 10.11.20.x/32 | 10.11.128.0/24 |
| PoD2 | 10.2.0.0/16 (внутри PoD) | **10.12.0.0/16** | 10.12.0.0–7/31 | 10.12.0.8–11/31 | 10.12.20.x/32 | 10.12.128.0/24 |
| PoD3 | 10.3.0.0/16 (внутри PoD) | **10.13.0.0/16** | 10.13.0.0–7/31 | 10.13.0.8–11/31 | 10.13.20.x/32 | 10.13.128.0/24 |

| Сеть | Диапазон |
|---|---|
| InterPoD/Core P2P | 172.16.10.x/31, 172.16.1.x/31, 172.16.2.x/31 |
| PoD3/City2-Core P2P | 172.16.3.x/31 |
| Inter-DC WAN | 172.16.100.x/31 |
| Core loopbacks | 172.16.255.x/32 |

---

## Потоки трафика

### VM intra-PoD (VM-A в PoD1 → VM-B в PoD1)

```
VM-A → PVE-1 (VXLAN encap, VNI 100)
     → [hoster fabric VRF TENANT: leaf→spine→leaf]
     → PVE-2 (VXLAN decap)
     → VM-B
```
VTEP-адреса PVE-1 и PVE-2 известны через iBGP EVPN с EVPN-RT-1/2.

### VM inter-PoD (PoD1 → PoD2)

```
VM-A → PVE-1 (VXLAN encap, VNI 100)
     → hoster PoD1 fabric (L3VNI) → BGW-1/2
     → interpod-rt-1/2
     → BGW PoD2
     → hoster PoD2 fabric → PVE в PoD2 (VXLAN decap)
     → VM-B
```

### VM inter-DC (PoD1 City1 → PoD3 City2)

```
VM-A → PVE PoD1 → BGW PoD1 → interpod-rt → city1-core-rt
     → [WAN 172.16.100.x/31] → city2-core-rt
     → BGW PoD3 → hoster PoD3 fabric → PVE PoD3 → VM-B
```

---

## Проверка

### Хостерская фабрика (Arista)

```bash
# Underlay BGP
show bgp summary
show ip route

# EVPN overlay
show bgp evpn summary
show bgp evpn route-type ip-prefix
show vxlan address-table

# VRF TENANT
show ip route vrf TENANT
show bgp evpn route-type ip-prefix vrf TENANT

# ESI-LAG
show evpn ethernet-segment detail
show port-channel 1 detail
```

### Ядро сети (Huawei VRP)

```bash
# BGP соседи
display bgp peer
display bgp routing-table

# Маршруты между PoD-ами
display ip routing-table 10.1.0.0 255.255.0.0
display ip routing-table 10.2.0.0 255.255.0.0
display ip routing-table 10.3.0.0 255.255.0.0
```

### EVPN-RT (Linux FRR)

```bash
# BGP соседи
vtysh -c "show bgp summary"

# EVPN маршруты
vtysh -c "show bgp l2vpn evpn"
vtysh -c "show bgp l2vpn evpn route type prefix"

# IP маршруты (лупбэки других PoD через хостерскую фабрику)
ip route show
vtysh -c "show ip route"

# VXLAN туннели
bridge fdb show dev vxlan0
```

### Proxmox SDN

```bash
# Статус SDN
pvesdn status

# VXLAN туннели
bridge fdb show | grep vxlan

# BGP сессии к EVPN-RT (внутри Proxmox используется frr)
vtysh -c "show bgp summary"
vtysh -c "show bgp l2vpn evpn"
```

---

## Тест-план

| # | Тест | Ожидаемый результат |
|---|---|---|
| 1 | `ping 10.11.0.0` с EVPN-RT-1 | Leaf rack1 anycast отвечает |
| 2 | `ping 10.11.20.2` с EVPN-RT-1 | EVPN-RT-2 loopback достижим (через хостерскую фабрику) |
| 3 | `ping 10.12.20.1` с EVPN-RT-1 PoD1 | EVPN-RT-1 PoD2 loopback достижим (через InterPoD) |
| 4 | `ping 10.13.20.1` с EVPN-RT-1 PoD1 | EVPN-RT-1 PoD3 loopback достижим (через WAN) |
| 5 | `vtysh -c "show bgp l2vpn evpn"` на EVPN-RT-1 | Видны EVPN маршруты от PoD2 и PoD3 EVPN-RT |
| 6 | `ping <VM-IP в PoD2>` с VM в PoD1 | VM-to-VM cross-PoD связность |
| 7 | `ping <VM-IP в PoD3>` с VM в PoD1 | VM-to-VM inter-DC связность |
| 8 | Отключить один leaf (rack1) — трафик продолжается | ESI-LAG failover, DF переходит на второй leaf |
| 9 | Отключить BGW-1 — трафик в другие PoD продолжается | ECMP через BGW-2 |
| 10 | `show bgp evpn route-type ip-prefix` на BGW | Видны prefixes 10.2.0.0/16 и 10.3.0.0/16 (от remote PoDs) |
