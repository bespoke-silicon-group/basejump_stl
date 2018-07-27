module bsg_test_node_client #(parameter incr_p="inv")
(
  input clk_i
  ,input rst_i
  ,input en_i

  ,input v_i
  ,input [79:0] data_i
  ,output logic ready_o

  ,output logic v_o
  ,output logic [79:0] data_o
  ,input yumi_i
);

if (incr_p == 1) begin : incr
  bsg_incrementer incr0 (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.en_i(en_i)
    
    ,.v_i(v_i)
    ,.data_i(data_i)
    ,.ready_o(ready_o)
    
    ,.v_o(v_o)
    ,.data_o(data_o)
    ,.yumi_i(yumi_i)
  );
end
else begin : dcache
  logic sign_extend;
  logic word_op, half_op, byte_op;
  logic ld_op, st_op;
  logic invalidate_op, flush_op, valid_op, lnaddr_op;
  logic afl_op, aflinv_op, ainv_op;
  logic [31:0] dc_data_i;
  logic [31:0] dc_addr_i;
  logic [31:0] dc_data_o;
  logic [31:0] cmni_data;
  logic cmni_valid;
  logic cmni_thanks;
  logic cmno_send_req;
  logic cmno_send_committed;
  logic [31:0] cmno_data;

  assign {sign_extend, word_op, half_op, byte_op} = data_i[71:68];
  assign {ainv_op, aflinv_op, afl_op, lnaddr_op, valid_op,
    flush_op, invalidate_op, st_op, ld_op} = (9'b1 << data_i[67:64]);
  assign dc_addr_i = data_i[63:32];
  assign dc_data_i = data_i[31:0];
  assign data_o = {48'b0, dc_data_o};

  bsg_data_cache dcache0 (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.sign_extend_i(sign_extend)
    ,.word_op_i(word_op)
    ,.half_op_i(half_op)
    ,.byte_op_i(byte_op)
    ,.ld_op_i(ld_op)
    ,.st_op_i(st_op)
    ,.invalidate_op_i(invalidate_op)
    ,.flush_op_i(flush_op)
    ,.valid_op_i(valid_op)
    ,.lnaddr_op_i(lnaddr_op)
    ,.afl_op_i(afl_op)
    ,.aflinv_op_i(aflinv_op)
    ,.ainv_op_i(ainv_op)
    ,.addr_i(dc_addr_i)
    ,.data_i(dc_data_i)
    ,.data_o(dc_data_o)
    ,.cmni_data_i(cmni_data)
    ,.cmni_valid_i(cmni_valid)
    ,.cmni_thanks_o(cmni_thanks)
    ,.cmno_send_req_o(cmno_send_req)
    ,.cmno_send_committed_i(cmno_send_committed)
    ,.cmno_data_o(cmno_data)
    ,.v_i(v_i)
    ,.ready_o(ready_o)
    ,.v_o(v_o)
    ,.yumi_i(yumi_i)
  );

  mock_memory mm (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cmni_data_o(cmni_data)
    ,.cmni_valid_o(cmni_valid)
    ,.cmni_thanks_i(cmni_thanks)
    ,.cmno_send_req_i(cmno_send_req)
    ,.cmno_committed_o(cmno_send_committed)
    ,.cmno_data_i(cmno_data)
  );

end

endmodule
