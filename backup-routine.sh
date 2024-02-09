#!/usr/bin/env bash

SSH=$1
DOCKER_SERVER="$(sudo docker ps | grep "minecraft" | awk '{print $1}')"

# Print message to server that backup is starting
sudo docker exec "$DOCKER_SERVER" rcon-cli 'tellraw @a [{"text":"[","color":"white"},{"text":"Server","color":"gold"},{"text":"] ","color":"white"},{"text":"Backup started","color":"green"}]'
# Disable saving to prevent world corruption
sudo docker exec "$DOCKER_SERVER" rcon-cli save-off

# Make sure the backups directory exists
ssh "$SSH" "mkdir -p ./backups"

# Remove oldest backup if there are more than 10
if [ "$(ssh "$SSH" 'ls -1 ./backups | wc -l')" -ge 10 ]; then
  # Print message to server that oldest backup is being removed
  sudo docker exec "$DOCKER_SERVER" rcon-cli 'tellraw @a [{"text":"[","color":"white"},{"text":"Server","color":"gold"},{"text":"] ","color":"white"},{"text":"Removing oldest backup","color":"yellow"}]'
  # Remove oldest backup
  OLD_BACKUP=$(ssh "$SSH" 'ls -t1 ./backups | tail -n 1')
  ssh "$SSH" rm "./backups/$OLD_BACKUP"
fi

# Create backup name with current date and time e.g. backup-2020-01-01_12-00-00
BACKUP_NAME="backup-$(date +%Y-%m-%d_%H-%M-%S)"

# Use rsync to copy the server data to the backup directory on the host
rsync -avz -e ssh -i /home/ubuntu/.ssh/id_rsa ./minecraft-data/ "$SSH:backups/$BACKUP_NAME"

# Zip the backup and remove the original folder

ssh "$SSH" "cd backups && tar -czf $BACKUP_NAME.tar.gz $BACKUP_NAME && rm -rf $BACKUP_NAME"

# Enable saving again to allow the server to save properly
sudo docker exec "$DOCKER_SERVER" rcon-cli save-on

# Print message to server that backup is finished
sudo docker exec "$DOCKER_SERVER" rcon-cli 'tellraw @a [{"text":"[","color":"white"},{"text":"Server","color":"gold"},{"text":"] ","color":"white"},{"text":"Backup finished","color":"green"}]'
