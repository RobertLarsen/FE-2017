;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                           ;;
;; zero   = zero register                    ;;
;; r1   = return value from subrouting calls ;;
;; r3   = First arg to subroutine calls      ;;
;; r4   = Second arg to subroutine calls     ;;
;; r5   = Third arg to subroutine calls      ;;
;; r6   = Fourth arg to subroutine calls     ;;
;; lr  = Link register                       ;;
;; sp  = Stack register                      ;;
;; pc  = Program counter                     ;;
;;                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               Boot sector, bring in 11 sectors                                 ;;
;;               Preconditions:                                                   ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Remember where we are                                                           ;;
0000   ADD   r61, pc, zero                                                         ;;
0004   MOVI  r57, 0x4                                                             ;;
0008   NOR   r57, r57, r57                                                        ;;
000c   ADD   r61, r61, r57                                                        ;;
0010   MOVI  r57, 0x1                                                             ;;
0014   ADD   r61, r61, r57                                                        ;;
                                                                                  ;;
                                                                                  ;;
0018   MOVI  sp, 0x100000          ; Stack                                       ;;
001c   MOVI  r22, 0xb               ; Number of sectors to bring in               ;;
0020   MOVI  r20, 0x1               ; First sector                                ;;
0024   MOVI  r21, 0x200             ; Location in memory to put first sector      ;;
                                                                                  ;;
CHECK_FOR_MORE_SECTORS:                                                           ;;
; r23 = 0xb - r20                                                                 ;;
0028   NOR   r57, r20, r20                                                        ;;
002c   ADD   r23, r22, r57                                                        ;;
0030   MOVI  r57, 0x1                                                             ;;
0034   ADD   r23, r23, r57                                                        ;;
                                                                                  ;;
; If more sectors remain goto reading another one                                 ;;
; if (r23 != 0) GOTO LOAD_SECTOR                                                  ;;
0038   MOVI  r57, 0xc                                                             ;;
003c   ADD   r57, pc, r57                                                        ;;
0040   CMOV  pc, r57, r23  ; GOTO 0x4c                                           ;;
                                                                                  ;;
; else GOTO NO_MORE_SECTORS                                                       ;;
0044   MOVI  r57, 0x68                                                            ;;
0048   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
LOAD_SECTOR:                                                                      ;;
004c   READ  MEM[r21], DISK[r20]  ; Read sector r20 into memory at address r21    ;;
                                                                                  ;;
; r20++   (next sector index)                                                     ;;
0050   MOVI  r57, 0x1                                                             ;;
0054   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; r21 += 0x200    (next sector location)                                          ;;
0058   MOVI  r57, 0x200                                                           ;;
005c   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
; GOTO CHECK_FOR_MORE_SECTORS                                                     ;;
0060   MOVI  r57, 0x28                                                            ;;
0064   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NO_MORE_SECTORS:
;Allocate 0x100 bytes on the stack for reading string
0068   MOVI  r57, 0x100
006c   NOR   r57, r57, r57
0070   ADD   sp, sp, r57
0074   MOVI  r57, 0x1
0078   ADD   sp, sp, r57

; readline(buffer)
007c   ADD   r3, sp, zero    ; First argument is address of buffer
0080   MOVI  r57, 0x8
0084   ADD   lr, pc, r57  ; Setup link register
0088   MOVI  r57, 0x970
008c   ADD   pc, r57, zero   ; Make call to READ_LINE

; r10 = address of buffer
0090   ADD   r10, sp, zero

; Search for first space
; strchr(buffer, ' ')
0094   ADD   r3, r10, zero  ; First argument is address of buffer
0098   MOVI  r4, 0x20       ; Second argument is ' '
009c   MOVI  r57, 0x8       ; sizeof two instructions
00a0   ADD   lr, pc, r57    ; Setup link register
00a4   MOVI  r57, 0xba8     ; Address of strchr
00a8   ADD   pc, r57, zero  ; Make call

; if result is not null goto 0xc0
00ac   MOVI  r57, 0xc
00b0   ADD   r57, pc, r57
00b4   CMOV  pc, r57, r1

NULL:
; bad_request()
00b8   MOVI  r57, 0x6ac
00bc   ADD   pc, r57, zero

NOT_NULL:
00c0   ADD   r11, r1, zero        ; r11 <- pointer to first space in request
00c4   STORE zero, BYTE [r11+zero]  ; Replace first space with a null byte

; strcpy(0x1485, request_method)
00c8   MOVI  r3, 0x1485         ; Destination for where to copy request method
00cc   ADD   r4, r10, zero        ; Source argument points to request method
00d0   MOVI  r57, 0x8
00d4   ADD   lr, pc, r57      ; Setup link register
00d8   MOVI  r57, 0xb84
00dc   ADD   pc, r57, zero       ; Make call

; Make r10 point to request path (and http version)
00e0   MOVI  r57, 0x1
00e4   ADD   r10, r11, r57

; strchr(buffer, ' ')
00e8   ADD   r3, r10, zero      ; Request path + http version
00ec   MOVI  r4, 0x20         ; Search for a space character
00f0   MOVI  r57, 0x8
00f4   ADD   lr, pc, r57    ; Link register
00f8   MOVI  r57, 0xba8
00fc   ADD   pc, r57, zero     ; Make call

; If a match was found goto 0x114
0100   MOVI  r57, 0xc
0104   ADD   r57, pc, r57
0108   CMOV  pc, r57, r1

