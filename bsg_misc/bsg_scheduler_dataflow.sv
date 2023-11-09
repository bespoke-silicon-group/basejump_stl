// bsg_scheduler_dataflow
//
// this module implements a scheduler, where a number of items are waiting
// for inputs. currently, one item can be woken up, and one item can be
// inserted, per cycle.
//
// the scheduler critical loop is basically
// a set of input dependencies
//
// <srcA><srcB><dstA>
//
// followed by a trigger output dependence
// which then wakes up subsequent dependence rules
//


// helper module bsg_scheduler_dataflow_entry
// hardware that tracks a set of input dependence tags
// and signals whether all input tags have been satisfied
//
// outputs which dependences have recently been received

`include "bsg_defines.sv"

module bsg_scheduler_dataflow_entry #(`BSG_INV_PARAM(tag_width_p)
                                      , `BSG_INV_PARAM(src_tags_p)

                                     // these handle wakeup
                                      , `BSG_INV_PARAM(wakeup_tags_p)
                                     )
  (
  	input clk_i
    , input reset_i
    // write 
    , input we_i
    
    // v= 1 == wait for this tag
    // valid bit usually comes from some kind of scoreboard
    , input [src_tags_p-1:0] src_tags_v_i
    , input [src_tags_p-1:0][tag_width_p-1:0] src_tags_i
    
    // 1 == valid
    , input [wakeup_tags_p-1:0] wakeup_tags_v_i
    , input [wakeup_tags_p-1:0][tag_width_p-1:0] wakeup_tags_i
    
    // operation is waiting on something
    , output busy_o
    
    // strobe that indicates an input that was just woken up
    // useful for bypassing; can be input to 1-hot bypass mux

    , output [src_tags_p-1:0][wakeup_tags_p-1:0] bypass_o
  );
  
  logic [src_tags_p-1:0][tag_width_p-1:0] src_tags_r, src_tags_n;
  logic [src_tags_p-1:0] src_tags_v_r, src_tags_v_n;
  logic entry_v_r;

  wire [src_tags_p-1:0][wakeup_tags_p-1:0] bypass_n;
  
  always_ff @(posedge clk_i)
	begin
	   src_tags_v_r <= src_tags_v_n;
	   src_tags_r   <= src_tags_n;
    end

  genvar i,j;

  always @(negedge clk_i)
    $display("%m: entry we_i=%b src_tags_v_r=%b src_tags_r=%b wakeup_tags_i=%b busy_o=%b"
             , we_i, src_tags_v_r, src_tags_r, wakeup_tags_i, busy_o);

  
  for (i = 0; i < src_tags_p; i=i+1)
    begin: rof
      
      for (j = 0; j < wakeup_tags_p; j=j+1)
         begin: rof2
           assign bypass_n[i][j] = wakeup_tags_v_i[j] & (src_tags_r[i] == wakeup_tags_i[j]);
         end

      // we only assert the bypass line if there is an actual bypass

      assign bypass_o[i] = bypass_n[i] & { wakeup_tags_p { src_tags_v_r[i] }};
      
      always_comb
        begin
          if (we_i)
            src_tags_n[i] = src_tags_i[i];
          else
            src_tags_n[i] = src_tags_r[i];
        end

      wire not_matched = ~(|bypass_n[i]);
      
      always_comb
        begin
          if (reset_i)
            src_tags_v_n[i] = '0;
          else
            if (we_i)
              src_tags_v_n[i] = src_tags_v_i[i];
            else
              src_tags_v_n[i] = src_tags_v_r[i] & not_matched; 
        end
    end
  
  assign busy_o = (| src_tags_v_r);
  
endmodule


