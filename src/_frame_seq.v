module frame_sequencer (
   output flag_seq_envtri,
   output flag_seq_lensweep,
   input clk, 
   input CLK_240HZ,
   input [4:0] reg_a,
   input reg_wr,
   input [7:0] D
);
     /*
  Frame Sequencer
  $4017 = mi-- ---- mode, IRQ disable

      f = set interrupt flag
      l = clock length counters and sweep units
      e = clock envelopes and triangle's linear counter

  mode 0: 4-step  effective rate (approx)
  ---------------------------------------
      - - - f      60 Hz
      - l - l     120 Hz
      e e e e     240 Hz
      0 1 2 3

  mode 1: 5-step  effective rate (approx)
  ---------------------------------------
      - - - - -   (interrupt flag never set)
      l - l - -    96 Hz
      e e e e -   192 Hz
      0 1 2 3 4

      max = 4 + flag

  */

  reg [2:0] frame_sequencer;
  reg frame_seq_mode;

  always @(posedge clk) begin
    if(CLK_240HZ) begin
      if(frame_sequencer >= (3'b011 + frame_seq_mode)) begin
        frame_sequencer <= 3'b000;
      end else begin
        frame_sequencer <= frame_sequencer + 1;
      end
    end
  end

  // flag to process envelope and tri lin counter
  assign flag_seq_envtri = (frame_sequencer[2] == 1'b0); // all except mode 1 frame 1

  // flag to process length counters and sweep units
  assign flag_seq_lensweep = flag_seq_envtri && (frame_sequencer[0] == ~frame_seq_mode); // all even except mode 1 frame 1

  always @(*) begin
      if(reg_a == 5'h17 && reg_wr) begin
         frame_seq_mode <= D[7];
      end
  end

endmodule