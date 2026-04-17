-- Central database is created by MYSQL_DATABASE env var
-- This script grants privileges for tenant DB creation
GRANT ALL PRIVILEGES ON *.* TO 'foodapp'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
