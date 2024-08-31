
`include "bsg_defines.sv"

module bsg_mem_2rw_sync_synth #( parameter `BSG_INV_PARAM(width_p )
                         , parameter `BSG_INV_PARAM(els_p )
                         , parameter read_write_same_addr_p=0
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         , parameter harden_p = 1
                         , parameter disable_collision_warning_p=0                   
                         )
  ( input                      clk_i
  , input                      reset_i

  , input [width_p-1:0]        a_data_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [width_p-1:0]        b_data_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [width_p-1:0] a_data_o
  , output logic [width_p-1:0] b_data_o
  );

   wire                   unused = reset_i;

   if (width_p == 0)
    begin: z
      wire unused0 = &{clk_i, a_data_i, a_addr_i, a_v_i, a_w_i};
      wire unused1 = &{clk_i, b_data_i, b_addr_i, b_v_i, b_w_i};
      assign a_data_o = '0;
      assign b_data_o = '0;
    end
   else
    begin: nz

   logic [width_p-1:0]    mem [els_p-1:0];

   // this treats the ram as an array of registers for which the
   // read addr is latched on the clock, the write
   // is done on the clock edge, and actually multiplexing
   // of the registers for reading is done after the clock edge.

   // logically, this means that reads happen in time after
   // the writes, and "simultaneous" reads and writes to the
   // register file are allowed -- IF read_write_same_addr is set.

   // note that this behavior is generally incompatible with
   // hardened 1r1w rams, so it's better not to take advantage
   // of it if not necessary

   // we explicitly 'X out the read address if valid is not set
   // to avoid accidental use of data when the valid signal was not
   // asserted. without this, the output of the register file would
   // "auto-update" based on new writes to the ram, a spooky behavior
   // that would never correspond to that of a hardened ram.

   logic [addr_width_lp-1:0] a_addr_r, b_addr_r;

   always_ff @(posedge clk_i)
     begin
        if (a_v_i)
            a_addr_r <= a_addr_i;
        else
            a_addr_r <= 'X;
          
        if (b_v_i)
            b_addr_r <= b_addr_i;
        else
            b_addr_r <= 'X;

`ifndef BSG_HIDE_FROM_SYNTHESIS
        // if addresses match and this is forbidden, then nuke the read address

        if (a_addr_i == b_addr_i && a_v_i && b_v_i && (a_w_i || b_w_i) && !read_write_same_addr_p)
          begin
             if (!disable_collision_warning_p)
               begin
                 $error("X'ing matched read address %x (%m)",a_addr_i);
               end
             a_addr_r <= 'X;
             b_addr_r <= 'X;
          end
`endif

     end

   assign a_data_o = mem[a_addr_r];
   assign b_data_o = mem[b_addr_r];

	always_ff @(posedge clk_i)
    begin
	  if (a_v_i & a_w_i)
            mem[a_addr_i] <= a_data_i;
	  if (b_v_i & b_w_i)
            mem[b_addr_i] <= b_data_i;
    end
  end
endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_synth)