; No space was found
; bad_request()
010c   MOVI  r57, 0x6ac
0110   ADD   pc, r57, zero

; Space was found
; Store null byte at that location
0114   ADD   r11, r1, zero
0118   STORE zero, BYTE [r11+zero]

; strcpy(0x1495, request_path)
011c   MOVI  r3, 0x1495      ; request_path destination
0120   ADD   r4, r10, zero     ; Source for copy
0124   MOVI  r57, 0x8
0128   ADD   lr, pc, r57   ; Link register
012c   MOVI  r57, 0xb84
0130   ADD   pc, r57, zero    ; Make call


; At this point 0x1485 contains the request method and 0x1495 contains the request path


; find_last_and_null_out(request_path, '/')
0134   MOVI  r3, 0x1495       ; request_path
0138   MOVI  r4, 0x2f         ; '/'
013c   MOVI  r57, 0x8
0140   ADD   lr, pc, r57    ; Link register
0144   MOVI  r57, 0xacc
0148   ADD   pc, r57, zero     ; Make call

; Make r10 point to http version
014c   MOVI  r57, 0x1
0150   ADD   r10, r11, r57

; strchr(http_version, '\r')
0154   ADD   r3, r10, zero      ; http_version
0158   MOVI  r4, 0xd          ; '\r'
015c   MOVI  r57, 0x8
0160   ADD   lr, pc, r57    ; Link register
0164   MOVI  r57, 0xba8
0168   ADD   pc, r57, zero     ; Make call

; If a match was found goto 0x180
016c   MOVI  r57, 0xc
0170   ADD   r57, pc, r57
0174   CMOV  pc, r57, r1

; bad_request()
0178   MOVI  r57, 0x6ac
017c   ADD   pc, r57, zero

; Match was found
; Replace with null byte
0180   ADD   r11, r1, zero
0184   STORE zero, BYTE [r11+zero]

; strcpy(0x1515, http_version)
0188   MOVI  r3, 0x1515      ; http_version
018c   ADD   r4, r10, zero     ; Source for copy
0190   MOVI  r57, 0x8
0194   ADD   lr, pc, r57   ; Link register
0198   MOVI  r57, 0xb84
019c   ADD   pc, r57, zero    ; Make call


; strcmp(request_method, "GET")
01a0   MOVI  r3, 0x1485      ; request_method
01a4   MOVI  r4, 0xc78       ; "GET"
01a8   MOVI  r57, 0x8
01ac   ADD   lr, pc, r57   ; Link register
01b0   MOVI  r57, 0xb40
01b4   ADD   pc, r57, zero    ; Make call

; If not equal call unsupported_method()
01b8   MOVI  r57, 0x664
01bc   ADD   r57, r57, zero
01c0   CMOV  pc, r57, r1    ; Make call


; If only character of request path was a '/' it is now empty
; If not, goto 0x1e0
01c4   MOVI  r57, 0x1495          ; request_path
01c8   LOAD  r20, BYTE [r57+zero]
01cc   MOVI  r57, 0xc
01d0   ADD   r57, pc, r57
01d4   CMOV  pc, r57, r20

; Request path was "/"
; redirect()
01d8   MOVI  r57, 0x6f4
01dc   ADD   pc, r57, zero

; if (request_path[15] != 't')
;    goto 0x4b8
01e0   MOVI  r57, 0x14a4
01e4   LOAD  r20, BYTE [r57+zero]
01e8   MOVI  r57, 0x74
01ec   NOR   r57, r57, r57
01f0   ADD   r20, r20, r57
01f4   MOVI  r57, 0x1
01f8   ADD   r20, r20, r57
01fc   MOVI  r57, 0x4b8
0200   ADD   r57, r57, zero
0204   CMOV  pc, r57, r20

; if (request_path[0] != '/')
;    goto 0x4b8
0208   MOVI  r57, 0x1495
020c   LOAD  r20, BYTE [r57+zero]
0210   MOVI  r57, 0x2f
0214   NOR   r57, r57, r57
0218   ADD   r20, r20, r57
021c   MOVI  r57, 0x1
0220   ADD   r20, r20, r57
0224   MOVI  r57, 0x4b8
0228   ADD   r57, r57, zero
022c   CMOV  pc, r57, r20

; if (request_path[5] != 'r')
;    goto 0x4b8
0230   MOVI  r57, 0x149a
0234   LOAD  r20, BYTE [r57+zero]
0238   MOVI  r57, 0x72
023c   NOR   r57, r57, r57
0240   ADD   r20, r20, r57
0244   MOVI  r57, 0x1
0248   ADD   r20, r20, r57
024c   MOVI  r57, 0x4b8
0250   ADD   r57, r57, zero
0254   CMOV  pc, r57, r20

; if (request_path[13] != '.')
;    goto 0x4b8
0258   MOVI  r57, 0x14a2
025c   LOAD  r20, BYTE [r57+zero]
0260   MOVI  r57, 0x2e
0264   NOR   r57, r57, r57
0268   ADD   r20, r20, r57
026c   MOVI  r57, 0x1
0270   ADD   r20, r20, r57
0274   MOVI  r57, 0x4b8
0278   ADD   r57, r57, zero
027c   CMOV  pc, r57, r20


; if (request_path[2] != 'u')
;    goto 0x4b8
0280   MOVI  r57, 0x1497
0284   LOAD  r20, BYTE [r57+zero]
0288   MOVI  r57, 0x75
028c   NOR   r57, r57, r57
0290   ADD   r20, r20, r57
0294   MOVI  r57, 0x1
0298   ADD   r20, r20, r57
029c   MOVI  r57, 0x4b8
02a0   ADD   r57, r57, zero
02a4   CMOV  pc, r57, r20


