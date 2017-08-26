#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <malloc.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define DEBUG(...) do { if (debug_enabled()) { fprintf(stderr, "%04x   ", REG(63) - 4); fprintf(stderr, __VA_ARGS__); } } while(0)

typedef uint32_t machinecode_t;
typedef uint32_t reg_t;
#define REG_ZERO 0
#define REG_PC 63
#define REG(x) (vm->registers[x])

typedef struct {
    machinecode_t machinecode;
    uint32_t opcode;
    uint32_t arg1;
    uint32_t arg2;
    uint32_t arg3;
} instruction_t;

#define ARG1 (instruction->arg1)
#define ARG2 (instruction->arg2)
#define ARG3 (instruction->arg3)

typedef struct {
    uint8_t halted;
    uint8_t * disk;
    size_t disk_size;
    uint8_t memory[1024 * 1024];
    reg_t registers[64];
} vm_t;

int debug_enabled() {
    return getenv("DEBUG") && (strcasecmp(getenv("DEBUG"), "true") == 0 || strcasecmp(getenv("DEBUG"), "yes") == 0);
}

void decode(instruction_t * instruction) {
    instruction->opcode = instruction->machinecode >> 27;
    ARG1 = (instruction->machinecode >> 21) & 077;
    ARG2 = (instruction->machinecode >> 15) & 077;
    ARG3 = (instruction->machinecode >> 9) & 077;
}

int op_load_b(instruction_t * instruction, vm_t * vm) {
    uint32_t addr = REG(ARG2) + REG(ARG3);
    DEBUG("LOAD  r%d, BYTE [r%d+r%d]\n", ARG1, ARG2, ARG3);

    REG(ARG1) = vm->memory[addr];
    return 0;
}

int op_load_h(instruction_t * instruction, vm_t * vm) {
    uint32_t addr = REG(ARG2) + REG(ARG3);
    DEBUG("LOAD  r%d, HALF [r%d+r%d]\n", ARG1, ARG2, ARG3);
    REG(ARG1) = (vm->memory[addr + 0] << 8)+
                (vm->memory[addr + 1] << 0);
    return 0;
}

int op_load_w(instruction_t * instruction, vm_t * vm) {
    uint32_t addr = REG(ARG2) + REG(ARG3);
    DEBUG("LOAD  r%d, WORD [r%d+r%d]\n", ARG1, ARG2, ARG3);
    REG(ARG1) = (vm->memory[addr + 0] << 24) +
                (vm->memory[addr + 1] << 16) +
                (vm->memory[addr + 2] <<  8) +
                (vm->memory[addr + 3] <<  0);
    return 0;
}

int op_store_b(instruction_t * instruction, vm_t * vm) {
    uint32_t addr = REG(ARG2) + REG(ARG3);
    DEBUG("STORE r%d, BYTE [r%d+r%d]\n", ARG1, ARG2, ARG3);
    vm->memory[addr] = REG(ARG1);
    return 0;
}

int op_store_h(instruction_t * instruction, vm_t * vm) {
    uint32_t addr = REG(ARG2) + REG(ARG3);
    DEBUG("STORE r%d, HALF [r%d+r%d]\n", ARG1, ARG2, ARG3);
    vm->memory[addr + 0] = REG(ARG1) >> 8;
    vm->memory[addr + 1] = REG(ARG1) >> 0;
    return 0;
}

int op_store_w(instruction_t * instruction, vm_t * vm) {
    uint32_t addr = REG(ARG2) + REG(ARG3);
    DEBUG("STORE r%d, WORD [r%d+r%d]\n", ARG1, ARG2, ARG3);
    vm->memory[addr + 0] = REG(ARG1) >> 24;
    vm->memory[addr + 1] = REG(ARG1) >> 16;
    vm->memory[addr + 2] = REG(ARG1) >>  8;
    vm->memory[addr + 3] = REG(ARG1) >>  0;
    return 0;
}

int op_add(instruction_t * instruction, vm_t * vm) {
    DEBUG("ADD   r%d, r%d, r%d\n", ARG1, ARG2, ARG3);
    REG(ARG1) = REG(ARG2) + REG(ARG3);
    return 0;
}

int op_mul(instruction_t * instruction, vm_t * vm) {
    DEBUG("MUL   r%d, r%d, r%d\n", ARG1, ARG2, ARG3);
    REG(ARG1) = REG(ARG2) * REG(ARG3);
    return 0;
}

int op_div(instruction_t * instruction, vm_t * vm) {
    DEBUG("DIV   r%d, r%d, r%d\n", ARG1, ARG2, ARG3);
    if (REG(ARG3) == 0) {
        return 1;
    } else {
        REG(ARG1) = REG(ARG2) / REG(ARG3);
    }
    return 0;
}

int op_nor(instruction_t * instruction, vm_t * vm) {
    DEBUG("NOR   r%d, r%d, r%d\n", ARG1, ARG2, ARG3);
    REG(ARG1) = ~(REG(ARG2) | REG(ARG3));
    return 0;
}

int op_movi(instruction_t * instruction, vm_t * vm) {
    uint32_t immediate;
    uint32_t shift;

    immediate = (instruction->machinecode >> 5) & 0xffff;
    shift = instruction->machinecode & 037;

    DEBUG("MOVI  r%d, 0x%x\n", ARG1, immediate << shift);

    REG(ARG1) = immediate << shift;
    return 0;
}

