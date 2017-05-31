%define REG(r) [REGS + r * 4]
%define PTR(p) [MEM + p]
U5_LE:
mov ecx, 0x200
mov edi, MEM
mov esi, DISK
rep movsb

SPIN:
mov edx, REG(63)
mov edx, PTR(edx)
add WORD REG(63), 4
mov WORD REG(0), 0

mov ebp, edx
shr ebp, 21
and ebp, 77o

mov esi, edx
shr esi, 15
and esi, 77o

mov edi, edx
shr edi, 9
and edi, 77o

mov eax, edx
shr eax, 27
mov eax, [OP_TABLE + eax * 4]
jmp eax

OP_TABLE:
dd OP_LOAD_B, OP_LOAD_H, OP_LOAD_W, 0, OP_STORE_B, OP_STORE_H, OP_STORE_W, \
0, OP_ADD, OP_MUL, OP_DIV, OP_NOR, 0, 0, 0, 0, OP_MOVI, 0, OP_CMOV, 0, 0,  \
0, 0, 0, OP_IN, OP_OUT, OP_READ, OP_WRITE, 0, 0, 0, OP_HALT

OP_LOAD_W:
mov eax, REG(esi)
add eax, REG(edi)
mov eax, PTR(eax)
mov REG(ebp), eax
jmp SPIN

OP_MUL:
mov eax, REG(esi)
mul DWORD REG(edi)
mov REG(ebp), eax
jmp SPIN

OP_MOVI:
mov eax, edx
mov ecx, edx
shr eax, 5
and eax, 0xffff
and ecx, 37o
shl eax, cl
mov REG(ebp), eax
jmp SPIN

OP_CMOV:
mov eax, REG(edi)
test eax, eax
jz .F
mov eax, REG(esi)
mov REG(ebp), eax
.F:
jmp SPIN

OP_OUT:
push DWORD REG(ebp)
call putchar
add esp, 4
jmp SPIN

OP_READ:
mov ecx, 0x200
mov esi, REG(esi)
shl esi, 9
lea esi, [DISK + esi]
mov edi, REG(ebp)
lea edi, PTR(edi)
rep movsb
jmp SPIN
