#!/bin/bash

# iType=CD16
# iType=MERGE
iType=50km

# iGrid=fine
iGrid=coarse

dates_doy=(`cat dates_doy.csv`)
dates_yyyymmdd=(`cat dates_yyyymmdd.csv`)

BASEDIR='/gfs1/work/mvkdneum/HBM/ATM_DEPO_EMEP'

# SRCDIR=BSH_origName
# TRGDIR=BSH_origName_dating

# SRCDIR=BSH_agri
# TRGDIR=BSH_agri_dating

SRCDIR=BSH_EMEP_orig
TRGDIR=BSH_EMEP_dating

for i1 in `seq 0 365`; do
#  ln -s $BASEDIR/${SRCDIR}/ndep_cmaq_cb05tucl_ae5_aq_${iType}_2_${iGrid}_masked_${dates_doy[$i1]}.nc $BASEDIR/${TRGDIR}/ndep_cmaq_cb05tucl_ae5_aq_${iType}_2_${iGrid}_masked_${dates_yyyymmdd[$i1]}00
#  ln -s $BASEDIR/${SRCDIR}/ndep_cmaq_cb05tucl_ae5_aq_${iType}_2_${iGrid}_masked_${dates_doy[$i1]}.nc $BASEDIR/${TRGDIR}/ndep_cmaq_cb05tucl_ae5_aq_${iType}_2_${iGrid}_masked_${dates_yyyymmdd[$i1]}12
  ln -s ${BASEDIR}/${SRCDIR}/EMEP_${iType}_2_${iGrid}_masked_${dates_doy[$i1]}.nc ${BASEDIR}/${TRGDIR}/EMEP_${iType}_2_${iGrid}_masked_${dates_yyyymmdd[$i1]}00
  ln -s ${BASEDIR}/${SRCDIR}/EMEP_${iType}_2_${iGrid}_masked_${dates_doy[$i1]}.nc ${BASEDIR}/${TRGDIR}/EMEP_${iType}_2_${iGrid}_masked_${dates_yyyymmdd[$i1]}12
done

exit 0
