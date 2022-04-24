# Veco Masternode Installation Guide

This guide will teach you how to setup a Veco Masternode on a remote server (VPS). You should have at least a basic knowledge of linux. For better clarity, all commands that must be typed shall be displayed as such:
```bash
this is a command
```
Type the command exactly (you may copy&paste it). There will always be some space between commands so that you can easily see commands spanning over several lines. Some commands may also be appended together with **&&** to speed up the process when commands are short or trivial. You may execute these commands as one, or you may type each one separately.

If you need any additional help, feel free to join [our discord](https://discord.com/invite/Z7j9mz6) and ask for help in the _#masternode_ channel.

**BEWARE scammers trying to impersonate team members! Do not accept help from people directly contacting you. No one from Veco team will contact you and “help” proactively!**

## What you’ll need

1. **A local computer** – your everyday computer, which will run a control wallet and hold your coins. This computer need not always be online.

2. **A remote server** – typically a VPS, with Ubuntu Server 16.04, 18.04 or 20.04 64-bit OS installed with a unique and static IP address (an IP address that does not change), which is always running and connected to the Internet. This VPS should at least have 1Gb of RAM and 10Gb of space storage.

3. **A collateral** – an amount in Veco that will be unspendable as long as you wish to keep your node running. For a masternode you’ll need 10,000 VECO. You’ll need some change for transaction fees, so 1 VECO more to cover expenses is good enough.

## Setting up a Control wallet

### Step 1 – Set up a wallet

This involves downloading and synchronizing the [wallet](https://github.com/VecoOfficial/Veco/releases). Please use [bootstrap](https://github.com/VecoOfficial/Veco/releases/download/v1.13.4/bootstrap.zip) to speed up the process.

### Step 2 – Create collateral

As mentioned above, you will need some Veco to create what is called collateral: a certain amount of Veco that will be “frozen” in order for your masternode to keep running.

You will first need to get the amount of Veco for the collateral, as well as a small amount to pay the transactions fees. You may purchase some Veco on exchanges [CREX24](https://crex24.com/exchange/VECO-BTC) or [FINEXBOX](https://www.finexbox.com/market/pair/VECO-BTC.html). You will need:

- 10,000 VECO (+1 VECO) for a masternode

Once you have this amount in your control wallet, you need to set it as official collateral. This is done by creating a receiving address in your wallet, and sending the exact amount – 10,000 VECO – to it. Making a payment to yourself requires a fee. This is why you needed that extra VECO.

After making that payment, you will need to retrieve some information about it: the Transfer ID and Index.

This information can be found using the Debug Console. Go to Tools > Debug Console. Type the following command:
```bash
masternode outputs
```
this will yield something like this:

{  
"efa598dd5df8fdff8777b1bf36066bbda34426a2bba33c702867d67e64070707": "1"  
}

The first part is the transfer ID, and the last (the digit) is the index.

### Step 3 – Create private key and BLS key

A private key is used to identify your masternode in your control wallet. You can create this key using the console again and typing the following command:
```bash
masternode genkey
```
This key will work for masternode.

The BLS key is needed to prepare for the new DIP3 deterministic masternodes. You may read more about deterministic masternodes [here](https://blog.dash.org/introducing-deterministic-masternode-lists-daaa7c9bef34).
```bash
bls generate
```
The command yields a secret key and a public key. You will need to keep both parts for future use. The secret key will be inserted in the veco.conf file of the masternode and the public key will be needed to activate the masternode on the blockchain once the DIP3 protocol is activated.

## Setting up a VPS

The following procedure assumes an installation from scratch. If you have an existing VPS already installed, then some steps might not be needed. **BEWARE: securing your server is still your responsibility!**

### Step 1 – Acquire a VPS from any provider

The cheapest one will do, provided you create a swap file (see below).
When asked, choose the Ubuntu 16.04, 18.04 (recomened) or 20.04 LTS Linux distribution.

### Step 2 – Log into your VPS and install updates and packages

In order to access your VPS, you will need a software/SSH client such as [PuTTY](https://www.putty.org/). This tutorial does not cover installation of, know-how to use such software.

Once you have access to your VPS, create a user that will be running your masternode (for security reasons, it is always better not to run any application as root user):
```bash
adduser veco && adduser veco sudo
```
This creates user **veco** with root privileges (be able to run root commands using the “sudo” prefix).

Switch to **veco** user
```bash
su veco
cd ~
```
A clean server install will likely need some software updates. Enter the following command which will bring the system up to date (can take a few minutes to complete):
```bash
sudo apt-get update && sudo apt-get upgrade -y
```
Reboot your VPS for changes to take effect:
```bash
sudo reboot
```
After rebooting, switch to **veco** user again:
```bash
su veco
cd ~
```
Install the following packages and libraries (some libraries are not necessary if you don’t compile sources but it’s still a good idea to do it so you got them installed anyways):

#### Ubuntu 16.04 and 18.04

```bash
sudo add-apt-repository ppa:bitcoin/bitcoin
```
You will be asked to confirm installation of the bitcoin library. Simply hit **enter**.

Now install the dependencies:
```bash
sudo apt update -y && sudo apt upgrade -y && sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git libdb4.8-dev libdb4.8++-dev curl && sudo apt install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libzmq3-dev python-virtualenv unzip htop
```

#### Ubuntu 20.04

Install the dependencies:
```bash
sudo apt update -y && sudo apt upgrade -y && sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git libdb-dev libdb++-dev curl && sudo apt install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libzmq3-dev python-virtualenv unzip htop
```

### Step 3 – Set up a Swap File (optional)

This will be needed especially if using a low end VPS and you wish to compile the source code. Some providers already install a swap on their VPS. You can check this by doing:
```bash
htop
```
This provides you with a nice view of your VPS resources. In the higher left part, check if **Swp** has any value higher than **0K**. If so, you are good to go to Step 4. If not, continue below.

The following command sets up a 2GB swap file. You may change this size by modifying the **2G** to anything you like (we still recommend at least **2G**). Leave all other commands unchanged.
```bash
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && sudo cp /etc/fstab /etc/fstab.bak && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
[More information about swap files](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-18-04)

### Step 4 – Install masternode binaries and configuration

Get the latest binaries [from github](https://github.com/VecoOfficial/Veco/releases). At the time of writing, latest version is **v1.13.4**. You should check on github and adapt the following commands with **latest binaries** and **Ubuntu version** reference.

Example for **v1.13.4** and **Ubuntu 18.04** VPS:
```bash
wget https://github.com/VecoOfficial/Veco/releases/download/v1.13.4/vecocore-1.13.4-x86_64-ubuntu18-gnu.tar.gz
```
```bash
tar zxvf vecocore-1.13.4-x86_64-ubuntu18-gnu.tar.gz

sudo mv vecocore-1.13.4/bin/veco{d,-cli,-tx} /usr/local/bin/

rm -r vecocore-1.13.4
```
Before the node can operate as a masternode, a custom configuration file needs to be created. Since we have not loaded the blockchain yet, we will create the necessary directory and configuration file
```bash
mkdir .vecocore && cd .vecocore
```
Get the following values for your configuration file:

-   **USER** – an alphanumerical string
-   **PASSWORD** – an alphanumerical string, not the same as user
-   **VPS IP** – the IP of your VPS (looks something like: 192.168.2.1)
-   **PRIVATE KEY** – the one you created earlier in your control wallet’s Debug Console
-   **BLS SECRET KEY** – the one you created earlier in your control wallet’s Debug Console

Create _veco.conf_ file
```bash
nano veco.conf
```
then copy&paste the following in it, inserting the proper values:
```bash
rpcuser=USER
rpcpassword=PASSWORD
listen=1
server=1
daemon=1
maxconnections=8
masternode=1
externalip=VPS IP
rpcallowip=127.0.0.1
rpcport=26920
masternodeprivkey=PRIVATE KEY
masternodeblsprivkey=BLS SECRET KEY
```

Save the file (**ctrl-x**, then type **y** and hit **enter**)

### Step 5 – Start the daemon

Now that you have everything set up, it’s time to start the daemon. To speed up the synchronization of the blockchain, you may download a booststrap file and put it in the .vecocore directory you created earlier, the one where your veco.conf file was created (this is not mandatory):
```bash
wget https://github.com/VecoOfficial/Veco/releases/download/v1.13.4/bootstrap.zip && unzip bootstrap.zip
```
And finally launch the masternode daemon:
```bash
vecod
```
Wait about 30 minutes for your masternode to sync completely.

You may monitor the sync progress using the following command:
```bash
watch veco-cli getinfo
```
which should yield the following information:

{  
"version": 1130400,  
"protocolversion": 70211,  
"walletversion": 61000,  
"balance": 0.00000000,  
"privatesend_balance": 0.00000000,  
"blocks": **total number of blocks**,  
"timeoffset": 0,  
"connections": 8,  
"proxy": "",  
"difficulty": 0.000471432058882026,  
"testnet": false,  
"keypoololdest": 1650834178,  
"keypoolsize": 999,  
"paytxfee": 0.00000000,  
"relayfee": 0.00001000,  
"errors": ""  
}

Here, “watch”-ing lets you see the synchronization (you can exit the watch at any time with **ctrl-c**). The blocks number will go up until your masternode reaches the total number of blocks in the blockchain.

This is the longest part. You can see what number it needs to reach by hovering over the small **V** in the lower right of your control wallet or by checking [Veco Block Explorer](explorer.veco.to).

**BEWARE: the blocks number might not start growing for a while. This is because the daemon could be looking for a valid connections or synchronizing headers. As long as you have connections higher than zero you are fine.**

You may verify that it is synced using the command:
```bash
watch veco-cli mnsync status
```
which should yield the following information:

{  
"AssetID": **999**,  
"AssetName": "MASTERNODE_SYNC_FINISHED",  
"AssetStartTime": 1650834730,  
"Attempt": 0,  
"IsBlockchainSynced": true,  
"IsMasternodeListSynced": true,  
"IsWinnersListSynced": true,  
"IsSynced": true,  
"IsFailed": false  
}

The masternode is completely synced when AssetID is **999** (it will go through 0, 1, 2, 3, 4 and 999).
You can exit the watch at any time with **ctrl-c**.
Once your masternode is synced, you may delete the bootstrap file:
```bash
rm bootstrap.zip
```
### Step 6 – Installing sentinel

Sentinel is not strictly needed for payouts, but if you want to monitor your masternode easily from your wallet, you will have to install it.

#### A – Download source code

The following commands will suppose that sentinel is installed in the home directory of veco user.
```bash
cd ~ && git clone https://github.com/VecoOfficial/sentinel.git
```

#### B – Compile and run code

The following commands will compile the code and create necessary files and folders.
```bash
cd sentinel && virtualenv ./venv && ./venv/bin/pip install -r requirements.txt
```

#### C – Create crontab entry

Sentinel needs to be executed regularly to monitor your masternode accurately. This is done by entering a command in your veco user cron daemon.

To find the path to Sentinel, run the following command:
```bash
pwd
```
Edit your crontab:
```bash
crontab -e
```
Add the following line (edit **/path/to/sentinel** with your path):
```bash
* * * * * cd /path/to/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1
```
And save the file (**ctrl-x**, then type **y** and hit **enter**)

### Step 7 – Starting the masternode

Your masternode is now synchronized and chatting with the network but is not accepted as a masternode because it hasn’t been introduced to the network with your collateral. This is done with the control wallet.

#### A – Activate masternodes tab

If the masternodes tab is not available (should be available by default) in your control wallet, you need to activate it. Go to Settings > Options, then Wallet tab and check the Show Masternodes Tab box.

#### B – Edit masternode.conf file

This file is used to link your control wallet to your masternode. You can access it by going to Tools > Open Masternode Configuration File. You must add the following line:

**name** **ip:26919** **private key** **collateral txid** **collateral index**

Where:

-   **name** is any name you wish to give your masternode. For example “MN-01”
-   **ip:26919** IP is the static IP address of your VPS. 26919 is the port
-   **private key** is the key you generated with the **masternode genkey** command
-   **collateral txid** is the first part of what you got when typing the **masternode outputs** command
-   **collateral index** is the second part (the digit, almost always “1”) of what you got when typing the **masternode outputs** command

For example (should be typed as one line):

MN-01 192.168.2.1:26919 3XAuT7wG2KKuKAZ8bkfV7ExfJ8e7bWeXKXonsR6cWFpvnbmzk39 efa598dd5df8fdff8777b1bf36066bbda34426a2bba33c702867d67e64070707 1

Once you have typed this line, save the file and **restart your control wallet**.

#### C – Start masternode

At last, we arrive to the final step needed to complete the installation. **BEWARE: for this final step, your collateral transaction needs at least 15 confirmations!**

Go to the **My Masternodes** tab. You should see your masternode information, and a MISSING status. Click on the **Start MISSING** button. Your masternode will go to PRE_ENABLED status, then ENABLED. Once enabled, all is done.

Again, don’t forget: your collateral must have 15 confirmations before you can use it to enable a masternode.

You may check the status on your VPS with the following command (as veco user):
```bash
veco-cli masternode status
```
which should yield the following information:

{  
"outpoint": "**your masternode output**",  
"service": "**your ip**:26919",  
"payee": "**your collateral address**",  
"status": "Masternode successfully started"  
}

If you see **"status": "Not capable masternode: Masternode not in masternode list"**, please go to **control wallet**, choose your masternode from the **My Masternodes** tab, and click on **Start alias**.
