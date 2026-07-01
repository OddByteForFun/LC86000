const std = @import("std");
const testing = std.testing;
const Cpu = @import("lc86K").Cpu;
const step = @import("decode").step;

fn makeCpu(rom: []u8) Cpu {
    @memset(rom, 0);
    return Cpu.init(rom);
}

test "nop advances PC by 1" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x00; // nop
    try testing.expectEqual(@as(u16, 0), cpu.pc);
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 1), cpu.pc);
}

test "BR forward" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x01; // br
    rom[1] = 0x3f; // +63
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 0x41), cpu.pc);
}

test "BR backward" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    cpu.pc = 0x10;
    rom[0x10] = 0x01; // br
    rom[0x11] = 0xFE; // -2
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 0x10), cpu.pc);
}

test "BZ taken when ACC zero" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x80; // bz
    rom[1] = 0x05; // +5
    cpu.a = 0;
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 7), cpu.pc);
}

test "BZ not taken when ACC non-zero" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x80; // bz
    rom[1] = 0x05;
    cpu.a = 1;
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 2), cpu.pc);
}

test "BNZ taken when ACC non-zero" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x90; // bnz
    rom[1] = 0x05;
    cpu.a = 1;
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 7), cpu.pc);
}

test "BNZ not taken when ACC zero" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x90; // bnz
    rom[1] = 0x05;
    cpu.a = 0;
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 2), cpu.pc);
}

test "BN branches when memory bit clear" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    // BN d9=0x10, bit=0, r8=0x05
    // opcode 0x88 = row 8 col 8 → bn, mode .d9, bit=(opcode&7=0)
    rom[0] = 0x88; // BN with d9 bit0=0
    rom[1] = 0x10; // d9 byte → address = (0&1)<<8 | 0x10 = 0x10
    rom[2] = 0x05; // +5
    cpu.store8(0x10, 0x00); // bit 0 is 0 → branch taken
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 8), cpu.pc); // 3 + 5
}

test "BN not taken when memory bit set" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x88;
    rom[1] = 0x10;
    rom[2] = 0x05;
    cpu.store8(0x10, 0x01); // bit 0 is 1 → branch not taken
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 3), cpu.pc);
}

test "ADD immediate" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x81; // add #imm
    rom[1] = 42;
    try testing.expectEqual(@as(u8, 0), cpu.a);
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 2), cpu.pc);
    try testing.expectEqual(@as(u8, 42), cpu.a);
}

test "ADD immediate carry" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x81; // add #200
    rom[1] = 200;
    cpu.a = 200;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 144), cpu.a);
    try testing.expect(cpu.psw.cy);
}

test "ADD immediate overflow" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x81;
    rom[1] = 0x81;
    rom[2] = 0x81;
    rom[3] = 0x81;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x81), cpu.a);
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x02), cpu.a);
}

test "ADD immediate VMC-156" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x81; rom[1] = 0x13;
    rom[2] = 0x81; rom[3] = 0x0a;
    rom[4] = 0x81; rom[5] = 0x0f;
    rom[6] = 0x81; rom[7] = 0x80;
    cpu.a = 0x55;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x68), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x72), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x81), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x01), cpu.a);
}

test "ADDC immediate VMC-159" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x81; rom[1] = 0x13;
    rom[2] = 0x91; rom[3] = 0x0a;
    rom[4] = 0x91; rom[5] = 0x0f;
    rom[6] = 0x91; rom[7] = 0x80;
    rom[8] = 0x91; rom[9] = 0x01;
    cpu.a = 0x55;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x68), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x72), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x81), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x01), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x03), cpu.a);
}

test "SUB immediate VMC-160" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xA1; rom[1] = 0x13;
    rom[2] = 0xA1; rom[3] = 0x03;
    rom[4] = 0xA1; rom[5] = 0x3f;
    rom[6] = 0xA1; rom[7] = 0x02;
    cpu.a = 0x55;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x42), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x3f), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x00), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xfe), cpu.a);
}

test "SUBC indirect VMC-166" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xA1; rom[1] = 0x16;
    rom[2] = 0xB4; // SUBC @R0 (0xB4 = row 11 col 4, ri=0)
    rom[3] = 0xB4; // SUBC @R0
    cpu.a = 0x55;
    cpu.ram_bank0[0] = 0x68; // R0 via IRBK=0 at addr 0x00 → value 0x68
    cpu.ram_bank0[0x68] = 0x40;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x3f), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xff), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xbe), cpu.a);
}

