module uart_rx #(
	parameter		CLK_FRE		=	50,				// clock frequency(Mhz)
	parameter		BAUD_RATE	=	115200			// serial baud rate
) (
	input						clk				,	// clock input
	input						rst_n			,	// asynchronous reset input, low active 
	output	reg	[7:0]			rx_data			,	// received serial data
	output	reg					rx_rdy			,	// received serial data is valid
	input						rx_ack			,	// data receiver module ready
	input						uart_rx				// serial data input
);

	// calculates the clock cycle for baud rate 
	localparam		CYCLE		=	CLK_FRE * 1000000 / BAUD_RATE;
	// state machine code
	localparam		S_IDLE		=	1;
	localparam		S_START		=	2;				// start bit
	localparam		S_REC_BYTE	=	3;				// data bits
	localparam		S_STOP		=	4;				// stop bit
	localparam		S_DATA		=	5;

	reg rx_d0;										// delay 1 clock for uart_rx
	reg rx_d1;										// delay 1 clock for rx_d0
	reg[2:0] bit_cnt;								// bit counter
	reg[2:0] state, next_state;
	wire rx_negedge;								// negedge of uart_rx
	reg[7:0] rx_bits;								// temporary storage of received data
	reg[15:0] cycle_cnt;							// baud counter

	assign rx_negedge = rx_d1 && ~rx_d0;

	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			begin
			rx_d0 <= 1'b0;
			rx_d1 <= 1'b0;
			end
		else
			begin
			rx_d0 <= uart_rx;
			rx_d1 <= rx_d0;
			end
		end

	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			state <= S_IDLE;
		else
			state <= next_state;
		end

	always@ (*)
		begin
		case(state)
			S_IDLE:
				if (rx_negedge)
					next_state <= S_START;
				else
					next_state <= S_IDLE;
			S_START:
				if (cycle_cnt == CYCLE - 1)				// one data cycle 
					next_state <= S_REC_BYTE;
				else
					next_state <= S_START;
			S_REC_BYTE:
				if (cycle_cnt == CYCLE - 1  && bit_cnt == 3'd7)	// receive 8bit data
					next_state <= S_STOP;
				else
					next_state <= S_REC_BYTE;
			S_STOP:
				if (cycle_cnt == CYCLE/2 - 1)			// half bit cycle,to avoid missing the next byte receiver
					next_state <= S_DATA;
				else
					next_state <= S_STOP;
			S_DATA:
				if (rx_ack)						// data receive complete
					next_state <= S_IDLE;
				else
					next_state <= S_DATA;
			default:
				next_state <= S_IDLE;
		endcase
		end

	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			rx_rdy <= 1'b0;
		else if (state == S_STOP && next_state != state)
			rx_rdy <= 1'b1;
		else if (state == S_DATA && rx_ack)
			rx_rdy <= 1'b0;
		end

	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			rx_data <= 8'd0;
		else if (state == S_STOP && next_state != state)
			rx_data <= rx_bits;							// latch received data
		end

	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			begin
				bit_cnt <= 3'd0;
			end
		else if (state == S_REC_BYTE)
			if (cycle_cnt == CYCLE - 1)
				bit_cnt <= bit_cnt + 3'd1;
			else
				bit_cnt <= bit_cnt;
		else
			bit_cnt <= 3'd0;
		end


	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			cycle_cnt <= 16'd0;
		else if ((state == S_REC_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
			cycle_cnt <= 16'd0;
		else
			cycle_cnt <= cycle_cnt + 16'd1;	
		end

	//receive serial data bit data
	always@ (posedge clk or negedge rst_n)
		begin
		if (rst_n == 1'b0)
			rx_bits <= 8'd0;
		else if (state == S_REC_BYTE && cycle_cnt == CYCLE/2 - 1)
			rx_bits[bit_cnt] <= uart_rx;
		else
			rx_bits <= rx_bits; 
		end

endmodule
