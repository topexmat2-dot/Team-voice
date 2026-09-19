`timescale 1ns / 1ps
// Module: spi_frontend
// Description: Bundles the clock-domain synchronizer (spi_sync) and the SPI
//              slave controller core (spi_controller).
module spi_frontend (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sclk,
    input  wire        mosi,
    input  wire        cs_n,
    output wire        rx_valid,
    output wire [15:0] rx_data,
    input  wire [7:0]  tx_data,
    output wire        miso
  );

  wire sclk_s;
  wire mosi_s;
  wire cs_n_s;

  // Synchronizer for external SPI lines
  spi_sync u_sync (
             .clk       (clk),
             .rst_n     (rst_n),
             .sclk_in   (sclk),
             .mosi_in   (mosi),
             .cs_n_in   (cs_n),
             .sclk_sync (sclk_s),
             .mosi_sync (mosi_s),
             .cs_n_sync (cs_n_s)
           );

  // SPI controller logic
  spi_controller u_core (
                   .clk       (clk),
                   .rst_n     (rst_n),
                   .sclk_sync (sclk_s),
                   .mosi_sync (mosi_s),
                   .cs_n_sync (cs_n_s),
                   .tx_data   (tx_data),
                   .rx_valid  (rx_valid),
                   .rx_data   (rx_data),
                   .miso      (miso)
                 );

endmodule
