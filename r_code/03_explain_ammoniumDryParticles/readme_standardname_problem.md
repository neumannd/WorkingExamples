What we want to plot:
 - one figure containing three plots alphabetized from (a) to ( c). 
 - a plot with differently sized circles on the left and bar plots in the center and on the right
 - save it as pdf file

It should look this way:


```r
#
# +-------------------+-------------------+-------------------+
# | (a)               | (b)               | (c)               |
# |                   |                   |                   |
# |    plot showing   | bar plot (3 bars) | bar plot (3 bars) |
# |    atmospheric    |   showing model   |  showing what the |
# |     particles     | representation of | current CF stand- |
# |   (as circles)    |  atmos. particles | ard names mean    |
# |                   |                   |                   |
# +-------------------+-------------------+-------------------+
#
```

That's it.




~~~~ load libraries ~~~~


```r
# load libraries ----
library('plotrix')
# enables to use 'draw.circle' function
```

~~~~ open PDF document and define parameters ~~~~


```r
# open PDF document and define parameters ----
pdf(file = 'readme_standardname_problem.pdf', title = 'aerosol representation and meaning of standard names',
    paper='special', width = 6.3, height = 2.1)
# x11(width = 6.3, height = 2.1)
par(mar = c(0.5,0.5,0.5,0.5))
```

~~~~ define screens ~~~~


```r
# define screens ----
split.screen(c(1,3))
```

~~~~ make first plot ~~~~


```r
# make first plot ----
# activate screen 1
screen(1)

# create base plot
plot(c(0,1), c(0,1), xlim = c(0,1.1), ylim = c(-0.1,1),
     type = 'n', yaxt = 'n', xaxt = 'n', bty = 'n',
     ann = FALSE)

# write "(a)"
text(0.03, 0.96, '(a)', cex = 0.8, col = '#444444')

# define particles to plot (x- and y-coordinates and radius)
p.x = c(0.11, 0.15, 0.2,  0.5,    0.75, 0.85, 0.45,  0.4,  0.3,  0.8,  0.6,   0.62,  0.08, 0.3,  0.55,  0.11,  0.95, 0.91, 0.78)
p.y = c(0.15, 0.5,  0.85, 0.48,   0.8,  0.90, 0.29,  0.78, 0.75, 0.55, 0.6,   0.4,   0.3,  0.4,  0.65,  0.65,  0.8,  0.35, 0.3)
p.r = c(0.1,  0.03, 0.02, 0.045,  0.02, 0.02, 0.07,  0.06, 0.02, 0.05, 0.03,  0.025, 0.01, 0.02, 0.01,  0.015, 0.03, 0.07, 0.01)
p.col.fill = NA
p.col.border = 'black'
p.lwd = 1.5

# define ammonium to plot (x- and y-coord)
a.x = c(0.18, 0.16, 0.19,  0.49,  0.75, 0.85, 0.42,  0.45, NA,   NA,   0.6,   NA,    0.08, 0.3,  0.545, NA,    0.94, 0.875, 0.775)
a.y = c(0.15, 0.51, 0.86,  0.47,  0.79, 0.90, 0.25,  0.77, NA,   NA,   0.615, NA,    0.3,  0.41, 0.65,  NA,    0.82, 0.385, 0.295)
a.a = c(0.03, 0.01, 0.009, 0.01,  0.01, 0.02, 0.015, 0.01, NA,   NA,   0.015, NA,    0.01, 0.01, 0.005, NA,    0.02, 0.02,  0.005)
a.b = c(0.05, 0.01, 0.007, 0.013, 0.01, 0.02, 0.03,  0.02, NA,   NA,   0.015, NA,    0.01, 0.01, 0.007, NA,    0.01, 0.04,  0.005)
a.rot = c(0,  0,    0,     0,     0,    0,    55,    0,    NA,   NA,   0,     NA,    0,    0,    0,     NA,    30,   -45,   0)
a.col.fill = 'blue'
a.col.border = NA

# define non-ammonium particles to plot (x- and y-coord)
o.x = c(NA,   NA,   NA,    NA,    NA,   NA,   NA,    NA,   0.3,  0.8,  NA,    0.62,  NA,   NA,   NA,    0.11,  NA,   NA,    NA)
o.y = c(NA,   NA,   NA,    NA,    NA,   NA,   NA,    NA,   0.75, 0.55, NA,    0.4,   NA,   NA,   NA,    0.65,  NA,   NA,    NA)
o.r = c(NA,   NA,   NA,    NA,    NA,   NA,   NA,    NA,   0.02, 0.05, NA,    0.025, NA,   NA,   NA,    0.015, NA,   NA,    NA)
o.col.fill = 'grey'
o.col.border = NA

# plot circles
for(i1 in 1:length(a.x)) draw.ellipse(a.x[i1], a.y[i1], a.a[i1], a.b[i1], angle = a.rot[i1], border = a.col.border, col = a.col.fill)
for(i1 in 1:length(o.x)) draw.circle(o.x[i1], o.y[i1], o.r[i1], border = o.col.border, col = o.col.fill)
for(i1 in 1:length(p.x)) draw.circle(p.x[i1], p.y[i1], p.r[i1], border = p.col.border, col = p.col.fill, lwd = p.lwd)

# plot legend
# legend('bottomright', c('total suspended particles', 'ammonium in particles'),
#        pch = c(1, 20), col = c(p.col.border, a.col.fill), pt.lwd = c(1.5, 0),
#        inset = c(0, 0), box.col = '#444444', text.col = '#444444', 
#        cex = 0.5, pt.cex = 1.1)
legend('bottomright', c('ammonium in particles', 'ammonium dry particles', 'particles without ammonium', 'total suspended particles'),
       box.col = '#444444', text.col = '#444444',
       pch = c(20, 1, 21, 3), col = c(a.col.fill, p.col.border, p.col.border, '#444444'),#  pt.lwd = c(0, 1.5, 1.5, 1.5), 
       pt.bg = c(NA, NA, o.col.fill, NA), 
       lty = NA, lwd = 1, seg.len = 4, x.intersp = 0.1, y.intersp = 1.1, 
       inset = c(0, 0), cex = 0.5, pt.cex = c(0.9, 1.1, 1.1, 0.4))
points(c(0.32, 0.44, 0.43, 0.38), c(-0.08, -0.09, -0.08, 0.05), 
       pch = c(21, 20, 1, 20), cex = c(1.1, 0.8, 1.1, 0.8), 
       col = c(p.col.border, a.col.fill, p.col.border, a.col.fill),
       bg = c(o.col.fill, NA, NA, NA))
```

