module Slave(CPHA, SS, CLK, MOSI, READ_MEMORY, DATA, 
	     MISO, OUT_SHIFT_STATE, OUT_MAIN);

// INPUTS
input CPHA;	//CLOCK PHASE
input CLK;	//CLOCK POLARITY
input SS;	//SLAVE SELECT
input  MOSI;	//MASTER OUTPUT SLAVE INPUT
input READ_MEMORY;//READING FROM MEMORY OR WRITING
input [7:0]DATA; //INPUT DATA FOR SLAVE

// OUTPUTS
output  MISO;	//MASTER INPUT SLAVE OUTPUT
output [0:7]OUT_SHIFT_STATE; 
output [0:7]OUT_MAIN;

// PARAMETRS
reg [0:7] MAIN_MEMORY = 8'b00000000;
reg [0:7] STATE;
reg DATA_IN;
reg IS_VALID = 0;

assign OUT_SHIFT_STATE = STATE;
assign OUT_MAIN = MAIN_MEMORY;
assign  MISO =STATE[7];
// Load Data to The Main Memory
always @(posedge READ_MEMORY) begin 
MAIN_MEMORY = DATA;
end

always @(negedge SS) begin
IS_VALID = 0;
STATE = MAIN_MEMORY;
end

always @(posedge CLK) begin
if(SS == 0) begin
	if(CPHA == 0) begin 
	    DATA_IN = MOSI;
            IS_VALID = 1;
	end
	else if(CPHA == 1 && IS_VALID)begin
	    STATE[0:7] = {DATA_IN, STATE[0:6]}; 
	end
end
end

always @(negedge CLK) begin
if(SS == 0) begin
	if(CPHA == 1) begin 
	    DATA_IN = MOSI;
	    IS_VALID = 1;
	end
	else if(CPHA == 0 && IS_VALID) begin
	    STATE[0:7] = {DATA_IN, STATE[0:6]};
	end
end
end

endmodule


///////////////////////////////////--> SLAVE TESTBENCH <--////////////////////////////////////////////////////////

module Slave_tb();

//SLAVE INPUTS 
reg CPHA;
reg CPOL;
reg CLK;
reg SS = 1;
reg MOSI;
reg READ_MEMORY;
reg [0:7]DATA;

//OUTPUTS 
wire MISO;
wire [0:7]OUT_SHIFT_STATE;
wire [0:7]OUT_MAIN;

integer f;
integer Iterator;
integer i = 1;
reg START = 0;
reg [7:0]TEST_CASE;
integer wrong = 0;

Slave Slave1(CPHA,SS,CLK,MOSI,READ_MEMORY,DATA,MISO,OUT_SHIFT_STATE,OUT_MAIN);

