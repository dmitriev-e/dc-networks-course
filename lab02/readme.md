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

