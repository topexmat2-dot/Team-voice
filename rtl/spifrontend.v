rtl/spi_frontend_hierarchica

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
         rx_valid <= 1'b0;
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
           if (cs_n_prev && !cs_n_sync)
           begin
             tx_shift_reg <= tx_data;
             miso         <= tx_data[7];
           end

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

           if (sclk_fall)
           begin
             tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
             miso         <= tx_shift_reg[7];
           end
         end
       end
     end
   endmodule

   module spi_frontend (
       input  wire        clk,
       input  wire        rst_n,
       input  wire        sclk,
       input  wire        mosi,
       input  wire        cs_n,
       output wire        rx_valid,
       output wire [15:0] rx_data,
       input  wire [7:0]  tx_data,
       output wire        miso
     );
     wire sclk_s, mosi_s, cs_n_s;

     spi_sync u_sync (
                .clk(clk), .rst_n(rst_n),
                .sclk_in(sclk), .mosi_in(mosi), .cs_n_in(cs_n),
                .sclk_sync(sclk_s), .mosi_sync(mosi_s), .cs_n_sync(cs_n_s)
              );

     spi_controller u_core (
                      .clk(clk), .rst_n(rst_n),
                      .sclk_sync(sclk_s), .mosi_sync(mosi_s), .cs_n_sync(cs_n_s),
                      .tx_data(tx_data), .rx_valid(rx_valid), .rx_data(rx_data), .miso(miso)
                    );
   endmodule
