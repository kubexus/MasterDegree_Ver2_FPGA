module NLFSR_tb ();

reg clk,res,ena;
reg [6*8-1:0] co_buf;
wire failure, found;

NLFSR #(.SIZE(11), .NUM_OF_TAPS(6)) nlfsr(
	.clk (clk),
	.res (res),
	.ena (ena),
	.co_buf (co_buf),
	.failure (failure),
	.found (found)
);

initial begin
	clk = 1'b0;
	co_buf = {8'h4, 8'h5, 8'h1, 8'h2, 8'h4, 8'h6};
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
	repeat(1000000) @(posedge clk);
	$finish;
end

endmodule