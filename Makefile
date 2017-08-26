CFLAGS=-Wall -ggdb

.phony: all
all: fe_vm pta

pta: pta.c
	$(CC) $(CFLAGS) -o $@ $<

fe_vm: fe_vm.c
	$(CC) $(CFLAGS) -o $@ $<

.phony: run
run: fe_vm
	./fe_vm decoded.bin

fuzz: fe_vm.c
	clang++ -DFUZZER -g -fsanitize=address -fsanitize-coverage=trace-pc-guard -o $@ $^ /usr/lib/llvm-4.0/lib/libFuzzer.a
