.code16
.att_syntax

.global _start

_start:
    
   
#Инициализация адресов сегментов. Эти операции требуется не для любого BIOS, но их рекомендуется проводить.

	mov %cs, %ax # Сохранение адреса сегмента кода в ax
	mov %ax, %ds # Сохранение этого адреса как начало сегмента данных
	mov %ax, %ss # И сегмента стека
	mov _start, %sp # Сохранение адреса стека как адрес первой инструкции этого кода. Стек будет расти вверх и не перекроет код.
	
	call clearing_the_screen
		
	jmp yellow

	
while: # метка
	
  	mov $0x00, %ah # считывание, установка текстового режима терминала
	int $0x16
	
  	cmp $0x0d, %al
  	je exit

  	cmp $'w', %al
  	je next

  	cmp $'s', %al 
  	je prev

  	jmp while  # если ни вверх, ни вниз

  next:
        cmp $0, %bx  
        je red
        
        cmp $1, %bx 
        je gray

        cmp $2, %bx 
        je blue

        cmp $3, %bx 
        je yellow

        cmp $4, %bx
        je white

        cmp $5, %bx 
        je green

  prev:
        cmp $0, %bx  
        je white

        cmp $1, %bx
        je green

        cmp $2, %bx
        je red

        cmp $3, %bx
        je gray

        cmp $4, %bx
        je blue

        cmp $5, %bx
        je yellow

  red:
  	call clearing_the_screen
  	mov $1, %bx
	mov $0x0e, %ah
	mov $'r', %al
	int $0x10 
	mov $'e', %al
	int $0x10
	mov $'d', %al
	int $0x10
	movb $0x04, 0x467
        jmp while
  gray:
  	call clearing_the_screen
  	mov $2, %bx	
	mov $0x0e, %ah
        mov $'g', %al
	int $0x10
	mov $'r', %al
	int $0x10
	mov $'a', %al
	int $0x10
	mov $'y', %al
	int $0x10
	movb $0x08, 0x467
        jmp while
  blue:
  	call clearing_the_screen	
  	mov $3, %bx
	mov $0x0e, %ah
        mov $'b', %al
	int $0x10
	mov $'l', %al
	int $0x10
	mov $'u', %al
	int $0x10
	mov $'e', %al
	int $0x10
	movb $0x09, 0x467
        jmp while
  yellow:
     	call clearing_the_screen
     	mov $4, %bx
	mov $0x0e, %ah # Вывод символа на активную видео страницу (эмуляция телетайпа)
        mov $'y', %al
	int $0x10 # Вызывается прерывание. Обработчиком является код BIOS. Символ будет выведен на экран.
	mov $'e', %al
	int $0x10
	mov $'l', %al
	int $0x10
	mov $'l', %al
	int $0x10
	mov $'o', %al
	int $0x10
	mov $'w', %al
	int $0x10
	movb $0x0e, 0x467 # кладем цвет
        jmp while
  white:
  	call clearing_the_screen
  	mov $5, %bx
	mov $0x0e, %ah
        mov $'w', %al
	int $0x10
	mov $'h', %al
	int $0x10
	mov $'i', %al
	int $0x10
	mov $'t', %al
	int $0x10
	mov $'e', %al
	int $0x10
	movb $0x0f, 0x467
        jmp while
  green:
  	call clearing_the_screen
        mov $0, %bx
	mov $0x0e, %ah
        mov $'g', %al
	int $0x10
	mov $'r', %al
	int $0x10
	mov $'e', %al
	int $0x10
	mov $'e', %al
	int $0x10
	mov $'n', %al
	int $0x10
	movb $0x02, 0x467
        jmp while

exit:
   call clearing_the_screen
   
	# Дисковой ввод/ввывод
	
	mov $0x1000, %bx 
  	mov %bx, %es # адрес буфера, в который считываются данные
  	mov %bx, %ax
  	xor %bx, %bx
	movb $25, %al # количество секторов
	movb $0, %ch # номер цилиндра
	movb $1, %cl # номер цилиндра
	movb $0, %dh # номер головки
	movb $1, %dl # номер диска
	movb $0x02, %ah # считывание заданного количества секторов с диска в память

        int $0x13    # дисковый ввод/вывод
    
        # Отключение прерываний
        cli
	lgdt gdt_info

        inb $0x92, %al
    	orb $2, %al
    	outb %al, $0x92 

    	movl %cr0, %eax
    	orb $1, %al
    	movl %eax, %cr0
	
    	ljmp $0x8, $protected_mode
	
	
	
# Минимальная таблица дескрипторов, необходимая для переключения
# процессора в защищенный режим. Каждый сегмент имеет базу 0 и лимит 4
# Гб, что покрывает всю адресуемую процессором память.

gdt:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x9A, 0xCF, 0x00
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x92, 0xCF, 0x00
gdt_info:
	.word gdt_info - gdt
	.word gdt, 0
	
	
	
.code32
protected_mode:
# Загрузка селекторов сегментов для стека и данных в регистры
	movw $0x10, %ax # Используется дескриптор с номером 2 в GDT
	movw %ax, %es
	movw %ax, %ds
	movw %ax, %ss
	call 0x10000 # Передача управления загруженному ядру
	# Адрес равен адресу загрузки в случае если ядро скомпилировано в "плоский" код
	
	clearing_the_screen:
	xor %ah, %ah # ah - Цвет символа и фона, обнуляем
	mov $2, %al
	int $0x10
	ret
	

.zero (512 - (. - _start) - 2)
.byte 0x55 
.byte 0xAA

