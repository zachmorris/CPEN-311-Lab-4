`default_nettype none
module rc4(

    //////////// CLOCK //////////
    CLOCK_50,

    //////////// LED //////////
    LEDR,

    //////////// KEY //////////
    KEY,

    //////////// SW //////////
    SW,

    //////////// SEG7 //////////
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5

);


//////////// CLOCK //////////
input                       CLOCK_50;

//////////// KEY //////////
input            [3:0]      KEY;

//////////// SW //////////
input           [17:0]      SW;

//////////// LED //////////
output          [17:0]      LEDR;

//////////// SEG7 //////////
output           [6:0]      HEX0;
output           [6:0]      HEX1;
output           [6:0]      HEX2;
output           [6:0]      HEX3;
output           [6:0]      HEX4;
output           [6:0]      HEX5;

//=======================================================
//  REG/WIRE declarations
//=======================================================
// Input and output declarations
logic CLK_50M;
assign CLK_50M =  CLOCK_50;
logic reset_n;


wire start_press;

// declarations for s-RAM memory
reg [7:0] s_addr;
reg [7:0] s_data_in;  // not sure if these should be regs
reg [7:0] s_data_out;
logic s_en;

// counter for s-RAM memory
reg [7:0] s_counter = 8'h00;  // AHHHHHHHHHHHHH

// state
reg [7:0] state;

//=======================================================
//  Code goes here
//=======================================================

// how do we instantiate something that only runs once?
// how do we make it start? Do we have any user input?

// state encoding
localparam IDLE 				= 8'b0000_0000;
localparam COLD_START 		= 8'b0001_0001;

// internal state bit use
assign s_en 					= state[0];

// instantiate memory
always_ff @(posedge CLK_50M)
begin
	if(s_en & s_counter <= 8'hFF)
	begin
		s_counter 	<= s_counter + 1'b1;
		s_addr 		<= s_counter;
		s_data_in 	<= s_counter;
	end
end

// state transitions
always_ff @(posedge CLK_50M)
begin
	case(state)
		IDLE: 				if(start_press) 			state <= COLD_START;
		COLD_START:			if(s_counter == 8'hFF) 	state <= IDLE;
	endcase
end


// declare s_mem
s_memory s_mem(.address(s_addr), .clock(CLK_50M), .data(s_data_in), .wren(s_en), .q(s_data_out));

// trap start press
async_trap start_key_pulse(.async_sig(!KEY[0]), .clk(CLK_50M), .reset(1'b0), .trapped_edge(start_press));



//=====================================================================================
//
//  Seven-Segment and speed control
//
//=====================================================================================
logic [7:0] Seven_Seg_Val[7:0];
logic [3:0] Seven_Seg_Data[7:0];
    
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst0(.ssOut(Seven_Seg_Val[0]), .nIn(Seven_Seg_Data[0]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst1(.ssOut(Seven_Seg_Val[1]), .nIn(Seven_Seg_Data[1]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst2(.ssOut(Seven_Seg_Val[2]), .nIn(Seven_Seg_Data[2]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst3(.ssOut(Seven_Seg_Val[3]), .nIn(Seven_Seg_Data[3]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst4(.ssOut(Seven_Seg_Val[4]), .nIn(Seven_Seg_Data[4]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst5(.ssOut(Seven_Seg_Val[5]), .nIn(Seven_Seg_Data[5]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst6(.ssOut(Seven_Seg_Val[6]), .nIn(Seven_Seg_Data[6]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst7(.ssOut(Seven_Seg_Val[7]), .nIn(Seven_Seg_Data[7]));

assign HEX0 = Seven_Seg_Val[0];
assign HEX1 = Seven_Seg_Val[1];
assign HEX2 = Seven_Seg_Val[2];
assign HEX3 = Seven_Seg_Val[3];
assign HEX4 = Seven_Seg_Val[4];
assign HEX5 = Seven_Seg_Val[5];
            
wire Clock_2Hz;
            
Generate_Arbitrary_Divided_Clk32 
Gen_2Hz_clk
(.inclk(CLK_50M),
.outclk(Clock_2Hz),
.outclk_Not(),
.div_clk_count(32'h17D7840 >> 1),
.Reset(1'h1)
); 
        
logic [31:0] actual_7seg_output;
reg [31:0] regd_actual_7seg_output;

always @(posedge Clock_2Hz)
begin
    regd_actual_7seg_output <= actual_7seg_output;
end


assign Seven_Seg_Data[0] = regd_actual_7seg_output[3:0];
assign Seven_Seg_Data[1] = regd_actual_7seg_output[7:4];
assign Seven_Seg_Data[2] = regd_actual_7seg_output[11:8];
assign Seven_Seg_Data[3] = regd_actual_7seg_output[15:12];
assign Seven_Seg_Data[4] = regd_actual_7seg_output[19:16];
assign Seven_Seg_Data[5] = regd_actual_7seg_output[23:20];
assign Seven_Seg_Data[6] = regd_actual_7seg_output[27:24];
assign Seven_Seg_Data[7] = regd_actual_7seg_output[31:28];
    
assign actual_7seg_output =  4'h0;  // seven segment display input data


endmodule