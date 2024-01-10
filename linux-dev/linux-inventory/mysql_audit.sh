#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    printf 'Must be run as root, exiting!\n'
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <mysql_user> <mysql_password> <OPTIONAL: mysql_host>"
    exit 1
fi


sep () {
    echo "======================================================================================================="
}

dash_sep () {
    echo "-------------------------------------------------------------------------------------------------------"
}


MYSQL_USER="$1"
MYSQL_PASSWORD="$2"
MYSQL_HOST="$3"
REMOTE=false
echo "MySQL Auditing"
sep

# check if a host is provided
if [ -z "$MYSQL_HOST" ]; then
    MYSQL_HOST="localhost"
else 
    REMOTE=true
fi

# Check if MySQL logging is enabled
mysql_logging_status=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW VARIABLES LIKE 'general_log';" | awk '$1=="general_log" {print $2}')

if [ "$mysql_logging_status" == "OFF" ]; then
    read -p "MySQL logging is currently disabled. Do you want to enable it? (y/N): " enable_logging
    dash_sep
    if [ "$enable_logging" == "y" ] || [ "$enable_logging" == "Y" ]; then
        # Enable MySQL logging
        if [ "$REMOTE" = true ]; then
            mysql -u "$MYSQL_USER" -p "$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "SET GLOBAL general_log = 'ON';"
        else
            mysql -u "$MYSQL_USER" -p "$MYSQL_PASSWORD" -e "SET GLOBAL general_log = 'ON';"
        fi
        echo "MySQL logging has been enabled."
    else
        echo "MySQL logging remains disabled."
    fi
else
    echo "MySQL logging is already enabled."
fi
sep


# Log into MySQL and list databases
if [ "$REMOTE" = true ]; then
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "SHOW DATABASES;" | awk '{if(NR>1) print NR-1, $1}' > database_list.txt
else
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" | awk '{if(NR>1) print NR-1, $1}' > database_list.txt
fi

# Display the list of databases and prompt the user to choose
echo "List of databases:"
dash_sep
cat database_list.txt
sep

read -p "Enter the number corresponding to the database you want to analyze: " selected_db_number

# Validate user input
if ! [ "$selected_db_number" -ge 1 ] 2>/dev/null || ! [ "$selected_db_number" -le $(wc -l < database_list.txt) ]; then
    echo "Invalid input. Please enter a valid number."
    exit 1
fi

# Retrieve the selected database from the list
selected_db=$(awk -v num="$selected_db_number" '$1 == num {print $2}' database_list.txt)
sep

# Echo statement informing the user
echo "Checking grants for all users in the database '$selected_db'..."

if [ "$REMOTE" = true ]; then
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$selected_db" -e "SELECT user, host FROM mysql.user;" | tail -n +2 | grep -vE '^performance|^mysql' > user_list.txt
else
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$selected_db" -e "SELECT user, host FROM mysql.user;" | tail -n +2 | grep -vE '^performance|^mysql' > user_list.txt
fi


if [ $? -ne 0 ]; then
    echo "Error: Unable to retrieve the list of users."
    exit 1
fi

# Iterate over each user and show grants
echo "$users" | while read -r user host; do
    dash_sep
    echo "Grants for user '$user'@'$host':"
    if [ "$REMOTE" = true ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$selected_db" -e "SHOW GRANTS FOR '$user'@'$host';" | grep -vE '^Grants|^\+'
    else
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$selected_db" -e "SHOW GRANTS FOR '$user'@'$host';" | grep -vE '^Grants|^\+'
    fi
    if [ $? -ne 0 ]; then
        echo "Error: Unable to retrieve grants for user '$user'@'$host'."
        exit 1
    fi

done

sep
echo "Users with DROP, ALTER for database '$selected_db':"
dash_sep
if [ "$REMOTE" = true ]; then
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$selected_db" -e "SELECT user, host FROM mysql.user WHERE Drop_priv='Y' OR ALTER_priv='Y';" | tail -n +2
else
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$selected_db" -e "SELECT user, host FROM mysql.user WHERE Drop_priv='Y' OR ALTER_priv='Y';" | tail -n +2
fi

sep
echo "Users with UPDATE, INSERT, CREATE, or DELETE privileges for database '$selected_db':"
dash_sep
if [ "$REMOTE" = true ]; then
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -D "$selected_db" -e "SELECT user, host FROM mysql.user WHERE Update_priv='Y' OR Insert_priv='Y' OR Create_priv='Y' OR Delete_priv='Y';" | tail -n +2
else
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$selected_db" -e "SELECT user, host FROM mysql.user WHERE Update_priv='Y' OR Insert_priv='Y' OR Create_priv='Y' OR Delete_priv='Y';" | tail -n +2
fi

sep
echo "MySQL Audit Finished"