; if (request_path[4] != 'e')
;    goto 0x4b8
02a8   MOVI  r57, 0x1499
02ac   LOAD  r20, BYTE [r57+zero]
02b0   MOVI  r57, 0x65
02b4   NOR   r57, r57, r57
02b8   ADD   r20, r20, r57
02bc   MOVI  r57, 0x1
02c0   ADD   r20, r20, r57
02c4   MOVI  r57, 0x4b8
02c8   ADD   r57, r57, zero
02cc   CMOV  pc, r57, r20


; if (request_path[17] != 'l')
;    goto 0x4b8
02d0   MOVI  r57, 0x14a6
02d4   LOAD  r20, BYTE [r57+zero]
02d8   MOVI  r57, 0x6c
02dc   NOR   r57, r57, r57
02e0   ADD   r20, r20, r57
02e4   MOVI  r57, 0x1
02e8   ADD   r20, r20, r57
02ec   MOVI  r57, 0x4b8
02f0   ADD   r57, r57, zero
02f4   CMOV  pc, r57, r20


; if (request_path[7] != 's')
;    goto 0x4b8
02f8   MOVI  r57, 0x149c
02fc   LOAD  r20, BYTE [r57+zero]
0300   MOVI  r57, 0x73
0304   NOR   r57, r57, r57
0308   ADD   r20, r20, r57
030c   MOVI  r57, 0x1
0310   ADD   r20, r20, r57
0314   MOVI  r57, 0x4b8
0318   ADD   r57, r57, zero
031c   CMOV  pc, r57, r20


; if (request_path[3] != 'p')
;    goto 0x4b8
0320   MOVI  r57, 0x1498
0324   LOAD  r20, BYTE [r57+zero]
0328   MOVI  r57, 0x70
032c   NOR   r57, r57, r57
0330   ADD   r20, r20, r57
0334   MOVI  r57, 0x1
0338   ADD   r20, r20, r57
033c   MOVI  r57, 0x4b8
0340   ADD   r57, r57, zero
0344   CMOV  pc, r57, r20


; if (request_path[9] != 'c')
;    goto 0x4b8
0348   MOVI  r57, 0x149e
034c   LOAD  r20, BYTE [r57+zero]
0350   MOVI  r57, 0x63
0354   NOR   r57, r57, r57
0358   ADD   r20, r20, r57
035c   MOVI  r57, 0x1
0360   ADD   r20, r20, r57
0364   MOVI  r57, 0x4b8
0368   ADD   r57, r57, zero
036c   CMOV  pc, r57, r20


; if (request_path[11] != 'e')
;    goto 0x4b8
0370   MOVI  r57, 0x14a0
0374   LOAD  r20, BYTE [r57+zero]
0378   MOVI  r57, 0x65
037c   NOR   r57, r57, r57
0380   ADD   r20, r20, r57
0384   MOVI  r57, 0x1
0388   ADD   r20, r20, r57
038c   MOVI  r57, 0x4b8
0390   ADD   r57, r57, zero
0394   CMOV  pc, r57, r20


; if (request_path[10] != 'r')
;    goto 0x4b8
0398   MOVI  r57, 0x149f
039c   LOAD  r20, BYTE [r57+zero]
03a0   MOVI  r57, 0x72
03a4   NOR   r57, r57, r57
03a8   ADD   r20, r20, r57
03ac   MOVI  r57, 0x1
03b0   ADD   r20, r20, r57
03b4   MOVI  r57, 0x4b8
03b8   ADD   r57, r57, zero
03bc   CMOV  pc, r57, r20


; if (request_path[12] != 't')
;    goto 0x4b8
03c0   MOVI  r57, 0x14a1
03c4   LOAD  r20, BYTE [r57+zero]
03c8   MOVI  r57, 0x74
03cc   NOR   r57, r57, r57
03d0   ADD   r20, r20, r57
03d4   MOVI  r57, 0x1
03d8   ADD   r20, r20, r57
03dc   MOVI  r57, 0x4b8
03e0   ADD   r57, r57, zero
03e4   CMOV  pc, r57, r20



03e8   MOVI  r57, 0x14a5
03ec   LOAD  r20, BYTE [r57+zero]
03f0   MOVI  r57, 0x6d
03f4   NOR   r57, r57, r57
03f8   ADD   r20, r20, r57
03fc   MOVI  r57, 0x1
0400   ADD   r20, r20, r57
0404   MOVI  r57, 0x4b8
0408   ADD   r57, r57, zero
040c   CMOV  pc, r57, r20


0410   MOVI  r57, 0x149b
0414   LOAD  r20, BYTE [r57+zero]
0418   MOVI  r57, 0x5f
041c   NOR   r57, r57, r57
0420   ADD   r20, r20, r57
0424   MOVI  r57, 0x1
0428   ADD   r20, r20, r57
042c   MOVI  r57, 0x4b8
0430   ADD   r57, r57, zero
0434   CMOV  pc, r57, r20


0438   MOVI  r57, 0x14a3
043c   LOAD  r20, BYTE [r57+zero]
0440   MOVI  r57, 0x68
0444   NOR   r57, r57, r57
0448   ADD   r20, r20, r57
044c   MOVI  r57, 0x1
0450   ADD   r20, r20, r57
0454   MOVI  r57, 0x4b8
0458   ADD   r57, r57, zero
045c   CMOV  pc, r57, r20


