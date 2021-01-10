`ifndef _CP0_
`define _CP0_

    //CP0 register numbers
    `define CP0_INDEX {5'd0,3'b0}
    `define CP0_RANDOM {5'd1,3'b0}
    `define CP0_ENTRYLO0 {5'd2,3'b0}
    `define CP0_ENTRYLO1 {5'd3,3'b0}
    `define CP0_CONTEXT {5'd4,3'b0}
    `define CP0_PAGEMASK {5'd5,3'b0}
    `define CP0_WIRED {5'd6,3'b0}
    //5'd7 is none
    `define CP0_BADVADDR {5'd8,3'b0}
    `define CP0_COUNT {5'd9,3'b0}
    `define CP0_ENTRYHI {5'd10,3'b0}
    `define CP0_COMPARE {5'd11,3'b0}
    `define CP0_STATUS {5'd12,3'b0}
    `define CP0_CAUSE {5'd13,3'b0}
    `define CP0_EPC {5'd14,3'b0}
    `define CP0_PRID {5'd15,3'b0}
    `define CP0_CONFIG {5'd16,3'b0}
    `define CP0_LLADDR {5'd17,3'b0}
    `define CP0_WATCHLO {5'd18,3'b0}
    `define CP0_WATCHHI {5'd19,3'b0}
    //5'd20 ~ 5'd22 is none
    `define CP0_DEBUG {5'd23,3'b0}
    `define CP0_DEPC {5'd24,3'b0}
    //5'd25 is none
    `define CP0_ERRCTL {5'd26,3'b0}
    //5'd27 is none
    `define CP0_TAGLO {5'd28,3'b0}
    //5'd29 is none
    `define CP0_ERROREPC {5'd30,3'b0}
    `define CP0_DESAVE {5'd31,3'b0}

    //CP0_STATUS func
    `define CU 31:28
    `define RP 27
    `define RE 25
    `define BEV 22
    `define TS 21
    `define SR 20
    `define NMI 19
    `define IM72 15:10
    `define IM10 9:8
    `define UM 4
    `define ERL 2
    `define EXL 1
    `define IE 0

    //CP0_CAUSE func
    `define BD 31
    `define CE 29:28
    `define DC 27
    `define PCI 26
    `define IV 23
    `define WP 22
    `define IP72 15:10
    `define IP10 9:8
    `define EXCCODE 6:2

    //ExcCode func
    `define EXC_Int 0
    `define EXC_Mod 1
    `define EXC_TLBL 2
    `define EXC_TLBS 3
    `define EXC_AdEL 4
    `define EXC_AdES 5
    `define EXC_IBS 6
    `define EXC_DBE 7
    `define EXC_Sys 8
    `define EXC_Bp 9
    `define EXC_RI 10
    `define EXC_CpU 11
    `define EXC_Ov 12
    `define EXC_Tr 13
    `define EXC_WATCH 23
    `define EXC_MCheck 24

    //CP0_PRID func
    `define CompanyId 23:16
    `define ProcessorId 15:6
    `define Revision 5:0

    //CP0_CONFIG func
    `define M 31
    `define K23 30:28
    `define KU 27:25
    `define ImPl 24:16
    `define BE 15
    `define AT 14:13
    `define AR 12:10
    `define MT 9:7
    `define VI 3
    `define K0 2:0
    
`endif