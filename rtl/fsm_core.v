module fsm_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_valid,
    input  wire [15:0] rx_data,
    output reg  [7:0]  tx_data
);

      // State Encoding matching the diagram flow
      parameter IDLE   = 2'b00;
      parameter CONFIG = 2'b01;
      parameter ACTIVE = 2'b10;
      parameter ERROR  = 2'b11;

      (* fsm_encoding = "binary" *)
      reg [1:0]  state, next_state;
      reg [15:0] config_threshold;

      // State Register with Asynchronous Reset (Error -> Idle reset path)
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          state            <= IDLE;
          config_threshold <= 16'd0;
        end else begin
          state <= next_state;
          // capture configuration data when moving into CONFIG so it's latched
          if (rx_valid && next_state == CONFIG) begin
            config_threshold <= rx_data;
          end
        end
      end

      // Next-State Combinational Logic (Matching diagram conditions)
      always @* begin
        next_state = state;
        case (state)
          // IDLE: Waits for rx_valid strobe to move to CONFIG
          IDLE: begin
            if (rx_valid) begin
              next_state = CONFIG;
            end
          end

          // CONFIG: Automatically transitions to ACTIVE on the next cycle
          CONFIG: begin
            next_state = ACTIVE;
          end

          // ACTIVE: Monitors rx_data[0]; goes to ERROR if triggered
          ACTIVE: begin
            if (rx_data[0]) begin
              next_state = ERROR;
            end
          end

          // ERROR: move back to IDLE (per diagram)
          ERROR: begin
            next_state = IDLE;
          end

          default: begin
            next_state = IDLE;
          end
        endcase
      end

      // Status Output Generation Logic (MISO status byte)
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          tx_data <= 8'h00;
        end else begin
          case (state)
            IDLE:    tx_data <= 8'h11;
            CONFIG:  tx_data <= 8'h22;
            ACTIVE:  tx_data <= 8'h33;
            ERROR:   tx_data <= 8'hEE;
            default: tx_data <= 8'h00;
          endcase
        end
      end

    endmodule
