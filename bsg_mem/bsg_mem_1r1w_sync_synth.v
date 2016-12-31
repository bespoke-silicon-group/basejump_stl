// MBT 7/7/2016
//
// 1 read-port, 1 write-port ram
//
// reads are synchronous
//
// although we could merge this with normal bsg_mem_1r1w
// and select with a parameter, we do not do this because
// it's typically a very big change to the instantiating code
// to move to/from sync/async, and we want to reflect this.
//

module bsg_mem_1r1w_sync_synth #(parameter width_p=-1
				 , parameter els_p=-1
				 , parameter read_write_same_addr_p=0
				 , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
				 , parameter harden_p=0
				 )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

   logic [width_p-1:0]    mem [els_p-1:0];

   wire                   unused = reset_i;

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

   logic [addr_width_lp-1:0] r_addr_r;

   always_ff @(posedge clk_i)
     if (r_v_i)
       r_addr_r <= r_addr_i;
     else
       r_addr_r <= 'X;

   assign r_data_o = mem[r_addr_r];

   always_ff @(posedge clk_i)
     if (w_v_i)
       mem[w_addr_i] <= w_data_i;

endmodule
