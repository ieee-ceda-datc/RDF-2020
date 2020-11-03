source function_mbff.tcl

read_lef ./NangateOpenCellLibrary.tech.lef
read_lef ./NangateOpenCellLibrary.macro.lef
read_lef ./mbff.lef

read_def ./3_4_place_dp.def  

write_mean_shift_inputs input.txt

# call mean_shift binary 
catch {
  puts "Execute Mean Shift"
  exec ./clustering-a input.txt output.txt
} exception

read_mbff_outputs ./output.txt
write_def ./gcd_mbff_mean_shift.def

detailed_placement 

write_def ./gcd_mbff_mean_shift_dp.def


exit
