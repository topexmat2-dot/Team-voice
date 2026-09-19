`timescale 1ns / 1ps
// Module: spi_controller
// Description: SPI slave controller (Mode 0: CPOL=0, CPHA=0, MSB first).
//              Receives 16-bit words on MOSI and transmits 8-bit status on MISO.
module spi_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sclk_sync,
    input  wire        mosi_sync,
    input  wire        cs_n_sync,
    input  wire [7:0]  tx_data,
    output reg         rx_valid,
    output reg  [15:0] rx_data,
    output reg         miso
  );

  reg sclk_d;
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      sclk_d <= 1'b0;
    else
      sclk_d <= sclk_sync;
  end
  wire sclk_rise = sclk_sync && !sclk_d;
  wire sclk_fall = !sclk_sync && sclk_d;

  reg [4:0]  bit_cnt;
  reg [15:0] shift_reg;
  reg [7:0]  tx_shift_reg;
  reg        cs_n_prev;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      bit_cnt      <= 5'd0;
      shift_reg    <= 16'd0;
      tx_shift_reg <= 8'd0;
      rx_valid     <= 1'b0;
      rx_data      <= 16'd0;
      miso         <= 1'b0;
      cs_n_prev    <= 1'b1;
    end
    else
    begin
      rx_valid  <= 1'b0;
      cs_n_prev <= cs_n_sync;

      if (cs_n_sync)
      begin
        bit_cnt      <= 5'd0;
        shift_reg    <= 16'd0;
        tx_shift_reg <= tx_data;
        miso         <= 1'b0;
      end
      else
      begin
        // Falling edge of CS_N: load status byte and present MSB immediately
        if (cs_n_prev && !cs_n_sync)
        begin
          tx_shift_reg <= tx_data;
          miso         <= tx_data[7];
        end

        // SCLK rising edge: sample incoming MOSI bit
        if (sclk_rise)
        begin
          shift_reg <= {shift_reg[14:0], mosi_sync};
          if (bit_cnt == 5'd15)
          begin
            rx_data  <= {shift_reg[14:0], mosi_sync};
            rx_valid <= 1'b1;
            bit_cnt  <= 5'd0;
          end
          else
          begin
            bit_cnt <= bit_cnt + 5'd1;
          end
        end

        // SCLK falling edge: shift next MISO bit out (transmits bits 7..0 correctly)
        if (sclk_fall)
        begin
          tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
          miso         <= tx_shift_reg[6];
        end
      end
    end
  end

endmodule