0460   MOVI  r57, 0x149d
0464   LOAD  r20, BYTE [r57+zero]
0468   MOVI  r57, 0x65
046c   NOR   r57, r57, r57
0470   ADD   r20, r20, r57
0474   MOVI  r57, 0x1
0478   ADD   r20, r20, r57
047c   MOVI  r57, 0x4b8
0480   ADD   r57, r57, zero
0484   CMOV  pc, r57, r20


0488   MOVI  r57, 0x1496
048c   LOAD  r20, BYTE [r57+zero]
0490   MOVI  r57, 0x73
0494   NOR   r57, r57, r57
0498   ADD   r20, r20, r57
049c   MOVI  r57, 0x1
04a0   ADD   r20, r20, r57
04a4   MOVI  r57, 0x4b8
04a8   ADD   r57, r57, zero
04ac   CMOV  pc, r57, r20

04b0   MOVI  r57, 0x5c0
04b4   ADD   pc, r57, zero


; request_path[15] != 't' || request_path[0] != '/'
04b8   MOVI  r57, 0x4c0
04bc   ADD   pc, r57, zero


04c0   ADD   r10, zero, zero
04c4   MOVI  r57, 0x12bc
04c8   LOAD  r20, WORD [r10+r57]
04cc   MOVI  r57, 0xc
04d0   ADD   r57, pc, r57
04d4   CMOV  pc, r57, r20
04d8   MOVI  r57, 0x578
04dc   ADD   pc, r57, zero

; strcmp(?, request_path)
04e0   ADD   r3, r20, zero
04e4   MOVI  r4, 0x1495          ; request_path
04e8   MOVI  r57, 0x8
04ec   ADD   lr, pc, r57       ; Link register
04f0   MOVI  r57, 0xb40
04f4   ADD   pc, r57, zero        ; Make call


04f8   MOVI  r57, 0xc
04fc   ADD   r57, pc, r57
0500   CMOV  pc, r57, r1
0504   MOVI  r57, 0x51c
0508   ADD   pc, r57, zero


050c   MOVI  r57, 0x10
0510   ADD   r10, r10, r57
0514   MOVI  r57, 0x4c4
0518   ADD   pc, r57, zero


051c   MOVI  r3, 0xc8
0520   MOVI  r4, 0xccc
0524   MOVI  r57, 0x12c0
0528   LOAD  r5, WORD [r10+r57]
052c   MOVI  r57, 0x12c4
0530   LOAD  r6, WORD [r10+r57]
0534   MOVI  r57, 0x8
0538   ADD   lr, pc, r57
053c   MOVI  r57, 0x750
0540   ADD   pc, r57, zero


0544   MOVI  r57, 0xd
0548   OUT   r57
054c   MOVI  r57, 0xa
0550   OUT   r57
0554   MOVI  r57, 0x12c8
0558   LOAD  r3, WORD [r10+r57]
055c   MOVI  r57, 0x12c4
0560   LOAD  r4, WORD [r10+r57]
0564   MOVI  r57, 0x8
0568   ADD   lr, pc, r57
056c   MOVI  r57, 0x8b8
0570   ADD   pc, r57, zero


0574   HALT
0578   MOVI  r3, 0x194
057c   MOVI  r4, 0xec8
0580   MOVI  r5, 0x1425
0584   MOVI  r6, 0xcb
0588   MOVI  r57, 0x8
058c   ADD   lr, pc, r57
0590   MOVI  r57, 0x750
0594   ADD   pc, r57, zero


0598   MOVI  r57, 0xd
059c   OUT   r57
05a0   MOVI  r57, 0xa
05a4   OUT   r57

; putstring("404 not found") ..html
05a8   MOVI  r3, 0xed2
05ac   MOVI  r57, 0x8
05b0   ADD   lr, pc, r57
05b4   MOVI  r57, 0x9e8
05b8   ADD   pc, r57, zero

05bc   HALT



05c0   MOVI  r3, 0x539
05c4   MOVI  r4, 0x105b
05c8   MOVI  r5, 0x1425
05cc   MOVI  r6, 0x25a
05d0   MOVI  r57, 0x8
05d4   ADD   lr, pc, r57
05d8   MOVI  r57, 0x750
05dc   ADD   pc, r57, zero

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               unsupported_request_method()                                     ;;
;;               Writes an unsupported request method response and halts          ;;
;;               Preconditions:                                                   ;;
;;               Postconditions:                                                  ;;
;;                  * Machine halts                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UNSUPPOTED_REQUEST_METHOD:                                                        ;;
0664   MOVI  r3, 0x1f5                                                            ;;
0668   MOVI  r4, 0xf9d                                                            ;;
066c   MOVI  r5, 0x1425                                                           ;;
0670   MOVI  r6, 0xa7                                                             ;;
0674   MOVI  r57, 0x8                                                             ;;
0678   ADD   lr, pc, r57                                                        ;;
067c   MOVI  r57, 0x750                                                           ;;
0680   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; output "\r\n"                                                                   ;;
0684   MOVI  r57, 0xd                                                             ;;
0688   OUT   r57                                                                  ;;
068c   MOVI  r57, 0xa                                                             ;;
0690   OUT   r57                                                                  ;;
                                                                                  ;;
