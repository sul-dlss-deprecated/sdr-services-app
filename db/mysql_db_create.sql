
DROP DATABASE IF EXISTS archive_catalog_test;
CREATE DATABASE archive_catalog_test
    DEFAULT CHARACTER SET utf8
    DEFAULT COLLATE utf8_general_ci;

DROP DATABASE IF EXISTS archive_catalog_development;
CREATE DATABASE archive_catalog_development
    DEFAULT CHARACTER SET utf8
    DEFAULT COLLATE utf8_general_ci;

# DROP USER 'sdrAdmin'@'localhost';
# CREATE USER 'sdrAdmin'@'localhost' IDENTIFIED BY 'sdrPass';
GRANT ALL PRIVILEGES ON archive_catalog_test.*
  TO 'sdrAdmin'@'localhost' IDENTIFIED BY 'sdrPass';
GRANT ALL PRIVILEGES ON archive_catalog_development.*
  TO 'sdrAdmin'@'localhost' IDENTIFIED BY 'sdrPass';

