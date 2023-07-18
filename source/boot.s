SECTION .boot
BITS 16

GLOBAL _start
_start: 
        ; Setup the Stack.
        mov     bp, $$
        mov     sp, bp

        ; Save the variables given when booted.
        mov     [boot_drive], dl ; The drive that was booted from.

        mov     si, booting_msg
        call    print

        ; Read the next sector following the boot sector into memory.
        mov     al, 0x01         ; Sectors,
        mov     ch, 0x00         ; cylinder,
        mov     cl, 0x02         ; start sector,
        mov     dh, 0x00         ; head,
        mov     dl, [boot_drive] ; disk,
        mov     bx, 0x00         ; output register, and
        mov     es, bx
        mov     bx, 0x7E00       ; output offset.
        call    read_disk

        mov     si, starting_bit32pm_msg
        call    print

        ; Since 32-bit protected mode code is going to start executing, we need
        ; to tell the CPU to ignore interrupts because 32-bit PM iterrupts are
        ; handled differently.
        cli

        ; Load the GDT and enable 32-bit protected mode.
        lgdt    [gdtr]
        mov     eax, cr0  ; (The cr0 register can't be accessed directly).
        or      eax, 0x01
        mov     cr0, eax

        ; Long jump to 32-bit code to flush the CPU pipeline.
        jmp     CODESEG:start_protected_mode

_end: 
        cli
        jmp     $

; Reads from the disk.
; Parameters:
;       al: number of sectors to read (1-128)
;       ch: cylinder number (0-1023)
;       cl: sector number (1-17)
;       dh: head number (0-15)
;       dl: drive number
;       es: segment buffer
;       bx: segment offset buffer
GLOBAL read_disk
read_disk: 
        pusha

        ; We push the number of sectors to read to later compare it with the
        ; actual number of sectors read.
        push    ax

        mov     ah, 0x02

        ; All parameters are set, so we can just simply call the disk service.
        int     0x13

        ; If an error occurred, the carry flag is set.
        jc      .error

        ; Check if we didn't read the requested amount of sectors.
        pop     bx
        cmp     bl, al ; Compare requested number with the actual number.
        jne     .error
        popa
        ret
.error:
        mov     si, disk_error_msg
        call    print
        jmp     _end

; Prints a string.
; Paramters:
;       si: string to print
GLOBAL print
print: 
        pusha
        mov     ah, 0x0E  ; Specify tty output function.
.put: 
        lodsb             ; Load a byte and increment the string ptr.
        test    al, al    ; Check if the loaded byte is null;
        jz      .end ; if so, stop printing.
        int     0x10      ; Tell the bios to print the byte.
        jmp     .put ; Repeat.
.end:
        mov     al, 0xa
        int     0x10
        mov     al, 0xd
        int     0x10
        popa
        ret

; Prints a hexadecimal.
; Parameters:
;     ax: number to print
GLOBAL print_hexadecimal
print_hexadecimal: 
        pusha

        ; Since we are using the stack to allocate a string of bytes
        ; representing digits, we first have to push the null terminator.
        push    WORD 0x00

        ; This counter is used for counting the number of words pushed on the
        ; stack, not the number of bytes.
        ; Its primary use is to later pop the string of bytes.
        mov     cx, 0x01
.loop: 

        ; We first get hexadecimal digit as an ascii character by using an
        ; array of ascii hexadecimal digits as a map.
        mov     bx, ax          ; Save the state of ax.
        and     bx, 0x0F        ; Get the lower 4 bits as the offset to the
                                ; corresponding ascii character.
        lea     si, [digit_map] ; Load the ascii digits.
        add     si, bx          ; Get the address of the ascii digit using the
                                ; offset.
        mov     bl, [si]        ; Get the ascii digit.
        pop     dx              ; Load the previously pushed word.
        test    dl, dl          ; Check if the previous digit is null.
        jz      .push_low

        ; There existed a previous digit which means the word in which the
        ; previous digit occupies is full.
        ; Therefore, we push back the word and create a new word with the
        ; current digit occupying the high byte.
        push    dx       ; Push back the full word.
        shl     bx, 0x08 ; Move the digit to the high byte.
        inc     cx       ; Increment the counter because a new word is
                         ; being created.
        jmp     .push
.push_low: 

        ; The previous word had null occupying the low byte.
        ; Therefore, we put the current digit in place of the low byte to fill
        ; the word.
        mov     bh, dh
.push: 
        push    bx       ; Concatenate the string of digits using the word.
        shr     ax, 0x04 ; Pop the bits that have been read.
        test    ax, ax   ; Check if there are no more bits to read.
        jnz     .loop

        ; Since the last word can have null occupying the low byte, we have to
        ; deduct the last byte.
        ; Otherwise, the string won't print because a null terminator occupies
        ; the first read byte.
        mov     si, sp ; Save the state of the stack ptr.
        pop     ax     ; Load the last word.
        test    al, al ; Check if the low byte is null.
        push    ax     ; Push back the word.
        jnz     .print

        ; The word had null in the low byte, so we increment the string pionter
        ; So that the null byte won't be read.
        inc     si
.print: 
        call    print ; Print the string.

        ; We now have a useless string pushed onto the stack.
        ; Since we counted the amount of words pushed onto the stack, we first
        ; multiply the counter by 2 to remove a each byte because a word is 2
        ; bytes.
        shl     cx, 0x01 ; Multiply the string by 2.
        add     sp, cx   ; Pop the string. popa
        ret

boot_drive          : db 0x00
digit_map           : db '0123456789ABCDEF'
booting_msg         : db 'Booting...', 0x00
disk_error_msg      : db 'Disk error!', 0x00
starting_bit32pm_msg: db 'Starting 32-bit protected mode...', 0x00

gdtr:
        dw gdt_end - gdt_start - 1 ; size
        dd gdt_start               ; offset

db 0x01FE - ($ - $$) dup 0
dw 0xAA55

SECTION .gdt
BITS 16

gdt_start:
        dd 0x00
        dd 0x00
gdt_codeseg:
        dw 0xffff     ; limit
        dw 0x00       ; base
        db 0x00       ; base
        db 0b10011010 ; access flags
        db 0b11001111 ; flags; limit
        db 0x00       ; base
gdt_dataseg:
        dw 0xffff     ; limit
        dw 0x00       ; base
        db 0x00       ; base
        db 0b10010010 ; access flags
        db 0b11001111 ; flags; limit
        db 0x00       ; base
gdt_end:

CODESEG equ gdt_codeseg - gdt_start
DATASEG equ gdt_dataseg - gdt_start

SECTION .text
BITS 32

start_protected_mode:
        ; Note that the code segment is automatically set due to performing a
        ; long jump to the `start_protected_mode` label.
        ;
        ; Now that we're in protected mode, our old 16-bit segments are
        ; meaningless.
        ; Therefore, we reset them to the data segment defined in the GDT.
        mov     ax, DATASEG
        mov     ds, ax
        mov     ss, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax

        ; Setup the Stack.
        mov     ebp, 0x09fc00 ; This address is the top of the free space
                              ; right above the boot sector.
        mov     esp, ebp

        mov     esi, bit32pm_msg
        call    vgaprint
        jmp     $

; Prints a string to the VGA textmode buffer.
; Parameters:
;       esi: string
vgaprint:
        pusha
        mov     ebx, 0x0b8000
        mov     ah, 0x0f
.put:
        lodsb
        test    al, al
        jz      .end
        mov     [ebx], ax
        add     ebx, 2
        jmp     .put
.end:
        popa
        ret

bit32pm_msg: db "Landed in 32-bit protected mode.", 0x00
