#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    printf 'Must be run as root, exiting!\n'
    exit 1
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <psql_user> <psql_password> <psql host>"
    exit 1
fi


sep () {
    echo "======================================================================================================="
}

dash_sep () {
    echo "-------------------------------------------------------------------------------------------------------"
}


PSQL_USER="$1"
# PSQL_PASSWORD="$2"
export PGPASSWORD="$2"
PSQL_HOST="$3"

echo "MySQL Auditing"
sep


# List all databases

psql -h "$PSQL_HOST" -U "$PSQL_USER" -t -c "SELECT datname FROM pg_database;" | awk '{print NR, $1}' > database_list.txt
let numlines="$(wc -l < database_list.txt) - 1"
head -n $numlines database_list.txt > tmp.txt; mv tmp.txt database_list.txt



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

psql -h "$PSQL_HOST" -U "$PSQL_USER" $selected_db -c "
SELECT grantor,grantee,table_name,privilege_type,is_grantable,with_hierarchy
 FROM information_schema.role_table_grants WHERE table_catalog='${selected_db}' AND table_schema = 'public';"


