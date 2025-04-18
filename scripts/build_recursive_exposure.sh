#!/bin/bash
# Build script for "Recursive Exposure" challenge (Backup Misconfiguration Level 3)

set -e

CHALLENGE_DIR="recursive-exposure"
BACKUP_ROOT="$CHALLENGE_DIR/var/backups"
OUTFILE="$CHALLENGE_DIR/recursive-exposure.tar.gz"

REAL_FLAG="flag{nested_backup_exposure_872a}"
DECOY_FLAG="flag{this_is_a_decoy}"

echo "[*] Cleaning up..."
rm -rf "$CHALLENGE_DIR"
mkdir -p "$BACKUP_ROOT/2025-04-01/etc"
mkdir -p "$BACKUP_ROOT/2025-04-01/2025-03-01/etc"

echo "[*] Creating decoy /etc/shadow..."
cat <<EOF > "$BACKUP_ROOT/2025-04-01/etc/shadow"
root:\$6\$saltsalt\$ABCDEFGHASHVALUEHERE:::::: # $DECOY_FLAG
user:\$6\$othersalt\$HIDDENHASHVALUEHERE::::::
EOF

echo "[*] Creating real flag in nested shadow.bak..."
cat <<EOF > "$BACKUP_ROOT/2025-04-01/2025-03-01/etc/shadow.bak"
root:\$6\$saltREAL\$HASHREAL:::::: # $REAL_FLAG
user:\$6\$othersalt\$HIDDEN::::::
EOF

echo "[*] Creating tar.gz archive..."
tar -czf "$OUTFILE" -C "$CHALLENGE_DIR" var/

echo "[*] Removing raw build files..."
rm -rf "$BACKUP_ROOT"

echo "[*] Writing challenge.json..."
cat <<EOF > "$CHALLENGE_DIR/challenge.json"
{
  "name": "Recursive Exposure",
  "category": "Backup Misconfiguration",
  "description": "You've discovered a recursive backup inside /var/backups/. Somewhere deep in the nesting, a forgotten shadow file remains. Be careful — not everything is what it seems.",
  "value": 350,
  "state": "visible",
  "type": "standard",
  "flags": [
    {
      "type": "static",
      "content": "$REAL_FLAG",
      "data": ""
    }
  ]
}
EOF

echo "[✔] Challenge built: $CHALLENGE_DIR"


