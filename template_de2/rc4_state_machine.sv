`default_nettype none
module rc4_state_machine
(
input clk,
input start_loop_1,
input start_loop_2,
input start_loop_2b,
input [7:0] data_to_fsm,
input [24:0] secret_key_val,
output reg [7:0] sram_addr,
output reg [7:0] data_to_sram,
output reg enable_sram
);

// general declarations
logic [7:0] dram_addr;
logic [7:0] data_to_dram;  // not sure if these should be logics
logic [7:0] data_from_dram;
logic enable_dram;

logic [7:0] mrom_addr;
logic [7:0] data_from_mrom;

// instantiate d-RAM and m-ROM
d_memory 		d_mem(.address(dram_addr), .clock(clk), .data(data_to_dram), .wren(enable_dram), .q(data_from_dram));
message_rom 	m_rom(.address(mrom_addr), .clock(clk), .q(data_from_mrom));

// counter for s-RAM memory
reg [7:0] i_counter = 0;
reg [7:0] j_var;
reg [7:0] j_mem;
reg [7:0] i_mem;
reg [7:0] j_counter;
reg [7:0] k_counter;
reg [7:0] s_i;
reg [7:0] s_j;
reg [7:0] s_ij;
reg [7:0] f_var;

logic secret_val_select;

// state
reg [8:0] state;

// state encoding
localparam IDLE 				= 9'b00000_0000;
localparam L1 					= 9'b00001_0001;
localparam L2_START			= 9'b00010_0000;
localparam L2_CALCJ			= 9'b00011_0000;
localparam L2_PREP_MEMJ		= 9'b00100_0000;
localparam L2_WRITE_MEMJ	= 9'b00101_0001;
localparam L2_PREP_MEMI		= 9'b00110_0000;
localparam L2_WRITE_MEMI	= 9'b00111_0001;
localparam L2_WAIT			= 9'b01000_0000;
localparam L2_WAIT2			= 9'b01001_0000;
localparam L2B_START			= 9'b01010_0000;
localparam L2B_INC_I			= 9'b01011_0000;
localparam L2B_WAIT			= 9'b01100_0000;
localparam L2B_INC_J			= 9'b01101_0000;
localparam L2B_WAIT_2		= 9'b01110_0000;
localparam L2B_SWAP_J		= 9'b01111_0001;
localparam L2B_WAIT_3		= 9'b10000_0001;
localparam L2B_SWAP_I_ADDR	= 9'b10001_0000;
localparam L2B_WAIT_4		= 9'b10010_0000;
localparam L2B_SWAP_I		= 9'b10011_0001;
localparam L2B_WAIT_5		= 9'b10100_0001;
localparam L2B_F_ADDR		= 9'b10101_0000;
localparam L2B_WAIT_6		= 9'b10110_0000;
localparam L2B_NEW_F			= 9'b10111_0000;
localparam L2B_XOR_F			= 9'b11000_0010;
localparam L2B_WAIT_7		= 9'b11001_0010;


// internal state bit use
assign enable_sram 					= state[0];
assign enable_dram 					= state[1];

// instantiate memory
always_ff @(posedge clk)
begin
	case(state)
		IDLE:
		begin
			i_counter 		<= 0;
			sram_addr 		<= 0;
		end
		L1: 
		begin
			i_counter 		<= i_counter + 1'b1;
			sram_addr 		<= i_counter;
			data_to_sram 	<= i_counter;
		end
		L2_START: 
		begin
			i_counter 		<= 0;	// set i_counter to zero
			j_var		 		<= 0;	// set j variable to zero
			sram_addr		<= 0;	// set sram address to zero
		end
		L2_CALCJ: // now we're at address i
		begin
			j_var 			<= j_var + data_to_fsm + secret_key_val[23-((i_counter % 3)*8) -: 8];	// calculate j
			i_mem				<= data_to_fsm; // save the current value of s[i] into i_mem
			sram_addr		<= j_var + data_to_fsm + secret_key_val[23-((i_counter % 3)*8) -: 8];
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
			i_counter 		<= i_counter + 1'b1;
		end
		L2_WRITE_MEMI:
		begin
			sram_addr		<= i_counter; // go to next address
		end
		L2B_START: 
		begin
			i_counter 		<= 0;	
			j_counter 		<= 0;
			k_counter 		<= 0;
		end
		L2B_INC_I: 
		begin
			i_counter 		<= i_counter + 8'h01;
			sram_addr		<= i_counter + 8'h01;	
			dram_addr		<= k_counter;
			mrom_addr		<= k_counter;
		end
		L2B_INC_J: 
		begin
			s_i 				<= data_to_fsm;
			j_counter 		<= j_counter + data_to_fsm;
			sram_addr 		<= j_counter + data_to_fsm;
		end
		L2B_SWAP_J: 
		begin
			s_j 				<= data_to_fsm;
			data_to_sram 	<= s_i;  // s[j] <= s[i]
		end
		L2B_SWAP_I_ADDR: 
		begin
			sram_addr		<= i_counter;	
		end
		L2B_SWAP_I:
		begin
			data_to_sram 	<= s_j;  // s[i] <= s[j]
			s_ij 				<= s_i + s_j;			
		end
		L2B_F_ADDR: 
		begin
			sram_addr		<= s_ij;
		end
		L2B_NEW_F: 
		begin
			f_var 			<= data_to_fsm;
		end
		L2B_XOR_F: 
		begin
			data_to_dram 	<= f_var ^ data_from_mrom;
			k_counter 		<= k_counter + 8'h01;
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
		L2_WRITE_MEMI:		if(sram_addr == 8'hFF)	state <= L2B_START;
								else							state <= L2_WAIT;
		L2B_START:			if(start_loop_2b)			state <= L2B_INC_I;
		L2B_INC_I:											state <= L2B_WAIT;
		L2B_WAIT:											state <= L2B_INC_J;
		L2B_INC_J:											state <= L2B_WAIT_2;
		L2B_WAIT_2:											state <= L2B_SWAP_J;
		L2B_SWAP_J:											state <= L2B_WAIT_3;
		L2B_WAIT_3:											state <= L2B_SWAP_I_ADDR;
		L2B_SWAP_I_ADDR:									state <= L2B_WAIT_4;
		L2B_WAIT_4:											state <= L2B_SWAP_I;
		L2B_SWAP_I:											state <= L2B_WAIT_5;
		L2B_WAIT_5:											state <= L2B_F_ADDR;
		L2B_F_ADDR:											state <= L2B_WAIT_6;
		L2B_WAIT_6:											state <= L2B_NEW_F;
		L2B_NEW_F:											state <= L2B_XOR_F;
		L2B_XOR_F:											state <= L2B_WAIT_7;
		L2B_WAIT_7:			if(k_counter == 8'h20)	state <= IDLE;
								else							state <= L2B_INC_I;
	endcase
end


endmodule