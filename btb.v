`include "macros.v"

module btb(input clk, input wire[15:0]PCA, output wire branchA, output wire[15:0]targetA, input wire[15:0]PCB, output wire branchB, output wire[15:0]targetB, input wire WE, input wire[15:0]PCW, input wire[15:0]targetW);

    reg[7:0]tags[0:127];
    reg[15:0]targets[0:127];

    integer i;
    initial begin
        for (i = 0; i < 128; i += 1) begin
            tags[i] = 255;
            targets[i] = 65535;
        end
    end

    wire[6:0]hashA = PCA[7:1];
    wire[7:0]tagA = PCA[15:8];

    assign branchA = tags[hashA] == tagA;
    assign targetA = branchA ? targets[hashA] : PCA + 2;


    wire[6:0]hashB = PCB[7:1];
    wire[7:0]tagB = PCA[15:8];

    assign branchB = tags[hashB] == tagB;
    assign targetB = branchB ? targets[hashB] : PCB + 2;


    wire[6:0]hashW = PCW[7:1];
    wire[7:0]tagW = PCW[15:8];

    always @(posedge clk) begin

        if (WE) begin
            tags[hashW] <= tagW;
            targets[hashW] <= targetW;
        end
    end

endmodule