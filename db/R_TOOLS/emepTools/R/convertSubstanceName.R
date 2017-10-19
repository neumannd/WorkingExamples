#' Convert the name of a variable into a convenient form.
#' 
#' shortEMEP: sum formular of the substance as used in the EMEP ASCII
#'            export files; standard sum formular with - and +; no spaces
#' shortDB:   sum formular of the substance without - and +; sometimes
#'            shorter than the EMEP short format such as susp_part_mat
#'            instead of susp_part_matter; sometimes more information as
#'            wspd10m instead of wspd; no spaces;
#' long:      long name of the substance as used in the variable definitions
#'            in the EMEP ASCII export file (header, line 13 and following) 
#'            (often IUPAC convention); no spaces;
#'            
#' @param titleIn ; character ; a variable name which should be converted into 
#'    another format
#' @param conv2which ; character ; (optional) defines in which format titleIn 
#'    should be converted; It can be choosen from "long", "short", "shortEMEP",
#'    "shortDB" and "" whereas "" and "short" are equal to "shortDB". If
#'    set to another value a warning is thrown and titleOut=titleIn is 
#'    returned. The default value of conv2which is "shortDB".
#' @return titleOut ; character ; the variable name in the format defined by 
#'    conv2which; by default 
#' @author Daniel Neumann, Helmholtz-Zentrum Geesthacht
#'    \email{daniel.neumann@___.de}
#' @note If titleIn is unknown then titleOut = titleIn. 
#' @export
#' @format R Code
convertSubstanceName <- function(titleIn, conv2which="") {
  ##
  # col 1: short name; EMEP files, data columns
  # col 2: short name; no special characters as +/-
  # col 3: long name; EMEP files, variable description in the header
  # col 4: long name; alternative name
  # col 5: long name; official table to EMEP measurement units
  titles = c("SO2", "SO2" ,"sulphur_dioxide", "sulphur_dioxide", "Sulphur dioxide", 
             "SO4--", "SO4", "sulphate_total", "sulphate", "Sulphate total", 
             "XSO4--", "XSO4", "sulphate_corrected", "sulphate_corrected", "Sulphate corrected for sea salt contribution", 
             "PO4---", "SO4", "phosphate", "phosphate", "Phosphate", 
             
             "NH3", "NH3", "ammonia", "ammonia", "Ammonia", 
             "NH4+", "NH4", "ammonium", "ammonium", "Ammonium", 
             "NH3+NH4", "SNH4", "sum_ammonia_and_ammonium", "sum_ammonia_and_ammonium", "Sum ammonia and ammonium", 
             
             "NO", "NO", "nitrogen_oxide", "nitrogen_monoxide", "Nitrogen Oxide", 
             "NO2", "NO2", "nitrogen_dioxide", "nitrogen_dioxide_plus", "Nitrogen Dioxide", 
             "N2O", "N2O", "dinitrogen_oxide", "nitrous_oxide", "Dinitrogen Oxide", 
             "NO3-", "NO3", "nitrate", "nitrate", "Nitrate", 
             "HNO2", "HNO2", "nitrous_acid", "nitrous_acid", "Nitrous Acid",
             "HNO3", "HNO3", "nitric_acid", "nitric_acid", "Nitric Acid",
             "HNO3+NO3", "SNO3", "sum_nitric_acid_and_nitrate", "sum_nitric_acid_and_nitrate", "Sum nitric acid and nitrate", 
             
             "O3", "O3", "ozone", "ozone", "Ozone", 
             
             "CH4", "CH4", "methane", "methane", "Methane", 
             "MSA", "MSA", "methanesulfonic_acid", "methanesulfonic_acid", "Methanesulfonic Acid", 
             
             "CO", "CO", "carbon_oxide", "carbon_monoxide", "Carbon Oxide", 
             "CO2", "CO2", "carbon_dioxide", "carbon_dioxide", "Carbon Dioxide", 
             
             "Mg++", "Mg", "magnesium", "magnesium", "Magnesium", 
             "Ca++", "Ca", "calcium", "calcium", "Calcium", 
             "Na+", "Na", "sodium", "sodium", "Sodium", 
             "K+", "K", "potassium", "potassium", "Potassium", 
             "Cl-", "Cl", "chloride", "chlorine", "Chloride", 
             "Br-", "Br", "bromide", "bromide", "Bromide", 
             "HCl", "HCl", "hydrochloric_acid", "hydrochloric_acid", "Hydrochloric Acid", 
             "H+", "H", "acidity", "acidity", "Acidity", 
             
             "Hg", "Hg", "total_mercury", "mercury", "Mercury", 
             "TGM", "TGM", "total_gaseous_mercury", "total_gaseous_mercury", "Total Gaseous Mercury", 
             "RGM", "GOM", "gaseous_oxidized_mercury", "reactive_gaseous_mercury", "Reactive Gaseous Mercury", 
             "GEM", "GEM", "elemental_gaseous_mercury", "gaseous_elemental_mercury", "Gaseous Elemental Mercury",
             "PBM", "PBM", "particle_bound_mercury", "particle_bound_mercury", "Particle Bound Mercury", 
             "Al", "Al", "aluminium", "aluminium", "Aluminium", 
             "Al27", "Al27", "aluminium_27", "aluminium_27", "Aluminium 27", 
             "Sb", "Sb", "antimony", "antimony", "Antimony", 
             "As", "As", "arsenic", "arsenic", "Arsenic", 
             "Ba", "Ba", "barium", "barium", "Barium", 
             "Cd", "Cd", "cadmium", "cadmium", "Cadmium", 
             "Cr", "Cr", "chromium", "chromium", "Chromium", 
             "Co", "Co", "cobalt", "cobalt", "Cobalt", 
             "Cu", "Cu", "copper", "copper", "Copper", 
             "Fe", "Fe", "iron", "iron", "Iron", 
             "Fe57", "Fe57", "iron_57", "iron_57", "Iron 57", 
             "Pb", "Pb", "lead", "lead", "Lead", 
             "Li+", "Li", "lithium", "lithium", "Lithium", 
             "Mn", "Mn", "manganese", "manganese", "Manganese", 
             "Ni", "Ni", "nickel", "nickel", "Nickel",
             "Ni58", "Ni58", "nickel", "nickel", "Nickel 58", 
             "Ni60", "Ni60", "nickel", "nickel", "Nickel 60", 
             "Ru", "Ru", "ruthenium", "ruthenium", "Ruthenium", 
             "Sc", "Sc", "scandium", "scandium", "Scandium", 
             "Se", "Se", "selenium", "selenium", "Selenium", 
             "Sr", "Sr", "strontium", "strontium", "Strontium", 
             "Sn", "Sn", "tin", "tin", "Tin", 
             "Ti", "Ti", "titanium", "titan", "Titanium", 
             "Tl", "Tl", "thallium", "thallium", "Thallium", 
             "U", "U", "uranium", "uranium", "Uranium", 
             "V", "V", "vanadium", "vanadium", "Vanadium", 
             "Zn", "Zn", "zinc", "zinc", "Zinc", 
             
             "pm10_mass", "pm10_mass", "pm10_mass", "PM10", "PM10 mass", 
             "pm25_mass", "pm25_mass", "pm25_mass", "PM2.5", "PM2.5 mass", 
             "pm1_mass", "pm1_mass", "pm1_mass", "PM1", "PM1.0 mass",
             "susp_part_matter", "susp_part_mat", "suspended_particulate_matter", "SPM", "Suspended particulate matter", 
             "particle_number_concentration", "pnc", "particle_number_concentration", "PNC", "particle number concentration",
             "EC", "EC", "elemental_carbon", "elemental_carbon", "EC", 
             "OC", "OC", "organic_carbon", "organic_carbon", "OC", 
             "XOC", "XOC", "organic_carbon_corrected", "organic_carbon_corrected", "OC corrected", 
             "TC", "TC", "total_carbon", "total_carbon", "TC",  
             "XTC", "XTC", "total_carbon_corrected", "total_carbon_corrected", "TC corrected", 
             "BC", "BC", "black_carbon", "black_carbon", "BC",
             
             "mm", "precip", "precipitation_amount", "precipitation", "Precipitation amount", 
             "mm_off", "precip_off", "precipitation_amount_off", "precipitation_off", "Precipitation amount official gauge", 
             "k", "Cond", "conductivity", "conductivity", "Conductivity", 
             "pH", "pH", "pH", "pH", "pH",
             
             "rh", "RH", "relative_humitidty", "relative_humidity", "Relative Humidity", 
             "p", "P", "pressure", "atmospheric_pressure", "Pressure", 
             "T", "T", "temperature", "temperature", "Temperature", 
             "T_d", "Td", "dewpoint_temperature", "dewpoint_temperature", "dewpoint_Temperature", 
             "wdir", "wdir10m", "wind_direction", "wind_direction", "Wind Direction", 
             "wspd", "wspd10m", "wind_speed", "wind_speed", "Wind Speed",
             
             "heav_met_dep", "heav_met_dep", "heavy_metal_deposition", "heavy_metal_deposition", "Heavy metals deposition", 
             "POP_dep", "POP_dep", "POP_deposition", "POP_deposition", "POP deposition", 
             
             "", "", "", "", ""
  )
  # "", "", "", "", "", 
  
  # number of variables for which name-conversion is possible
  nTitles = length(titles)/5   
  # Make from the 1-dim titles array a 2-dim titles array
  #  -> nice table with rows corresponding to different formats
  #     and columns correstponding to different substances
  dim(titles) = c(5, nTitles)
  # "rotate" table (actually we transpose it); We want rows and columns
  # to be exchanged.
  titles = t(titles)
  
  titleOut = ""
  
  # Which formats are allowed to chose?
  formats = c("long",
              "short",
              "shortEMEP",
              "shortDB",
              "")
  
  # Test whether a valid format is parsed (conv2which)
  if (sum(conv2which == formats)) {
    colsIn = 1:5    # columns in which it is looked for titleIn
    colOut = 0      # If titleIn is found one column: From which
    # other column should titleOut be chosen?
    # We have transposed 'titles'. Therefore the 'columns' are
    # 'rows' actually.
    
    # If the format 'short' or no format ("") were parsed, conv2which
    # is set to "shortDB". "shortDB" will cause the least problems. 
    # A '+' or '-' could cause problems in some cases because it could
    # be regarded as a special character.
    if (sum(conv2which == c("", "short"))) conv2which = "shortDB"
    
    # Inquire which format is the wished output format. Depending on
    # the output format 'colsOut' is set.
    if (conv2which == "shortEMEP") {
      colOut = 1
    } else if (conv2which == "shortDB") {
      colOut = 2
    } else if (conv2which == "long") {
      colOut = 3
    } else { # redundant, because if(sum(conv2which == formats)) should have
      # catched this case already. However, one never knows ... :-) .
      warning("Format to convert to titleIn is unknown!")
    }
    
    ## We will go throught all rows of titles (while ... ) till all catalogued
    ## titles are past (i1 < nTitles) or till a row containing titleIn is 
    ## found (!found).
    ## Within each row we go through each column (for ...) defined in colsIn.
    ## If titleIn is found in the current row i1 (titles[i1, i2] == titleIn)
    ## the titleOut is set to the value from this row i1 and column colOut 
    ## in the titles array.
    # set some initial values
    i1 = 0
    found = FALSE
    while (i1 < nTitles && !found) {
      # increase iterator (row number)
      i1 = i1 + 1
      # go through each column
      for (i2 in colsIn) {
        # if titleIn is found in titles
        if (titles[i1, i2] == titleIn) {
          found = TRUE
          titleOut = titles[i1, colOut]
        }
      }
    }
    
    # If titleIn was not found in the titles array, titlesOut will be set
    # to titlesIn
    if (!found) titleOut = titleIn
    
  } else { # If conv2which is no element of formats we do the following:
    titleOut = titleIn
    warning("Format to convert to titleIn is unknown!")
  }
  
  # print(paste(titleIn, '->', titleOut, sep = ' '))
  
  # parse titleOut back to the user
  return(titleOut)
}
