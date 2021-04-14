// *****************************************************************************
// Filename    : SDRAM_Control_4Port.v
// Create on   : 2021/1/26 14:23
// Revise on   : 2021/1/26 14:23
// Version     : 1.0
// Author      : ccb
// Email       : chunbo_chen@163.com    
// Description : SDRAM的多端口控制器,其中fifo采用show-ahead模式
//               
// Editor      : sublime text 3, tab size 4
// *****************************************************************************

`timescale        1ns/1ns

module SDRAM_Control_Mult_Port
(
	//	HOST Side
	CLK,
	RESET_N,		
	
	//	FIFO Write Side 1
	WR1_DATA,
	WR1,
	WR1_ADDR,
	WR1_MAX_ADDR,
	WR1_LENGTH,
	WR1_LOAD,
	WR1_CLK,
	WR1_FULL,
	WR1_USE,
	
	//	FIFO Write Side 2
	WR2_DATA,
	WR2,
	WR2_ADDR,
	WR2_MAX_ADDR,
	WR2_LENGTH,
	WR2_LOAD,
	WR2_CLK,
	WR2_FULL,
	WR2_USE,

    //  FIFO Write Side 3
    WR3_DATA,
    WR3,
    WR3_ADDR,
    WR3_MAX_ADDR,
    WR3_LENGTH,
    WR3_LOAD,
    WR3_CLK,
    WR3_FULL,
    WR3_USE,    

	//	FIFO Read Side 1
	RD1_DATA,
	RD1,
	RD1_ADDR,
	RD1_MAX_ADDR,
	RD1_LENGTH,
	RD1_LOAD,	
	RD1_CLK,

	//	FIFO Read Side 2
	RD2_DATA,
	RD2,
	RD2_ADDR,
	RD2_MAX_ADDR,
	RD2_LENGTH,
	RD2_LOAD,
	RD2_CLK,

    //  FIFO Read Side 3
    RD3_DATA,
    RD3,
    RD3_ADDR,
    RD3_MAX_ADDR,
    RD3_LENGTH,
    RD3_LOAD,
    RD3_CLK,

    //avalon_mm_master
    avl_address,
    avl_byteenable_n,
    avl_chipselect,
    avl_writedata,
    avl_read_n,
    avl_write_n,
    avl_readdata,
    avl_readdatavalid,
    avl_waitrequest
	
);

`define ASIZE           	24      	//  total address width of the SDRAM			
`define	DSIEZE_IN			16			//	data width of the CMOS 
`define	DSIEZE_SDRAM	    16			//	data width of the SDRAM IP 

//	HOST Side
input                       CLK;                    //System Clock
input                       RESET_N;                    //System Reset

