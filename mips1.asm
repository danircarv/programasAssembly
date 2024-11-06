.data
        .align 2                           # Adiciona alinhamento para garantir word boundary
  	 input_file:      .asciiz "C:/Users/danie/OneDrive/Documentos/programasAssembly/lista.txt"     
    	output_file:     .asciiz "C:/Users/danie/OneDrive/Documentos/programasAssembly/lista_ordenada.txt"
        buffer: .space 2048                # Buffer aumentado para garantir espa�o suficiente
        .align 2                           # Garante alinhamento para o array numbers
        numbers: .space 400                # Array para 100 n�meros (100 * 4 bytes)
        temp_string: .space 16             # Buffer tempor�rio para convers�o
        space: .asciiz " "                 # Espa�o para separar n�meros
        newline: .asciiz "\n"              # Nova linha
        comma: .asciiz ","                 # V�rgula para separar n�meros
        error_msg: .asciiz "Erro ao abrir o arquivo\n" # Mensagem de erro
        
.text
.globl main

main:
        # Abrir arquivo de entrada
        li $v0, 13
        la $a0, input_file
        li $a1, 0      # Modo leitura
        li $a2, 0
        syscall
        move $s0, $v0  # Salvar file descriptor
        
        # Verificar se o arquivo foi aberto corretamente
        bltz $s0, file_error
        
        # Ler arquivo
        li $v0, 14
        move $a0, $s0
        la $a1, buffer
        li $a2, 2048
        syscall
        move $s1, $v0  # Salvar quantidade de bytes lidos
        
        # Fechar arquivo de entrada
        li $v0, 16
        move $a0, $s0
        syscall
        
        # Inicializar registradores para parse
        la $s0, buffer     # Endere�o do buffer
        la $s1, numbers    # Endere�o do array de n�meros
        li $s2, 0          # Contador de n�meros
        
parse_loop:
        # Verificar limite de n�meros
        li $t0, 100
        beq $s2, $t0, parse_done
        
        move $a0, $s0      # Passar endere�o atual do buffer
        jal parse_number
        beq $v0, -1, parse_done  # Se chegou ao fim
        
        # Calcular endere�o correto no array
        la $t0, numbers
        sll $t1, $s2, 2    # Multiplicar �ndice por 4
        add $t0, $t0, $t1
        
        # Armazenar n�mero no array
        sw $v1, ($t0)
        addi $s2, $s2, 1   # Incrementar contador
        move $s0, $v0      # Atualizar posi��o do buffer
        j parse_loop
        
parse_done:
        # Ordenar n�meros (Bubble Sort)
        la $a0, numbers    # Endere�o do array
        move $a1, $s2      # Quantidade de n�meros
        jal bubble_sort
        
        # Abrir arquivo de sa�da
        li $v0, 13
        la $a0, output_file
        li $a1, 1          # Modo escrita
        li $a2, 0644       # Permiss�es do arquivo
        syscall
        move $s0, $v0      # Salvar file descriptor
        
        # Verificar se o arquivo foi aberto corretamente
        bltz $s0, file_error
        
        # Preparar para escrever n�meros ordenados
        la $s1, numbers    # Endere�o do array
        li $s3, 0          # Contador
        
write_loop:
        beq $s3, $s2, write_done
        
        # Carregar n�mero atual
        lw $a0, ($s1)
        la $a1, temp_string
        jal int_to_string
        
        # Calcular comprimento da string
        la $t0, temp_string
        li $t1, 0          # Contador de caracteres
count_loop:
        lb $t2, ($t0)
        beqz $t2, count_done
        addi $t1, $t1, 1
        addi $t0, $t0, 1
        j count_loop
count_done:
        
        # Escrever n�mero
        li $v0, 15
        move $a0, $s0
        la $a1, temp_string
        move $a2, $t1
        syscall
        
        # Verificar se � o �ltimo n�mero
        addi $t0, $s2, -1
        beq $s3, $t0, skip_comma
        
        # Escrever v�rgula e espa�o
        li $v0, 15
        move $a0, $s0
        la $a1, comma
        li $a2, 1
        syscall
        
        li $v0, 15
        move $a0, $s0
        la $a1, space
        li $a2, 1
        syscall
        
skip_comma:
        addi $s1, $s1, 4   # Pr�ximo n�mero
        addi $s3, $s3, 1   # Incrementar contador
        j write_loop
        
