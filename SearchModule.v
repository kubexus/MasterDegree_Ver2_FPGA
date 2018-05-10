module SearchModule #(parameter NUM_OF_TAPS = 16, SIZE = 32, SEED = 13413515)(
	input 			clk		,
	input 			start		,
	input				ext_res	,
	
	output 	wire 	found		,
	output	reg	started	,
	output 	[NUM_OF_TAPS*8-1:0]		co_buf
);



reg 	ena;
reg   res;

wire [7:0] temp1; 
wire temp2, temp3;
wire failure;

wire [SIZE-1:0]	nlfsr_reg;

wire [NUM_OF_TAPS*8-1:0] taps_from_selector; 
assign co_buf = taps_from_selector;

initial begin
	ena <= 1'b0;
	started <= 1'b0;
	res <= 1'b0;
end

PRNG #(.SEED(SEED) ) generator (
	.clk 		(clk)			,
	.res 		(res)			,
	.dout 	(temp1)		,
	.done 	(temp2)
);

Selector #(.NUM_OF_TAPS (NUM_OF_TAPS), .SIZE(SIZE)) selector (
	.res 		(res)						,
	.clk 		(clk)						,
	.din 		(temp1)					,
	.ena		(ena)						,
	.take 	(temp2)					,
	.taps 	(taps_from_selector)	,
	.done 	(temp3)
);

XORs #(
	.NUM_OF_TAPS (NUM_OF_TAPS), .SIZE (SIZE) ) xory (
	.clk			(clk)						,
	.res			(res)						,
	.start		(temp3)					,
	.co_buf		(taps_from_selector)	,	
	.register	(nlfsr_reg)				,	
	.result		(feedback)
);

NLFSR #(.SIZE(SIZE) ) nlfsr (
	.clk				(clk)			,
	.res				(res)			,
	.ena				(ena)			,
	.feedback		(feedback)	,
	.selector_done	(temp3)		,
	.found			(found)		,
	.failure			(failure)	,
	.state			(nlfsr_reg)	
);

always @ (posedge clk) begin
	if (start) begin
		ena <= 1'b1;
		started <= 1'b1;
	end
	if (started) begin
		if (failure) begin
			res <= 1'b1;
		end
		if (res) begin
			res <= 1'b0;
		end
		if (ext_res) begin
			res <= 1'b1;
		end
	end
	
end

endmodule
