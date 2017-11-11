`default_nettype none
module rc4_state_machine
(
input clk,
input start_loop_1,
input start_loop_2,
input [7:0] data_to_fsm,
input [24:0] secret_key_val,
output reg [7:0] sram_addr,
output reg [7:0] data_to_sram,
output reg enable_sram
);

// general declarations

// counter for s-RAM memory
reg [7:0] i_counter = 0;
reg [7:0] j_var;
reg [7:0] j_mem;
reg [7:0] i_mem;

logic secret_val_select;

// state
reg [7:0] state;

// state encoding
localparam IDLE 				= 8'b0000_0000;
localparam L1 					= 8'b0001_0001;
localparam L2_START			= 8'b0010_0000;
localparam L2_CALCJ			= 8'b0011_0000;
localparam L2_PREP_MEMJ		= 8'b0100_0000;
localparam L2_WRITE_MEMJ	= 8'b0101_0001;
localparam L2_PREP_MEMI		= 8'b0110_0000;
localparam L2_WRITE_MEMI	= 8'b0111_0001;
localparam L2_WAIT			= 8'b1000_0000;
localparam L2_WAIT2			= 8'b1001_0000;

// internal state bit use
assign enable_sram 					= state[0];

// instantiate memory
always_ff @(posedge clk)
begin
	case(state)
		IDLE:
		begin
			i_counter <= 0;
			sram_addr <= 0;
		end
		L1: 
		begin
			i_counter 		<= i_counter + 1'b1;
			sram_addr 		<= i_counter;
			data_to_sram 	<= i_counter;
		end
		L2_START: 
		begin
			i_counter 	<= 0;	// set i_counter to zero
			j_var		 	<= 0;	// set j variable to zero
			sram_addr	<= 0;	// set sram address to zero
		end
		L2_CALCJ: // now we're at address i
		begin
			j_var 		<= j_var + data_to_fsm + secret_key_val[23-((i_counter % 3)*8) -: 8];	// calculate j
			i_mem			<= data_to_fsm; // save the current value of s[i] into i_mem
			sram_addr	<= j_var + data_to_fsm + secret_key_val[23-((i_counter % 3)*8) -: 8];
		end
		L2_PREP_MEMJ: // now we're at address j
		begin
			data_to_sram 	<= i_mem; // write s[i] into s[j]
			j_mem				<= data_to_fsm; // save s[j] into j_mem
		end
		L2_WRITE_MEMJ: // write s[i] into s[j]
		begin
		sram_addr		<= i_counter; // go back to s[i]
		end
		L2_PREP_MEMI: // now we're at address i
		begin
		data_to_sram	<= j_mem; // write s[j] to s[i]
		i_counter <= i_counter + 1'b1;
		end
		L2_WRITE_MEMI:
		begin
		sram_addr		<= i_counter; // go to next address
		end
	endcase
end

// state transitions
always_ff @(posedge clk)
begin
	case(state)
		IDLE: 				if(start_loop_1) 			state <= L1;
		L1:					if(sram_addr == 8'hFF) 	state <= L2_START;
		L2_START:			if(start_loop_2)			state <= L2_WAIT;
		L2_WAIT:												state <= L2_CALCJ;
		L2_CALCJ:											state <= L2_WAIT2;
		L2_WAIT2:											state <= L2_PREP_MEMJ;
		L2_PREP_MEMJ:										state <= L2_WRITE_MEMJ;
		L2_WRITE_MEMJ:										state <= L2_PREP_MEMI;
		L2_PREP_MEMI:										state <= L2_WRITE_MEMI;
		L2_WRITE_MEMI:		if(sram_addr == 8'hFF)	state <= IDLE;
								else							state <= L2_WAIT;
	endcase
end


endmodule