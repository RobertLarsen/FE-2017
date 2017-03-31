# Danish Defence Intelligence Service 2017 challenge

This repo contains programs and reversing results I developed for solving the challenge.

## hacker-opgave2017.bmp

This is the original challenge. The text on the right decodes to a shorter version of the disk image in this repo.

You can solve the challenge using that version, but at a point the bytecode rewrites itself to a web server, but it doesn't work in that version.

A longer version could be retrieved from an onion address which is down now however that version is the one I based my disk.img upon.

## disk.img

Bytecode for the VM. This is the long version retrieved from the onion server.

## fe_vm.c

My implementation of the VM which is begun on the left of the picture.

You run it like this:

```
./fe_vm disk.img
```

If the program writes to the disk you can have it written out to a new file like this:

```
./fe_vm disk.img out.img
```

You can get a runtrace like this:

```
DEBUG=true ./fe_vm disk.img out.img 2>runtrace.asm
```

That will likely be very long so sort it and remove duplicate lines:


```
sort -u < runtrace.asm >disassembly.asm
```

## pta.c

Performs a plain text attack on the crypto used by the bytecode.

## disk.img.asm

Commented disassembly of the code behind the disk.img

## web.img.asm

Commented disassembly of the code behind the web.img
