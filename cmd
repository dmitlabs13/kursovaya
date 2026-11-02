sudo ansible-playbook -k -K -i inventory.ini reset_machine_id.yml /


network:
  version: 2
  ethernets:
    enp6s18:
      dhcp4: true
    enp6s19:
      dhcp4: false
      addresses:
        - 192.168.6.10/24
      routes:
        - to: 192.168.7.0/24
          via: 192.168.6.1


# Проверить синтаксис конфигурации
sudo netplan generate

# Применить с возможностью отката при потере связи
sudo netplan try

# Проверить IP-адреса интерфейсов
ip -br addr

# Проверить таблицу маршрутизации
ip route
