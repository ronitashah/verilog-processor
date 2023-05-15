`define IBL 8
`define IB 0 : `IBL - 1
`define IBIL 3
`define IBI `IBIL - 1 : 0

`define valid 0
`define PC 16 : 1
`define target 32 : 17
`define pred 33
`define path 34
`define branch 35
`define F 35 : 0
`define FE 36

`define bad `FE
`define sub `FE + 1
`define movl `FE + 2
`define movh `FE + 3
`define jmp `FE + 4
`define jz `FE + 5
`define jnz `FE + 6
`define js `FE + 7
`define jns `FE + 8
`define ld `FE + 9
`define st `FE + 10
`define rw `FE + 11
`define ra `FE + 15 : `FE + 12
`define rb `FE + 19 : `FE + 16
`define rt `FE + 23 : `FE + 20
`define disp `FE + 31 : `FE + 24
`define R `FE + 31 : 0
`define RE `FE + 32

`define mis `RE
`define M `RE : 0
`define ME `RE + 1

`define va `ME + 15 : `ME
`define vb `ME + 31 : `ME + 16
`define M0 `ME + 31 : 0 
`define M0E `ME + 32

`define vt `ME + 15 : `ME
`define M1 `ME + 15 : 0
`define M1E `ME + 16