; putstring(0xfb4)  - "Method not implemented" html                               ;;
0694   MOVI  r3, 0xfb4                                                            ;;
0698   MOVI  r57, 0x8                                                             ;;
069c   ADD   lr, pc, r57                                                        ;;
06a0   MOVI  r57, 0x9e8                                                           ;;
06a4   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
                                                                                  ;;
06a8   HALT                                                                       ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               bad_request()                                                    ;;
;;               Writes a bad request response and halts                          ;;
;;               Preconditions:                                                   ;;
;;               Postconditions:                                                  ;;
;;                  * Machine halts                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BAD_REQUEST:                                                                      ;;
06ac   MOVI  r3, 0x190                                                            ;;
06b0   MOVI  r4, 0xdcf                                                            ;;
06b4   MOVI  r5, 0x1425                                                           ;;
06b8   MOVI  r6, 0xe2                                                             ;;
06bc   MOVI  r57, 0x8                                                             ;;
06c0   ADD   lr, pc, r57                                                        ;;
06c4   MOVI  r57, 0x750                                                           ;;
06c8   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; Output '\r\n'                                                                   ;;
06cc   MOVI  r57, 0xd                                                             ;;
06d0   OUT   r57                                                                  ;;
06d4   MOVI  r57, 0xa                                                             ;;
06d8   OUT   r57                                                                  ;;
                                                                                  ;;
; putstring(0xde6)  - "Bad request" html                                          ;;
06dc   MOVI  r3, 0xde6                                                            ;;
06e0   MOVI  r57, 0x8                                                             ;;
06e4   ADD   lr, pc, r57                                                        ;;
06e8   MOVI  r57, 0x9e8                                                           ;;
06ec   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
06f0   HALT                                                                       ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               redirect()                                                       ;;
;;               Writes a redirect response and halts                             ;;
;;               Preconditions:                                                   ;;
;;               Postconditions:                                                  ;;
;;                  * Machine halts                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
06f4   MOVI  r3, 0x12e                                                            ;;
06f8   MOVI  r4, 0xccf                                                            ;;
06fc   MOVI  r5, 0x1425                                                           ;;
0700   MOVI  r6, 0xd4                                                             ;;
0704   MOVI  r57, 0x8                                                             ;;
0708   ADD   lr, pc, r57                                                        ;;
070c   MOVI  r57, 0x750                                                           ;;
0710   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; putstr("Location: http://localhost/index.html")                                 ;;
0714   MOVI  r3, 0xcd5                                                            ;;
0718   MOVI  r57, 0x8                                                             ;;
071c   ADD   lr, pc, r57                                                        ;;
0720   MOVI  r57, 0x9e8                                                           ;;
0724   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; Print "\r\n"                                                                    ;;
0728   MOVI  r57, 0xd                                                             ;;
072c   OUT   r57                                                                  ;;
0730   MOVI  r57, 0xa                                                             ;;
0734   OUT   r57                                                                  ;;
                                                                                  ;;
; putstr("The document has moved...") html                                        ;;
0738   MOVI  r3, 0xcfb                                                            ;;
073c   MOVI  r57, 0x8                                                             ;;
0740   ADD   lr, pc, r57                                                        ;;
0744   MOVI  r57, 0x9e8                                                           ;;
0748   ADD   pc, r57, zero                                                         ;;
074c   HALT                                                                       ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;                                                                                ;;
;;               Preconditions:                                                   ;;
;;                  * r3  :                                                       ;;
;;                  * r4  :                                                       ;;
;;                  * r5  :                                                       ;;
;;                  * r6  :                                                       ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                  * r1  : Pointer in string to first occurence of character     ;;
;;                          Null if character is not found                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; r57 = -4
0750   MOVI  r57, 0x3
0754   NOR   r57, r57, r57

; PUSH link register
0758   ADD   sp, sp, r57
075c   STORE lr, WORD [sp+zero]

; PUSH r10
0760   ADD   sp, sp, r57
0764   STORE r10, WORD [sp+zero]

; PUSH r11
0768   ADD   sp, sp, r57
076c   STORE r11, WORD [sp+zero]

; PUSH r12
0770   ADD   sp, sp, r57
0774   STORE r12, WORD [sp+zero]

; PUSH r13
0778   ADD   sp, sp, r57
077c   STORE r13, WORD [sp+zero]

; Allocate 10 bytes on stack
0780   MOVI  r57, 0x10
0784   NOR   r57, r57, r57
0788   ADD   sp, sp, r57
078c   MOVI  r57, 0x1
0790   ADD   sp, sp, r57

; Copy arguments r3-r6 into r10-r13
0794   ADD   r10, r3, zero
0798   ADD   r11, r4, zero
079c   ADD   r12, r5, zero
07a0   ADD   r13, r6, zero


07a4   MOVI  r3, 0x1515     ; http_version
07a8   MOVI  r57, 0x8
07ac   ADD   lr, pc, r57
07b0   MOVI  r57, 0x9e8
07b4   ADD   pc, r57, zero


07b8   MOVI  r57, 0x20
07bc   OUT   r57
07c0   ADD   r3, sp, zero
07c4   ADD   r4, r10, zero
07c8   MOVI  r57, 0x8
07cc   ADD   lr, pc, r57
07d0   MOVI  r57, 0xa14
07d4   ADD   pc, r57, zero


07d8   ADD   r3, sp, zero
07dc   MOVI  r57, 0x8
07e0   ADD   lr, pc, r57
07e4   MOVI  r57, 0x9e8
07e8   ADD   pc, r57, zero


