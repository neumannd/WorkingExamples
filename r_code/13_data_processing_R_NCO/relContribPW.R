#' Calculate relative tracer concentrations with R and NCO
#' 
#' We want to calculate relative contrations of tagged tracers with respect
#' to their un-tagged counterparts. Doing just t_a/t_total with NCO or
#' cdo does not work properly because some t_total might be 0 and we do not
#' want to introduce NaNs. Therefore, we first copy the file via NCO (creating
#' new variables and then we do the calculations via R. We do the first step
#' via NCO because creating a new netCDF file via R is more work :-) .
#' 
#' In detail, we create our own calculation script for ncap2, call ncap2, and
#' calculate in R 't_a/t_total' for all 't_total != 0' and 't_total != NA'.
#' 
#' @author Daniel Neumann
#' @date 2017-09-19


# load libraries -----
library('ncdf4')

# set control parameters ----
WORK='A'

prefixIn='m_p_'
prefixOt='m_r_'
suffixIn=paste0('_PW_WORK', WORK, '_merge_mean_2012.nc')
suffixOt=suffixIn

gridNames = c('fine', 'coarse')


# variables to process ----
varnames = list()
varnames$bio = array(c('rel_phos_wP_bio','mole_concentration_of_phosphate_from_warnow_P_in_seawater','mole_concentration_of_ammonium_in_seawater',
                       'rel_dia_wP_bio','mole_concentration_of_diatoms_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_diatoms_expressed_as_nitrogen_in_seawater',
                       'rel_flag_wP_bio','mole_concentration_of_flagellates_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_flagellates_expressed_as_nitrogen_in_seawater',
                       'rel_cyan_wP_bio','mole_concentration_of_cyanobacteria_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_cyanobacteria_expressed_as_nitrogen_in_seawater',
                       'rel_zoo_wP_bio','mole_concentration_of_zooplankton_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_zooplankton_expressed_as_nitrogen_in_seawater',
                       'rel_pzoo_wP_bio','mole_concentration_of_protozooplankton_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_protozooplankton_expressed_as_nitrogen_in_seawater',
                       'rel_det_wP_bio','mole_concentration_of_detritus_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_detritus_expressed_as_nitrogen_in_seawater',
                       'rel_biomass_wP_bio','mole_concentration_of_biomass_expressed_as_nitrogen_from_warnow_P_in_seawater','mole_concentration_of_biomass_expressed_as_nitrogen_in_seawater',
                       'rel_amm_wN_bio','mole_concentration_of_ammonium_from_warnow_N_in_seawater','mole_concentration_of_ammonium_in_seawater',
                       'rel_nit_wN_bio','mole_concentration_of_nitrate_from_warnow_N_in_seawater','mole_concentration_of_nitrate_in_seawater',
                       'rel_dia_wN_bio','mole_concentration_of_diatoms_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_diatoms_expressed_as_nitrogen_in_seawater',
                       'rel_flag_wN_bio','mole_concentration_of_flagellates_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_flagellates_expressed_as_nitrogen_in_seawater',
                       'rel_cyan_wN_bio','mole_concentration_of_cyanobacteria_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_cyanobacteria_expressed_as_nitrogen_in_seawater',
                       'rel_zoo_wN_bio','mole_concentration_of_zooplankton_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_zooplankton_expressed_as_nitrogen_in_seawater',
                       'rel_pzoo_wN_bio','mole_concentration_of_protozooplankton_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_protozooplankton_expressed_as_nitrogen_in_seawater',
                       'rel_det_wN_bio','mole_concentration_of_detritus_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_detritus_expressed_as_nitrogen_in_seawater',
                       'rel_don_wN_bio','mole_concentration_of_labile_dissolved_organic_nitrogen_from_warnow_N_expressed_as_nitrogen_in_seawater','mole_concentration_of_labile_dissolved_organic_nitrogen_expressed_as_nitrogen_in_seawater',
                       'rel_biomass_wN_bio','mole_concentration_of_biomass_expressed_as_nitrogen_from_warnow_N_in_seawater','mole_concentration_of_biomass_expressed_as_nitrogen_in_seawater'),
                     dim = c(3,18))
varnames$ben = array(c('rel_nit_ship_ben','mole_concentration_of_nitrogen_from_warnow_P_in_the_sediment','mole_concentration_of_nitrogen_in_the_sediment',
                       'rel_nit_river_ben','mole_concentration_of_nitrogen_from_warnow_N_in_the_sediment','mole_concentration_of_nitrogen_in_the_sediment'),
                     dim = c(3,2))


# variables to remove ----
rmvar = list()
rmvar$bio = c('mole_concentration_of_phosphate_in_seawater',
              'mole_concentration_of_silicate_in_seawater',
              'mole_concentration_of_detritus_expressed_as_silicate_in_seawater')
