# Projet

"Le Dreamcast VMU est une carte mémoire développée par l'entreprise Sega comportant un écran LCD pour pouvoir jouer à des mini-jeux mais aussi voir des animations lors de parties jouées sur Dreamcast. Son nom original est Dreamcast VMS pour Visual Memory System." Source : Wikipedia

## Caractéristiques matérielles

| Composant | Détail |
|-----------|--------|
| CPU | 8-bit Sanyo LC86K87 |
| Horloge | 6 MHz (céramique) + 32.768 kHz (quartz RTC) |
| RAM | 512B interne banquée (2×256B) + 198B XRAM LCD (2×96 + 6 icônes) |
| ROM | 16KB BIOS |
| Flash | 128KB (200 blocs), FAT8 |
| Affichage | 48×32, monochrome |
| Son | PWM 1 canal 8-bit |
| Entrées | D-pad 4 dir. + A, B, MODE, SLEEP |
| Timer | 1× Base (14-bit) + 2× Timer 16-bit |
| Série | Maple (Dreamcast) + synchro 8-bit (VMU-VMU) |

**Doc** : 
répertoire doc /  
Les références seront effectuées d'après le fichier VMU.pdf


## Opcodes

Le LC86k possède 70 instructions (p561) :

## Tableau des instructions

### Arithmetic instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| ADD | `0x81` | #i8 | CY AC OV P | ACC ← ACC + i8 |
| ADD | `0x82-0x83` | d9 | CY AC OV P | ACC ← ACC + (d9) |
| ADD | `0x84-0x87` | @Ri | CY AC OV P | ACC ← ACC + ((Ri)) |
| ADDC | `0x91` | #i8 | CY AC OV P | ACC ← ACC + i8 + CY |
| ADDC | `0x92-0x93` | d9 | CY AC OV P | ACC ← ACC + (d9) + CY |
| ADDC | `0x94-0x97` | @Ri | CY AC OV P | ACC ← ACC + ((Ri)) + CY |
| SUB | `0xA1` | #i8 | CY AC OV P | ACC ← ACC − i8 |
| SUB | `0xA2-0xA3` | d9 | CY AC OV P | ACC ← ACC − (d9) |
| SUB | `0xA4-0xA7` | @Ri | CY AC OV P | ACC ← ACC − ((Ri)) |
| SUBC | `0xB1` | #i8 | CY AC OV P | ACC ← ACC − i8 − CY |
| SUBC | `0xB2-0xB3` | d9 | CY AC OV P | ACC ← ACC − (d9) − CY |
| SUBC | `0xB4-0xB7` | @Ri | CY AC OV P | ACC ← ACC − ((Ri)) − CY |
| INC | `0x62-0x63` | d9 | P | (d9) ← (d9) + 1 |
| INC | `0x64-0x67` | @Ri | P | ((Ri)) ← ((Ri)) + 1 |
| DEC | `0x72-0x73` | d9 | P | (d9) ← (d9) − 1 |
| DEC | `0x74-0x77` | @Ri | P | ((Ri)) ← ((Ri)) − 1 |
| MUL | `0x30` | impl | CY=0, OV | B:ACC:C ← (ACC:C) × B |
| DIV | `0x40` | impl | CY=0, OV | ACC:C, mod(B) ← (ACC:C) ÷ B |

### Logical instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| AND | `0xE1` | #i8 | P | ACC ← ACC & i8 |
| AND | `0xE2-0xE3` | d9 | P | ACC ← ACC & (d9) |
| AND | `0xE4-0xE7` | @Ri | P | ACC ← ACC & ((Ri)) |
| OR | `0xD1` | #i8 | P | ACC ← ACC \| i8 |
| OR | `0xD2-0xD3` | d9 | P | ACC ← ACC \| (d9) |
| OR | `0xD4-0xD7` | @Ri | P | ACC ← ACC \| ((Ri)) |
| XOR | `0xF1` | #i8 | P | ACC ← ACC ^ i8 |
| XOR | `0xF2-0xF3` | d9 | P | ACC ← ACC ^ (d9) |
| XOR | `0xF4-0xF7` | @Ri | P | ACC ← ACC ^ ((Ri)) |
| ROL | `0xE0` | impl | CY | rotate left through ACC, LSB ← MSB |
| ROLC | `0xF0` | impl | CY | rotate left through ACC via CY |
| ROR | `0xC0` | impl | CY | rotate right through ACC, MSB ← LSB |
| RORC | `0xD0` | impl | CY | rotate right through ACC via CY |

