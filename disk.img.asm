;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                           ;;
;; zero   = zero register                    ;;
;; r1   = return value from subrouting calls ;;
;; r3   = First arg to subroutine calls      ;;
;; r4   = Second arg to subroutine calls     ;;
;; r5   = Third arg to subroutine calls      ;;
;; lr  = Link register                       ;;
;; sp  = Stack register                      ;;
;; pc  = Program counter                     ;;
;;                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;GOTO 0xc
0000   MOVI  pc, 0xc

;GOTO 0xa8
000c   MOVI  pc, 0xa8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;       Address 0x000 - 0x200 is the first sector (boot sector).                 ;;
;;       Its responsibility is to load the rest of the program into memory,       ;;
;;       set up stack and start execution of the program.                         ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; I believe this is the "detect wrong endianess" magic
00a8   MOVI  r20, 0xc0
00ac   MOVI  r21, 0x14c

; uint32_t LOC_0xbe = 0
00b0   MOVI  r22, 0xbe
00b4   STORE zero, BYTE [r22+zero]

;Read first 512 program bytes into memory...again
00b8   READ  MEM[zero], DISK[zero] 

;r21 contains 0x14c
;GOTO 0x14c
00bc   ADD   pc, r21, zero

#r61 = pc   Remember where we are (plus four)
014c   ADD   r61, pc, zero

;r57 = -5
0150   MOVI  r57, 0x4
0154   NOR   r57, r57, r57

;r61 = 0x14b
0158   ADD   r61, r61, r57

;r61++
015c   MOVI  r57, 0x1
0160   ADD   r61, r61, r57


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;              Read five more sectors from disk into consecutive                 ;;
;;              memory regions starting from address 512.                         ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
;sp = 0x100000, r22 = 6, r20 = 1, r21 = 0x200, r57 = -2                          ;;
0164   MOVI  sp, 0x100000    ; Dunno what this is used for, stack probably       ;;
0168   MOVI  r22, 0x6         ; Loop counter for looping 5 times                  ;;
016c   MOVI  r20, 0x1         ; Index of block to read                            ;;
0170   MOVI  r21, 0x200       ; Location of next block to fetch into memory       ;;
                                                                                  ;;
                                                                                  ;;
LOAD_NEXT_SECTOR:                                                                 ;;
;r23 = 6 - r20                                                                    ;;
0174   NOR   r57, r20, r20   ; r57 = -(r20) - 1                                   ;;
0178   ADD   r23, r22, r57   ; r23 = r22 + r57                                    ;;
017c   MOVI  r57, 0x1                                                             ;;
0180   ADD   r23, r23, r57   ; r23++                                              ;;
                                                                                  ;;
;if more sectors remain goto reading another one                                  ;;
;if (r23 != 0) GOTO 0x198                                                         ;;
0184   MOVI  r57, 0xc                                                             ;;
0188   ADD   r57, pc, r57                                                        ;;
018c   CMOV  pc, r57, r23                                                        ;;
                                                                                  ;;
;if we got here there are no more sectors                                         ;;
;GOTO NO_MORE_SECTORS                                                             ;;
0190   MOVI  r57, 0x1b4                                                           ;;
0194   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
                                                                                  ;;
;Load disk sector r20 into memory at 512                                          ;;
0198   READ  MEM[r21], DISK[r20]                                                  ;;
                                                                                  ;;
;r20++  (next disk sector)                                                        ;;
019c   MOVI  r57, 0x1                                                             ;;
01a0   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
;r21 += 512   ;One disk sector size higher memory address                         ;;
01a4   MOVI  r57, 0x200                                                           ;;
01a8   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
;GOTO LOAD_NEXT_SECTOR                                                            ;;
01ac   MOVI  r57, 0x174                                                           ;;
01b0   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
NO_MORE_SECTORS:                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;Are these just here to confuse?
;Apparently they don't do anything
01b4   NOR   r20, zero, zero
01b8   DIV   r20, zero, r20
01bc   MOVI  r57, 0x1d0
01c0   ADD   r57, r57, zero
01c4   CMOV  pc, r57, r20

