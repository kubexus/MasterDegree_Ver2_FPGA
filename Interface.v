module Interface #(parameter NUM_OF_TAPS = 5, NUM_OF_MODULES = 20)(
	input 	clk,
	input 	rx,
	output 	tx,
	
	input [NUM_OF_MODULES-1:0] found,
	input [NUM_OF_MODULES-1:0] failure,
	
	output reg [NUM_OF_MODULES-1:0] ena,
	output reg [NUM_OF_MODULES-1:0] res,

	output reg [NUM_OF_MODULES*(NUM_OF_TAPS*8)-1:0] co_buf,
	
	output reg test1, test2, test3
	
);

wire [7:0] 	byte_in;
reg [7:0] 	byte_out;

reg 								transmit_byte;
reg [(NUM_OF_TAPS*8)-1:0] 	buff;
reg [7:0] 						which;

reg [7:0] state;
parameter	IDLE 				= 8'b00000001,
				RECEIVE 			= 8'b00000010,
				ASSIGN_TO_REG	= 8'b00000100,
				CONFIRM			= 8'b00001000,
				TRANSMIT_POLY	= 8'b00010000,
				FOUND				= 8'b00100000,
				FAILURE			= 8'b01000000,
				RESET				= 8'b10000000;
				
				
parameter 	START = 	8'hf0,
				END	=	8'hff,
				ACCK	=	8'hf1,
				ERR	=	8'hee,
				FAIL	=	8'hf2;

wire jeden; 
assign jeden = 1'b0;

wire tx_ready;
wire take_byte;

reg [5:0] receive_count;
reg [5:0] assign_count;
reg [5:0] i;

