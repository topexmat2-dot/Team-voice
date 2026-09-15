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

  spi_frontend u_spi_frontend (
                 .clk      (clk),
                 .rst_n    (rst_n),
                 .sclk     (sclk),
                 .mosi     (mosi),
                 .cs_n     (cs_n),
                 .rx_valid (rx_valid_out),
                 .rx_data  (rx_data_out),
                 .miso     (miso)
               );

endmodule