;Start executing the loaded programs main function
;GOTO 0x28c
01c8   MOVI  r57, 0x28c
01cc   ADD   pc, r57, zero


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;          Main program. Does this:                                              ;;
;;          putstring("Password: ")                                               ;;
;;          if (password_length = (getstring(0x1200)) == 0) {                     ;;
;;             no_password()                                                      ;;
;;          }                                                                     ;;
;;          putstring("Initializing decryption")                                  ;;
;;          waste_time()                                                          ;;
;;          rc4_init(0xb4c, 0x1200, password_length)                              ;;
;;          putstring("OK\n")                                                     ;;
;;          putstring("Checking decryption key")                                  ;;
;;          waste_time()                                                          ;;
;;                                                                                ;;
;;          if (memcmp(0x964, 0x92c, 56) != 0) {                                  ;;
;;              putstring("Bad key!\n")                                           ;;
;;              exit()                                                            ;;
;;          }                                                                     ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;putstring("Password: ")
028c   MOVI  r3, 0xad0          ; Address of string to output
0290   MOVI  r57, 0x8           ; This is the return address, a link register
0294   ADD   lr, pc, r57      ; ...more setting return address
0298   MOVI  r57, 0x870         ; Address of putstring
029c   ADD   pc, r57, zero       ; Call putstring


;getstring(0x1200)
02a0   MOVI  r3, 0x1200         ; Address for where to store string
02a4   MOVI  r57, 0x8           ; Set return address
02a8   ADD   lr, pc, r57      ; ...more setting return address
02ac   MOVI  r57, 0x7f8         ; Address of getstring
02b0   ADD   pc, r57, zero       ; Call getstring, length of string is in r1

; If length of string != 0:
;    GOTO 0x2c8
02b4   MOVI  r57, 0xc
02b8   ADD   r57, pc, r57
02bc   CMOV  pc, r57, r1

;Length is 0
;GOTO no_password()
02c0   MOVI  r57, 0x518
02c4   ADD   pc, r57, zero

;Length is not 0
;putstring("Initializing decryption")
02c8   ADD   r10, r1, zero      ; Save length of string
02cc   MOVI  r3, 0xadb        ; Point to "Initializing decryption"
02d0   MOVI  r57, 0x8         ; Set return address
02d4   ADD   lr, pc, r57    ; ...more setting return address
02d8   MOVI  r57, 0x870       ; Address of putstring
02dc   ADD   pc, r57, zero     ; Call putstring


;waste_time()
02e0   MOVI  r57, 0x8         ; Set return address
02e4   ADD   lr, pc, r57    ; ...more setting return address
02e8   MOVI  r57, 0x5a4       ; Address of waste_time
02ec   ADD   pc, r57, zero     ; Call waste_time


; rc4_init(0xb4c, 0x1200, password_length)
02f0   MOVI  r3, 0xb4c        ; First argument to rc4_init, address of key
02f4   MOVI  r4, 0x1200       ; Second argument to rc4_init, address of password
02f8   ADD   r5, r10, zero      ; Third argument to rc4_init, length of password
02fc   MOVI  r57, 0x8         ; Set return address
0300   ADD   lr, pc, r57    ; ...more setting return address
0304   MOVI  r57, 0x5fc       ; Address of rc4_init
0308   ADD   pc, r57, zero     ; Call rc4_init


; putstring("OK\n")
030c   MOVI  r3, 0xaf3        ; Address of "OK\n"
0310   MOVI  r57, 0x8         ; Set return address
0314   ADD   lr, pc, r57    ; ...more setting return address
0318   MOVI  r57, 0x870       ; Address of putstring
031c   ADD   pc, r57, zero     ; Call putstring

; putstring("Checking decryption key")
0320   MOVI  r3, 0xafd        ; Address of "Checking decryption key"
0324   MOVI  r57, 0x8         ; Set return address
0328   ADD   lr, pc, r57    ; ...more setting return address
032c   MOVI  r57, 0x870       ; Address of putstring
0330   ADD   pc, r57, zero     ; Call putstring

