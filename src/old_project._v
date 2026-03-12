/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_leonllrmc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire IN_240HZ = uio_in[7];
  wire IN_240HZ_BUF;
  wire CLK_240HZ;
  reg PREV_CLK_240HZ;

  wire [7:0] D = uio_in;

  always @(posedge clk) begin
    IN_240HZ_BUF <= IN_240HZ;
    PREV_CLK_240HZ <= IN_240HZ_BUF;
  end

  assign CLK_240HZ = IN_240HZ_BUF && ~PREV_CLK_240HZ; // rising edge


  wire [4:0] REG_ADDR = uio_in[4:0];
  wire REG_WR = uio_in[6:0];

  wire flag_seq_envtri;
  wire flag_seq_lensweep;
  frame_sequencer frameSequencer(
    .flag_seq_envtri(flag_seq_envtri),
    .flag_seq_lensweep(flag_seq_lensweep),
    .clk(clk), 
    .CLK_240HZ(CLK_240HZ),
    .reg_a(REG_ADDR),
    .reg_wr(REG_WR),
    .D(D)
  );

  // $4015   ---d nt21   length ctr enable: DMC, noise, triangle, pulse 2, 1
  reg DMC_enable;
  reg noise_enable;
  reg triangle_enable;
  reg [1:0] pulse_enable;

    always @(*) begin
        if(REG_ADDR == 5'h15 && REG_WR) begin
          pulse_enable <= D[1:0];
          triangle_enable <= D[2];
          noise_enable <= D[3];
          DMC_enable <= D[4];
        end else if(~rst_n) begin
          pulse_enable <= 2'b00;
          triangle_enable <= 1'b0;
          noise_enable <= 1'b0;
          DMC_enable <= 1'b0;
        end
    end





endmodule
