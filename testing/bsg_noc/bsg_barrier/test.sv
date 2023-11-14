module test;
  
  genvar i;
  localparam nodes_p=7;
  wire [nodes_p:0] wi_nets, ei_nets;
  logic [nodes_p-1:0] pi_nets, po_nets;
  logic clk_li, reset_li;
  
  
  // program the barrier network
  //
  //                                   WEP
  localparam [nodes_p-1:0][2:0] ins_p = {   3'b001 /* east end node */
                                  , 3'b011 /* east middle node */
                                  , 3'b111 /* center node */
                                  , 3'b101 /* west middle node */
                                  , 3'b101 /* west middle node */
                                  , 3'b101 /* west middle node */
                                  , 3'b001 /* west end node */ };
  
  localparam [nodes_p-1:0][1:0] outs_p = { 2'd2 /*node  6 W  */
                                  ,2'd2 /*node  5 W  */
                                  ,2'd3 /*node  4 X  */
                                  ,2'd1 /*nodes 3 E  */
                                  ,2'd1 /*nodes 2 E  */
                                  ,2'd1 /*nodes 1 E  */
                                  ,2'd1 /*nodes 0 E  */           
                      };
  
  //    0              1                  2                    3                 4        
  //   --->           --->           ---> Wi --->         ---> Wi --->           --> Wi
  //   <---  node 0   <---- node 1   <--- Ei <---- node 2 <--- Ei <----  node 3 <--- Ei 
  //

  // wire up the topology
  for (i=0; i < nodes_p; i++)
    begin: rof
  
      bsg_barrier #(.dirs_p(3)) one
	  (.clk_i(clk_li)
	   ,.reset_i(reset_li)
       ,.data_i({wi_nets[i+0],ei_nets[i+1], pi_nets[i]})
       ,.data_o({ei_nets[i+0],wi_nets[i+1], po_nets[i]})
       ,.src_r_i(ins_p[i])
       ,.dest_r_i(outs_p[i])
	  );

    end

  initial 
    begin
      clk_li = 0;
      while (1)
        begin
		  #5 clk_li = ~clk_li;  
        end
    end
  
  
  // we set it up so we enter the next barrier immediately after the first
  bsg_dff_reset #(.width_p(nodes_p)) dff
  (.clk_i(clk_li)
   ,.reset_i(reset_li)
   ,.data_i(~po_nets)
   ,.data_o(pi_nets)
  );
  
  always @(negedge clk_li)
    begin
      $display("%d Pi=%b, Wi=%b Ei=%b Po=%b",$time, pi_nets, wi_nets, ei_nets, po_nets);      
      // when pi==po, we know the barrier is completed
      // so we can xor the pi bit to enter the barrier
      for (integer i = 0; i < nodes_p; i++)
        if (pi_nets[i] == po_nets[i])
          $display("%t %d: barrier completed",$time,i);
  
    end
  
  initial 
    begin
      reset_li = 0;
      #10
      reset_li = 1;
      #10 
      reset_li = 0;
      #200
      #200
      $finish();
    end
  
endmodule
