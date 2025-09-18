/*
 * serializer_gamtemate_10_to_1_generic_ddr.v
 *
 * Copyright (C) 2022  Gwenhael Goavec-Merou <gwenhael.goavec-merou@trabucayre.com>
 * SPDX-License-Identifier: MIT
 */

module serializer (
	input  wire       ref_clk_i,  // reference clock
	input  wire       fast_clk_i, // must be ref_clk frequency x (n / 2)
	input  wire       rst,
	input  wire [9:0] dat_i,
	output wire       dat_o
);

	/* detect ref_clk_i edge */
	reg ref_clk_i_d, ref_clk_i_s;
	reg ref_clk_i_edge;

	always @(posedge ref_clk_i)
		ref_clk_i_s <= (rst) ? 1'b0 : !ref_clk_i_s;

	always @(posedge fast_clk_i) begin
		ref_clk_i_d <= ref_clk_i_s;
		ref_clk_i_edge <= ref_clk_i_d ^ ref_clk_i_s;
	end

	reg [9:0] dat_pos;

	always @(posedge fast_clk_i) begin
		if (ref_clk_i_edge)
			dat_pos <= dat_i;
		else
			dat_pos <= {2'b0, dat_pos[9:2]};
	end

	/* FF associated to D0 in CC_ODDR is updated on the CLK rising edge
	 * but D1 is updated on the CLK falling edge.
	 * This mean D0 keep dat_pos[0] value before current rising edge
	 * and D1 keep dat_pos[1] after current rising edge since dat_pos is
	 * updated at the same time.
	 * https://www.colognechip.com/docs/ug1001-gatemate1-primitives-library-latest.pdf
	 * This introduces a corruption
	 * By adding a CC_DFF to latch dat_pos[1] the result is the same as
	 * Xilinx SAME_EDGE
	 */
	wire d1_d;
	CC_DFF #(
		.CLK_INV(0), .EN_INV(0), .SR_INV(0), .SR_VAL(0),
	) cc_dff_d1 (.CLK(fast_clk_i), .EN(1'b1), .SR(1'b0),
		.D(dat_pos[1]), .Q(d1_d)
	);

	CC_ODDR #(
		.CLK_INV(1'b0)
	) ddr_inst (.CLK(fast_clk_i), .DDR(fast_clk_i),
		// when _p/_n must be swapped this must be done BEFORE
		// CC_ODDR
`ifdef PN_SWAP
		.D0(~dat_pos[0]), .D1(~d1_d),
`else
		.D0(dat_pos[0]), .D1(d1_d),
`endif
		.Q(dat_o)
	);

endmodule
