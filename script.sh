#!/bin/bash
# Checking Promtail installation
if apt-cache policy promtail | grep none
then
echo "Promtail is not installed"
cd $HOME
echo "Zip app will be installed to help Promtail installation"
sudo apt-get install unzip -y
sudo wget https://github.com/grafana/loki/releases/download/v3.0.0/promtail-linux-amd64.zip
sudo unzip ./promtail-linux-amd64.zip
sudo wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
sudo sed -i 's/localhost:3100/195.201.98.42:3100/g' promtail-local-config.yaml
sudo sed -i 's|*log|caddy/*log|g' promtail-local-config.yaml
echo "Promtail installed and configured"
else
echo "Promtail installed in:"
which promtail
cd $HOME
fi

#Configuring in case of matching config file
if grep localhost:3100 $HOME/promtail-local-config.yaml
then
echo "Configuring Loki server"
sudo sed -i 's/localhost:3100/195.201.98.42:3100/g' promtail-local-config.yaml
else
echo "Config file hasn't beed found and will be installed and configured"
sudo wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
sudo sed -i 's/localhost:3100/195.201.98.42:3100/g' promtail-local-config.yaml
fi

if grep log/*log $HOME/promtail-local-config.yaml
then
echo "Configuring logging path"
sudo sed -i 's|*log|caddy/*log|g' promtail-local-config.yaml
echo "Done"
else
echo "Logging path already been modified"
fi

#Checking Promtail exec file"
if -f $HOME/promtail-linux-amd64
then
echo "Promtail exec file installed in home directory"
else
echo "Promtail exec file hasn't been found and will be installed"
echo "Zip app will be installed to help Promtail installation"
sudo apt-get install unzip -y
cd $HOME
sudo wget https://github.com/grafana/loki/releases/download/v3.0.0/promtail-linux-amd64.zip
sudo unzip ./promtail-linux-amd64.zip
echo "Promtail exec file is installed in:"
echo $HOME

#Service configuration
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
echo "Things must work well. Please report any misconfigurations in discord"
