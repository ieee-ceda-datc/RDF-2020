proc generate_ispd19_mean_shift_input {} {
    set outdir mean_shift
    if {![file exists $outdir]} {
        exec mkdir $outdir 
    }
    set fp [open $outdir/input.txt w]

    set die_lx [dbGet top.fplan.box_llx]
    set die_ly [dbGet top.fplan.box_lly]
    set die_ux [dbGet top.fplan.box_urx]
    set die_uy [dbGet top.fplan.box_ury]
    puts $fp "DIEAREA ( $die_lx $die_ly )($die_ux $die_uy )"
    puts $fp "Register_Name X Y Max_Rise Max_Fall"

    set regs [dbGet top.insts.cell.name *DFF* -p2]
    foreach reg $regs {
        set inst_name [dbGet $reg.defName]
        set cell_name [dbGet $reg.cell.name]
        set x         [dbGet $reg.pt_x]
        set y         [dbGet $reg.pt_y]
        puts $fp "$inst_name $x $y * *"
    }

    close $fp
}


proc generate_endpoint_placement {} {
    if {![file exists latopt]} {
        exec mkdir latopt
    }
    set fp [open latopt/endpoint_placement.yaml w]
    puts $fp "endpoint placement:"

    set regs [dbGet top.insts.cell.name *DFF* -p2]
    foreach reg $regs {
        set inst_name [dbGet $reg.name]
        set cell_name [dbGet $reg.cell.name]
        set box_llx   [dbGet $reg.box_llx]
        set box_lly   [dbGet $reg.box_lly]
        set box_urx   [dbGet $reg.box_urx]
        set box_ury   [dbGet $reg.box_ury]
        puts $fp "  - name: \"$inst_name\""
        puts $fp "    cell_name: \"$cell_name\""
        puts $fp "    box: \[ $box_llx $box_lly $box_urx $box_ury \]"
    }

    set pios [dbGet top.terms]
    foreach term $pios {
        set term_name [dbGet $term.name]
        set pt_x [dbGet $term.pt_x]
        set pt_y [dbGet $term.pt_y]
        puts $fp "  - name: \"$term_name\""
        if {[dbGet $term.direction] == "input"} {
            puts $fp "    cell_name: \"PI\""
        } else {
            puts $fp "    cell_name: \"PO\""
        }
        puts $fp "    box: \[ $pt_x $pt_y \]"
    }

    close $fp
}


proc generate_latch_graph {} {
    if {![file exists latopt]} {
        exec mkdir latopt
    }
    set fp [open latopt/latch_graph.yaml w]
    set regs [dbGet top.insts.cell.name *DFF* -p2]
    puts $fp "latch graph:"

    foreach reg $regs {
        set begin_point [dbGet $reg.name]
        set opin [get_pins -of_objects $begin_point -filter "direction==out"]

        set a [all_fanout -from [get_pins $opin] -endpoints_only]
        foreach_in_collection i $a {
            set fo [dbGet [dbGet top.insts.instTerms.name [get_property $i hierarchical_name] -p2].name]
            if {$fo == 0} {
                set fo [dbGet top.terms.name [get_property $i hierarchical_name]]
            }
            set pc [report_timing -late -from $opin -to $fo -path_type full_clock -collection]

            if {[sizeof_collection $pc] > 0} {
                set at  [get_property $pc arrival]
                set rat [get_property $pc required_time]
                set slk [get_property $pc slack]
                puts $fp "  - begin: \"$begin_point\""
                puts $fp "    end: \"$fo\""
                puts $fp "    slk: $slk"
                puts $fp "    rat: $rat"
                puts $fp "    at: $at"
            } else {
                puts $fp "  - begin: \"$begin_point\""
                puts $fp "    end: \"$fo\""
                puts $fp "    slk: 987654321"
                puts $fp "    rat: 987654321"
                puts $fp "    at: 987654321"
            }
        }
    }

    close $fp
}


proc generate_latopt_report {clk_port} {
    generate_endpoint_placement
    generate_latch_graph

    if {[get_ccopt_clock_trees] == ""} {
        create_ccopt_clock_tree_spec
    }
    report_ccopt_clock_tree_structure -file latopt/clock_tree_structure.txt -show_sinks -delay_type late -check_type setup
    defOut -netlist placed.def
}


proc highlight_endPoints {startpin} {
    deselectAll
    set a [all_fanout -from [get_pins $startpin] -endpoints_only]
    foreach_in_collection i $a {
        selectInst [dbget [dbget top.insts.instTerms.name [get_property $i hierarchical_name] -p2].name ]
    }
    # highlights the selected instances with green and the index 57 (which is bold)
    highlight -color green -index 57
    highlight [dbget top.insts.instTerms.name $startpin -p2] -color red -index 51
    deselectAll
}


#proc rpt_insts_in_path {startp endp} {
#  set a [report_timing -from $startp -to $endp -collection]
#  set b [get_property $a timing_points]
#  foreach_in_collection i $b {
#    set tmp [get_property $i pin]
#    if {![get_property $tmp is_port]} {
#      set inst [get_cells -of_object $tmp ]
#      highlight [dbGet -p top.insts.name [get_property $inst hierarchical_name]] -color cyan
#      set net [get_nets -of_object $tmp]
#      highlight [dbGet -p top.nets.name [get_property $net hierarchical_name]] -color cyan
#    }
#    if {[get_property $tmp is_port]} {
#      highlight [dbGet -p top.terms.name [get_property $tmp hierarchical_name]] -color cyan
#    }
#  }
#}
