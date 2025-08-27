
# Minecraft Bedrock Server Installer and Auto Updater

## Installation & Usage

### 1. Install the Minecraft Bedrock Server

Run the install script as root (or with sudo):

```sh
sudo ./install.sh
```

This will:
- Create a dedicated `minecraft` user
- Install all scripts in `/opt/minecraft-bedrock-server`
- Set up the systemd service
- Schedule weekly updates via cron

### 2. Fresh Install of the Server

To perform a fresh install (or update to the latest version):

```sh
sudo ./install_minecraft.sh
```

This will run the update script and install the latest Minecraft Bedrock server files.

### 3. Starting and Stopping the Server

Start the server:
```sh
sudo systemctl start minecraft
```

Stop the server:
```sh
sudo systemctl stop minecraft
```

Check server status:
```sh
sudo systemctl status minecraft
```


### 4. Automatic Updates

The server will automatically update every Monday at 3am via cron, using the `update_bedrock.sh` script.


All scripts and the server run as the dedicated `minecraft` user for improved security.