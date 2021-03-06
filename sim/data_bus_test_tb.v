`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////
//
// Author:        Ryan Clarke
//
// Create Date:   07/06/2017
// Module Name:   data_bus_test_tb
// Target Device: Mojo V3 (Spartan-6)  
//
// Description:   Verilog Test Fixture for module data_bus_test
//
// Dependencies:  data_bus_test
// 
////////////////////////////////////////////////////////////////////////////////

module data_bus_test_tb;
    
    
// INPUTS //////////////////////////////////////////////////////////////////////
    
    reg clk;
    reg rst;
    reg en;
    reg ready;
    reg [7:0] data2fpga;
    
    
// OUTPUTS /////////////////////////////////////////////////////////////////////
    
    wire mem;
    wire rw;
    wire [19:0] addr;
    wire [7:0] data2ram;
    wire done;
    wire result;
    
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
    
    // Clock period (ns)
    localparam T_clk = 20;
    
    // SRAM timing (ns)
    localparam T_wp = 8;    // write pulse width
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // SRAM register
    reg [7:0] sram;
    
    // SRAM controller register
    reg [7:0] sram_ctrl_data2ram;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
	data_bus_test uut
        (
        .clk(clk), 
        .rst(rst), 
        .en(en), 
        .mem(mem), 
        .rw(rw), 
        .ready(ready), 
        .addr(addr), 
        .data2ram(data2ram), 
        .data2fpga(data2fpga), 
        .done(done), 
        .result(result)
        );
    
    
// CLOCK ///////////////////////////////////////////////////////////////////////
    
    // 50 MHz master clock
    always
        begin
            clk = 1;
            #(T_clk / 2);
            
            clk = 0;
            #(T_clk / 2);
        end
    
    
// MAIN ////////////////////////////////////////////////////////////////////////
    
    initial
        begin
            initialize();
            enable();
            
            // wait until done goes high and then delay a cycle
            @(posedge done);
            @(posedge clk) $stop;
        end
    
    
// SRAM CONTROLLER SIMULATION //////////////////////////////////////////////////
    
    // 60 ns read/write cycle
    always
        begin
            // wait for command
            @(posedge mem);             // t = 0
            
            // SRAM control commands ready low after a clock cycle
            @(posedge clk) ready = 0;   // t = 20
            
            if(!rw)
                begin
                    // SRAM control registers input data during the first cycle
                    sram_ctrl_data2ram = data2ram;
                    
                    // WE goes low and SRAM writes after T_wp
                    @(posedge clk);     // t = 40
                    #(T_wp) sram = sram_ctrl_data2ram;
                    
                    // clean up the clock
                    @(posedge clk);     // t = 60
                end
            else
                begin
                    // read registered after two clock cycles
                    @(posedge clk);     // t = 40
                    @(posedge clk);     // t = 60
                    data2fpga = sram;
                end
            
            ready = 1;
        end
    
    
// TASKS ///////////////////////////////////////////////////////////////////////
    
    // initialization
    task initialize;
        begin
            rst = 0;
            en = 0;
            ready = 1;
            data2fpga = 0;
            sram_ctrl_data2ram = 0;
            
            reset_async();
        end
    endtask
    
    // asynchronous reset
    task reset_async;
        begin
            rst = 1;
            #(T_clk / 2) rst = 0;
        end
    endtask
    
    // enable test
    task enable;
        begin
            @(posedge clk) en = 1;
            @(posedge clk) en = 0;
        end
    endtask
    
endmodule