always @(OUT_SHIFT_STATE) begin
if (OUT_SHIFT_STATE != 8'b00000000) begin
MOSI = TEST_CASE[i % 8];
i = i + 1;
end

end

initial begin 
f=$fopen("Slave_tb.txt");
$fdisplay (f,"////////// SLAVE TESTBENCH //////////////////");
$fdisplay (f,"/////////////////////////////////////////////");
$fdisplay (f,"/////////////// MODE 0 //////////////////////");
$display("SEND 01010101 To SLAVE IN MODE 0");
$fdisplay (f,"CLK	MOSI	MISO	OUT_SHIFT_STATE");
$fmonitor (f,"%b	%b	%b	%b",CLK,MOSI,MISO,OUT_SHIFT_STATE);

// MODE 0
SS=0;
CPHA=0;
CPOL=0;
CLK=0;
READ_MEMORY=1;
DATA=8'b00000000;
TEST_CASE = 8'b01010101;
MOSI = TEST_CASE[0];
#10 START = 1;

//CLK GENERATION :
for (Iterator=1;Iterator<17;Iterator=Iterator+1) begin 
CLK=~CLK;
#10;
end

READ_MEMORY=0; SS = 1;
#20;

if(OUT_SHIFT_STATE == 8'b01010101) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 01010101 Output: %b", OUT_SHIFT_STATE);
$fdisplay(f, "Wrong Output Expected Output: 01010101 Output: %b", OUT_SHIFT_STATE);
end

//MODE 1
$fdisplay (f,"/////////////////////////////////////////////");
$fdisplay (f,"/////////////// MODE 1 //////////////////////");
$display("SEND 00110011 To SLAVE IN MODE 1");
$fdisplay (f,"CLK	MOSI	MISO	OUT_SHIFT_STATE	");

CPHA=1;
READ_MEMORY=1;
SS = 0;
TEST_CASE = 8'b00110011;
i = 1;
MOSI = TEST_CASE[0];
#10;

//CLK GENERATION 
for (Iterator=0;Iterator<17;Iterator=Iterator+1) begin 
CLK=~CLK;
#10;
end

SS = 1;
#20;

if(OUT_SHIFT_STATE == 8'b00110011) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 00110011 Output: %b", OUT_SHIFT_STATE);
$fdisplay(f, "Wrong Output Expected Output: 00110011 Output: %b", OUT_SHIFT_STATE);
end

//MODE 2
$fdisplay (f,"/////////////////////////////////////////////");
$fdisplay (f,"/////////////// MODE 2 //////////////////////");
$display("SEND 01101101 To SLAVE IN MODE 2");
$fdisplay (f,"CLK	MOSI	MISO	OUT_SHIFT_STATE	");

CPHA=1;
CPOL=1;
READ_MEMORY=1;
MOSI=1;
TEST_CASE = 8'b01101101;
SS = 0;
i = 1;
MOSI = TEST_CASE[0];
#10;

//CLK GENERATION 
for (Iterator=1;Iterator<17;Iterator=Iterator+1) begin 
CLK=~CLK;
#10;
end

SS = 1;
#20 READ_MEMORY=0;

if(OUT_SHIFT_STATE == 8'b01101101) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 01101101 Output: %b", OUT_SHIFT_STATE);
$fdisplay(f, "Wrong Output Expected Output: 01101101 Output: %b", OUT_SHIFT_STATE);
end

//MODE 3
$fdisplay (f,"/////////////////////////////////////////////");
$fdisplay (f,"/////////////// MODE 3 //////////////////////");
$display("SEND 10101010 To SLAVE IN MODE 3");
$fdisplay (f,"CLK	MOSI	MISO	OUT_SHIFT_STATE");

CPHA=0;
CPOL=1;
READ_MEMORY=1;
SS = 0;
MOSI=0;
i = 1;
TEST_CASE = 8'b00110011;
MOSI = TEST_CASE[0];

#10;

for (Iterator=1;Iterator<18;Iterator=Iterator+1) begin 
CLK=~CLK;
#10;
end

#20 READ_MEMORY=0;

if(OUT_SHIFT_STATE == 8'b00110011) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 00110011 Output: %b", OUT_SHIFT_STATE);
$fdisplay(f, "Wrong Output Expected Output: 00110011 Output: %b", OUT_SHIFT_STATE);
end


//MODE DEACTIVATED
$fdisplay (f,"//////////////////////////////////////////////");
$fdisplay (f,"/////////// SLAVE IS DEACTIVATED /////////////");
$display("SEND 11111111 To SLAVE WHEN DEACTIVATED");
$fdisplay (f,"CLK	MOSI	MISO	OUT_SHIFT_STATE");

SS=1;
CLK=1;
MOSI=1;
TEST_CASE = 8'b11111111;
i = 0;

for (Iterator=0;Iterator<=17;Iterator=Iterator+1) begin 
CLK=~CLK;
#10;
end

#20 READ_MEMORY=0;

if(OUT_SHIFT_STATE == 8'b00110011) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 10101010 Output: %b", OUT_SHIFT_STATE);
$fdisplay(f, "Wrong Output Expected Output: 10101010 Output: %b", OUT_SHIFT_STATE);
end


$fdisplay (f,"//////////////////////////////////////////////");
$fdisplay (f,"/////////////// END SIMULATION ///////////////");
$display("Simulation Ended. Number of wrong cases: %d", wrong);
$display("for more details check Slave_tb.txt file");



$fclose(f);


$stop;
end

endmodule 
















