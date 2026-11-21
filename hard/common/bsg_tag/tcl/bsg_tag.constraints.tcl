
# This process constraints a bsg_tag interface, which typically has three pins:
#    bsg_tag_clk : The source synchronous clock
#    bsg_tag_data: Center-aligned data
#    bsg_tag_en  : Out-of-band signal enabling the tag interface. It is illegal to
#                    manipulate this signal while sending data on the interface
#
#                -----+           +-----------+           +------------
# tag_clk_i:          |           |           |           |
#                     +-----------+           +-----------+
#
#                     +-----------------------+
# tag_data_i:         |                       |
#                -----+                       +-----------------------
#
#             +-----------------------------------------------------------------
# tag_en_i:   |
#             +
#
# Example usage:
#   bsg_tag_clock_create $tag_clk_name bsg_tag_clk_i/C bsg_tag_data_i/C bsg_tag_en_i/C $tag_clk_period
#

proc bsg_tag_clock_create { clk_name clk_source tag_data tag_attach period {uncertainty 0}} {
    # this is the scan chain
    create_clock -period $period -name $clk_name $clk_source

    # apply uncertainty
    set_clock_uncertainty ${uncertainty} [get_clocks ${clk_name}]

    # we set the input delay of these pins to be half the bsg_tag clock period; we launch on the negative edge and clock and
    # data travel in parallel, so should be about right
    set_input_delay [expr $period  / 2.0] -clock $clk_name $tag_data

    # this signal is relative to the bsg_tag_clk, but is used in the bsg_tag_client in a CDC kind of way
    if {$tag_attach != ""} {
      set_input_delay [expr $period  / 2.0] -clock $clk_name $tag_attach
    }
}

