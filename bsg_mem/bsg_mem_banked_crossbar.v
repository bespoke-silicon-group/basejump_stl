
/*****************************************
* banked memory crossbar
******************************************/

module bsg_mem_banked_crossbar #
  ( parameter num_ports_p  = -1
   ,parameter num_banks_p  = -1

   ,parameter bank_size_p        = -1 // power of 2
    // fairness policy (2=round robin, 1=fixed lo, 0=fixed hi)
   ,parameter rr_lo_hi_p         = "inv"
   ,parameter addr_hash_width_lp = `BSG_SAFE_CLOG2(num_banks_p)
   ,parameter bank_addr_width_lp = `BSG_SAFE_CLOG2(bank_size_p)
    // fixme: this is a little weird as an interface.
   ,parameter addr_width_lp      = (num_banks_p == 1)?
                                    bank_addr_width_lp
                                    : addr_hash_width_lp + bank_addr_width_lp

   ,parameter data_width_p  = -1
   ,parameter debug_p = 0
   ,parameter debug_reads_p = debug_p
   ,parameter mask_width_lp = data_width_p >> 3
  )
  ( input                                       clk_i
   ,input                                       reset_i
   //the reverse the priority for the dynamic scheme
   ,input                                reverse_pr_i

   ,input [num_ports_p-1:0]                     v_i
   ,input [num_ports_p-1:0]                     w_i
   ,input [num_ports_p-1:0][addr_width_lp-1:0]  addr_i
   ,input [num_ports_p-1:0][data_width_p-1:0]   data_i
   ,input [num_ports_p-1:0][mask_width_lp-1:0]  mask_i  // 1 = write byte

   ,output [num_ports_p-1:0]                    yumi_o
   ,output [num_ports_p-1:0]                    v_o
   ,output [num_ports_p-1:0][data_width_p-1:0]  data_o
  );

   localparam debug_lp = debug_p;
//   localparam debug_lp = 4;
   localparam debug_reads_lp = debug_reads_p;
//   localparam debug_reads_lp = 1;

  // synopsys translate_off
  initial
    assert((bank_size_p & bank_size_p-1) == 0)
      else $error("bank_size_p must be a power of 2");

  // synopsys translate_on


  logic [num_ports_p-1:0][addr_hash_width_lp-1:0] bank_reqs;

  genvar i;

  // synopsys translate_off
   logic [num_ports_p-1:0][addr_width_lp-1:0] addr_r;

   always_ff @(posedge clk_i)
     addr_r <= addr_i;

   for (i=0; i<num_ports_p; i=i+1)
     if (debug_lp > 1)
       always_ff @(negedge clk_i)
