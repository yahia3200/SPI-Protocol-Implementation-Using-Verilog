module Integration(MODE,SS_IN,START,READ_MEMORY_M,DATA_M,READ_MEMORY_S,DATA_S,OUT_STATE_MASTER,OUT_MAIN_MASTER,OUT_STATE_S[1],OUT_STATE_S[2],OUT_STATE_S[3],OUT_MAIN_SLAVE,CLK,isValid_Selection);
//INPUTS
input [0:2]MODE;
input [0:2]SS_IN;
input START;
input READ_MEMORY_M;
input[0:7] DATA_M;
input READ_MEMORY_S;
input[0:7]DATA_S;

//OUTPUTS
output [0:7]OUT_STATE_MASTER;
output [0:7]OUT_MAIN_MASTER;
output [0:7]OUT_MAIN_SLAVE;
output wire CLK;
output wire isValid_Selection;
output wire [0:7]OUT_STATE_S[1:3];

//PARAMETERS
wire CPHA_IN;
wire CPOL_IN; 
wire MISO;
wire MISO_S[1:3];
wire MOSI;
wire SS1;
wire SS2;
wire SS3;
wire [0:7]OUT_MAIN_S[1:3];
Master M(CPHA_IN,CPOL_IN,MISO,SS_IN,START,READ_MEMORY_M,DATA_M,MOSI,SS1,SS2,SS3,CLK,OUT_STATE_MASTER,OUT_MAIN_MASTER,isValid_Selection);
Slave S1(CPHA_IN,SS1,CLK,MOSI,READ_MEMORY_S,DATA_S,MISO_S[1],OUT_STATE_S[1],OUT_MAIN_S[1]);
Slave S2(CPHA_IN,SS2,CLK,MOSI,READ_MEMORY_S,DATA_S,MISO_S[2],OUT_STATE_S[2],OUT_MAIN_S[2]);
Slave S3(CPHA_IN,SS3,CLK,MOSI,READ_MEMORY_S,DATA_S,MISO_S[3],OUT_STATE_S[3],OUT_MAIN_S[3]);

assign {CPOL_IN,CPHA_IN}={MODE==0}?2'b00:
                         {MODE==1}?2'b01:
                         {MODE==2}?2'b11:
                         {MODE==3}?2'b10:2'bxx;

assign MISO=(SS1==0)?MISO_S[1]:
            (SS2==0)?MISO_S[2]:
            (SS3==0)?MISO_S[3]:1'bx;
                          
                          
assign OUT_MAIN_SLAVE=(SS1==0)?OUT_MAIN_S[1]:
                      (SS2==0)?OUT_MAIN_S[2]:
                      (SS3==0)?OUT_MAIN_S[3]:OUT_MAIN_SLAVE;                            
endmodule




module Integration_TB();

//Local parameters
reg START;
reg READ_MEMORY_M;
reg READ_MEMORY_S;
reg [0:2] MODE; 
reg [0:2] SS_IN;
reg [0:7] DATA_M;
reg [0:7] DATA_S;

integer f;
integer wrong = 0;

//OUTPUTS
wire isValid_Selection;
wire CLK;
wire [0:7]OUT_STATE_MASTER;
wire [0:7]OUT_MAIN_MASTER;
wire [0:7]OUT_STATE_SLAVE[1:3];
wire [0:7]OUT_MAIN_SLAVE;

Integration SPI(MODE,SS_IN,START,READ_MEMORY_M,DATA_M,READ_MEMORY_S,DATA_S,OUT_STATE_MASTER,OUT_MAIN_MASTER,OUT_STATE_SLAVE[1],OUT_STATE_SLAVE[2],OUT_STATE_SLAVE[3],OUT_MAIN_SLAVE,CLK,isValid_Selection);

initial begin

f = $fopen("SPI_Test.txt");

$fdisplay(f,"\n Commnication with Slave 1 in Mode 0 \n");
$fdisplay(f,"Mater sends 11111111 and Slave1 sends 00000000 ");

START=0;
DATA_M=8'b11111111;
READ_MEMORY_M=1;
MODE=0;
SS_IN=3'b011;
#10
$fmonitor(f,"clk=%b Mater_reg= %b  Slave1_reg=%b Slave2_reg=%b Slave3_reg=%b",CLK,OUT_STATE_MASTER,OUT_STATE_SLAVE[1],OUT_STATE_SLAVE[2],OUT_STATE_SLAVE[3]);
START=1;
READ_MEMORY_M=0;
#200
$fdisplay(f,"\n End Of Mode 0");

//OUT_MAIN_SLAVE is the excpected data to be transmitted to the Master
//OUT_MAIN_MASTER is the excpected data to be transmitted to the Slave
//OUT_STATE_MASTER is the Master's register
//OUT_STATE_MASTER is the Slave's register

//if successful communicaion
if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[1])
begin
$fdisplay(f," Communication Succeeded ");
end
else if(isValid_Selection==0)
begin
wrong = wrong +1;
$fdisplay(f,"==============================================");
$fdisplay(f," Communication Failed Due to invalid selection");
$fdisplay(f,"==============================================");
end 
else
begin
wrong = wrong +1;
$fdisplay(f," ========================");
$fdisplay(f," Communication Failed o.O");
$fdisplay(f," ========================");

