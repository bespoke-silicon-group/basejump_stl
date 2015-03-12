// MBT 9/6/2014
//
// BSG Front Side Bus
//
// This is a *full duplex* front side bus
// that allows output and input traffic
// to proceed independently, from nodes
// into the bsg out assembler; and from
// bsg in assembler to nodes.
//
// It is designed to interoperate with
// the "MURN ring protocol" and nodes,
// per UCSC's rnswitch, but without
// research features and implementing
// full duplex channels instead of a ring
// for performance reasons.
//

module bsg_fsb #(parameter  width_p = "inv"
                 ,parameter nodes_p = "inv"

                 // bit vector of master nodes
                 , parameter enabled_at_start_vec_p = { (nodes_p) { 1'b0 } }
                 , parameter snoop_vec_p            = { (nodes_p) { 1'b0 } }
                 )
   (input clk_i
    , input reset_i

    // from assembler
    , input                asm_v_i
    , input  [width_p-1:0] asm_data_i
    , output               asm_yumi_o

    // to asm
    , output               asm_v_o
    , output [width_p-1:0] asm_data_o
    , input                asm_ready_i

    // into nodes
    , output [nodes_p-1:0] node_v_o
    , output [width_p-1:0] node_data_o [nodes_p-1:0]
    , input  [nodes_p-1:0] node_ready_i

    // into nodes (control)
    , output [nodes_p-1:0] node_en_r_o
    , output [nodes_p-1:0] node_reset_r_o

    // unsupported
    // , output [nodes_p-1:0] node_powerup_o

    // out of nodes
    , input  [nodes_p-1:0] node_v_i
    , input  [width_p-1:0] node_data_i [nodes_p-1:0]
    , output [nodes_p-1:0] node_yumi_o
    );

   genvar i;

   // index is node this channel goes out of
   wire [nodes_p-1:0] in_hop_v;
   wire [width_p-1:0] in_hop_data [nodes_p-1:0];
   wire [nodes_p-1:0] in_hop_ready;

   // index is node this channel goes in to
   wire [nodes_p-1:0] out_hop_v;
   wire [width_p-1:0] out_hop_data [nodes_p-1:0];
   wire [nodes_p-1:0] out_hop_ready;



   assign out_hop_v   [nodes_p-1] = 1'b0;
   assign out_hop_data[nodes_p-1] = { (width_p) {1'b0} };

   wire               to_asm_ready;

   assign asm_yumi_o = to_asm_ready & asm_v_i;

   // make sure packets fall off of the end.
   assign in_hop_ready[nodes_p-1] = 1'b1;

   for (i = 0; i < nodes_p; i++)
     begin : fsb_node
        wire node_ready_int, node_v_int, node_en_r_int;
        wire [width_p-1:0] node_data_o_int;

        // m1 = minus 1
        wire [width_p-1:0] out_hop_data_m1;
        wire               in_hop_ready_m1, out_hop_v_m1;

        if (i == 0)
          begin
             assign to_asm_ready = in_hop_ready_m1;
             assign asm_v_o      = out_hop_v_m1;
             assign asm_data_o   = out_hop_data_m1;
          end
        else
          begin
             assign in_hop_ready[i-1] = in_hop_ready_m1;
             assign out_hop_v[i-1]    = out_hop_v_m1;
             assign out_hop_data[i-1] = out_hop_data_m1;
          end
        // note: for critical path optimization, these hops
        // can be wrapped in an additional loop that
        // instantiates multiple of these nodes, each of which
        // handles a subset of data bus.

        // create a chain of hops going in from assembler
        bsg_front_side_bus_hop_in
          #(.width_p(width_p)
            ,. fan_out_p(2)
            ) hopin
            (.clk_i(clk_i)
             ,.reset_i(reset_i)

             // (i==0) ? 0:   avoid vcs complaint of negative index.
             ,.ready_o(in_hop_ready_m1)
             ,.v_i    ((i==0) ? asm_v_i      : in_hop_v     [(i==0) ? i: i-1])
             ,.data_i ((i==0) ? asm_data_i   : in_hop_data  [(i==0) ? i: i-1])

             ,.v_o    ({node_v_int      , in_hop_v    [i]})
             ,.data_o ({node_data_o_int , in_hop_data [i]}) // 1=local node, 0 is next node
             // note: the node does valid->ready
             // but should be located nearby so it's okay
             ,.ready_i({node_ready_int, in_hop_ready[i]})
             );

        // create a chain of hops going out to assembler

        bsg_front_side_bus_hop_out #(.width_p(width_p)) hopout
          (.clk_i(clk_i)
           ,.reset_i(reset_i)
           // we can't transmit data unless the node is enabled
           ,.v_i    ({node_en_r_int & node_v_i    [i], out_hop_v   [i]})
           ,.data_i ({node_data_i [i], out_hop_data[i]})
           ,.ready_o(out_hop_ready[i])
           ,.yumi_o (node_yumi_o  [i])

           // (i==0) ? 0:   avoid vcs complaint of negative index.
           ,.v_o    (out_hop_v_m1)
           ,.data_o (out_hop_data_m1)
           ,.ready_i((i==0) ? asm_ready_i : out_hop_ready[(i==0) ? 0:i-1])
           );

        bsg_fsb_murn_gateway #(.width_p(width_p)
                               ,.id_p(i)
                               ,.enabled_at_start_p(enabled_at_start_vec_p[i])
                               ,.snoop_p(snoop_vec_p[i])
                               ) murn_gateway

          (.clk_i          (clk_i)
           ,.reset_i       (reset_i)

           // from gateway
           ,.v_i           (node_v_int)
           ,.data_i        (node_data_o_int)
           ,.ready_o       (node_ready_int)

           // to node
           // updated valid bit based on enable
           // and filtering out switch command packets

           ,.ready_i       (node_ready_i  [i])
           ,.v_o           (node_v_o      [i])
           ,.node_en_r_o   (node_en_r_int    )
           ,.node_reset_r_o(node_reset_r_o[i])
           );

        // avoid lint warnings
        assign node_data_o[i] = node_data_o_int;
        assign node_en_r_o[i] = node_en_r_int;

	// synopsys translate_off
        always @(negedge node_reset_r_o[i])
          $display("## reset low on FSB in module %m, node %-d",i);
        // synopsys translate_on

     end

endmodule

