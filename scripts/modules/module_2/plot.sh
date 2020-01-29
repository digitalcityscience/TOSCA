#! /usr/bin/gnuplot

unset yrange
unset key
unset title
set terminal png size 1200,600 enhanced font 'Helvetica,10'
set output '~/cityapp/scripts/modules/module_2/output.png'
set yrange [0:100]
set xrange [0:25]
set key off

#set object circle at first 120,85 radius char 0.5 fillstyle empty border lc rgb '#000000' lw 3

set arrow 1 from 6.16,0 to 6.16,120 nohead lc rgb 'orange' lw 3
set arrow 2 from 0,93.5 to 25,93.5 nohead lc rgb 'orange' lw 3
set label 'A' at 5,110
set label 'B' at 20,110
set label 'C' at 5,20
set label 'D' at 20,20

set object circle at first 5.1,110 radius char 2 fillstyle empty border lc rgb '#000000' lw 1
set object circle at first 20.1,110 radius char 2 fillstyle empty border lc rgb '#000000' lw 1
set object circle at first 5.1,20 radius char 2 fillstyle empty border lc rgb '#000000' lw 1
set object circle at first 20.1,20 radius char 2 fillstyle empty border lc rgb '#000000' lw 1

plot '~/scan/main/plotting_data/scan_plot' using 1:2 with points pointtype 6 ps 0.6 lc rgb 'blue','main/plotting_data/scan_plot' using 1:3 with points ps 1 pointtype 7 lc rgb 'red','main/plotting_data/current_data' using 1:2 with points pointtype 3 lw 2 ps 2 lc rgb 'black'
