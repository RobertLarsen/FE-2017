[SECTION .text]

%define REG(r) [REGS + r * 4]

%define PTR(p) [MEM + p]

U5_LE:
;Copy 0x200 (512) bytes from DISK to MEM
mov ecx, 0x200       ; Copy 512 bytes
mov edi, MEM         ; ...to MEM
mov esi, DISK        ; ...from DISK
rep movsb            ; Do it!

SPIN:
mov edx, REG(63)     ; Read 64th entry of REGS table into edx
mov edx, PTR(edx)    ; Read MEM+edx into edx
add WORD REG(63), 4  ; Make 64th entry of REGS table point one entry higher
mov WORD REG(0), 0   ; Zero out first entry of REGS table

; The dword retrieved from MEM into edx works like a small language.
; It consists of an opcode and up to three operands like this:
; [AAAA|ABBB|BBBC|CCCC|CDDD|DDD_|____|____]
; <--MSB                              LSB->
; 
; In the following code this happens:
; * The A's are moved into eax
; * The B's are moved into ebp
; * The C's are moved into esi
; * The D's are moved into edi
;
; The A's are then used to look up an instruction in the OP_TABLE, so those five bits are the opcode
; ebp, edi and esi are operands.
;
; REGS is an array of 64 dwords functioning as registers.
; REGS[63] is the program counter
; REGS[0] is initialized to zero before every execute cycle, works kind of like the MIPS zero register

; Move six bits into ebp (the B's)
mov ebp, edx
shr ebp, 21
and ebp, 77o

; Move six bits into esi (the C's)
mov esi, edx
shr esi, 15
and esi, 77o

; Move six bits into edi (the D's)
mov edi, edx
shr edi, 9
and edi, 77o

; Move top five bits into eax (the A's) and use it to look up an opcode in the OP_TABLE
; Jump to that opcode
mov eax, edx
shr eax, 27
mov eax, [OP_TABLE + eax * 4]
jmp eax

; opcode table has 32 entries but only 17 entries are actually defined
; of those we only have the code for six but perhaps we can guess the implementation for a couple of the others
OP_TABLE:
dd OP_LOAD_B, OP_LOAD_H, OP_LOAD_W, 0, OP_STORE_B, OP_STORE_H, OP_STORE_W, \
0, OP_ADD, OP_MUL, OP_DIV, OP_NOR, 0, 0, 0, 0, OP_MOVI, 0, OP_CMOV, 0, 0,  \
0, 0, 0, OP_IN, OP_OUT, OP_READ, OP_WRITE, 0, 0, 0, OP_HALT

; OP_LOAD_B = Load Byte
; OP_LOAD_H = Load Half Word
; OP_LOAD_W = Load Word

; Load Word
; REGS[B] = MEM[REGS[C] + REGS[D]]
OP_LOAD_W:
mov eax, REG(esi)
add eax, REG(edi)
mov eax, PTR(eax)
mov REG(ebp), eax
jmp SPIN

; REGS[B] = REGS[C] * REGS[D]
OP_MUL:
mov eax, REG(esi)
mul DWORD REG(edi)
mov REG(ebp), eax
jmp SPIN

; REGS[B] = I << S
; [AAAA|ABBB|BBBI|IIII|IIII|IIII|IIIS|SSSS]
; <--MSB                              LSB->
OP_MOVI:
mov eax, edx
mov ecx, edx
;Isolate 16 bits stating form sixth
shr eax, 5
and eax, 0xffff
;Isolate lower five bits
and ecx, 37o
shl eax, cl        ; Left shift the 'I' immediate by 'S' bits
mov REG(ebp), eax  ; ..and store them in REGS[B]
jmp SPIN

; if REGS[D] != 0:
;     REGS[B] = REGS[C]
OP_CMOV:
mov eax, REG(edi)
test eax, eax
jz .F
mov eax, REG(esi)
mov REG(ebp), eax
.F:
jmp SPIN

; Write to stdout
; putchar(REGS[B])
OP_OUT:
push DWORD REG(ebp)
call putchar
add esp, 4
jmp SPIN

; Read from DISK into MEM the 512 byte block indexed by the B register to the memory address specified by the D register
; memcpy(MEM + REGS[B], DISK + (REGS[C] * 512), 512)
OP_READ:
mov ecx, 0x200
mov esi, REG(esi)
shl esi, 9
lea esi, [DISK + esi]
mov edi, REG(ebp)
lea edi, PTR(edi)
rep movsb
jmp SPIN

; Missing symbols
MEM:
DISK:
REGS:
OP_LOAD_B:
OP_LOAD_H:
OP_STORE_B:
OP_STORE_H:
OP_STORE_W:
OP_ADD:
OP_DIV:
OP_NOR:
OP_IN:
OP_WRITE:
OP_HALT:
putchar:
