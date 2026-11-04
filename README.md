# kursovaya
## Тема «Развёртывание и сопровождение веб-проекта с мониторингом, централизованным логированием и резервным копированием»

какой-то веб сервис с фронтом и минимум двумя беками(должна быть балансировка). Это либо cms либо свой проект. Соответсвенно дальше, должна быть настроена репликация БД, это все должно мониториться, это все должно логироваться.\
Важно, на профешинал на фронте должно быть все по https(серт обязателен, но летсэндкрипт или нет, желателен летсэндкрипт)\
между фронтом и беком не нужен серт, там по http это окей.\
итак, фронт работающий по https, два бека для балансировки которые пользуются БД, как следствие это БД с репликой. И весь проект мониторится и со всего проекта собираются логи.\
SE линукс отключать, но при этом с фронта сделать доступными только порты 80 и 443, в идеале сделатть чтобы все было в DMZ и чтобы только фронт торчал на ружу.\
Все как всегда, все должно быть в оркестраторе, все должно быть запушено в гите, должен быть адекватный ридми\
В отличие от бейскиа не стоит задача развернуть все во время защины. В защите стенд уже должен работать.


### Описание/Пошаговая инструкция выполнения домашнего задания:

Веб проект с развертыванием нескольких виртуальных машин должен отвечать следующим требованиям:
включен https;
основная инфраструктура в DMZ зоне;
файрвалл на входе;
сбор метрик и настроенный алертинг;
организован централизованный сбор логов;
организован backup.


# необходимые сервера
k-ans - absible - поставил чистую ОС -- сбросил ID -- \
k-front - nginx, балансировка -- поставил чистую ОС -- сбросил ID\
k-b1 - wordpress\
k-b2 - wordpress\
k-db1 - postgres, primary\
k-db2 - postgres, replica\
k-log - graylog\
k-mon - prometheus\
k-backup - резервное копирование
k-net - маршрутизатор и wirewall для построения dmz. -- поставил чистую машину -- сделал снапшот, 

## Сетевая инфраструктура

### Сетевые сегменты

| Proxmox Bridge | Подсеть | Зона | Назначение |
|---|---|---|---|
| `vmbr4` | `192.168.50.0/24` | WAN | Внешняя сеть |
| `vmbr6_sw6` | `192.168.6.0/24` | DMZ | Демилитаризованная зона, фронтенд |
| `vmbr7-sw7` | `192.168.7.0/24` | INTERNAL | Внутренняя сеть |

### Сетевые интерфейсы k-net

| Интерфейс | Сегмент | IP-адрес |
|---|---|---|
| `net0` | WAN | DHCP (`192.168.50.0/24`) |
| `net1` | DMZ | `192.168.6.1/24` |
| `net2` | INTERNAL | `192.168.7.1/24` |

### Адресация виртуальных машин

| Виртуальная машина | Назначение | IP-адрес | Шлюз |
|---|---|---|---|
| `k-net` | Router / Firewall | `192.168.50.204` (WAN) | `192.168.50.1` |
|       | | | |
|  `DMZ`     | | | |
| `k-front` | Nginx / Load Balancer | `192.168.6.10` | `192.168.6.1` |
|       | | | |
|  `INTERNAL`     | | | |
| `k-b1` | WordPress Backend 1 | `192.168.7.11` | `192.168.7.1` |
| `k-b2` | WordPress Backend 2 | `192.168.7.12` | `192.168.7.1` |
| `k-db1` | PostgreSQL Primary | `192.168.7.21` | `192.168.7.1` |
| `k-db2` | PostgreSQL Replica | `192.168.7.22` | `192.168.7.1` |
| `k-log` | Graylog | `192.168.7.31` | `192.168.7.1` |
| `k-mon` | Prometheus | `192.168.7.32` | `192.168.7.1` |
| `k-backup` | Backup Server | `192.168.7.33` | `192.168.7.1` |
| `k-ans` | Ansible Control Node | `192.168.7.40` | `192.168.7.1` |



<img width="320" height="376" alt="image" src="https://github.com/user-attachments/assets/ff6256d5-05a4-4b81-b350-b7a2e051e6ca" />




по шагам как то так

1. Чистая VM
       ↓
2. Базовая настройка
       ↓
3. SNAPSHOT: clean
       ↓
4. Изучаю сервис руками
       ↓
5. SNAPSHOT: manual
       ↓
6. Возвращаюсь к clean
       ↓
7. Пишу Ansible
       ↓
8. Проверяю
       ↓
9. SNAPSHOT: ansible


### структура в ansible
kursovaya/
│\
├── inventory/\
│   └── inventory.ini\
│\
├── playbooks/\
│   ├── k-front-base.yml\
│   ├── k-front.yml\
│   │\
│   ├── k-back1-base.yml\
│   ├── k-back1.yml\
│   │\
│   ├── k-back2-base.yml\
│   ├── k-back2.yml\
│   │\
│   ├── k-db1-base.yml\
│   ├── k-db1.yml\
│   │\
│   ├── k-db2-base.yml\
│   ├── k-db2.yml\
│   │\
│   ├── k-prom-base.yml\
│   ├── k-prom.yml\
│   │\
│   ├── k-glog-base.yml
│   ├── k-glog.yml
│   │
│   └── k-backup-base.yml\
│       k-backup.yml\
│\
└── README.md\


---------------------------------------\
шпрагалка\
sadmin@alp-ansible:~/projects/machine-id$ sudo nano  reset_machine_id.yml \
sadmin@alp-ansible:~/projects/machine-id$ sudo nano inventory.ini\
sadmin@alp-ansible:~/projects/machine-id$ sudo ansible-playbook -k -K -i inventory.ini reset_machine_id.yml \

------------------------------------------\

Установил машину с ansible. networkname: k-an ip: 192.168.50.206\
Ставим Python: sudo apt install python3 python3-pip python3-dev\
Ставим ansible: sudo apt install ansible\
Создаем структуру папок:\
mkdir kursovaya
mkdir kursovaya/inventory
mkdir kursovaya/playbooks
touch kursovaya/readme.md
touch kursovaya/inventory/hosts.yml

Создаем inventory файл:\
[front]\
k-front ansible_host=192.168.6.10\

[b]\
k-b1 ansible_host=192.168.7.11\
k-b2 ansible_host=192.168.7.12\

[db]\
k-db1 ansible_host=192.168.7.21\
k-db2 ansible_host=192.168.7.22\

[mon]\
k-mon ansible_host=192.168.7.32\

[log]\
k-log ansible_host=192.168.7.31\

[backup]\
k-backup ansible_host=192.168.7.33\

[net]\
k-net ansible_host=192.168.50.204\

[all:vars]\
ansible_user=sadmin\




