
// $4000 / $4004	DDLC VVVV	Duty (D), envelope loop / length counter halt (L), constant volume (C), volume/envelope (V)
// $4001 / $4005	EPPP NSSS	Sweep unit: enabled (E), period (P), negate (N), shift (S)
// $4002 / $4006	TTTT TTTT	Timer low (T)
// $4003 / $4007	LLLL LTTT	Length counter load (L), timer high (T)

module moduleName #(
   parameter channel_id = 0
) (
   input [7:0] D,
   input [5:0] reg_addr,
   input reg_wr,

   input clk,

);

localparam chan_offset = channel_id * 4;

reg [1:0] duty_reg;
reg envlen_halt_reg;
reg use_const_volume_reg; // 1 = const volume, 0 = use envelope
reg [3:0] vol_env_reg;
reg sweep_en_reg;
reg [2:0] sweep_period_reg;
reg sweep_negate_reg;
reg [2:0] sweep_shift_reg;
reg [10:0] timer_reg;
reg [4:0] len_counter_load_reg;

wire [3:0] volume;
reg [3:0] env_gen_out;
reg [3:0] env_counter;

assign volume = use_const_volume_reg ? vol_env_reg : env_gen_out;

// TODO detect write to enveloppe and reset reg
always @(posedge clk) begin
   if(env_counter == 4'b0) begin
      if(env_gen_out == 4'h0) begin
         if(envlen_halt_reg) begin
            env_gen_out <= 4'hF;
         end
      end else begin
         env_gen_out <= env_gen_out - 1;
      end

      env_counter <= vol_env_reg;
   end else begin
      env_counter <= env_counter - 1;
   end
end

// sweep unit
wire [10:0] sweep_timer_output;
reg [3:0] sweep_timer;

assign sweep_timer_output = ((timer >> sweep_shift_reg) ^ {11'b{sweep_negate_reg}}) + sweep_timer;

reg [10:0] timer;
reg timer_overflow;
wire [10:0] timer_reload;

assign timer_reload_value = sweep_en_reg ? sweep_timer_output : timer_reg;

always @(posedge clk) begin
   if(timer == 0) begin
      timer <= timer_reload_value + 1;
      timer_overflow <= 1'b1;
   end else begin
      timer_overflow <= 1'b0;
      timer <= timer + 1;
   end
end

   
endmodule