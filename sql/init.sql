CREATE ROLE "kc-user" WITH
    LOGIN
    SUPERUSER
    INHERIT
    CREATEDB
    CREATEROLE
    NOREPLICATION
    PASSWORD 'kc-pass';

CREATE DATABASE keycloak
    WITH
    OWNER = "kc-user"
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

GRANT ALL PRIVILEGES ON DATABASE keycloak TO "kc-user";
GRANT ALL PRIVILEGES ON DATABASE keycloak TO postgres;

-- #############################################

-- CREATE ROLE "mydb-user" WITH
--     LOGIN
--     INHERIT
--     PASSWORD 'mydb-pass';
-- 
-- CREATE DATABASE mydb
--     WITH
--     OWNER = "mydb-user"
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.utf8'
--     LC_CTYPE = 'en_US.utf8'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1;
-- 
-- GRANT ALL PRIVILEGES ON DATABASE mydb TO "mydb-user";
