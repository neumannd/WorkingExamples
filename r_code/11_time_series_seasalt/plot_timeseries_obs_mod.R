#' Creates a nices time series plot
#'
#' WORK IN PROGRESS
#' 
#' @author Daniel Neumann, daniel.neumannATioMINUSwarnemuendeDOTde
#'
#' @param data.mod data.frame containing model data to plot
#' @param data.obs data.frame containing observational data to plot
#' @param type.mod string or array/list of strings; same as 'type' in 'plot'
#' @param type.obs string or array/list of strings; same as 'type' in 'plot'
#' @param col.mod string or array/list of strings; same as 'col' in 'plot'
#' @param pch.mod numeric/integer or array/list of them; same as 'pch' in 'plot'
#' @param cex.mod numeric/integer or array/list of them; same as 'cex' in 'plot'
#' @param lty.mod 
#' @param lwd.mod numeric/integer or array/list of them; same as 'lwd' in 'plot'
#' @param bg.mod string or array/list of strings; same as 'bg' in 'plot'
#' @param col.obs string or array/list of strings; same as 'col' in 'plot'
#' @param pch.obs numeric/integer or array/list of them; same as 'pch' in 'plot'
#' @param cex.obs numeric/integer or array/list of them; same as 'cex' in 'plot'
#' @param lty.obs 
#' @param lwd.obs numeric/integer or array/list of them; same as 'lwd' in 'plot'
#' @param bg.obs string or array/list of strings; same as 'bg' in 'plot'
#' @param x.align.mod TODO
#' @param x.align.obs TODO
#' @param x.lim.mod TODO
#' @param x.lim.obs TODO
#' @param x.inter.width.mod TODO
#' @param x.inter.width.obs TODO
#' @param xLab TODO
#' @param xLabTxt TODO
#' @param xLabLoc TODO
#' @param xLabLine TODO
#' @param yLab TODO
#' @param yLabTxt TODO
#' @param yLabLoc TODO
#' @param yLabLine TODO
#' @param xAxisTick TODO
#' @param xAxisTickLoc TODO
#' @param xAxisTickLab TODO
#' @param xAxisTickTck TODO
#' @param yAxisTick TODO
#' @param yAxisTickLoc TODO
#' @param yAxisTickLab TODO
#' @param yAxisTickTck TODO
#' @param xAxisLab TODO
#' @param xAxisLabLab TODO
#' @param xAxisLabLoc TODO
#' @param yAxisLab TODO
#' @param yAxisLabLab TODO
#' @param yAxisLabLoc TODO
#' @param header TODO
#' @param headerLab TODO
#' @param headerLine TODO
#' @param xlim TODO
#' @param ylim TODO
#'
#' @return nothin -> a plot
#' @export
#'
#' @examples
#'   TODO
plot_timeseries_obs_mod = function(data.mod, data.obs,
                                   type.mod = 'l', type.obs = 'p',
                                   col.mod=NULL, pch.mod=NULL, cex.mod=NULL, lty.mod=NULL, lwd.mod=NULL, bg.mod=NULL,
                                   col.obs=NULL, pch.obs=NULL, cex.obs=NULL, lty.obs=NULL, lwd.obs=NULL, bg.obs=NULL,
                                   x.align.mod = 'center',  x.align.obs = 'center', 
                                   x.lim.mod = NULL, x.lim.obs = NULL,
                                   x.inter.width.mod = -1, x.inter.width.obs = -1,
                                   xLab=TRUE, xLabTxt='time', xLabLoc=NULL, xLabLine=1.6,
                                   yLab=TRUE, yLabTxt='data', yLabLoc=NULL, yLabLine=1.6,
                                   xAxisTick=TRUE, xAxisTickLoc=NULL, xAxisTickLab=FALSE, xAxisTickTck = -0.03,
                                   yAxisTick=TRUE, yAxisTickLoc=NULL, yAxisTickLab=FALSE, yAxisTickTck = -0.03,
                                   xAxisLab=FALSE, xAxisLabLab=TRUE, xAxisLabLoc=NULL,
                                   yAxisLab=FALSE, yAxisLabLab=TRUE, yAxisLabLoc=NULL,
                                   header=TRUE, headerLab='NO HEADER', headerLine=-1,
                                   xlim = NULL, ylim = NULL) {
  
  # xLabLoc and yLabLoc not implemented
  
  # def_cols = c('blue', 'red', 'orange', 'green', 'pink')
  def_cols = c('cyan', 'orange', 'darkviolet', 'green', 'red', 'darkgreen')
  def_pchs = c(16, 1, 8, 4, 3, 5)
  def_cexs = c(0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
  def_bgs = def_cols # 'white'
  # def_ltys = c(1,5,2,6,3)
  def_ltys = c('solid', 'longdash', 'dashed', 'twodash', 'dotdash', 'dotted')
  def_lwds = c(1,1,1,1,1,1)
  n_distinct = 6
  synonymes.align = list('center' = c('centre', 'center'),
                         'start' = c('start', 'left', 'first'),
                         'stop' = c('end', 'stop', 'right', 'last'))
  synonymes.type = list('p' = c('p', 'points', 'point'),
                        'l' = c('l', 'lines', 'line'),
                        's' = c('s', 'steps', 'step'),
                        'b' = c('b', 'bars', 'bar'))
  
  
  ## PREPARE DATA
  l.data.mod = ensure_list.data(data.mod)
  for (iN in names(l.data.mod)) if(dim(l.data.mod[[iN]])[1]==0) l.data.mod[[iN]]=NULL
  names.mod = names(l.data.mod)
  n_columns.mod = length(names.mod)
  if(length(l.data.mod)==0) no.data.mod = TRUE else no.data.mod = FALSE 
  
  l.data.obs = ensure_list.data(data.obs)
  for (iN in names(l.data.obs)) if(dim(l.data.obs[[iN]])[1]==0) l.data.obs[[iN]]=NULL
  names.obs = names(l.data.obs)
  n_columns.obs = length(names.obs)
  if(length(l.data.obs)==0) no.data.obs = TRUE else no.data.obs = FALSE
  
  
  ## get y_min and y_max values
  if (!is.null(ylim)) {
    y.min = ylim[1]; y.max = ylim[2]
  } else {
    y.min = 0; y.max = -Inf
    if(!no.data.mod) for (iN in names.mod) y.max = max(y.max, max(l.data.mod[[iN]]$value, na.rm = TRUE))
    if(!no.data.obs) for (iN in names.obs) y.max = max(y.max, max(l.data.obs[[iN]]$value, na.rm = TRUE))
  }
  
  if (!is.null(xlim)) {
    t.min = xlim[1]; t.max = xlim[2]
  } else {
    t.min = Inf; t.max = -Inf
    if(!no.data.mod) for (iN in names.mod) {
      t.min = min(t.min, min(l.data.mod[[iN]]$time, na.rm = TRUE))
      t.max = max(t.max, max(l.data.mod[[iN]]$time, na.rm = TRUE))}
    if(!no.data.obs) for (iN in names.obs) {
      t.min = min(t.min, min(l.data.obs[[iN]]$time, na.rm = TRUE))
      t.max = max(t.max, max(l.data.obs[[iN]]$time, na.rm = TRUE))}
  }
  
  ## get limits
  if(!no.data.mod) f.t.lim.mod = ensure_list.limits(x.lim.mod, c(t.min, t.max), names.mod) else f.t.lim.mod = NULL
  if(!no.data.obs) f.t.lim.obs = ensure_list.limits(x.lim.obs, c(t.min, t.max), names.obs) else f.t.lim.obs = NULL
  
  # ERROR TESTING ----
  ## construct 'l_col'
  if(!no.data.mod) l.col.mod = ensure_list.default(col.mod, def_cols, names.mod) else l.col.mod = NULL
  if(!no.data.obs) l.col.obs = ensure_list.default(col.obs, def_cols, names.obs) else f.t.lim.obs = NULL
  
  ## construct 'l.bg'
  if(!no.data.mod) l.bg.mod = ensure_list.default(bg.mod, def_bgs, names.mod) else l.bg.mod = NULL
  if(!no.data.obs) l.bg.obs = ensure_list.default(bg.obs, def_bgs, names.obs) else l.bg.obs = NULL
  
  ## construct 'l_pch'
  if(!no.data.mod) l.pch.mod = ensure_list.default(pch.mod, def_pchs, names.mod) else l.pch.mod = NULL
  if(!no.data.obs) l.pch.obs = ensure_list.default(pch.obs, def_pchs, names.obs) else l.pch.obs = NULL
  
  ## construct 'l_cex'
  if(!no.data.mod) l.cex.mod = ensure_list.default(cex.mod, def_cexs, names.mod) else l.cex.mod = NULL
  if(!no.data.obs) l.cex.obs = ensure_list.default(cex.obs, def_cexs, names.obs) else l.cex.obs = NULL
  
  ## construct 'l_lwd'
  if(!no.data.mod) l.lwd.mod = ensure_list.default(lwd.mod, def_lwds, names.mod) else l.lwd.mod = NULL
  if(!no.data.obs) l.lwd.obs = ensure_list.default(lwd.obs, def_lwds, names.obs) else l.lwd.obs = NULL
  
  ## construct 'l_lty'
  if(!no.data.mod) l.lty.mod = ensure_list.default(lty.mod, def_ltys, names.mod) else l.lty.mod = NULL
  if(!no.data.obs) l.lty.obs = ensure_list.default(lty.obs, def_ltys, names.obs) else l.lty.obs = NULL
  
  ## construct 'type'
  if(!no.data.mod) l.type.mod = ensure_list.default(type.mod, 'l', names.mod, synonymes = synonymes.type) else l.type.mod = NULL
  if(!no.data.obs) l.type.obs = ensure_list.default(type.obs, 'p', names.obs, synonymes = synonymes.type) else l.type.obs = NULL
  
  ## construct 'x.align'
  if(!no.data.mod) c.t.align.mod = ensure_list.default(x.align.mod, 'center', names.mod, synonymes = synonymes.align) else c.t.align.mod = NULL
  if(!no.data.obs) c.t.align.obs = ensure_list.default(x.align.obs, 'center', names.obs, synonymes = synonymes.align) else c.t.align.obs = NULL
  
  
  # PREPARE TIME ----
  #' We want to plot one time series with bars and 1+ times series with points.
  #' The time, at which one point is located, has to be in the middle of a bar
  #' (with respect to the time axis):
  #' 
  #'      x
  #'     ___
  #'    |   |
  #'    |   |
  #' ___|   |_____
  #' 
  #'      ^
  #'      |
  #'   time a (center of the bar '___' but location of the 'x')
  #'   
  #' Now, each bar needs two time points: one start and one end; the respective
  #' point is located at (start+end)/2. Hence, we need n+1 times for n bars.
  #' But 'data' contains only n time steps. Thus, we need to get the n+1_th or
  #' 0_th time from somewhere.
  #' 
  #' Moreover, the points might be point values or average values. In the first
  #' case, data$time are probably the times of the data points. In the latter 
  #' case, however, data$time might be the start, the center, or the end of the
  #' averaging interval.
  #'  (1) 'center': we plot (data$time, data$data_point_value)
  #'  (2) 'start': we plot 'for all i from 1 to n:
  #'                ((data$time[i]+data$time[i+1])/2, data$data_point_value[i])
  #'               => we are missing the value data$time[n+1]
  #'  (3) 'end': we plot 'for all i from 1 to n:
  #'                ((data$time[i-1]+data$time[i])/2, data$data_point_value[i])
  #'               => we are missing the value data$time[0]
  #'
  #' Thus, we need each one extra time value in the 'start' and 'end' cases. In
  #' the 'center' case we even need two extra time values for the bar plots
  #' because they extend to the left and to the right beyond the data$time 
  #' axis. 
  #' 
  #' We approach this problem with 'x.align.mod', 
  #' 'x.inter.width.mod', and 'x.lim.mod':
  #'  (1) x.align.mod: set to 'start', 'end', or 'center'
  #'  (3) x.inter.width.mod: Set the width of the bars
  #'    (3a) >0 : value = width of bars/steps
  #'    (3b) ==0: like center
  #'    (3c) -1: min diff between (l.data.mod[[param]]$value), different for each param
  #'    (3d) -2: min diff between (l.data.mod[[ALL]]$value), same for each param
  #'    (3d) -2: min(min diff between (l.data.mod[[ALL]]$value), min diff between (l.data.obs[[ALL]]$value)), same for each param
  #'  (4) x.lim.mod: plot only range between [1] and [2]
  
  ## get basic time axis data
  if(!no.data.mod) t.minmax.diff.mod = calc.t.minmax.diff(l.data.mod, f.t.lim.mod, names.mod) else t.minmax.diff.mod = NULL
  if(!no.data.obs) t.minmax.diff.obs = calc.t.minmax.diff(l.data.obs, f.t.lim.obs, names.obs) else t.minmax.diff.obs = NULL
  
  if(!no.data.mod) t.inter.width.mod = calc.t.inter.width(x.inter.width.mod, t.minmax.diff.mod, t.minmax.diff.obs, names.mod) else t.inter.width.mod = NULL
  if(!no.data.obs) t.inter.width.obs = calc.t.inter.width(x.inter.width.obs, t.minmax.diff.obs, t.minmax.diff.mod, names.obs) else t.inter.width.obs = NULL
  
  
  ## create time bounds in date format
  ll.data.mod=list()
  ll.data.obs=list()
  if(!no.data.mod) for (iN in names.mod) {
    ll.data.mod[[iN]] = generated_ts_plot_arrays(l.data.mod[[iN]]$time, l.data.mod[[iN]]$value, 
                                                 l.type.mod[[iN]], c.t.align.mod[[iN]],
                                                 t.inter.width.mod[[iN]])
  }
  if(!no.data.obs) for (iN in names.obs) {
    ll.data.obs[[iN]] = generated_ts_plot_arrays(l.data.obs[[iN]]$time, l.data.obs[[iN]]$value, 
                                                 l.type.obs[[iN]], c.t.align.obs[[iN]],
                                                 t.inter.width.obs[[iN]])
  }
  
  
  # PLOT ----
  ## base plot
  #' This is an empty plot that has the extend of the final plot but contains
  #' no data.
  plot(c(t.min, t.max), c(y.min, y.max),
       type = 'n', ann = FALSE, ylim = c(y.min, y.max),
       yaxt = 'n', xaxt = 'n')
  
  for (iN in names.obs) {
    if (l.type.obs[[iN]] == 'p') {
      points(ll.data.obs[[iN]]$time, ll.data.obs[[iN]]$value,
             col = l.col.obs[[iN]], bg = l.bg.obs[[iN]],  
             pch = l.pch.obs[[iN]], cex = l.cex.obs[[iN]])
    } else if (l.type.obs[[iN]] == 'l') {
      lines(ll.data.obs[[iN]]$time, ll.data.obs[[iN]]$value,
            col = l.col.obs[[iN]], lty = l.lty.obs[[iN]], lwd = l.lwd.obs[[iN]], 
            cex = l.cex.obs[[iN]])
    } else if (l.type.obs[[iN]] == 'b') {
      polygon(ll.data.obs[[iN]]$time, ll.data.obs[[iN]]$value,
              col = l.col.obs[[iN]], border = FALSE)
    } else if (l.type.obs[[iN]] == 's') {
      lines(ll.data.obs[[iN]]$time, ll.data.obs[[iN]]$value,
            col = l.col.obs[[iN]], lty = l.lty.obs[[iN]], lwd = l.lwd.obs[[iN]], 
            cex = l.cex.obs[[iN]])
    }
  }
  
  for (iN in names.mod) {
    if (l.type.mod[[iN]] == 'p') {
      points(ll.data.mod[[iN]]$time, ll.data.mod[[iN]]$value,
             col = l.col.mod[[iN]], bg = l.bg.mod[[iN]], 
             pch = l.pch.mod[[iN]], cex = l.cex.mod[[iN]])
    } else if (l.type.mod[[iN]] == 'l') {
      lines(ll.data.mod[[iN]]$time, ll.data.mod[[iN]]$value,
            col = l.col.mod[[iN]], lty = l.lty.mod[[iN]], lwd = l.lwd.mod[[iN]], 
            cex = l.cex.mod[[iN]])
    } else if (l.type.mod[[iN]] == 'b') {
      polygon(ll.data.mod[[iN]]$time, ll.data.mod[[iN]]$value,
              col = l.col.mod[[iN]], border = FALSE)
    } else if (l.type.mod[[iN]] == 's') {
      lines(ll.data.mod[[iN]]$time, ll.data.mod[[iN]]$value,
            col = l.col.mod[[iN]], lty = l.lty.mod[[iN]], lwd = l.lwd.mod[[iN]], 
            cex = l.cex.mod[[iN]])
    }
  }
  
  # add axis ticks and labels
  if(xLab) mtext(xLabTxt, 1, line = xLabLine)
  if(yLab) mtext(yLabTxt, 2, line = yLabLine)
  
  if(xAxisTick) axis(1,at = xAxisTickLoc, labels = xAxisTickLab, tck = xAxisTickTck)
  if(xAxisLab) axis(1,at = xAxisLabLoc, tick = FALSE, labels = xAxisLabLab)
  
  if(yAxisTick) axis(2,at = yAxisTickLoc, labels = yAxisTickLab, tck = yAxisTickTck)
  if(yAxisLab) axis(2,at = yAxisLabLoc, tick = FALSE, labels = yAxisLabLab)
  
  if(header) title(headerLab, line = headerLine)
  
}