module bsg_scheduler_dataflow #(`BSG_INV_PARAM(els_p)
                               ,`BSG_INV_PARAM(src_tags_p)                     
                               ,`BSG_INV_PARAM(wakeup_tags_p)
                               // as wakeup_tag_p gets large relative to number of tags,
                               // a one hot representation starts to make more sense
                               , `BSG_INV_PARAM(tag_width_p)
                      )
  (
  	input clk_i
    , input reset_i
    
    // for adding something to the scheduler
    , input                                   insert_v_i
    
    // for each tag, a valid bit and the tag
    , input [src_tags_p-1:0]                  insert_src_tags_v_i
    , input [src_tags_p-1:0][tag_width_p-1:0] insert_src_tags_i
    
    // whether we were able to allocate the source
    , output                                  insert_src_yumi_o
    
    // this is a one hot vector of the id's, feeds easily into
    // array of metadata or one hot mux
    
    , output [els_p-1:0]                      insert_allocated_id_one_hot_o

    // for waking up things in the scheduler
    , input [wakeup_tags_p-1:0]                  wakeup_tags_v_i
    , input [wakeup_tags_p-1:0][tag_width_p-1:0] wakeup_tags_i
    
    // can be zero. can use this as input to one-hot-mux
    , output [els_p-1:0]                         selected_operation_one_hot_o

    // whether any operation was selected
    , output                                     selected_operation_v_o
    
    // for each source, which wakeup tag woke it up; if any
    , output [src_tags_p-1:0][wakeup_tags_p-1:0] selected_bypass_o
  );
  

  genvar i;
  
  wire [els_p-1:0] busies_lo, active_r_lo;
  wire [els_p-1:0][src_tags_p-1:0][wakeup_tags_p-1:0] selected_bypass_lo;
  
  for (i = 0; i < els_p; i++)
    begin  : entry
      bsg_scheduler_dataflow_entry #(.tag_width_p   (tag_width_p)
                                    ,.src_tags_p    (src_tags_p )
                                    ,.wakeup_tags_p (wakeup_tags_p )
                                    ) entry
      (.clk_i        (clk_i)
       ,.reset_i     (reset_i)
       
       // we write if there is space, and we have incoming data
       ,.we_i        (insert_allocated_id_one_hot_o[i] & v_i)

       ,.src_tags_v_i   (insert_src_tags_v_i   )
       ,.src_tags_i     (insert_src_tags_i     )
       ,.wakeup_tags_v_i(wakeup_tags_v_i)
       ,.wakeup_tags_i  (wakeup_tags_i  )
       ,.busy_o        (busies_lo[i])
       
       // bypass logic
       ,.bypass_o    (selected_bypass_lo [i])
      );
    end   
  
  // select among available entries for dispatch

  wire [els_p-1:0] ready_to_issue = ~busies_lo & active_r_lo;
  
  
    always @(negedge clk_i)
    begin
      $display("reset_i=%b insert_v_i=%b insert_src_tags_v_i=%b insert_src_tags_i=%b insert_src_yumi=%b insert_allocated_id_one_hot_o=%b wakeup_tags_v_i=%b wakeup_tags_i=%b selected_operation_one_hot_o=%b select_operation_v_o=%b busies_lo=%b, active_r_lo=%b ready_to_issue=%b bypass_lo=%b"
               , reset_i, insert_v_i, insert_src_tags_v_i, insert_src_tags_i, insert_src_yumi_o, insert_allocated_id_one_hot_o, wakeup_tags_v_i, wakeup_tags_i
               , selected_operation_one_hot_o, selected_operation_v_o, busies_lo, active_r_lo, ready_to_issue, bypass_lo);
    end
  
  bsg_priority_encode_one_hot_out #(
    .width_p(els_p)
    ,.lo_to_hi_p(1)
  ) pe0 (
    .i   (ready_to_issue)

  // this one hot signal can be used for a one hot mux to pull out the instruction
  // info, e.g. dest register or delay. it can also be used to free the entry 
  // from the scheduler
    
    ,.o  (selected_operation_one_hot_o)
    ,.v_o(selected_operation_v_o)
  );

  wire alloc_id_v_lo;
  
  // instruction bit vector
  bsg_id_pool_dealloc_alloc_one_hot #(.els_p(els_p)) idpool
  (.clk_i              (clk_i)
   ,.reset_i           (reset_i)
   ,.active_ids_r_o    (active_r_lo)
   ,.alloc_id_one_hot_o(insert_allocated_id_one_hot_o)
   ,.alloc_id_v_o      (alloc_id_v_lo)
   
   // an input for the leaf module; and an output for this module
   ,.alloc_yumi_i      (src_yumi_o)
   
   // deallocate spot for instruction that has been selected
   ,.dealloc_ids_i     (selected_operation_one_hot_o)

  );
  
  // successfully enqueud
  assign insert_src_yumi_o = alloc_id_v_lo & insert_v_i;
  
  // pull out bypass data for the selected item
  bsg_mux_one_hot # (.width_p(src_tags_p*wakeup_tags_p)
                     ,.els_p(els_p)) bmoh
  (.data_i        (selected_bypass_lo)
   ,.sel_one_hot_i(selected_operation_one_hot_o)
   ,.data_o       (selected_bypass_o)
  );
  
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_scheduler_dataflow)