;waste_time()
0334   MOVI  r57, 0x8         ; Set return address
0338   ADD   lr, pc, r57    ; ...more setting return address
033c   MOVI  r57, 0x5a4       ; Address of waste_time
0340   ADD   pc, r57, zero     ; Call waste_time


; rc4_decrypt(0xb4c, 0x964, 56)
0344   MOVI  r3, 0xb4c        ; Address of key
0348   MOVI  r4, 0x964        ; Address of data to decrypt
034c   MOVI  r5, 0x38         ; Length of data to decrypt
0350   MOVI  r57, 0x8         ; Set return address
0354   ADD   lr, pc, r57    ; ...more setting return address
0358   MOVI  r57, 0x730       ; Address of rc4_decrypt
035c   ADD   pc, r57, zero     ; Call rc4_decrypt

; memcmp (0x964, 0x92c, 56)
0360   MOVI  r3, 0x964       ; First arg. to memcmp
0364   MOVI  r4, 0x92c       ; Second arg. to memcmp
0368   MOVI  r5, 0x38        ; Length to compare
036c   MOVI  r57, 0x8        ; Set return address
0370   ADD   lr, pc, r57   ; ...more setting return address
0374   MOVI  r57, 0x89c      ; Address of memcmp
0378   ADD   pc, r57, zero    ; Call memcmp

; if regions were different:
;    GOTO 0x500
037c   MOVI  r57, 0x500
0380   ADD   r57, r57, zero
0384   CMOV  pc, r57, r1


0388   MOVI  r3, 0xaf3
038c   MOVI  r57, 0x8
0390   ADD   lr, pc, r57
0394   MOVI  r57, 0x870
0398   ADD   pc, r57, zero


039c   MOVI  r3, 0xb4c
03a0   MOVI  r4, 0x1200
03a4   ADD   r5, r10, zero
03a8   MOVI  r57, 0x8
03ac   ADD   lr, pc, r57
03b0   MOVI  r57, 0x5fc
03b4   ADD   pc, r57, zero


03b8   MOVI  r3, 0xb15
03bc   MOVI  r57, 0x8
03c0   ADD   lr, pc, r57
03c4   MOVI  r57, 0x870
03c8   ADD   pc, r57, zero


03cc   ADD   r11, zero, zero
03d0   MOVI  r57, 0x464
03d4   ADD   pc, r57, zero


03d8   MOVI  r57, 0xc00
03dc   ADD   r21, r11, r57
03e0   MOVI  r57, 0x200
03e4   DIV   r21, r21, r57
03e8   MOVI  r57, 0xe00
03ec   READ  MEM[r57], DISK[r21]
03f0   MOVI  r3, 0xb4c
03f4   MOVI  r4, 0xe00
03f8   MOVI  r5, 0x200
03fc   MOVI  r57, 0x8
0400   ADD   lr, pc, r57
0404   MOVI  r57, 0x730
0408   ADD   pc, r57, zero


040c   MOVI  r57, 0x200
0410   DIV   r21, r11, r57
0414   MOVI  r58, 0xe00
0418   WRITE MEM[r58], DISK[r21]
0464   MOVI  r57, 0xa537
0468   MOVI  r21, 0xffff0000
046c   NOR   r21, r21, r57
0470   NOR   r57, r21, r21
0474   ADD   r21, r11, r57
0478   MOVI  r57, 0x1
047c   ADD   r21, r21, r57
0480   MOVI  r57, 0x80000
0484   DIV   r21, r21, r57
0488   MOVI  r57, 0x3d8
048c   ADD   r57, r57, zero
0490   CMOV  pc, r57, r21


; putstring("Bad key!\n")
0500   MOVI  r3, 0xb2b
0504   MOVI  r57, 0x8
0508   ADD   lr, pc, r57
050c   MOVI  r57, 0x870
0510   ADD   pc, r57, zero

