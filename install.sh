#!/bin/sh
PROGRAM_NAME="irnm"
INSTALL_DIR="/usr/local/bin"
DEST_FILE="$INSTALL_DIR/$PROGRAM_NAME"
BAK_FILE="$DEST_FILE"
TMP_LINK="$PROGRAM_NAME.ln"

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
  [ ! "$1" = "--nobak" ]; then
  echo "[*] Creating backup copy..."
  sudo mv "$DEST_FILE" "$BAK_FILE" || exit 1
  echo "Backup copy created: $BAK_FILE"
fi

# copy to install dir
sudo cp "$PROGRAM_NAME" "$DEST_FILE"

if [ -x "$DEST_FILE" ]; then
  echo "[*] Install complete!"
else
  echo "[!] error: failed to install $PROGRAM_NAME"
  exit 2
fi
