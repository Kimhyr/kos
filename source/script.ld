ENTRY(_start)

MEMORY
{
    BOOT(WX) : ORIGIN = 0x7c00, LENGTH = 0x0200
    FREE(RX) : ORIGIN = 0x7e00, LENGTH = 0x97E00
}

SECTIONS
{
    .boot :
    {
        *(.boot)
    } > BOOT
    
    .rodata : ALIGN(4)
    {
        *(.gdt)
        *(.rodata)
    } > FREE

    .text : ALIGN(4)
    {
        *(.text)
        *(.*)
    } > FREE

    .data : ALIGN(4)
    {
        *(.data)
    } > FREE

    .bss :
    {
        *(.bss)
    } > FREE
}
