module Master(CPHA_IN, CPOL_IN, MISO, SS_IN, START, READ_MEMORY, DATA,
	      MOSI, SS1_OUT, SS2_OUT, SS3_OUT, CLK_OUT, OUT_SHIFT_STATE, OUT_MAIN);

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
output reg SS1_OUT;
output reg SS2_OUT;
output reg SS3_OUT;
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
#10 START_CLK = 1;

// Choose the Correct Slave
if (SS_IN == 'b011)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b011;

else if (SS_IN == 'b101)
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b101;

else
{SS1_OUT, SS2_OUT, SS3_OUT} = 3'b110;



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
	    IS_VALID = 1;   // To Avoid Edges When Initializing Clock Value
	end

	else if(CPHA_IN == 0 && IS_VALID) begin
	    // Shifting Data
	    STATE[0:7] = {DATA_IN, STATE[0:6]}; 
	    SAMPLED_COUNT = SAMPLED_COUNT + 1;
	    // End COM. if All New 8bits are Shifted 
	    if (SAMPLED_COUNT == 8) begin
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


Master M1(CPHA, CPOL, MISO, SS, START, READ, DATA, MOSI, SS1, SS2,  SS3, CLK, STATE, MAIN);

initial begin

f = $fopen("Master_Test.txt");
$fdisplay(f, "TEST MODE 0 WITH SLAVE 1");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
$fmonitor(f,"%b    %b  %b    %b    %b   %b   %b", CLK, STATE, MISO, MOSI, SS1, SS2, SS3);

CPHA = 0;
CPOL = 0;
MISO = 1;
SS = 'b011;
START = 0;
READ = 1;
DATA = 8'b00000000;

// TEST MODE 0
START = 1;
#10 START = 0; READ = 0;
#200;

// TEST MODE 1
$fdisplay(f, "##########################");
$fdisplay(f, "TEST MODE 1 WITH SLAVE 2");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
CPHA = 1;
SS = 'b101;
START = 1;
#10 START = 0;
#200;

// TEST MODE 2
$fdisplay(f, "##########################");
$fdisplay(f, "TEST MODE 2 WITH SLAVE 3");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
CPOL = 1;
CPHA = 1;
SS = 'b110;
START = 1;
#10 START = 0;
#200;

// TEST MODE 3
$fdisplay(f, "##########################");
$fdisplay(f, "TEST MODE 3 WITH SLAVE 3");
$fdisplay(f, "CLK   STATE   MISO  MOSI SS1 SS2 SS3");
CPOL = 1;
CPHA = 0;
START = 1;
#10 START = 0;
#200;

$fclose(f);


$stop;


end


endmodule

