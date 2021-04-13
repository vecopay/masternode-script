#!/bin/bash

#################################
# Script by Veco Developers     #
# Update to Veco Core v1.12.2.6 #
# https://veco.to/              #
#################################

LOG_FILE=/tmp/vecoupdate.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

cat <<'FIG'
 .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. |
| | ____   ____  | || |  _________   | || |     ______   | || |     ____     | |
| ||_  _| |_  _| | || | |_   ___  |  | || |   .' ___  |  | || |   .'    `.   | |
| |  \ \   / /   | || |   | |_  \_|  | || |  / .'   \_|  | || |  /  .--.  \  | |
| |   \ \ / /    | || |   |  _|  _   | || |  | |         | || |  | |    | |  | |
| |    \ ' /     | || |  _| |___/ |  | || |  \ `.___.'\  | || |  \  `--'  /  | |
| |     \_/      | || | |_________|  | || |   `._____.'  | || |   `.____.'   | |
| |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------' 
FIG

echo "Starting Veco 1.12.2.6 Masternode update. This will take a few minutes..."

# Check for version
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 16.04 or Ubuntu 18.04?"  >&2; exit 1; }
version=$(lsb_release -rs)
if [[ $version == "16.04" ]]; then
        echo "Ubuntu $version detected, moving foward...";
elif [[ $version == "18.04" ]]; then
        echo "Ubuntu $version detected, moving foward...";
else
        echo "Ubuntu 16.04 or Ubuntu 18.04 is required. Are you using Ubuntu 16.04 or Ubuntu 18.04?"
        exit 1
fi

## Check if root user
if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run as \033[1mroot\033[0m user."
	exit 1
fi

## Ask for veco user name
read -e -p "1) Please enter the user name that runs Veco core |CaSe SeNsItIvE|: " whoami

## Check if veco user exist
getent passwd $whoami > /dev/null 2&>1
if [ $? -ne 0 ]; then
	echo "$whoami user does not exist"
	exit 3
fi

## Stop active core
echo "2) Stoping active Veco core..."
SERVICE="vecod"
if pgrep -x "$SERVICE" >/dev/null; then
        pkill -f vecod >> $LOG_FILE 2>&1
        sleep 20
fi

## Download and Install new bin
echo "3) Downloading new core and installing it..."
cd
if [[ $version == "16.04" ]]; then
        wget https://github.com/VecoOfficial/Veco/releases/download/v1.12.2.6/vecocore-1.12.2.6-ubuntu16.tar.gz >> $LOG_FILE 2>&1
        tar xvzf vecocore-1.12.2.6-ubuntu16.tar.gz >> $LOG_FILE 2>&1
        rm -rf vecocore-1.12.2.6-ubuntu16.tar.gz >> $LOG_FILE 2>&1
elif [[ $version == "18.04" ]]; then
        wget https://github.com/VecoOfficial/Veco/releases/download/v1.12.2.6/vecocore-1.12.2.6-ubuntu18.tar.gz >> $LOG_FILE 2>&1
        tar xvzf vecocore-1.12.2.6-ubuntu18.tar.gz >> $LOG_FILE 2>&1
        rm -rf vecocore-1.12.2.6-ubuntu18.tar.gz >> $LOG_FILE 2>&1
else
#Ubuntu 20.04
        exit 1
fi

chmod -R 755 vecocore-1.12.2.6
sudo cp vecocore-1.12.2.6/bin/vecod /usr/bin/ >> $LOG_FILE 2>&1
sudo cp vecocore-1.12.2.6/bin/veco-cli /usr/bin/ >> $LOG_FILE 2>&1
sudo cp vecocore-1.12.2.6/bin/veco-tx /usr/bin/ >> $LOG_FILE 2>&1
rm -rf vecocore-1.12.2.6 >> $LOG_FILE 2>&1

## Backup configuration

if [ "$whoami" != "root" ]; then
	path=/home/$whoami
else
	path=/root
fi

cd $path

## Relunch core
echo "4) Relaunching Veco core..."
chown -R $whoami:$whoami /home/$whoami/.vecocore
sudo -H -u $whoami bash -c 'vecod' >> $LOG_FILE 2>&1

## Update sentinel
echo "5) Updating sentinel..."
rm -rf /home/$whoami/sentinel >> $LOG_FILE 2>&1
git clone https://github.com/VecoOfficial/sentinel.git /home/$whoami/sentinel >> $LOG_FILE 2>&1
chown -R $whoami:$whoami /home/$whoami/sentinel >> $LOG_FILE 2>&1
cd /home/$whoami/sentinel
sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

decho "Update almost completed!"
echo "To start your Masternode please follow the steps below:"
echo "1 - In your VPS terminal, use command 'veco-cli mnsync status' and wait for AssetID: to be 999"
echo "2 - In your wallet, go to the 'Masternodes' tab"
echo "3 - Select the updated Masternode and click 'Start alias'"
echo "4 - In your VPS terminal, use command 'veco-cli masternode status' and you should see your Masternode was successfully started"

su $whoami
