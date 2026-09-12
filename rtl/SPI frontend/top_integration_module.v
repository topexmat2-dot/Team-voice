// ============================================================================
// Module: top_integration (Member 1 Deliverable)
// Description: Top-level RTL wrapper connecting SPI frontend and FSM control block.
// ============================================================================
module top_integration (
	input  wire        clk,
	input  wire        rst_n,
	// SPI Interface
	input  wire        sclk,
	input  wire        mosi,
	input  wire        cs_n,
	output wire        miso,
	// Configuration Output to I/O pads
	output wire [7:0]  io_config_out
);

	wire        u_rx_valid;
	wire [15:0] u_rx_data;
	wire [7:0]  u_tx_data;

	// Tie-off default TX data and connect to SPI frontend.
	assign u_tx_data = 8'h00;

	// Instantiate SPI Frontend (Member 2 Module)
	spi_frontend u_spi_frontend (
		.clk      (clk),
		.rst_n    (rst_n),
		.sclk     (sclk),
		.mosi     (mosi),
		.cs_n     (cs_n),
		.rx_valid (u_rx_valid),
		.rx_data  (u_rx_data),
		.tx_data  (u_tx_data),
		.miso     (miso)
	);

	// Minimal FSM/control block to consume the SPI payload and update the output register.
	fsm_config_core u_fsm_config_core (
		.clk           (clk),
		.rst_n         (rst_n),
		.rx_valid      (u_rx_valid),
		.rx_data       (u_rx_data),
		.io_config_out (io_config_out)
	);

endmodule

module fsm_config_core (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        rx_valid,
	input  wire [15:0] rx_data,
	output reg  [7:0]  io_config_out
);

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			io_config_out <= 8'd0;
		else if (rx_valid)
			io_config_out <= rx_data[7:0];
	end

endmodule
