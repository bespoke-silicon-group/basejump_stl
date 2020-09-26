// MBT September 6, 2014
//
// This implements the subset of the MURN ring
// protocol that is supported by the GF28 chip.
//
// The protocol was designed by UCSC's Jose Renau
// and Rigo Dicochea in 2011.
//
// Omitted: Power Enable/Disable
//
//
`include "bsg_defines.v"

`ifndef  FSB_LEGACY 
`include "bsg_fsb_pkg.v"

module bsg_fsb_murn_gateway
   #(parameter width_p="inv"
   , parameter id_p="inv"
   , parameter id_width_p="inv"
   // resets with core reset
   // rather than by a command.
   , parameter enabled_at_start_p=0
   // once the node is enabled
   // look at all packets;
   // useful if we would like to
   // test and ignore packet formats
   , parameter snoop_p=0
   )
   (input    clk_i

    // from/to switch
    , input  reset_i
    , input  v_i
    , input  [width_p-1:0] data_i
    , output ready_o // note this inspects v_i, so technically is v_i->ready_o
                     // but the underlying bsg_test_node is true v_i / ready_o

    // from node
    , output v_o
    , input  ready_i
    , output node_en_r_o
    , output node_reset_r_o
    );

   `declare_bsg_fsb_pkt_s(width_p, id_width_p)
   // if we are in snoop mode and don't need a wakeup
   // packet, we keep it simple and avoid having
   // a dependency on the packet format.

   if (snoop_p & enabled_at_start_p)
     begin
        assign v_o            = v_i;
        assign ready_o        = ready_i;
        assign node_reset_r_o = reset_i;
        assign node_en_r_o    = 1'b1;

        wire stop_lint_unused_warning = clk_i | (|data_i);

     end
   else
     begin
        logic node_en_r   , node_en_n;
        logic node_reset_r, node_reset_n;

        assign node_en_r_o    = node_en_r;
        assign node_reset_r_o = node_reset_r;


        bsg_fsb_pkt_s data_RPT;
        assign data_RPT = bsg_fsb_pkt_s ' (data_i);

        wire  id_match      = data_RPT.destid == id_p;
        wire  for_this_node = v_i & (id_match | snoop_p) ;

        // once this switch is enabled, then switch packets are ignored in snoop mode
        wire  for_switch    = ~(snoop_p & node_en_r) & v_i & (id_match) & (data_RPT.cmd == 1'b1);

        // filter out traffic for switch
        assign  v_o           = node_en_r & for_this_node & ~for_switch;

        // we will sink packets:
        //  - if the node is not enabled
        //  - if the message is valid and node is actually ready for the packet
        //  - or if the message is not for us

        assign  ready_o       = v_i   // guard against X propagation
                                & (~node_en_r        // node is sleeping
                                   | ready_i         // node actually is ready
                                   | for_switch      // message is for a switch
                                   | ~for_this_node  // message is for another node
                                   );

        // on "real" reset initialize node_en to 1, otherwise 0.
        always_ff @(posedge clk_i)
          node_en_r     <= reset_i ? (enabled_at_start_p != 0) : node_en_n;

        // if we are master, the reset is fed straight through
        if (enabled_at_start_p)
             always_ff @(posedge clk_i)
               node_reset_r  <= reset_i;
        else
          begin
             // we start with reset set to high on the node
             // so that it clears its stuff out
             always_ff @(posedge clk_i)
               if (reset_i)
                 node_reset_r  <= 1'b1;
               else
                 node_reset_r  <= node_reset_n;
          end

        always_comb
          begin
             node_en_n    = node_en_r;
             node_reset_n = node_reset_r;

             if (for_switch)
               unique case(data_RPT.opcode)
                    RNENABLE_CMD:        node_en_n    = 1'b1;
                    RNDISABLE_CMD:       node_en_n    = 1'b0;

                    RNRESET_ENABLE_CMD:  node_reset_n = 1'b1;
                    RNRESET_DISABLE_CMD: node_reset_n = 1'b0;
                    default:
                      begin
                      end
               endcase // unique case (data_RPT.opcode)
          end // always_comb
end // else: !if(snoop_p & enabled_at_start_p)

endmodule
`else
//  ______ _____ ____   _      ______ _____          _______     __ 
// |  ____/ ____|  _ \ | |    |  ____/ ____|   /\   / ____\ \   / / 
// | |__ | (___ | |_) || |    | |__ | |  __   /  \ | |     \ \_/ /  
// |  __| \___ \|  _ < | |    |  __|| | |_ | / /\ \| |      \   /   
// | |    ____) | |_) || |____| |___| |__| |/ ____ \ |____   | |    
// |_|   |_____/|____/ |______|______\_____/_/    \_\_____|  |_|    
//                 ______                                           
//                |______| 

module bsg_fsb_murn_gateway
   import bsg_fsb_pkg::*;
   #(parameter width_p="inv"
   , parameter id_p="inv"
   // resets with core reset
   // rather than by a command.
   , parameter enabled_at_start_p=0
   // once the node is enabled
   // look at all packets;
   // useful if we would like to
   // test and ignore packet formats
   , parameter snoop_p=0
   )
   (input    clk_i

    // from/to switch
    , input  reset_i
    , input  v_i
    , input  [width_p-1:0] data_i
    , output ready_o // note this inspects v_i, so technically is v_i->ready_o
                     // but the underlying bsg_test_node is true v_i / ready_o

    // from node
    , output v_o
    , input  ready_i
    , output node_en_r_o
    , output node_reset_r_o
    );

   // if we are in snoop mode and don't need a wakeup
   // packet, we keep it simple and avoid having
   // a dependency on the packet format.

   if (snoop_p & enabled_at_start_p)
     begin
        assign v_o            = v_i;
        assign ready_o        = ready_i;
        assign node_reset_r_o = reset_i;
        assign node_en_r_o    = 1'b1;

        wire stop_lint_unused_warning = clk_i | (|data_i);

     end
   else
     begin
        logic node_en_r   , node_en_n;
        logic node_reset_r, node_reset_n;

        assign node_en_r_o    = node_en_r;
        assign node_reset_r_o = node_reset_r;


        bsg_fsb_pkt_s data_RPT;
        assign data_RPT = bsg_fsb_pkt_s ' (data_i);

        wire  id_match      = data_RPT.destid == id_p;
        wire  for_this_node = v_i & (id_match | snoop_p) ;

        // once this switch is enabled, then switch packets are ignored in snoop mode
        wire  for_switch    = ~(snoop_p & node_en_r) & v_i & (id_match) & (data_RPT.cmd == 1'b1);

        // filter out traffic for switch
        assign  v_o           = node_en_r & for_this_node & ~for_switch;

        // we will sink packets:
        //  - if the node is not enabled
        //  - if the message is valid and node is actually ready for the packet
        //  - or if the message is not for us

        assign  ready_o       = v_i   // guard against X propagation
                                & (~node_en_r        // node is sleeping
                                   | ready_i         // node actually is ready
                                   | for_switch      // message is for a switch
                                   | ~for_this_node  // message is for another node
                                   );

        // on "real" reset initialize node_en to 1, otherwise 0.
        always_ff @(posedge clk_i)
          node_en_r     <= reset_i ? (enabled_at_start_p != 0) : node_en_n;

        // if we are master, the reset is fed straight through
        if (enabled_at_start_p)
             always_ff @(posedge clk_i)
               node_reset_r  <= reset_i;
        else
          begin
             // we start with reset set to high on the node
             // so that it clears its stuff out
             always_ff @(posedge clk_i)
               if (reset_i)
                 node_reset_r  <= 1'b1;
               else
                 node_reset_r  <= node_reset_n;
          end

        always_comb
          begin
             node_en_n    = node_en_r;
             node_reset_n = node_reset_r;

             if (for_switch)
               unique case(data_RPT.opcode)
                    RNENABLE_CMD:        node_en_n    = 1'b1;
                    RNDISABLE_CMD:       node_en_n    = 1'b0;

                    RNRESET_ENABLE_CMD:  node_reset_n = 1'b1;
                    RNRESET_DISABLE_CMD: node_reset_n = 1'b0;
                    default:
                      begin
                      end
               endcase // unique case (data_RPT.opcode)
          end // always_comb
end // else: !if(snoop_p & enabled_at_start_p)

endmodule
`endif
