
`include "bsg_defines.v"

module bsg_fsb_to_nasti_slave_connector
import bsg_fsb_pkg::RingPacketType;
import bsg_nasti_pkg::bsg_nasti_addr_channel_s;
import bsg_nasti_pkg::bsg_nasti_write_data_channel_s;
import bsg_nasti_pkg::bsg_nasti_read_data_channel_s;
import bsg_nasti_pkg::bsg_nasti_write_response_channel_s;

#(parameter ring_width_p=$bits(bsg_fsb_pkg::RingPacketType)
  , destid_p="inv")
(
 input  clk_i
 , input reset_i
 , output bsg_nasti_addr_channel_s nasti_read_addr_ch_o
 , input  logic                    nasti_read_addr_ch_ready_i

 , output bsg_nasti_addr_channel_s nasti_write_addr_ch_o
 , input  logic                    nasti_write_addr_ch_ready_i

 , output bsg_nasti_write_data_channel_s nasti_write_data_ch_o
 , input  logic                          nasti_write_data_ch_ready_i

 , input  bsg_nasti_read_data_channel_s  nasti_read_data_ch_i
 , output logic                          nasti_read_data_ch_ready_o

 , input  bsg_nasti_write_response_channel_s nasti_write_resp_ch_i
 , output logic                              nasti_write_resp_ch_ready_o

 // from fsb
 , input fsb_v_i
 , input [ring_width_p-1:0] fsb_data_i
 , output logic fsb_ready_o

 // to fsb
 , output logic fsb_v_o
 , output logic [ring_width_p-1:0] fsb_data_o
 , input fsb_yumi_i
);

   // first buffer all of the signals with a fifo
   // because we cannot reliable assert ready without
   // inspecting the input packets

   logic [ring_width_p-1:0] in_fifo_data;
   logic                    in_fifo_yumi;
   logic                    in_fifo_v;

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

   RingPacketType ring_data_in, ring_data_out;

   // demultiplex incoming data
   assign ring_data_in  = in_fifo_data;

   // handle channels going to nasti
   // we demultiplex packets going from fsb to nasti
   always @(*)
     begin
        nasti_read_addr_ch_o.v     = 1'b0;
        nasti_read_addr_ch_o.addr  = ring_data_in.data[31:0];
        nasti_read_addr_ch_o.id    = ring_data_in.data[32+:5];
        nasti_read_addr_ch_o.size  = 3'b11; // fixme; hardcode this to correct val
        nasti_read_addr_ch_o.len   = 8'b111;   // fixme; hardcode this to correct val

        nasti_write_addr_ch_o.v    = 1'b0;
        nasti_write_addr_ch_o.addr = ring_data_in.data[31:0];
        nasti_write_addr_ch_o.id   = ring_data_in.data[32+:5];
        nasti_write_addr_ch_o.size = 3'b11; // fixme; hardcode this to correct val
        nasti_write_addr_ch_o.len  = 8'b111;   // fixme; hardcode this to correct val

        nasti_write_data_ch_o.v    = 1'b0;
        nasti_write_data_ch_o.data = ring_data_in.data[63:0];
        nasti_write_data_ch_o.strb = 8'b1111_1111; // fixme; hardcode this to correct val
        nasti_write_data_ch_o.last = 1'b0;

        in_fifo_yumi = 1'b0;

        if (in_fifo_v & ~ring_data_in.cmd)
          begin
             // note, these are only requests from master to slave
             unique casez  (ring_data_in.opcode)
                  // read request addr
                  7'b000_0100:
                    begin
                       nasti_read_addr_ch_o.v  = 1'b1;
                       in_fifo_yumi = nasti_read_addr_ch_ready_i;
                    end
                 // write request addr
                  7'b000_0101:
                    begin
                       nasti_write_addr_ch_o.v = 1'b1;
                       in_fifo_yumi = nasti_write_addr_ch_ready_i;
                    end
                 // write request data not last
                  7'b000_0110:
                    begin
                       nasti_write_data_ch_o.v = 1'b1;
                       in_fifo_yumi = nasti_write_data_ch_ready_i;
                    end
                 // write request data last
                  7'b000_0111:
                    begin
                       nasti_write_data_ch_o.v    = 1'b1;
                       nasti_write_data_ch_o.last = 1'b1;
                       in_fifo_yumi               = nasti_write_data_ch_ready_i;
                    end
               default:
                 begin
                    $display("*** %m unmatched opcode for fsb_to_nasti_slave",ring_data_in.opcode);
                 end
                   endcase // unique casez {

             end // if (in_fifo_v && ring_data_in.cmd)
     end // always @ (*)


   logic                    out_fifo_ready;
   RingPacketType           out_fifo_data;
   logic                    out_fifo_v;

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

   // these are channels coming in from nasti slave
   // we need to multiplex them onto the FSB
   // interconnect. what's more important, read
   // responses or write responses?

   assign out_fifo_data = ring_data_out;

   always @(*)
     begin
        out_fifo_v = nasti_read_data_ch_i.v
                     | nasti_write_resp_ch_i.v;
        ring_data_out.data   = nasti_read_data_ch_i.data;
        ring_data_out.cmd    = 1'b0;
        // per AXI4 spec, valid must be continuously asserted
        // once first asserted
        // but not so for ready signal
        nasti_read_data_ch_ready_o = 1'b0;
        nasti_write_resp_ch_ready_o = 1'b0;

        if (nasti_read_data_ch_i.v)
          begin : rd
             ring_data_out.opcode[6]    = 1'b1;
             ring_data_out.opcode[5]    = nasti_read_data_ch_i.last;
             ring_data_out.opcode[4:0]  = nasti_read_data_ch_i.id;
             nasti_read_data_ch_ready_o = out_fifo_ready;
          end
        else
          begin : wr
             ring_data_out.opcode=7'b0001000;
             nasti_write_resp_ch_ready_o = out_fifo_ready;
             ring_data_out.data[4:0] = nasti_write_resp_ch_i.id;
             ring_data_out.data[6:5] = nasti_write_resp_ch_i.resp;
             // fixme: where does the ID go?
          end

        ring_data_out.srcid  = 4'b0; // fixme
        // we have a hardcoded destid_p, which is okay
        // because this thing will be in FPGA
        ring_data_out.destid = destid_p ;
     end // always @ (*)


endmodule

