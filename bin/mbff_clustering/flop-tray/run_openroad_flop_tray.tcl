source function_mbff.tcl

read_lef ./NangateOpenCellLibrary.tech.lef
read_lef ./NangateOpenCellLibrary.macro.lef
read_lef ./mbff.lef

read_def ./3_4_place_dp.def  
write_flop_tray_inputs

# call flopTray binary
catch {
  puts "Execute Flop Tray"
  exec ./ffTrayOpt
} exception

read_mbff_outputs ./ff_tray.sol.new
write_def ./gcd_mbff_flop_tray.def

# Detailed Placement
detailed_placement 

write_def ./gcd_mbff_flop_tray_dp.def
exit
