#!/bin/bash
# Проверка установки Promtail
if apt-cache policy promtail | grep none
then
echo "Промтейл не установлен"
cd $HOME
echo "Будет установлен unzip для установки Промтейл"
sudo apt-get install unzip -y
sudo wget https://github.com/grafana/loki/releases/download/v3.0.0/promtail-linux-amd64.zip
sudo unzip ./promtail-linux-amd64.zip
sudo wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
sudo sed -i 's/localhost:3100/195.201.98.42:3100/g' promtail-local-config.yaml
sudo sed -i 's|*log|caddy/*log|g' promtail-local-config.yaml
echo "Промтейл установлен и настроен"
else
echo "Промтейл уже установлен:"
which promtail
cd $HOME
fi

#Настройка в случае существуюшего конфига или его отсутствия
if grep localhost:3100 $HOME/promtail-local-config.yaml
then
echo "Будет выполнена настройка конфигурации сервера Локи"
sudo sed -i 's/localhost:3100/195.201.98.42:3100/g' promtail-local-config.yaml
else
echo "Файл не найден или настройка хоста сервера Локи не требуется"
sudo wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
sudo sed -i 's/localhost:3100/195.201.98.42:3100/g' promtail-local-config.yaml
fi

if grep log/*log $HOME/promtail-local-config.yaml
then
echo "Требуется настройка пути логгирования"
sudo sed -i 's|*log|caddy/*log|g' promtail-local-config.yaml
echo "Выполнено"
else
echo "Путь логгирования уже настроен"
fi

#Проверка исполняемого файла Промтейл"
if -f $HOME/promtail-linux-amd64
then
echo "Файл Промтейл установлен в домашней директории"
else
echo "Файл Промтейла не найден и будет установлен"
echo "Будет установлен unzip для установки Промтейл"
sudo apt-get install unzip -y
cd $HOME
sudo wget https://github.com/grafana/loki/releases/download/v3.0.0/promtail-linux-amd64.zip
sudo unzip ./promtail-linux-amd64.zip
echo "Исполняемый файл Промтейл установлен по пути:"
echo $HOME

#Подготовка службы
touch /etc/systemd/system/promtail.service
sudo cat > /etc/systemd/system/promtail.service << EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$HOME/promtail-linux-amd64 -config.file $HOME/promtail-local-config.yaml
# Give a reasonable amount of time for promtail to start up/shut down
TimeoutSec = 60
Restart = on-failure
RestartSec = 2

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-restart
sudo systemctl enable promtail.service
sudo systemctl start promtail.service
echo "В теории все должно работать, нужен фидбек"
