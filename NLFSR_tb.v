module NLFSR_tb ();

reg clk,res,ena;
reg [6*8-1:0] co_buf;
wire failure, found;

NLFSR nlfsr(
	.clk (clk),
	.res (res),
	.ena (ena),
	.co_buf (co_buf),
	.failure (failure),
	.found (found)
);

initial begin
	clk = 1'b0;
	co_buf = {8'h01, 8'h08, 8'h09, 8'h0f, 8'h07, 8'h12};
	res = 1'b1;
	ena = 1'b0;
	repeat (4) #5 clk = ~clk;
	res = 1'b0;
	forever #5 clk = ~clk;
end

initial begin
	ena = 1'b0;
	@(negedge res);
	ena = 1'b1;
	repeat(100) @(posedge clk);
	ena = 1'b0;
	#5 res = 1'b1;
	#20 res = 1'b0;
	#5 ena = 1'b1;
	repeat(100) @(posedge clk);
	$finish;
end

endmodule