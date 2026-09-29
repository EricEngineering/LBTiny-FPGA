`timescale 1ns/1ps

module shadow_reg_tb ();
    reg [7:0] data_8bit;
    reg [11:0] data_12bit;
    reg CLK, RESET_n, backup, restore, latch_en;
    wire [7:0] out_8bit;
    wire [11:0] out_12bit;

    shadow_reg #(.W(8), .DEFAULT(0)) sr_8bit(
        .data(data_8bit),
        .CLK(CLK),
        .RESET_n(RESET_n),
        .backup(backup),
        .restore(restore),
        .latch_en(latch_en),
        .register(out_8bit)
    );

    shadow_reg #(.W(12), .DEFAULT(12'hF00)) sr_12bit(   // Use 0xF00 as default to test default value (like stack pointer register)
        .data(data_12bit),
        .CLK(CLK),
        .RESET_n(RESET_n),
        .backup(backup),
        .restore(restore),
        .latch_en(latch_en),
        .register(out_12bit)
    );

    always #5 CLK = ~CLK;

    task check_reg8bit;
        input [7:0] read;
        input [7:0] expected;
        input [7:0] data_in;
        input latch_en;
        input backup;
        input restore;
        begin
            if(read === expected) begin
                $display("Check passed");
            end
            else begin
                $display("8 bit register FAIL:    GOT: 0x%h    EXPECTED: 0x%h    DATA IN: 0x%h    LATCH ENABLE: %b    BACKUP: %b    RESTORE: %b",
                read, expected, data_in, latch_en, backup, restore);
                $finish;
            end
        end
    endtask

    task check_reg12bit;
        input [11:0] read;
        input [11:0] expected;
        input [11:0] data_in;
        input latch_en;
        input backup;
        input restore;
        begin
            if(read === expected) begin
                $display("Check passed");
            end
            else begin
                $display("12 bit register FAIL:    GOT: 0x%h    EXPECTED: 0x%h    DATA IN: 0x%h    LATCH ENABLE: %b    BACKUP: %b    RESTORE: %b",
                read, expected, data_in, latch_en, backup, restore);
                $finish;
            end
        end
    endtask

    initial begin
        
        // Establish initial values
        data_8bit = 8'h00;
        data_12bit = 12'h000;
        latch_en = 1'b0;
        backup = 1'b0;
        restore = 1'b0;

        // RESET SEQUENCE
        CLK = 1'b0;
        RESET_n = 1'b1;
        #5;
        RESET_n = 1'b0;
        #5;
        RESET_n = 1'b1;
        #10
    
        // Verify that everything is reset to 0
        check_reg8bit(out_8bit, 8'h00, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'hF00, data_12bit, latch_en, backup, restore);

        // Different data than output but no latch enable (no change)
        data_8bit = 8'hAA;
        data_12bit = 12'hAAA;
        latch_en = 1'b0;
        backup = 1'b0;
        restore = 1'b0;
        #10;
        check_reg8bit(out_8bit, 8'h00, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'hF00, data_12bit, latch_en, backup, restore);

        // Latch input with backup (register = data_in, shadow register = data_in)
        latch_en = 1'b1;
        backup = 1'b1;
        restore = 1'b0;
        #10;
        check_reg8bit(out_8bit, 8'hAA, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'hAAA, data_12bit, latch_en, backup, restore);
        
        // Latch input with no backup (register = data_in, shadow register = previous data_in)
        data_8bit = 8'h55;
        data_12bit = 12'h555;
        latch_en = 1'b1;
        backup = 1'b0;
        restore = 1'b0;
        #10;
        check_reg8bit(out_8bit, 8'h55, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'h555, data_12bit, latch_en, backup, restore);

        // No latch, no backup, no restore (nothing changes)
        latch_en = 1'b0;
        #10;
        check_reg8bit(out_8bit, 8'h55, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'h555, data_12bit, latch_en, backup, restore);

        // Restore (register = shadow register)
        data_8bit = 8'hFF;
        data_12bit = 12'hFFF;
        restore = 1'b1;
        #10;
        check_reg8bit(out_8bit, 8'hAA, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'hAAA, data_12bit, latch_en, backup, restore);


        // Edge case: latch_en and restore high (latch takes priority over restoration)
        latch_en = 1'b1;
        restore = 1'b1;
        #10;
        check_reg8bit(out_8bit, 8'hFF, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'hFFF, data_12bit, latch_en, backup, restore);

        // Edge case: backup and restore high (nothing changes)
        latch_en = 1'b0;
        backup = 1'b1;
        #10;
        check_reg8bit(out_8bit, 8'hFF, data_8bit, latch_en, backup, restore);
        check_reg12bit(out_12bit, 12'hFFF, data_12bit, latch_en, backup, restore);

        $display("All tests passed!");
        $finish;
    end
endmodule