;Halt execution
0514   HALT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               No password specified                                            ;;
;;               Say "Eh..?\n" and halt execution                                 ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
;call putstring("Eh..?\n")                                                        ;;
0518   MOVI  r3, 0xb35       ; Address of "Eh..?\n"                               ;;
051c   MOVI  r57, 0x8        ; Set return address                                 ;;
0520   ADD   lr, pc, r57   ; ...more setting of return address                  ;;
0524   MOVI  r57, 0x870      ; Address of putstring                               ;;
0528   ADD   pc, r57, zero    ; Call putstring                                     ;;
                                                                                  ;;
052c   HALT                  ; Halt execution                                     ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               busywait_and_putc                                                ;;
;;                                                                                ;;
;;               Does this:                                                       ;;
;;                  busywait(100000)                                              ;;
;;                  putc('.')                                                     ;;
;;                  return                                                        ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
                                                                                  ;;
; sp -= 4   ; Decrement stack pointer                                            ;;
0568   MOVI  r57, 0x3                                                             ;;
056c   NOR   r57, r57, r57                                                        ;;
0570   ADD   sp, sp, r57                                                        ;;
                                                                                  ;;
; Store return address                                                            ;;
0574   STORE lr, WORD [sp+zero]                                                   ;;
                                                                                  ;;
; busywait(100000)                                                                ;;
0578   MOVI  r3, 1000000          ; How long to busywait                          ;;
057c   MOVI  r57, 0x8             ; Set return address                            ;;
0580   ADD   lr, pc, r57        ; More setting return address                   ;;
0584   MOVI  r57, 0x8f8           ; Address of busywait                           ;;
0588   ADD   pc, r57, zero         ; Call busywait                                 ;;
                                                                                  ;;
;putc('.')                                                                        ;;
058c   MOVI  r57, 0x2e                                                            ;;
0590   OUT   r57                                                                  ;;
                                                                                  ;;
;Load return address and increment stack                                          ;;
0594   MOVI  r57, 0x4                                                             ;;
0598   LOAD  lr, WORD [sp+zero]                                                   ;;
059c   ADD   sp, sp, r57                                                        ;;
                                                                                  ;;
;Return                                                                           ;;
05a0   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;                     waste_time()                                               ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
; sp -= 4   ; Decrement stack pointer                                            ;;
05a4   MOVI  r57, 0x3                                                             ;;
05a8   NOR   r57, r57, r57                                                        ;;
05ac   ADD   sp, sp, r57                                                        ;;
                                                                                  ;;
;Store return address                                                             ;;
05b0   STORE lr, WORD [sp+zero]                                                   ;;
                                                                                  ;;
; busywait_and_putc()                                                             ;;
05b4   MOVI  r57, 0x8                ; Set return address                         ;;
05b8   ADD   lr, pc, r57           ; ...more setting return address             ;;
05bc   MOVI  r57, 0x568              ; Address of busywait_and_putc               ;;
05c0   ADD   pc, r57, zero            ; Call busywait_and_putc                     ;;
                                                                                  ;;
; busywait_and_putc()                                                             ;;
05c4   MOVI  r57, 0x8                ; Set return address                         ;;
05c8   ADD   lr, pc, r57           ; ...more setting return address             ;;
05cc   MOVI  r57, 0x568              ; Address of busywait_and_putc               ;;
05d0   ADD   pc, r57, zero            ; Call busywait_and_putc                     ;;
                                                                                  ;;
; busywait_and_putc()                                                             ;;
05d4   MOVI  r57, 0x8                ; Set return address                         ;;
05d8   ADD   lr, pc, r57           ; ...more setting return address             ;;
05dc   MOVI  r57, 0x568              ; Address of busywait_and_putc               ;;
05e0   ADD   pc, r57, zero            ; Call busywait_and_putc                     ;;
                                                                                  ;;
; putc(' ')                                                                       ;;
05e4   MOVI  r57, 0x20                                                            ;;
05e8   OUT   r57                                                                  ;;
                                                                                  ;;
