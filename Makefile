CFLAGS=-Wall

.phony: all
all: fe_vm pta

pta: pta.c
	$(CC) $(CFLAGS) -o $@ $<

fe_vm: fe_vm.c
	$(CC) $(CFLAGS) -o $@ $<

.phony: run
run: fe_vm
	./fe_vm decoded.bin
