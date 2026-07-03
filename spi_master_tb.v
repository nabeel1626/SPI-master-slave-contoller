`timescale 1ns / 1ps

module spi_master_tb();

    // Parameters
    parameter SPI_MODE          = 0;
    parameter CLKS_PER_HALF_BIT = 2;
    parameter CLK_PERIOD        = 10; // 10ns clock = 100MHz

    // Signals
    reg        i_Rst_L;
    reg        i_Clk;
    
    // TX (MOSI)
    reg  [7:0] i_TX_Byte;
    reg        i_TX_DV;
    wire       o_TX_Ready;
    
    // RX (MISO)
    wire       o_RX_DV;
    wire [7:0] o_RX_Byte;
    
    // SPI Interface
    wire       o_SPI_Clk;
    reg        i_SPI_MISO;
    wire       o_SPI_MOSI;

    // Instantiate SPI Master
    spi_master #(
        .SPI_MODE(SPI_MODE),
        .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
    ) uut (
        .i_Rst_L(i_Rst_L),
        .i_Clk(i_Clk),
        .i_TX_Byte(i_TX_Byte),
        .i_TX_DV(i_TX_DV),
        .o_TX_Ready(o_TX_Ready),
        .o_RX_DV(o_RX_DV),
        .o_RX_Byte(o_RX_Byte),
        .o_SPI_Clk(o_SPI_Clk),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_MOSI(o_SPI_MOSI)
    );

    // Clock generation
    always begin
        #(CLK_PERIOD/2) i_Clk = ~i_Clk;
    end

    // Test procedure
    initial begin
        // Initialize signals
        i_Clk       = 1'b0;
        i_Rst_L     = 1'b0;
        i_TX_Byte   = 8'h00;
        i_TX_DV     = 1'b0;
        i_SPI_MISO  = 1'b0;

        $dumpfile("spi_master_tb.vcd");
        $dumpvars(0, spi_master_tb);

        // Reset
        #(CLK_PERIOD * 5);
        i_Rst_L = 1'b1;
        #(CLK_PERIOD * 5);

        $display("===== Test 1: Send 8'hA5 (10100101) =====");
        send_byte(8'hA5, 8'h00);

        $display("\n===== Test 2: Send 8'h5A (01011010) with MISO response =====");
        send_byte(8'h5A, 8'hFF);

        $display("\n===== Test 3: Send 8'h55 (01010101) =====");
        send_byte(8'h55, 8'hAA);

        $display("\n===== Test 4: Sequential sends =====");
        send_byte(8'h11, 8'h00);
        #(CLK_PERIOD * 50);
        send_byte(8'h22, 8'h00);

        #(CLK_PERIOD * 200);
        $display("===== Simulation Complete =====");
        $finish;
    end

    // Task to send a byte and capture response
    task send_byte(input [7:0] tx_data, input [7:0] miso_data);
        integer i;
        begin
            // Wait for TX ready
            wait(o_TX_Ready);
            #(CLK_PERIOD);
            
            // Send byte
            i_TX_Byte = tx_data;
            i_TX_DV = 1'b1;
            #(CLK_PERIOD);
            i_TX_DV = 1'b0;
            
            $display("[%0t] Sending: 0x%02h", $time, tx_data);
            
            // Simulate MISO response bit-by-bit
            for (i = 7; i >= 0; i = i - 1) begin
                // Wait for SPI clock transitions
                wait(o_SPI_Clk == 1'b0);
                i_SPI_MISO = miso_data[i];
                #(CLK_PERIOD);
                wait(o_SPI_Clk == 1'b1);
                #(CLK_PERIOD);
            end
            
            // Wait for RX valid
            wait(o_RX_DV);
            #(CLK_PERIOD);
            $display("[%0t] Received: 0x%02h (Expected: 0x%02h) %s", 
                     $time, o_RX_Byte, miso_data, 
                     (o_RX_Byte == miso_data) ? "PASS" : "FAIL");
            
            // Wait for ready again
            wait(o_TX_Ready);
            #(CLK_PERIOD * 10);
        end
    endtask

    // Monitor outputs
    always @(posedge i_Clk) begin
        if (o_RX_DV) begin
            $display("[%0t] RX Valid: 0x%02h", $time, o_RX_Byte);
        end
    end

endmodule
