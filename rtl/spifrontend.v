// Description: SPI receiver/transmitter (Mode 0) for command and configuration data.
module spi_frontend (
    input  wire        clk,
    input  wire        rst_n,
    // SPI Physical Interface
    input  wire        sclk,
    input  wire        mosi,
    input  wire        cs_n,
    // Internal Interface to FSM/Core
    output reg         rx_valid,
    output reg  [15:0] rx_data,
    input  wire [7:0]  tx_data,
    output reg         miso
);

    // Synchronize SPI inputs to the internal clock domain.
    reg sclk_sync1, sclk_sync2;
    reg cs_n_sync1, cs_n_sync2;
    reg mosi_sync1, mosi_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync1 <= 1'b0; sclk_sync2 <= 1'b0;
            cs_n_sync1 <= 1'b1; cs_n_sync2 <= 1'b1;
            mosi_sync1 <= 1'b0; mosi_sync2 <= 1'b0;
        end else begin
            sclk_sync1 <= sclk;
            sclk_sync2 <= sclk_sync1;
            cs_n_sync1 <= cs_n;
            cs_n_sync2 <= cs_n_sync1;
            mosi_sync1 <= mosi;
            mosi_sync2 <= mosi_sync1;
        end
    end

    // SPI Mode 0 edge detection:
    //   CPOL = 0, CPHA = 0 => sample MOSI on rising edge, drive MISO on falling edge.
    reg sclk_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_d <= 1'b0;
        else
            sclk_d <= sclk_sync2;
    end
    wire sclk_rise = sclk_sync2 && !sclk_d;
    wire sclk_fall = !sclk_sync2 && sclk_d;

    reg [4:0] bit_cnt;
    reg [15:0] shift_reg;
    reg [7:0] tx_shift_reg;
    reg cs_n_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt       <= 5'd0;
            shift_reg     <= 16'd0;
            tx_shift_reg  <= 8'd0;
            rx_valid      <= 1'b0;
            rx_data       <= 16'd0;
            miso          <= 1'b0;
            cs_n_prev     <= 1'b1;
        end else begin
            rx_valid <= 1'b0;

            // Track the previous chip-select state to detect a new transaction.
            cs_n_prev <= cs_n_sync2;

            if (cs_n_sync2) begin
                // Idle / transaction boundary: reset the RX path and preload TX.
                bit_cnt      <= 5'd0;
                shift_reg    <= 16'd0;
                tx_shift_reg <= tx_data;
                miso         <= 1'b0;
            end else begin
                // Start of a new SPI transaction: load the first TX bit.
                if (cs_n_prev && !cs_n_sync2) begin
                    tx_shift_reg <= tx_data;
                    miso         <= tx_data[7];
                end

                // Receive data on the rising edge (Mode 0).
                if (sclk_rise) begin
                    shift_reg <= {shift_reg[14:0], mosi_sync2};
                    if (bit_cnt == 5'd15) begin
                        rx_data  <= {shift_reg[14:0], mosi_sync2};
                        rx_valid <= 1'b1;
                        bit_cnt  <= 5'd0;
                    end else begin
                        bit_cnt <= bit_cnt + 5'd1;
                    end
                end

                // Drive MISO on the falling edge.
                if (sclk_fall) begin
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    miso         <= tx_shift_reg[7];
                end
            end
        end
    end

endmodule
