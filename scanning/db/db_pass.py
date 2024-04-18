from db_connector import mysql_db_pass_change, psql_db_pass_change
import argparse

#required packages: mysql-connector-python, psycopg2

SCAN_FILE = 'dbscan'

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d','--default', help='default passwords for db. ex: -d default,creds')
    parser.add_argument('-p','--password', help='new password. ex: -p new_pass')

    args = parser.parse_args()

    default_creds = ['', 'dd'] + args.default.split(',')
    new_pass = args.password

    with open(SCAN_FILE) as file:
        lines = file.readlines()

    for line in lines[2:]:
        if line == '\n':
            break
        db_type = line.split('/')[4]
        host = line.split(':')[0]
        print(host, db_type)
        if db_type == 'mysql':
            mysql_db_pass_change(host, default_creds, new_pass)
        elif db_type == 'postgresql':
            psql_db_pass_change(host, default_creds, new_pass)


