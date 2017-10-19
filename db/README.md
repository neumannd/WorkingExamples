## DB

During my work at the Helmholtz-Zentrum Geesthacht, we validated atmospheric
chemistry transport model simulations with data from the EMEP measurement 
database. EMEP is the *European Measurement and Evaluation Programme*. Within
EMEP, measurement data from European background air quality monitoring 
stations is collected. The data can be freely downloaded from the
[NILU's EBAS database via a web interface](http://ebas.nilu.no).

The EMEP data are provided in one file per year, station, and parameter. Some
parameters can also be summarized in one file. The EMEP files are structured
according to the NASA AMES format. The EMEP format is a bit stricter. To 
simplify the validation process, I
   * wrote R functions to import in the standardized EMEP text files into R
   * created as PostgreSQL database to locally host EMEP data
   * wrote R functions to import EMEP data into the database.
A colleague wrote R functions to export the EMEP data from the database and
visualized them. The three aspects for I was responsible are presented here:

   * `CREATE_AND_INITIALIZE_DB`: set up and initialize database
   * `DIAGRAMS`: Entity Relationship diagram of the database
   * `R_TOOLS`:
      * two R packages, which are for reading EMEP text files 
         (`R_TOOLS/emepTools`) and for importing EMEP data into the database 
         (`R_TOOLS/emepDB`)
      * two R scripts and some dummy data to test the packages

The test script for the `emepDB` packages is also an example for generally 
using the package. Maybe the one or the other reader is interested in it.

In the emepDB package, I use `RODBC` to access the database. ODBC provides 
a universal database access interface. The user needs to have 

   * install the appropriate ODBC package on his/her operating system,
   * installed a PostgreSQL-OBDC driver, and
   * configured the OBDC package to *know* the database
   
This has the advantage that the database does not necessarily need to be a 
PostgreSQL database but any database, for which a ODBC driver is available.
In addition, it is platform independent and the database may either be a 
local one or a remove one. 

In order to fully test/use this example case, one needs to have a PostgreSQL 
server running (for `CREATE_AND_INITIALIZE_DB`) and ODBC configured (`emepDB` 
package). The `emepTools` package runs out of the box.


### CREATE_AND_INITIALIZE_DB

The scripts in the `CREATE_AND_INITIALIZE_DB` folder create the EMEP database,
create necessary tables and fill some tables with predefined data (e.g. station
data). If one has a local PostgreSQL database running and if the current user 
is allowed to create new database, one can just run

    ./create_db_and_do_all.sh

Otherwise, one needs to create the new database manually and call the two SQL 
scripts `create_tables_v02.1.sql` and `fill_tables_v02.1.sql` by hand.


### DIAGRAMS

Just one ER diagram in different formats. I created it with dia, exported it 
to SVG, made some corrections in Inkscape, and exported it to PDF.


### R_TOOLS

The two folders `emepDB` and `emepTools` contain the two R packages. The 
packages are also provided as `*.tar.gz` files in the same folder. The folder
`emepPackagesTesting` contains two R scripts to test the R packages. Some dummy
data is included in `emepPackagesTesting/emep_data`. These are no real data and
they are only provided for testing purposes.

The package `emepTools` has no dependencies. The packages `emepDB` depends on
`emepTools` and on `RODBC`. Each function in `emepDB` exists twice. The 
functions of the format `name.RODBC` expect an open rodbc database connection
as first argument. The functions of the format `name` expect a variable 
`DBaccess` to be set as follows:

    DBaccess <- list(name="ODBC-dsn", uid="USERNAME", pwd="PASSWORD") 

The `ODBC-dsn`, `USERNAME`, and `PASSWORD` need to be replaced. The latter set 
of functions (without `RODBC` in their name) causes some extra opening and 
closing of the database connection. However, they save inexperienced users some
time to deal with the database connection.

For more details on using the packages please consult the test scripts and the
manual pages of the functions.
