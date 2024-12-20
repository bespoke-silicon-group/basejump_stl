  package bsg_chip_test_pkg;
 
    import bsg_chip_pkg::*;

    // The number of bits needed for a tag rom
    localparam tag_rom_data_width_gp =
        4 // 4b opcode
        +tag_num_masters_gp // master enable mask
        +tag_lg_els_gp // client id
        +1 // data_not_reset
        +tag_lg_width_gp // len
        +tag_max_payload_width_gp; // data payload
    localparam tag_rom_payload_width_gp = tag_rom_data_width_gp-4;
    localparam tag_rom_addr_width_gp = 20;
    localparam tag_rom_str_gp = "TAG_TRACE";

    // The number of bits needed for a test rom
    localparam test_rom_data_width_gp = 196;
    localparam test_rom_addr_width_gp = 20;
    localparam test_rom_payload_width_gp = test_rom_data_width_gp-4; // 4b opcode
    localparam test_rom_str_gp = "TEST_TRACE";

    typedef struct packed {
        logic [(test_rom_payload_width_gp-1)-1:0] padding;
        logic async_output_disable;
    } bsg_test_rom_clk_gen_pearl_s;

    localparam max_test_links_lp = 32;
    typedef enum logic [1:0] {e_link_type_fwd = 0, e_link_type_rev = 1, e_link_type_noc = 2, e_link_type_raw=3} bsg_test_link_type_e;
    localparam test_link_id_width_lp = `BSG_SAFE_CLOG2(max_test_links_lp);
    localparam test_link_pkt_width_lp = 100;
    localparam test_link_fwd_width_lp = 97;
    localparam test_link_rev_width_lp = 53;
    localparam test_link_noc_width_lp = 64;
    localparam test_link_fwd_padding_width_lp = test_link_pkt_width_lp - test_link_fwd_width_lp;
    localparam test_link_rev_padding_width_lp = test_link_pkt_width_lp - test_link_rev_width_lp;
    localparam test_link_noc_padding_width_lp = test_link_pkt_width_lp - test_link_noc_width_lp;
    typedef struct packed {
        logic [(test_rom_payload_width_gp-test_link_pkt_width_lp-$bits(bsg_test_link_type_e)-test_link_id_width_lp)-1:0] padding;
        union packed {
            logic [test_link_pkt_width_lp-1:0] raw;
            struct packed { logic [test_link_fwd_padding_width_lp-1:0] padding; logic [test_link_fwd_width_lp-1:0] data; } fwd;
            struct packed { logic [test_link_rev_padding_width_lp-1:0] padding; logic [test_link_rev_width_lp-1:0] data; } rev;
            struct packed { logic [test_link_noc_padding_width_lp-1:0] padding; logic [test_link_noc_width_lp-1:0] data; } noc;
        } pkt;
        bsg_test_link_type_e typ;
        logic [test_link_id_width_lp-1:0] idx;
    } bsg_test_rom_manycore_s;

endpackage