### Data transfer instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| LD | `0x02-0x03` | d9 | — | ACC ← (d9) |
| LD | `0x04-0x07` | @Ri | — | ACC ← ((Ri)) |
| ST | `0x12-0x13` | d9 | — | (d9) ← ACC |
| ST | `0x14-0x17` | @Ri | — | ((Ri)) ← ACC |
| MOV | `0x22-0x23` | d9, #i8 | — | (d9) ← i8 |
| MOV | `0x24-0x27` | @Ri, #i8 | — | ((Ri)) ← i8 |
| LDC | `0xC1` | impl | — | ACC ← (BNK)(TRR + ACC) |
| PUSH | `0x60-0x61` | d9 | — | SP++ ; (SP) ← (d9) |
| POP | `0x70-0x71` | d9 | — | (d9) ← (SP) ; SP−− |
| XCH | `0xC2-0xC3` | d9 | — | swap ACC ↔ (d9) |
| XCH | `0xC4-0xC7` | @Ri | — | swap ACC ↔ ((Ri)) |

### Jump instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| BR | `0x01` | r8 | — | PC ← PC + r8 (sign-extended) |
| BRF | `0x11` | r16 | — | PC ← PC + r16 − 1 |
| JMP | `0x28-0x2F, 0x38-0x3F` | a12 | — | PC ← (PC & 0xF000) \| a12 |
| JMPF | `0x21` | a16 | — | PC ← a16, commit bank switch |

### Conditional branch instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| BZ | `0x80` | r8 | — | if ACC == 0 → PC ← PC + r8 |
| BNZ | `0x90` | r8 | — | if ACC ≠ 0 → PC ← PC + r8 |
| BP | `0x68-0x6F, 0x78-0x7F` | d9, b3, r8 | — | if bit(d9,b3)=1 → PC ← PC + r8 |
| BN | `0x88-0x8F, 0x98-0x9F` | d9, b3, r8 | — | if bit(d9,b3)=0 → PC ← PC + r8 |
| BPC | `0x48-0x4F, 0x58-0x5F` | d9, b3, r8 | — | if bit(d9,b3)=1 → PC ← PC + r8; clear bit |
| BE | `0x31` | #i8, r8 | CY | if ACC == i8 → PC ← PC + r8 ; CY ← ACC < i8 |
| BE | `0x32-0x33` | d9, r8 | CY | if ACC == (d9) → PC ← PC + r8 ; CY ← ACC < (d9) |
| BE | `0x34-0x37` | @Ri, r8 | CY | if ACC == ((Ri)) → PC ← PC + r8 ; CY ← ACC < ((Ri)) |
| BNE | `0x41` | #i8, r8 | CY | if ACC ≠ i8 → PC ← PC + r8 ; CY ← ACC < i8 |
| BNE | `0x42-0x43` | d9, r8 | CY | if ACC ≠ (d9) → PC ← PC + r8 ; CY ← ACC < (d9) |
| BNE | `0x44-0x47` | @Ri, r8 | CY | if ACC ≠ ((Ri)) → PC ← PC + r8 ; CY ← ACC < ((Ri)) |
| DBNZ | `0x52-0x53` | d9, r8 | — | (d9) ← (d9) − 1 ; if (d9) ≠ 0 → PC ← PC + r8 |
| DBNZ | `0x54-0x57` | @Ri, r8 | — | ((Ri)) ← ((Ri)) − 1 ; if ((Ri)) ≠ 0 → PC ← PC + r8 |