test "AND immediate VMC-173" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xE1; rom[1] = 0xfa;
    rom[2] = 0xE1; rom[3] = 0xaf;
    rom[4] = 0xE1; rom[5] = 0x0f;
    rom[6] = 0xE1; rom[7] = 0xf0;
    cpu.a = 0xff;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xfa), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xaa), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x0a), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x00), cpu.a);
}

test "OR direct" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xD2; rom[1] = 0x23;
    rom[2] = 0xD2; rom[3] = 0x23;
    cpu.a = 0x00;
    cpu.ram_bank0[0x23] = 0x55;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x55), cpu.a);
    cpu.ram_bank0[0x23] = 0xAA;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xFF), cpu.a);
}

test "XOR immediate" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xF1; rom[1] = 0xFF;
    cpu.a = 0x55;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xAA), cpu.a);
}

test "ROL 0x01 → 0x02" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xE0;
    cpu.a = 0x01;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x02), cpu.a);
}

test "ROL wraps MSB to LSB" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xE0;
    cpu.a = 0x80;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x01), cpu.a);
}

test "ROL 8 times returns to original (0x55 ↔ 0xAA)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    @memset(&rom, 0xE0);
    cpu.a = 0x55;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xAA), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x55), cpu.a);
}

test "ROR 0x01 → 0x80" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xC0;
    cpu.a = 0x01;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x80), cpu.a);
}

test "ROR wraps LSB to MSB" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xC0;
    rom[1] = 0xC0;
    rom[2] = 0xC0;
    cpu.a = 0x01;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x80), cpu.a);
    cpu.a = 0x51;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0xA8), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x54), cpu.a);
}

test "ROLC through carry" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    @memset(&rom, 0xF0);
    cpu.a = 1;
    cpu.psw.cy = true;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b11), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b110), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b1100), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b11000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b110000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b1100000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b11000000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b10000000), cpu.a);
    try testing.expect(cpu.psw.cy);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 1), cpu.a);
    try testing.expect(cpu.psw.cy);
}

test "RORC through carry" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    @memset(&rom, 0xD0);
    cpu.a = 0x01;
    cpu.psw.cy = true;
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b10000000), cpu.a);
    try testing.expect(cpu.psw.cy);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b11000000), cpu.a);
    try testing.expect(!cpu.psw.cy);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b01100000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b00110000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b00011000), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b00001100), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b00000110), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b00000011), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0b00000001), cpu.a);
    try testing.expect(cpu.psw.cy);
}

test "MUL 0x1123 × 0x52 = 0x057D36" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x30;
    cpu.a = 0x11;
    cpu.c = 0x23;
    cpu.b = 0x52;
    try testing.expectEqual(@as(u8, 7), step(&cpu));
    try testing.expectEqual(@as(u8, 0x05), cpu.b);
    try testing.expectEqual(@as(u8, 0x7D), cpu.a);
    try testing.expectEqual(@as(u8, 0x36), cpu.c);
    try testing.expect(!cpu.psw.cy);
    try testing.expect(cpu.psw.ov);
}

test "MUL 0x0705 × 0x10 = 0x007050" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x30;
    cpu.a = 0x07;
    cpu.c = 0x05;
    cpu.b = 0x10;
    try testing.expectEqual(@as(u8, 7), step(&cpu));
    try testing.expectEqual(@as(u8, 0x00), cpu.b);
    try testing.expectEqual(@as(u8, 0x70), cpu.a);
    try testing.expectEqual(@as(u8, 0x50), cpu.c);
    try testing.expect(!cpu.psw.cy);
    try testing.expect(!cpu.psw.ov);
}

test "DIV 0x7905 ÷ 0x07 = 0x1149 rem 0x06" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x40;
    cpu.a = 0x79;
    cpu.c = 0x05;
    cpu.b = 0x07;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x06), cpu.b);
    try testing.expectEqual(@as(u8, 0x11), cpu.a);
    try testing.expectEqual(@as(u8, 0x49), cpu.c);
    try testing.expect(!cpu.psw.cy);
    try testing.expect(!cpu.psw.ov);
}

test "DIV by zero sets Ov and ACC=0xFF" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x40;
    cpu.a = 0x07;
    cpu.c = 0x10;
    cpu.b = 0x00;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0xFF), cpu.a);
    try testing.expectEqual(@as(u8, 0x10), cpu.c);
    try testing.expect(cpu.psw.ov);
    try testing.expect(!cpu.psw.cy);
}

