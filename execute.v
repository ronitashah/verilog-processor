`include "macros.v"

module branch(input wire[`R]inst, input wire[15:0]va, input wire[15:0]vb, output wire[15:0]PC2);

    wire taken = inst[`jz] && va == 0 || inst[`jnz] && va != 0 || inst[`js] && va[15] == 1 || inst[`jns] && va[15] == 0;
    assign PC2 = taken ? vb : inst[`PC] + 2;

endmodule

module execute(input wire[`R]inst, input wire[15:0]va, input wire[15:0]vb, output wire[15:0]vt, output wire[15:0]PC2);

    wire[7:0]disp = inst[`disp];

    wire[15:0]vtsub = inst[`sub] ? va - vb : 0;
    wire[15:0]vtmovl = inst[`movl] ? {{8{disp[7]}}, disp} : 0;
    wire[15:0]vtmovh = inst[`movh] ? {disp, vb[7:0]} : 0;
    wire[15:0]vtst = inst[`st] ? vb : 0;

    branch branch(inst, va, vb, PC2);

    assign vt = inst[`jmp] ? PC2 : vtsub | vtmovl | vtmovh | vtst;

endmodule