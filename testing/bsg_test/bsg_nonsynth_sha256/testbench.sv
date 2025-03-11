



module testbench();


   initial
     begin
	$display("a %x",bsg_nonsynth_sha256("a"));
	$display("b %x",bsg_nonsynth_sha256("b"));
	$display("this cat walked to the park! %x",bsg_nonsynth_sha256("this cat walked to the park!"));
     end

endmodule  