test "INC direct memory" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x62; rom[1] = 0x7f;
    rom[2] = 0x62; rom[3] = 0x7f;
    rom[4] = 0x62; rom[5] = 0x7f;
    rom[6] = 0x62; rom[7] = 0x7f;
    cpu.ram_bank0[0x7f] = 0xFD;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0xFE), cpu.ram_bank0[0x7f]);
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0xFF), cpu.ram_bank0[0x7f]);
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x00), cpu.ram_bank0[0x7f]);
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x01), cpu.ram_bank0[0x7f]);
}

test "DEC direct memory" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x72; rom[1] = 0x7f;
    rom[2] = 0x72; rom[3] = 0x7f;
    rom[4] = 0x72; rom[5] = 0x7f;
    cpu.ram_bank0[0x7f] = 0x02;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x01), cpu.ram_bank0[0x7f]);
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x00), cpu.ram_bank0[0x7f]);
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0xFF), cpu.ram_bank0[0x7f]);
}

test "LD direct loads from memory into ACC" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x02; rom[1] = 0x70;
    cpu.ram_bank0[0x70] = 0x55;
    cpu.a = 0xFF;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x55), cpu.a);
}

test "ST direct stores ACC to memory" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x12; rom[1] = 0x70;
    cpu.a = 0xFF;
    cpu.ram_bank0[0x70] = 0x55;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0xFF), cpu.ram_bank0[0x70]);
}

test "XCH direct swaps ACC and memory" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0xC2; rom[1] = 0x23;
    cpu.a = 0xFF;
    cpu.ram_bank0[0x23] = 0x55;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x55), cpu.a);
    try testing.expectEqual(@as(u8, 0xFF), cpu.ram_bank0[0x23]);
}

test "PUSH ACC onto stack" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    // PUSH ACC: d9 pour SFR ACC (0x100) → opcode bit0=1 → 0x61, byte=0x00
    rom[0] = 0x61; rom[1] = 0x00; // opcode row 6 col 1, d9 byte=0x00 → addr = 0x100 = ACC
    cpu.sp = 0x1F;
    cpu.a = 0xAA;
    // On synchronise manuellement sfr_raw[0x00] = cpu.a pour que load8(0x100) → loadSFR → sfr_raw[0]
    // TODO: supprimer quand loadSFR sera synchronisé avec cpu.a
    cpu.sfr_raw[0x00] = 0xAA;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x20), cpu.sp);
    try testing.expectEqual(@as(u8, 0xAA), cpu.ram_bank0[0x20]);
}

test "POP from stack" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    // POP ACC: d9 pour SFR ACC (0x100) → opcode bit0=1 → 0x71, byte=0x00
    rom[0] = 0x71; rom[1] = 0x00;
    cpu.sp = 0x20;
    cpu.ram_bank0[0x20] = 0x55;
    _ = step(&cpu);
    try testing.expectEqual(@as(u8, 0x1F), cpu.sp);
    // store8(0x100) → storeSFR(0x00) → sfr_raw[0x00] = 0x55
    // TODO: utiliser cpu.a directement quand storeSFR synchro avec cpu.a
    try testing.expectEqual(@as(u8, 0x55), cpu.sfr_raw[0x00]);
}

test "CALL (call_a12) pushes return address and jumps" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    // call_a12 at 0x0FFA: opcode 0x0F (row 0 col 0xF)
    rom[0x0FFA] = 0x0F; // call_a12
    rom[0x0FFB] = 0x0E; // imm8
    // A12 = (opcode&0x10)<<7 | (opcode&7)<<8 | imm8
    // = 0 | 7<<8 | 0x0E = 0x070E
    // PC = (PC & 0xF000) | A12
    cpu.pc = 0x0FFA;
    cpu.sp = 0x1F;
    _ = step(&cpu);
    // After step: pc = (0x0FFC & 0xF000) | 0x070E = 0x070E
    // SP after push low(0x20) + push high(0x21) = 0x21
    try testing.expectEqual(@as(u16, 0x070E), cpu.pc);
    try testing.expectEqual(@as(u8, 0x21), cpu.sp);
    try testing.expectEqual(@as(u8, 0xFC), cpu.ram_bank0[0x20]); // return_addr low
    try testing.expectEqual(@as(u8, 0x0F), cpu.ram_bank0[0x21]); // return_addr high
}

