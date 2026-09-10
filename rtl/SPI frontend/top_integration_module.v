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

    // Instantiate SPI Frontend (Member 2 Module)
    spi_frontend u_spi_frontend (
        .clk      (clk),
        .rst_n    (rst_n),
        .sclk     (sclk),
        .mosi     (mosi),
        .cs_n     (cs_n),
        .rx_valid (u_rx_valid),
        .rx_data  (u_rx_data),
        .tx_data  (8'h00),
        .miso     (miso)
    );

    // Instantiate FSM Control and Configuration Core
    fsm_config_core u_fsm_config_core (
        .clk           (clk),
        .rst_n         (rst_n),
        .rx_valid      (u_rx_valid),
        .rx_data       (u_rx_data),
        .io_config_out (io_config_out)
    );

endmodule