07ec   MOVI  r57, 0x20
07f0   OUT   r57
07f4   ADD   r3, r11, zero
07f8   MOVI  r57, 0x8
07fc   ADD   lr, pc, r57
0800   MOVI  r57, 0x9e8
0804   ADD   pc, r57, zero


0808   MOVI  r3, 0xc7e
080c   MOVI  r57, 0x8
0810   ADD   lr, pc, r57
0814   MOVI  r57, 0x9e8
0818   ADD   pc, r57, zero


081c   ADD   r3, r12, zero
0820   MOVI  r57, 0x8
0824   ADD   lr, pc, r57
0828   MOVI  r57, 0x9e8
082c   ADD   pc, r57, zero


0830   MOVI  r3, 0xcb9
0834   MOVI  r57, 0x8
0838   ADD   lr, pc, r57
083c   MOVI  r57, 0x9e8
0840   ADD   pc, r57, zero


0844   ADD   r3, sp, zero
0848   ADD   r4, r13, zero
084c   MOVI  r57, 0x8
0850   ADD   lr, pc, r57
0854   MOVI  r57, 0xa14
0858   ADD   pc, r57, zero


085c   ADD   r3, sp, zero
0860   MOVI  r57, 0x8
0864   ADD   lr, pc, r57
0868   MOVI  r57, 0x9e8
086c   ADD   pc, r57, zero


0870   MOVI  r57, 0xd
0874   OUT   r57
0878   MOVI  r57, 0xa
087c   OUT   r57
0880   MOVI  r57, 0x10
0884   ADD   sp, sp, r57
0888   MOVI  r57, 0x4
088c   LOAD  r13, WORD [sp+zero]
0890   ADD   sp, sp, r57
0894   LOAD  r12, WORD [sp+zero]
0898   ADD   sp, sp, r57
089c   LOAD  r11, WORD [sp+zero]
08a0   ADD   sp, sp, r57
08a4   LOAD  r10, WORD [sp+zero]
08a8   ADD   sp, sp, r57
08ac   LOAD  lr, WORD [sp+zero]
08b0   ADD   sp, sp, r57
08b4   ADD   pc, lr, zero
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




08b8   MOVI  r57, 0x3
08bc   NOR   r57, r57, r57
08c0   ADD   sp, sp, r57
08c4   STORE r60, WORD [sp+zero]
08c8   ADD   r60, sp, zero
08cc   MOVI  r57, 0xffe00
08d0   NOR   r57, r57, r57
08d4   NOR   sp, sp, sp
08d8   NOR   sp, r57, sp
08dc   MOVI  r57, 0x200
08e0   NOR   r57, r57, r57
08e4   ADD   sp, sp, r57
08e8   MOVI  r57, 0x1
08ec   ADD   sp, sp, r57
08f0   ADD   r20, zero, zero
08f4   MOVI  r57, 0x1ff
08f8   NOR   r57, r57, r57
08fc   NOR   r21, r20, r20
0900   NOR   r21, r57, r21
0904   MOVI  r57, 0x920
0908   ADD   r57, r57, zero
090c   CMOV  pc, r57, r21
0910   ADD   r21, r20, r3
0914   MOVI  r57, 0x200
0918   DIV   r21, r21, r57
091c   READ  MEM[sp], DISK[r21]
0920   MOVI  r57, 0x1ff
0924   NOR   r57, r57, r57
0928   NOR   r21, r20, r20
092c   NOR   r21, r57, r21
0930   LOAD  r21, BYTE [sp+r21]
0934   OUT   r21
0938   MOVI  r57, 0x1
093c   ADD   r20, r20, r57
0940   NOR   r57, r4, r4
0944   ADD   r21, r20, r57
0948   MOVI  r57, 0x1
094c   ADD   r21, r21, r57
0950   MOVI  r57, 0x8f4
0954   ADD   r57, r57, zero
0958   CMOV  pc, r57, r21
095c   ADD   sp, r60, zero
0960   MOVI  r57, 0x4
0964   LOAD  r60, WORD [sp+zero]
0968   ADD   sp, sp, r57
096c   ADD   pc, lr, zero



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
READ_LINE:																		  ;;
; r20 = 0                                                                         ;;
0970   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
READ_NEXT_CHARACTER:                                                              ;;
; read character                                                                  ;;
0974   IN    r21                                                                  ;;
                                                                                  ;;
; ?? After these two, r57 will be 0                                               ;;
0978   NOR   r57, zero, zero                                                          ;;
097c   NOR   r57, r57, r57                                                        ;;
                                                                                  ;;
; if (read_character != -1) GOTO 0x9a0                                            ;;
0980   ADD   r22, r21, r57                                                        ;;
0984   MOVI  r57, 0x1                                                             ;;
0988   ADD   r22, r22, r57                                                        ;;
098c   MOVI  r57, 0xc                                                             ;;
0990   ADD   r57, pc, r57                                                        ;;
0994   CMOV  pc, r57, r22                                                        ;;
                                                                                  ;;
NOT_NEGATIVE_ONE:                                                                 ;;
; if (read_character != '\n') GOTO CHAR_IS_NOT_NEWLINE                            ;;
09a0   MOVI  r57, 0xa                                                             ;;
09a4   NOR   r57, r57, r57                                                        ;;
09a8   ADD   r22, r21, r57                                                        ;;
09ac   MOVI  r57, 0x1                                                             ;;
09b0   ADD   r22, r22, r57                                                        ;;
09b4   MOVI  r57, 0xc                                                             ;;
09b8   ADD   r57, pc, r57                                                        ;;
09bc   CMOV  pc, r57, r22                                                        ;;
                                                                                  ;;