test "CALLR pushes return address and jumps relative" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0x0FFA] = 0x10; // callr
    rom[0x0FFB] = 0x01; // lo byte
    rom[0x0FFC] = 0x01; // hi byte → offset = 0x0101
    cpu.pc = 0x0FFA;
    cpu.sp = 0x1F;
    _ = step(&cpu);
    // PC after fetch: 0x0FFD. PC = 0x0FFD + 0x0101 - 1 = 0x10FD
    try testing.expectEqual(@as(u16, 0x10FD), cpu.pc);
    try testing.expectEqual(@as(u8, 0x21), cpu.sp);
    try testing.expectEqual(@as(u8, 0xFD), cpu.ram_bank0[0x20]); // return_addr low
    try testing.expectEqual(@as(u8, 0x0F), cpu.ram_bank0[0x21]); // return_addr high
}

test "BP branches when bit is set in memory" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x68; rom[1] = 0x10; rom[2] = 0x3F;
    cpu.ram_bank0[0x10] = 0x01; // bit 0 set
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 0x42), cpu.pc);
}

test "BP does not branch when bit is clear" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x68; rom[1] = 0x10; rom[2] = 0x3F;
    cpu.ram_bank0[0x10] = 0x00; // bit 0 clear
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 3), cpu.pc);
}

test "BP with bit 2" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x6A; rom[1] = 0x10; rom[2] = 0x3F;
    cpu.ram_bank0[0x10] = 0x04; // bit 2 set
    _ = step(&cpu);
    try testing.expectEqual(@as(u16, 0x42), cpu.pc);
}

test "step returns correct cycle counts" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);
    rom[0] = 0x00; // nop → 1
    rom[1] = 0x81; rom[2] = 42; // add #imm → 1
    rom[3] = 0x30; // mul → 7
    rom[4] = 0x40; // div → 7
    rom[5] = 0xC0; // ror → 1
    try testing.expectEqual(@as(u8, 1), step(&cpu));
    try testing.expectEqual(@as(u8, 1), step(&cpu));
    try testing.expectEqual(@as(u8, 7), step(&cpu));
    try testing.expectEqual(@as(u8, 7), step(&cpu));
    try testing.expectEqual(@as(u8, 1), step(&cpu));
}

test "MOV #SP, CALLF, INC ACC, RET sequence" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    // MOV #0x1F,SP at 0FF9H: 23 06 1F
    rom[0xFF9] = 0x23;
    rom[0xFFA] = 0x06;
    rom[0xFFB] = 0x1F;

    // CALLF 0F0EH at 0FFCH: 20 0F 0E
    rom[0xFFC] = 0x20;
    rom[0xFFD] = 0x0F;
    rom[0xFFE] = 0x0E;

    // INC ACC at 0F0EH: 63 00
    rom[0xF0E] = 0x63;
    rom[0xF0F] = 0x00;

    // RET at 0F10H: A0
    rom[0xF10] = 0xA0;

    // NOP at 0FFFH: 00
    rom[0xFFF] = 0x00;

    cpu.pc = 0xFF9;
    cpu.a = 0xFF;

    _ = step(&cpu); // MOV #0x1F,SP
    try testing.expectEqual(@as(u8, 0x1F), cpu.sp);
    try testing.expectEqual(@as(u16, 0xFFC), cpu.pc);

    _ = step(&cpu); // CALLF 0F0EH
    try testing.expectEqual(@as(u16, 0xF0E), cpu.pc);
    try testing.expectEqual(@as(u8, 0x21), cpu.sp);
    try testing.expectEqual(@as(u8, 0xFF), cpu.ram_bank0[0x20]);
    try testing.expectEqual(@as(u8, 0x0F), cpu.ram_bank0[0x21]);

    _ = step(&cpu); // INC ACC
    try testing.expectEqual(@as(u8, 0x00), cpu.a);
    try testing.expectEqual(@as(u16, 0xF10), cpu.pc);

    _ = step(&cpu); // RET
    try testing.expectEqual(@as(u16, 0xFFF), cpu.pc);
    try testing.expectEqual(@as(u8, 0x1F), cpu.sp);

    _ = step(&cpu); // NOP
    try testing.expectEqual(@as(u16, 0x1000), cpu.pc);
}
