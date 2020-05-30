module Integration(MODE,SS_IN,START,READ_MEMORY_M,DATA_M,READ_MEMORY_S,DATA_S,OUT_STATE_MASTER,OUT_MAIN_MASTER,OUT_STATE_S[1],OUT_STATE_S[2],OUT_STATE_S[3],OUT_MAIN_SLAVE,CLK);
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
wire [0:7]OUT_STATE_SLAVE;
output [0:7]OUT_MAIN_SLAVE;


//PARAMETERS
wire CPHA_IN;
wire CPOL_IN; 
wire MISO;
wire MISO_S[1:3];
wire MOSI;
output wire CLK;
wire SS1;
wire SS2;
wire SS3;
output wire [0:7]OUT_STATE_S[1:3];
wire [0:7]OUT_MAIN_S[1:3];
Master M(CPHA_IN,CPOL_IN,MISO,SS_IN,START,READ_MEMORY_M,DATA_M,MOSI,SS1,SS2,SS3,CLK,OUT_STATE_MASTER,OUT_MAIN_MASTER);
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
                          
assign OUT_STATE_SLAVE=(SS1==0)?OUT_STATE_S[1]:
                       (SS2==0)?OUT_STATE_S[2]:
                       (SS3==0)?OUT_STATE_S[3]:OUT_STATE_SLAVE;
                          
assign OUT_MAIN_SLAVE=(SS1==0)?OUT_MAIN_S[1]:
                      (SS2==0)?OUT_MAIN_S[2]:
                      (SS3==0)?OUT_MAIN_S[3]:OUT_MAIN_SLAVE;                            
endmodule




module Integration_TB();
reg[0:2] MODE; 
reg [0:2]SS_IN;
reg START;
reg READ_MEMORY_M;
reg[0:7] DATA_M;
reg READ_MEMORY_S;
reg[0:7]DATA_S;

//OUTPUTS
wire [0:7]OUT_STATE_MASTER;
wire [0:7]OUT_MAIN_MASTER;
wire [0:7]OUT_STATE_SLAVE[1:3];
wire [0:7]OUT_MAIN_SLAVE;
wire CLK;
integer f;
Integration SPI(MODE,SS_IN,START,READ_MEMORY_M,DATA_M,READ_MEMORY_S,DATA_S,OUT_STATE_MASTER,OUT_MAIN_MASTER,OUT_STATE_SLAVE[1],OUT_STATE_SLAVE[2],OUT_STATE_SLAVE[3],OUT_MAIN_SLAVE,CLK);
initial begin
f = $fopen("SPI_Test.txt");
$fdisplay(f,"Commnication with Slave 1 in Mode 0");
$fdisplay(f,"Mater sends 11111111 and slave1 sends 00000000 ");
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
if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[1])
begin
$fdisplay(f," Successful Communication");
end
$fdisplay(f," End Of Mode 0");
$fdisplay(f,"//////////////////////////////////////////////////////////////////////");
$fdisplay(f,"Commnication with Slave 2 in Mode 1");
$fdisplay(f,"Mater sends 01010101 and slave2 sends 10101010 ");
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
if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[2])
begin
$fdisplay(f," Successful Communication");
end
$fdisplay(f," End Of Mode 1");
$fdisplay(f,"//////////////////////////////////////////////////////////////////////");
$fdisplay(f,"Commnication with Slave 3 in Mode 2");
$fdisplay(f,"Mater sends 01010101 and slave3 sends 11110111 ");
START=0;
MODE=2;
SS_IN=3'b110;
DATA_M=8'b01010101;
DATA_S=8'b11110111;
READ_MEMORY_S=1;
READ_MEMORY_M=1;
#10
START=1;
READ_MEMORY_S=0;
READ_MEMORY_M=0;
#200
if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[3])
begin
$fdisplay(f," Successful Communication");
end
$fdisplay(f," End Of Mode 2");
$fdisplay(f,"//////////////////////////////////////////////////////////////////////");
$fdisplay(f,"Commnication with Slave 2 in Mode 3");
$fdisplay(f,"Mater sends 10010011 and slave2 sends 01001110 ");
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
if(OUT_MAIN_SLAVE==OUT_STATE_MASTER && OUT_MAIN_MASTER==OUT_STATE_SLAVE[2])
begin
$fdisplay(f," Successful Communication");
end
$fdisplay(f," End Of Mode 3");
$fclose(f);
$stop;
end
endmodule