//       if ((addr_i[i] == ('h310 >> 2) || (addr_r[i] == ('h310 >> 2))))
         begin
            if (v_i[i] & yumi_o[i])
              begin
                 if (w_i[i])
                   $display("%m port %d [%x]=%x (mask_i=%b)", i,addr_i[i]*debug_lp,data_i[i],mask_i[i]);
                 else if (debug_reads_lp)
                   $display("%m port %d           = [%x]",i,addr_i[i]*debug_lp);
              end
            if (v_o[i] && debug_reads_lp)
              $display("%m port %d  %x = [%x]", i,data_o[i],addr_r[i]*debug_lp);
         end
  // synopsys translate_on

  if(num_banks_p > 1)
    for(i=0; i<num_ports_p; i=i+1)
      assign bank_reqs[i] = addr_i[i][bank_addr_width_lp+:addr_hash_width_lp];
  else
    assign bank_reqs = 1'b0;


   logic [num_banks_p-1:0][num_ports_p-1:0] bank_port_grants_one_hot
                                            , bank_port_grants_one_hot_r;
   logic [num_banks_p-1:0]                  bank_v, bank_v_r;

   bsg_crossbar_control_o_by_i #( .i_els_p(num_ports_p)
                                  ,.o_els_p(num_banks_p)
                                  ,.rr_lo_hi_p(rr_lo_hi_p)
                                  ) crossbar_control
     ( .clk_i              (clk_i)
       ,.reset_i            (reset_i)
       ,.reverse_pr_i       (reverse_pr_i)
       // ports
       ,.valid_i            (v_i)
       ,.sel_io_i           (bank_reqs)
       ,.yumi_o             (yumi_o)

       // banks
       ,.ready_i            ({num_banks_p{1'b1}})
       ,.valid_o            (bank_v)
       ,.grants_oi_one_hot_o(bank_port_grants_one_hot)
       );


  logic [num_banks_p-1:0][data_width_p-1:0] bank_data, bank_data_out;

  bsg_crossbar_o_by_i #( .i_els_p(num_ports_p)
                        ,.o_els_p(num_banks_p)
                        ,.width_p(data_width_p)
                       ) port_bank_data_crossbar
                       ( .i               (data_i)
                        ,.sel_oi_one_hot_i(bank_port_grants_one_hot)
                        ,.o               (bank_data)
                       );


  logic [num_ports_p-1:0][bank_addr_width_lp-1:0] bank_req_addr;

  for(i=0; i<num_ports_p; i=i+1)
    assign bank_req_addr[i] = addr_i[i][0+:bank_addr_width_lp];


  logic [num_banks_p-1:0][bank_addr_width_lp-1:0] bank_addr;

  bsg_crossbar_o_by_i #( .i_els_p(num_ports_p)
                        ,.o_els_p(num_banks_p)
                        ,.width_p(bank_addr_width_lp)
                       ) port_bank_addr_crossbar
                       ( .i               (bank_req_addr)
                        ,.sel_oi_one_hot_i(bank_port_grants_one_hot)
                        ,.o               (bank_addr)
                       );


  logic [num_banks_p-1:0] bank_w, bank_w_r;

  bsg_crossbar_o_by_i #( .i_els_p(num_ports_p)
                        ,.o_els_p(num_banks_p)
                        ,.width_p(1)
                       ) port_bank_w_crossbar
                       ( .i               (w_i)
                        ,.sel_oi_one_hot_i(bank_port_grants_one_hot)
                        ,.o               (bank_w)
                       );


  logic [num_banks_p-1:0][mask_width_lp-1:0] bank_mask;

  bsg_crossbar_o_by_i #( .i_els_p(num_ports_p)
                        ,.o_els_p(num_banks_p)
                        ,.width_p(mask_width_lp)
                       ) port_bank_mask_crossbar
                       ( .i               (mask_i)
                        ,.sel_oi_one_hot_i(bank_port_grants_one_hot)
                        ,.o               (bank_mask)
                       );




  for(i=0; i<num_banks_p; i=i+1)
  begin: z

   // synopsys translate_off
   if (debug_lp > 1)
     always @(negedge clk_i)
       begin
          if (bank_v[i])
            if (bank_w[i])
              $display("%m [%x] <= %d", bank_addr[i]*debug_p, bank_data[i]);
            else
              $display("%m <= [%x]", bank_addr[i]*debug_p);
       end
   // synopsys translate_on

    // to be replaced with bsg_mem_1rw_sync_byte_masked
    bsg_mem_1rw_sync_mask_write_byte #( .data_width_p (data_width_p)
                                       ,.els_p        (bank_size_p)
                                      ) m1rw_mask
                                      ( .clk_i        (clk_i)
                                       ,.reset_i      (reset_i)
                                       ,.data_i       (bank_data[i])
                                       ,.addr_i       (bank_addr[i])
                                       ,.v_i          (bank_v[i])
                                       ,.w_i          (bank_w[i])
                                       ,.write_mask_i (bank_mask[i])
                                       ,.data_o       (bank_data_out[i])
                                      );
  end


  always_ff @(posedge clk_i)
  begin
    bank_port_grants_one_hot_r <= bank_port_grants_one_hot;
    bank_w_r                   <= bank_w;
    bank_v_r                   <= bank_v;
  end


  logic [num_ports_p-1:0][num_banks_p-1:0] port_bank_grants_one_hot;

  bsg_transpose #( .width_p(num_ports_p)
                  ,.els_p  (num_banks_p)
                 ) grants_transpose
                 ( .i(bank_port_grants_one_hot_r)
                  ,.o(port_bank_grants_one_hot)
                 );

  bsg_crossbar_o_by_i #( .i_els_p(num_banks_p)
                        ,.o_els_p(num_ports_p)
                        ,.width_p(data_width_p)
                       ) bank_port_data_crossbar
                       ( .i               (bank_data_out)
                        ,.sel_oi_one_hot_i(port_bank_grants_one_hot)
                        ,.o               (data_o)
                       );

  bsg_crossbar_o_by_i #( .i_els_p(num_banks_p)
                        ,.o_els_p(num_ports_p)
                        ,.width_p(1)
                       ) bank_port_v_crossbar
                       ( .i               (bank_v_r & ~bank_w_r)
                        ,.sel_oi_one_hot_i(port_bank_grants_one_hot)
                        ,.o               (v_o)
                       );

endmodule // bsg_mem_banked_crossbar
