`timescale 1ns / 1ps

module testbench;

  // Inputs to top module
  reg clk;
  reg rst_n;
  reg sclk;
  reg mosi;
  reg cs_n;

  // Outputs from top module
  wire miso;
  wire rx_valid_out;
  wire [15:0] rx_data_out;

  // Instantiate the Top Integration Module
  top_integration uut (
                    .clk(clk),
                    .rst_n(rst_n),
                    .sclk(sclk),
                    .mosi(mosi),
                    .cs_n(cs_n),
                    .miso(miso),
                    .rx_valid_out(rx_valid_out),
                    .rx_data_out(rx_data_out)
                  );

  // 1. Generate System Clock (e.g., 50 MHz -> 20ns period)
  always #10 clk = ~clk;

  // 2. SPI Bit-Bang Task to send a 16-bit word
  task spi_send_word(input [15:0] data);
    integer i;
    begin
      @(posedge clk);
      cs_n = 1'b0; // Assert Chip Select
      #40;

      for (i = 15; i >= 0; i = i - 1)
      begin
        mosi = data[i];
        sclk = 1'b0;
        #20;
        sclk = 1'b1;
        #20; // Rising edge samples MOSI in your controller
      end

      sclk = 1'b0;
      #40;
      cs_n = 1'b1; // Deassert Chip Select
      #100;
    end
  endtask

  // 3. Test Stimulus Sequence
  initial
  begin
    $display(">>> TESTBENCH STARTED SUCCESSFULLY <<<");

    // Initialize signals
    clk = 0;
    rst_n = 0;
    sclk = 0;
    mosi = 0;
    cs_n = 1;

    // Apply Reset
    #50;
    rst_n = 1;
    #100;

    // Test 1: Send Configuration Data (rx_data[0] = 0, so it transitions IDLE -> CONFIG -> ACTIVE)
    $display("--- Starting Transaction 1: Normal Config & Active ---");
    spi_send_word(16'hA5A0); // Last bit [0] is 0 (No error)

    // Test 2: Send Data that triggers an Error (rx_data[0] = 1)
    $display("--- Starting Transaction 2: Triggering Error State ---");
    spi_send_word(16'h1231); // Last bit [0] is 1 (Triggers ERROR -> IDLE)

    // Wait and finish simulation
    #200;
    $finish;
  end

  // Dump waveforms for viewing in GTKWave
  initial
  begin
    $dumpfile("simulation_waves.vcd");
    $dumpvars(0, testbench);
  end

endmodule