### Subroutine instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| CALL | `0x08-0x0F, 0x18-0x1F` | a12 | — | push PC ; PC ← (PC & 0xF000) \| a12 |
| CALLR | `0x10` | r16 | — | push PC ; PC ← PC + r16 − 1 |
| CALLF | `0x20` | a16 | — | push PC ; PC ← a16 ; commit bank switch |
| RET | `0xA0` | impl | — | PC ← pop() |
| RETI | `0xB0` | impl | — | PC ← pop() ; enable interrupts |

### Bit manipulation instructions

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| CLR1 | `0xC8-0xCF, 0xD8-0xDF` | d9, b3 | — | (d9,b3) ← 0 |
| SET1 | `0xE8-0xEF, 0xF8-0xFF` | d9, b3 | — | (d9,b3) ← 1 |
| NOT1 | `0xA8-0xAF, 0xB8-0xBF` | d9, b3 | — | (d9,b3) ← ¬(d9,b3) |

### Miscellaneous

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| NOP | `0x00` | impl | — | no operation |

### Macro instruction

| Inst | Opcodes | Mode | Flags | Description |
|------|---------|------|-------|-------------|
| CHANGE | `0xE1` + `0xF1` | #i8, #i8 | P | AND mask1, XOR mask2 (2-word macro) |

## Etat d'avancement 

| Instruction | Opcode(s) | Impl. | Test | Note |
|-------------|-----------|:-----:|:----:|------|
| nop | 0x00 | 🟢 | Oui | |
| br | 0x01 | 🟢 | Oui | |
| ld | 0x02–0x03 | 🟢 | Oui | |
| ld_ri | 0x04–0x07 | 🟢 | Non | |
| call_a12 | 0x08–0x0F, 0x18–0x1F | 🟢 | Oui | |
| callr | 0x10 | 🟢 | Oui | |
| brf | 0x11 | 🟢 | Non | |
| st | 0x12–0x13 | 🟢 | Oui | |
| st_ri | 0x14–0x17 | 🟢 | Non | |
| callf | 0x20 | 🟢 | Non | |
| jmpf | 0x21 | 🟢 | Non | |
| mov | 0x22–0x23 | 🟢 | Non | |
| mov_ri | 0x24–0x27 | 🟢 | Non | |
| jmp_a12 | 0x28–0x2F, 0x38–0x3F | 🔴 | Non | |
| mul | 0x30 | 🟢 | Oui | |
| be_imm | 0x31 | 🟢 | Non | |
| be_d9 | 0x32–0x33 | 🟢 | Non | |
| be_ri | 0x34–0x37 | 🟢 | Non | |
| div | 0x40 | 🟢 | Oui | |
| bne_imm | 0x41 | 🟢 | Non | |
| bne_d9 | 0x42–0x43 | 🟢 | Non | |
| bne_ri | 0x44–0x47 | 🟢 | Non | |
| bpc | 0x48–0x4F, 0x58–0x5F | 🔴 | Non | |
| dbnz_d9 | 0x52–0x53 | 🔴 | Non | |
| dbnz_ri | 0x54–0x57 | 🔴 | Non | |
| push | 0x60–0x61 | 🟢 | Oui | |
| inc_d9 | 0x62–0x63 | 🟢 | Oui | |
| inc_ri | 0x64–0x67 | 🟢 | Non | |
| bp | 0x68–0x6F, 0x78–0x7F | 🟢 | Oui | |
| pop | 0x70–0x71 | 🟢 | Oui | |
| dec_d9 | 0x72–0x73 | 🟢 | Oui | |
| dec_ri | 0x74–0x77 | 🟢 | Non | |
| bz | 0x80 | 🟢 | Oui | |
| add_imm | 0x81 | 🟢 | Oui | |
| add_d9 | 0x82–0x83 | 🟢 | Non | |
| add_ri | 0x84–0x87 | 🟢 | Non | |
| bn | 0x88–0x8F, 0x98–0x9F | 🟢 | Oui | |
| bnz | 0x90 | 🟢 | Oui | |
| addc_imm | 0x91 | 🟢 | Oui | |
| addc_d9 | 0x92–0x93 | 🟢 | Non | |
| addc_ri | 0x94–0x97 | 🟢 | Non | |
| ret | 0xA0 | 🟢 | Oui | |
| sub_imm | 0xA1 | 🟢 | Oui | |
| sub_d9 | 0xA2–0xA3 | 🟢 | Non | |
| sub_ri | 0xA4–0xA7 | 🟢 | Non | |
| not1 | 0xA8–0xAF, 0xB8–0xBF | 🟢 | Non | |
| reti | 0xB0 | 🔴 | Non | |
| subc_imm | 0xB1 | 🟢 | Oui | |
| subc_d9 | 0xB2–0xB3 | 🟢 | Non | |
| subc_ri | 0xB4–0xB7 | 🟢 | Non | |
| ror | 0xC0 | 🟢 | Oui | |
| ldc | 0xC1 | 🟢 | Non | |
| xch_d9 | 0xC2–0xC3 | 🟢 | Oui | |
| xch_ri | 0xC4–0xC7 | 🟢 | Non | |
| clr1 | 0xC8–0xCF, 0xD8–0xDF | 🟢 | Non | |
| rorc | 0xD0 | 🟢 | Oui | |
| or_imm | 0xD1 | 🟢 | Oui | |
| or_d9 | 0xD2–0xD3 | 🟢 | Oui | |
| or_ri | 0xD4–0xD7 | 🟢 | Non | |
| rol | 0xE0 | 🟢 | Oui | |
| and_imm | 0xE1 | 🟢 | Oui | |
| and_d9 | 0xE2–0xE3 | 🟢 | Non | |
| and_ri | 0xE4–0xE7 | 🟢 | Non | |
| set1 | 0xE8–0xEF, 0xF8–0xFF | 🟢 | Non | |
| rolc | 0xF0 | 🟢 | Oui | |
| xor_imm | 0xF1 | 🟢 | Oui | |
| xor_d9 | 0xF2–0xF3 | 🟢 | Non | |
| xor_ri | 0xF4–0xF7 | 🟢 | Non | |

