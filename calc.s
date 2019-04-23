%define enter 10

%macro macroForStartLabels 0
     push ebp
     mov ebp,esp    ; Entry code - set up ebp and esp
     pushad             ; Save registers
     %endmacro

%macro macroEndOfFunc 0      
    popad
    pop ebp            
    ret  
    %endmacro

%macro macroCheckEndList 0
    cmp byte[ecx],enter
    je closing_the_list 
    cmp byte[ecx],0
    je closing_the_list 
    jmp even_length
    %endmacro

%macro macroEnd 0
    pop ebp
    ret
%endmacro

%macro macroChangeHeadOfList 0
    mov dword edx,[head]      ; saving the head of list
    mov dword [eax+1],edx      ; put the old head in the next
    mov dword [head], eax       ; init head in the new head
    inc ecx
    %endmacro

 %macro macroCreatingNewlink 0
    pushad                  ; save registers 
    push dword 5            ; allocate new link in the LinkList-1 byte data. 4-next   
    call malloc             
    mov dword[ebp-4],eax    ; the pointer to the new alloceted space is in the empty space
    add esp,4               ; because push
    popad                   ; change registers to last state
    mov eax,dword[ebp-4]    ; put the pointer to the alloceted space in eax
    %endmacro

%macro macroEndOfList 0
    cmp dword ecx, 0  
    je end_print_list
%endmacro
    
%macro macroStartAndTakeInput 0
  push ebp               ; Save caller state
  mov ebp,esp
  mov ecx,[ebp+8]        ; get input- ebp+4 the return adress
  %endmacro
     
%macro macroPrintFOrCalc 1
    pushad
    push %1
    call printf
    add esp,4
    popad
    %endmacro

%macro macroPrintTwoVal 2
    pushad
    push %1
    push %2
    call printf
    add esp,8
    popad
    %endmacro
    
%macro macroDebug 2
    pushad
    cmp byte[calc_debug_flag],0
    je %%toNotDebug
    push %1
    push %2
    call printf
    add esp,8
    %%toNotDebug:
        popad
    %endmacro
    
%macro ourParameter 1
    ;command input
    cmp byte[eax],enter    ;if the usre enter noting
        je our_loop
        
    cmp byte[eax],'q'   ;we check for quit option!
        je quit_from_calc
    
     cmp byte[eax],'+'   ;here we check for addition.
        jne not_to_addition ;if we have not '+' in the stack.
        call our_addition   ;else we have to addition numbers.
        jmp our_loop        ;go back to the loop.
    
    not_to_addition:    ;we have not a '+' so we have to check other cases.
        cmp byte[eax],'p'       ;here we check for print.
        jne no_need_to_print    ;if we didnt need to print some thing.
        call our_pop_and_print      ;else we have to pop and print from the stack.
        jmp our_loop            ;go back to the loop.
     
     no_need_to_print:       ;we have not a 'p' so we have to check other cases.
        cmp byte[eax],'d'       ;here we check for duplicat.
        jne no_need_to_duplicat ;if we didnt get a 'd' so we check other cases.
        call our_duplicat        ;else we have to duplicat our numbers.
        jmp our_loop            ;go back to the loop.
    
     no_need_to_duplicat:            ;go and check for other cases.
        cmp byte[eax],'r'           ;here we check for shift right.
        jne no_need_to_shift_right  ;if we didnt need to shift right so we check for other cases.
        call our_shift_right          ;else we have to shift right our numbers.
        jmp our_loop                ;go back to the loop. 
        
    no_need_to_shift_right:     ;go and check for valid input.
        cmp byte[eax],'l'
        jne no_need_to_shift_left
        call our_shift_left
        jmp our_loop
                            
    no_need_to_shift_left:
        push eax
        
          
    check_for_valid_input:  ;go and check for valid input.
        cmp byte[eax],enter
        je invalid_input
        cmp byte[eax],'0'
        jb iligal_input
        cmp byte[eax],'9'
        ja iligal_input
        inc eax
        jmp check_for_valid_input
                                
    invalid_input:
        pop eax
        cmp dword[our_stack_size],calc_stack_size
        jne recive_a_list
                                    
        macroPrintTwoVal calc_StackOverFlowError,calc_string_to_print
        jmp our_loop
                                    
    iligal_input:
        pop eax
        macroPrintTwoVal calc_IlgalInputError,calc_string_to_print
        jmp our_loop
    %endmacro

    
