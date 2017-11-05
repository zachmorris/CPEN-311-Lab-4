`default_nettype none
module rc4_state_machine
(
input clk,
input start_fsm,
input [7:0] data_to_fsm,
output reg [7:0] ram_addr,
output reg [7:0] data_to_ram,
output reg enable_ram
);

// general declarations

// counter for s-RAM memory
reg [7:0] s_counter = 8'h00;  // AHHHHHHHHHHHHH

// state
reg [7:0] state;

// state encoding
localparam IDLE 				= 8'b0000_0000;
localparam COLD_START 		= 8'b0001_0001;

// internal state bit use
assign enable_ram 					= state[0];

// instantiate memory
always_ff @(posedge clk)
begin
	if(enable_ram & s_counter <= 8'hFF)
	begin
		s_counter 	<= s_counter + 1'b1;
		ram_addr		<= s_counter;
		data_to_ram 	<= s_counter;
	end
end

// state transitions
always_ff @(posedge clk)
begin
	case(state)
		IDLE: 				if(start_fsm) 			state <= COLD_START;
		COLD_START:			if(s_counter == 8'hFF) 	state <= IDLE;
	endcase
end


endmodule