#!/bin/bash

#################################
# Script by Veco Developers     #
# Update to Veco Core v1.1.0.0  #
# https://veco.info/            #
#################################

LOG_FILE=/tmp/update.log

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

decho "\nStarting Veco 1.1.0.0 Masternode update. This will take a few minutes...\n"

## Check if root user
if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run as \033[1mroot\033[0m user."
	exit 1
fi

## Ask for veco user name
read -e -p "Please enter the user name that runs Veco core |CaSe SeNsItIvE|: " whoami

## Check if veco user exist
getent passwd $whoami > /dev/null 2&>1
if [ $? -ne 0 ]; then
	echo "$whoami user does not exist"
	exit 3
fi

## Stop active core
decho "Stoping active Veco core..."
pkill -f vecod >> $LOG_FILE 2>&1

## Wait to kill properly
sleep 5

## Download and Install new bin
decho "Downloading new core and installing it..."
wget https://github.com/VecoOfficial/Veco/releases/download/v1.1.0.0/vecocore-1.1.0.0-x86_64-linux-gnu.tar.gz >> $LOG_FILE 2>&1
sudo tar xvzf vecocore-1.1.0.0-x86_64-linux-gnu.tar.gz >> $LOG_FILE 2>&1
chmod -R 755 veco
sudo cp veco/vecod /usr/bin/ >> $LOG_FILE 2>&1
sudo cp veco/veco-cli /usr/bin/ >> $LOG_FILE 2>&1
sudo cp veco/veco-tx /usr/bin/ >> $LOG_FILE 2>&1
rm -rf veco >> $LOG_FILE 2>&1

## Backup configuration
decho "Backup configuration file..."

if [ "$whoami" != "root" ]; then
	path=/home/$whoami
else
	path=/root
fi

cd $path

## Relunch core
decho "Relaunching Veco core..."
sudo -H -u $whoami bash -c 'vecod' >> $LOG_FILE 2>&1

## Update sentinel
decho "Updating sentinel..."
cd $path/sentinel
git pull >> $LOG_FILE 2>&1

sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

decho "Update almost completed!"
echo "To start your Masternode please follow the steps below:"
echo "1 - In your VPS terminal, use command 'veco-cli mnsync status' and wait for AssetID: to be 999"
echo "2 - In your wallet, go to the 'Masternodes' tab"
echo "3 - Select the updated Masternode and click 'Start alias'"
echo "4 - In your VPS terminal, use command 'veco-cli masternode status' and you should see your Masternode was successfully started"

su $whoami