CHAR_IS_NEWLINE:                                                                  ;;
09c0   MOVI  r57, 0x9dc                                                           ;;
09c4   ADD   pc, r57, zero   ; GOTO READ_LINE_END                                  ;;
09c8   STORE r21, BYTE [r3+r20]                                                   ;;
                                                                                  ;;
CHAR_IS_NOT_NEWLINE:                                                              ;;
09c8   STORE r21, BYTE [r3+r20] ; Store character at end of buffer                ;;
09cc   MOVI  r57, 0x1                                                             ;;
09d0   ADD   r20, r20, r57      ; Increment string length counter                 ;;
09d4   MOVI  r57, 0x974                                                           ;;
09d8   ADD   pc, r57, zero       ; GOTO READ_NEXT_CHARACTER                        ;;
                                                                                  ;;
READ_LINE_END:                                                                    ;;
;Store null byte at r3+r20                                                        ;;
09dc   STORE zero, BYTE [r3+r20]                                                    ;;
                                                                                  ;;
;return length of read string                                                     ;;
09e0   ADD   r1, r20, zero                                                          ;;
09e4   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               putstr(char * str)                                               ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Null terminated string to output                      ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; r20 = 0                                                                         ;;
09e8   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; Go reading first byte                                                           ;;
09ec   MOVI  r57, 0xa00                                                           ;;
09f0   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; r20++                                                                           ;;
09f4   OUT   r21                                                                  ;;
09f8   MOVI  r57, 0x1                                                             ;;
09fc   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; r21 = first[r20]                                                                ;;
0a00   LOAD  r21, BYTE [r3+r20]                                                   ;;
                                                                                  ;;
; if not null byte goto 0x9fc                                                     ;;
0a04   MOVI  r57, 0x9f4                                                           ;;
0a08   ADD   r57, r57, zero                                                         ;;
0a0c   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Return                                                                          ;;
0a10   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

0a14   ADD   r20, zero, zero
0a18   MOVI  r57, 0xa38
0a1c   ADD   r57, r57, zero
0a20   CMOV  pc, r57, r4
0a38   MOVI  r57, 0xa
0a3c   DIV   r58, r4, r57
0a40   MUL   r57, r57, r58
0a44   NOR   r57, r57, r57
0a48   ADD   r22, r4, r57
0a4c   MOVI  r57, 0x1
0a50   ADD   r22, r22, r57
0a54   MOVI  r57, 0xa
0a58   DIV   r4, r4, r57
0a5c   MOVI  r57, 0x30
0a60   ADD   r22, r22, r57
0a64   MOVI  r57, 0x3
0a68   NOR   r57, r57, r57
0a6c   ADD   sp, sp, r57
0a70   STORE r22, WORD [sp+zero]
0a74   MOVI  r57, 0x1
0a78   ADD   r20, r20, r57
0a7c   MOVI  r57, 0xa38
0a80   ADD   r57, r57, zero
0a84   CMOV  pc, r57, r4
0a88   ADD   r21, zero, zero
0a8c   MOVI  r57, 0x4
0a90   LOAD  r22, WORD [sp+zero]
0a94   ADD   sp, sp, r57
0a98   STORE r22, BYTE [r3+r21]
0a9c   MOVI  r57, 0x1
0aa0   ADD   r21, r21, r57
0aa4   NOR   r57, r20, r20
0aa8   ADD   r22, r21, r57
0aac   MOVI  r57, 0x1
0ab0   ADD   r22, r22, r57
0ab4   MOVI  r57, 0xa8c
0ab8   ADD   r57, r57, zero
0abc   CMOV  pc, r57, r22
0ac0   STORE zero, BYTE [r3+r20]
0ac4   ADD   r1, r20, zero
0ac8   ADD   pc, lr, zero

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               find_last_and_null_out(char * str, char needle)                  ;;
;;               Find last occurence of 'needle' in 'str' and replace it with     ;;
;;               a null byte                                                      ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : String pointer                                        ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initialize counter                                                              ;;
0acc   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; Jump to condition                                                               ;;
0ad0   MOVI  r57, 0xae0                                                           ;;
0ad4   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; counter++                                                                       ;;
0ad8   MOVI  r57, 0x1                                                             ;;
0adc   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; r21 = str[counter]                                                              ;;
0ae0   LOAD  r21, BYTE [r3+r20]                                                   ;;
                                                                                  ;;
; if (str[counter] != 0) goto 0xad8                                               ;;
0ae4   MOVI  r57, 0xad8                                                           ;;
0ae8   ADD   r57, r57, zero                                                         ;;
0aec   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Null byte found, goto 0xb30                                                     ;;
0af0   MOVI  r57, 0xb30                                                           ;;
0af4   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
; counter--                                                                       ;;
0af8   MOVI  r57, 0x1                                                             ;;
0afc   NOR   r57, r57, r57                                                        ;;
0b00   ADD   r20, r20, r57                                                        ;;
0b04   MOVI  r57, 0x1                                                             ;;
0b08   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; if (str[counter] == r4) {                                                       ;;
;     str[counter] = 0;                                                           ;;
;     return;                                                                     ;;
; }                                                                               ;;
0b0c   LOAD  r21, BYTE [r3+r20]                                                   ;;
0b10   NOR   r57, r4, r4                                                          ;;
0b14   ADD   r21, r21, r57                                                        ;;
0b18   MOVI  r57, 0x1                                                             ;;
0b1c   ADD   r21, r21, r57                                                        ;;
0b20   MOVI  r57, 0xb3c                                                           ;;
0b24   ADD   r57, r57, zero                                                         ;;
0b28   CMOV  pc, r57, r21                                                        ;;
0b2c   STORE zero, BYTE [r3+r20]                                                    ;;
                                                                                  ;;
