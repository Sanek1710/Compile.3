    mov  eax, 1
    mov  ebx, 2
    mov  [.mem+00h], eax
    mov  eax, 5
    mlt  ebx, eax
    mov  eax, [.mem+00h]
    add  eax, ebx
    mov  [c], eax
    mov  eax, [c]
    mov  ebx, [b]
    cmp  eax, ebx
    mov  ebx, [b]
    jle  . + 0Ah
    mov  eax, 1
    jmp  . + 08h
    mov  eax, 0
    tst  eax
    je   _P000
    mov  eax, [c]
    call print
    jmp  _P001

    mov  eax, [b]
    call print

    ret 