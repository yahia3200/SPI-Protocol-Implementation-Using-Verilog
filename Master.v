module Master(CPHA_IN, CPOL_IN, MISO, SS_IN, START, READ_MEMORY, DATA,
	      MOSI, SS1_OUT, SS2_OUT, SS3_OUT, CLK_OUT, OUT_SHIFT_STATE, OUT_MAIN, isValid_Selection);

// INPUTS
input CPHA_IN;
input CPOL_IN;
input MISO;
input [0:2]SS_IN;
input START;
input READ_MEMORY;
input [7:0] DATA;

// OUTPUTS
output MOSI;
output reg SS1_OUT = 1;
output reg SS2_OUT = 1;
output reg SS3_OUT = 1;
output reg isValid_Selection; //A flag to detect any invalid value for the SS line
output CLK_OUT;
output [0:7] OUT_SHIFT_STATE;
output [0:7] OUT_MAIN;


// PARAMETRS
reg [0:7] MAIN_MEMORY = 8'b00000000;
reg [0:7] STATE;
integer SAMPLED_COUNT;
reg CLK;
reg IS_VALID;
reg DATA_IN;
reg START_CLK;

// Clock Output to the Slave
assign CLK_OUT = CLK;
// 
assign OUT_SHIFT_STATE = STATE;
assign OUT_MAIN = MAIN_MEMORY;
// Master Output to the Slave
assign MOSI = STATE[7];

// Load Data to The Main Memory
always @(posedge READ_MEMORY) begin 
MAIN_MEMORY = DATA;
end


// START COM.
always @(posedge START) begin
// Initializing Parameters
CLK = CPOL_IN;
STATE = MAIN_MEMORY;
SAMPLED_COUNT = 0;
IS_VALID = 0;
isValid_Selection = 1;
#10 START_CLK = 1;

