`include "macros.v"

`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    wire clk;
    clock c0(clk);

    reg halt = 0;

    reg[15:0]lost = 0;

    counter ctr(halt,clk);

    //MEM
    wire[15:1]MA0;
    wire[15:0]MD0;
    wire[15:1]MA1;
    wire[15:0]MD1;
    wire MWE;
    wire[15:1]MWA;
    wire[15:0]MWD;

    mem mem(clk,
    MA0, MD0,
    MA1, MD1,
    MWE, MWA, MWD);

    //REG
    wire[3:0]RA0;
    wire[15:0]RD0;
    wire[3:0]RA1;
    wire[15:0]RD1;
    wire RWE;
    wire[3:0]RWA;
    wire[15:0]RWD;

    regs regs(clk,
    RA0, RD0,
    RA1, RD1,
    RWE, RWA, RWD);

    //BTB
    wire[15:0]BPCA;
    wire BBA;
    wire[15:0]BTA;

    wire[15:0]BPCB;
    wire BBB;
    wire[15:0]BTB;

    wire BWE;
    wire[15:0]BWPC;
    wire[15:0]BWT;

    btb btb(clk,
    BPCA, BBA, BTA, 
    BPCB, BBB, BTB, 
    BWE, BWPC, BWT);

    //M1
    reg[`M1]M1 = 0;

    //M0
    reg[`M0]M0 = 0;

    //R
    reg[`R]R = 0;

    //IB
    reg[`R]IB[`IB];
    reg[`IBI]IBstart = 0;
    reg[`IBI]IBsize = 0;
    reg IBempty = 1;

    //F1
    reg[`F]F1B = 0;
    reg[`F]F1A = 0;

    //F0
    reg[`F]F0B = 0;
    reg[`F]F0A = 0;

    // PC
    reg[15:0]PC = 0;

    //M1-RW
    wire M1rw = M1[`valid] && M1[`rw];
    wire[15:0]M1vt = M1[`ld] ? M1[`mis] ? {MD0[7:0], MD1[15:8]} : MD1 : M1[`vt];
    assign RWA = M1[`rt];
    assign RWD = M1vt;
    assign RWE = M1rw;

    //M0-M1
    wire[15:0]M0va = M0[`ra] == 0 ? 0 : M1rw && M1[`rt] == M0[`ra] ? M1vt : M0[`va];
    wire[15:0]M0vb = M0[`rb] == 0 ? 0 : M1rw && M1[`rt] == M0[`rb] ? M1vt : M0[`vb];
    
    wire[15:0]M0vt;
    wire[15:0]M0PC2;
    execute execute(M0[`R], M0va, M0vb, M0vt, M0PC2);

    //M0-MW
    assign MWA = M0va[15:1];
    assign MWD = M0vt;
    assign MWE = M0[`valid] && M0[`st];

    //M0-PC
    wire[15:0]M0predTarget = M0[`pred] ? M0[`target] : M0[`PC] + 2;
    wire Mflush = M0[`valid] && (M0predTarget != M0PC2 || MWE && M0[`PC] < M0va && M0va < PC - 16);

    //R-M0
    wire M0rw = M0[`valid] && M0[`rw];
    wire[15:0]Rva = R[`ra] == 0 ? 0 : M0rw && M0[`rt] == R[`ra] ? M0vt : M1rw && M1[`rt] == R[`ra] ? M1vt : RD0;
    wire[15:0]Rvb = R[`rb] == 0 ? 0 : M0rw && M0[`rt] == R[`rb] ? M0vt : M1rw && M1[`rt] == R[`rb] ? M1vt : RD1;
    
    wire Rld = R[`valid] && R[`ld];
    wire Rmis = Rld && Rva[0];
    wire M0ld = M0[`valid] && M0[`ld];
    wire stall = Rld && M0ld && R[`ra] == M0[`rt];

    //F1-IB
    wire[15:0]F1APC = F1A[`PC];
    wire FAmis = F1A[`valid] && F1APC[0];
    wire[15:0]FAinst = FAmis ? {MD1[7:0], MD0[15:8]} : MD0; 

    wire[`R]FAIB;
    decode decodeA(FAinst, F1A, FAIB);
    wire[`R]FBIB;
    decode decodeB(MD1, FAmis ? 0 : F1B, FBIB);

    //R-PC
    wire[15:0]RPC2;
    branch branch(R, Rva, Rvb, RPC2);
    wire[15:0]RpredTarget = R[`pred] ? R[`target] : R[`PC] + 2;
    wire Rdep = M0ld && (M0[`rt] == R[`ra] || M0[`rt] == R[`rb]);
    wire Rflush = R[`valid] && !R[`bad] && RPC2 != RpredTarget && !Rdep && !Mflush;
    wire Rflow = Rflush && RPC2 == FAIB[`PC] && FAIB[`valid];
    wire Rflow2 = Rflow && FBIB[`valid];
    wire[15:0]RPC3 = !Rflow ? RPC2 : !Rflow2 ? FBIB[`PC] : FBIB[`pred] ? FBIB[`target] : FBIB[`PC] + 2;

    //BTB
    wire Mjmp = M0[`valid] && M0[`jmp];
    wire Rjmp = R[`valid] && !R[`bad] && R[`jmp] && !Rdep;
    
    assign BWE = Mjmp || Rjmp;
    assign BWPC = Mjmp ? M0[`PC] : R[`PC];
    assign BWT = Mjmp ? M0vb : Rvb;

    //IB-R
    wire[`R]IBR = IBempty ? FAIB[`path] ? FAIB : 0 : IB[IBstart];
    wire[`IBI]IBstart2 = stall ? IBstart : IBstart + 1;
    wire[`IBI]IBsize2 = stall ? IBsize : IBempty ? 0 : IBsize - 1;
    wire IBempty2 = stall ? IBempty : IBempty || IBsize == 1;

    assign RA0 = Rflow ? FAIB[`ra] : stall ? R[`ra] : IBR[`ra];
    assign RA1 = Rflow ? FAIB[`rb] : stall ? R[`rb] : IBR[`rb];

    //F1-IB
    wire FApath = F1A[`valid] && F1A[`path];
    wire FAflush = FApath && IBsize2 == 0 && !IBempty2;
    wire FAIBvalid = FApath && !FAflush && (!IBempty || stall);
    wire[`IBI]FAIBindex = IBstart2 + IBsize2;
    wire[`IBI]IBsize3 = IBsize2 + (FAIBvalid ? 1 : 0);
    wire IBempty3 = IBempty2 && !FAIBvalid;

    wire FBpath = F1B[`valid] && F1B[`path];
    wire FBflush = FBpath && IBsize3 == 0 && !IBempty3;
    wire FBIBvalid = FBpath && !FAflush && !FBflush;
    wire[`IBI]FBIBindex = IBstart2 + IBsize3;
    wire[`IBI]IBsize4 = IBsize3 + (FBIBvalid ? 1 : 0);
    wire IBempty4 = IBempty3 && !FBIBvalid;

    //flush
    wire flush = Rflush || Mflush;
    wire Fflush = flush || FAflush || FBflush;

    //PC-F0
    wire PCFAvalid = Mflush || !Rmis || stall;
    wire PCFBvalid = Mflush || !Rld || stall;

    wire[`F]nextI = !IBempty2 ? IB[IBstart2][`F] : !IBempty ? FApath ? F1A : F0A : FApath ? FBpath ? F1B : F0A : F0B;
    wire path = !nextI[`valid] || !nextI[`branch] || !nextI[`path] || flush;
    wire[15:0]nextPC2 = nextI[`pred] ? nextI[`PC] + 2 : nextI[`target];
    
    wire[15:0]PC1 = Mflush ? M0PC2 : Rflush ? RPC3 : FAflush ? FAIB[`PC] : FBflush ? FBIB[`PC] : PC;
    wire[15:0]PC2 = !path ? nextPC2 : PC1;
    assign BPCA = PC2;

    wire[`F]PCFA;
    assign PCFA[`valid] = PCFAvalid && (!PC2[0] || PCFBvalid);
    assign PCFA[`PC] = PC2;
    assign PCFA[`target] = BTA;
    assign PCFA[`branch] = BBA && !PC2[0];
    assign PCFA[`pred] = PCFA[`branch] && PCFA[`target] < PCFA[`PC];
    assign PCFA[`path] = path;
    assign MA0 = PCFA[`valid] ? PC2[15:1] : Rva[15:1] + 1;

    wire[15:0]PC3 = PCFA[`valid] ? PCFA[`pred] ? PCFA[`target] : PC2 + 2 : PC2; //still next if misaligned
    assign BPCB = PC3;
    
    wire[`F]PCFB;
    assign PCFB[`valid] = PCFBvalid;
    assign PCFB[`PC] = PC3;
    assign PCFB[`target] = BTB;
    assign PCFB[`branch] = BBB && !PC3[0];
    assign PCFB[`pred] = PCFB[`branch] && PCFB[`target] < PCFB[`PC];
    assign PCFB[`path] = path;
    assign MA1 = PCFB[`valid] ? PC3[15:1] : Rva[15:1];

    //PC-PC
    wire[15:0]nextPC = !path ? PC1 : PCFB[`valid] && (!PCFA[`valid] || !PC2[0]) ? PCFB[`pred] ? PCFB[`target] : PC3 + 2 : PC3;

    wire[15:0]nextLost = lost + (flush && !Rflow ? Mflush ? 3 : 2 : 0);

    always @(posedge clk) begin
        //$write("%00h\t%00h\t%00h\t%00h\t%00h\t%00h\t%00h\t%00h\t\t%00h\t%00h\t%00h\n", nextI[`PC], nextI[`branch], path, nextI[`path], nextI[`valid], flush, Rflow, R[`PC], IB[IBstart2][`PC], FAIB[`PC], FBIB[`PC]);
        if (M1rw && !M1[`bad] && M1[`rt] == 0)  begin
            $write("%c", M1vt[7:0]);
        end

        halt <= M0[`valid] && M0[`bad] || R[`valid] && R[`bad] && !Mflush;

        //M0-M1
        M1 <= {M0vt, M0[`M]};

        //R-M0
        M0 <= flush || stall ? 0 : {Rvb, Rva, Rmis, R};

        //IB-R
        if (!stall) begin
            R <= flush ? Rflow ? FAIB : 0 : IBR;
        end

        //IB-IB
        IBstart <= IBstart2;
        IBsize <= flush ? Rflow2 : IBsize4;
        IBempty <= flush ? !Rflow2 : IBempty4;
        
        //F1-IB
        if (FAIBvalid && !flush) begin
            IB[FAIBindex] <= FAIB;
        end
        if (FBIBvalid && !flush) begin
            IB[FBIBindex] <= FBIB;
        end
        if (Rflow2) begin
            IB[IBstart2] <= FBIB;
        end

        //F0-F1
        F1A <= Fflush && F0A[`path] ? 0 : F0A;
        F1B <= Fflush && F0B[`path] ? 0 : F0B;

        //PC-F0
        F0A <= PCFA;
        F0B <= PCFB;

        //PC-PC
        PC <= nextPC;

        if (lost != nextLost) begin
            lost <= nextLost;
            //$write("\n%00h\n", nextLost);
        end
    end
endmodule