#!/usr/bin/env bash
# irnm - install script
#############################
# install config
PROGRAM_NAME="irnm"
DEST_FILE="${INSTALL_DIR:-"/usr/local/bin"}/$PROGRAM_NAME"
#############################
# do not edit below this line
#############################
BAK_FILE="$DEST_FILE"

confirm () {
  while true; do
    read -n 1 -p "Do you want to create a backup? (Y/n) " ans
    [ -n "$ans" ] && echo # if input wasn't a return, add newline
    case "$ans" in
      [Yy]* | "" ) return ;;
      [Nn]* ) return 1 ;;
      * ) echo "invalid option: $ans" ;;
    esac
  done
}

echo "[*] Installing $PROGRAM_NAME..."

# cd to install directory
cd "$(eval 'dirname "$(readlink -f "$0")"')" || exit 1
# make program executable
chmod +x "$PROGRAM_NAME"

# find available file name for backup
while [ -e "$BAK_FILE" ]; do
  BAK_FILE="$BAK_FILE.bak"
done

# make backup if dest file exists and is not the same file
if [ -e "$DEST_FILE" ] &&
  ! diff "$PROGRAM_NAME" "$DEST_FILE" > /dev/null &&
  [ ! "$1" = "-n" ] &&
  [ ! "$1" = "--nobak" ]
then
  if confirm; then
    echo "[*] Creating backup copy..."
    sudo mv "$DEST_FILE" "$BAK_FILE" || exit 1
    echo "Backup copy created: $BAK_FILE"
  fi
fi

# copy to install dir
sudo cp "$PROGRAM_NAME" "$DEST_FILE"

if [ -x "$DEST_FILE" ]; then
  echo "[*] Install complete!"
else
  echo "[!] error: failed to install $PROGRAM_NAME"
  exit 2
fi
