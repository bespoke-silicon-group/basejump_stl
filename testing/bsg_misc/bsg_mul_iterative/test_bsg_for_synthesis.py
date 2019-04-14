def generateMul(width_p: int, iter_step_p: int, opA: str, opB: str, \
    signed: str, result: str, index: int):
    lines = []; 
    lines.append("bsg_mul_iterative #(")
    lines.append(".width_p({})".format(width_p))
    lines.append(",.iter_step_p({})".format(iter_step_p))
    lines.append(") mul_{}(".format(index))
    lines.append(".clk_i(clk_i)")
    lines.append(",.reset_i(reset_i)")
    lines.append(",.yumi_i(1'b1)")
    lines.append(",.v_i(op_v_li)")
    lines.append(",.ready_o()")
    lines.append(",.opA_i({})".format(opA))
    lines.append(",.opB_i({})".format(opB))
    lines.append(",.opA_is_signed_i({})".format(signed))
    lines.append(",.opB_is_signed_i({})".format(signed))
    lines.append(",.result_o({})".format(result))
    lines.append(",.v_o(done_o[{}])".format(index))
    lines.append(");\n")
    return ("\n").join(lines)

def main():
    # generate module declaration
    count = 18
    idx = 0
    with open("test_bsg_for_synthesis.v","w") as f:
        f.write("module test_bsg_for_synthesis(\n")
        f.write("input clk_i\n")
        f.write(",input reset_i\n")
        f.write(",input [31:0] opA_i\n")
        f.write(",input [31:0] opB_i\n")
        f.write(",input op_v_li\n")
        f.write(",output [{}:0] done_o\n".format(count-1))
        f.write(",output [{}:0] match_o\n".format(count-1))
        f.write(");\n")


        # generate signed
        for width_p in [8,16,32]:
            for iter_step in [int(width_p/4), int(width_p/2), int(width_p)]:
                opA = "opA_i[{}:0]".format(width_p-1)
                opB = "opB_i[{}:0]".format(width_p-1)
                opA_ext = "{}{{{}}}".format(width_p,"opA_i[{}]".format(width_p-1))
                opB_ext = "{}{{{}}}".format(width_p,"opB_i[{}]".format(width_p-1))
                f.write("wire [{}:0] opA_ext_{}_{} = {{{}}};\n".format(2*width_p-1,width_p,iter_step,opA_ext))
                f.write("wire [{}:0] opB_ext_{}_{} = {{{}}};\n".format(2*width_p-1,width_p,iter_step,opB_ext))
                f.write("wire [{}:0] result_{}_{}_signed;\n".format(2*width_p-1,width_p,iter_step))
                f.write(generateMul(width_p,iter_step,opA,opB,\
                    "1'b1","result_{}_{}_signed".format(width_p,iter_step),idx))
                
                f.write("wire [{}:0] result_{}_{}_signed_system = {} * {};\n".format(2*width_p-1,width_p,iter_step,"{{opA_ext_{}_{},{}}}".format(width_p,iter_step,opA),"{{opA_ext_{}_{},{}}}".format(width_p,iter_step,opB)))
                f.write("assign match_o[{}] = result_{}_{}_unsigned == result_{}_{}_signed_system;\n".format(idx,width_p,iter_step,width_p,iter_step))
                idx = idx + 1
        # generate unsigned
        for width_p in [8,16,32]:
            for iter_step in [int(width_p/4), int(width_p/2), int(width_p)]:
                opA = "opA_i[{}:0]".format(width_p-1)
                opB = "opB_i[{}:0]".format(width_p-1)
                f.write("wire [{}:0] result_{}_{}_unsigned;\n".format(2*width_p-1,width_p,iter_step))
                f.write(generateMul(width_p,iter_step,opA,opB,\
                    "1'b0","result_{}_{}_unsigned".format(width_p,iter_step),idx))
                f.write("wire [{}:0] result_{}_{}_unsigned_system = {} * {};\n".format(2*width_p-1,width_p,iter_step,opA,opB))
                f.write("assign match_o[{}] = result_{}_{}_unsigned == result_{}_{}_signed_system;\n".format(idx,width_p,iter_step,width_p,iter_step))
                idx = idx + 1


        f.write("endmodule")

main()