section .data
                calc_stack_size equ 5
                calc_debug_flag db 0
                calc_shift_left_flag db 0
                calc_shift_left_exp db 0
                calc_shift_left_counter db 0
                our_stack_size dd 0
                calc_offset dd 0
                calc_head_of_stack times calc_stack_size dd 0 
                head dd 0
                calc_number_of_operands dd 0
 
section .rodata
                calc_print: db ">>calc: ",0
                calc_result: db ">>",0
                calc_string_to_print: db "%s",10,0
                calc_StackOverFlowError: db "Error: Operand Stack Overflow",0
                calc_InsufficientNumberError: db "Error: Insufficient Number of Arguments on Stack",0
                calc_IlgalInputError: db "Error: Iligal input",0
                calc_NoArgumentsInStackError: db "Error: Insufficient Number of Arguments on Stack",0
                calc_debug_msg_for_append: db"%02X,User insert a Even Number: ",10,0
                calc_debug_msg_for_append_2:db "%X,User insert a Odd Number: ",10,0
                calc_debug_msg_curr_Stack: db "the current data is copeing from the las data in the stack.",10,0
                calc_debug_msg_Pop_N_Print: db "User insert p Parameter so we have to Pop & Print HEAD OF STACK",10,0
                calc_debug_msg_Addition:db "User insert + Parameter so we have to Addition into Stack",10,0
                calc_debug_msg_quit: db "User insert q Parameter so we have to quit from the Program",10,0
                calc_format_1: db "%02x",0 
                calc_format_2: db "%x",0
                calc_new_line: db 10,0

section .bss
            SIZE equ 80
            BUFF: RESB SIZE
                
section .text
            align 16
            global main
            extern exit
            extern printf
            extern fprintf
            extern malloc
            extern free
            extern fgets
            extern stderr
            extern stdin
            extern stdout

main:
     macroForStartLabels
     mov ecx, dword [ebp+8]     ;this is our argc
     cmp ecx,1                  ;check if we have only calc without -d
     je not_a_debug             ;jump to not a debug mod
            mov ebx,dword[ebp+12]   ;
            mov eax,dword[ebx+4]    ;
            cmp byte[eax],'-'       ;
            jne not_a_debug         ;
            cmp byte[eax+1],'d'     ;
            jne not_a_debug         ;
            mov byte[calc_debug_flag],1 ;
    not_a_debug:
    call our_calc
    macroEndOfFunc
    ;----------END OF OUR MAIN-----------
    
    our_calc:
            macroForStartLabels
            sub esp,4   ;leave space for local var on the stack
            
            
    our_loop: 
            macroPrintFOrCalc calc_print
            push dword [stdin]
            push dword SIZE
            push BUFF
            call fgets
            add esp,12
;----- now our eax registers contain the user input so we have to switch cases: -----
            ourParameter byte[eax]
                                        
            recive_a_list:
                push eax
                call creating_a_link
                add esp,4
                push eax
                call push_to_our_stack
                add esp,4
                jmp our_loop
                   
;---------- Call Operands----------

        quit_from_calc: 
             cmp byte[calc_debug_flag],0
                je not_debug_Quit
                macroPrintFOrCalc calc_debug_msg_quit
                
            not_debug_Quit:
            
            call free_Stack     ;call freeStack      
            add esp,4           ;clean local var
            popad               ;restore caller state
            mov eax,[ebp-4]     ;place returned value where caller can see it
            macroEnd
            
        our_addition:
            ;call Addition       ;call to Addition.
            jmp our_loop
        
        our_pop_and_print:
            call PopNPrint      ;call to PopNPrint.
            jmp our_loop
            
        our_duplicat:
            call Duplicat       ;call to Duplicat.
            jmp our_loop
            
        our_shift_right:
          ;  call ShiftRight     ;call to ShiftRight.
            jmp our_loop
            
        our_shift_left:
           ; call ShiftLeft      ;call to ShiftLeft.
            jmp our_loop
            
            