int op_cmov(instruction_t * instruction, vm_t * vm) {
    DEBUG("CMOV  r%d, r%d, r%d\n", ARG1, ARG2, ARG3);
    if (REG(ARG3)) {
        REG(ARG1) = REG(ARG2);
    }
    return 0;
}

int op_in(instruction_t * instruction, vm_t * vm) {
    DEBUG("IN    r%d\n", ARG1);
    REG(ARG1) = fgetc(stdin);
    return 0;
}

int op_out(instruction_t * instruction, vm_t * vm) {
    DEBUG("OUT   r%d\n", ARG1);
    putchar(REG(ARG1));
    return 0;
}

int op_read(instruction_t * instruction, vm_t * vm) {
    DEBUG("READ  MEM[r%d], DISK[r%d]\n", ARG1, ARG2);
    if (vm->disk_size < REG(ARG2) * 512 + 512) {
        fprintf(stderr, "Disk size exceeded\n");
        return 1;
    }
    memcpy(&vm->memory[REG(ARG1)], &vm->disk[REG(ARG2) * 512], 512);
    return 0;
}

int op_write(instruction_t * instruction, vm_t * vm) {
    DEBUG("WRITE MEM[r%d], DISK[r%d]\n", ARG1, ARG2);
    if (vm->disk_size < REG(ARG2) * 512 + 512) {
        fprintf(stderr, "Disk size exceeded\n");
        return 1;
    }
    memcpy(&vm->disk[REG(ARG2) * 512], &vm->memory[REG(ARG1)], 512);
    return 0;
}

int op_halt(instruction_t * instruction, vm_t * vm) {
    DEBUG("HALT\n");
    vm->halted = 1;
    return 0;
}

typedef int(*opcode_impl_t)(instruction_t *, vm_t *);

opcode_impl_t opcode_table[] = {
    op_load_b, op_load_h, op_load_w, 
    NULL,
    op_store_b, op_store_h, op_store_w, 
    NULL,
    op_add, op_mul, op_div, op_nor,
    NULL, NULL, NULL, NULL,
    op_movi,
    NULL,
    op_cmov,
    NULL, NULL, NULL, NULL, NULL,
    op_in, op_out, op_read, op_write,
    NULL, NULL, NULL,
    op_halt
};

int execute(uint8_t * disk, size_t len) {
    vm_t vm;

    instruction_t instruction;

    /* Initialize memory and registers */
    memset(&vm, 0, sizeof(vm));
    vm.disk = disk;
    vm.disk_size = len;

    /* Bring in 512 bytes */
    memcpy(vm.memory, disk, 512 < len ? 512 : len);

    /* Enter execute cycle */
    while (!vm.halted) {
        /* Fetch */
        instruction.machinecode = (vm.memory[vm.registers[REG_PC] + 0] << 24) |
                                  (vm.memory[vm.registers[REG_PC] + 1] << 16) |
                                  (vm.memory[vm.registers[REG_PC] + 2] <<  8) |
                                  (vm.memory[vm.registers[REG_PC] + 3] <<  0);
        vm.registers[REG_PC] += 4;
        vm.registers[REG_ZERO] = 0;
        decode(&instruction);
        if (opcode_table[instruction.opcode]) {
            if (opcode_table[instruction.opcode](&instruction, &vm)) {
                return 1;
            }
        } else {
            fprintf(stderr, "illegal opcode\n");
            return 1;
        }
    }
    return 0;
}

#if defined(FUZZER)
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t len) {
    uint8_t *copy;
    if ((copy = (uint8_t*)malloc(len))) {
        memcpy(copy, data, len);
        execute(copy, len);
        free(copy);
        return 0;
    }
    return 1;
}
#else
int main(int argc, char *argv[]) {
    int fd, len;
    struct stat st;
    uint8_t * disk;

    if (argc > 1) {
        if ((fd = open(argv[1], O_RDONLY)) < 0) {
            perror("open");
        } else if (fstat(fd, &st) < 0) {
            perror("fstat");
            close(fd);
        } else if ((disk = (uint8_t*)malloc(st.st_size)) == NULL) {
            perror("malloc");
            close(fd);
        } else if(read(fd, disk, st.st_size) != st.st_size) {
            perror("read");
            free(disk);
            close(fd);
        } else {
            close(fd);
            execute(disk, st.st_size);

            if (argc > 2) {
                if ((fd = open(argv[2], O_WRONLY | O_CREAT, 0664)) < 0) {
                    perror("open");
                } else {
                    write(fd, disk, st.st_size);
                    close(fd);
                }
            }

            free(disk);
        }
    } else {
        fprintf(stderr, "%s %n<infile> [outfile]\n", argv[0], &len);
        fprintf(stderr, "%*sinfile  - Bytecode to execute\n", len, "");
        fprintf(stderr, "%*soutfile - File to write modified infile to\n", len, "");
        fprintf(stderr, "Setting environment variable \"DEBUG\" to \"true\" makes %s output a runtrace.\n", argv[0]);
    }
    
    return 0;
}
#endif
