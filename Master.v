module Master(CPHA_IN, CPOL_IN, MISO, SS_IN, START, READ_MEMORY, DATA,
	      MOSI, SS1_OUT, SS2_OUT, SS3_OUT, CLK_OUT, OUT_STATE);

// INPUTS
input CPHA_IN;
input CPOL_IN;
input MISO;
input SS_IN;
input START;
input READ_MEMORY;
input [7:0] DATA;

// OUTPUTS
output reg MOSI;
output reg SS1_OUT;
output reg SS2_OUT;
output reg SS3_OUT;
output CLK_OUT;
output [7:0] OUT_STATE;


// PARAMETRS
reg [7:0] MAIN_MEMORY = 8'b00000000;
reg [7:0] STATE;
wire [7:0] NEXT_STATE;
integer SAMPLED_COUNT;
reg CLK;
wire CLK_INITIAL;
reg IS_VALID;

assign CLK_INITIAL = CPOL_IN;
assign NEXT_STATE = {MISO, STATE[7:1]};
assign CLK_OUT = CLK;
assign OUT_STATE = STATE;


// Load Data to The Main Memory
always @(posedge READ_MEMORY) begin 
MAIN_MEMORY = DATA;
end


// START COM.
always @(posedge START) begin
CLK = CPOL_IN;
STATE = MAIN_MEMORY;
MOSI = 1'bx;
SAMPLED_COUNT = 0;
IS_VALID = 0;
#10;

if (SS_IN == 1)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b011;

else if (SS_IN == 2)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b101;

else
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b110;

end

// Clock
always @(negedge SS1_OUT, negedge SS2_OUT, negedge SS3_OUT) begin 
while ((SS1_OUT && SS2_OUT && SS3_OUT) == 0) begin
CLK=~CLK;
#10;
end
end

always @(posedge CLK ) begin
if ((SS1_OUT && SS2_OUT && SS3_OUT) == 0) begin
	if(CPHA_IN ~^ CPOL_IN == 1 && IS_VALID) begin 
	STATE = NEXT_STATE;
	SAMPLED_COUNT = SAMPLED_COUNT + 1;

	if (SAMPLED_COUNT == 8)
	{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b111;

	end
	else begin
	MOSI = STATE[0];
	IS_VALID = 1;
	end
end
end


always @(negedge CLK ) begin
if ((SS1_OUT && SS2_OUT && SS3_OUT) == 0) begin
	if(CPHA_IN ^ CPOL_IN == 1 && IS_VALID) begin 
	STATE = NEXT_STATE;
	SAMPLED_COUNT = SAMPLED_COUNT + 1;

	if (SAMPLED_COUNT == 8)
	{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b111;

	end
	else begin
	MOSI = STATE[0];
	IS_VALID = 1;
	end
end
end


endmodule




module Master_Testbench();

// Inputs For Master
reg CPHA;
reg CPOL;
reg MISO;
integer SS;
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

integer f;


Master M1(CPHA, CPOL, MISO, SS, START, READ, DATA, MOSI, SS1, SS2,  SS3, CLK, STATE);

initial begin

f = $fopen("MASTER.txt");
$fdisplay(f, "TEST MODE 1");
$fdisplay(f, "CLK   STATE   MISO  MOSI");
$fmonitor(f,"%b    %b  %b    %b", CLK, STATE, MISO, MOSI);

CPHA = 0;
CPOL = 0;
MISO = 1;
SS = 1;
START = 0;
READ = 1;
DATA = 8'b00000000;

// TEST MODE 1
START = 1;
#10 START = 0; READ = 0;
#180;

// TEST MODE 2
$fdisplay(f, "##########################");
$fdisplay(f, "TEST MODE 2");
$fdisplay(f, "CLK   STATE   MISO  MOSI");
CPHA = 1;
READ = 1;
START = 1;
#10 START = 0; READ = 0;
#180;

// TEST MODE 3
$fdisplay(f, "##########################");
$fdisplay(f, "TEST MODE 3");
$fdisplay(f, "CLK   STATE   MISO  MOSI");
CPOL = 1;
CPHA = 0;
READ = 1;
START = 1;
#10 START = 0; READ = 0;
#180;

// TEST MODE 4
$fdisplay(f, "##########################");
$fdisplay(f, "TEST MODE 4");
$fdisplay(f, "CLK   STATE   MISO  MOSI");
CPOL = 1;
CPHA = 1;
READ = 1;
START = 1;
#10 START = 0; READ = 0;
#180;

$fclose(f);
$stop;


end


endmodule

