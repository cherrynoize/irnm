#!/bin/bash
####--------************--------####    
#              irnm                #
#      ----************----        -
#  improved rofi network manager   #
####--------************--------####    
#
# Author: cherrynoize
# https://github.com/cherrynoize/irnm
#
# Originally based on rofi-network-manager
# by P3rf (https://gitlab.com/P3rf/rofi-network-manager)
#

# Default values
LOCATION=0
QRCODE_LOCATION=$LOCATION
Y_AXIS=0
X_AXIS=0
QRCODE_DIR="/tmp/"
WIDTH_FIX_MAIN=1
WIDTH_FIX_STATUS=10
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSWORD_ENTER="if connection is stored,hit enter/esc."

# Wireless interfaces
WIRELESS_INTERFACES=("$(nmcli device | awk '$2=="wifi" {print $1}')")
WIRELESS_INTERFACES_PRODUCT=()
WLAN_INT=0

# Wired interfaces
WIRED_INTERFACES=("$(nmcli device | awk '$2=="ethernet" {print $1}')")
WIRED_INTERFACES_PRODUCT=()

# Signal settings
CHANGE_BARS=false
SIGNAL_STRENGTH_0="0"
SIGNAL_STRENGTH_1="1"
SIGNAL_STRENGTH_2="12"
SIGNAL_STRENGTH_3="123"
SIGNAL_STRENGTH_4="1234"

# Loading notification id
nid="7777"

# Menu options
opt_disc="Disconnect"
opt_scan="Scan"
opt_status="Status"
opt_pwd="Share Wifi Password"
opt_add="Add network (manual/hidden)"
opt_manual="Manual"
opt_hidden="Hidden"
opt_wifi_on="Wi-Fi On"
opt_wifi_off="Wi-Fi Off"
opt_eth_on="Eth On"
opt_eth_off="Eth Off"
opt_eth_conn="Eth Connecting"
opt_eth_na="Eth Unavailable"
opt_wifi_ix="Change Wifi Interface"
opt_restart="Restart Network"
opt_qr="QrCode"
opt_more="More Options"
opt_editor="Open Connection Editor"
opt_vpn="VPN"

option_prefix=" "
option_suffix=""

# Title for notifications
title="irnm"

function add_option () {
  while [ -n "$1" ]; do
    OPTIONS+="$option_prefix$1$option_suffix\n"
    shift
  done
}

function strip_option () {
  sed -e 's/^'"$option_prefix"'//' -e 's/'"$option_suffix"'$//' <<< "$1"
}

function config () {
  source_config () {
    [ -f "$1" ] && . "$1"
  }

  source_config "$DIR/network-manager.conf" || source_config "${XDG_CONFIG_HOME:-$HOME/.config}/rofi/network-manager/network-manager.conf"
  
  if [ -f "$DIR/network-manager.rasi" ]; then
    RASI_DIR="$DIR/network-manager.rasi"
  elif [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/rofi/network-manager.rasi" ]; then
    RASI_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/network-manager.rasi"
  else
    exit
  fi
}

function initialize() {
  for i in "${WIRELESS_INTERFACES[@]}"; do
    WIRELESS_INTERFACES_PRODUCT+=("$(nmcli -f general.product device show "$i" | awk '{print $2}')")
  done
  
  for i in "${WIRED_INTERFACES[@]}"; do
    WIRED_INTERFACES_PRODUCT+=("$(nmcli -f general.product device show "$i" | awk '{print $2}')")
  done

  wireless_interface_state
  ethernet_interface_state
}

function notification () {
  if [ "$NOTIFICATIONS" = "on" ]; then
    dunstify -u "${3:-normal}" -r "$nid" "$1" "$2"
  fi
}

function wireless_interface_state() {
  if [ ! "${#WIRELESS_INTERFACES[@]}" = "0" ]; then
    ACTIVE_SSID="$(nmcli device status | grep "^${WIRELESS_INTERFACES[WLAN_INT]}." | awk '{print $4;}')"
    WIFI_CON_STATE="$(nmcli device status | grep "^${WIRELESS_INTERFACES[WLAN_INT]}." | awk '{print $3;}')"

    if [ "$WIFI_CON_STATE" = "unavailable" ]; then
      add_option "Wi-Fi Disabled" "$opt_wifi_on" "$opt_scan"
    elif [ "$WIFI_CON_STATE" = "connected" ]; then
      PROMPT=${WIRELESS_INTERFACES_PRODUCT[WLAN_INT]}[${WIRELESS_INTERFACES[WLAN_INT]}]
      WIFI_LIST=$(nmcli --fields SSID,SECURITY,BARS device wifi list ifname "${WIRELESS_INTERFACES[WLAN_INT]}")
      wifi_list

      OPTIONS="$WIFI_LIST\n"

      if [ "$ACTIVE_SSID" = "--" ]; then
        add_option "$opt_scan" "$opt_add" "$opt_wifi_off"
      else
        add_option "$opt_scan" "$opt_disc" "$opt_add" "$opt_wifi_off"
      fi
    fi
  fi
}

function ethernet_interface_state() {
  if [ ! "${#WIRED_INTERFACES[@]}" = "0" ]; then
    case "$WIRED_CON_STATE" in
      "disconnected")
        add_option "$opt_eth_on"
        ;;
      "connected")
        add_option "$opt_eth_off"
        ;;
      "connecting")
        add_option "$opt_eth_conn"
        ;;
      "unavailable"|*)
        add_option "$opt_eth_na"
        ;;
    esac
  fi
}