; while (counter != 0) goto 0xaf8                                                 ;;
0b30   MOVI  r57, 0xaf8                                                           ;;
0b34   ADD   r57, r57, zero                                                         ;;
0b38   CMOV  pc, r57, r20                                                        ;;
                                                                                  ;;
; Return                                                                          ;;
0b3c   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               strcmp(char * s1, char * s2)                                     ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : First string to compare                               ;;
;;                  * r4  : Second string to compare                              ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                  * r1  : Difference between last two characters                ;;
;;                          which is zero if the two strings were equal           ;;
;;                                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initialize counter                                                              ;;
0b40   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; r21 = s1[counter] - s2[counter]                                                 ;;
0b44   LOAD  r21, BYTE [r3+r20]                                                   ;;
0b48   LOAD  r22, BYTE [r4+r20]                                                   ;;
0b4c   NOR   r57, r22, r22                                                        ;;
0b50   ADD   r21, r21, r57                                                        ;;
0b54   MOVI  r57, 0x1                                                             ;;
0b58   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
; If the two chars were different, goto 0xb7c                                     ;;
0b5c   MOVI  r57, 0xb7c                                                           ;;
0b60   ADD   r57, r57, zero                                                         ;;
0b64   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; counter++                                                                       ;;
0b68   MOVI  r57, 0x1                                                             ;;
0b6c   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; Repeat unless we have reached a null byte                                       ;;
0b70   MOVI  r57, 0xb44                                                           ;;
0b74   ADD   r57, r57, zero                                                         ;;
0b78   CMOV  pc, r57, r22                                                        ;;
                                                                                  ;;
; Return the difference between the last two characters (0 if they were the same) ;;
0b7c   ADD   r1, r21, zero                                                          ;;
0b80   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               strcpy(char * dst, char * src)                                   ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Destination for copy                                  ;;
;;                  * r4  : Source for copy                                       ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initialize counter                                                              ;;
0b84   ADD   r20, zero, zero                                                          ;;
                                                                                  ;;
; arg1[counter] = arg2[counter]                                                   ;;
0b88   LOAD  r21, BYTE [r4+r20] ; Load from second arg                            ;;
0b8c   STORE r21, BYTE [r3+r20] ; Store to first arg                              ;;
                                                                                  ;;
; counter++                                                                       ;;
0b90   MOVI  r57, 0x1                                                             ;;
0b94   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; if current character is not null...repeat                                       ;;
0b98   MOVI  r57, 0xb88                                                           ;;
0b9c   ADD   r57, r57, zero                                                         ;;
0ba0   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Return                                                                          ;;
0ba4   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                ;;
;;               strchr(char * str, char c)                                       ;;
;;               Preconditions:                                                   ;;
;;                  * r3  : Points to string to search                            ;;
;;                  * r4  : Character to search for                               ;;
;;                  * lr : Contains return address                               ;;
;;               Postconditions:                                                  ;;
;;                  * r1  : Pointer in string to first occurence of character     ;;
;;                          Null if character is not found                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STRCHR:                                                                           ;;
; r20 = -1                                                                        ;;
0ba8   NOR   r20, zero, zero                                                          ;;
                                                                                  ;;
NEXT_CHAR:                                                                        ;;
; r20++                                                                           ;;
0bac   MOVI  r57, 0x1                                                             ;;
0bb0   ADD   r20, r20, r57                                                        ;;
                                                                                  ;;
; Load indexed byte from buffer into r21                                          ;;
0bb4   LOAD  r21, BYTE [r3+r20]                                                   ;;
                                                                                  ;;
; if indexed byte is not a null byte goto 0xbcc                                   ;;
0bb8   MOVI  r57, 0xc                                                             ;;
0bbc   ADD   r57, pc, r57                                                        ;;
0bc0   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Is null so goto NULL_RESULT                                                     ;;
0bc4   MOVI  r57, 0xbf0                                                           ;;
0bc8   ADD   pc, r57, zero                                                         ;;
                                                                                  ;;
NOT_NULL:                                                                         ;;
; r21 = read char - r4                                                            ;;
0bcc   NOR   r57, r4, r4                                                          ;;
0bd0   ADD   r21, r21, r57                                                        ;;
0bd4   MOVI  r57, 0x1                                                             ;;
0bd8   ADD   r21, r21, r57                                                        ;;
                                                                                  ;;
; if (read_char != r4) goto NEXT_CHAR                                             ;;
0bdc   MOVI  r57, 0xbac                                                           ;;
0be0   ADD   r57, r57, zero                                                         ;;
0be4   CMOV  pc, r57, r21                                                        ;;
                                                                                  ;;
; Return address of character                                                     ;;
0be8   ADD   r1, r3, r20                                                          ;;
0bec   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
NULL_RESULT:                                                                      ;;
; Return null                                                                     ;;
0bf0   ADD   r1, zero, zero                                                           ;;
0bf4   ADD   pc, lr, zero                                                         ;;
                                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
