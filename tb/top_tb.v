`timescale 1ns / 1ps

module top_tb;
  // Testbench Signals
  reg         clk;
  reg         rst_n;
  reg         sclk;
  reg         mosi;
  reg         cs_n;
  wire        miso;
  wire        rx_valid_out;
  wire [15:0] rx_data_out;

  integer error_count = 0;
  integer test_step   = 0;


  // Device Under Test (DUT) Instantiation
  top_integration dut (
                    .clk          (clk),
                    .rst_n        (rst_n),
                    .sclk         (sclk),
                    .mosi         (mosi),
                    .cs_n         (cs_n),
                    .miso         (miso),
                    .rx_valid_out (rx_valid_out),
                    .rx_data_out  (rx_data_out)
                  );

  // System Clock: 50 MHz (Period = 20ns)

  initial
    clk = 0;
  always #10 clk = ~clk;

  // SPI Master Task (Mode 0: CPOL=0, CPHA=0, MSB first)
  // SCLK Period = 200ns (5 MHz)

  task spi_send_16bit (
      input  [15:0] tx_word,
      output [7:0]  rx_status
    );
    integer i;
    reg [7:0] captured_status;
    begin
      captured_status = 8'd0;
      sclk = 1'b0;
      mosi = 1'b0;
      cs_n = 1'b1;
      #100;

      // Assert Chip Select (Active Low)
      cs_n = 1'b0;
      #100; // Setup time before first SCLK rising edge

      for (i = 15; i >= 0; i = i - 1)
      begin
        // Drive MOSI bit
        mosi = tx_word[i];
        #100;

        // SCLK Rising Edge: Slave and Master sample
        sclk = 1'b1;

        // Capture MISO for the first 8 bits (status byte)
        if (i >= 8)
        begin
          captured_status[i - 8] = miso;
        end
        #100;

        // SCLK Falling Edge: Slave shifts out next bit
        sclk = 1'b0;
      end

      #100;
      // Deassert Chip Select
      cs_n = 1'b1;
      mosi = 1'b0;
      #200; // Hold time between transactions

      rx_status = captured_status;
    end
  endtask

  // State Name Formatter for Console Logs

  function [47:0] state_name;
    input [1:0] st;
    begin
      case (st)
        2'b00:
          state_name = "IDLE  ";
        2'b01:
          state_name = "CONFIG";
        2'b10:
          state_name = "ACTIVE";
        2'b11:
          state_name = "ERROR ";
        default:
          state_name = "UNKNOWN";
      endcase
    end
  endfunction

  // Monitor State Changes
  always @(dut.u_fsm_core.state)
  begin
    #1;
    $display("[TIME: %0t ns] [FSM STATE CHANGED] -> %s (2'b%b) | tx_data = 0x%02h",
             $time, state_name(dut.u_fsm_core.state), dut.u_fsm_core.state, dut.u_fsm_core.tx_data);
  end

  // Main Stimulus
  reg [7:0] read_status;

  initial
  begin
    $dumpfile("simulation.vcd");
    $dumpvars(0, top_tb);

    $display("=");
    $display("          STARTING SPI & FSM CORE TESTBENCH SIMULATION            ");
    $display("=");

    // Reset Sequence
    rst_n = 1'b0;
    sclk  = 1'b0;
    mosi  = 1'b0;
    cs_n  = 1'b1;
    #150;
    rst_n = 1'b1;
    #100;

    // STEP 1: Verify Initial State
    test_step = 1;
    $display("\n--- TEST STEP 1: Check Initial Reset State ---");
    if (dut.u_fsm_core.state !== 2'b00 || dut.u_fsm_core.tx_data !== 8'h11)
    begin
      $display("[FAIL] Expected IDLE (00) and tx_data=0x11, got %b, 0x%02h",
               dut.u_fsm_core.state, dut.u_fsm_core.tx_data);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] Initial state correctly in IDLE with status byte 0x11.");
    end

    // STEP 2: Send Config Word (0xA010, rx_data[0] = 0)
    test_step = 2;
    $display("\n--- TEST STEP 2: Send Configuration Packet (0xA010) ---");
    spi_send_16bit(16'hA010, read_status);

    if (read_status !== 8'h11)
    begin
      $display("[FAIL] MISO status byte mismatch: Expected 0x11 (IDLE), got 0x%02h", read_status);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] Received expected MISO status byte 0x11 (IDLE).");
    end

    #100;
    if (dut.rx_data_out !== 16'hA010)
    begin
      $display("[FAIL] rx_data_out mismatch: Expected 0xA010, got 0x%04h", dut.rx_data_out);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] rx_data_out correctly received 0xA010.");
    end

    if (dut.u_fsm_core.config_threshold !== 16'hA010)
    begin
      $display("[FAIL] config_threshold latch mismatch: Expected 0xA010, got 0x%04h", dut.u_fsm_core.config_threshold);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] config_threshold correctly latched 0xA010.");
    end

    if (dut.u_fsm_core.state !== 2'b10)
    begin
      $display("[FAIL] Expected FSM in ACTIVE (10), got %b", dut.u_fsm_core.state);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] FSM successfully transitioned to ACTIVE state (tx_data=0x%02h).", dut.u_fsm_core.tx_data);
    end

    // STEP 3: Send Normal Packet in ACTIVE (0x5544, rx_data[0] = 0)
    test_step = 3;
    $display("\n--- TEST STEP 3: Send Normal Packet in ACTIVE State (0x5544) ---");
    spi_send_16bit(16'h5544, read_status);

    if (read_status !== 8'h33)
    begin
      $display("[FAIL] MISO status mismatch: Expected 0x33 (ACTIVE), got 0x%02h", read_status);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] Received expected MISO status byte 0x33 (ACTIVE).");
    end

    #100;
    if (dut.u_fsm_core.state !== 2'b10)
    begin
      $display("[FAIL] FSM should remain in ACTIVE, but state is %b", dut.u_fsm_core.state);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] FSM correctly remained in ACTIVE state.");
    end

    // STEP 4: Trigger ERROR in ACTIVE (0xFF01, rx_data[0] = 1)
    test_step = 4;
    $display("\n--- TEST STEP 4: Send Error Packet with bit 0 set (0xFF01) ---");
    spi_send_16bit(16'hFF01, read_status);

    if (read_status !== 8'h33)
    begin
      $display("[FAIL] MISO status mismatch: Expected 0x33, got 0x%02h", read_status);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] Received MISO status byte 0x33 during transaction.");
    end

    #100;
    if (dut.u_fsm_core.state !== 2'b00)
    begin
      $display("[FAIL] FSM should return to IDLE after ERROR, but state is %b", dut.u_fsm_core.state);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] FSM transitioned through ERROR and returned to IDLE.");
    end

    // STEP 5: Confirm return to IDLE (0x1110)
    test_step = 5;
    $display("\n--- TEST STEP 5: Confirm FSM is back in IDLE ---");
    spi_send_16bit(16'h1110, read_status);

    if (read_status !== 8'h11)
    begin
      $display("[FAIL] MISO status mismatch: Expected 0x11 (IDLE), got 0x%02h", read_status);
      error_count = error_count + 1;
    end
    else
    begin
      $display("[PASS] Received expected MISO status byte 0x11 (IDLE). FSM recovered successfully!");
    end

    #200;
    $display("\n===================================================================");
    if (error_count == 0)
    begin
      $display("             ALL TESTS PASSED SUCCESSFULLY! (0 Errors)            ");
      $display(" Waveform file 'simulation.vcd' generated successfully.          ");
    end
    else
    begin
      $display("             TESTS COMPLETED WITH %0d ERROR(S).                  ", error_count);
    end
    $display("===================================================================\n");

    $finish;
  end

endmodule