function rofi_menu() {
  if [ "${#WIRELESS_INTERFACES[@]}" -gt "1" ]; then
    add_option "$opt_wifi_ix"
  fi
  add_option "$opt_more"

  if [ "$WIRED_CON_STATE" = "connected" ]; then
    PROMPT="${WIRELESS_INTERFACES_PRODUCT}[$WIRED_INTERFACES]"
  else
    PROMPT="${WIRELESS_INTERFACES_PRODUCT[WLAN_INT]}[${WIRELESS_INTERFACES[WLAN_INT]}]"
  fi

  choice=$(echo -e "$OPTIONS" | rofi_cmd "$OPTIONS" $WIDTH_FIX_MAIN "-a 0")
  SSID=$(echo "$choice" | sed "s/\s\{2,\}/\|/g" | awk -F "|" '{ print $1; }')
  menu
}

function rofi_cmd() {
  if [ -n "$1" ]; then
    WIDTH="$(echo -e "$1" | awk '{ print length; }' | sort -n | tail -1)"
  fi
  (( WIDTH += $2 ))
  (( WIDTH /= 2 ))

  rofi -config "$HOME/.config/rofi/network-manager/network-manager.rasi"\
       -dmenu -i -location "$LOCATION" -yoffset "$Y_AXIS" -xoffset "$X_AXIS" "$3"\
       -theme-str 'window{width: '"$WIDTH"'em;}textbox-prompt-colon{str:"'"$PROMPT"':";}'"$4"''
}

function change_wireless_interface() {
  if [ "${#WIRELESS_INTERFACES[@]}" = "2" ]; then
    WLAN_INT=$((WLAN_INT?0:1)) # flip value
  else
    LIST_WLAN_INT=""
    for i in "${!WIRELESS_INTERFACES[@]}"; do
      LIST_WLAN_INT=("${LIST_WLAN_INT[@]}${WIRELESS_INTERFACES_PRODUCT[$i]}[${WIRELESS_INTERFACES[$i]}]\n")
    done
    LIST_WLAN_INT[-1]=${LIST_WLAN_INT[-1]::-2}
    CHANGE_WLAN_INT=$(echo -e "${LIST_WLAN_INT[@]}" | rofi_cmd "${LIST_WLAN_INT[@]}" $WIDTH_FIX_STATUS)
    
    for i in "${!WIRELESS_INTERFACES[@]}"; do
      if [ "$CHANGE_WLAN_INT" = "${WIRELESS_INTERFACES_PRODUCT[$i]}[${WIRELESS_INTERFACES[$i]}]" ]; then
        WLAN_INT="$i"
        break
      fi
    done
  fi

  wireless_interface_state && ethernet_interface_state
  rofi_menu
}

function scan () {
  if [ "$WIFI_CON_STATE" = "unavailable" ]; then
    change_wifi_state "Wi-Fi" "Enabling Wi-Fi connection" "on"
  fi
  notification "Wifi" "Please, Wait... Scanning"
  WIFI_LIST="$(nmcli --fields SSID,SECURITY,BARS device wifi list ifname "${WIRELESS_INTERFACES[WLAN_INT]}" --rescan yes)"
  wifi_list
  wireless_interface_state && ethernet_interface_state
  dunstify -C "$nid"
  rofi_menu
}