## Résumé

| Status | Nb instructions |
|--------|:--------------:|
| 🟢 implémenté | 65 |
| 🔴 manquant | 5 |

**Tests :** 44/44 passent ✅ (`zig build test`)

## TODO

### Ajout SFR autre que CPU (P0)

- [ ] Timers T0, T1, Base Timer — overflow, prescaler, 8/16-bit modes
- [ ] I/O Ports P1, P3, P7 — boutons, état connexion
- [ ] Contrôle LCD XBNK, VCCR, MCR, CNR, TDR
- [ ] Contrôle Horloge OCR, ISL, division d'horloge
- [ ] Interruptions IE, IP, I01Cr, I23Cr
- [ ] Maple MPLSW, MPLSTA, MPLRST
- [ ] Série SCON0/1, SBUF0/1, SBR
- [ ] Flash FPR, EXT (bank switching)
- [ ] Work RAM VRMAD, VTRBF
- [ ] Power PCON (halt)

### Autres (P1)
- [ ] Interruptions : 10 sources avec vecteurs en ROM (0x0003-0x004B) : INT0 (connexion Dreamcast), INT1 (batterie faible), INT2 (Timer0), INT3 (Base Timer), T0H, T1, SIO0/1, Maple, P3 (boutons). Priorité, masquage, nesting.
- [ ] Affichage : 48×32 monochrome depuis XRAM (2×96 + 6 icônes). Relativement simple une fois XRAM dispatché.
- [ ] 1 bit PWM via T1L, buffer PCM 32kHz. Simple si le Timer 1 est implémenté.

### Affichage + Filesystem (P2)
- [ ] Maple Bus : Protocole de communication Dreamcast ↔ VMU. Requis pour charger des vms/vmu et pour l'intégration Flycast.
- [ ] Filesystem Flash : 128KB, FAT8, 256 blocs de 512B. Root block, directory entries, import/export VMS/VMI. ≈1000 lignes.
- [ ] Affichage de l'écran, capture des entrées clavier, émulation de l'horloge temps réel.

