`timescale 1ns / 1ps

module uart_tb ();

    // Clock and Reset
    reg clk;
    reg reset;

    // TX Test Signals
    reg [7:0] tx_data;
    reg tx_send;
    wire tx;
    wire tx_busy;

    // RX Test Signals
    wire rx;
    wire [7:0] rx_data;
    wire rx_valid;

    // Assign rx input to tx output (loopback for testing)
    assign rx = tx;

    // Instantiate UART Top Module
    uart_top uart_inst (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_send(tx_send),
        .tx(tx),
        .tx_busy(tx_busy),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns period = 100 MHz
    end

    // Reset Generation
    initial begin
        reset = 0;
        #100 reset = 1;  // Assert reset for 100 ns
    end

    // Test Stimulus
    initial begin
        // Initialize signals
        tx_data = 8'b0;
        tx_send = 0;

        // Wait for reset
        wait(reset == 1);
        #1000;  // Wait 1 microsecond

        // Test 1: Send 0xA5 (10100101)
        $display("Test 1: Transmitting 0xA5");
        tx_data = 8'hA5;
        tx_send = 1;
        #10 tx_send = 0;  // Pulse send for one clock cycle

        // Wait for transmission complete
        wait(tx_busy == 0);
        $display("Test 1 Complete: tx_busy deasserted");
        #100000;  // Wait 100 microseconds

        // Test 2: Send 0x55 (01010101)
        $display("Test 2: Transmitting 0x55");
        tx_data = 8'h55;
        tx_send = 1;
        #10 tx_send = 0;

        wait(tx_busy == 0);
        $display("Test 2 Complete: tx_busy deasserted");
        #100000;

        // Test 3: Send 0xFF (11111111)
        $display("Test 3: Transmitting 0xFF");
        tx_data = 8'hFF;
        tx_send = 1;
        #10 tx_send = 0;

        wait(tx_busy == 0);
        $display("Test 3 Complete: tx_busy deasserted");
        #100000;

        // Test 4: Send 0x00 (00000000)
        $display("Test 4: Transmitting 0x00");
        tx_data = 8'h00;
        tx_send = 1;
        #10 tx_send = 0;

        wait(tx_busy == 0);
        $display("Test 4 Complete: tx_busy deasserted");
        #100000;

        // End simulation
        $display("All tests complete");
        $finish;
    end

    // Monitor RX data
    always @(posedge rx_valid) begin
        $display("RX Valid: Received 0x%02X at time %t", rx_data, $time);
    end

endmodule