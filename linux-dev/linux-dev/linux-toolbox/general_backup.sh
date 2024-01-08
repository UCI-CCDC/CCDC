#/usr/bin/env bash

sep () {
    echo "======================================================================================================="
}

dash_sep () {
    echo "-------------------------------------------------------------------------------------------------------"
}

if [ "$#" -ne 1 ]; then
    if [ -n "$AAA" ]; then
        backup_dir="$AAA"
    else
        echo "Usage: $0 <backup_path>"
        echo "Alternatively, set environment variable AAA."
        exit 1
    fi
else
    backup_dir="$1"
fi

echo "Commencing General Backup"
sep
# Ensure the backup directory exists
mkdir -p "$backup_dir" && echo "Backup directory created at $backup_dir"
chmod 600 "$backup_dir"
sep

echo "Default Firewall Backups"
dash_sep
firewall_backup_dir=$backup_dir/firewall_rules
mkdir -p $firewall_backup_dir && echo "Firewall backup directory created at $firewall_backup_dir"
chmod 600 "$firewall_backup_dir"
# Backup iptables rules
if command -v iptables-save >/dev/null 2>&1; then
    echo "Backing up iptables rules..."
    iptables-save > "$firewall_backup_dir/iptables_rules.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$firewall_backup_dir/iptables_rules.bak"
        echo "Done backing up iptables rules."
    else
        echo "[!] Error: Failed to create backup for iptables rules."
    fi
else
    echo "[-] iptables-save command not found. Skipping iptables backup."
fi

# Backup ufw rules
if command -v ufw >/dev/null 2>&1; then
    echo "Backing up ufw rules..."
    ufw status numbered > "$firewall_backup_dir/ufw_rules.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$firewall_backup_dir/ufw_rules.bak"
        echo "Done backing up ufw rules."
    else
        echo "[!] Error: Failed to create backup for ufw rules."
    fi
else
    echo "[-] ufw command not found. Skipping ufw backup."
fi

# Backup nftables rules
if command -v nft >/dev/null 2>&1; then
    echo "Backing up nftables rules..."
    nft list ruleset > "$firewall_backup_dir/nftables_rules.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$firewall_backup_dir/nftables_rules.bak"
        echo "Done backing up nftables rules."
    else
        echo "[!] Error: Failed to create backup for nftables rules."
    fi
else
    echo "[-] nft command not found. Skipping nftables backup."
fi

# Backup firewalld rules
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "Backing up firewalld rules..."
    firewall-cmd --list-all > "$firewall_backup_dir/firewalld_rules.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$firewall_backup_dir/firewalld_rules.bak"
        echo "Done backing up firewalld rules."
    else
        echo "[!] Error: Failed to create backup for firewalld rules."
    fi
else
    echo "[-] firewall-cmd command not found. Skipping firewalld backup."
fi


# Backup /etc/profile
if [ -f "/etc/profile" ]; then
    echo "Backing up /etc/profile..."
    cp /etc/profile "$backup_dir/etc_profile.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/etc_profile.bak"
        echo "Done backing up /etc/profile."
    else
        echo "[!] Error: Failed to create backup for /etc/profile."
        exit 1
    fi
else
    echo "[-] /etc/profile not found."
fi
sep

# Backup /etc/profile.d if it is non-empty
profile_d_dir="/etc/profile.d"
if [ -d "$profile_d_dir" ] && [ "$(ls -A "$profile_d_dir")" ]; then
    echo "Backing up $profile_d_dir..."
    tar -czf "$backup_dir/etc_profile.d.tar.gz" -C /etc profile.d
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/etc_profile.d.tar.gz"
        echo "Done backing up $profile_d_dir."
    else
        echo "[!] Error: Failed to create backup for $profile_d_dir."
        exit 1
    fi
else
    echo "[-] $profile_d_dir is empty or not found. Skipping backup."
fi
sep

# Backup current user's .profile
user_profile="$HOME/.profile"
if [ -f "$user_profile" ]; then
    echo "Backing up $user_profile..."
    cp "$user_profile" "$backup_dir/user_profile.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/user_profile.bak"
        echo "Done backing up $user_profile."
    else
        echo "[!] Error: Failed to create backup for $user_profile."
        exit 1
    fi
else
    echo "[-] $user_profile not found."
fi
sep

# Backup /etc/passwd
if [ -f "/etc/passwd" ]; then
    echo "Backing up /etc/passwd..."
    cp /etc/passwd "$backup_dir/passwd.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/passwd.bak"
        echo "Done backing up /etc/passwd."
    else
        echo "[!] Error: Failed to create backup for /etc/passwd."
    fi
else
    echo "[!] Error: /etc/passwd not found."
fi
sep

# Backup aliases from .bash_aliases (assuming Bash)
if [ -f "$HOME/.bash_aliases" ]; then
    echo "Backing up aliases from .bash_aliases..."
    cp "$HOME/.bash_aliases" "$backup_dir/bash_aliases.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/bash_aliases.bak"
        echo "Done backing up aliases from .bash_aliases."
    else
        echo "[!] Error: Failed to create backup for .bash_aliases."
    fi
else
    echo "[-] .bash_aliases not found."
fi
sep

# Backup entire .bashrc (assuming Bash)
if [ -f "$HOME/.bashrc" ]; then
    echo "Backing up entire .bashrc..."
    cp "$HOME/.bashrc" "$backup_dir/bashrc.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/bashrc.bak"
        echo "Done backing up entire .bashrc."
    else
        echo "[!] Error: Failed to create backup for .bashrc."
    fi
else
    echo "[-] Error: .bashrc not found."
fi
sep

# Backup aliases from .bashrc (assuming Bash)
if [ -f "$HOME/.bashrc" ]; then
    echo "Checking .bashrc for aliases..."
    grep -E '^\s*alias ' "$HOME/.bashrc" | sed 's/^\s*//' > "$backup_dir/bashrc_aliases.bak"
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_dir/bashrc_aliases.bak"
        echo "Done backing up aliases from .bashrc."
    else
        echo "No aliases found in .bashrc."
    fi
else
    echo "[-] Error: .bashrc not found."
fi
sep

# Backup environment variables
echo "Backing up environment variables..."
env > "$backup_dir/environment_variables.bak"
if [ $? -eq 0 ]; then
    chmod 600 "$backup_dir/environment_variables.bak"
    echo "Done backing up environment variables."
else
    echo "[!] Error: Failed to create backup for environment variables."
fi
sep

# Backup PATH
echo "Backing up PATH..."
echo "$PATH" > "$backup_dir/path.bak"
if [ $? -eq 0 ]; then
    chmod 600 "$backup_dir/path.bak"
    echo "Done backing up PATH."
else
    echo "[!] Error: Failed to create backup for PATH."
fi
sep
echo "General backup finished. Find files in $backup_dir"