rmvar$ben = c('mole_concentration_of_silicate_in_the_sediment')


# iterate grids
for (iG in gridNames) {
  for (iT in c('bio', 'ben')) {
    # information for user
    print(paste0('do: ', iG, ', ', iT))
    
    # make file names
    fileIn=paste0(prefixIn,iT,'dat_',iG,suffixIn)
    fileOt=paste0(prefixOt,iT,'dat_',iG,suffixOt)
    
    
    # process file via NCO ----
    # user information
    print('  copy file')
    
    # create ncap2 script
    if (iT == 'bio') {
      calcScript = c(c('mole_concentration_of_biomass_expressed_as_nitrogen_in_seawater=mole_concentration_of_diatoms_expressed_as_nitrogen_in_seawater+mole_concentration_of_flagellates_expressed_as_nitrogen_in_seawater+mole_concentration_of_cyanobacteria_expressed_as_nitrogen_in_seawater+mole_concentration_of_zooplankton_expressed_as_nitrogen_in_seawater+mole_concentration_of_protozooplankton_expressed_as_nitrogen_in_seawater+mole_concentration_of_detritus_expressed_as_nitrogen_in_seawater;',
                       'mole_concentration_of_biomass_expressed_as_nitrogen_from_warnow_P_in_seawater=mole_concentration_of_diatoms_expressed_as_nitrogen_from_warnow_P_in_seawater+mole_concentration_of_flagellates_expressed_as_nitrogen_from_warnow_P_in_seawater+mole_concentration_of_cyanobacteria_expressed_as_nitrogen_from_warnow_P_in_seawater+mole_concentration_of_zooplankton_expressed_as_nitrogen_from_warnow_P_in_seawater+mole_concentration_of_protozooplankton_expressed_as_nitrogen_from_warnow_P_in_seawater;',
                       'mole_concentration_of_biomass_expressed_as_nitrogen_from_warnow_N_in_seawater=mole_concentration_of_diatoms_expressed_as_nitrogen_from_warnow_N_in_seawater+mole_concentration_of_flagellates_expressed_as_nitrogen_from_warnow_N_in_seawater+mole_concentration_of_cyanobacteria_expressed_as_nitrogen_from_warnow_N_in_seawater+mole_concentration_of_zooplankton_expressed_as_nitrogen_from_warnow_N_in_seawater+mole_concentration_of_protozooplankton_expressed_as_nitrogen_from_warnow_N_in_seawater+mole_concentration_of_detritus_expressed_as_nitrogen_from_warnow_N_in_seawater;'),
                     paste(varnames[[iT]][1,], '=', varnames[[iT]][2,], '.float();', sep = ''),
                     paste(varnames[[iT]][2,], '=', varnames[[iT]][2,], '.float();', sep = ''),
                     paste(varnames[[iT]][3,1:(dim(varnames[[iT]])[2]/2)], '=', varnames[[iT]][3,1:(dim(varnames[[iT]])[2]/2)], '.float();', sep = '')
                     )
    } else {
      calcScript = c(paste(varnames[[iT]][1,], '=', varnames[[iT]][2,], '.float();', sep = ''),
                     paste(varnames[[iT]][2,], '=', varnames[[iT]][2,], '.float();', sep = ''),
                     paste(varnames[[iT]][3,1:(dim(varnames[[iT]])[2]/2)], '=', varnames[[iT]][3,1:(dim(varnames[[iT]])[2]/2)], '.float();', sep = '')
                     )
    }
    write(calcScript, paste0('calcScript_', iT, '_', iG, '_WORK', WORK, '.nco'))

    # call ncap2
    print(paste('ncap2 -O -S', paste0('calcScript_', iT, '_', iG, '_WORK', WORK, '.nco'), fileIn, fileOt, sep = ' '))
    system(paste('ncap2 -O -S', paste0('calcScript_', iT, '_', iG, '_WORK', WORK, '.nco'), fileIn, fileOt, sep = ' '))

    
    # process netCDF file via R ----
    # open file
    ncId = nc_open(fileOt, write=TRUE)

    # user information
    print('  recalc vars')
    
    # iterate all relevant variables in the file
    for (iV in 1:(dim(varnames[[iT]])[2])) {
      print(paste0('   var: ', iV))
      numerator = ncvar_get(ncId, varnames[[iT]][2,iV])
      denominator = ncvar_get(ncId, varnames[[iT]][3,iV])

      newvars = denominator

      for (i1 in 1:length(denominator)) {
        if(!is.na(denominator[i1])) {
          if (denominator[i1] > 0) {
            newvars[i1] = numerator[i1] / denominator[i1]
          }
        }
      }

      ncvar_put(ncId, varnames[[iT]][1,iV], newvars)
    }

    # user information
    print('  recalc finished; closing file')
    
    # close netCDF file
    nc_close(ncId)
  }

}