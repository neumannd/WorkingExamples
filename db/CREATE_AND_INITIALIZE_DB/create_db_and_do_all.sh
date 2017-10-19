#!/bin/bash

# @author Daniel Neumann, daniel.neumann@___.de
# @date 2016-06-05

version='02.1'
DB_name='myThirdDB'

echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo 'This script will create a new database for EMEP data, create the basic'
echo 'table structure and fill some tables with standard data.'
echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'

echo -e '\nCreate DB'
createdb ${DB_name}

echo -e '\nCreate Tables'
psql ${DB_name} -f create_tables_v02.1.sql

echo -e "\nFille with Standard Data"
psql ${DB_name} -f fill_tables_v02.1.sql

echo -e '\nFinished!'
