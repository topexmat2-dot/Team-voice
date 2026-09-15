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
                 .tx_data  (tx_data_from_fsm),
                 .miso     (miso)
               );
  // wire connecting FSM-generated tx_data into the SPI frontend
  wire [7:0] tx_data_from_fsm;

  // Instantiate FSM core to produce tx_data and consume received data
  fsm_core u_fsm_core (
      .clk      (clk),
      .rst_n    (rst_n),
      .rx_valid (rx_valid_out),
      .rx_data  (rx_data_out),
      .tx_data  (tx_data_from_fsm)
  );

endmodule