function wifi_list(){
  WIFI_LIST="$(echo -e "$WIFI_LIST" | awk -F'  +' '{ if (!seen[$1]++) print}' | awk '$1!="--" {print}' | awk '$1 !~ "^'"${ACTIVE_SSID}"'"' )"
  [ "$ASCII_OUT" = "true" ] && WIFI_LIST="$(echo -e "$WIFI_LIST" | sed 's/\(..*\)\*\{4,4\}/\1▂▄▆█/g' | sed 's/\(..*\)\*\{3,3\}/\1▂▄▆_/g' | sed 's/\(..*\)\*\{2,2\}/\1▂▄__/g' | sed 's/\(..*\)\*\{1,1\}/\1▂___/g')"
  [ "$CHANGE_BARS" = "true" ] && WIFI_LIST="$(echo -e "$WIFI_LIST" |  sed 's/\(.*\)▂▄▆█/\1'$SIGNAL_STRENGTH_4'/' | sed 's/\(.*\)▂▄▆_/\1'$SIGNAL_STRENGTH_3'/' | sed 's/\(.*\)▂▄__/\1'$SIGNAL_STRENGTH_2'/' | sed 's/\(.*\)▂___/\1'$SIGNAL_STRENGTH_1'/' | sed 's/\(.*\)____/\1'$SIGNAL_STRENGTH_0'/')"
}

function change_wifi_state () {
  notification "$1" "$2"
  nmcli radio wifi "$3"
}

function change_wired_state () {
  notification "$1" "$2"
  nmcli device "$3" "$4"
}

function net_restart () {
  notification "$1" "$2"
  nmcli networking off && sleep 3 && nmcli networking on
}

function disconnect () {
  ACTIVE_SSID=$(nmcli -t -f GENERAL.CONNECTION dev show "${WIRELESS_INTERFACES[WLAN_INT]}" | cut -d ':' -f2)
  notification "$1" "You're now disconnected from Wi-Fi network '$ACTIVE_SSID'"
  nmcli con down id "$ACTIVE_SSID"
}

function check_wifi_connected () {
  if [ "$(nmcli device status | grep "^${WIRELESS_INTERFACES[WLAN_INT]}." | awk '{print $3}')" = "connected" ]; then
    disconnect "Connection_Terminated"
  fi
}

function connect() {
  check_wifi_connected
  local ssid="$1"
  local password="$2"
  
  notification "-t 0 Wi-Fi" "Connecting to $ssid"
  
  if [ "$(nmcli dev wifi con "$ssid" password "$password" ifname "${WIRELESS_INTERFACES[WLAN_INT]}" | grep -c "successfully activated")" = "1" ]; then
    notification "Connection_Established" "You're now connected to Wi-Fi network '$ssid'"
  else
    notification "Connection_Error" "Connection cannot be established"
  fi
}

function password_prompt () {
  PROMPT="Enter_Password" && PASS=$(echo "$PASSWORD_ENTER" | rofi_cmd "$PASSWORD_ENTER" 4 "-password")
}

function enter_ssid () {
  PROMPT="Enter_SSID" && SSID=$(rofi_cmd "" 40)
}

function stored_connection() {
  check_wifi_connected
  local ssid="$1"

  notification "-t 0 Wi-Fi" "Connecting to $ssid"
  
  if [ "$(nmcli dev wifi con "$ssid" ifname "${WIRELESS_INTERFACES[WLAN_INT]}" | grep -c "successfully activated")" = "1" ]; then
    notification "Connection_Established" "You're now connected to Wi-Fi network '$ssid'"
  else
    notification "Connection_Error" "Connection cannot be established"
  fi
}

function ssid_manual () {
  enter_ssid
  if [ -n "$SSID" ]; then
    password_prompt
    { [ -n "$PASS" ] && [ ! "$PASS" = "$PASSWORD_ENTER" ] && connect "$SSID" "$PASS"; } || stored_connection "$SSID"
  fi
}