//  FIFO Write Side 1
input   [`DSIEZE_IN-1:0]    WR1_DATA;                   //Data input
input                       WR1;                        //Write Request
input   [`ASIZE-1:0]        WR1_ADDR;                   //Write start address
input   [`ASIZE-1:0]        WR1_MAX_ADDR;               //Write max address
input   [8:0]               WR1_LENGTH;                 //Write length
input                       WR1_LOAD;                   //Write register load & fifo clear
input                       WR1_CLK;                    //Write fifo clock
output                      WR1_FULL;                   //Write fifo full
output  [`ASIZE-1:0]        WR1_USE;                    //Write fifo usedw
//  FIFO Write Side 2
input   [`DSIEZE_IN-1:0]    WR2_DATA;                  
input                       WR2;                                
input   [`ASIZE-1:0]        WR2_ADDR;                    
input   [`ASIZE-1:0]        WR2_MAX_ADDR;                   
input   [8:0]               WR2_LENGTH;                     
input                       WR2_LOAD;                      
input                       WR2_CLK;                     
output                      WR2_FULL;                      
output  [`ASIZE-1:0]        WR2_USE;
//  FIFO Write Side 3
input   [`DSIEZE_IN-1:0]    WR3_DATA;                  
input                       WR3;                                
input   [`ASIZE-1:0]        WR3_ADDR;                    
input   [`ASIZE-1:0]        WR3_MAX_ADDR;                   
input   [8:0]               WR3_LENGTH;                     
input                       WR3_LOAD;                      
input                       WR3_CLK;                     
output                      WR3_FULL;                      
output  [`ASIZE-1:0]        WR3_USE;                         
//  FIFO Read Side 1
output  [`DSIEZE_IN-1:0]    RD1_DATA;                   //Data output
input                       RD1;                        //Read Request
input   [`ASIZE-1:0]        RD1_ADDR;                   //Read start address
input   [`ASIZE-1:0]        RD1_MAX_ADDR;               //Read max address
input   [8:0]               RD1_LENGTH;                 //Read length
input                       RD1_LOAD;                   //Read register load & fifo clear
input                       RD1_CLK;                    //Read fifo clock
//  FIFO Read Side 2
output  [`DSIEZE_IN-1:0]    RD2_DATA;                  
input                       RD2;                               
input   [`ASIZE-1:0]        RD2_ADDR;                      
input   [`ASIZE-1:0]        RD2_MAX_ADDR;                 
input   [8:0]               RD2_LENGTH;                     
input                       RD2_LOAD;                      
input                       RD2_CLK; 
//  FIFO Read Side 3
output  [`DSIEZE_IN-1:0]    RD3_DATA;                  
input                       RD3;                               
input   [`ASIZE-1:0]        RD3_ADDR;                      
input   [`ASIZE-1:0]        RD3_MAX_ADDR;                 
input   [8:0]               RD3_LENGTH;                     
input                       RD3_LOAD;                      
input                       RD3_CLK;                         

//avalon_mm_master
output reg  [`ASIZE-1:0]        avl_address;
output      [1:0]               avl_byteenable_n;
output                          avl_chipselect;
output reg  [`DSIEZE_IN-1:0]    avl_writedata;
output reg                      avl_read_n;
output reg                      avl_write_n;
input       [`DSIEZE_IN-1:0]    avl_readdata;
input                           avl_readdatavalid;
input                           avl_waitrequest;

//  Internal Registers/Wires
//  Controller
reg [`ASIZE-1:0]            rWR1_ADDR;                      //Register write address                
reg [`ASIZE-1:0]            rWR1_MAX_ADDR;                  //Register max write address                
reg [8:0]                   rWR1_LENGTH;                    //Register write length
reg [`ASIZE-1:0]            rWR2_ADDR;                      //Register write address                
reg [`ASIZE-1:0]            rWR2_MAX_ADDR;                  //Register max write address                
reg [8:0]                   rWR2_LENGTH;                    //Register write length
reg [`ASIZE-1:0]            rWR3_ADDR;                      //Register write address                
reg [`ASIZE-1:0]            rWR3_MAX_ADDR;                  //Register max write address                
reg [8:0]                   rWR3_LENGTH;                    //Register write length

reg [`ASIZE-1:0]            rRD1_ADDR;                      //Register read address
reg [`ASIZE-1:0]            rRD1_MAX_ADDR;                  //Register max read address
reg [8:0]                   rRD1_LENGTH;                    //Register read length
reg [`ASIZE-1:0]            rRD2_ADDR;                      //Register read address
reg [`ASIZE-1:0]            rRD2_MAX_ADDR;                  //Register max read address
reg [8:0]                   rRD2_LENGTH;                    //Register read length
reg [`ASIZE-1:0]            rRD3_ADDR;                      //Register read address
reg [`ASIZE-1:0]            rRD3_MAX_ADDR;                  //Register max read address
reg [8:0]                   rRD3_LENGTH;                    //Register read length

reg [`ASIZE-1:0]            mADDR;                          //Internal address
reg [`ASIZE-1:0]            mLENGTH;                        //Internal length
reg [2:0]                   WR_MASK;                        //Write port active mask
reg [2:0]                   RD_MASK;                        //Read port active mask
reg                         mWR_DONE;                       //Flag write done, 1 pulse SDR_CLK
reg                         mRD_DONE;                       //Flag read done, 1 pulse SDR_CLK
reg                         mWR;                            //Internal WR edge capture
reg                         mRD;                            //Internal RD edge capture

