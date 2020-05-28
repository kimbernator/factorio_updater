#!/bin/bash

factorio_loc="/opt/factorio-init/factorio"

old_ver=$($factorio_loc version)

new_ver=$(curl -s "https://www.factorio.com/get-download/latest/headless/linux64" | grep 'factorio_headless_x64')

if [[ $new_ver == *"${old_ver}"* ]]
then
  echo "Already on current version"
  exit 0
else
  echo "New version found!"
fi

if [[ -f /opt/factorio_$old_ver ]]; then
  echo "folder for current version already exists at /opt/factorio_$old_ver"
  exit 1
fi

players_online=$($factorio_loc players-online)
if [[ $players_online ]]; then
  notif_cmd='Server will be stopped to upgrade version in 30 seconds'
  echo "Players online: ${players_online}"
  echo "Sending 30 second warning"
  echo "<server>: ${notif_cmd}"
  $factorio_loc cmd $notif_cmd
  sleep 30
fi

save_name="upgrade_from_${old_ver}"
echo "Saving game as ${save_name}"
$factorio_loc save-game $save_name

old_folder="/opt/factorio_${old_ver}"
echo "Backing current installation up to ${old_folder}"
mv /opt/factorio $old_folder

echo "Installing new version"
$factorio_loc install > /dev/null 2>&1
RC=$?
if [[ $RC -eq 0 ]]
then
  echo "Success!"
else
  echo "FAILED TO INSTALL"
  exit 1
fi

echo "Restoring save file"
cp $old_folder/saves/${save_name}.zip /opt/factorio/saves/

echo "Restoring json files"
cp $old_folder/data/*.json /opt/factorio/data

echo "Configuring ownership for factorio user"
chown -R factorio:factorio /opt

echo "Loading save: ${save_name}"
$factorio_loc load-save $save_name

echo "Starting server"
$factorio_loc start
