#!/bin/bash

# @author Daniel Neumann
# @date 2017-05-04
# @description Script to summarize CMAQ model results into one file that will be later uploaded to CERA at WDCC

# export PATH="/media/neumannd/sw/linux/packages/netcdf/netcdf-4.4.1.1/gcc-5.4.0/noMPI/bin/:/media/neumannd/sw/linux/packages/cdo/cdo-1.7.2/gcc-5.4.0/noMPI/bin:/media/neumannd/sw/linux/packages/nco/nco-4.6.5/gcc-5.4.0/noMPI/bin:/media/neumannd/sw/linux/packages/nco/nco-4.6.5/gcc-5.4.0/noMPI/build/src/nco:${PATH}"


for DATE in `cat dates/my_dates_full2008.dat`; do

  #### ~~~~~~~~~~~~~~~~~~~~~~~~~~~ USER SECTION ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ####

  ## MODEL RUN PARAMETERS
  # date
  ## DATE=2008140
  YEAR=${DATE:0:4}

  # grid definition
  GRID_NAME="CD24"
  grid_name="${GRID_NAME,,}"

  # aero in aero5 and aero6
  vAERO=5
  # vAERO=6

  # mechanism
  MECH=cb05tucl
  # MECH=cb05tump

  # scen in base and ov14
  # SCEN=zero
  SCEN=base
  # SCEN=ov14

  # CMAQ base file name (part between CONC/DRYDEP/... and DATE)
  CMAQ_BASE_NAME="${GRID_NAME}_effectSeaSalt.v5.${SCEN}_${MECH}_ae${vAERO}_aq_ssa"
  # CONCfile = CONC.${CMAQ_BASE_NAME}_DATE
  # WETDEPfile = WETDEP1.${CMAQ_BASE_NAME}_DATE
  # DRYDEPfile = DRYDEP.${CMAQ_BASE_NAME}_DATE


  ## DIRECTORIES
  dCURR=`pwd`
  dScripts="${dCURR}/scripts"
  dTMP="${dCURR}/tmp_${SCEN}"
  dCCTM="/ocean-storage/neumannd/data/storage/neumannd/data/cctm/${GRID_NAME}/effectSeaSalt.v5.${SCEN}/"
  dMET="/ocean-storage/M3HOME/data/lmmcip/${GRID_NAME}/${YEAR}"
  dOUT="/ocean-storage/neumannd/data/cctm/cera/${GRID_NAME}_${SCEN}"




  #### ~~~~~~~~~~~~~~~~~~~~~~~ ADVANCED USER SECTION ~~~~~~~~~~~~~~~~~~~~~~~ ####

  ## FILE NAMES (INPUT AND OUTPUT)
  fBASEDEF_TXT='fileDefinition.cdl'
  fBASEDEF_NC='fileDefinition.nc'
  fOUT="cmaq_${grid_name}_${MECH}_ae${vAERO}_seasalt.${SCEN}_${DATE}.nc"
  fTMP='tmp.nc'

  fCONC="CONC.${CMAQ_BASE_NAME}_${DATE}"
  fWETDEP="WETDEP1.${CMAQ_BASE_NAME}_${DATE}"
  fDRYDEP="DRYDEP.${CMAQ_BASE_NAME}_${DATE}"

  fGRIDCRO2D="/GRIDCRO2D_${grid_name}_${DATE}"
  fGRIDDOT2D="/GRIDDOT2D_${grid_name}_${DATE}"
  fMETCRO2D="METCRO2D_${grid_name}_${DATE}"
  fMETCRO3D="METCRO3D_${grid_name}_${DATE}"


  ## SCRIPT NAMES
  if [ "${SCEN}" = "base" ]; then
    sEAsALTmODE="base"
  elif [ "${SCEN}" = "ov14" ]; then
    sEAsALTmODE="wiANAI"
  else
    sEAsALTmODE="base"
  fi

  calc_conc_script="calc_conc_aero${vAERO}_${sEAsALTmODE}.nco"
  calc_wetdep_script='calc_wetdep.nco'
  calc_drydep_script='calc_drydep.nco'
  calc_gridcro2d_script='calc_gridcro2d.nco'
  calc_griddot2d_script='calc_griddot2d.nco'
  calc_metcro2d_script='calc_metcro2d.nco'
  calc_metcro3d_script='calc_metcro3d.nco'



  if [[ -f "${dCCTM}/${fCONC}" ]]; then
    
    echo "processing data ${DATE}"
    
    #~ #### ~~~~~~~~~~~~~~~~~~~~~~~~ AUTOMATIC SECTION ~~~~~~~~~~~~~~~~~~~~~~~~ ####

    ## CHECK WHETHER DIRECTORIES EXIST
    echo "~~~ Checking Directories ~~~"
    if [ ! -d "${dTMP}" ]; then
      mkdir -p ${dTMP}
      echo " Directory ${dTMP} did not exist and was created."
    fi
    if [ ! -d "${dOUT}" ]; then
      mkdir -p ${dOUT}
      echo " Directory ${dOUT} did not exist and was created."
    fi
    if [ ! -d "${dScripts}" ]; then
      echo " Directory ${dScripts} does not exist. Stopping Script ..."
      exit 1
    fi
    if [ ! -d "${dCCTM}" ]; then
      echo " Directory ${dCCTM} does not exist. Stopping Script ..."
      exit 1
    fi
    if [ ! -d "${dMET}" ]; then
      echo " Directory ${dMET} does not exist. Stopping Script ..."
      exit 1
    fi


    ## CHECK WHETHER INPUT FILE EXIST
    echo "~~~ Checking Files ~~~"
    if [ ! -f "${fBASEDEF_TXT}" ]; then
      echo " Text file with basic definition for new netCDF file does not exist:"
      echo "   ${fBASEDEF_TXT}"
      echo "  Stopping Script ..."
      exit 1
    fi
    if [ ! -f "${dCCTM}/${fCONC}" ]; then
      echo " CONC file does not exist:"
      echo "   ${dCCTM}/${fCONC}"
      echo "  Stopping Script ..."
      exit 1
    fi
    if [ ! -f "${dCCTM}/${fWETDEP}" ]; then
      echo " WETDEP1 file does not exist:"
      echo "   ${dCCTM}/${fWETDEP}"
      echo "  Stopping Script ..."
      exit 1
    fi
    if [ ! -f "${dCCTM}/${fDRYDEP}" ]; then
      echo " DRYDEP file does not exist:"
      echo "   ${dCCTM}/${fDRYDEP}"
      echo "  Stopping Script ..."
      exit 1
    fi
    if [ ! -f "${dMET}/${fGRIDCRO2D}" ]; then
      echo " GRIDCRO2D file does not exist:"
      echo "   ${dMET}/${fGRIDCRO2D}"
      echo "  Stopping Script ..."
      exit 1
    fi
    if [ ! -f "${dMET}/${fMETCRO2D}" ]; then
      echo " METRO2D file does not exist:"
      echo "   ${dMET}/${fMETCRO2D}"
      echo "  Stopping Script ..."
      exit 1
    fi
    if [ ! -f "${dMET}/${fMETCRO3D}" ]; then
      echo " METRO3D file does not exist:"
      echo "   ${dMET}/${fMETCRO3D}"
      echo "  Stopping Script ..."
      exit 1
    fi


    ## CHECK WHETHER INPUT FILE EXIST
    echo "~~~ Checking Scripts ~~~"
    if [ ! -f "${dScripts}/${calc_conc_script}" ]; then
      echo " NCO script file does not exist:"
      echo "   ${dScripts}/${calc_conc_script}"
      echo "  Stopping Script ..."
      exit 1
    fi
    echo "~~~ Checking Scripts ~~~"
    if [ ! -f "${dScripts}/${calc_wetdep_script}" ]; then
      echo " NCO script file does not exist:"
      echo "   ${dScripts}/${calc_wetdep_script}"
      echo "  Stopping Script ..."
      exit 1
    fi
    echo "~~~ Checking Scripts ~~~"
    if [ ! -f "${dScripts}/${calc_drydep_script}" ]; then
      echo " NCO script file does not exist:"
      echo "   ${dScripts}/${calc_drydep_script}"
      echo "  Stopping Script ..."
      exit 1
    fi
    echo "~~~ Checking Scripts ~~~"
    if [ ! -f "${dScripts}/${calc_gridcro2d_script}" ]; then
      echo " NCO script file does not exist:"
      echo "   ${dScripts}/${calc_gridcro2d_script}"
      echo "  Stopping Script ..."
      exit 1
    fi
    echo "~~~ Checking Scripts ~~~"
    if [ ! -f "${dScripts}/${calc_metcro2d_script}" ]; then
      echo " NCO script file does not exist:"
      echo "   ${dScripts}/${calc_metcro2d_script}"
      echo "  Stopping Script ..."
      exit 1
    fi
    echo "~~~ Checking Scripts ~~~"
    if [ ! -f "${dScripts}/${calc_metcro3d_script}" ]; then
      echo " NCO script file does not exist:"
      echo "   ${dScripts}/${calc_metcro3d_script}"
      echo "  Stopping Script ..."
      exit 1
    fi


    ## DO THE WORK
    # make basefile with time
    echo "~~~ BASEFILE ~~~"
    ncgen -k nc4 -o ${dTMP}/${fBASEDEF_NC} ${fBASEDEF_TXT}
    ## ncap2 -A -v -S /media/neumannd/work_main/81_CERA/11_scripts/calc_gridcro2d.nco gridcro2d/test.nc tist.nc
    cd ${dScripts}
    ./setTime.R ${DATE} ${dTMP}/${fBASEDEF_NC} ${dTMP}/${fBASEDEF_NC}
    cd ${dCURR}

    # GRIDCRO2D -> LWMASK -> time independent???
    echo "~~~ GRIDCRO2D ~~~"
    ncwa -O -a TSTEP,LAY ${dMET}/${fGRIDCRO2D} ${dTMP}/grid_${fTMP}
    ncap2 -O -v -S ${dScripts}/${calc_gridcro2d_script} ${dTMP}/grid_${fTMP} ${dTMP}/grid2_${fTMP}
    ncatted -h -a ,global,d,, -a cell_methods,,d,, ${dTMP}/grid2_${fTMP}
    ncrename -d ROW,y -d COL,x -v z_land_mask,land_mask -v z_land_frac,land_frac ${dTMP}/grid2_${fTMP}
    ncks -A -a ${dTMP}/grid2_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/grid_${fTMP} ${dTMP}/grid2_${fTMP}


    # GRIDCRO3D
    echo "~~~ GRIDDOT2D ~~~"
    ncwa -O -a TSTEP,LAY ${dMET}/${fGRIDDOT2D} ${dTMP}/grid_${fTMP}
    ncap2 -O -v -S ${dScripts}/${calc_griddot2d_script} ${dTMP}/grid_${fTMP} ${dTMP}/grid2_${fTMP}
    ncatted -h -a ,global,d,, -a cell_methods,,d,, ${dTMP}/grid2_${fTMP}
    ncks -A -a ${dTMP}/grid2_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/grid_${fTMP} ${dTMP}/grid2_${fTMP}


    # CONC
    echo "~~~ CONC ~~~"
    ncap2 -O -v -S ${dScripts}/${calc_conc_script} $dCCTM/$fCONC ${dTMP}/conc_${fTMP}
    ## ncap2 -O -v -S ${dScripts}/${calc_conc_script} $dCCTM/$fCONC ${dTMP}/tist.nc
    ncatted -h -a ,global,d,, ${dTMP}/conc_${fTMP}
    ncks -O --no_rec_dmn TSTEP ${dTMP}/conc_${fTMP} ${dTMP}/conc_${fTMP}
    ncrename -d layer,z -d ROW,y -d COL,x ${dTMP}/conc_${fTMP}
    ncks -A -a ${dTMP}/conc_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/conc_${fTMP}


    # WETDEP1
    echo "~~~ WETDEP ~~~"
    ## ncap2 -A -v -S ${dScripts}/${calc_wetdep_script} $dCCTM/$fWETDEP ${dTMP}/${fTMP}
    ncap2 -O -v -S ${dScripts}/${calc_wetdep_script} $dCCTM/$fWETDEP ${dTMP}/wetdep_${fTMP}
    ncatted -h -a ,global,d,, ${dTMP}/wetdep_${fTMP}
    ncrename -d TSTEP,time -d LAY,z -d ROW,y -d COL,x ${dTMP}/wetdep_${fTMP}
    ncks -A -a ${dTMP}/wetdep_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/wetdep_${fTMP}


    # DRYDEP
    echo "~~~ DRYDEP ~~~"
    ## ncap2 -A -v -S ${dScripts}/${calc_drydep_script} $dCCTM/$fDRYDEP ${dTMP}/${fTMP}
    ncap2 -O -v -S ${dScripts}/${calc_drydep_script} $dCCTM/$fDRYDEP ${dTMP}/drydep_${fTMP}
    ncatted -h -a ,global,d,, ${dTMP}/drydep_${fTMP}
    ncrename -d TSTEP,time -d LAY,z -d ROW,y -d COL,x ${dTMP}/drydep_${fTMP}
    ncks -A -a ${dTMP}/drydep_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/drydep_${fTMP}


    # METCRO2D
    echo "~~~ METCRO2D ~~~"
    ncap2 -O -v -S ${dScripts}/${calc_metcro2d_script} $dMET/$fMETCRO2D ${dTMP}/met2d_${fTMP}
    ncatted -h -a ,global,d,, ${dTMP}/met2d_${fTMP}
    ncrename -d TSTEP,time -d LAY,z -d ROW,y -d COL,x ${dTMP}/met2d_${fTMP}
    ncks -A -a ${dTMP}/met2d_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/met2d_${fTMP}


    # METCRO3D
    echo "~~~ METCRO3D ~~~"
    ncap2 -O -v -S ${dScripts}/${calc_metcro3d_script} $dMET/$fMETCRO3D ${dTMP}/met3d_${fTMP}
    ncatted -h -a ,global,d,, ${dTMP}/met3d_${fTMP}
    ncrename -d TSTEP,time -d ROW,y -d COL,x ${dTMP}/met3d_${fTMP}
    ncks -A -a ${dTMP}/met3d_${fTMP} ${dTMP}/${fBASEDEF_NC}
    rm ${dTMP}/met3d_${fTMP}


    # finalize
    echo "~~~ Finalize ~~~"
    ncatted -h -a history,global,d,, ${dTMP}/${fBASEDEF_NC}
    mv ${dTMP}/${fBASEDEF_NC} ${dOUT}/${fOUT}
    
  else
    echo "skipping date ${DATE}"
    #~ echo "${dCCTM}/${fCONC}"
  fi
  
done
