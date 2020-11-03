# note that the following tcl scirpt is an example of
# applying cadence gpdk45
#

############################
# set the FF2 and FF4 types
set mean_shift_ff2_master "M2BFF_X1"
set mean_shift_ff4_master "M4BFF_X1"

# solve delimiter issues in inst name
proc escape_delimiter {name} {
  set new_str [string map {"\[" "\\\["} $name]
  set new_str [string map {"\]" "\\\]"} $new_str]
  return  $new_str
}

# get net from inst and
# reconnect with new inst
#
proc get_pin_net_and_reconnect { ff_inst pin_name new_ff_inst master_term } {
  
  set ff_iterm [$ff_inst findITerm $pin_name]
  set prev_net [$ff_iterm getNet]

  # reconnect net with updated instance and master term
  odb::dbITerm_connect $new_ff_inst $prev_net $master_term
  
  # release nets.
  odb::dbITerm_disconnect $ff_iterm

  return $prev_net
}


proc get_power_master_term { master } {
  foreach master_term [$master getMTerms] {
    if {[$master_term getSigType] == "POWER"} {
      return $master_term
    }
  } 
  return {NULL}
}

proc get_ground_master_term { master } {
  foreach master_term [$master getMTerms] {
    if {[$master_term getSigType] == "GROUND"} {
      return $master_term
    }
  } 
  return {NULL}
}

proc get_power_inst_term { inst } {
  foreach inst_term [$inst getITerms] {
    if {[$inst_term getSigType] == "POWER"} {
      return $inst_term
    }
  } 
  return {NULL}
}

proc get_ground_inst_term { inst } {
  foreach inst_term [$inst getITerms] {
    if {[$inst_term getSigType] == "GROUND"} {
      return $inst_term
    }
  } 
  return {NULL}
}


# merge 2 ffs in opendb 
proc merge_2_ffs { fflist } {
  global mean_shift_ff2_master 
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  set ff1_inst [lindex $fflist 0]
  set ff2_inst [lindex $fflist 1]
 
  set new_ff_master [$db findMaster $mean_shift_ff2_master] 
  set new_q1_term [$new_ff_master findMTerm "Q1"]
  set new_q2_term [$new_ff_master findMTerm "Q2"]

  set new_d1_term [$new_ff_master findMTerm "D1"]
  set new_d2_term [$new_ff_master findMTerm "D2"]

  # set new_rn_term [$new_ff_master findMTerm "RN"]
  set new_clk_term [$new_ff_master findMTerm "CK"]

  
  set new_ff_name "[$ff1_inst getName]__[$ff2_inst getName]"
  set new_ff_inst [odb::dbInst_create $block $new_ff_master $new_ff_name]
  puts "Created 2FF Instance: $new_ff_name"

  # Q-pin reconnects
  set ff1_q_net [get_pin_net_and_reconnect $ff1_inst "Q" $new_ff_inst $new_q1_term]
  set ff2_q_net [get_pin_net_and_reconnect $ff2_inst "Q" $new_ff_inst $new_q2_term]

  # D-pin reconnects 
  set ff1_d_net [get_pin_net_and_reconnect $ff1_inst "D" $new_ff_inst $new_d1_term]
  set ff2_d_net [get_pin_net_and_reconnect $ff2_inst "D" $new_ff_inst $new_d2_term]
 
  # RN and CK-pins reconnect 
  # set ff1_rn_net [get_pin_net_and_reconnect $ff1_inst "RN" $new_ff_inst $new_rn_term]
  #set ff2_rn_net [get_pin_net_and_reconnect $ff2_inst "RN" $new_ff_inst $new_rn_term]
  
  set ff1_clk_net [get_pin_net_and_reconnect $ff1_inst "CK" $new_ff_inst $new_clk_term]
  #set ff2_clk_net [get_pin_net_and_reconnect $ff2_inst "CK" $new_ff_inst $new_clk_term]
  

  # power pins (VDD/VSS) connect to ff1's VDD/VSS net
  #set ff1_power_term [get_power_inst_term $ff1_inst]
  #set ff1_ground_term [get_ground_inst_term $ff1_inst]

  #set ff1_power_net [$ff1_power_term getNet]
  #set ff1_ground_net [$ff1_ground_term getNet]

  #odb::dbITerm_disconnect $ff1_power_term
  #odb::dbITerm_disconnect $ff1_ground_term

  #set new_power_term [get_power_master_term $new_ff_master]
  #set new_ground_term [get_ground_master_term $new_ff_master]

  #puts "new_power_term: [$new_power_term getName]"
  #puts "new_ground_term: [$new_ground_term getName]"

  #odb::dbITerm_connect $new_ff_inst $ff1_power_net $new_power_term  
  #odb::dbITerm_connect $new_ff_inst $ff1_ground_net $new_ground_term 

  #puts "Net update: [$ff1_q_net getName]"
  #puts "Net update: [$ff2_q_net getName]"
  #puts "Net update: [$ff1_d_net getName]"
  #puts "Net update: [$ff2_d_net getName]"

  set locs [$ff1_inst getLocation]
  $new_ff_inst setPlacementStatus PLACED
  $new_ff_inst setLocation [lindex $locs 0] [lindex $locs 1] 
  $new_ff_inst setOrient R0 

  odb::dbInst_destroy $ff1_inst
  odb::dbInst_destroy $ff2_inst 

  #set net [$block findNet "VDD"]
  #foreach iterm [$net getITerms] {
  #  puts -nonewline "[[$iterm getMTerm] getName] "
  #}
  #puts ""
}

