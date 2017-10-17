# generate some data ----
#  create an array from 0 to 9 as x-values
x_vals = 0:9
#  create an array of 10 uniformly distributed random numbers as first set of y-values
y1_vals = runif(10) * 3.5
#  create another array with 10 values as second set of y-values
y2_vals = c(1,2,3,3,3,2.5,2.2,2.6, 2.7, 3.1)


# first plot ----
png(filename = "basic_plotting_1.png",
    width = 500, height = 350,
    bg = "white")
#  create a basic plot, dots
plot(x_vals, y1_vals)
title('first plot')
dev.off()


# second plot ----
png(filename = "basic_plotting_2.png",
  width = 500, height = 350,
    bg = "white")
#  create a second plot, lines
#    orange line
#    set 'title' in the plotting function
plot(x_vals, y2_vals, type = 'l', col = 'orange', main = 'second plot')
#  add red dots to existing plot
points(x_vals, y2_vals, col = 'red')
#  add y1 values as lines and points (other line style and symbols)
#    see documentation of 'points' for symbols
#    see documentation of 'par' for line types
lines(x_vals, y1_vals, col = 'darkgreen', lty = 'dashed')
points(x_vals, y1_vals, col = 'green', pch = 18)
#  add a blue axis on the right
#    values for the first parameter:
#      1 = below (x-axis)
#      2 = left (y-axis)
#      3 = top
#      4 = right
#    see documentation of 'axis' and 'par' for options
axis(4, col = 'blue', col.axis = 'violet', col.ticks = 'cyan')
#  add a brown axis with different tick locations
axis(3, col = 'brown', at = c(0,3,6,9))
dev.off()


# third plot ----
png(filename = "basic_plotting_3.png",
    width = 500, height = 350,
    bg = "white")
## problems of our second plot
##  (a) the extend in x- and y-direction was not nice
##  (b) no nice x- and y-axes labels
##  (c) we would like to have minor tick marks at the top axis
##  (d) we would like to have a legend

##  solve problems (a) and (b)
#  create a second plot, lines
#    the line is orange
#    the plotting area goes from 0 to 10 in x-directions
#     and from 0 to 3.5 in y-direction
plot(x_vals, y2_vals, type = 'l', col = 'orange',
     xlim = c(0,10), ylim = c(0, 3.5), 
     xlab = 'x-values', ylab = 'my y-values',
     main = 'third plot')
#  add red dots to existing plot
points(x_vals, y2_vals, col = 'red')
#  add y1 values as lines and points (other line style and symbols)
#    see documentation of 'points' for symbols
#    see documentation of 'par' for line types
lines(x_vals, y1_vals, col = 'darkgreen', lty = 'dashed')
points(x_vals, y1_vals, col = 'green', pch = 18)
#  add a blue axis on the right
#    values for the first parameter:
#      1 = below (x-axis)
#      2 = left (y-axis)
#      3 = top
#      4 = right
#    see documentation of 'axis' and 'par' for options
axis(4, col = 'blue', col.axis = 'violet', col.ticks = 'cyan')
## solve problem (c)
#  add brown axis with shorter ticks (tcl = tick length) without labels to the top
axis(3, col = 'darkgrey', at = x_vals, labels = FALSE, tcl = -0.2)
#  add a brown axis with different tick locations and longer ticks to the top
axis(3, col = 'brown', at = c(0,3,6,9))
## solve problem (d)
legend('bottomright', c('user defined data', 'random data'), 
       col = c('orange', 'darkgreen'), lty = c('solid', 'dashed'))
dev.off()