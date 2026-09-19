`timescale 1ns / 1ps

module fsm_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_valid,
    input  wire [15:0] rx_data,
    output reg  [7:0]  tx_data
  );

  typedef enum logic [1:0] {
            IDLE   = 2'b00,
            CONFIG = 2'b01,
            ACTIVE = 2'b10,
            ERROR  = 2'b11
          } state_t;

  state_t state, next_state;
  reg [15:0] config_threshold;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state            <= IDLE;
      config_threshold <= 16'd0;
    end
    else
    begin
      state <= next_state;
      if (state == IDLE && rx_valid)
      begin
        config_threshold <= rx_data;
      end
    end
  end

  always_comb
  begin
    next_state = state;
    tx_data    = 8'h11;

    case (state)
      IDLE:
      begin
        tx_data = 8'h11;
        if (rx_valid)
        begin
          next_state = CONFIG;
        end
        else
        begin
          next_state = IDLE;
        end
      end

      CONFIG:
      begin
        tx_data    = 8'h22;
        next_state = ACTIVE;
      end

      ACTIVE:
      begin
        tx_data = 8'h33;
        if (rx_valid && rx_data[0])
        begin
          next_state = ERROR;
        end
        else
        begin
          next_state = ACTIVE;
        end
      end

      ERROR:
      begin
        tx_data    = 8'hEE;
        next_state = IDLE;
      end

      default:
      begin
        tx_data    = 8'h11;
        next_state = IDLE;
      end
    endcase
  end

endmodule