# merge 4 ffs in opendb
proc merge_4_ffs { fflist } {
  global mean_shift_ff4_master 
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  set ff1_inst [lindex $fflist 0]
  set ff2_inst [lindex $fflist 1]
  set ff3_inst [lindex $fflist 2]
  set ff4_inst [lindex $fflist 3]
 
  set new_ff_master [$db findMaster $mean_shift_ff4_master] 
  set new_q1_term [$new_ff_master findMTerm "Q1"]
  set new_q2_term [$new_ff_master findMTerm "Q2"]
  set new_q3_term [$new_ff_master findMTerm "Q3"]
  set new_q4_term [$new_ff_master findMTerm "Q4"]

  set new_d1_term [$new_ff_master findMTerm "D1"]
  set new_d2_term [$new_ff_master findMTerm "D2"]
  set new_d3_term [$new_ff_master findMTerm "D3"]
  set new_d4_term [$new_ff_master findMTerm "D4"]

  # set new_rn_term [$new_ff_master findMTerm "RN"]
  set new_clk_term [$new_ff_master findMTerm "CK"]
  
  set new_ff_name "[$ff1_inst getName]__[$ff2_inst getName]__[$ff3_inst getName]__[$ff4_inst getName]"
  set new_ff_inst [odb::dbInst_create $block $new_ff_master $new_ff_name]
  puts "Created 4FF Instance: $new_ff_name"

  # Q-pin reconnects
  set ff1_q_net [get_pin_net_and_reconnect $ff1_inst "Q" $new_ff_inst $new_q1_term]
  set ff2_q_net [get_pin_net_and_reconnect $ff2_inst "Q" $new_ff_inst $new_q2_term]
  set ff3_q_net [get_pin_net_and_reconnect $ff3_inst "Q" $new_ff_inst $new_q3_term]
  set ff4_q_net [get_pin_net_and_reconnect $ff4_inst "Q" $new_ff_inst $new_q4_term]

  # D-pin reconnects 
  set ff1_d_net [get_pin_net_and_reconnect $ff1_inst "D" $new_ff_inst $new_d1_term]
  set ff2_d_net [get_pin_net_and_reconnect $ff2_inst "D" $new_ff_inst $new_d2_term]
  set ff3_d_net [get_pin_net_and_reconnect $ff3_inst "D" $new_ff_inst $new_d3_term]
  set ff4_d_net [get_pin_net_and_reconnect $ff4_inst "D" $new_ff_inst $new_d4_term]
 
  # RN and CK-pins reconnect 
  # set ff1_rn_net [get_pin_net_and_reconnect $ff1_inst "RN" $new_ff_inst $new_rn_term]
  #set ff2_rn_net [get_pin_net_and_reconnect $ff2_inst "RN" $new_ff_inst $new_rn_term]
  #set ff3_rn_net [get_pin_net_and_reconnect $ff3_inst "RN" $new_ff_inst $new_rn_term]
  #set ff4_rn_net [get_pin_net_and_reconnect $ff4_inst "RN" $new_ff_inst $new_rn_term]

  set ff1_clk_net [get_pin_net_and_reconnect $ff1_inst "CK" $new_ff_inst $new_clk_term]
  #set ff2_clk_net [get_pin_net_and_reconnect $ff2_inst "CK" $new_ff_inst $new_clk_term]
  #set ff3_clk_net [get_pin_net_and_reconnect $ff3_inst "CK" $new_ff_inst $new_clk_term]
  #set ff4_clk_net [get_pin_net_and_reconnect $ff4_inst "CK" $new_ff_inst $new_clk_term]
  
  # power pins (VDD/VSS) connect to ff1's VDD/VSS net
  #set ff1_power_term [get_power_inst_term $ff1_inst]
  #set ff1_ground_term [get_ground_inst_term $ff1_inst]

  #set ff1_power_net [$ff1_power_term getNet]
  #set ff1_ground_net [$ff1_ground_term getNet]

  #odb::dbITerm_disconnect $ff1_power_term
  #odb::dbITerm_disconnect $ff1_ground_term

  #set new_power_term [get_power_master_term $new_ff_master]
  #set new_ground_term [get_ground_master_term $new_ff_master]

  #odb::dbITerm_connect $new_ff_inst $ff1_power_net $new_power_term  
  #odb::dbITerm_connect $new_ff_inst $ff1_ground_net $new_ground_term 

  #puts "Net update: [$ff1_q_net getName]"
  #puts "Net update: [$ff2_q_net getName]"
  #puts "Net update: [$ff1_d_net getName]"
  #puts "Net update: [$ff2_d_net getName]"
  
  set locs [$ff1_inst getLocation]
  $new_ff_inst setPlacementStatus PLACED
  $new_ff_inst setLocation [lindex $locs 0] [lindex $locs 1] 
  $new_ff_inst setOrient R0 


  odb::dbInst_destroy $ff1_inst
  odb::dbInst_destroy $ff2_inst 
  odb::dbInst_destroy $ff3_inst
  odb::dbInst_destroy $ff4_inst 
}