; Load return address and return                                                  ;;
05ec   MOVI  r57, 0x4                                                             ;;
05f0   LOAD  lr, WORD [sp+zero]                                                   ;;
05f4   ADD   sp, sp, r57                                                        ;;
05f8   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;     typedef struct {                                                           ;;
;;         uint8_t a                                                              ;;
;;         uint8_t b                                                              ;;
;;         uint8_t s[256]                                                         ;;
;;     } rc4_key_t                                                                ;;
;;                                                                                ;;
;;     rc4_init(rc4_key_t * key, char * password, size_t password_length)         ;;
;;                                                                                ;;
;;     Preconditions:                                                             ;;
;;        * r3  : Points to rc4 key to initialize                                 ;;
;;        * r4  : Points to password                                              ;;
;;        * r5  : Length of password                                              ;;
;;        * lr : Contains return address                                         ;;
;;     Postconditions:                                                            ;;
;;        * r1  :                                                                 ;;
;;                                                                                ;;
;;                                                                                ;;
;;     Does this:                                                                 ;;
;;        int i = 0                                                               ;;
;;        do {                                                                    ;;
;;            key->s[i] = i                                                       ;;
;;            i = (i + 1) & 0xff                                                  ;;
;;        } while (i != 0)                                                        ;;
;;        key->a = 0                                                              ;;
;;        key->b = 0                                                              ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
; r22 = key->s                                                                    ;;
05fc   MOVI  r57, 0x2                                                             ;;
0600   ADD   r22, r3, r57                                                         ;;
                                                                                  ;;
; r20 = 0                                                                         ;;
0604   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; r22[r20] = r20                                                                  ;;
0608   STORE r20, BYTE [r22+r20]  ; key->s[i] = i                                 ;;
                                                                                  ;;
; r20++                                                                           ;;
060c   MOVI  r57, 0x1                                                             ;;
0610   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; r20 &= 0xff                                                                     ;;
0614   MOVI  r57, 0xff                                                            ;;
0618   NOR   r57, r57, r57                                                        ;;
061c   NOR   r20, r20, r20                                                        ;;
0620   NOR   r20, r57, r20                                                        ;;
                                                                                  ;;
; if r20 != 0:                                                                    ;;
;    GOTO 0x608                                                                   ;;
0624   MOVI  r57, 0x608                                                           ;;
0628   ADD   r57, r57, zero                                                         ;;
062c   CMOV  pc, r57, r20                                                        ;;
                                                                                  ;;
; Done with array initializing loop                                               ;;
                                                                                  ;;
; r20 = 0, r21 = 0                                                                ;;
0630   ADD   r20, zero, zero                                                          ;;
0634   ADD   r21, zero, zero                                                          ;;
                                                                                  ;;
; r21 += key->s[r20]                                                              ;;
0638   LOAD  r23, BYTE [r22+r20]                                                  ;;
063c   ADD   r21, r21, r23                                                        ;;
                                                                                  ;;
                                                                                  ;;
0640   DIV   r58, r20, r5                                                         ;;
0644   MUL   r57, r5, r58                                                         ;;
0648   NOR   r57, r57, r57                                                        ;;
064c   ADD   r23, r20, r57                                                        ;;
0650   MOVI  r57, 0x1                                                             ;;
0654   ADD   r23, r23, r57                                                        ;;
0658   LOAD  r23, BYTE [r4+r23]                                                   ;;
065c   ADD   r21, r21, r23                                                        ;;
                                                                                  ;;
; r21 &= 0xff                                                                     ;;
0660   MOVI  r57, 0xff                                                            ;;
0664   NOR   r57, r57, r57                                                        ;;
0668   NOR   r21, r21, r21                                                        ;;
066c   NOR   r21, r57, r21                                                        ;;
                                                                                  ;;
; key->s[r20], key->s[r21] = key->s[r21], key->s[r20]                             ;;
0670   LOAD  r23, BYTE [r22+r20]                                                  ;;
0674   LOAD  r24, BYTE [r22+r21]                                                  ;;
0678   STORE r24, BYTE [r22+r20]                                                  ;;
067c   STORE r23, BYTE [r22+r21]                                                  ;;
                                                                                  ;;
; r20++                                                                           ;;
0680   MOVI  r57, 0x1                                                             ;;
0684   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; r20 &= 0xff                                                                     ;;
0688   MOVI  r57, 0xff                                                            ;;
068c   NOR   r57, r57, r57                                                        ;;
0690   NOR   r20, r20, r20                                                        ;;
0694   NOR   r20, r57, r20                                                        ;;
                                                                                  ;;