write_done:
        # Adicionar nova linha no final
        li $v0, 15
        move $a0, $s0
        la $a1, newline
        li $a2, 1
        syscall
        
        # Fechar arquivo
        li $v0, 16
        move $a0, $s0
        syscall
        
        j exit_program

file_error:
        li $v0, 4
        la $a0, error_msg
        syscall

exit_program:
        li $v0, 10
        syscall

# Fun��es auxiliares
bubble_sort:
        move $t0, $a0      # Endere�o do array
        move $t1, $a1      # Quantidade de elementos
        subi $t1, $t1, 1   # n-1 para o loop externo
        
outer_loop:
        li $t2, 0          # i = 0
        move $t3, $t0      # Ponteiro atual
        
inner_loop:
        lw $t4, ($t3)      # arr[j]
        lw $t5, 4($t3)     # arr[j+1]
        
        ble $t4, $t5, skip_swap
        # Trocar elementos
        sw $t5, ($t3)
        sw $t4, 4($t3)
        
skip_swap:
        addi $t3, $t3, 4   # Pr�ximo elemento
        addi $t2, $t2, 1   # i++
        sub $t6, $t1, $t2
        bgtz $t6, inner_loop
        
        subi $t1, $t1, 1   # Decrementar contador externo
        bgtz $t1, outer_loop
        
        jr $ra

parse_number:
        li $v1, 0          # Resultado
        li $t0, 0          # Flag para n�mero negativo
        
        # Verificar espa�os iniciais
skip_spaces:
        lb $t1, ($a0)
        beq $t1, 32, next_char    # Espa�o
        beq $t1, 9, next_char     # Tab
        beq $t1, 10, next_char    # Nova linha
        beq $t1, 44, next_char    # V�rgula
        j check_sign
        
next_char:
        addi $a0, $a0, 1
        j skip_spaces
        
check_sign:
        lb $t1, ($a0)
        bne $t1, 45, convert      # N�o � negativo
        li $t0, 1                 # � negativo
        addi $a0, $a0, 1
        
convert:
        lb $t1, ($a0)
        
        # Verificar fim do n�mero
        beq $t1, 32, end_number   # Espa�o
        beq $t1, 9, end_number    # Tab
        beq $t1, 10, end_number   # Nova linha
        beq $t1, 44, end_number   # V�rgula
        beq $t1, 0, end_number    # Null
        
        # Converter d�gito
        subi $t1, $t1, 48         # Converter ASCII para n�mero
        bltz $t1, end_number      # Se < 0, n�o � d�gito
        li $t2, 9
        bgt $t1, $t2, end_number  # Se > 9, n�o � d�gito
        
        mul $v1, $v1, 10
        add $v1, $v1, $t1
        
        addi $a0, $a0, 1
        j convert
        
end_number:
        beqz $t0, positive
        neg $v1, $v1            # Tornar negativo se necess�rio
        
positive:
        beqz $t1, eof
        move $v0, $a0
        jr $ra
        
eof:
        li $v0, -1
        jr $ra

int_to_string:
        move $t0, $a0      # N�mero
        move $t1, $a1      # Buffer
        li $t2, 0          # Contador de d�gitos
        
        # Verificar se � negativo
        bgez $t0, positive_number
        li $t3, 45         # '-'
        sb $t3, ($t1)
        addi $t1, $t1, 1
        neg $t0, $t0
        
positive_number:
        # Primeiro, empilhar todos os d�gitos
        move $t3, $t0      # C�pia do n�mero
        li $t4, 10         # Divisor
        
digit_stack:
        div $t3, $t4
        mfhi $t5           # Resto (d�gito)
        mflo $t3           # Quociente
        
        # Empilhar d�gito
        addi $sp, $sp, -4
        sw $t5, ($sp)
        addi $t2, $t2, 1   # Incrementar contador
        
        bnez $t3, digit_stack
        
        # Agora, desempilhar e converter para ASCII
        move $t3, $t1      # Posi��o atual no buffer
        move $t4, $t2      # Contador de d�gitos
        
unstack_digits:
        lw $t5, ($sp)      # Carregar d�gito
        addi $sp, $sp, 4
        
        addi $t5, $t5, 48  # Converter para ASCII
        sb $t5, ($t3)      # Armazenar no buffer
        addi $t3, $t3, 1   # Pr�xima posi��o
        
        addi $t4, $t4, -1
        bnez $t4, unstack_digits
        
        # Adicionar null terminator
        sb $zero, ($t3)
        
        jr $ra
