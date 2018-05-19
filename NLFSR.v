module NLFSR #(parameter SIZE = 24, NUM_OF_TAPS = 6)(

	input 								clk,
	input 								res,
	input 								ena,
	input [(NUM_OF_TAPS*8)-1:0]	co_buf,
	
	output reg	failure,
	output reg	found
);

parameter [35:0] period = (2**SIZE) - 1;
parameter INIT_VAL = {{SIZE-1{1'b0}},1'b1};

reg [35:0] i;
reg [SIZE-1:0] state;
reg [NUM_OF_TAPS:1] TAPS;

initial begin
	i <= 0;
	state <= INIT_VAL;
	failure <= 1'b0;
	found 	<= 1'b0;
	TAPS <= {NUM_OF_TAPS{1'b0}};
end

wire feedback;
assign feedback = state[0] ^ (TAPS[1] & TAPS[2]) ^ TAPS[3] ^ TAPS[4] ^ TAPS[5] ^ TAPS[6];// & TAPS[7] & TAPS[8]) ^ (TAPS[9] & TAPS[10] & TAPS[11]) ^ TAPS[12] ^ TAPS[13] ^ TAPS[14] ^ TAPS[15] ^ TAPS[16] ^ TAPS[17] ^ TAPS[18] ^ TAPS[19];


always @ (posedge clk) begin
	if (res) begin
		state 	<= INIT_VAL;
		found 	<= 1'b0;
		failure 	<= 1'b0;
		i 			<= {36{1'b0}};
	end
	if (ena) begin
		if (!found && !failure) begin
			state <= {feedback, state[SIZE-1:1]};
			i <= i + 1;
		end
		if (state == INIT_VAL) begin
			if (i == period)
				found <= 1'b1; 
			if (i > 5 && i < period)
				failure <= 1'b1;
		end
		if (i > period + 3)
			failure <= 1'b1;
	end
end
					
genvar j;
generate
for (j = 1; j <= NUM_OF_TAPS; j = j + 1) 
	begin: TAPSY
	always @ (*) begin
		if (res) begin
			TAPS[j] <= 1'b0;
		end 
		if (ena) begin
			case (co_buf[j*8-1-:8])
				8'h01 :	TAPS[j] <= state[1];
				8'h02 :	TAPS[j] <= state[2];
				8'h03 :	TAPS[j] <= state[3];
				8'h04 :	TAPS[j] <= state[4];
				8'h05 :	TAPS[j] <= state[5];
				8'h06 :	TAPS[j] <= state[6];
				8'h07 :	TAPS[j] <= state[7];
				8'h08 :	TAPS[j] <= state[8];
				8'h09 :	TAPS[j] <= state[9];
				8'h0a :	TAPS[j] <= state[10];
				8'h0b :	TAPS[j] <= state[11];
				8'h0c :	TAPS[j] <= state[12];
				8'h0d :	TAPS[j] <= state[13];
				8'h0e :	TAPS[j] <= state[14];
				8'h0f :	TAPS[j] <= state[15];
				8'h10 :	TAPS[j] <= state[16];
				8'h11 :	TAPS[j] <= state[17];
				8'h12 :	TAPS[j] <= state[18];
				8'h13 :	TAPS[j] <= state[19];
				8'h14 :	TAPS[j] <= state[20];
				8'h15 :	TAPS[j] <= state[21];
				8'h16 :	TAPS[j] <= state[22];
				8'h17 :	TAPS[j] <= state[23];
//				8'h18 :	TAPS[j] <= state[24];
//				8'h19 :	TAPS[j] <= state[25];
//				8'h1a :	TAPS[j] <= state[26];
//				8'h1b :	TAPS[j] <= state[27];
//				8'h1c :	TAPS[j] <= state[28];
//				8'h1d :	TAPS[j] <= state[29];
//				8'h1e :	TAPS[j] <= state[30];
//				8'h1f :	TAPS[j] <= state[31];
				default : TAPS[j] <= 1'b0;
			endcase
		end
	end
end
endgenerate


///////////
endmodule

