#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all:calc

# Tool invocations
# Executable "calc" depends on the files hello.o and run.o.
calc: calc.o
	gcc -m32 -Wall -g calc.o -o calc.bin

# Depends on the source and header files

calc.o: calc.s
	nasm -f elf calc.s -o calc.o

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o calc