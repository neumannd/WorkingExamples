/* This SQL scripts fills predefined data into some tables of EMEP database of 
   the Chemistry Transport department at HZG. */


/* copy content into units table */
\copy units (substance_long, matrix, substance_short, unit, type) FROM './data_files/emep_units_4db';
 
/* copy content into flaggroups table; NEEDS TO BE FILLED BEFORE 'flags' */
\copy flaggroups (flaggroup, description) FROM './data_files/emep_flaggroups_4db';
 
/* copy content into flags table; 'flaggroups' NEEDS TO BE FILLED BEFORE 'data' */
\copy flags (numflag, status, description, flaggroup) FROM './data_files/emep_flags_4db';
 
/* copy content into stations table; 'stations' NEEDS TO BE FILLED BEFORE 'data' */
\copy stations (station_id, station_name, country, longitude, latitude, altitude) FROM './data_files/emep_stations_4db';
 
/* copy content into matrices table */
\copy matrices (matrix) FROM './data_files/emep_matrices_4db';
