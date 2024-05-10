#!/bin/bash
# https://github.com/GitArtyon/Sharings/blob/main/script.sh
# UTILS
exists()
{
  command -v "$1" >/dev/null 2>&1
}

# ENV
NG_PROMTAIL_BINARY_ARCHIVE="promtail-linux-amd64.zip"
NG_PROMTAIL_BINARY="promtail-linux-amd64"
NG_PROMTAIL_RELEASE="v3.0.0"
NG_PROMTAIL_CONFIG_NAME="promtail-local-config.yaml"
NG_PROMTAIL_DIR="$HOME/.promtail"
NG_PROMTAIL_LOKI_SERVER_ADDRESS="195.201.98.42:3100"

# Checking Promtail installation
if exists $NG_PROMTAIL_BINARY; then
    echo "Promtail installed in: $(which $NG_PROMTAIL_BINARY)"
    cd $HOME
else
    echo "Promtail is not installed"
    mkdir $NG_PROMTAIL_DIR
    cd $NG_PROMTAIL_DIR
    echo "Zip app will be installed to help Promtail installation"
    sudo apt-get install unzip -y < "/dev/null"
    wget -O $NG_PROMTAIL_DIR/$NG_PROMTAIL_BINARY_ARCHIVE https://github.com/grafana/loki/releases/download/$NG_PROMTAIL_RELEASE/$NG_PROMTAIL_BINARY_ARCHIVE
    unzip $NG_PROMTAIL_DIR/$NG_PROMTAIL_BINARY_ARCHIVE
    cp $NG_PROMTAIL_DIR/$NG_PROMTAIL_BINARY /usr/local/bin/
    wget -O $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/$NG_PROMTAIL_CONFIG_NAME
    sed -i 's/localhost:3100/$NG_PROMTAIL_LOKI_SERVER_ADDRESS/g' $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME
    sed -i 's|*log|caddy/*log|g' $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME
    echo "Promtail installed and configured"
fi

# Configuring in case of matching config file
if grep localhost:3100 $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME; then
    echo "Configuring Loki server"
    sed -i 's/localhost:3100/$NG_PROMTAIL_LOKI_SERVER_ADDRESS/g' $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME
else
    echo "Config file hasn't beed found and will be installed and configured"
    wget -O $NG_PROMTAIL_CONFIG_NAME https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/$NG_PROMTAIL_CONFIG_NAME
    sed -i 's/localhost:3100/$NG_PROMTAIL_LOKI_SERVER_ADDRESS/g' $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME
fi

if grep log/*log $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME; then
    echo "Configuring logging path"
    sed -i 's|*log|caddy/*log|g' $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME
    echo "Done"
else
    echo "Logging path already been modified"
fi

# Checking Promtail exec file"
if [ -f $(which $NG_PROMTAIL_BINARY) ]; then
    echo "Promtail installed in: $(which $NG_PROMTAIL_BINARY)"
else
    echo "Promtail exec file hasn't been found and will be installed"
    echo "Unzip package will be installed to help Promtail installation"
    sudo apt-get install unzip -y < "/dev/null"
    cd $NG_PROMTAIL_DIR
    wget -O $NG_PROMTAIL_DIR/$NG_PROMTAIL_BINARY_ARCHIVE https://github.com/grafana/loki/releases/download/$NG_PROMTAIL_RELEASE/$NG_PROMTAIL_BINARY_ARCHIVE
    unzip $NG_PROMTAIL_DIR/$NG_PROMTAIL_BINARY_ARCHIVE
    cp $NG_PROMTAIL_DIR/$NG_PROMTAIL_BINARY /usr/local/bin/$NG_PROMTAIL_BINARY
    echo "Promtail exec file is installed in:" $(which $NG_PROMTAIL_BINARY)
fi

# Service configuration
# touch /etc/systemd/system/promtail.service
sudo cat > /etc/systemd/system/promtail.service << EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$(which $NG_PROMTAIL_BINARY) -config.file $NG_PROMTAIL_DIR/$NG_PROMTAIL_CONFIG_NAME
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
sudo journalctl -u promtail -f -o cat
echo "Things must work well. Please report any misconfigurations in discord"