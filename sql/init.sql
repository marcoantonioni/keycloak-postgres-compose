CREATE ROLE "quarkus-user" WITH
    LOGIN
    SUPERUSER
    INHERIT
    CREATEDB
    CREATEROLE
    NOREPLICATION
    PASSWORD 'quarkus-pass';

CREATE DATABASE kogito
    WITH
    OWNER = "quarkus-user"
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE keycloak
    WITH
    OWNER = "quarkus-user"
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

GRANT ALL PRIVILEGES ON DATABASE postgres TO "quarkus-user";
GRANT ALL PRIVILEGES ON DATABASE kogito TO "quarkus-user";
GRANT ALL PRIVILEGES ON DATABASE kogito TO postgres;

GRANT ALL PRIVILEGES ON DATABASE keycloak TO "quarkus-user";
GRANT ALL PRIVILEGES ON DATABASE keycloak TO postgres;