; if r20 != 0:                                                                    ;;
;    GOTO 0x638                                                                   ;;
0698   MOVI  r57, 0x638                                                           ;;
069c   ADD   r57, r57, zero                                                         ;;
06a0   CMOV  pc, r57, r20                                                        ;;
                                                                                  ;;
; key->a = 0                                                                      ;;
; key->b = 0                                                                      ;;
06a4   STORE zero, BYTE [r3+zero]                                                     ;;
06a8   MOVI  r58, 0x1                                                             ;;
06ac   STORE zero, BYTE [r3+r58]                                                    ;;
                                                                                  ;;
; return                                                                          ;;
06b0   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


06b4   LOAD  r20, BYTE [r3+zero]
06b8   MOVI  r57, 0x1
06bc   LOAD  r21, BYTE [r3+r57]
06c0   MOVI  r57, 0x2
06c4   ADD   r24, r3, r57
06c8   MOVI  r57, 0x1
06cc   ADD   r20, r20, r57

; r20 &= 0xff
06d0   MOVI  r57, 0xff
06d4   NOR   r57, r57, r57
06d8   NOR   r20, r20, r20
06dc   NOR   r20, r57, r20

06e0   LOAD  r22, BYTE [r24+r20]
06e4   ADD   r21, r21, r22


; r21 &= 0xff
06e8   MOVI  r57, 0xff
06ec   NOR   r57, r57, r57
06f0   NOR   r21, r21, r21
06f4   NOR   r21, r57, r21


06f8   STORE r20, BYTE [r3+zero]
06fc   MOVI  r58, 0x1
0700   STORE r21, BYTE [r3+r58]
0704   LOAD  r22, BYTE [r24+r20]
0708   LOAD  r23, BYTE [r24+r21]
070c   STORE r23, BYTE [r24+r20]
0710   STORE r22, BYTE [r24+r21]
0714   ADD   r22, r22, r23

; r22 &= 0xff
0718   MOVI  r57, 0xff
071c   NOR   r57, r57, r57
0720   NOR   r22, r22, r22
0724   NOR   r22, r57, r22


0728   LOAD  r1, BYTE [r24+r22]
072c   ADD   pc, lr, zero




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;     typedef struct {                                                           ;;
;;         uint8_t a                                                              ;;
;;         uint8_t b                                                              ;;
;;         uint8_t s[256]                                                         ;;
;;     } rc4_key_t                                                                ;;
;;                                                                                ;;
;;     rc4_decrypt(rc4_key_t * key, char * data, size_t data_length)              ;;
;;                                                                                ;;
;;     Preconditions:                                                             ;;
;;        * r3  : unknown                                                         ;;
;;        * r4  : Points to password                                              ;;
;;        * r5  : Length of password                                              ;;
;;        * lr : Contains return address                                         ;;
;;     Postconditions:                                                            ;;
;;        * r1  :                                                                 ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
0730   MOVI  r57, 0x3                                                             ;;
0734   NOR   r57, r57, r57                                                        ;;
0738   ADD   sp, sp, r57                                                        ;;
073c   STORE lr, WORD [sp+zero]                                                   ;;
0740   ADD   r20, zero, zero                                                          ;;
0744   MOVI  r57, 0x7cc                                                           ;;
0748   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
                                                                                  ;;
074c   MOVI  r57, 0x3                                                             ;;
0750   NOR   r57, r57, r57                                                        ;;
0754   ADD   sp, sp, r57                                                        ;;
0758   STORE r3, WORD [sp+zero]                                                    ;;
075c   ADD   sp, sp, r57                                                        ;;
0760   STORE r4, WORD [sp+zero]                                                    ;;
0764   ADD   sp, sp, r57                                                        ;;
0768   STORE r5, WORD [sp+zero]                                                    ;;
076c   ADD   sp, sp, r57                                                        ;;
0770   STORE r20, WORD [sp+zero]                                                   ;;
0774   MOVI  r57, 0x8                                                             ;;
0778   ADD   lr, pc, r57                                                        ;;
077c   MOVI  r57, 0x6b4                                                           ;;
0780   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
                                                                                  ;;