;---------- this is our Stack Function----------
        
        push_to_our_stack: 
            push ebp
            mov ebp,esp
            
            mov ecx,[ebp+8]
            mov ebx,calc_stack_size
            cmp dword[our_stack_size],ebx
            jl .start
            macroPrintTwoVal calc_StackOverFlowError,calc_string_to_print
            
            .start:
                mov dword eax,[calc_offset]
                mov dword [calc_head_of_stack+eax],ecx
                add dword [calc_offset],4
                add dword [our_stack_size],1
                jmp end_of_print_error_over_flow
            
        end_of_print_error_over_flow:
            macroEnd
            
        pop_from_stack:
            push ebp
            mov ebp,esp
            cmp dword[our_stack_size],0
            je cant_pop_from_stack
            
            mov dword edx,[calc_offset]
            sub edx,4
            mov dword eax,[calc_head_of_stack+edx]
            sub dword[calc_offset],4
            sub dword[our_stack_size],1
            jmp end_print_cuz_no_argumants
        
        cant_pop_from_stack:
            macroPrintTwoVal calc_NoArgumentsInStackError,calc_string_to_print
            mov eax,0
        
        end_print_cuz_no_argumants:
            macroEnd
            
        print_stack:
            push ebp
            mov ebp,esp
            mov eax,0
         
        loop_stack:
            mov edx,dword[calc_head_of_stack+eax*4]
            cmp eax,dword[our_stack_size]
            je the_end_loop_stack
            push edx
            call print_stack
            pop edx
            popad
            inc eax
            jmp loop_stack
            
        the_end_loop_stack:
            macroEnd
            
        free_Stack:
            push ebp
            mov ebp,esp
            mov eax,0
            
        loop_free_stack:
            mov edx,dword[calc_head_of_stack+eax*4]
            cmp eax,dword[our_stack_size]
            je end_of_loop_free_stack
            push edx
            call free_our_list
            pop edx
            inc eax
            jmp loop_free_stack
            
        end_of_loop_free_stack:
            macroEnd
            
;---------- End Of Stack ----------
            
        
;---------- List Function ----------
 ; ----------------------------------*** Clean the LinkList ***---------------------------------
    free_our_list:
    macroForStartLabels          
    mov ecx,[ebp+8]           ; get input to ecx 
    
    loop_delete_current_link:
    mov dword eax,[ecx+1]      ; get next to eax
    pushad                     ; save reg before free
    push ecx
    call free
    add esp,4                  ; because of push ecx
    popad                      ; restore reg

    mov ecx,eax                 ; put next in ecx   
    cmp ecx,0                   ; check if its the last link
    je end_delete_list
    jne loop_delete_current_link  ; there are more links to delete

    
    end_delete_list:
    macroEndOfFunc                    
    
    
; ------------------------------*** End Of Clean the LinkList ***--------------------------------- 
    
; ------------------------------*** creating a LinkList ***-----------------------------
    creating_a_link:  
    macroStartAndTakeInput
    mov eax,0          ; eax is a counter for the number of leading zeros
    sub esp,4          ; allocate place for new variable
    mov dword[esp],0   ; init new variable
    
            
    loop_for_counting_leading_zero:
    cmp byte[ecx],'0'       ; check if the char is '0'
    jne check_if_not_zero
    inc eax                 ; the index for counting 0
    inc ecx                 ; input- go next char
    jmp loop_for_counting_leading_zero
            
    check_if_not_zero:
    cmp eax,0
    je no_more_leading_zero
    dec eax
    dec ecx
            
    no_more_leading_zero:
    mov dword[head],0
    mov ebx,0
           
    loop_length_of_input: ; calc the length of input
    cmp byte[ecx],enter   ; if its /n its the end of input
    je check_odd_or_even
    cmp byte[ecx],0       ; check if end of input
    je check_odd_or_even   
    inc ecx               ; next char
    inc ebx               ; length ++ 
    jmp loop_length_of_input
   
    check_odd_or_even:
    mov ecx,dword[ebp+8]   ; get input to ecx   
    add ecx,eax            ; go to the first char without leading zeroes
    and ebx,1              ; check if last char is 0- even, or 1- odd
    je even_length
    jne odd_length
   
    even_length:
    mov edx,0
    macroCreatingNewlink                
    mov ebx,0            ; newlink 
    mov bl,[ecx]
    sub bl,48            ; ascii to binary
    shl bl,4
    inc ecx
    mov dl,[ecx]
    sub dl,48            ; ascii to binary
    or bl,dl
    mov [eax],bl            ;insert 2 digits into node
    macroChangeHeadOfList
    macroDebug ebx,calc_debug_msg_for_append
    cmp byte[ecx],0
    je closing_the_list
    cmp byte[ecx],enter
    je closing_the_list
    jmp even_length         
                

    odd_length:
    macroCreatingNewlink
    mov ebx,0
    mov bl,[ecx]
    sub bl,48            ; ascii to binary
    mov byte[eax],0    
    mov [eax],bl            
    macroChangeHeadOfList
    macroDebug ebx,calc_debug_msg_for_append_2           
    macroCheckEndList
    closing_the_list:    
    mov dword eax,[head]  
    add esp,4             
    macroEnd