initial begin
	byte_out <= 8'h00;
	transmit_byte <= 1'b0;
	buff <= {NUM_OF_TAPS{8'h00}};
	which <= 8'h00;
	state <= IDLE;
	receive_count <= 1;
	assign_count <= 0;
	i <= 0;
	ena <= {NUM_OF_MODULES{1'b0}};
	res <= {NUM_OF_MODULES{1'b0}};
	test1 <= 1'b0;
	test2 <= 1'b0;
	test3 <= 1'b0;
end

Transmitter transmitter (
	.clk		(clk)			,
	.res		(jeden)		,
	.drl		(transmit)	,
	.load		(tx_ready)	,
	.din		(byte_out)	,
	.tx		(tx)
);

Receiver receiver (
	.clk		(clk)			,
	.res		(jeden)		,
	.rx		(rx)			,
	.take		(take_byte)	,
	.dout		(byte_in)
);

task conf;
input [7:0] byte;
begin
	byte_out <= byte;
	transmit_byte <= 1'b1;
	state <= CONFIRM;
end
endtask


always @ (posedge clk) begin
	case (state)
		IDLE: begin
			if (take_byte) begin
				if (byte_in == START && ena != {NUM_OF_MODULES{1'b1}}) begin
					test1 <= ~test1;
					state <= RECEIVE;
				end else conf(ERR);
			end else begin 
				if (found != {NUM_OF_MODULES{1'b0}}) begin
					test2 <= ~test2;
					state <= FOUND;
				end
				if (failure != {NUM_OF_MODULES{1'b0}}) begin
					state <= FAILURE;
				end
			end
		end
		
		RECEIVE: begin
			if (take_byte) begin
				if (byte_in == END) begin
					state <= ASSIGN_TO_REG;
				end else begin
					buff[receive_count*8-1-:8] <= byte_in;
					receive_count <= receive_count + 1;
				end
			end
		end
		
		ASSIGN_TO_REG: begin
			if (ena[assign_count] == 1'b0) begin
				co_buf[(assign_count+1)*(NUM_OF_TAPS*8)-1-:NUM_OF_TAPS*8] <= buff;
				ena[assign_count] <= 1'b1;
				transmit_byte <= 1'b1;
				conf(ACCK);
			end else begin
				assign_count <= assign_count + 1;
			end
			if (assign_count > NUM_OF_MODULES)
				conf(ERR);
		end
		
		FOUND: begin
			if (found[i] == 1'b1) begin
				which <= i + 1;
				transmit_byte <= 1'b1;
				state <= TRANSMIT_POLY;
				i <= 0;
			end else i <= i + 1;
			if (i > NUM_OF_MODULES)
				conf(ERR);
		end
		
		FAILURE: begin
			if (failure[i] == 1'b1) begin
				ena[i] <= 1'b0;
				res[i] <= 1'b1;
				co_buf[(i+1)*(NUM_OF_TAPS*8)-1-:NUM_OF_TAPS*8] <= {NUM_OF_TAPS{8'h00}};
				byte_out <= FAIL;
				transmit_byte <= 1'b1;
				state <= CONFIRM;
			end else i <= i + 1;
			if (i > NUM_OF_MODULES)
				conf(ERR);
		end
		
		TRANSMIT_POLY: begin
			if (tx_ready) begin
				if (i == 0) begin
					byte_out <= START;
					ena[which-1] <= 1'b0;
					buff <= co_buf[which*(NUM_OF_TAPS*8)-1-:NUM_OF_TAPS*8];
				end
				if (i>0 && i<=NUM_OF_TAPS) begin
					byte_out <= buff[i*8-1-:8];
				end
				if (i == NUM_OF_TAPS + 1) begin
					byte_out <= END;
				end
				if (i == NUM_OF_TAPS + 2) begin
					transmit_byte		<= 1'b0;
					res[which-1] 		<= 1'b1;
					co_buf[(which)*(NUM_OF_TAPS*8)-1-:NUM_OF_TAPS*8] <= {NUM_OF_TAPS{8'h00}};
					state	<= RESET;
				end
				i <= i + 1;
			end
		end
		
		CONFIRM: begin
			if (tx_ready) begin
				state <= RESET;
			end
		end
		
		RESET: begin
			byte_out <= 8'h00;
			transmit_byte <= 1'b0;
			buff <= {NUM_OF_TAPS{8'h00}};
			which <= 8'h00;
			state <= IDLE;
			receive_count <= 1;
			assign_count <= 0;
			i <= 0;
			res <= {NUM_OF_MODULES{1'b0}};
		end
	
//		IDLE: begin
//			if (take_byte)
//				if (byte_in == START && ena != {NUM_OF_MODULES{1'b1}}) begin
//					state <= RECEIVE;
//					i <= 1;
//					test <= 1'b1;
//				end else	conf(ERR);
//			if (found != {NUM_OF_MODULES{1'b0}}) begin
//				i <= 0;
//				state <= FOUND;
//			end
//			if (failure != {NUM_OF_MODULES{1'b0}}) begin
//				i <= 0;
//				state <= FAILURE;
//			end
//		end
		

		

		
//		CONFIRM: begin
////			if (tx_ready) begin
////				byte_out <= ACCK;
////				test3 <= 1'b1;
////				state <= RESET;
////			end
//				if (tx_ready) begin
//					if (i == 0) begin
//						byte_out <= 8'hff;
//					end
//					if (i>0 && i<NUM_OF_TAPS+1) begin
//						byte_out <= 8'hee;
//					end
//					if (i == NUM_OF_TAPS + 1) begin
//						byte_out <= 8'hfe;
//						test3 <= 1'b1;
//					end
//					i 	<= i + 1;
//				end
//				if (i == NUM_OF_TAPS + 2) begin
//					transmit_byte		<= 1'b0;
//					//res[which] 			<= 1'b1;
//					i <= i + 1;
//				end
//				if (i == NUM_OF_TAPS + 3) begin
//					state					<= RESET;
//				end
//		end
	endcase
end
assign transmit = (transmit_byte) ? 1'b1:1'b0;

endmodule
