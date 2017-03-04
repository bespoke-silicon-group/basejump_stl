// MBT 7/7/2016
//
// 1 read-port, 1 write-port ram
//
// reads are synchronous

module bsg_mem_1r1w_sync_mask_write_bit_synth_custom #(  parameter width_p=-1
						       , parameter els_p=-1
						       , parameter read_write_same_addr_p=0
						       , parameter partial_collision_p=0
						       , parameter collision_val_p=1'hx
						       , parameter read_before_write_p=1
						       , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
						       , parameter harden_p=0
                                                      )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    , input [width_p-1:0]       w_mask_i
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

   logic [width_p-1:0] r_data_w;

   always_ff @(posedge clk_i)
     begin

        integer n;

        r_data_w = 0;

        if (r_v_i)
          if ((r_addr_i == w_addr_i) && w_v_i && !read_before_write_p)
          begin
            //r_data_w = (mem[r_addr_i] & ~w_mask_i) | (w_data_i & w_mask_i);
            for(n=0; n<width_p; n=n+1)
            begin
              if (w_mask_i[n])
                r_data_w[n] = w_data_i[n];
              else
                r_data_w[n] = mem[r_addr_i][n];
            end
          end
          else
          begin
            r_data_w = mem[r_addr_i];
          end

        // synopsys translate_off
        else
          r_data_w = 'X;

        // if addresses match and this is forbidden, then nuke the read address

        if (r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p)
          begin
             $error("X'ing matched read address %x (%m)",r_addr_i);
             if (partial_collision_p)
             begin
               //r_data_w = (r_data_w & ~w_mask_i) | ({width_p{collision_val_p[0]}} & w_mask_i);
               for(n=0; n<width_p; n=n+1)
               begin
                 if (w_mask_i[n])
                   r_data_w[n] = collision_val_p[0];
                 else
                   r_data_w[n] = r_data_w[n];
               end
             end
             else
             begin
               //r_data_w = {width_p{collision_val_p[0]}};
               for(n=0; n<width_p; n=n+1)
               begin
                 r_data_w[n] = collision_val_p[0];
               end
             end

             $error("Assigning data = %x", r_data_w);
          end
        // synopsys translate_on

        r_data_o <= r_data_w;

     end

   genvar                       i;
   for (i = 0; i < width_p; i=i+1)
     begin
	always_ff @(posedge clk_i)

	  if (w_v_i && w_mask_i[i])
            mem[w_addr_i][i] <= w_data_i[i];
     end

endmodule
