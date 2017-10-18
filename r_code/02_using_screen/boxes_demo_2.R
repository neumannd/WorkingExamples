## create a png file
png(filename = "boxes_demo_2.png",
    width = 834, height = 546,
    bg = "white")

## set plot margins to 0
# (this is the white margin between plot frame/box and the surrounding pane)
par(mar = c(0,0,0,0)+0)

split.screen(rbind(c(0.012,  0.4904, 0.3242, 0.9725),
                   c(0.5096, 0.988,  0.3242, 0.9725),
                   c(0.012,  0.988,  0.0275, 0.3022)))

## open screen 1
screen(1)
box(); mtext('screen 1', side = 3, line = -2, cex = 2)

## open screen 2
screen(2)
# set plot parameters for this screen
par(mar = c(5,2,0,0)+0)
box(); mtext('screen 2', side = 3, line = -2, cex = 2)
box(); mtext('  margin modified (par)', side = 3, line = -4, cex = 2)

## open screen 3
screen(3)
box(); mtext('screen 3 (legend)', side = 3, line = -2, cex = 2)

## close all screens
close.screen(all.screens = TRUE)

## close painting device
dev.off()