proc write_mean_shift_inputs {text_file} {
  # get pointers from OpenDB
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]
  set dbu [$tech getDbUnitsPerMicron]
  puts "Writing mean_shift inputs from OpenROAD..."
  puts "DBU: $dbu"

  # set bbox [$block getBBox]
  set die_rect [$block getDieArea]
  
  set fid [open $text_file w]

  puts $fid "DIEAREA ( [$die_rect xMin] [$die_rect yMin] ) ( [$die_rect xMax] [$die_rect yMax] )"
  puts $fid "Register_Name X Y Max_Rise Max_Fall"
  set insts [$block getInsts]
  foreach inst $insts {
    set master_name [[$inst getMaster] getName]
    if {![string match DFF_X* $master_name]} {
      continue
    }

    set locs [$inst getLocation]
    set x [lindex $locs 0]
    set y [lindex $locs 1]
    puts $fid "[$inst getName] [expr $x/$dbu] [expr $y/$dbu] * *" 
  }
  close $fid
  puts "Writing mean_shift inputs is done. Total #Inst = [llength $insts]"
}

proc write_flop_tray_inputs {} {
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]
  set dbu [$tech getDbUnitsPerMicron]
  puts "Writing flop_tray inputs from OpenROAD..."
  puts "DBU: $dbu"

  if {![file exists input]} {
    exec mkdir input/
  }
  
  set fid [open input/fp_info.txt w]
  set die_rect [$block getDieArea]
  puts $fid "[$die_rect xMin] [$die_rect yMin] [$die_rect xMax] [$die_rect yMax]"
  close $fid

  set fid [open input/ff_info.txt w]
  
  set insts [$block getInsts]
  foreach inst $insts {

    set master_name [[$inst getMaster] getName]
    if {![string match DFF_X* $master_name]} {
      continue
    }

    set locs [$inst getLocation]
    set x [lindex $locs 0]
    set y [lindex $locs 1]
    puts $fid "[$inst getName] [expr 1.0*$x/$dbu] [expr 1.0*$y/$dbu]" 
  }
  
  close $fid

  set fid [open input/path_info.txt w]
  puts $fid ""
  close $fid 

  puts "Writing flop_tray inputs is done. Total #Inst = [llength $insts]"
}



