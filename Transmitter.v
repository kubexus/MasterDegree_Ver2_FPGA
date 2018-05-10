module Transmitter #(parameter BIT_RATE_VAL = 16'h01B0)(
	input wire clk,
	input wire res,
	input wire drl,
	output wire load,
	input wire [7:0] din,
	output wire tx
);

reg [3:0] FSM;
reg [3:0] bit_count;
reg [15:0] clk_count;
reg [9:0] transmit;
reg tx_reg;

initial begin
	FSM <= 4'h0;
	bit_count <= 4'h0;
	clk_count <= 16'h0000;
	transmit <= {10{1'b0}};
	tx_reg <= 1'b1;
end

assign tx = tx_reg;
assign load = (FSM == 4'h1)? 1'b1:1'b0;

always @(posedge clk) begin
	if (res)
		FSM <= 4'h0;
	else begin
		case (FSM)
			4'h0: if (drl) FSM <= 4'h1;
			4'h1: FSM <= 4'h2;
			4'h2: FSM <= 4'h3;
			4'h3: FSM <= 4'h4;
			4'h4: if (clk_count == 16'h0000) FSM <= 4'h5;
			4'h5: if (bit_count == 4'h0) FSM <= 4'h0; else FSM <= 4'h3;
			default: FSM <= 4'h0;
		endcase
	end
end

always @ (posedge clk) begin
	if (res) begin
		bit_count <= 4'h0;
	end
	else begin
		if (FSM == 4'h2)
			bit_count <= 4'ha;
		if (FSM == 4'h3)
			bit_count <= bit_count - 1;
	end
end

always @ (posedge clk) begin
	if (res)
		clk_count <= 16'h0000;
	else begin
		if (FSM == 4'h3)
			clk_count <= BIT_RATE_VAL;
		if (FSM == 4'h4)
			clk_count <= clk_count - 1;
	end
end

always @ (posedge clk) begin
	if (res)
		transmit <= {10{1'b0}};
	else begin
		if (FSM == 4'h2)
			transmit <= {1'b1,din,1'b0};
		if (FSM == 4'h3)
			transmit <= {1'b0,transmit[9:1]};
	end
end

always @ (posedge clk) begin
	if (res)
		tx_reg <= 1'b1;
	else begin 
		if (FSM == 4'h3) 
			tx_reg <= transmit[0];
	end
end

endmodule
















