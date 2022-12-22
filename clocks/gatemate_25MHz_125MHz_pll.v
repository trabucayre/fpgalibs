/*
 * gatemate_25MHz_125MHz_pll.v
 *
 * Copyright (C) 2022  Gwenhael Goavec-Merou <gwenhael.goavec-merou@trabucayre.com>
 * SPDX-License-Identifier: MIT
 */

module pll (
	input  wire clock_in,
	input  wire rst_in,
	output wire clock0_out,
	output reg  clock0_lock,
	output wire clock1_out,
	output reg  clock1_lock
);

wire clk270, clk180, clk90, clk0, usr_ref_out;
wire usr_pll_lock_stdy, usr_pll_lock;

wire pll_clk_nobuf;
CC_PLL #(
    .REF_CLK("10.0"),    // reference input in MHz
    .OUT_CLK("25.0"),    // pll output frequency in MHz
    //.PERF_MD("ECONOMY"), // LOWPOWER, ECONOMY, SPEED // uncomment to let p_r autodetect PERF_MD based on delay file
    .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
    .CI_FILTER_CONST(2), // optional CI filter constant
    .CP_FILTER_CONST(4)  // optional CP filter constant
) pll25 (
    .CLK_REF(clock_in), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
    .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
	.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clock0_out), .CLK_REF_OUT(usr_ref_out)
);
//CC_BUFG pll_bufg (.I(pll_clk_nobuf), .O(clock0_out)); // yosys automatically inserts bufg

// reset is synced the clock
reg locked_s1;
always @(posedge clock0_out) begin
	//locked_s1 <= usr_pll_lock;//_stdy; // requires -lockreq parameter in latest p_r
	locked_s1 <= ~rst_in;
	clock0_lock <= locked_s1;
end

wire usr_pll125_lock_stdy, usr_pll125_lock;
wire pll125_clk_nobuf;
CC_PLL #(
    .REF_CLK("10.0"),    // reference input in MHz
    .OUT_CLK("125.0"),   // pll output frequency in MHz
    //.PERF_MD("ECONOMY"), // LOWPOWER, ECONOMY, SPEED // uncomment to let p_r autodetect PERF_MD based on delay file
    .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
    .CI_FILTER_CONST(2), // optional CI filter constant
    .CP_FILTER_CONST(4)  // optional CP filter constant
) pll125 (
    .CLK_REF(clock_in), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(),
    .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll125_lock_stdy), .USR_PLL_LOCKED(usr_pll125_lock),
	.CLK270(), .CLK180(), .CLK90(), .CLK0(clock1_out), .CLK_REF_OUT()
);
//CC_BUFG pll125_bufg (.I(pll125_clk_nobuf), .O(clock1_out)); // yosys automatically inserts bufg

// reset is synced the clock
reg locked125_s1;
always @(posedge clock1_out) begin
	//locked125_s1 <= usr_pll125_lock;//_stdy; // requires -lockreq parameter in latest p_r
	locked125_s1 <= ~rst_in;
	clock1_lock <= locked125_s1;
end

endmodule