proc read_mbff_outputs {text_file} {
  global mean_shift_ff2_master 
  global mean_shift_ff4_master 

  # get pointers from OpenDB
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  puts "Reading mean_shift outputs to OpenROAD..."

  set dbu [$tech getDbUnitsPerMicron]
  puts "DBU: $dbu"


  set ff2_master [$db findMaster $mean_shift_ff2_master]
  set ff4_master [$db findMaster $mean_shift_ff4_master]

  # MBFF lef check
  if {$ff2_master == {NULL}} {
    puts "Error: FF2 master cell: $mean_shift_ff2_master is not found! Please double check lef."
    return
  }
  
  # MBFF lef check
  if {$ff4_master == {NULL}} {
    puts "Error: FF4 master cell: $mean_shift_ff4_master 4s not found! Please double check lef."
    return
  }

  puts "Checking LEF Done."

  puts "Reading $text_file"
  set fid [open $text_file r]
  set lst_lines [split [read $fid] \n]
  close $fid

  set idx_dict {}

  set i 0
  foreach line $lst_lines { 
    # skip for DIEAREA / name column 
    if {$i <= 1} {
      incr i
      continue
    }
  
    # output always have four columns
    if {[llength $line] != 4} {
      incr i
      continue
    }
  
    # instance name
    set inst_name [lindex $line 0]
    
    # x, y coordinates
    set x [expr int([lindex $line 1] * $dbu)]
    set y [expr int([lindex $line 2] * $dbu)]

    # idx
    set idx [lindex $line 3]

    set inst [$block findInst $inst_name]
    if { $inst == {NULL} } {
      set inst [$block findInst [escape_delimiter $inst_name]]
    }

    if { $inst == {NULL} } {
      puts "Error: Cannot find Instance: $inst_name in OpenDB"
      return
    }

    # append idx-inst list pair    
    # if already exists, just append inst to list
    if {[dict exists $idx_dict $idx]} {
      set new_list [dict get $idx_dict $idx] 
      lappend new_list $inst
      dict set idx_dict $idx $new_list
    # else, newly create 1-elem inst list
    } else {
      dict set idx_dict $idx [list $inst]
    }
    incr i
  }
  puts "Dictionary building is done. Total dict length = [expr [llength $idx_dict]/2]" 
  puts "NumInstances before merging: [llength [$block getInsts]]"

  foreach idx [dict keys $idx_dict] { 
    set ff_list [dict get $idx_dict $idx]
    set ff_len [llength $ff_list]


    # master cell type conversion
    if { $ff_len == 2 } {
      merge_2_ffs $ff_list
    } elseif { $ff_len == 3 } {
      merge_2_ffs [lrange $ff_list 0 end-1]
    } elseif { $ff_len == 4 } {
      merge_4_ffs $ff_list
    } elseif { $ff_len == 5 } {
      merge_4_ffs [lrange $ff_list 0 end-1]
    } elseif { $ff_len == 6 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_4_ffs [lrange $ff_list 2 end]
    } elseif { $ff_len == 7 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_4_ffs [lrange $ff_list 2 end]
    }
    # puts "current ff: $idx $ff_len"
  }
  puts "NumInstances after merging: [llength [$block getInsts]]"
  puts "Done!"
}