wire    [`DSIEZE_SDRAM-1:0] WR_DATA1;                       //Controller Data input 1
wire    [`DSIEZE_SDRAM-1:0] WR_DATA2;                       //Controller Data input 2
wire    [`DSIEZE_SDRAM-1:0] WR_DATA3;                       //Controller Data input 2

//  FIFO Control
wire    [`ASIZE-1:0]        write_side_fifo_rusedw1;
wire    [`ASIZE-1:0]        read_side_fifo_wusedw1;
wire    [`ASIZE-1:0]        write_side_fifo_rusedw2;
wire    [`ASIZE-1:0]        read_side_fifo_wusedw2;
wire    [`ASIZE-1:0]        write_side_fifo_rusedw3;
wire    [`ASIZE-1:0]        read_side_fifo_wusedw3;



assign  avl_byteenable_n = 2'b00;
assign  avl_chipselect = 1'b1;

reg		WR_FIFO_EN;

WR_FIFO 	WR_FIFO_inst1
(
    .data    (WR1_DATA),
    .wrreq   (WR1),
    .wrclk   (WR1_CLK),
    .aclr    ((!RESET_N) || WR1_LOAD),
    .rdreq   (WR_FIFO_EN & WR_MASK[0] & (!avl_waitrequest)),
    .rdclk   (CLK),
    .q       (WR_DATA1),
    .wrfull  (WR1_FULL),
    .wrusedw (WR1_USE),
    .rdusedw (write_side_fifo_rusedw1)
);

WR_FIFO 	WR_FIFO_inst2
(
    .data    (WR2_DATA),
    .wrreq   (WR2),
    .wrclk   (WR2_CLK),
    .aclr    ((!RESET_N) || WR2_LOAD),
    .rdreq   (WR_FIFO_EN & WR_MASK[1] & (!avl_waitrequest)),
    .rdclk   (CLK),
    .q       (WR_DATA2),
    .wrfull  (WR2_FULL),
    .wrusedw (WR2_USE),
    .rdusedw (write_side_fifo_rusedw2)
);

WR_FIFO     WR_FIFO_inst3
(
    .data    (WR3_DATA),
    .wrreq   (WR3),
    .wrclk   (WR3_CLK),
    .aclr    ((!RESET_N) || WR3_LOAD),
    .rdreq   (WR_FIFO_EN & WR_MASK[2] & (!avl_waitrequest)),
    .rdclk   (CLK),
    .q       (WR_DATA3),
    .wrfull  (WR3_FULL),
    .wrusedw (WR3_USE),
    .rdusedw (write_side_fifo_rusedw3)
);

RD_FIFO 	RD_FIFO_inst1
(
    .data    (avl_readdata),
    .wrreq   (avl_readdatavalid & RD_MASK[0]),
    .wrclk   (CLK),
    .aclr    ((!RESET_N) || RD1_LOAD),
    .rdreq   (RD1),
    .rdclk   (RD1_CLK),
    .q       (RD1_DATA),
    .wrusedw (read_side_fifo_wusedw1)
);
				
RD_FIFO 	RD_FIFO_inst2
(
    .data    (avl_readdata),
    .wrreq   (avl_readdatavalid & RD_MASK[1]),
    .wrclk   (CLK),
    .aclr    ((!RESET_N) || RD2_LOAD),
    .rdreq   (RD2),
    .rdclk   (RD2_CLK),
    .q       (RD2_DATA),
    .wrusedw (read_side_fifo_wusedw2)
);

RD_FIFO     RD_FIFO_inst3
(
    .data    (avl_readdata),
    .wrreq   (avl_readdatavalid & RD_MASK[2]),
    .wrclk   (CLK),
    .aclr    ((!RESET_N) || RD3_LOAD),
    .rdreq   (RD3),
    .rdclk   (RD3_CLK),
    .q       (RD3_DATA),
    .wrusedw (read_side_fifo_wusedw3)
);

// reg	[9:0]		Write_NUM;
reg	[9:0]		Read_NUM;			

reg	[3:0]		WR_Step;
reg	[3:0]		RD_Step;

reg	[7:0]		WR_Time;
reg	[7:0]		RD_Time;

reg WAIT;

always@(posedge CLK or negedge RESET_N)
begin
    if(RESET_N == 1'b0)
    begin
        mWR_DONE      <= 0;
        mRD_DONE      <= 0;

        avl_write_n   <= 1;
        avl_read_n    <= 1;  
        avl_address   <= 0;

        // Write_NUM     <= 0;
        WR_FIFO_EN    <= 0;
        Read_NUM      <= 0;
        
        WR_Step       <= 0;
        RD_Step       <= 0;   

        WAIT <= 0;      
    end
	else
	begin
        case(WR_MASK)
            3'b001:
                avl_writedata <= avl_waitrequest ? avl_writedata : WR_DATA1; 
            3'b010: 
                avl_writedata <= avl_waitrequest ? avl_writedata : WR_DATA2;
            3'b100: 
                avl_writedata <= avl_waitrequest ? avl_writedata : WR_DATA3;              
            default:
                avl_writedata <= 0;
		endcase

        if(mWR == 1'b1) begin
            case(WR_Step)
                4'd0: begin
                    WR_FIFO_EN <= 1; 
                    WR_Step  <= 4'd1; 
                end
                4'd1: begin //q杈撳嚭
                    if(avl_waitrequest == 1'b0) begin
                        avl_write_n <= 0; 
                        avl_address <= mADDR; 
                        WR_Step  <= 4'd2; 
                    end  
                end                     
                4'd2: begin //avl_writedata绋冲畾
                    if(avl_waitrequest == 1'b0) begin                        
                        if(avl_address < mADDR + mLENGTH - 1) begin
                            avl_write_n <= 0; 
                            avl_address <= avl_address + 1;   
                            if(avl_address == mADDR + mLENGTH - 2) begin
                                WR_FIFO_EN <= 0; 
                            end
                            else begin
                                WR_FIFO_EN <= 1; 
                            end
                        end
                        else begin
                            avl_write_n <= 1; 
                            avl_address <= 0; 
                            WR_Step  <= 4'd3;
                            mWR_DONE <= 1;                               
                        end
                    end
                end 
                4'd3: begin
                    WR_Step  <= 4'd0;
                    mWR_DONE <= 0;  
                end                        
                default: begin
                    WR_Step  <= 4'd0;   
                end
            endcase 
        end
        else begin
            mWR_DONE <= 0; 
            avl_write_n <= 1; 
            // Write_NUM <= 0;  
            WR_FIFO_EN <= 0; 
            WR_Step <= 4'd0; 
        end

		if(mRD == 1'b1)
		begin
			case(RD_Step)
				4'd0: begin 
                    avl_address <= mADDR; 
                    RD_Step     <= 4'd1;                    		
				end                         
                4'd1: begin
                    if(WAIT == 1'b0) begin
                        avl_read_n <= 0;
                        if(avl_waitrequest == 1'b0 && avl_read_n == 1'b0) begin
                            if(avl_address < mADDR + mLENGTH - 1) begin
                                avl_address <= avl_address + 1;     
                            end
                            else begin 
                                avl_address <= 0;
                                avl_read_n <= 1;
                                WAIT <= 1'b1;                                 
                            end
                        end
                    end
                    if(avl_readdatavalid == 1'b1) begin
                        Read_NUM <= Read_NUM + 1;
                        if(Read_NUM == mLENGTH - 1) begin
                            mRD_DONE <= 1;
                            RD_Step  <= 4'd2;     
                        end
                        else begin
                            mRD_DONE <= 0;
                            RD_Step  <= 4'd1;
                        end
                    end
                end
				4'd2: begin
                    Read_NUM    <= 0;
                    WAIT        <= 1'b0;
                    mRD_DONE <= 0; 
                    RD_Step     <= 4'd0;                     		
				end                        
				default: begin
					RD_Step <= 4'd0;	
                end
			endcase		
		end
		else
		begin
            avl_read_n  <= 1; 
            Read_NUM    <= 0;
            RD_Step     <= 4'd0;
            mRD_DONE    <= 0;  
            WAIT        <= 1'b0;	
		end
	end
end
	
//	Internal Address & Length Control
reg rd_flag1,rd_flag2,rd_flag3;
always@(posedge CLK or negedge RESET_N)
begin
	if(RESET_N == 1'b0)
	begin
		rWR1_ADDR		<=	WR1_ADDR;
		rWR1_MAX_ADDR	<=	WR1_MAX_ADDR;
        rWR1_LENGTH     <=  WR1_LENGTH;
		rWR2_ADDR		<=	WR2_ADDR;
		rWR2_MAX_ADDR	<=	WR2_MAX_ADDR;
        rWR2_LENGTH     <=  WR2_LENGTH;
        rWR3_ADDR       <=  WR3_ADDR;
        rWR3_MAX_ADDR   <=  WR3_MAX_ADDR;
        rWR3_LENGTH     <=  WR3_LENGTH; 

		rRD1_ADDR		<=	RD1_ADDR;
		rRD1_MAX_ADDR	<=	RD1_MAX_ADDR;
        rRD1_LENGTH     <=  RD1_LENGTH;
		rRD2_ADDR		<=	RD2_ADDR;
		rRD2_MAX_ADDR	<=	RD2_MAX_ADDR;
		rRD2_LENGTH		<=	RD2_LENGTH;
        rRD3_ADDR       <=  RD3_ADDR;
        rRD3_MAX_ADDR   <=  RD3_MAX_ADDR;
        rRD3_LENGTH     <=  RD3_LENGTH;  

        rd_flag1            <= 1'b0;
        rd_flag2            <= 1'b0;
        rd_flag3            <= 1'b0;
	end
	else
	begin
		//	Write Side 1
		if(WR1_LOAD)
		begin
			rWR1_ADDR	<=	WR1_ADDR;
            rWR1_MAX_ADDR   <=  WR1_MAX_ADDR;
			rWR1_LENGTH	<=	WR1_LENGTH;
		end
		else if(mWR_DONE&WR_MASK[0])
		begin
			if(rWR1_ADDR<rWR1_MAX_ADDR-rWR1_LENGTH)
			rWR1_ADDR	<=	rWR1_ADDR + rWR1_LENGTH;
			else
			rWR1_ADDR	<=	WR1_ADDR;
		end
		//	Write Side 2
		if(WR2_LOAD)
		begin
			rWR2_ADDR	<=	WR2_ADDR;
            rWR2_MAX_ADDR   <=  WR2_MAX_ADDR;
			rWR2_LENGTH	<=	WR2_LENGTH;
		end
		else if(mWR_DONE&WR_MASK[1])
		begin
			if(rWR2_ADDR<rWR2_MAX_ADDR-rWR2_LENGTH)
			rWR2_ADDR	<=	rWR2_ADDR+rWR2_LENGTH;
			else
			rWR2_ADDR	<=	WR2_ADDR;
		end
        //  Write Side 2
        if(WR3_LOAD)
        begin
            rWR3_ADDR   <=  WR3_ADDR;
            rWR3_MAX_ADDR   <=  WR3_MAX_ADDR;
            rWR3_LENGTH <=  WR3_LENGTH;
        end
        else if(mWR_DONE&WR_MASK[2])
        begin
            if(rWR3_ADDR<rWR3_MAX_ADDR-rWR3_LENGTH)
                rWR3_ADDR   <=  rWR3_ADDR+rWR3_LENGTH;
            else
                rWR3_ADDR   <=  WR3_ADDR;
        end

		//	Read Side 1
		if(RD1_LOAD)
		begin
			rRD1_ADDR	<=	RD1_ADDR;
            rRD1_MAX_ADDR   <=  RD1_MAX_ADDR;
			rRD1_LENGTH	<=	RD1_LENGTH;
            rd_flag1        <= 1'b1;
		end
		else if(mRD_DONE&RD_MASK[0])
		begin
			if(rRD1_ADDR<rRD1_MAX_ADDR-rRD1_LENGTH) begin
			    rRD1_ADDR	<=	rRD1_ADDR+rRD1_LENGTH;
                rd_flag1        <= rd_flag1;
            end
			else begin
			    rRD1_ADDR	<=	RD1_ADDR;
                rd_flag1        <= 1'b0;
            end
		end
		//	Read Side 2
		if(RD2_LOAD)
		begin
			rRD2_ADDR	<=	RD2_ADDR;
            rRD2_MAX_ADDR   <=  RD2_MAX_ADDR;
			rRD2_LENGTH	<=	RD2_LENGTH;
            rd_flag2        <= 1'b1;
		end
		else if(mRD_DONE&RD_MASK[1])
		begin
			if(rRD2_ADDR<rRD2_MAX_ADDR-rRD2_LENGTH) begin
			    rRD2_ADDR	<=	rRD2_ADDR+rRD2_LENGTH;
                rd_flag2        <= rd_flag2;
            end
			else begin
			    rRD2_ADDR	<=	RD2_ADDR;
                rd_flag2        <= 1'b0;
            end
		end
        //  Read Side 3
        if(RD3_LOAD)
        begin
            rRD3_ADDR   <=  RD3_ADDR;
            rRD3_MAX_ADDR   <=  RD3_MAX_ADDR;
            rRD3_LENGTH <=  RD3_LENGTH;
            rd_flag3        <= 1'b1;
        end
        else if(mRD_DONE&RD_MASK[2])
        begin
            if(rRD3_ADDR<rRD3_MAX_ADDR-rRD3_LENGTH) begin
                rRD3_ADDR   <=  rRD3_ADDR+rRD3_LENGTH;
                rd_flag3        <= rd_flag3;
            end
            else begin
                rRD3_ADDR   <=  RD3_ADDR;
                rd_flag3        <= 1'b0;
            end
        end
	end
end

//****************Global controller**************************//
always@(posedge CLK or negedge RESET_N)
begin
	if(RESET_N == 1'b0)
	begin
		mWR		<=	0;
		mRD		<=	0;
		mADDR	<=	0;
		mLENGTH	<=	0;
		WR_MASK	<=	3'b00;
		RD_MASK	<=	3'b00;
	end
	else
	begin
		if( (mWR==0) && (mRD==0) &&
			(WR_MASK==3'b0)	&&	(RD_MASK==3'b0) &&
			(WR1_LOAD==1'b0)	&&	(RD1_LOAD==1'b0) &&
			(WR2_LOAD==1'b0)	&&	(RD2_LOAD==1'b0) &&
            (WR3_LOAD==1'b0)    &&  (RD3_LOAD==1'b0))
		begin
        //  Read Side 1
            if((read_side_fifo_wusedw1 < rRD1_LENGTH) && (rd_flag1 == 1'b1))
            begin
                mADDR   <=  rRD1_ADDR;
                mLENGTH <=  rRD1_LENGTH;
                WR_MASK <=  3'b000;
                RD_MASK <=  3'b001;
                mWR     <=  0;
                mRD     <=  1;              
            end
            //  Read Side 2
            else if((read_side_fifo_wusedw2 < rRD2_LENGTH) && (rd_flag2 == 1'b1))
            begin
                mADDR   <=  rRD2_ADDR;
                mLENGTH <=  rRD2_LENGTH;
                WR_MASK <=  3'b000;
                RD_MASK <=  3'b010;
                mWR     <=  0;
                mRD     <=  1;
            end 
            //  Read Side 3
            else if((read_side_fifo_wusedw3 < rRD3_LENGTH) && (rd_flag3 == 1'b1))
            begin
                mADDR   <=  rRD3_ADDR;
                mLENGTH <=  rRD3_LENGTH;
                WR_MASK <=  3'b000;
                RD_MASK <=  3'b100;
                mWR     <=  0;
                mRD     <=  1;
            end		
		//	Write Side 1
			else if( (write_side_fifo_rusedw1 >= rWR1_LENGTH) && (rWR1_LENGTH!=0) )
			begin
				mADDR	<=	rWR1_ADDR;
				mLENGTH	<=	rWR1_LENGTH;
				WR_MASK	<=	3'b001;
				RD_MASK	<=	3'b000;
				mWR		<=	1;
				mRD		<=	0;
			end
			//	Write Side 2
			else if( (write_side_fifo_rusedw2 >= rWR2_LENGTH) && (rWR2_LENGTH!=0) )
			begin
				mADDR	<=	rWR2_ADDR;
				mLENGTH	<=	rWR2_LENGTH;
				WR_MASK	<=	3'b010;
				RD_MASK	<=	3'b000;
				mWR		<=	1;
				mRD		<=	0;
			end
            //  Write Side 2
            else if( (write_side_fifo_rusedw3 >= rWR3_LENGTH) && (rWR3_LENGTH!=0) )
            begin
                mADDR   <=  rWR3_ADDR;
                mLENGTH <=  rWR3_LENGTH;
                WR_MASK <=  3'b100;
                RD_MASK <=  3'b000;
                mWR     <=  1;
                mRD     <=  0;
            end
		end
        
		if(mWR_DONE)
		begin
			WR_MASK	<=	0;
			mWR		<=	0;
		end
		if(mRD_DONE)
		begin
			RD_MASK	<=	0;
			mRD		<=	0;
		end
	end
end

endmodule
