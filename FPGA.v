module FPGA #(parameter NUM_OF_TAPS = 6, SIZE = 24, NUM_OF_MODULES = 30) (
	input clk,
	input wire rx,
	output wire tx,
	output reg found_smth,
	output wire startedmod,
	output wire t1, t2, t3
);

wire [NUM_OF_MODULES*(NUM_OF_TAPS*8)-1:0] coefficient_buff;

wire [NUM_OF_MODULES-1:0] found;
wire [NUM_OF_MODULES-1:0] failure;
wire [NUM_OF_MODULES-1:0] res;
wire [NUM_OF_MODULES-1:0] ena;

assign startedmod = ena[0];

Interface #(
			.NUM_OF_TAPS		(NUM_OF_TAPS)		, 
			.NUM_OF_MODULES	(NUM_OF_MODULES)	)
			
	interfejs (	
		.clk		(clk)			,
		.rx 		(rx)			,
		.tx		(tx)			,
		.found	(found)		,
		.failure	(failure)	,
		.ena		(ena)			,
		.res		(res)			,
		.co_buf	(coefficient_buff),
		.test1  (t1),
		.test2 (t2),
		.test3 (t3)
);

genvar i;
generate
for (i=0; i<NUM_OF_MODULES; i=i+1) begin: Trololo
	
	NLFSR #(
				.NUM_OF_TAPS 	(NUM_OF_TAPS), 
				.SIZE 			(SIZE) )
		rejestr (
			.clk		(clk),
			.res		(res[i]),
			.ena		(ena[i]),
			.co_buf	(coefficient_buff[(i+1)*(NUM_OF_TAPS*8)-1-:NUM_OF_TAPS*8]),
			.failure	(failure[i]),
			.found	(found[i])
	);
	
end
endgenerate

initial begin
	found_smth <= 1'b0;
end

always @ (posedge clk) begin
	
	if (found != {NUM_OF_MODULES{1'b0}}) begin
		found_smth <= 1'b1;
	end

end

endmodule