; ----------------------------*** End of creating a LinkList ***---------------------------------

; ------------------------------*** Print the LinkList ***---------------------------------
    print_the_linklist: 
    macroStartAndTakeInput     
    mov ebx,0
    mov eax,0  
    macroEndOfList
    mov edx,0
    
    over_the_list:
    movzx eax,byte[ecx]    ; put the input- move with zero extand
    push eax
    inc ebx                ; count the num of links in link list
    mov ecx, dword[ecx+1]  ; move to next char
    cmp dword ecx,0        ; check for last link
    jne over_the_list 
    dec ebx                ; edx is how many on stack
    pop eax                ; cancel the push
    macroPrintTwoVal eax,calc_format_2
             
    loop_print_link:
    cmp ebx,0
    je end_print_list
    pop eax
    dec ebx                ; count num of element in stack
    macroPrintTwoVal eax,calc_format_1
    jmp loop_print_link
    
    end_print_list:
    pushad  
    push calc_new_line
    call printf
    pop ebx
            
    macroEndOfFunc  
 ; ------------------------------*** End Of Print the LinkList ***---------------------------   
 
 
; ----------------------------------*** Copy the LinkList ***--------------------------------
Copy_the_LinkList:
        macroStartAndTakeInput     
        sub esp,12            ; allocate space for variables
        mov dword[ebp-4],0    
        mov dword[ebp-8],0    
        mov dword[ebp-12],0   
     

        loop_for_copy_list:  
        mov edx,0             ; init ebx in zeros
        mov dl,byte[ecx]      ; take input from memory
        macroCreatingNewlink
        mov byte[eax],dl      ; put input in the new link   
        mov dword[eax+1],0    ; init next to- 0    
        cmp dword[ebp-12],0  
        jne not_last_link
        mov dword[ebp-12],eax ;eax containig the new link
        jmp creat_link
            
        not_last_link:
        mov ebx,[ebp-8]    
        mov dword[ebx+1],eax

        creat_link: 
        mov [ebp-8], eax ; asigning this to 'prev'
        mov dword ecx ,[ecx + 1]
        cmp ecx,0
        jne loop_for_copy_list

        end_CopyList:
        mov eax,dword [ebp-12]  ;return vale is the head
        add esp,12
    	macroEnd
; ------------------------------*** End of Copy LinkList  ***---------------------------------


;----------End Of Linked List----------

;----------calc Function----------

    ;-----Duplicat-----
        Duplicat:
        pushad
        mov ebp,esp
            
            cmp dword[our_stack_size],calc_stack_size
            jne can_dup
            macroPrintTwoVal calc_StackOverFlowError,calc_string_to_print
            jmp end_duplicat
            
            can_dup:
                call pop_from_stack
                cmp eax,0
                je end_duplicat
                
                push eax
                call Copy_the_LinkList
                
                push eax
                call push_to_our_stack
                add esp,4
                
                call push_to_our_stack
                add esp,4
                
                cmp byte[calc_debug_flag],0
                    je not_debug
                    macroPrintFOrCalc calc_debug_msg_curr_Stack
                
            not_debug:
                inc dword[calc_number_of_operands]
                
            end_duplicat:
                popad
                ret
                
                    
    ;-----End of Duplicat-----
    
    ;-----Pop & Print-----
        PopNPrint:
            pushad
            mov ebp,esp
            
            call pop_from_stack
            cmp eax,0
            je end_pop_and_print
            macroPrintFOrCalc calc_result
            push eax
            call print_the_linklist
            call free_our_list
            pop eax
            inc dword[calc_number_of_operands]
            
         cmp byte[calc_debug_flag],0
            je not_debug_PopNPrint
            macroPrintFOrCalc calc_debug_msg_Pop_N_Print
            
        not_debug_PopNPrint:
            inc dword[calc_number_of_operands]
            
        end_pop_and_print:
            popad
            ret
    ;----- End Of Pop & Print-----

            
                        
         
         
         