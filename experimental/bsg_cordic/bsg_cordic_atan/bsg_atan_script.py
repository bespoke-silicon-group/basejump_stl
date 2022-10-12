import math, sys
# Inputs to the module has a bit-length defined by ansbitlen and output by ansbitlen. Both accomodate a fixed point representation
# which uses 'precision' number of bits for the decimal point. 'posprec' determines the number of pipeline stages starting from 0th stage. 
def lookup_compute(posprec, precision_result):
    lookup=[]
    for j in range(0,posprec+1):
        m=(math.atan2(1,2**j)*180)/math.pi
        lookup.append(format(round(m*(2**precision_result)),'x'))
    return lookup


def constant_compute(precision, ansbitlen):
    const=[]
    const.append('1')
    for i in range(0,precision):
        const.append('0')
    return ''.join(const)


def bsg_atan_init(angbitlen, ansbitlen, posprec):
    print('''
    module bsg_cordic_atan #(precis_p = %(p)d, ang_width_p = %(g)d, ans_width_p = %(s)d)
    (
    input clk_i
    ,input signed [ans_width_p-1:0] quant_i
    ,input ready_i
    ,input val_i
    ,output signed [ang_width_p-1:0] tan_inv_o
    ,output ready_o
    ,output val_o
    );
    logic signed [precis_p+1:0][ans_width_p-1:0] x ;
    logic signed [precis_p+1:0][ans_width_p-1:0] y ;
    logic signed [precis_p+1:0][ang_width_p-1:0] ang ;
    logic [precis_p+1:0] val ;
    logic [precis_p+1:0] sign_op ;
    logic signed [precis_p:0][ans_width_p-1:0] x_ans ;
    logic signed [precis_p:0][ans_width_p-1:0] y_ans ;
    logic signed [precis_p:0][ang_width_p-1:0] ang_ans ; 
    logic [precis_p:0] val_ans ; 
    logic [precis_p:0] sign_op_ans ;
    wire stall_pipe = val_o & (~ready_i);
    
    ''' %{'s':ansbitlen, 'g':angbitlen, 'p':posprec})
    return


def lookup_initialization(posprec, angbitlen, result):
    print("     localparam [precis_p:0][ang_width_p-1:0] ang_lookup_lp={" )
    for i in range(posprec,0,-1):
        print("     %(g)d'h%(r)s," %{'g':angbitlen,'r':result[i] })
    print("     %(g)d'h%(r)s };" %{'g':angbitlen,'r':result[0] })
    return


def bsg_constxy_initialization(constant, ansbitlen):
    print("""    localparam x_start_lp = %(s)d'b%(c)s;               
    """ %{'s':ansbitlen, 'c':constant})
    return


def main_body_print(ansbitlen, ninetyconstant):
    print(''' 
    
    logic in_sign_op = quant_i[ans_width_p-1];
    logic signed [ans_width_p-1:0] in_quant = in_sign_op ? ~quant_i + 1 : quant_i;
    always_ff @(posedge clk_i) begin
        if(~stall_pipe) begin
          x[0] <= x_start_lp;
          y[0] <= in_quant;
          ang[0] <= 0;
          sign_op[0] <= in_sign_op;
          val[0] <= val_i;
      end
    end 
    genvar i;
    generate
        for(i = 0; i <= precis_p ; i = i+1)
            begin : stage
                bsg_cordic_atan_stage #(.stage_p(i), .ang_width_p(ang_width_p), .ans_width_p(ans_width_p)) cs
                       (.x_i(x[i])
                        ,.y_i(y[i])
                        ,.ang_i(ang[i])
                        ,.ang_lookup_i(ang_lookup_lp[i])
                        ,.val_i(val[i])
                        ,.sign_op_i(sign_op[i])
                        ,.x_o(x_ans[i])
                        ,.y_o(y_ans[i])
                        ,.ang_o(ang_ans[i])
                        ,.val_o(val_ans[i])
                        ,.sign_op_o(sign_op_ans[i])
                        );
          
                    always_ff @(posedge clk_i)
                      begin
                        if(~stall_pipe) begin
                         x[i+1] <= x_ans[i];
                         y[i+1] <= y_ans[i];
                         ang[i+1] <= ang_ans[i];
                         val[i+1] <= val_ans[i];
                         sign_op[i+1] <= sign_op_ans[i];
                     end
                    end
                 end
          
            endgenerate
            assign tan_inv_o = sign_op[precis_p+1] ? ~ang[precis_p+1] + 1 : ang[precis_p+1];
            assign val_o = val[precis_p+1];
            assign ready_o = ~stall_pipe;
endmodule
'''% {'s':ansbitlen, 'nc':ninetyconstant})
    return


angbitlen = (int)(sys.argv[1])# Advised to use 1-sign bit+7-bits for reperenting a 
#max of 90 degrees+precision number of bits. 
#Output in fixed point format with precision number of bits for decimal representation.
ansbitlen = (int)(sys.argv[2])# Can be any desired length including precision number of bits.
#Output in fixed point format with precision number of bits for decimal representation.
posprec = (int)(sys.argv[3])
precision = (int)(sys.argv[4])
startquant_pow = (int)(sys.argv[5])# Input to the module will start from 2^startquant_pow.
# Fixed-point value will be 2^(startquant_pow-precision)

lookup = lookup_compute(posprec, precision)
bsg_atan_init(angbitlen, ansbitlen, posprec)
lookup_initialization(posprec, angbitlen, lookup)
constant = constant_compute(precision, ansbitlen)
bsg_constxy_initialization(constant, ansbitlen)
ninetyconstant = format(90*(2**precision),'x')
main_body_print(ansbitlen, ninetyconstant)


# This file object is used to create a header file facilitating the passing
# of parameters of the module to Verilator for testing purposes. 

f_params = open("params_def.h","w+")
f_params.write('#ifndef PARAMS_DEF\n')
f_params.write('#define PARAMS_DEF\n')
f_params.write('int anglen = %(g)d;\n'%{'g':angbitlen})
f_params.write('int anslen = %(s)d;\n'%{'s':ansbitlen})
f_params.write('int startquant_pow = %(s)d;\n'%{'s':startquant_pow})
f_params.write('int precis_p = %(p)d;\n'%{'p':posprec})
f_params.write('int precision = %(p)d;\n'%{'p':precision})
f_params.write('#endif')
f_params.close()
    
    