~~~~ make second plot ~~~~


```r
# make second plot ----
# activate screen 2
screen(2)

# create base plot
plot(c(0,1), c(0,1), xlim = c(0,1), ylim = c(0,1),
     type = 'n', yaxt = 'n', xaxt = 'n', bty = 'n',
     ann = FALSE)

# write "(b)"
text(0.03, 0.96, '(b)', cex = 0.8, col = '#444444')

# plot y-axis
ax.x = 0.16
axis(2, at = (0:1)*2, labels = FALSE, 
     pos = ax.x, tcl = +0.2,
     col = 'white', col.ticks = '#444444')
arrows(ax.x, 0, ax.x, 0.95, length = 0.1, col = '#444444')
axis(2, at = (0:5)*0.16, labels = FALSE, 
     pos = ax.x, tcl = -0.2, col = '#444444')
mtext('particle mass', cex = 0.7, 
      side = 2, line = -1.3, at = 0.5,
      col = '#444444')

# define bars, general
b.x = c(0.35, 0.64, 0.93)
b.w = 0.2
# define bars, particles
bp.y0 = c(0, 0, 0)
bp.y1 = c(NA, 0.82, 0.9)
bp.col.fill = NA
bp.col.border = 'black'
bp.lwd = 1.5
# define bars, ammonium
ba.y0 = c(0, 0, 0)
ba.y1 = c(0.165, 0.165, 0.165)
ba.col.fill = 'blue'
ba.col.border = NA
# define bars, particles withOut ammonium
bo.y0 = c(NA, NA, 0.82)
bo.y1 = c(NA, NA, 0.9)
bo.col.fill = 'grey'
bo.col.border = NA
bo.lwd = 1.5

# generate support arrays for bar plotting
p.b.x = (rep(b.x, each = 6) + rep(c(NA,-b.w/2, b.w/2), each = 2, times = length(b.x)))[-(1:2)]
p.bp.y = t(array(c(rep(bp.y0,times=2), rep(bp.y1,times=2), rep(bp.y0,times=2)), dim = c(length(bp.y1),6)))[-c(1,length(b.x)*6)]
p.ba.y = t(array(c(rep(ba.y0,times=2), rep(ba.y1,times=2), rep(ba.y0,times=2)), dim = c(length(ba.y1),6)))[-c(1,length(b.x)*6)]
p.bo.y = t(array(c(rep(bo.y0,times=2), rep(bo.y1,times=2), rep(bo.y0,times=2)), dim = c(length(bo.y1),6)))[-c(1,length(b.x)*6)]
# plot bars (polygons)
polygon(p.b.x, p.ba.y, border = ba.col.border, col = ba.col.fill)
polygon(p.b.x, p.bo.y, border = bo.col.border, col = bo.col.fill)
polygon(p.b.x, p.bp.y, border = bp.col.border, col = bp.col.fill, lwd = bp.lwd)

# add text to bars
text(b.x[1]-0.04, 0.2, 'particulate \nammonium', cex = 0.7, srt = 90, pos = 4)
text(b.x[2]-0.04, 0.2, 'ammonium \ndry particles', cex = 0.7, srt = 90, pos = 4)
text(b.x[3]-0.04, 0.2, 'total suspended \nparticles (TSP)', cex = 0.7, srt = 90, pos = 4)
```

