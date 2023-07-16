/* TODO: Worry about the heap. */

ENTRY(_start)

MEMORY
{
	iterrupt_vector_table(R) : ORIGIN = 0x0 , LENGTH = 0x400
	bios_data_area(R) : ORIGIN = 0x400, LENGTH = 0x100
	stack(WAI) : ORIGIN = 0x500, LENGTH = 0x7700
	boot_sector(WX) : ORIGIN = 0x7c00, LENGTH = 0x200
	free(RX) : ORIGIN = 0x7e00, LENGTH = 0x97e00
}

__stack_origin = 0x500;
__stack_size = 0x7700;

SECTIONS
{
	.boot_sector :
	{
		*(.boot_sector)
	} > boot_sector

	.text :
	{
		*(.text)
	} > free

	.rodata :
	{
		*(.rodata)
	} > free

	.data :
	{
		*(.data)
	} > free

	.bss :
	{
		*(COMMON)
		*(.bss)
	} > free
}