0784   MOVI  r57, 0x4                                                             ;;
0788   LOAD  r20, WORD [sp+zero]                                                   ;;
078c   ADD   sp, sp, r57                                                        ;;
0790   LOAD  r5, WORD [sp+zero]                                                    ;;
0794   ADD   sp, sp, r57                                                        ;;
0798   LOAD  r4, WORD [sp+zero]                                                    ;;
079c   ADD   sp, sp, r57                                                        ;;
07a0   LOAD  r3, WORD [sp+zero]                                                    ;;
07a4   ADD   sp, sp, r57                                                        ;;
07a8   LOAD  r21, BYTE [r4+r20]                                                   ;;
07ac   NOR   r58, r21, r1                                                         ;;
07b0   NOR   r21, r58, r21                                                        ;;
07b4   NOR   r57, r58, r1                                                         ;;
07b8   NOR   r21, r21, r57                                                        ;;
07bc   NOR   r21, r21, r21                                                        ;;
07c0   STORE r21, BYTE [r4+r20]                                                   ;;
07c4   MOVI  r57, 0x1                                                             ;;
07c8   ADD   r20, r20, r57                                                        ;;
07cc   NOR   r57, r20, r20                                                        ;;
07d0   ADD   r21, r5, r57                                                         ;;
07d4   MOVI  r57, 0x1                                                             ;;
07d8   ADD   r21, r21, r57                                                        ;;
07dc   MOVI  r57, 0x74c                                                           ;;
07e0   ADD   r57, r57, zero                                                         ;;
07e4   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
                                                                                  ;;
07e8   MOVI  r57, 0x4                                                             ;;
07ec   LOAD  lr, WORD [sp+zero]                                                   ;;
07f0   ADD   sp, sp, r57                                                        ;;
07f4   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               Read line from stdin, substitute '\n' with '\0'                  ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Points to where to store string                       ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                  * r1  : Contains the length of the string                     ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;r20 = 0                                                                          ;;
07f8   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
;Read char                                                                        ;;
07fc   IN    r21                                                                  ;;
                                                                                  ;;
;r57 = 0                                                                          ;;
0800   NOR   r57, zero, zero                                                          ;;
0804   NOR   r57, r57, r57                                                        ;;
                                                                                  ;;
;r22 = char + 1                                                                   ;;
0808   ADD   r22, r21, r57                                                        ;;
080c   MOVI  r57, 0x1                                                             ;;
0810   ADD   r22, r22, r57                                                        ;;
                                                                                  ;;
;GOTO 0x828                                                                       ;;
0814   MOVI  r57, 0xc                                                             ;;
0818   ADD   r57, pc, r57                                                        ;;
                                                                                  ;;
081c   CMOV  pc, r57, r22                                                        ;;
                                                                                  ;;
;r22 = char - 10                                                                  ;;
;Test if char is '\n'                                                             ;;
0828   MOVI  r57, 0xa                                                             ;;
082c   NOR   r57, r57, r57                                                        ;;
0830   ADD   r22, r21, r57                                                        ;;
0834   MOVI  r57, 0x1                                                             ;;
0838   ADD   r22, r22, r57                                                        ;;
                                                                                  ;;
;if char != '\n':                                                                 ;;
;   GOTO 0x850                                                                    ;;
083c   MOVI  r57, 0xc                                                             ;;
0840   ADD   r57, pc, r57                                                        ;;
0844   CMOV  pc, r57, r22                                                        ;;
                                                                                  ;;
