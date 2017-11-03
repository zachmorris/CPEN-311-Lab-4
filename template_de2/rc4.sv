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
    HEX5,
    HEX6,
    HEX7

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
logic reset_n = SW[3];

//=======================================================
//  Code goes here
//=======================================================



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
    Clock_1Hz <= ~Clock_1Hz;
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


