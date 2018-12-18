## Veco Masternode Installation Guide

This is a complete guide to setup a Masternode for Veco Coin.  This method uses a "cold" Windows wallet with a "hot" Ubuntu 16.04 Linux VPS.  The reason for this is so your coins will be safe in your Windows wallet offline and the VPS will host the Masternode but will not hold any coins.

## Requirements

1. Download the latest Veco Windows wallet [**here**](https://github.com/VecoOfficial/Veco/releases)
2. Download and install Bitvise SSH Client [**here**](https://www.bitvise.com/ssh-client-download)
3. Exactly 1000 VECO coins sent to a new receiving address with at least 15 confirmations
4. Ubuntu 16.04 VPS


## Running the Masternode script

- In your wallet, select 'Debug Console' from the Tools menu
- Use command 'masternode genkey' (this is your Masternode Private Key)
- Open Bitvise SSH Client, enter your VPS IP, use port '22' and login with username 'root'
- Use the password provided by the VPS provider to gain access to the server
- Once you are logged in, copy and paste the Masternode installation script below and follow the on-screen instructions 


```bash
wget https://raw.githubusercontent.com/VecoOfficial/masternode-script-veco/master/install.sh && chmod +x install.sh && ./install.sh
```

## Completing the Masternode setup

- In your VPS terminal, use command 'veco-cli mnsync status' and wait for AssetID: to be 999
- In your wallet, select 'Debug Console' from the Tools menu
- In the Debug Console type the command 'masternode outputs' (these outputs will be used in Masternode Configuration File)
- In your wallet, select 'Open Masternode Configuration File' from the Tools menu
- Following the example, enter the required details on a new line (without #) and save the file
- In your wallet, click 'Reload Config' from the 'Masternodes' tab
- Select your Masternode and click 'Start alias'
- In your VPS terminal, use command 'veco-cli masternode status' and you should see your Masternode was successfully started

---

## Update script (from 1.0.0.0 to 1.1.0.0)

To launch the installation, connect to your VPS via SSH and run this command:

```bash
wget https://raw.githubusercontent.com/VecoOfficial/masternode-script-veco/master/update_to_1.1.0.0.sh && chmod +x update_to_1.1.0.0.sh && ./update_to_1.1.0.0.sh
```

Follow the on-screen instructions.

---


## Error Troubleshooting
If for some reason you don’t have Git installed, you can install git with the following command:

```bash
sudo apt-get install git -y
```

If script doesn't start: 
- Check that you have write permission in the current folder
- Check that you can change permission on a file

If you are still facing issues, please get in contact with the Veco Developers on Discord (https://discord.gg/Z7j9mz6)
