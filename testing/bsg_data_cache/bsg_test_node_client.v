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

  wire unused = en_i;
  logic sigext_op;
  logic [1:0] size_op;
  logic [3:0] instr_op;
  logic [31:0] dc_data_i;
  logic [31:0] dc_addr_i;

  logic [31:0] dc_data_o;

  logic [31:0] cmni_data;
  logic cmni_valid;
  logic cmni_thanks;

  logic cmno_send_req;
  logic cmno_send_committed;
  logic [31:0] cmno_data;

  assign sigext_op = data_i[70];
  assign size_op = data_i[69:68];
  assign instr_op = data_i[67:64];
  assign dc_addr_i = data_i[63:32];
  assign dc_data_i = data_i[31:0];
  assign data_o = {48'b0, dc_data_o};

  bsg_data_cache dcache0 (
    .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.sigext_op_i(sigext_op)
    ,.size_op_i(size_op)
    ,.instr_op_i(instr_op)
    ,.addr_i(dc_addr_i)
    ,.data_i(dc_data_i)
    ,.v_i(v_i)
    ,.ready_o(ready_o)

    ,.v_o(v_o)
    ,.yumi_i(yumi_i)
    ,.data_o(dc_data_o)

    ,.cmni_data_i(cmni_data)
    ,.cmni_valid_i(cmni_valid)
    ,.cmni_thanks_o(cmni_thanks)

    ,.cmno_send_req_o(cmno_send_req)
    ,.cmno_send_committed_i(cmno_send_committed)
    ,.cmno_data_o(cmno_data)
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
