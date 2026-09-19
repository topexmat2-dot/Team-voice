`timescale 1ns / 1ps
// Module: top_integration
// Description: Top-level integration module connecting the SPI frontend
module top_integration (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sclk,
    input  wire        mosi,
    input  wire        cs_n,
    output wire        miso,
    output wire        rx_valid_out,
    output wire [15:0] rx_data_out
  );

  // Interconnect wire from FSM status byte to SPI MISO transmitter
  wire [7:0] tx_data_from_fsm;

  // SPI Frontend instance
  spi_frontend u_spi_frontend (
                 .clk      (clk),
                 .rst_n    (rst_n),
                 .sclk     (sclk),
                 .mosi     (mosi),
                 .cs_n     (cs_n),
                 .rx_valid (rx_valid_out),
                 .rx_data  (rx_data_out),
                 .tx_data  (tx_data_from_fsm),
                 .miso     (miso)
               );

  // FSM Core instance
  fsm_core u_fsm_core (
             .clk      (clk),
             .rst_n    (rst_n),
             .rx_valid (rx_valid_out),
             .rx_data  (rx_data_out),
             .tx_data  (tx_data_from_fsm)
           );

endmodule
