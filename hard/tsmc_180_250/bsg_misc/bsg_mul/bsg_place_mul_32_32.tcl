
puts "bsg_place_mul_32_32 guts/n_0__ode/sl_mul my_mul"

proc bsg_place_mul_32_32 { prefix rp_group_name } {
    # guts/n_0__ode/sl_mul/fi32_m32/brr1/rof_3__br/h_bb4bh/macro_b4b/aoi2_w1_b1
    # the naming of the multiplier blocks; from least significant rows to most significant
    # run from brr0 to brr3; with in the rows, it runs from rof_0 to rof_5
    #                                  ?     ?
    #guts/n_0__node/sl_mul/fi32_m32/brr2/rof_3__br/h_bb4bh/macro_b4b/add42_w3_b1
    #guts/n_0__node/sl_mul/fi32_m32/brr2/rof_1__br/h_bb4bh/macro_b4b/add42_w2_b0

    # guts/n_0__node/sl_mul/fi32_m32/crr03/rof_4__fi_cr/macro_c42/add42_w3_b1

    # 8     5 5   6
    # 7     4 4 5 5
    # 6     3 3 4 4 5 5
    # 5     2 2 3 3 4 4 5
    # 4     1 1 2 2 3 3 4
    # 3     0 0 1 1 2 2 3
    # 2         0 0 1 1 2
    # 1             0 0 1
    # 0                 0
    #   0 1 2 3 4 5 6 7 8
    #
    #     G B 4 B 4 B 4 B
    #     R 3 2 2 2 1 2 0
    # B = brr

    set sep "_"

    create_rp_group $rp_group_name -design bsg_chip -columns 9 -rows 9

    set col 8
    foreach row [list  0 1 2 3 4 ] {
	set group [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}brr0${sep}rof_${row}__br${sep}bb4bh${sep}macro_b4b/add42_w4_b0] rp_group_name]
	set_rp_group_options $group -placement_type compression
	if {$row == 0} {
	    set_rp_group_options $group -group_orient FN
	}
	add_to_rp_group bsg_chip::$rp_group_name -hier $group -column $col -row $row
    }

    set col 7
    foreach row [list  0 1 2 3 4 5 ] {
	set group [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}crr01${sep}rof_${row}__cr${sep}macro_c42/add42_w3_b1]  rp_group_name]
	add_to_rp_group bsg_chip::$rp_group_name -hier $group -column $col -row [expr $row+1]
    }

    set col 6
    foreach row [list 0 1 2 3 4 5 ] {
	set group [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}brr1${sep}rof_${row}__br${sep}bb4bh${sep}macro_b4b/add42_w4_b0]   rp_group_name]
	set_rp_group_options $group -placement_type compression

	if {$row == 0} {
	    set_rp_group_options $group -group_orient FN
	}

	add_to_rp_group bsg_chip::$rp_group_name -hier $group -column $col -row [expr $row+1]
    }

    set col 5
    foreach row [list  0 1 2 3 4 5 6 ] {
	add_to_rp_group bsg_chip::$rp_group_name -hier [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}crr03${sep}rof_${row}__cr${sep}macro_c42/add42_w3_b1]  rp_group_name] -column $col -row [expr $row+2]
    }

    set col 4
    foreach row [list  0 1 2 3 4 5 6 ] {
	add_to_rp_group bsg_chip::$rp_group_name -hier [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}pipe_dffe_c42_03_r${sep}rof_${row}__bde${sep}macro_dff/reg_b8]  rp_group_name] -column $col -row [expr $row+2]
    }


    set col 3
    foreach row [list  0 1 2 3 4 5] {
	set group  [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}brr2${sep}rof_${row}__br${sep}bb4bh${sep}macro_b4b/add42_w4_b0]   rp_group_name]
	set_rp_group_options $group -placement_type compression

	if {$row == 0} {
	    set_rp_group_options $group -group_orient FN
	}
	add_to_rp_group bsg_chip::$rp_group_name -hier $group -column $col -row [expr $row+2]
    }


    set col 2
    foreach row [list  0 1 2 3 4 5 ] {
	add_to_rp_group bsg_chip::$rp_group_name -hier [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}crr23${sep}rof_${row}__cr${sep}macro_c42/add42_w3_b1]  rp_group_name] -column $col -row [expr $row+3]
    }


    set col 1
    foreach row [list 0 1 2 3 4 5] {
	set group  [get_attribute [get_cell ${prefix}${sep}fi32_m32${sep}brr3${sep}rof_${row}__br${sep}bb4bh${sep}macro_b4b/add42_w4_b0] rp_group_name]
	set_rp_group_options $group -placement_type compression

	if {$row == 0} {
	    set_rp_group_options $group -group_orient FN
	}

	add_to_rp_group bsg_chip::$rp_group_name -hier $group -column $col -row [expr $row+3]

    }

#    set col 1
#    foreach row [list 1 2 3 4] {
#	add_to_rp_group bsg_chip::$rp_group_name -hier [get_attribute [get_cell ${prefix}/fi32_m32/gb/rof_${row}__macro_bach/macro_b4b/csa_w3_b0] rp_group_name] -column $col -row [expr $row+4]
#    }

}
