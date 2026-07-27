`timescale 1ns / 1ps

module uart_rx (
    input clk,                    // 100 MHz clock
    input reset,                  // Asynchronous reset
    input rx,                     // Serial input (UART RX line)
    output reg [7:0] data_out,    // 8-bit data received
    output reg data_valid         // Signal when data is ready
);

    // UART Parameters
    parameter CLK_FREQ = 100_000_000;  // 100 MHz
    parameter BAUD_RATE = 9600;        // 9600 bps
    parameter CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;  // 10417 cycles

    // FSM States
    parameter IDLE = 2'b00;
    parameter START_BIT = 2'b01;
    parameter DATA_BITS = 2'b10;
    parameter STOP_BIT = 2'b11;

    // Synchronization (debounce RX input)
    reg rx_sync1, rx_sync2, rx_r1, rx_r2;

    // State Machine
    reg [1:0] state, next_state;
    reg [13:0] baud_counter;
    reg [3:0] bit_index;
    reg [7:0] data_buffer;

    // Synchronize RX input (2-stage synchronizer for metastability)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
            rx_r1 <= 1'b1;
            rx_r2 <= 1'b1;
        end
        else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
            rx_r1 <= rx_sync2;
            rx_r2 <= rx_r1;
        end
    end

    // Detect falling edge (start bit)
    wire start_bit_detected = rx_r2 && !rx_r1;

    // State Machine - Transition Logic
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Combinational Logic for Next State
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:
                if (start_bit_detected)
                    next_state = START_BIT;

            START_BIT:
                if (baud_counter == CYCLES_PER_BIT - 1)
                    next_state = DATA_BITS;

            DATA_BITS:
                if ((baud_counter == CYCLES_PER_BIT - 1) && (bit_index == 7))
                    next_state = STOP_BIT;

            STOP_BIT:
                if (baud_counter == CYCLES_PER_BIT - 1)
                    next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    // Baud Counter Logic
    always @(posedge clk or negedge reset) begin
        if (!reset)
            baud_counter <= 0;
        else if (state == IDLE)
            baud_counter <= 0;
        else
            if (baud_counter == CYCLES_PER_BIT - 1)
                baud_counter <= 0;
            else
                baud_counter <= baud_counter + 1;
    end

    // Bit Index Logic
    always @(posedge clk or negedge reset) begin
        if (!reset)
            bit_index <= 0;
        else if (state == IDLE)
            bit_index <= 0;
        else if ((state == DATA_BITS) && (baud_counter == CYCLES_PER_BIT - 1))
            bit_index <= bit_index + 1;
    end

    // Data Capture and Valid Signal
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            data_out <= 8'b0;
            data_buffer <= 8'b0;
            data_valid <= 1'b0;
        end
        else begin
            data_valid <= 1'b0;

            // Sample data bits at middle of bit period
            if ((state == DATA_BITS) && (baud_counter == CYCLES_PER_BIT / 2))
                data_buffer[bit_index] <= rx_r2;

            // Latch data when stop bit is received
            if ((state == STOP_BIT) && (baud_counter == CYCLES_PER_BIT / 2)) begin
                data_out <= data_buffer;
                data_valid <= 1'b1;
            end
        end
    end

endmodule