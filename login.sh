#!/bin/bash

trap "{ echo 'Terminate'; ./stop_flash.sh; exit 1; }" SIGINT SIGTERM

cd /root/tuya-convert/
./start_flash.sh
function menu1 (){
while true; do
  echo -e "\n\n\n\nHere are you options for flashing your device\n\n" \
    "    1) BACKUP only and UNDO\n" \
    "    2) FLASH loader to user2\n" \
    "    3) FLASH third-party firmware\n"
  read -n 1 -p "Which flash mechanism would you like? " RESPONSE
  if [[ "$RESPONSE" =~ ^[0-9]+$ ]] && [ $RESPONSE -ge 1 -a $RESPONSE -le 2 ]; then
    echo -e "\n\nYou selected $RESPONSE"
    break
  elif [[ "$RESPONSE" =~ ^[0-9]+$ ]] && [ $RESPONSE -eq 3 ]; then
    menu2
    break
  fi
done
}
function menu2 () {
  while true; do
    mapfile -t FILES < <(find /root/tuya-convert/files/ -type f -exec basename {} \;)
    mapfile -t LINKS < <(find /root/tuya-convert/files/ -type l -exec readlink {} \;)
    for link in "${LINKS[@]}"; do
      for i in "${!FILES[@]}"; do
        if [[ ${FILES[i]} = "$link" ]]; then
          unset 'FILES[i]'
        fi
      done
    done
    FILES=("${FILES[@]}")
    echo -e "\n\nHere is the list of third-party firmwares\n\n" \
      "    1) Sonoff-tasmota"
    for file in "${!FILES[@]}"; do
      echo -e "     $((file+2))) ${FILES[$file]}"
    done
    echo -e "\n     b) Go back to previous menu\n"
    if [ ${#FILES[@]} -le 8 ]; then
      CHAR=1
    else
      CHAR=2
    fi
    read -e -n $CHAR -p "Which third-party firmware would you like to use? " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ $CHOICE -eq 1 ]; then
      echo -e "\n\nYou selected $CHOICE"
      break
    elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ $CHOICE -le $((${#FILES[@]}+1)) -a $CHOICE -gt 0 ]; then
      FIRMWARE=${FILES[$CHOICE-2]}
      RESPONSE=4
      break
    elif [[ "$CHOICE" == "b" ]]; then
      menu1
      break
    fi
  done
}
menu1
case $RESPONSE in
  1)
    curl -m 2 http://10.42.42.42/undo
    ;;
  2)
    curl -m 2 http://10.42.42.42/flash2
    ;;
  3)
    curl -m 2 http://10.42.42.42/flash3
    ;;
  4)
    echo -e "\nUsing $FIRMWARE firmware..."
    curl -m 2 http://10.42.42.42/flashURL?url=http://10.42.42.1/files/$FIRMWARE
    ;;
esac
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo -e "\nWARNING: An error occured when trying to flash device. Dropping to shell...\n"
  /bin/bash
  exit 1
fi
if [ $RESPONSE -eq 1 ]; then
  SLEEP=2
else
  SLEEP=75
fi
echo -e "\n\nWaiting for flash to complete.\nSleeping for $SLEEP seconds...\n"
sleep $SLEEP
./stop_flash.sh
