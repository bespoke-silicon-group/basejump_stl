
`include "bsg_defines.v"

module bsg_fsb_to_nasti_master_connector
import bsg_nasti_pkg::bsg_nasti_addr_channel_s;
import bsg_nasti_pkg::bsg_nasti_write_data_channel_s;
import bsg_nasti_pkg::bsg_nasti_read_data_channel_s;
import bsg_nasti_pkg::bsg_nasti_write_response_channel_s;

 #(parameter ring_width_p=$bits(bsg_fsb_pkg::RingPacketType)
  , dest_id_p="not set")
(
 input  clk_i
 , input reset_i
 , input bsg_nasti_addr_channel_s nasti_read_addr_ch_i
 , output logic                   nasti_read_addr_ch_ready_o

 , input bsg_nasti_addr_channel_s nasti_write_addr_ch_i
 , output logic                   nasti_write_addr_ch_ready_o

 , input bsg_nasti_write_data_channel_s nasti_write_data_ch_i
 , output logic                         nasti_write_data_ch_ready_o

 , output       bsg_nasti_read_data_channel_s      nasti_read_data_ch_o
 , input                                           nasti_read_data_ch_ready_i

 , output       bsg_nasti_write_response_channel_s nasti_write_resp_ch_o
 , input                                           nasti_write_resp_ch_ready_i

 // from fsb
 , input fsb_v_i
 , input [ring_width_p-1:0] fsb_data_i
 , output logic fsb_ready_o

 // to fsb
 , output fsb_v_o
 , output [ring_width_p-1:0] fsb_data_o
 , input fsb_yumi_i
);

   import bsg_fsb_pkg::RingPacketType;

   // first we buffer the packets and convert flow control
   logic                   out_fifo_ready;
   RingPacketType          out_fifo_data;
   logic                   out_fifo_v;


   RingPacketType ring_data_in, ring_data_out;

   bsg_two_fifo #( .width_p(ring_width_p)) fifo_out
     (.clk_i(clk_i)

      ,.reset_i(reset_i)

      ,.ready_o(out_fifo_ready)
      ,.v_i    (out_fifo_v    )
      ,.data_i (out_fifo_data )

      ,.v_o   (fsb_v_o   )
      ,.data_o(fsb_data_o)
      ,.yumi_i(fsb_yumi_i)
      );

   // encode outgoing data
   assign out_fifo_data = ring_data_out;

   // channels are going out from the nasti master to the fsb. we need to multiplex them.
   always @(*)
     begin
        out_fifo_v = nasti_read_addr_ch_i.v
                     | nasti_write_addr_ch_i.v
                     | nasti_write_data_ch_i.v;

        ring_data_out.cmd = 1'b0;

        // keep it blank for now
        ring_data_out.data = 64'b0;

        nasti_read_addr_ch_ready_o  = 1'b0;
        nasti_write_addr_ch_ready_o = 1'b0;
        nasti_write_data_ch_ready_o = 1'b0;

        if (nasti_read_addr_ch_i.v)
          begin: ra
             ring_data_out.data[31:0]   = nasti_read_addr_ch_i.addr;
             ring_data_out.data[32+:5]  = nasti_read_addr_ch_i.id;
             ring_data_out.opcode       = 7'b000_0100;
             nasti_read_addr_ch_ready_o = out_fifo_ready;
          end
        else if (nasti_write_addr_ch_i.v)
          begin : wa
             ring_data_out.data[31:0]   = nasti_write_addr_ch_i.addr;
             ring_data_out.data[32+:5]  = nasti_write_addr_ch_i.id;
             ring_data_out.opcode       = 7'b000_0101;
             nasti_write_addr_ch_ready_o = out_fifo_ready;
          end
        else if (nasti_write_data_ch_i.v)
          begin: wd
             ring_data_out.data[63:0] = nasti_write_data_ch_i.data;
             if (nasti_write_data_ch_i.last)
               ring_data_out.opcode    = 7'b000_0111;
             else
               ring_data_out.opcode    = 7'b000_0110;
             nasti_write_data_ch_ready_o = out_fifo_ready;
          end
     end

   // channels are also coming in from the fsb to the nasti master. we need
   // to demultiplex them

   // first buffer all of the signals with a fifo
   // because we cannot reliable assert ready without
   // inspecting the input packets

   wire [ring_width_p-1:0] in_fifo_data;
   logic                   in_fifo_yumi;
   wire                    in_fifo_v;

   bsg_two_fifo #( .width_p(ring_width_p)) fifo_in
     (.clk_i(clk_i)

      ,.reset_i(reset_i)

      ,.ready_o(fsb_ready_o)
      ,.v_i    (fsb_v_i    )
      ,.data_i (fsb_data_i )

      ,.v_o   (in_fifo_v)
      ,.data_o(in_fifo_data)
      ,.yumi_i(in_fifo_yumi)
      );

   // demultiplex incoming data
   assign ring_data_in  = in_fifo_data;

   always @(*)
     begin
        nasti_read_data_ch_o.v    = 1'b0;
        nasti_read_data_ch_o.data = ring_data_in.data;
        nasti_read_data_ch_o.id   = ring_data_in.opcode[4:0];
        nasti_read_data_ch_o.resp = 2'b0; // fixme is this the right value?
        nasti_read_data_ch_o.last = 1'b0;

        nasti_write_resp_ch_o.v    = 1'b0;
        nasti_write_resp_ch_o.id   = ring_data_in.data[4:0];
	nasti_write_resp_ch_o.resp = ring_data_in.data[6:5];

        in_fifo_yumi = 1'b0;

        if (in_fifo_v & ~ring_data_in.cmd)
          begin
             // handle read response and write response
             unique casez ( ring_data_in.opcode )
               // write response
               7'b000_1000:
               begin
                  nasti_write_resp_ch_o.v = 1'b1;
                  in_fifo_yumi = nasti_write_resp_ch_ready_i;
               end
               // read response not last
               7'b10?_????:
                 begin
                    nasti_read_data_ch_o.v = 1'b1;
                    in_fifo_yumi = nasti_read_data_ch_ready_i;
                 end
               // read response last
               7'b11?_????:
                 begin
                    nasti_read_data_ch_o.v = 1'b1;
                    nasti_read_data_ch_o.last = 1'b1;
                    in_fifo_yumi = nasti_read_data_ch_ready_i;
                 end
             default:
                 $display("*** %m unmatched opcode for fsb_to_nasti_master",ring_data_in.opcode);

             endcase // unique casez ( ring_data_in.opcode )
          end

     end // always @ (*)



endmodule // fsb_to_nasti_master_connector
