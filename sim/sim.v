// File: tb/tb_spi_top.v
`timescale 1ns / 1ps

module tb_spi_top;

  // Testbench signals
  reg clk;
  reg rst_n;
  reg sclk;
  reg mosi;
  reg cs_n;
  reg [7:0] tx_data_in;

  wire miso;
  wire rx_valid_out;
  wire [15:0] rx_data_out;

  // Instantiate the top integration module
  member1_top_integration u_top (
                            .clk(clk),
                            .rst_n(rst_n),
                            .sclk(sclk),
                            .mosi(mosi),
                            .cs_n(cs_n),
                            .miso(miso),
                            .tx_data_in(tx_data_in),
                            .rx_valid_out(rx_valid_out),
                            .rx_data_out(rx_data_out)
                          );

  // System clock generation (50 MHz -> 20ns period)
  always #10 clk = ~clk;

  // SPI SCLK generation (slower than system clock)
  always #100 sclk = ~sclk;

  initial
  begin
    // Initialize signals
    clk = 0;
    rst_n = 0;
    sclk = 0;
    mosi = 0;
    cs_n = 1;
    tx_data_in = 8'hA5;

    // Apply reset
    #50;
    rst_n = 1;
    #50;

    // Begin SPI Transaction (Mode 0)
    cs_n = 0;
    tx_data_in = 8'h3C; // Data to transmit on MISO

    // Drive 16 bits of incoming data on MOSI
    repeat (16)
    begin
      @(posedge sclk);
      mosi = $random;
    end

    // End transaction
    #200;
    cs_n = 1;

    #500;
    $finish;
  end

  // Monitor output results in console
  initial
  begin
    $monitor("Time=%0t ns | cs_n=%b sclk=%b mosi=%b miso=%b | rx_valid=%b rx_data=%h",
             $time, cs_n, sclk, mosi, miso, rx_valid_out, rx_data_out);
  end

endmodule
