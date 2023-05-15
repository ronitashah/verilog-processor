`include "macros.v"

module decode(input wire[15:0] inst, input wire[`F] F, output wire[`R] R);

    assign R[`F] = F;

    wire[3:0]op = inst[15:12];
    wire[3:0]ia = inst[11:8];
    wire[3:0]ib = inst[7:4];
    wire[3:0]it = inst[3:0];

    assign R[`disp] = inst[11:4];

    assign R[`sub] = op == 0;

    assign R[`movl] = op == 8;
    assign R[`movh] = op == 9;

    assign R[`jmp] = op == 14;
    assign R[`jz] = R[`jmp] && ib == 0;
    assign R[`jnz] = R[`jmp] && ib == 1;
    assign R[`js] = R[`jmp] && ib == 2;
    assign R[`jns] = R[`jmp] && ib == 3;

    wire mem = op == 15;
    assign R[`ld] = mem && ib == 0;
    assign R[`st] = mem && ib == 1;

    assign R[`rw] = R[`sub] || R[`movl] || R[`movh] || R[`ld];
    
    assign R[`bad] = !(R[`rw] || R[`st] || R[`jz] || R[`jnz] || R[`js] || R[`jns]);

    assign R[`ra] = ia;
    assign R[`rb] = R[`sub] ? ib : it;
    assign R[`rt] = it;

endmodule