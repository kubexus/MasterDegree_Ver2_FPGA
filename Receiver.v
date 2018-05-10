module Receiver #(parameter [15:0] BIT_RATE_VAL = 16'h01B0) (
	input wire clk,
	input wire res,
	input wire rx,
	output wire take,
	output wire [7:0] dout
);

reg [3:0] FSM;
reg [3:0] bit_count;
reg [15:0] clk_count;
reg [9:0] received;

initial begin
	FSM <= 4'h0;
	bit_count <= 4'h0;
	clk_count <= 16'h0000;
	received <= {10{1'b0}};
end

assign dout = received;
assign take = (FSM == 4'h5)? 1'b1:1'b0;

always @(posedge clk) begin
	if (res)
		FSM <= 4'h0;
	else begin
		case (FSM)
			4'h0: if (!rx) FSM <= 4'h1;
			4'h1: FSM <= 4'h2;
			4'h2: if (clk_count == 16'h0000) FSM <= 4'h3;
			4'h3: FSM <= 4'h4;
			4'h4: if (bit_count == 4'h0) FSM <= 4'h5; else FSM <= 4'h2;
			4'h5: FSM <= 4'h0;
			default: FSM <= 4'h0;
		endcase
	end
end

always @ (posedge clk) begin
	if (res)
		bit_count <= 4'h0;
	else begin
		if (FSM == 4'h1)
			bit_count <= 4'ha;
		if (FSM == 4'h3)
			bit_count <= bit_count - 1;
	end
end

always @ (posedge clk) begin
	if (res)
		clk_count <= 16'h0000;
	else begin
		if (FSM == 4'h1)
			clk_count <= {1'b0,BIT_RATE_VAL[15:1]};
		if (FSM == 4'h3)
			clk_count <= BIT_RATE_VAL;
		if (FSM == 4'h2)
			clk_count <= clk_count - 1;
	end
end

always @ (posedge clk) begin
	if (res)
		received <= {10{1'b0}};
	else begin
		if (FSM == 4'h0)
			received <= {10{1'b0}};
		if (FSM == 4'h3)
			received <= {rx,received[9:1]};
	end
end

endmodule
