`timescale 1ns / 1ps
// Module: spi_sync
// Description: 2-stage flip-flop synchronizer for asynchronous SPI inputs
//              (sclk, mosi, cs_n) crossing into the system clock domain
module spi_sync (
    input  wire clk,
    input  wire rst_n,
    input  wire sclk_in,
    input  wire mosi_in,
    input  wire cs_n_in,
    output reg  sclk_sync,
    output reg  mosi_sync,
    output reg  cs_n_sync
  );

  reg sclk_s1, mosi_s1, cs_n_s1;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      sclk_s1   <= 1'b0;
      sclk_sync <= 1'b0;
      mosi_s1   <= 1'b0;
      mosi_sync <= 1'b0;
      cs_n_s1   <= 1'b1;
      cs_n_sync <= 1'b1;
    end
    else
    begin
      sclk_s1   <= sclk_in;
      sclk_sync <= sclk_s1;
      mosi_s1   <= mosi_in;
      mosi_sync <= mosi_s1;
      cs_n_s1   <= cs_n_in;
      cs_n_sync <= cs_n_s1;
    end
  end

endmodule