// Choose the Correct Slave
if (SS_IN == 'b011)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b011;

else if (SS_IN == 'b101)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b101;

else if (SS_IN == 'b110)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b110;

else
begin
isValid_Selection = 0;
end

end

// Clock
always @(negedge SS1_OUT, negedge SS2_OUT, negedge SS3_OUT) begin 
while ((SS1_OUT && SS2_OUT && SS3_OUT) == 0) begin
if (START_CLK == 1) // To Avoid Change The Clock Value at the End of COM.
CLK=~CLK;
#10; 
end
end


// @ Postive Edge: Sampling if CPHA == 0 OR Shifting if CPHA == 1
always @(posedge CLK) begin
if(START_CLK == 1) begin   // To Avoid Edges When Initializing Clock Value
	if(CPHA_IN == 0) begin
	    // Sampling Data
	    DATA_IN = MISO;
	    IS_VALID = 1;   // To Avoid Shifting Before Sampling
	end

	else if(CPHA_IN == 1 && IS_VALID) begin
	    // Shifting Data
            STATE[0:7] = {DATA_IN, STATE[0:6]}; 
	    SAMPLED_COUNT = SAMPLED_COUNT + 1;
	    // End COM. if All New 8bits are Shifted 
	    if (SAMPLED_COUNT == 8) begin
            #10
	    {SS1_OUT, SS2_OUT, SS3_OUT} = 3'b111;
	    START_CLK = 0;
   	    end
	end
end
end


// @ Negative Edge: Sampling if CPHA == 1 OR Shifting if CPHA == 0
always @(negedge CLK) begin
if (START_CLK == 1) begin   // To Avoid Edges When Initializing Clock Value
	if(CPHA_IN == 1) begin
	    // Sampling Data
	    DATA_IN = MISO;
	    IS_VALID = 1;   // To Avoid Shifting Before Sampling
	end

	else if(CPHA_IN == 0 && IS_VALID) begin
	    // Shifting Data
	    STATE[0:7] = {DATA_IN, STATE[0:6]}; 
	    SAMPLED_COUNT = SAMPLED_COUNT + 1;
	    // End COM. if All New 8bits are Shifted 
	    if (SAMPLED_COUNT == 8) begin
            #10 //so the slave could handle the last bit
	    {SS1_OUT, SS2_OUT, SS3_OUT} = 3'b111;
	    START_CLK = 0;    
	    end
	end
end
end

endmodule




module Master_Testbench();

// Inputs For Master
reg CPHA;
reg CPOL;
reg MISO;
reg [0:2]SS;
reg START;
reg READ;
reg [0:7]DATA;

// Outputs
wire MOSI;
wire SS1;
wire SS2;
wire SS3;
wire CLK;
wire [7:0]STATE;
wire [7:0]MAIN;

integer f;
integer Iterator;
integer wrong = 0;
reg [7:0]TEST_CASE;


Master M1(CPHA, CPOL, MISO, SS, START, READ, DATA, MOSI, SS1, SS2,  SS3, CLK, STATE, MAIN);

initial begin

f = $fopen("Master_Test.txt");
$fdisplay(f, "SEND 01010101 To MASTER IN MODE 0 FROM SLAVE 1");
$display("SEND 01010101 To MASTER IN MODE 0 FROM SLAVE 1");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
$fmonitor(f,"%b    %b  %b    %b    %b   %b   %b", CLK, STATE, MISO, MOSI, SS1, SS2, SS3);

CPHA = 0;
CPOL = 0;
MISO = 0;
SS = 'b011;
START = 0;
READ = 1;
DATA = 8'b00000000;
TEST_CASE = 8'b01010101;

// TEST MODE 0
START = 1;
MISO = TEST_CASE[0];

for (Iterator = 1; Iterator < 8; Iterator = Iterator + 1) begin 
#20 MISO = TEST_CASE[Iterator];
end
START = 0; READ = 0;
#50;

if(STATE == 8'b01010101) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 01010101 Output: %b", STATE);
$fdisplay(f, "Wrong Output Expected Output: 01010101 Output: %b", STATE);
end

// TEST MODE 1
$fdisplay(f, "##########################");
$fdisplay(f, "SEND 00110011 To MASTER IN MODE 1 FROM SLAVE 2");
$display("SEND 00110011 To MASTER IN MODE 1 FROM SLAVE 2");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
CPHA = 1;
SS = 'b101;
TEST_CASE = 8'b00110011;
START = 1;
MISO = TEST_CASE[0];

#10;
for (Iterator = 1; Iterator < 8; Iterator = Iterator + 1) begin 
#20 MISO = TEST_CASE[Iterator];
end
START = 0;
#50;

if(STATE == 8'b00110011) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 00110011 Output: %b", STATE);
$fdisplay(f, "Wrong Output Expected Output: 00110011 Output: %b", STATE);
end

// TEST MODE 2
$fdisplay(f, "##########################");
$fdisplay(f, "SEND 01101101 To MASTER IN MODE 2 FROM SLAVE 3");
$display("SEND 01101101 To MASTER IN MODE 2 FROM SLAVE 3");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
CPOL = 1;
CPHA = 1;
SS = 'b110;
TEST_CASE = 8'b01101101;
START = 1;
MISO = TEST_CASE[0];

for (Iterator = 1; Iterator < 8; Iterator = Iterator + 1) begin 
#20 MISO = TEST_CASE[Iterator];
end
START = 0; READ = 0;
#50;

if(STATE == 8'b01101101) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 01101101 Output: %b", STATE);
$fdisplay(f, "Wrong Output Expected Output: 01101101 Output: %b", STATE);
end

// TEST MODE 3
$fdisplay(f, "##########################");
$fdisplay(f, "SEND 10101010 To MASTER IN MODE 3 FROM SLAVE 3");
$display("SEND 10101010 To MASTER IN MODE 3 FROM SLAVE 3");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
CPOL = 1;
CPHA = 0;
TEST_CASE = 8'b10101010;
START = 1;
MISO = TEST_CASE[0];

#10;
for (Iterator = 1; Iterator < 8; Iterator = Iterator + 1) begin 
#20 MISO = TEST_CASE[Iterator];
end
START = 0;
#50;

if(STATE == 8'b10101010) begin
$display("Passed This Test Successfully");
$fdisplay(f, "Passed This Test Successfully");
end
else begin
wrong = wrong + 1;
$display("Wrong Output Expected Output: 10101010 Output: %b", STATE);
$fdisplay(f, "Wrong Output Expected Output: 10101010 Output: %b", STATE);
end

$display("Simulation Ended. Number of wrong cases: %d", wrong);
$display("for more details check Master_Test.txt file");

$fclose(f);
$stop;


end


endmodule