function ssid_hidden () {
  enter_ssid
  if [ -n "$SSID" ]; then
    password_prompt && check_wifi_connected
    [ -n "$PASS" ] && [ ! "$PASS" = "$PASSWORD_ENTER" ] && {
      nmcli con add type wifi con-name "$SSID" ssid "$SSID" ifname "${WIRELESS_INTERFACES[WLAN_INT]}"
      nmcli con modify "$SSID" wifi-sec.key-mgmt wpa-psk
      nmcli con modify "$SSID" wifi-sec.psk "$PASS"
    } || [ "$(nmcli -g NAME con show | grep -c "$SSID")" = "0" ] && nmcli con add type wifi con-name "$SSID" ssid "$SSID" ifname "${WIRELESS_INTERFACES[WLAN_INT]}"
    notification "-t 0 Wifi" "Connecting to $SSID"
    { [ "$(nmcli con up id "$SSID" | grep -c "successfully activated")" = "1" ] && notification "Connection_Established" "You're now connected to Wi-Fi network '$SSID'"; } || notification "Connection_Error" "Connection can not be established"
  fi
}

function interface_status () {
  local -n INTERFACES=$1 && local -n INTERFACES_PRODUCT=$2
  for i in "${!INTERFACES[@]}"; do
    CON_STATE=$(nmcli device status | grep "^${INTERFACES[$i]}." | awk '{print $3}')
    INT_NAME=${INTERFACES_PRODUCT[$i]}[${INTERFACES[$i]}]
    [ "$CON_STATE" = "connected" ] && STATUS="$INT_NAME:\n\t$(nmcli -t -f GENERAL.CONNECTION dev show "${INTERFACES[$i]}" | awk -F '[:]' '{print $2}') ~ $(nmcli -t -f IP4.ADDRESS dev show "${INTERFACES[$i]}" | awk -F '[:/]' '{print $2}')" || STATUS="$INT_NAME: ${CON_STATE^}"
    echo -e "$STATUS"
  done
}

function status() {
  OPTIONS=""

  if [ ! "${#WIRED_INTERFACES[@]}" = "0" ]; then
    add_option "$(interface_status WIRED_INTERFACES WIRED_INTERFACES_PRODUCT)"
  fi

  if [ ! "${#WIRELESS_INTERFACES[@]}" = "0" ]; then
    add_option "$(interface_status WIRELESS_INTERFACES WIRELESS_INTERFACES_PRODUCT)"
  fi

  ACTIVE_VPN="$(nmcli -g NAME,TYPE con show --active | awk '/:vpn/' | sed 's/:vpn.*//g')"

  if [ -n "$ACTIVE_VPN" ]; then
    add_option "${ACTIVE_VPN}[VPN]: $(nmcli -g ip4.address con show "$ACTIVE_VPN" | awk -F '[:/]' '{ print $1; }')"
  fi

  echo -e "$OPTIONS" | rofi_cmd "$OPTIONS" "$WIDTH_FIX_STATUS" "" "mainbox{children:[listview];}"
}

function show_pass () {
  SSID="$(nmcli dev wifi show-password | grep -oP '(?<=SSID: ).*' | head -1)"
  PASSWORD="$(nmcli dev wifi show-password | grep -oP '(?<=Password: ).*' | head -1)"
  OPTIONS="SSID: ${SSID}\nPassword: ${PASSWORD}"
  [ -x "$(command -v qrencode)" ] && add_option "$opt_qr"
  choice="$(echo -e "$OPTIONS" | rofi_cmd "$OPTIONS" $WIDTH_FIX_STATUS "-a -1" "mainbox{children:[listview];}")"
  menu
}

