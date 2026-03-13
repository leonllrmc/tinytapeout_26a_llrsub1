/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_leonllrmc(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire [2:0] reg_addr = ui_in[6:4];
  wire [3:0] reg_din = ui_in[3:0];
  wire reg_wr = ui_in[7];

  // Suppress unused signals warning
  wire _unused_ok = &{ena, uio_in};

  reg [15:0] counter_hsync;
  reg [11:0] counter_xin;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  

  wire [1:0] R_chan_out;
  wire [1:0] G_chan_out;
  wire [1:0] B_chan_out;

  assign R = video_active ? R_chan_out : 2'b00;
  assign G = video_active ? G_chan_out : 2'b00;
  assign B = video_active ? B_chan_out : 2'b00;
  
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      counter_xin <= 0;
    end else begin
      counter_xin <= counter_xin + 1;
    end
  end

    always @(posedge hsync, negedge rst_n) begin
    if (~rst_n) begin
      counter_hsync <= 0;
    end else begin
      counter_hsync <= counter_hsync + 1;
    end
  end

  // total reg count => 8 => 2 per chan + 2 global (4 bit each)
  // test for B (TODO: modify addr) => A = 0 => [x_sel, y_sel] (x/y) => - screen/2 or just coordinate
  // divider by 2

  /*
   REG table (TO MODIFY):
   $0 => ALU_SEL|XS|YS|D => S => sel (1 = substract half the size), D = (1=divide by 2)
   $1 => ALU_SEL|OP => ALU_SEL = (), OP=(0: a+b, 1:a-b, 2:b-a, 3: (a * b)>>factor, 4:sqrt(a^2 + b^2), 5: a>b, 6:a<b, 3: a(scaled), 6: b (scaled)))
   3 => const (adds the 3 bit value of reg 0 in the alu) => for ALU1 = const, for ALU2 = timer
   )
   $2, 3 => same as 2 orther but for second ALU
   Global => 1: timer, 2: ALU and timer stuff (concaneted) => the channel individual 2 ALU => into 1
   // => maybe 2 => add timer to X/Y of masked channel
  */

  wire [3:0] timer = (TIMER_SEL ? counter_hsync : counter_xin) >> (TIMER_DIV << TIMER_SEL);

  reg R_X_SEL_1;
  reg R_Y_SEL_1;
  reg R_DIV_1;  
  reg R_X_SEL_2;
  reg R_Y_SEL_2;
  reg R_DIV_2;
  reg [2:0] R_ALU1OP;
  reg [2:0] R_ALU2OP;
  reg G_X_SEL_1;
  reg G_Y_SEL_1;
  reg G_DIV_1;  
  reg G_X_SEL_2;
  reg G_Y_SEL_2;
  reg G_DIV_2;
  reg [2:0] G_ALU1OP;
  reg [2:0] G_ALU2OP;
  reg B_X_SEL_1;
  reg B_Y_SEL_1;
  reg B_DIV_1;  
  reg B_X_SEL_2;
  reg B_Y_SEL_2;
  reg B_DIV_2;
  reg [2:0] B_ALU1OP;
  reg [2:0] B_ALU2OP;

  reg [2:0] GLOBAL_ALUOP;

  reg [2:0] CHAN_TIMER_ADD_MSK;

  reg TIMER_SEL; // 0 => use hsync timer, 1 => use vsync timer
  reg [4:0] TIMER_DIV;




  always @(posedge reg_wr or negedge rst_n) begin
   if(~rst_n) begin
      R_X_SEL_2    <= 1'b0;
      R_Y_SEL_2    <= 1'b0;
      R_DIV_2      <= 1'b0;
      R_X_SEL_1    <= 1'b0;
      R_Y_SEL_1    <= 1'b0;
      R_DIV_1      <= 1'b0;
      R_ALU2OP     <= 3'h0;
      R_ALU1OP     <= 3'h0;
      G_X_SEL_2    <= 1'b0;
      G_Y_SEL_2    <= 1'b0;
      G_DIV_2      <= 1'b0;
      G_X_SEL_1    <= 1'b0;
      G_Y_SEL_1    <= 1'b0;
      G_DIV_1      <= 1'b0;
      G_ALU2OP     <= 3'h0;
      G_ALU1OP     <= 3'h0;
      B_X_SEL_2    <= 1'b0;
      B_Y_SEL_2    <= 1'b0;
      B_DIV_2      <= 1'b0;
      B_X_SEL_1    <= 1'b0;
      B_Y_SEL_1    <= 1'b0;
      B_DIV_1      <= 1'b0;
      B_ALU2OP     <= 3'h0;
      B_ALU1OP     <= 3'h0;
      TIMER_SEL    <= 1'b0;
      TIMER_DIV    <= 3'h0;
      GLOBAL_ALUOP <= 3'h0;
      CHAN_TIMER_ADD_MSK <= 3'h0;
   end else begin
      case (reg_addr)
         3'h0: begin
            if(reg_din[3]) begin
               R_X_SEL_2 <= reg_din[3];
               R_Y_SEL_2 <= reg_din[2];
               R_DIV_2 <= reg_din[0];
            end else begin   
               R_X_SEL_1 <= reg_din[3];
               R_Y_SEL_1 <= reg_din[2];
               R_DIV_1 <= reg_din[0];
            end
         end
         3'h1: begin
            if(reg_din[3]) begin
               R_ALU2OP <= reg_din[2:0];
            end else begin
               R_ALU1OP <= reg_din[2:0];
            end
         end
         3'h2: begin
            if(reg_din[3]) begin
               G_X_SEL_2 <= reg_din[3];
               G_Y_SEL_2 <= reg_din[2];
               G_DIV_2 <= reg_din[0];
            end else begin   
               G_X_SEL_1 <= reg_din[3];
               G_Y_SEL_1 <= reg_din[2];
               G_DIV_1 <= reg_din[0];
            end
         end
         3'h3: begin
            if(reg_din[3]) begin
               G_ALU2OP <= reg_din[2:0];
            end else begin
               G_ALU1OP <= reg_din[2:0];
            end
         end
         3'h4: begin
            if(reg_din[3]) begin
               B_X_SEL_2 <= reg_din[3];
               B_Y_SEL_2 <= reg_din[2];
               B_DIV_2 <= reg_din[0];
            end else begin   
               B_X_SEL_1 <= reg_din[3];
               B_Y_SEL_1 <= reg_din[2];
               B_DIV_1 <= reg_din[0];
            end
         end
         3'h5: begin
            if(reg_din[3]) begin
               B_ALU2OP <= reg_din[2:0];
            end else begin
               B_ALU1OP <= reg_din[2:0];
            end
         end
         //default: 
         3'h6: begin
            TIMER_SEL <= reg_din[3];
            TIMER_DIV <= reg_din[2:0];
            // timer might be a slight bit slow (at least when global add)
         end         
         3'h7: begin
            if(reg_din[3]) begin
               CHAN_TIMER_ADD_MSK <= reg_din[2:0];
            end else begin
               GLOBAL_ALUOP <= reg_din[2:0];
            end
         end
      endcase
   end
  end

  color_chan red_chan(
   .pix_x(pix_x),
   .pix_y(pix_y),
   .timer(timer),

   .X_SEL_1(R_X_SEL_1),
   .Y_SEL_1(R_Y_SEL_1),
   .X_SEL_2(R_X_SEL_1),
   .Y_SEL_2(R_Y_SEL_2),
   .DIV_1(R_DIV_1),
   .DIV_2(R_DIV_2),

   .ALU1OP(R_ALU1OP),
   .ALU2OP(R_ALU2OP),
   .GLOBAL_ALUOP(GLOBAL_ALUOP),

   .CHAN_TIMER_ADD_MSK(CHAN_TIMER_ADD_MSK),
   .CHAN_MSK(3'b100),
   
   .chan_val(R_chan_out)
);

color_chan green_chan(
   .pix_x(pix_x),
   .pix_y(pix_y),
   .timer(timer),

   .X_SEL_1(G_X_SEL_1),
   .Y_SEL_1(G_Y_SEL_1),
   .X_SEL_2(G_X_SEL_1),
   .Y_SEL_2(G_Y_SEL_2),
   .DIV_1(G_DIV_1),
   .DIV_2(G_DIV_2),

   .ALU1OP(G_ALU1OP),
   .ALU2OP(G_ALU2OP),
   .GLOBAL_ALUOP(GLOBAL_ALUOP),
   
   .CHAN_TIMER_ADD_MSK(CHAN_TIMER_ADD_MSK),
   .CHAN_MSK(3'b010),

   .chan_val(G_chan_out)
);

color_chan blue_chan(
   .pix_x(pix_x),
   .pix_y(pix_y),
   .timer(timer),

   .X_SEL_1(B_X_SEL_1),
   .Y_SEL_1(B_Y_SEL_1),
   .X_SEL_2(B_X_SEL_1),
   .Y_SEL_2(B_Y_SEL_2),
   .DIV_1(B_DIV_1),
   .DIV_2(B_DIV_2),

   .ALU1OP(B_ALU1OP),
   .ALU2OP(B_ALU2OP),
   .GLOBAL_ALUOP(GLOBAL_ALUOP),

   .CHAN_TIMER_ADD_MSK(CHAN_TIMER_ADD_MSK),
   .CHAN_MSK(3'b001),

   .chan_val(B_chan_out)
);

  // Suppress unused signals warning
  //wire _unused_ok_ = &{};

endmodule

module color_chan(
   input [9:0] pix_x,
   input [9:0] pix_y,
   input [3:0] timer,

   input X_SEL_1,
   input Y_SEL_1,
   input X_SEL_2,
   input Y_SEL_2,
   input DIV_1,
   input DIV_2,

   input [2:0] ALU1OP,
   input [2:0] ALU2OP,
   input [2:0] GLOBAL_ALUOP,

   input [2:0] CHAN_MSK,
   input [2:0] CHAN_TIMER_ADD_MSK,

   output [1:0] chan_val
);

   assign chan_val = alu_glob_out + ((CHAN_TIMER_ADD_MSK & CHAN_MSK) ? timer[1:0] : 0);

   localparam DISP_H_DIV2 = 640/2;
  localparam DISP_V_DIV2 = 480/2;

  wire [9:0] X_VAL_1 = ((X_SEL_1 ? pix_x : (pix_x - DISP_H_DIV2)) >> DIV_1);
  wire [9:0] Y_VAL_1 = ((Y_SEL_1 ? pix_y : (pix_y - DISP_V_DIV2)) >> DIV_1);
  wire [9:0] X_VAL_2 = ((X_SEL_2 ? pix_x : (pix_x - DISP_H_DIV2)) >> DIV_2);
  wire [9:0] Y_VAL_2 = ((Y_SEL_2 ? pix_y : (pix_y - DISP_V_DIV2)) >> DIV_2);

  wire [3:0] ALU_SUB1_RESULT1 = (X_VAL_1 - Y_VAL_1) >> 3;
  wire [3:0] ALU_SUB1_RESULT2 = (X_VAL_2 - Y_VAL_2) >> 3;
  wire [3:0] ALU_SUB2_RESULT1 = -ALU_SUB1_RESULT1;
  wire [3:0] ALU_SUB2_RESULT2 = -ALU_SUB1_RESULT2;
  
  wire [3:0] ALU_MUL_RESULT1 = (X_VAL_1[7:1] * Y_VAL_1[7:1]) >> 3;
  wire [3:0] ALU_MUL_RESULT2 = (X_VAL_2[7:1] * Y_VAL_2[7:1]) >> 3;
  wire [3:0] ALU_PSEUDOPYT_RESULT1 = (((X_VAL_1[7:1] * X_VAL_1[7:1]) >> 3) + ((Y_VAL_1[7:1] * Y_VAL_1[7:1]) >> 3));
  wire [3:0] ALU_PSEUDOPYT_RESULT2 = (((X_VAL_2[7:1] * X_VAL_2[7:1]) >> 3) + ((Y_VAL_2[7:1] * Y_VAL_2[7:1]) >> 3));

  wire [3:0] alu_1_out = (ALU1OP == 3'h0) ? (X_VAL_1 + Y_VAL_1) >> 3 : 
                      (ALU1OP == 3'h1) ? ALU_SUB1_RESULT1:
                      (ALU1OP == 3'h2) ? ALU_SUB2_RESULT1 :
                      (ALU1OP == 3'h3) ? ALU_MUL_RESULT1 :
                      (ALU1OP == 3'h4) ? ALU_PSEUDOPYT_RESULT1 :
                      (ALU1OP == 3'h5) ? X_VAL_1 >> 6 :
                      (ALU1OP == 3'h6) ? Y_VAL_1 >> 6 : {X_SEL_1, Y_SEL_2, DIV_2, 1'b0}; 


    // => could add "sub alu", controlled by 2nd channel X/Y SEL and div if timer is en
   wire [3:0] alu_2_out = (ALU2OP == 3'h0) ? (X_VAL_2 + Y_VAL_2) >> 3 : 
                      (ALU2OP == 3'h1) ? ALU_SUB1_RESULT2:
                      (ALU2OP == 3'h2) ? ALU_SUB2_RESULT2 :
                      (ALU2OP == 3'h3) ? ALU_MUL_RESULT2 :
                      (ALU2OP == 3'h4) ? ALU_PSEUDOPYT_RESULT2 :
                      (ALU2OP == 3'h5) ? X_VAL_2 >> 6 :
                     (ALU2OP == 3'h6) ? Y_VAL_2 >> 6 : timer; 
                     

   // to reduce usage, could combine ALU and only decouple selection
   // WARNING => was bad idea as X and Y have offset and div params => but could decouple them from interface

   // NOTE => could use global ALU second reg part to add timer to selected chan 

   wire [1:0] alu_glob_out = (GLOBAL_ALUOP == 3'h0) ? (alu_1_out + alu_2_out) >> 3 : 
                     (GLOBAL_ALUOP == 3'h1) ? (alu_1_out - alu_2_out) >> 3 :
                     (GLOBAL_ALUOP == 3'h2) ? (alu_2_out - alu_1_out) >> 3 :
                     (GLOBAL_ALUOP == 3'h3) ? (alu_1_out * alu_2_out) >> 3 :
                     (GLOBAL_ALUOP == 3'h4) ? ((alu_1_out * alu_1_out) >> 3) + ((alu_2_out * alu_2_out) >> 3) :
                     (GLOBAL_ALUOP == 3'h5) ? (alu_1_out ^ alu_2_out) >> 2 :
                     (GLOBAL_ALUOP == 3'h6) ? alu_1_out >> 2 : timer; 
  
endmodule