$fdisplay(f," The excpected data to be sent to the Master: %b", OUT_MAIN_SLAVE);
$fdisplay(f," However the actual data transmitted to the Master was: %b", OUT_STATE_MASTER);

$fdisplay(f," The excpected data to be sent to the Slave: %b", OUT_MAIN_MASTER);
$fdisplay(f," However the actual data transmitted to the Slave was: %b", OUT_STATE_SLAVE[1]);
end
$fdisplay(f,"=============================================================================");

$fdisplay(f,"\n Commnication with Slave 2 in Mode 1 \n");
$fdisplay(f,"Mater sends 01010101 and Slave2 sends 10101010 ");
START=0;
MODE=1;
SS_IN=3'b101;
DATA_M=8'b01010101;
DATA_S=8'b10101010;
READ_MEMORY_S=1;
READ_MEMORY_M=1;
#10
START=1;
READ_MEMORY_S=0;
READ_MEMORY_M=0;
#200
$fdisplay(f,"\n End Of Mode 1");

if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[2])
begin
$fdisplay(f," Communication Succeeded ");
end
else if(isValid_Selection==0)
begin
wrong = wrong +1;
$fdisplay(f,"==============================================");
$fdisplay(f," Communication Failed Due to invalid selection");
$fdisplay(f,"==============================================");
end 
else
begin
wrong = wrong +1;
$fdisplay(f," ========================");
$fdisplay(f," Communication Failed o.O");
$fdisplay(f," ========================");

$fdisplay(f," The excpected data to be sent to the Master: %b", OUT_MAIN_SLAVE);
$fdisplay(f," However the actual data transmitted to the Master was: %b", OUT_STATE_MASTER);

$fdisplay(f," The excpected data to be sent to the Slave: %b", OUT_MAIN_MASTER);
$fdisplay(f," However the actual data transmitted to the Slave was: %b", OUT_STATE_SLAVE[2]);
end
$fdisplay(f,"=============================================================================");

$fdisplay(f,"\n Commnication with Slave 3 in Mode 2 \n");
$fdisplay(f,"Mater sends 01010101 and Slave3 sends 11110111 ");
START=0;
MODE=2;
SS_IN=3'b110;
DATA_S=8'b11110111;
READ_MEMORY_S=1;
READ_MEMORY_M=1;
#10
START=1;
READ_MEMORY_S=0;
READ_MEMORY_M=0;
#200
$fdisplay(f,"\n End Of Mode 2");

if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[3])
begin
$fdisplay(f," Communication Succeeded ");
end
else if(isValid_Selection==0)
begin
wrong = wrong +1;
$fdisplay(f,"==============================================");
$fdisplay(f," Communication Failed Due to invalid selection");
$fdisplay(f,"==============================================");
end 
else
begin
wrong = wrong +1;
$fdisplay(f," ========================");
$fdisplay(f," Communication Failed o.O");
$fdisplay(f," ========================");

$fdisplay(f," The excpected data to be sent to the Master: %b", OUT_MAIN_SLAVE);
$fdisplay(f," However the actual data transmitted to the Master was: %b", OUT_STATE_MASTER);

$fdisplay(f," The excpected data to be sent to the Slave: %b", OUT_MAIN_MASTER);
$fdisplay(f," However the actual data transmitted to the Slave was: %b", OUT_STATE_SLAVE[3]);
end
$fdisplay(f,"=============================================================================");

$fdisplay(f,"\n Commnication with Slave 2 in Mode 3");
$fdisplay(f,"Mater sends 10010011 and Slave2 sends 01001110 ");
START=0;
MODE=3;
SS_IN=3'b101;
DATA_M=8'b10010011;
DATA_S=8'b01001110;
READ_MEMORY_S=1;
READ_MEMORY_M=1;
#10
START=1;
READ_MEMORY_S=0;
READ_MEMORY_M=0;
#200
$fdisplay(f,"\n End Of Mode 3");

if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[2])
begin
$fdisplay(f," Communication Succeeded ");
end
else if(isValid_Selection==0)
begin
wrong = wrong +1;
$fdisplay(f,"==============================================");
$fdisplay(f," Communication Failed Due to invalid selection");
$fdisplay(f,"==============================================");
end 
else
begin
wrong = wrong +1;
$fdisplay(f," ========================");
$fdisplay(f," Communication Failed o.O");
$fdisplay(f," ========================");

$fdisplay(f," The excpected data to be sent to the Master: %b", OUT_MAIN_SLAVE);
$fdisplay(f," However the actual data transmitted to the Master was: %b", OUT_STATE_MASTER);

$fdisplay(f," The excpected data to be sent to the Slave: %b", OUT_MAIN_MASTER);
$fdisplay(f," However the actual data transmitted to the Slave was: %b", OUT_STATE_SLAVE[2]);
end
$fdisplay(f,"=============================================================================");

$fdisplay(f,"\n Simulation Ended. Number of wrong cases: %d", wrong);
$display("Simulation Ended. Number of wrong cases: %d, for more details check SPI_Test.txt file", wrong);

$fclose(f);
$stop;
end
endmodule


