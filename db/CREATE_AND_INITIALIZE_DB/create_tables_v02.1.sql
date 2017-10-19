/* This SQL scripts creates all tables needed for the EMEP database of the
   Chemistry Transport department at HZG. Contact Daniel Neumann
   (daniel.neumann@___.de) when questions arise. */



-- Table holding units of measurement values in data
/* Examples: ppm, ug/m3
   Usage: The 'unit' attribute of the data table should have a 
          reference to the 'unit' attribute in the units table. */
-- UNITS IS CURRENTLY NOT USED.
CREATE TABLE units (
    unit_id SERIAL PRIMARY KEY,
    substance_long varchar(64),
    matrix varchar(64),
    substance_short varchar(16),
    unit varchar(16),
    type varchar(40)
  ); 


-- Table holding matrices of measurements
/* Examples: air, pm10, aerosol, precip
   Note: The matrix 'pm10' was denoted as 'aerosol' in the past. Hence, the
         matrices 'pm10' and 'aerosol' can be considered to be equal.
   Usage: The the 'matrix' attribute of the f_substances table should have a 
          reference to the 'matrix' attribute in the matrices table. */
-- MATRICES IS CURRENTLY NOT USED DUE TO NEWLY INTRODUCED VALUES FOR MATRIX.
CREATE TABLE matrices (
    matrix_id SERIAL PRIMARY KEY,
    matrix varchar(64)
  );


-- Table holding information on the higher-level groups of the flags
/* Each group indicates another problem type such as extreme/inconsistent
    values, mechnical or instrumental problems or chemical problems. */
CREATE TABLE flaggroups (
    flaggroup smallint PRIMARY KEY,
    description varchar(256)
  );



-- Table holding all possible quality flags, their validity and their meaning
CREATE TABLE flags (
    numflag smallint PRIMARY KEY,
    status char(1),
    description varchar(256),
    flaggroup smallint references flaggroups(flaggroup)
  );



-- Table holding information on all EMEP stations
CREATE TABLE stations (
    station_id character(7) PRIMARY KEY,
    station_name varchar(64),
    country character(2),
    longitude numeric(9, 6),
    latitude numeric(9, 6),
    altitude smallint
  );



-- Table holding meta data, which is unchanged for several files
CREATE TABLE files (
    file_id BIGSERIAL PRIMARY KEY,
    file_name varchar(256),
    station_id character(7),
    start_time integer,
    end_time integer,
    data_definition varchar(32),
    set_type_code varchar(10),
    regime varchar(10),
    station_code character(7),
    platform_code character(7),
    startdate date,
    timeref time,
    revision_date date,
    component varchar(32),
    unit varchar(16),
    matrix varchar(64),
    period_code varchar(4),
    resolution_code varchar(4),
    laboratory_code varchar(64),
    instrument_type varchar(64),
    instrument_name varchar(64),
    method_ref varchar(64),
    ext_lab_code varchar(64),
    ext_meth_ref varchar(64),
    add_qualifier varchar(64),
    insert_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );



-- Table holding file specific meta data of the individual measurement files
CREATE TABLE sgl_files (
  sgl_id SERIAL PRIMARY KEY,
  file_id integer references files(file_id),
  file_name varchar(256),
  startdate date,
  start_time_yyyyddd integer,
  start_time_hh smallint,
  end_time_yyyyddd integer,
  end_time_hh smallint,
  n_timesteps integer DEFAULT -1,
  special_comment_present boolean DEFAULT FALSE, /* NEW_v02.1 */
  complete boolean DEFAULT FALSE,
  insert_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  inserted_by varchar(64) DEFAULT current_user /* NEW_v02.1 */
);



-- Table holding information on individual measurement time series
--  (one per species and file)
CREATE TABLE f_substances (
    sf_id BIGSERIAL PRIMARY KEY,
    sgl_id integer references sgl_files(sgl_id),
    substance_short varchar(16),
    matrix varchar(64),  /* NEW_v02.1 */
    method_ref varchar(64),  /* NEW_v02.1 */
    complete boolean DEFAULT FALSE
  );



-- Table holding actual measurement data
/* Note: Some attributes are redundant (e.g. station_id and matrix) because the
          information can be obtained via the sf_id. These attributes
          exist for historical reasons. */
CREATE TABLE data (
    data_id BIGSERIAL PRIMARY KEY,
    file_id integer references files(file_id),
    sf_id integer references f_substances(sf_id),
    station_id character(7) references stations(station_id),
    substance_short varchar(16),
    matrix varchar(64),
    unit varchar(16),
    start_time_yyyyddd integer,
    start_time_hh smallint,
    end_time_yyyyddd integer,
    end_time_hh smallint,
    value double precision,
    /* REMOVED_v02.1: numflag smallint references flags(numflag) */
    numflag1 smallint references flags(numflag),  /* NEW_v02.1 */
    numflag2 smallint references flags(numflag),  /* NEW_v02.1 */
    numflag3 smallint references flags(numflag)  /* NEW_v02.1 */
  );
