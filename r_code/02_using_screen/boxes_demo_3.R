# open output device
png(filename = "boxes_demo_3.png",
    width = 834, height = 546,
    bg = "white")
# pdf(file = 'boxes_demo_3.pdf', onefile=TRUE,
#     paper = 'special', width = 8.34, height = 5.46)

## define some boundaroes for the plots
bL = 0.012 # left boundary
bR = 0.012 # right boundary
bT = 0.0275 # 0.02 # top boundary
bB = 0.0275 # 0.02 # bottom boundary
dHor = 0.0192 # horizontal distance between maps
dVert = 0.0220 # 0.016 # vertical distance between maps
dLeg = 0.2747 # width of the legend
plWidth = (1 - bL - bR - dHor) / 2 # width per map
plHeight = (1 - bT - bB - dVert - dLeg) # height per map

## define plot pane parameters for each screen
##  = parameters of the overall plotting pane are also used
##    for the individual plotting screens
par(mar = c(0,0,0,0)+0)

## define 3 screens (see 'NOTE 1' in the end!)
split.screen(rbind(c(bL,                  bL + plWidth, 1 - bT -
                       plHeight, 1 - bT),
                   c(bL + plWidth + dHor, 1 - bR,       1 - bT -
                       plHeight, 1 - bT),
                   c(bL,                  1 - bR, bB,                bB
                     + dLeg)))
## with values:
# split.screen(rbind(c(0.012,  0.4904, 0.3242, 0.9725),
#                    c(0.5096, 0.988,  0.3242, 0.9725),
#                    c(0.012,  0.988,  0.0275, 0.3022)))

## open screen 1
screen(1)
box(); mtext('screen 1', side = 3, line = -2, cex = 2)

## open screen 2
screen(2)
# set plot parameters for this screen
par(mar = c(2,2,1,1)+0)
box(); mtext('screen 2', side = 3, line = -2, cex = 2)
box(); mtext('  margin modified (par)', side = 3, line = -4, cex = 2)

## open screen 3
screen(3)
box(); mtext('screen 3 (legend)', side = 3, line = -2, cex = 2)

## ... oh damn, we forgot text at screen 1!
# you need to add 'new=FALSE'!
screen(1, new = FALSE)
mtext('Forgotten Text!', side = 4, line = -1, col = 'red')
## This works sometime and sometimes not. The manual says:
#'   "The behavior associated with returning to a screen to add 
#'    to an existing plot is unpredictable and may result in 
#'    problems that are not readily visible."
#'  See 'NOTE 2'

## close all screens
close.screen(all.screens = TRUE)

## close output device
dev.off()

## NOTE 1:
#' How does the function call look like?
#'  - split.screen([n x 4 matrix]) with n = number of screens
#'  - each row of the matrix contains the left, right, bottom
#'     and top boundary of one screen
#'  - the first row corresponds to screen(1) etc.
#'  - we use rbind(...) to build a 3x4 matrix from three individual
#'     arrays of the length 4
#'  - split.screen can also create [r x c] matrix of screens
#'     (r = rows and c = columns) when it is called as
#'     split.screen(c(r,c))
#'
#'
## NOTE 2:
#'  Just calling the following code often does not work
#'   properly:
#'      screen(1, new = FALSE)
#'      mtext('Forgotten Text!', side = 4, line = -1, col = 'red')
#'  
#'  However, if we defined a 4th screen (dummy screen) 
#'   previously, we can call that screen first and directly
#'   afterwards screen 1. This works:
#'      screen(4)
#'      screen(1, new = FALSE)
#'      mtext('Forgotten Text!', side = 4, line = -1, col = 'red')
#'   This does not work:
#'      screen(4, new=FALSE)
#'      screen(1, new = FALSE)
#'      mtext('Forgotten Text!', side = 4, line = -1, col = 'red')
#'   This does not work:
#'      screen(4)
#'      box()
#'      screen(1, new = FALSE)
#'      mtext('Forgotten Text!', side = 4, line = -1, col = 'red')
#'   I am not sure way the first code works and the second and
#'   third not.