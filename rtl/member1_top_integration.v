// File: rtl/member1_top_integration.v
module member1_top_integration (
    input  wire        clk,
    input  wire        rst_n,
    // External SPI Pins
    input  wire        sclk,
    input  wire        mosi,
    input  wire        cs_n,
    output wire        miso,
    // Core/FSM Application Interface
    input  wire [7:0]  tx_data_in,
    output wire        rx_valid_out,
    output wire [15:0] rx_data_out
);

    // Instantiate SPI Frontend
    spi_frontend u_spi_frontend (
        .clk      (clk),
        .rst_n    (rst_n),
        .sclk     (sclk),
        .mosi     (mosi),
        .cs_n     (cs_n),
        .rx_valid (rx_valid_out),
        .rx_data  (rx_data_out),
        .tx_data  (tx_data_in),
        .miso     (miso)
    );

endmodule