;Char is '\n'                                                                     ;;
;GOTO 0x864                                                                       ;;
0848   MOVI  r57, 0x864                                                           ;;
084c   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
;Char is not '\n'                                                                 ;;
0850   STORE r21, BYTE [r3+r20]                                                   ;;
0854   MOVI  r57, 0x1                                                             ;;
0858   ADD   r20, r20, r57                                                        ;;
085c   MOVI  r57, 0x7fc                                                           ;;
0860   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
;Store nul byte                                                                   ;;
0864   STORE zero, BYTE [r3+r20]                                                    ;;
0868   ADD   r1, r20, zero                                                          ;;
;Return to caller                                                                 ;;
086c   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               Write string to stdout                                           ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Points to string to output                            ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
;r20 = 0  ; Index into string to output                                           ;;
0870   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
;GOTO 0x888                                                                       ;;
0874   MOVI  r57, 0x888                                                           ;;
0878   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
;Output character in r21                                                          ;;
087c   OUT   r21                                                                  ;;
                                                                                  ;;
;Increment char string index                                                      ;;
0880   MOVI  r57, 0x1                                                             ;;
0884   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
;Load from memory next char into r21                                              ;;
0888   LOAD  r21, BYTE [r3+r20]                                                   ;;
                                                                                  ;;
;If we haven't reached end of string:                                             ;;
;   GOTO 0x87c                                                                    ;;
088c   MOVI  r57, 0x87c                                                           ;;
0890   ADD   r57, r57, zero                                                         ;;
0894   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
;End of string has been reached                                                   ;;
;So return                                                                        ;;
0898   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               memcmp(char * s1, char * s2, size_t n)                           ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Points to first address to compare                    ;;
;;                  * r4  : Points to second address to compare                   ;;
;;                  * r5  : Number of addresses to compare                        ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                  * r1  : Zero if the two regions were equal, otherwise the     ;;
;;                          difference between the last two bytes compared        ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
; r20 = 0   ; Index counter                                                       ;;
089c   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; GOTO 0x8d4                                                                      ;;
08a0   MOVI  r57, 0x8d4                                                           ;;
08a4   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; Load a byte from the two pointers at current index                              ;;
08a8   LOAD  r21, BYTE [r3+r20]                                                   ;;
08ac   LOAD  r22, BYTE [r4+r20]                                                   ;;
                                                                                  ;;
; r21 -= r22  ; Find difference                                                   ;;
08b0   NOR   r57, r22, r22                                                        ;;
08b4   ADD   r21, r21, r57                                                        ;;
08b8   MOVI  r57, 0x1                                                             ;;
08bc   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
; If the two bytes were different:                                                ;;
;    GOTO 0x8f0                                                                   ;;
08c0   MOVI  r57, 0x8f0                                                           ;;
08c4   ADD   r57, r57, zero                                                         ;;
08c8   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; r21 = len - counter                                                             ;;
08d4   NOR   r57, r20, r20                                                        ;;
08d8   ADD   r21, r5, r57                                                         ;;
08dc   MOVI  r57, 0x1                                                             ;;
08e0   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
; if r21 != 0:                                                                    ;;
;    GOTO 0x8a8                                                                   ;;
08e4   MOVI  r57, 0x8a8                                                           ;;
08e8   ADD   r57, r57, zero    ; Why? Stupid compiler??                             ;;
08ec   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Return difference of last two bytes                                             ;;
08f0   ADD   r1, r21, zero                                                          ;;
                                                                                  ;;
; Return                                                                          ;;
08f4   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               busywait(uint32_t loops)                                         ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Number of times to loop                               ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                                                                                ;;
;;               Does this:                                                       ;;
;;                                                                                ;;
;;               while (loops--) {}                                               ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                                                  ;;
; r20 = 0                                                                         ;;
08f8   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; GOTO 0x90c                                                                      ;;
08fc   MOVI  r57, 0x90c                                                           ;;
0900   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; r20++                                                                           ;;
0904   MOVI  r57, 0x1                                                             ;;
0908   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; r21 = r3 - r20                                                                  ;;
090c   NOR   r57, r20, r20                                                        ;;
0910   ADD   r21, r3, r57                                                         ;;
0914   MOVI  r57, 0x1                                                             ;;
0918   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
; if r21 != 0:                                                                    ;;
;    GOTO 0x904                                                                   ;;
091c   MOVI  r57, 0x904                                                           ;;
0920   ADD   r57, r57, zero                                                         ;;
0924   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Return                                                                          ;;
0928   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
