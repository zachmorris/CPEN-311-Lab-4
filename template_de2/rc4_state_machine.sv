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
output reg enable_sram,
output [23:0] checking_key,
output success_light,
output fail_light
);

// general declarations
logic [7:0] dram_addr;
logic [7:0] data_to_dram;  // not sure if these should be logics
logic [7:0] data_from_dram;
logic enable_dram;

logic [7:0] mrom_addr;
logic [7:0] data_from_mrom;

// instantiate d-RAM and m-ROM
d_memory 		d_mem(.address(dram_addr), .clock(clk), .data(data_to_dram), 
							.wren(enable_dram), .q(data_from_dram));
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
reg [7:0] dram_data;
reg [5:0] L_counter;
reg [21:0] M_counter;

assign checking_key = {2'b0, M_counter};

logic secret_val_select;

// state
reg [8:0] state;

// state encoding
localparam IDLE 				= 10'b000000_0000;
localparam L1 					= 10'b000001_0001;
localparam L2_START			= 10'b000010_0000;
localparam L2_CALCJ			= 10'b000011_0000;
localparam L2_PREP_MEMJ		= 10'b000100_0000;
localparam L2_WRITE_MEMJ	= 10'b000101_0001;
localparam L2_PREP_MEMI		= 10'b000110_0000;
localparam L2_WRITE_MEMI	= 10'b000111_0001;
localparam L2_WAIT			= 10'b001000_0000;
localparam L2_WAIT2			= 10'b001001_0000;
localparam L2B_START			= 10'b001010_0000;
localparam L2B_INC_I			= 10'b001011_0000;
localparam L2B_WAIT			= 10'b001100_0000;
localparam L2B_INC_J			= 10'b001101_0000;
localparam L2B_WAIT_2		= 10'b001110_0000;
localparam L2B_SWAP_J		= 10'b001111_0001;
localparam L2B_WAIT_3		= 10'b010000_0001;
localparam L2B_SWAP_I_ADDR	= 10'b010001_0000;
localparam L2B_WAIT_4		= 10'b010010_0000;
localparam L2B_SWAP_I		= 10'b010011_0001;
localparam L2B_WAIT_5		= 10'b010100_0001;
localparam L2B_F_ADDR		= 10'b010101_0000;
localparam L2B_WAIT_6		= 10'b010110_0000;
localparam L2B_NEW_F			= 10'b010111_0000;
localparam L2B_XOR_F			= 10'b011000_0010;
localparam L2B_WAIT_7		= 10'b011001_0010;

localparam L3_LOAD_KEY		= 10'b011010_0000;
localparam L3_DECRYPT		= 10'b011011_0000;
localparam L3_SET_RAM_ADDR	= 10'b011100_0000;
localparam L3_READ_RAM		= 10'b011101_0000;
localparam L3_WAIT_READ		= 10'b011110_0000;
localparam L3_INC_L			= 10'b011111_0000;
localparam L3_SUCCESS		= 10'b100000_1000;
localparam L3_FAIL			= 10'b100001_0100;
localparam L3_INC_M			= 10'b100010_1100;
localparam L3_ERROR			= 10'b100011_1100;
localparam L3_WAIT_1			= 10'b100100_0000;
localparam L3_WAIT_2			= 10'b100101_0000;
localparam L3_WAIT_3			= 10'b100110_0000;
localparam L3_WAIT_4			= 10'b100111_0000;

// character constants
localparam MAX_CHAR			= 7'h7A;
localparam MIN_CHAR			= 7'h61;
localparam SPACE_CHAR		= 7'h20;
localparam MAX_KEYVAL		= 22'h3FFFFF;
localparam WORD_SIZE			= 8'h20;

// internal state bit use
assign enable_sram 					= state[0];
assign enable_dram 					= state[1];
assign fail_light						= state[2];
assign success_light					= state[3];

// instantiate memory
always_ff @(posedge clk)
begin
	case(state)
		IDLE:
		begin
			i_counter 		<= 0;
			sram_addr 		<= 0;
			M_counter 		<= 22'b01;
			L_counter		<= 0;
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
			j_var 			<= j_var + data_to_fsm + checking_key[23-((i_counter % 3)*8) -: 8];	// calculate j
			i_mem				<= data_to_fsm; // save the current value of s[i] into i_mem
			sram_addr		<= j_var + data_to_fsm + checking_key[23-((i_counter % 3)*8) -: 8];
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
		L3_LOAD_KEY:
		begin
			i_counter 		<= 0;
			sram_addr 		<= 0;
		end
		L3_SET_RAM_ADDR:
		begin
			dram_addr		<= L_counter;
		end
		L3_READ_RAM:
		begin
			dram_data 		<= data_from_dram;
		end
		L3_INC_L:
		begin
			L_counter		<= L_counter + 1'b1;
		end
		L3_INC_M:
		begin
			M_counter		<= M_counter + 1'b1;
			L_counter		<= 0;
		end

	endcase
end

// state transitions
always_ff @(posedge clk)
begin
	case(state)
		IDLE: 				if(start_loop_1) 			state <= L3_LOAD_KEY;
		L3_LOAD_KEY:										state <= L1;		
		L1:					if(sram_addr == 8'hFF) 	state <= L2_START;
		L2_START:											state <= L2_WAIT;
		L2_WAIT:												state <= L2_CALCJ;
		L2_CALCJ:											state <= L2_WAIT2;
		L2_WAIT2:											state <= L2_PREP_MEMJ;
		L2_PREP_MEMJ:										state <= L2_WRITE_MEMJ;
		L2_WRITE_MEMJ:										state <= L2_PREP_MEMI;
		L2_PREP_MEMI:										state <= L2_WRITE_MEMI;
		L2_WRITE_MEMI:		if(sram_addr == 8'hFF)	state <= L2B_START;
								else							state <= L2_WAIT;
		L2B_START:											state <= L2B_INC_I;
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
		L2B_WAIT_7:			if(k_counter == WORD_SIZE)	state <= L3_SET_RAM_ADDR;
								else							state <= L2B_INC_I;
								
		L3_SET_RAM_ADDR:									state <= L3_WAIT_1;
		L3_WAIT_1:											state <= L3_READ_RAM;					
		L3_READ_RAM:										state <= L3_WAIT_4;
		L3_WAIT_4:											state <= L3_WAIT_READ;
		L3_WAIT_READ:		if(((dram_data <= MAX_CHAR) & (dram_data >= MIN_CHAR)) | (dram_data == SPACE_CHAR))
									if(L_counter != WORD_SIZE)						state <= L3_INC_L;
									else													state <= L3_SUCCESS;
								else if(M_counter != MAX_KEYVAL)					state <= L3_INC_M;
								else if(M_counter == MAX_KEYVAL)					state <= L3_FAIL;
								else 														state <= L3_ERROR;
		L3_INC_L:											state <= L3_WAIT_3;
		L3_WAIT_3:											state <= L3_SET_RAM_ADDR;
		L3_SUCCESS:											state <= L3_SUCCESS;
		L3_FAIL:												state <= L3_FAIL;
		L3_INC_M:											state <= L3_WAIT_2;
		L3_WAIT_2:											state <= L3_LOAD_KEY;
		L3_ERROR:											state <= L3_ERROR;
	endcase
end


endmodule