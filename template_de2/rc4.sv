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

logic start_press_L1;
logic start_press_L2;
logic start_press_L2b;

logic [7:0] s_addr;
logic [7:0] s_data_in;  // not sure if these should be logics
logic [7:0] s_data_out;
logic s_en;

//=======================================================
// CODE GOES HERE

reg [23:0] secret_key;
wire [7:0] s_current_val;

assign s_current_val = s_data_out;

assign secret_key = {14'b0, SW[9:0]};

logic [23:0] hex_to_display;


//=======================================================
// philosophy: main file handles I/O, I guess



// trap start press
async_trap_and_reset_gen_1_pulse start_loop_1_pulse(
.async_sig(!KEY[0]),
.outclk(CLK_50M),
.out_sync_sig(start_press_L1),
.auto_reset(1'b1),
.reset(1'b1));

async_trap_and_reset_gen_1_pulse start_loop_2_pulse(
.async_sig(!KEY[1]),
.outclk(CLK_50M),
.out_sync_sig(start_press_L2),
.auto_reset(1'b1),
.reset(1'b1));

async_trap_and_reset_gen_1_pulse start_loop_2b_pulse(
.async_sig(!KEY[2]),
.outclk(CLK_50M),
.out_sync_sig(start_press_L2b),
.auto_reset(1'b1),
.reset(1'b1));


// declare s_mem
s_memory s_mem(.address(s_addr), .clock(CLK_50M), .data(s_data_in), .wren(s_en), .q(s_data_out));

// instantiate state machine
// needs a catchier name
rc4_state_machine rc4_fsm(	.clk(CLK_50M),
									.start_loop_1(start_press_L1),
								   .start_loop_2(start_press_L2),
									.start_loop_2b(start_press_L2b),
									.data_to_fsm(s_current_val), 
									.sram_addr(s_addr),
									.data_to_sram(s_data_in), 
									.enable_sram(s_en),
									.secret_key_val(secret_key),
									.checking_key(hex_to_display),
									.success_light(LEDR[0]),
									.fail_light(LEDR[1]));

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
    
assign actual_7seg_output = hex_to_display;  // seven segment display input data


endmodule