~~~~ make third plot ~~~~


```r
# make third plot ----
# activate screen 3
screen(3)

# create base plot
plot(c(0,1), c(0,1), xlim = c(0,1), ylim = c(0,1),
     type = 'n', yaxt = 'n', xaxt = 'n', bty = 'n',
     ann = FALSE)

# write "(c)"
text(0.03, 0.96, '(c)', cex = 0.8, col = '#444444')

# plot y-axis
ax.x = 0.16
axis(2, at = (0:1)*2, labels = FALSE, 
     pos = ax.x, tcl = +0.2,
     col = 'white', col.ticks = '#444444')
arrows(ax.x, 0, ax.x, 0.95, length = 0.1, col = '#444444')
axis(2, at = (0:5)*0.16, labels = FALSE, 
     pos = ax.x, tcl = -0.2, col = '#444444')
mtext('particle mass', cex = 0.7, 
      side = 2, line = -1.3, at = 0.5,
      col = '#444444')

# define bars, general
b.x = c(0.35, 0.64, 0.93)
b.w = 0.2
# define bars, particles
bp.y = c(0.09, 0.65, 0.85)
bp.col.fill = NA
bp.col.border = 'black'
bp.lwd = 1.5
# define bars, ammonium
ba.y = c(0.03, 0.14, 0.09)
ba.col.fill = 'blue'
ba.col.border = NA
# define bars, particles withOut ammonium
bo.y0 = c(NA, NA, 0.82)
bo.y1 = c(NA, NA, 0.9)
bo.col.fill = 'grey'
bo.col.border = NA
bo.lwd = 2

# generate support arrays for bar plotting
p.b.x = (rep(b.x, each = 6) + rep(c(NA,-b.w/2, b.w/2), each = 2, times = length(b.x)))[-(1:2)]
p.bp.y = c(t(array(c(rep(0,length(bp.y)*4), rep(bp.y,length(bp.y)*2)), dim = c(length(bp.y),6)))[-(1:3)], 0)
p.ba.y = c(t(array(c(rep(0,length(ba.y)*4), rep(ba.y,length(ba.y)*2)), dim = c(length(ba.y),6)))[-(1:3)], 0)
# plot bars (polygons)
polygon(p.b.x, p.bp.y, border = bo.col.border, col = bo.col.fill, lwd = bo.lwd, angle=45, density=10)
polygon(p.b.x, p.ba.y, border = ba.col.border, col = ba.col.fill)
polygon(p.b.x, p.bp.y, border = bp.col.border, col = bp.col.fill, lwd = bp.lwd)

# add text to bars
text(b.x[1]-0.04, 0.2, ' ultra fine \n particles', cex = 0.7, srt = 90, pos = 4)
rect(b.x[2]-0.04, 0.18, b.x[2]+0.04, 0.57, col = 'white', border = NA)
text(b.x[2]-0.05, 0.2, 'fine particles', cex = 0.7, srt = 90, pos = 4, bg = 'red')
rect(b.x[3]-0.04, 0.18, b.x[3]+0.04, 0.67, col = 'white', border = NA)
text(b.x[3]-0.05, 0.2, 'coarse particles', cex = 0.7, srt = 90, pos = 4)
```

~~~~ finalize screens ~~~~


```r
# finalize screens ---
close.screen(all = TRUE)
```

~~~~ finalize PDF document ~~~~


```r
# finalize PDF document ----
dev.off()
```