function gen_qrcode () {
  DIRECTIONS=("Center" "Northwest" "North" "Northeast" "East" "Southeast" "South" "Southwest" "West")
  TMP_SSID="${SSID// /_}"
  [ -e "$QRCODE_DIR$TMP_SSID.png" ] || qrencode -t png -o "$QRCODE_DIR$TMP_SSID".png -l H -s 25 -m 2 --dpi=192 "WIFI:S:""$SSID"";T:""$(nmcli dev wifi show-password | grep -oP '(?<=Security: ).*' | head -1)"";P:""$PASSWORD"";;"
  rofi_cmd "" "0" "" "entry{enabled:false;}window{location:""${DIRECTIONS[QRCODE_LOCATION]}"";border-radius:6mm;padding:1mm;width:100mm;height:100mm;
  background-image:url(\"$QRCODE_DIR$TMP_SSID.png\",both);}"
}

function add_network () {
  add_option "$opt_manual" "$opt_hidden"
  choice="$(echo -e "$OPTIONS" | rofi_cmd "$OPTIONS" "$WIDTH_FIX_STATUS" "" "mainbox{children:[listview];}")"
  menu
}

function vpn () {
  ACTIVE_VPN="$(nmcli -g NAME,TYPE con show --active | awk '/:vpn/' | sed 's/:vpn.*//g')"
  opt_disable_vpn="Disable $ACTIVE_VPN"
  if [ -n "$ACTIVE_VPN" ]; then
    OPTIONS="$opt_disable_vpn"
  else
    OPTIONS="$(nmcli -g NAME,TYPE connection | awk '/:vpn/' | sed 's/:vpn.*//g')"
  fi
  VPN_ACTION=$(echo -e "$OPTIONS" | rofi_cmd "$OPTIONS" "$WIDTH_FIX_STATUS" "" "mainbox {children:[listview];}")
  if [ -n "$VPN_ACTION" ]; then
    if [ "$VPN_ACTION" = "$opt_disable_vpn" ]; then
      nmcli connection down "$ACTIVE_VPN" && notification "VPN_Deactivated" "$ACTIVE_VPN"
    else
      notification "-t 0 Activating_VPN" "$VPN_ACTION"
      VPN_OUTPUT="$(nmcli connection up "$VPN_ACTION" 2>/dev/null)"
      if grep -c "Connection successfully activated" <<< "$VPN_OUTPUT" > /dev/null; then
        notification "VPN_Successfully_Activated" "$VPN_ACTION"
      else
        notification "Error_Activating_VPN" "Check your configuration for $VPN_ACTION"
      fi
    fi
  fi
}

function more_options () {
  OPTIONS=""
  [ "$WIFI_CON_STATE" = "connected" ] && add_option "$opt_pwd"
  add_option "$opt_status" "$opt_restart"
  [ -n "$(nmcli -g NAME,TYPE connection | awk '/:vpn/' | sed 's/:vpn.*//g')" ] && add_option "$opt_vpn"
  [ -x "$(command -v nm-connection-editor)" ] && add_option "$opt_editor"
  choice="$(echo -e "$OPTIONS" | rofi_cmd "$OPTIONS" "$WIDTH_FIX_STATUS" "" "mainbox {children:[listview];}")"
  menu
}

function menu () {
  case "$(strip_option "$choice")" in
    "$opt_disc") disconnect "Connection_Terminated" ;;
    "$opt_scan") scan ;;
    "$opt_status") status ;;
    "$opt_pwd") show_pass ;;
    "$opt_add") add_network ;;
    "$opt_manual") ssid_manual ;;
    "$opt_hidden") ssid_hidden ;;
    "$opt_wifi_on") change_wifi_state "Wi-Fi" "Enabling Wi-Fi connection" "on" ;;
    "$opt_wifi_off") change_wifi_state "Wi-Fi" "Disabling Wi-Fi connection" "off" ;;
    "$opt_eth_off") change_wired_state "Ethernet" "Disabling Wired connection" "disconnect" "$WIRED_INTERFACES" ;;
    "$opt_eth_on") change_wired_state "Ethernet" "Enabling Wired connection" "connect" "$WIRED_INTERFACES" ;;
    "$opt_wifi_ix") change_wireless_interface ;;
    "$opt_restart") net_restart "Network" "Restarting Network" ;;
    "$opt_qr") gen_qrcode ;;
    "$opt_more") more_options ;;
    "$opt_editor") nm-connection-editor ;;
    "$opt_vpn") vpn ;;
    *)
      [ -n "$choice" ] && [[ "$WIFI_LIST" =~ .*"$choice".* ]] && {
        [ "$SSID" = "*" ] && SSID="$(echo "$choice" | sed "s/\s\{2,\}/\|/g " | awk -F "|" '{print $3}')"
        { [ "$ACTIVE_SSID" = "$SSID" ] && nmcli con up "$SSID" ifname "${WIRELESS_INTERFACES[WLAN_INT]}"; } || {
          [ "$choice" = "WPA2" ] || [ "$choice" = "WEP" ] && password_prompt
          { [ -n "$PASS" ] && [ ! "$PASS" = "$PASSWORD_ENTER" ] && connect "$SSID" "$PASS"; } || stored_connection "$SSID"
        }
      }
      ;;
  esac
}

config
notification "$title" "Please, wait..."
initialize && dunstify -C "$nid"
rofi_menu
