#!/bin/bash

#############################
# Script by Veco Developers #
# Veco Core v1.12.2.6       #
# https://veco.to/          #
#############################

LOG_FILE=/tmp/vecoinstall.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  exit "${code}"
}
trap 'error ${LINENO}' ERR

clear

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

# Check for systemd
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Check if executed as root user
if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run as \033[1mroot\033[0m user."
	exit 1
fi

# Print variable on a screen
decho "Please make sure you double check information before hitting enter!"

read -e -p "Please enter username that will run Veco Core |CaSe SeNsItIvE|: " whoami
if [[ "$whoami" == "" ]]; then
	decho "WARNING: No user entered, exiting!!!"
	exit 3
fi
if [[ "$whoami" == "root" ]]; then
	decho "WARNING: User root entered? It is recommended to use a non-root user, exiting!!!"
	exit 3
fi
read -e -p "Server IP Address: " ip
if [[ "$ip" == "" ]]; then
	decho "WARNING: No IP entered, exiting!!!"
	exit 3
fi
read -e -p "Please enter Masternode Private Key (e.g. 3YZEsru3J3kiy9itrLW1EzBt8RsF23s24co82rswUPrPgpJ6r6o # THE KEY YOU GENERATED IN YOUR WALLET EARLIER): " key
if [[ "$key" == "" ]]; then
	decho "WARNING: No Masternode private key entered, exiting!!!"
	exit 3
fi
read -e -p "(Optional) Install Fail2ban? (Recommended) [Y/n]: " install_fail2ban

# Update package and upgrade Ubuntu
decho "Updating system and installing required packages..."

apt-get -y update >> $LOG_FILE 2>&1

# Install required packages
decho "Installing base packages and dependencies..."

apt-get -y install sudo >> $LOG_FILE 2>&1
apt-get -y install wget >> $LOG_FILE 2>&1
apt-get -y install git >> $LOG_FILE 2>&1
apt-get -y install unzip >> $LOG_FILE 2>&1
apt-get -y install virtualenv >> $LOG_FILE 2>&1
apt-get -y install python-virtualenv >> $LOG_FILE 2>&1
apt-get -y install pwgen >> $LOG_FILE 2>&1
apt-get -y install mc >> $LOG_FILE 2>&1

# Install daemon packages
decho "Installing daemon packages and dependencies..."

apt-get -y install software-properties-common libzmq3-dev pwgen >> $LOG_FILE 2>&1
apt-get -y install git libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libboost-all-dev unzip libminiupnpc-dev python-virtualenv >> $LOG_FILE 2>&1
apt-get -y install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils >> $LOG_FILE 2>&1

# Add Berkely PPA
decho "Installing bitcoin PPA..."

apt-add-repository -y ppa:bitcoin/bitcoin >> $LOG_FILE 2>&1
apt-get -y update >> $LOG_FILE 2>&1
apt-get -y install libdb4.8-dev libdb4.8++-dev >> $LOG_FILE 2>&1


if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
	decho "Optional install: Fail2ban"
	cd ~
	apt-get -y install fail2ban >> $LOG_FILE 2>&1
	systemctl enable fail2ban >> $LOG_FILE 2>&1
	systemctl start fail2ban >> $LOG_FILE 2>&1
fi

decho "Create user $whoami (if necessary)"

# Deactivate trap only for this command
trap '' ERR
getent passwd $whoami > /dev/null 2&>1

if [ $? -ne 0 ]; then
	trap 'error ${LINENO}' ERR
	adduser --disabled-password --gecos "" $whoami >> $LOG_FILE 2>&1
else
	trap 'error ${LINENO}' ERR
fi

# Create veco.conf
decho "Setting up Veco Core..."

# Generate random passwords
user=`pwgen -s 16 1`
password=`pwgen -s 64 1`

echo 'Downloading bootstrap and creating veco.conf...'
wget https://github.com/VecoOfficial/Veco/releases/download/v1.12.2.6/bootstrap.tar.gz>> $LOG_FILE 2>&1
tar xvzf bootstrap.tar.gz -C /home/$whoami>> $LOG_FILE 2>&1
rm -rf bootstrap.tar.gz >> $LOG_FILE 2>&1
cat << EOF > /home/$whoami/.vecocore/veco.conf
rpcuser=$user
rpcpassword=$password
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
maxconnections=8
masternode=1
masternodeprivkey=$key
externalip=$ip
EOF
chown -R $whoami:$whoami /home/$whoami/.vecocore

# Install Veco Daemon
echo 'Downloading daemon...'
cd
wget https://github.com/VecoOfficial/Veco/releases/download/v1.12.2.6/vecocore-1.12.2.6-ubuntu18.tar.gz >> $LOG_FILE 2>&1
tar xvzf vecocore-1.12.2.6-ubuntu18.tar.gz >> $LOG_FILE 2>&1
chmod -R 755 vecocore-1.12.2.6

## Stop active core
echo 'Looking for active daemon...'
SERVICE="vecod"
if pgrep -x "$SERVICE" >/dev/null
then
echo "Stoping active Veco daemon..."
pkill -f vecod >> $LOG_FILE 2>&1
## Wait to kill properly
sleep 30
else
echo "No active daemon found"
fi

cp vecocore-1.12.2.6/bin/vecod /usr/bin/ >> $LOG_FILE 2>&1
cp vecocore-1.12.2.6/bin/veco-cli /usr/bin/ >> $LOG_FILE 2>&1
cp vecocore-1.12.2.6/bin/veco-tx /usr/bin/ >> $LOG_FILE 2>&1
rm -rf vecocore-1.12.2.6 >> $LOG_FILE 2>&1

# Run vecod as selected user
chown -R $whoami:$whoami /home/$whoami/.vecocore
sudo -H -u $whoami bash -c 'vecod' >> $LOG_FILE 2>&1

echo 'Veco Core prepared and launched...'

sleep 10

# Setting up sentinel
decho "Setting up sentinel..."

# Install sentinel
echo 'Downloading sentinel...'
rm -rf /home/$whoami/sentinel >> $LOG_FILE 2>&1
git clone https://github.com/VecoOfficial/sentinel.git /home/$whoami/sentinel >> $LOG_FILE 2>&1
chown -R $whoami:$whoami /home/$whoami/sentinel >> $LOG_FILE 2>&1

echo 'Setting up sentinel...'
cd /home/$whoami/sentinel
sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

# Deploy script to keep daemon alive
cat << EOF > /home/$whoami/vecodkeepalive.sh
until vecod; do
    echo "Vecod crashed with error $?.  Restarting.." >&2
    sleep 1
done
EOF

chmod +x /home/$whoami/vecodkeepalive.sh
chown $whoami:$whoami /home/$whoami/vecodkeepalive.sh

# Setup crontab
echo "@reboot sleep 30 && /home/$whoami/vecodkeepalive.sh" >> newCrontab
echo "* * * * * cd /home/$whoami/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> newCrontab
crontab -u $whoami newCrontab >> $LOG_FILE 2>&1
rm newCrontab >> $LOG_FILE 2>&1

# Final Masternode instructions
decho "Starting your Masternode"
echo ""
echo "To start your Masternode please follow the steps below:"
echo "1 - In your VPS terminal, use command 'veco-cli mnsync status' and wait for AssetID: to be 999"
echo "2 - In your wallet, select 'Debug Console' from the Tools menu"
echo "3 - In the Debug Console type the command 'masternode outputs' (these outputs will be used in Masternode Configuration File)"
echo "4 - In your wallet, select 'Open Masternode Configuration File' from the Tools menu"
echo "5 - Following the example, enter the required details on a new line (without #) and save the file"
echo "6 - In your wallet, click 'Reload Config' from the 'Masternodes' tab"
echo "7 - Select your Masternode and click 'Start alias'"
echo "8 - In your VPS terminal, use command 'veco-cli masternode status' and you should see your Masternode was successfully started"
echo ""
decho "If you have any issues, please get in contact with the Veco Developers on Discord (https://discord.gg/Z7j9mz6)"


su $whoami
