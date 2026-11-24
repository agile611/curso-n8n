#!/bin/bash
# Script para crear múltiples bases de datos en PostgreSQL (idempotente)

set -e

function create_user_and_database() {
    local database=$1
    echo "Checking/creating user and database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        -- Create user if not exists
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$database') THEN
                CREATE USER $database WITH PASSWORD '$database';
            END IF;
        END
        \$\$;
        
        -- Create database if not exists
        SELECT 'CREATE DATABASE $database' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$database')\gexec
        
        -- Grant privileges
        GRANT ALL PRIVILEGES ON DATABASE $database TO $database;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_user_and_database $db
    done
    echo "Multiple databases created/verified"
fi