#!/bin/bash
# Build script for "Backup Left Behind" challenge (Backup Misconfiguration Level 2)

set -e

CHALLENGE_DIR="backup-left-behind"
BACKUP_ROOT="$CHALLENGE_DIR/var/backups"
BACKUP_ARCHIVE_NAME="etc-backup.tar.gz"
FLAG="flag{exposed_hash_leak_3f21}"

echo "[*] Creating challenge directory..."
mkdir -p "$BACKUP_ROOT/etc"

echo "[*] Populating fake /etc directory with sensitive files..."

# Create /etc/passwd (dummy)
cat <<EOF > "$BACKUP_ROOT/etc/passwd"
root:x:0:0:root:/root:/bin/bash
user:x:1000:1000:Test User:/home/user:/bin/bash
EOF

# Create /etc/shadow with flag embedded in root line
cat <<EOF > "$BACKUP_ROOT/etc/shadow"
root:\$6\$saltsalt\$ABCDEFGHASHVALUEHERE:::::: # $FLAG
user:\$6\$othersalt\$HIDDENHASHVALUEHERE::::::
EOF

# Add dummy SSH host key file
mkdir -p "$BACKUP_ROOT/etc/ssh"
echo "-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC7...
-----END RSA PRIVATE KEY-----
" > "$BACKUP_ROOT/etc/ssh/ssh_host_rsa_key"

echo "[*] Creating tar.gz archive..."
tar -czf "$CHALLENGE_DIR/$BACKUP_ARCHIVE_NAME" -C "$BACKUP_ROOT" .

echo "[*] Cleaning up source files..."
rm -rf "$BACKUP_ROOT"

# Create challenge.json (CTFd compatible)
cat <<EOF > "$CHALLENGE_DIR/challenge.json"
{
  "name": "Backup Left Behind",
  "category": "Backup Misconfiguration",
  "description": "A forgotten system backup was discovered in /var/backups/. What can you recover from it?",
  "value": 250,
  "state": "visible",
  "type": "standard",
  "connection_info": "",
  "flags": [
    {
      "type": "static",
      "content": "$FLAG",
      "data": ""
    }
  ]
}
EOF

echo "[✔] Done. Challenge created in: $CHALLENGE_DIR"

