
-- Useage:
-- mysql -u sdrAdmin -p --default-character-set=utf8 archive_catalog_test < db/mysql_structure_init.sql
-- mysql -u sdrAdmin -p --default-character-set=utf8 archive_catalog_development < db/mysql_structure_init.sql

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS digital_objects CASCADE;
DROP TABLE IF EXISTS dpn_objects CASCADE;
DROP TABLE IF EXISTS dpn_replicas CASCADE;
DROP TABLE IF EXISTS replicas CASCADE;
DROP TABLE IF EXISTS sdr_objects CASCADE;
DROP TABLE IF EXISTS sdr_object_versions CASCADE;
DROP TABLE IF EXISTS sdr_version_stats CASCADE;
DROP TABLE IF EXISTS tape_archives CASCADE;
DROP TABLE IF EXISTS tape_replicas CASCADE;
DROP VIEW IF EXISTS new_replicas CASCADE;
SET FOREIGN_KEY_CHECKS=1;

-- tables and constraints

CREATE TABLE digital_objects (
  digital_object_id VARCHAR(40) NOT NULL,
  home_repository VARCHAR(8) NOT NULL,
  CONSTRAINT digital_objects_pk PRIMARY KEY (digital_object_id)
);

CREATE TABLE dpn_objects (
  dpn_object_id VARCHAR(40) NOT NULL,
  CONSTRAINT dpn_objects_pk PRIMARY KEY (dpn_object_id)
);

CREATE TABLE dpn_replicas (
  replica_id INT UNSIGNED NOT NULL,
  dpn_object_id VARCHAR(40) NOT NULL,
  submit_date TIMESTAMP,
  accept_date TIMESTAMP,
  verify_date TIMESTAMP,
  CONSTRAINT dpn_replicas_pk PRIMARY KEY (replica_id)
);

-- TODO: Do we need a primary key on this table?
-- TODO: Can we allow duplicates, that might have different fixity?
CREATE TABLE replicas (
  replica_id VARCHAR(40) NOT NULL,
  home_repository VARCHAR(8) NOT NULL,
  create_date TIMESTAMP,
  payload_fixity_type VARCHAR(7) NOT NULL,
  payload_fixity VARCHAR(256) NOT NULL,
  payload_size BIGINT UNSIGNED NOT NULL
);

CREATE TABLE sdr_objects (
  sdr_object_id VARCHAR(17) NOT NULL,
  object_type VARCHAR(20) NOT NULL,
  governing_object VARCHAR(17),
  object_label VARCHAR(100),
  latest_version SMALLINT UNSIGNED,
  CONSTRAINT sdr_objects_pk PRIMARY KEY (sdr_object_id)
);

CREATE TABLE sdr_object_versions (
  sdr_object_id VARCHAR(17) NOT NULL,
  sdr_version_id SMALLINT UNSIGNED NOT NULL,
  ingest_date TIMESTAMP,
  replica_id VARCHAR(23),
  CONSTRAINT sdr_object_versions_pk PRIMARY KEY (sdr_object_id, sdr_version_id)
);

CREATE TABLE sdr_version_stats (
  sdr_object_id VARCHAR(17) NOT NULL,
  sdr_version_id SMALLINT UNSIGNED NOT NULL,
  inventory_type VARCHAR(5) NOT NULL,
  content_files INT UNSIGNED NOT NULL,
  content_blocks INT UNSIGNED NOT NULL,
  content_bytes BIGINT UNSIGNED NOT NULL,
  metadata_files INT UNSIGNED NOT NULL,
  metadata_blocks INT UNSIGNED NOT NULL,
  metadata_bytes BIGINT UNSIGNED NOT NULL,
  CONSTRAINT sdr_version_stats_pk PRIMARY KEY (sdr_object_id, sdr_version_id, inventory_type)
);
ALTER TABLE sdr_version_stats ADD CONSTRAINT sdr_version_stats_sdr_obj_fk1
  FOREIGN KEY (sdr_object_id, sdr_version_id)
  REFERENCES sdr_object_versions(sdr_object_id, sdr_version_id);


CREATE TABLE tape_archives (
  tape_archive_id VARCHAR(32) NOT NULL,
  tape_server VARCHAR(32) NOT NULL,
  tape_node VARCHAR(32) NOT NULL,
  submit_date TIMESTAMP,
  accept_date TIMESTAMP,
  verify_date TIMESTAMP,
  CONSTRAINT tape_archive_set_pk PRIMARY KEY (tape_archive_id)
);


CREATE TABLE tape_replicas (
  replica_id VARCHAR(40) NOT NULL,
  tape_archive_id VARCHAR(32) NOT NULL,
  CONSTRAINT tape_replicas_pk PRIMARY KEY (replica_id, tape_archive_id)
);




-- rake db:structure:dump did not get this view

CREATE VIEW new_replicas (replica_id, home_repository, create_date, payload_size, payload_fixity_type, payload_fixity) AS
  SELECT  r.replica_id , r.home_repository, r.create_date , r.payload_size, r.payload_fixity_type,  r.payload_fixity
  FROM replicas r LEFT JOIN tape_replicas t on r.replica_id = t.replica_id
  WHERE t.tape_archive_id is null;


