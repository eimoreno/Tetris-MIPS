#######################
# Macros para a Pilha #
#######################

.macro pushWord (%dado)
	addi $sp $sp -4
	sw %dado ($sp)
.end_macro

.macro popWord (%dado)
	lw %dado ($sp)
	addi $sp $sp 4
.end_macro

##################
# Macros da Fila #
##################

#Start the FIFO List Struct
.macro startFila #Takes no arguments;
	la $t8 0x10000000 #Set Start of the List
	and $t7 $t8 $t8
.end_macro

#Teste of if FIFO List is empty
.macro isFEmpty #$v0: Returns 0 if FIFO List is empty and 1 otherwise;
	sne $v0 $t8 0x10000000
# beq $t8 0x10000000 empty
# 	nop
# 	ori $v0 $0 0x1
# 	j end
# 	nop
# empty:
# 	and $v0 $0 $0
# end:
.end_macro

#Saves data to the FIFO List
.macro pushFByte (%dado) #$1: Data to be saved;
	addi $t8 $t8 1
	sb %dado ($t8)
.end_macro

#Get a data from the FIFO List
.macro popFByte (%dado) #$s1 recives the data
	isFEmpty
	beq $v0 $0 return #Does nothing if FIFO List is empty
	nop
	lb %dado 1($t7)
	pushWord $t0
	pushWord %dado
	pushWord $t7 #Saves the pointer
loopPopF: #loop to move the elements in the FIFO List
	lb $t0 2($t7) #Get Next Value
	sb $t0 1($t7) #Store here
	addi $t7 $t7 1
	blt $t7 $t8 loopPopF
	nop
	popWord $t7
	popWord %dado
	popWord $t0
	addi $t8 $t8 -1 #Updates the last FIFO List position
	return:
.end_macro

##############################
# Macros para mover ponteiro #
##############################

#Moves the pointer to the next 'n' square horizontalçy
.macro nextSquareHorizontal (%pointer, %range) #$1: Memori Pointer; $2: Quantity of Squares to jump
	pushWord $t0
	and $t0 $0 $0
loop:
	addi %pointer %pointer 64 # 16*6
	addi $t0 $t0 1
	blt $t0 %range loop
	nop
	popWord $t0
.end_macro

#Moves the pointer to the previous 'n' square horizontaly
.macro previousSquareHorizontal (%pointer, %range) #$1: Memori Poniter; $2: Quantity of Squares to jump
	pushWord $t0
	and $t0 $0 $0
loop:
	addi %pointer %pointer -64 #16 * 4
	addi $t0 $t0 1
	blt $t0 %range loop
	nop
	popWord $t0
.end_macro

#Moves the pointer to the next 'n' square vertically
.macro nextSquareVertical (%pointer, %range) #$1: Memory Pointer; $2: Quantity of Squares to jump
	pushWord $t0
	and $t0 $0 $0
loop:
	addi %pointer %pointer 32768 #64 * 32 * 16
	addi $t0 $t0 1
	blt $t0 %range loop
	nop
	popWord $t0
.end_macro

#Moves the pointer to the previous 'n' square vertically
.macro previousSquareVertical (%ponteiro, %range) #$1: Memory Poniter; $2: Quantity of Squares to jump
	pushWord $t0
	and $t0 $0 $0
loop:
	addi %ponteiro %ponteiro -32768 #64 * 32 * 16
	addi $t0 $t0 1
	blt $t0 %range loop
	nop
	popWord $t0
.end_macro

#Moves the pointer 'n' line(s) down
.macro nextPixelLine (%pointer, %range) #$1: Memory Poninter; $2: Quantity of lines to jump
	pushWord $t0
	and $t0 $0 $0
loop:
	addi %pointer %pointer 2048
	addi $t0 $t0 1
	blt $t0 %range loop
	nop
	popWord $t0
.end_macro

#############################
# Macros para pintar pixels #
#############################

#Paint a single pixel
.macro paintPixel (%cor, %pointer)
	sw %cor (%pointer)
	addi %pointer %pointer 4
.end_macro

#Pinte a line of 'n' pixels
.macro paintPixelLine (%cor, %pointer, %range, %flag) #$1: Color to paint; $2: Pointer to line start; $3: Size of the line; $4: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t0
	pushWord %pointer
	and $t0 $zero $zero
loopLinha:
	sw %cor (%pointer)
	addi %pointer %pointer 4 #Next Pixel
	addi $t0 $t0 1
	blt $t0 %range loopLinha
	nop
	beq $zero %flag StartPointer
	nop
	popWord $t0 #Descarda a posição antiga do ponteiro
	popWord $t0
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t0
return:
.end_macro

###################################
# Macros para a printar Quadrados #
###################################

#Paint with ($1) color the square that starts and pointer($2)
.macro paintSquare (%cor, %pointer, %flag) #$1: Color to paint; $2: square pointer; $3: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t0
	pushWord $t1
	pushWord %pointer
	and $t0 $zero $zero
	and $t1 $zero $zero
loopLinha:
	sw %cor, (%pointer)
	addi %pointer %pointer 4 #Next Pixel
	addi $t0 $t0 1 #Line counter increment
	blt $t0 16 loopLinha
	nop
	and $t0 $zero $zero
	addi %pointer %pointer 1984 #Next line of the square((512-16)*4)
	addi $t1 $t1 1
	blt $t1 16 loopLinha
	nop
	beq $zero %flag StartPointer
	nop
	popWord $t1 #Descarda a posição antiga do ponteiro
	popWord $t1
	popWord $t0
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t1
	popWord $t0
return:
.end_macro

#Paints a block of the game
.macro paintBlock (%cor %light %shadow %pointer %flag) #$1 - $t3: Colors to paint the block; $2: square pointer; $3: '0' returns origal pointer, else returns the finish pointer;
	pushWord %pointer

	#Sstarts paiting
	#Line 1
	pushWord %pointer
	paintPixel $0 %pointer
	paintPixel $0 %pointer
	paintPixelLine %light %pointer 12 1
	paintPixel $0 %pointer
	paintPixel $0 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixel $0 %pointer
	paintPixelLine %light %pointer 13 1
	paintPixel %shadow  %pointer
	paintPixel $0 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4 to Line 13
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixel %light %pointer
	paintPixel %light %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	paintPixel %shadow  %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 15
	pushWord %pointer
	paintPixel $0 %pointer
	paintPixel %light %pointer
	paintPixelLine %shadow %pointer 13 1
	paintPixel $0 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 16
	pushWord %pointer
	paintPixel $0 %pointer
	paintPixel $0 %pointer
	paintPixelLine %shadow %pointer 12 1
	paintPixel $0 %pointer
	paintPixel $0 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	beq $zero %flag StartPointer
	nop
	popWord $v0 #Descarda a posição antiga do ponteiro
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
return:
.end_macro

#Paint a full squareline
.macro paintFullLine (%cor, %pointer, %flag) #$1: Color to paint; $2: square pointer; $3: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t0
	pushWord %pointer
	and $t0 $zero $zero
loopLinha:
	sw %cor (%pointer)
	addi %pointer %pointer 4 #Next Pixel
	add $t0 $t0 1
	blt $t0 8192 loopLinha #8192 (512*16)
	nop
	beq $zero %flag StartPointer
	nop
	popWord $t0 #Descarda a posição antiga do ponteiro
	popWord $t0
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t0
return:
.end_macro

#Paint a line of 'n' squares
.macro paintLine (%cor, %pointer, %range, %flag)#$1 Color to paint; $2: start pixel pointer; $3 Number of squares to paint; $4: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t0
	pushWord %pointer
	and $t0 $zero $zero
loopLine:
	paintSquare %cor, %pointer, 0
	addi $t0 $t0 1
	addi %pointer %pointer 64 #Next block (16*4)
	blt $t0 %range loopLine
	nop
	beq $zero %flag StartPointer
	nop
	popWord $t0 #Descarda a posição antiga do ponteiro
	popWord $t0
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t0
return:
.end_macro

#This is some magic that's necessary so things wouldn't fall apart
.macro magicMoveEndLine (%pointer)
	addi %pointer %pointer 30720 #Magic numbers muah ha ha (16*32*15*4)
.end_macro

#Paint a column of 'n' squares
.macro paintColumn (%cor, %pointer, %range, %flag)#$1 Color to paint; $2: square pointer; $3 Number of squares to paint; $4: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t0
	pushWord %pointer
loopColuna:
	paintSquare %cor, %pointer, 1
	addi $t0 $t0 1
	blt $t0 %range loopColuna
	nop
	beq $zero %flag StartPointer
	nop
	popWord $t0 #Descarda a posição antiga do ponteiro
	popWord $t0
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t0
return:
.end_macro

########################
# Paint Numbers Macros #
########################

#Paint a white zero with a black background
.macro paintZero (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line3
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line4
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 3 1
	paintPixelLine $t2 %pointer 2 1
	paintPixelLine $t3 %pointer 3 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line5
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line6
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line7
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 2 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 8 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 2 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line8
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 2 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 10 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 2 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line9
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 2 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 10 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 2 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line10
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 2 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 8 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 2 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line11
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line12
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line13
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 3 1
	paintPixelLine $t2 %pointer 2 1
	paintPixelLine $t3 %pointer 3 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line14
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white one with a black background
.macro paintOne (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 7 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 5
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 6
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 2 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 7
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 9 to 13
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 9 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1


	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white one with a black background
.macro paintTwo (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 5
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 6
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 7
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 9
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 9 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 10
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 11
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 7 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 12
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 9 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 13
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 10 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer #Saves the StartLine
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 9 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer #Get the StartLine Back
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white three with a black background
.macro paintThree (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixelLine $t3 %pointer 6 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 5 & Line 6
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 7
	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixelLine $t3 %pointer 5 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9 & Line 10
	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 11 & Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 13
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixelLine $t3 %pointer 6 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white four with a black background
.macro paintFour (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 9 1
	paintPixelLine $t3 %pointer 2 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 5
	pushWord %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 2 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 6 & Line 7
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 10 & Line 11
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 10 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 13 & Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 10 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 10 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white five with a black background
.macro paintFive (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 9 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4 & Line 5 % Line 6
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 7
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 6 1
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 9 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9
	pushWord %pointer
	paintPixelLine $t2 %pointer 11 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 10 & Line 11
	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 11 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 13
	pushWord %pointer
	paintPixelLine $t2 %pointer 9 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 6 1
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white six with a black background
.macro paintSix (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 9 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 5 & Line 6
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 11 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 11 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 7
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 3 1
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9 & Line 10 & Line 11 & Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 13
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white seven with a black background
.macro paintSeven (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine $t3 %pointer 10 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 11 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 5
	pushWord %pointer
	paintPixelLine $t2 %pointer 10 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 6
	pushWord %pointer
	paintPixelLine $t2 %pointer 9 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 7 & Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9
	pushWord %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 10 & Line 11
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 9 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 9 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 10 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 13
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 11 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white eight with a black background
.macro paintEight (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 5 & Line 6 & Line 7
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 8 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9 & Line 10 & Line 11 & Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1


	#Line 13
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

#Paint a white nine with a black background
.macro paintNine (%pointer, %flag) #$1 Pointer to the start of the number box; $2: '0' returns origal pointer, else returns the finish pointer;
	pushWord $t2
	pushWord $t3
	pushWord %pointer
	ori $t2 $0 0x000000 #Black Collor
	ori $t3 $0 0xFFFFFF #White Collor

	#Line 1 & Line 2
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Line 3
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 5 & Line 6 & Line 7 & Line 8
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 9
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 10
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine $t3 %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 11 & Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	pushWord %pointer
	paintPixelLine $t2 %pointer 12 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 13
	pushWord %pointer
	paintPixelLine $t2 %pointer 3 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 7 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine $t3 %pointer 7 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Line 15 & Line 16
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine $t2 %pointer 16 0
	nextPixelLine %pointer 1

	#Pointer flag control
	beq $zero %flag StartPointer
	nop
	popWord $t3 #Descarda a posição antiga do ponteiro
	popWord $t3
	popWord $t2
	j return
	nop
StartPointer:
	popWord %pointer #Pointer returns at start position
	popWord $t3
	popWord $t2
return:
.end_macro

####################
# Interface Macros #
####################

#Prints the interface with only the space of the game
.macro	printCleanLine (%cor %pointer %range)
	pushWord $t0
	and $t0 $zero $zero
loopCleanLine:
	paintSquare %cor %pointer 0
	nextSquareHorizontal %pointer 18 #17(camp) + 1(inicial column)
	paintLine %cor %pointer 14 1
	magicMoveEndLine %pointer
	addi $t0 $t0 1
	blt $t0 %range loopCleanLine
	nop
	popWord $t0
.end_macro

#Prints part of the interface(the line with the next space)
.macro printNextBlockLine (%cor %pointer %range)
	pushWord $t0
	and $t0 $zero $zero
loopNextBlock:
	paintSquare %cor %pointer 0
	nextSquareHorizontal %pointer 18 #17(camp) + 1(inicial column)
	paintLine %cor %pointer 4 1
	nextSquareHorizontal %pointer 6 #6(next camp)
	paintLine %cor %pointer 4 1
	magicMoveEndLine %pointer
	addi $t0 $t0 1
	blt $t0 %range loopNextBlock
	nop
	popWord $t0
.end_macro

#Reset to all 0's in the small box
.macro resetSmallBox (%pointer) #$1: Pointer to the start of the small box;
	pushWord %pointer
	paintZero %pointer 0
	nextSquareHorizontal %pointer 1
	paintZero %pointer 0
	nextSquareHorizontal %pointer 1
	paintZero %pointer 0
	nextSquareHorizontal %pointer 1
	paintZero %pointer 0
	nextSquareHorizontal %pointer 1
	popWord %pointer
.end_macro

#Prints the interface and the Score/Lines box
.macro printSmallBoxLine (%cor %pointer) #$1: Color of the interface; $2 Pointer to start of the line; $v0: Returns the start of the SmallBox
	paintSquare %cor %pointer 0
	nextSquareHorizontal %pointer 18 #17(camp) + 1(inical column)
	paintLine %cor %pointer 5 1
	and $v0 %pointer %pointer #Set the return to the start of the SmallBox
	resetSmallBox %pointer
	nextSquareHorizontal %pointer 4 #Jump the small Box
	paintLine %cor %pointer 5 1
	magicMoveEndLine %pointer
.end_macro

#Prints the interface and the text 'Next'
.macro printNextLine (%cor %pointer) #$1: Color of the interface; $2: Pointer to the start of the Line
	pushWord $t2
	pushWord $t3

	ori $t2 $0 0xb21030 #'Red' Color
	ori $t3 $0 0xebd320 #'Yellow' Color
	paintSquare %cor %pointer 0
	nextSquareHorizontal %pointer 18 #17(camp) + 1(inicial column)
	paintLine %cor %pointer 5 1

	#Paints the 'N' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Linha 2
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine %cor %pointer 5 1
	paintPixelLine $t2 %pointer 3 1
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 3
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 4
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 5
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 6
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 7
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 8
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 11
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixelLine $t2 %pointer 3 1
	paintPixelLine %cor %pointer 4 1
	paintPixelLine $t2 %pointer 4 1
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 15 & Line 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64 #16*4 #nextSquareHorizontal %pointer 1

	#Paints the 'E' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Linha 2
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixelLine $t2 %pointer 10 1
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 3
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 8 1
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 4
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 5 & Line 6
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 10 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 10 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 7
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 8
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 9
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 10 & Line 11
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 10 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 10 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 12
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 8 1
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 13
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 8 1
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 14
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixelLine $t2 %pointer 10 1
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the 'X' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Linha 2
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 3
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 4
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 5 & Line 6
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 7
	pushWord %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 6
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 9
	pushWord %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 10 & Line 11
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 12
	pushWord %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 13
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 14
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the 'T' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Linha 2
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixelLine $t2 %pointer 11 1
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 3
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 4
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 5 1
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 to 13
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 14
	pushWord %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#After "NEXT"
	paintLine %cor %pointer 5 1
	magicMoveEndLine %pointer

	popWord $t3
	popWord $t2
.end_macro

#Prints the interface and the text 'Score'
.macro printScoreLine (%cor %pointer) #$1: Color of the interface; $2: Pointer to the start of the Line
	pushWord $t2
	pushWord $t3

	ori $t2 $0 0xb21030 #'Red' Color
	ori $t3 $0 0xebd320 #'Yellow' Color
	paintSquare %cor %pointer 0
	nextSquareHorizontal %pointer 18 #17(camp) + 1(inicial column)
	paintLine %cor %pointer 4 1

	#Paints the first half of 'S' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine %cor %pointer 13 1
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 & Line 6
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixelLine %cor %pointer 12 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10 & Line 11
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints S/C ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 8 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixelLine $t3 %pointer 3 1
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 3 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 6
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 11
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 8 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints C/O ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixelLine $t3 %pointer 5 1
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 6
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7 & Line 8 & Line 9
	pushWord %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 11
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixelLine $t3 %pointer 5 1
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 6 1
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints O/R ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixelLine %cor %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 8 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 6
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixelLine %cor %pointer 4 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 5 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 11
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 8 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1

	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints R/E ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 8 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 & Line 6
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 8 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 11
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the final half of the 'E' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 & Line 6
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 7 & Line 8 & Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 15 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 15 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 15 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10 & Line 11
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#After "Score"
	paintLine %cor %pointer 4 1
	magicMoveEndLine %pointer

	popWord $t3
	popWord $t2
.end_macro

#Prints the interface and the text 'Lines'
.macro printLinesLine (%cor %pointer) #$1: Color of the interface; $2: Pointer to the start of the Line
	pushWord $t2
	pushWord $t3

	ori $t2 $0 0xb21030 #'Red' Color
	ori $t3 $0 0xebd320 #'Yellow' Color
	paintSquare %cor %pointer 0
	nextSquareHorizontal %pointer 18 #17(camp) + 1(inicial column)
	paintLine %cor %pointer 4 1

	#Paints the first half of 'L' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3 to 11
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixelLine $t2 %pointer 6 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the 'L/I' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 to 11
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 14 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	paintPixelLine $t2 %pointer 4 1
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the 'I/N' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 6
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7 & Line 8
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 11
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the 'N/E' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 & Line 6
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10 & Line 11
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 6 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 6 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the 'E/S' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 8 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 & Line 6
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 9 1
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 10 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 11 1
	paintPixelLine $t2 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10 and Line 11
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 7 1
	paintPixel $t2 %pointer
	paintPixelLine $t3 %pointer 4 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 7 1
	paintPixelLine $t2 %pointer 5 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#Paints the second half of 'S' ####################################
	pushWord %pointer
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 2
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 3
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 4
	pushWord %pointer
	paintPixelLine $t2 %pointer 4 1
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 5 & Line 6
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	#Line 7
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 13 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 8
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 9
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 10 & Line 11
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 11 1
	popWord %pointer
	nextPixelLine %pointer 1
	pushWord %pointer
	paintPixel %cor %pointer
	paintPixel %cor %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 11 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 12
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 12 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 13
	pushWord %pointer
	paintPixel $t3 %pointer
	paintPixel $t3 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 13 1
	popWord %pointer
	nextPixelLine %pointer 1
	#Line 14
	pushWord %pointer
	paintPixel $t2 %pointer
	paintPixel $t2 %pointer
	paintPixelLine %cor %pointer 14 1
	popWord %pointer
	nextPixelLine %pointer 1

	#Linha 15 & Linha 16
	paintPixelLine %cor %pointer 16 0
	nextPixelLine %pointer 1
	paintPixelLine %cor %pointer 16 0
	popWord %pointer
	addi %pointer %pointer 64

	#After "Lines"
	paintLine %cor %pointer 4 1
	magicMoveEndLine %pointer

	popWord $t3
	popWord $t2
.end_macro

#####################
# Move Piece Macros #
#####################

#Testes if a block can be moved to that space
.macro isBlockFree (%pointer) #$1: Pointer of block to be tested; $v0: Returns 1 if empty, otherwise returns 0
	pushWord $t0
	lw $t0 8(%pointer)
	seq $v0 $t0 $0 #If $t0 == $0 then $v0 = 1, else $v0 = 0
	popWord $t0
.end_macro

#Saves the moviment of the piece
.macro salvarMovimento #Takes no arguments
	pushWord $t2
	lw $t2 0xffff0000 #Read the 'Ready Bit'
	beq $t2 $0 end #No new Value read
	nop
	lw $t2 0xffff0004 #Read the action
	beq $t2 0x57 store #If read 'W'
	nop
	beq $t2 0x77 store #If read 'w'
	nop
	beq $t2 0x41 store #If read 'A'
	nop
	beq $t2 0x61 store #If read 'a'
	nop
	beq $t2 0x53 store #If read 'S'
	nop
	beq $t2 0x73 store #If read 's'
	nop
	beq $t2 0x44 store #If read 'D'
	nop
	beq $t2 0x64 store #If read 'd'
	nop
	j end #Invalid key
	nop
store:
	pushFByte $t2 #Sends movement to the FIFO List
	j end
	nop
end:
	popWord $t2
.end_macro

#Moves the piece according to the FIFO List
.macro mover (%p1, %p2, %p3, %p4) #$1 to 4: Pointesr to the piece to move; $v0: Returns 1 if no move is made.
	pushWord $t2
	isFEmpty
	and $t2 $v0 $v0 #Saves return of the function
	ori $v0 $0 1 #Set return to fail to be changed if the piece is moved
	beq $t2 $0 end #Jump if there is no moviment in FIFO List
	nop
	popFByte $t2 #Get move from the FIFO List
	beq $t2 0x57 Spin #If read 'W'
	nop
	beq $t2 0x77 Spin #If read 'w'
	nop
	beq $t2 0x41 Left #If read 'A'
	nop
	beq $t2 0x61 Left #If read 'a'
	nop
	beq $t2 0x53 Right #If read 'S'
	nop
	beq $t2 0x73 Right #If read 's'
	nop
	beq $t2 0x44 SoftDrop #If read 'D'
	nop
	beq $t2 0x64 SoftDrop #If read 'd'
	nop
Spin:
	and $v0 $0 $0 #Set return falg to indicates move made
	j end
	nop
Left:
	moveLeft %p1 %p2 %p3 %p4
	#and $v0 $0 $0 #Set return falg to indicates move made
	j end
	nop
Right:
	moveDown %p1 %p2 %p3 %p4
	#and $v0 $0 $0 #Set return falg to indicates move made
	j end
	nop
SoftDrop:
	moveRight %p1 %p2 %p3 %p4
	#and $v0 $0 $0 #Set return falg to indicates move made
#	j end #No need for this Jump
# nop

end:
	popWord $t2
.end_macro

#Moves down a block
.macro moveDown (%p1, %p2, %p3, %p4) #$1 to 4: Pointesr to the piece to move; $v0: Returns 1 if fails to move.
	pushWord $t2
	pushWord $t3
	pushWord $t4

	and $t3 %p1 %p1 #Copy the pointer
	nextSquareVertical $t3 1
	isBlockFree $t3
	beq $t3 %p2 test2 #A piece can't be traped but itself
	nop
	beq $t3 %p3 test2 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test2 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free and returns a flag
	nop

	test2:
	and $t3 %p2 %p2 #Copy the pointer
	nextSquareVertical $t3 1
	isBlockFree $t3
	beq $t3 %p1 test3 #A piece can't be traped but itself
	nop
	beq $t3 %p3 test3 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test3 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free and returns a flag
	nop

	test3:
	and $t3 %p3 %p3 #Copy the pointer
	nextSquareVertical $t3 1
	isBlockFree $t3
	beq $t3 %p1 test4 #A piece can't be traped but itself
	nop
	beq $t3 %p2 test4 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test4 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free and returns a flag
	nop

	test4:
	and $t3 %p4 %p4 #Copy the pointer
	nextSquareVertical $t3 1
	isBlockFree $t3
	beq $t3 %p1 outTests #A piece can't be traped but itself
	nop
	beq $t3 %p2 outTests #A piece can't be traped but itself
	nop
	beq $t3 %p3 outTests #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free and returns a flag
	nop

	outTests:
	lw $t2 8(%p1) #(2*4) Get Light
	lw $t3 2104(%p1) #(16*32*4) + (14*4)Get Dark
	lw $t4 4112(%p1) #(16*32*4*2) + (4*4)Get Color

	paintSquare $0 %p1 0
	paintSquare $0 %p2 0
	paintSquare $0 %p3 0
	paintSquare $0 %p4 0
	nextSquareVertical %p1 1
	nextSquareVertical %p2 1
	nextSquareVertical %p3 1
	nextSquareVertical %p4 1
	paintBlock $t4 $t2 $t3 %p1 0
	paintBlock $t4 $t2 $t3 %p2 0
	paintBlock $t4 $t2 $t3 %p3 0
	paintBlock $t4 $t2 $t3 %p4 0

	and $v0 $0 $0 #Set return value to success
	j end
	nop
fail:
	ori $v0 $0 1
end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Moves a block to the right
.macro moveRight (%p1, %p2, %p3, %p4) #$1 to 4: Pointesr to the piece to move; $v0: Returns 1 if fails to move.
	pushWord $t2
	pushWord $t3
	pushWord $t4

	and $t3 %p1 %p1 #Copy the pointer
	nextSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p2 test2 #A piece can't be traped but itself
	nop
	beq $t3 %p3 test2 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test2 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	test2:
	and $t3 %p2 %p2 #Copy the pointer
	nextSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p1 test3 #A piece can't be traped but itself
	nop
	beq $t3 %p3 test3 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test3 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	test3:
	and $t3 %p3 %p3 #Copy the pointer
	nextSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p1 test4 #A piece can't be traped but itself
	nop
	beq $t3 %p2 test4 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test4 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop


	test4:
	and $t3 %p4 %p4 #Copy the pointer
	nextSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p1 outTests #A piece can't be traped but itself
	nop
	beq $t3 %p2 outTests #A piece can't be traped but itself
	nop
	beq $t3 %p3 outTests #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	outTests:
	lw $t2 8(%p1) #(2*4) Get Light
	lw $t3 2104(%p1) #(16*32*4) + (14*4)Get Dark
	lw $t4 4112(%p1) #(16*32*4*2) + (4*4)Get Color

	paintSquare $0 %p1 0
	paintSquare $0 %p2 0
	paintSquare $0 %p3 0
	paintSquare $0 %p4 0
	nextSquareHorizontal %p1 1
	nextSquareHorizontal %p2 1
	nextSquareHorizontal %p3 1
	nextSquareHorizontal %p4 1
	paintBlock $t4 $t2 $t3 %p1 0
	paintBlock $t4 $t2 $t3 %p2 0
	paintBlock $t4 $t2 $t3 %p3 0
	paintBlock $t4 $t2 $t3 %p4 0

	and $v0 $0 $0 #Set return value to success
	j end
	nop
fail:
	ori $v0 $0 1
end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Moves a block to the left
.macro moveLeft (%p1, %p2, %p3, %p4) #$1 to 4: Pointesr to the piece to move; $v0: Returns 1 if fails to move.
	pushWord $t2
	pushWord $t3
	pushWord $t4

	and $t3 %p1 %p1 #Copy the pointer
	previousSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p2 test2 #A piece can't be traped but itself
	nop
	beq $t3 %p3 test2 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test2 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	test2:
	and $t3 %p2 %p2 #Copy the pointer
	previousSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p1 test3 #A piece can't be traped but itself
	nop
	beq $t3 %p3 test3 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test3 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	test3:
	and $t3 %p3 %p3 #Copy the pointer
	previousSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p1 test4 #A piece can't be traped but itself
	nop
	beq $t3 %p2 test4 #A piece can't be traped but itself
	nop
	beq $t3 %p4 test4 #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	test4:
	and $t3 %p4 %p4 #Copy the pointer
	previousSquareHorizontal $t3 1
	isBlockFree $t3
	beq $t3 %p1 endTestes #A piece can't be traped but itself
	nop
	beq $t3 %p2 endTestes #A piece can't be traped but itself
	nop
	beq $t3 %p3 endTestes #A piece can't be traped but itself
	nop
	beq $v0 $0 fail #Dont Move if space isn't free
	nop

	endTestes:
	lw $t2 8(%p1) #(2*4) Get Light
	lw $t3 2104(%p1) #(16*32*4) + (14*4)Get Dark
	lw $t4 4112(%p1) #(16*32*4*2) + (4*4)Get Color

	paintSquare $0 %p1 0
	paintSquare $0 %p2 0
	paintSquare $0 %p3 0
	paintSquare $0 %p4 0
	previousSquareHorizontal %p1 1
	previousSquareHorizontal %p2 1
	previousSquareHorizontal %p3 1
	previousSquareHorizontal %p4 1
	paintBlock $t4 $t2 $t3 %p1 0
	paintBlock $t4 $t2 $t3 %p2 0
	paintBlock $t4 $t2 $t3 %p3 0
	paintBlock $t4 $t2 $t3 %p4 0

	and $v0 $0 $0
	j end
	nop
fail:
	ori $v0 $0 1
end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

######################
# Drown Piece Macros #
######################

#Paint a blue Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 1 if fail to create
.macro bluePiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0x4141FF #Color
	ori $t3 $0 0x5182FF #Light
	ori $t4 $0 0x2800ba #Dark

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	nextSquareVertical %p2 1 #Set %p2

	#Set %p3
	and %p3 %p2 %p2
	previousSquareHorizontal %p3 1 #Set %p3

	#Set %p3
	and %p4 %p2 %p2
	nextSquareHorizontal %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Paint a purple Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 0 if fail to create
.macro purplePiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0x9241F3 #Color
	ori $t3 $0 0xA271FF #Light
	ori $t4 $0 0x6110A2 #Dark

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	nextSquareVertical %p2 1 #Set %p2

	#Set %p3
	and %p3 %p2 %p2
	nextSquareVertical %p3 1 #Set %p3

	#Set %p3
	and %p4 %p3 %p3
	nextSquareVertical %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Paint a orange Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 1 if fail to create
.macro orangePiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0xE35100 #Color
	ori $t3 $0 0xFF7930 #Light
	ori $t4 $0 0xA23000 #Dark

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	nextSquareHorizontal %p2 1 #Set %p2

	#Set %p3
	and %p3 %p1 %p1
	nextSquareVertical %p3 1 #Set %p3

	#Set %p3
	and %p4 %p3 %p3
	nextSquareHorizontal %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Paint a green Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 1 if fail to create
.macro greenPiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0x51a200 #Color
	ori $t3 $0 0x9aeb00 #Light
	ori $t4 $0 0x386900 #Shadow

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	nextSquareVertical %p2 1 #Set %p2

	#Set %p3
	and %p3 %p2 %p2
	previousSquareHorizontal %p3 1 #Set %p3

	#Set %p3
	and %p4 %p3 %p3
	previousSquareHorizontal %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Paint a pink Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 1 if fail to create
.macro pinkPiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0xDB4161 #Color
	ori $t3 $0 0xFF61B2 #Light
	ori $t4 $0 0xB21030 #Shadow

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	nextSquareVertical %p2 1 #Set %p2

	#Set %p3
	and %p3 %p2 %p2
	nextSquareHorizontal %p3 1 #Set %p3

	#Set %p3
	and %p4 %p3 %p3
	nextSquareHorizontal %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Paint a yellow Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 1 if fail to create
.macro yellowPiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0xEBD320 #Color
	ori $t3 $0 0xFFF392 #Light
	ori $t4 $0 0x8A8A00 #Shadow

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	previousSquareHorizontal %p2 1 #Set %p2

	#Set %p3
	and %p3 %p1 %p1
	nextSquareVertical %p3 1 #Set %p3

	#Set %p3
	and %p4 %p3 %p3
	nextSquareHorizontal %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#Paint a white Piece based on %p1 position and set the 4 arguments to the 4 squares
#Returns 1 if fail to create
.macro whitePiece (%p1, %p2, %p3, %p4) #$1 - 4: Pointers to the piece;
	pushWord $t2
	pushWord $t3
	pushWord $t4

	ori $t2 $0 0xEBEBEB #Color
	ori $t3 $0 0xFFFFFF #Light
	ori $t4 $0 0xB2B2B2 #Shadow

	#No need to set %p1

	#Set %p2
	and %p2 %p1 %p1
	nextSquareHorizontal %p2 1 #Set %p2

	#Set %p3
	and %p3 %p1 %p1
	nextSquareVertical %p3 1 #Set %p3

	#Set %p3
	and %p4 %p3 %p3
	previousSquareHorizontal %p4 1 #Set %p4

	isBlockFree %p1 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p2 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p3 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop
	isBlockFree %p4 #Returns 0 if block isn't free for moving
	beq $v0 $0 end
	nop

	paintBlock $t2 $t3 $t4 %p1 0
	paintBlock $t2 $t3 $t4 %p2 0
	paintBlock $t2 $t3 $t4 %p3 0
	paintBlock $t2 $t3 $t4 %p4 0

	end:
	popWord $t4
	popWord $t3
	popWord $t2
.end_macro

#############
# MAIN CODE #
#############
.text

main:
	jal printBaseInterface
	nop
	and $s2 $v0 $v0 #Score Box Pointer
	and $s3 $v1 $v1 #Lines Box Pointer

	and $s1 $gp $gp #Pointer to block
	nextSquareVertical $s1 1
	nextSquareHorizontal $s1 9 #Set position of inicial block

playLoop:
	and $a0 $s1 $s1 #Pointer to piece Start
	ori $v0 $0 1
	jal GeneratePiece
	nop
	beq $v0 $0 gameOver
	nop

	jal MovePiece
	nop

	j playLoop
	nop
gameOver:
	ori $v0 $0 0xA
	syscall #End the game

#Subrotine to generate a random piece
#Takes $a0 as argument to creat a piece at that point
#Returns 4 pointers in $a0 to $a3 to the piece
#Returns 0 at $v0 if fail to creat a piece
	GeneratePiece:
		pushWord $t0
		pushWord $a0
		ori $v0 $0 42 #Code to random number from range
		ori $t0 $0 7
		ori $a0 $0 1 #set Lower Value
		ori $a1 $0 9999 #Set Highter Value
		syscall #Generates a random number and saves on $a0
		div $a0 $t0 #Mod 7
		mfhi $t0
		popWord $a0

		beq $t0 0 green
		nop
		beq $t0 1 pink
		nop
		beq $t0 2 blue
		nop
		beq $t0 3 yellow
		nop
		beq $t0 4 white
		nop
		beq $t0 5 orange
		nop
		beq $t0 6 purple
		nop


	green:
		greenPiece $a0 $a1 $a2 $a3
		j end
		nop
	pink:
		pinkPiece $a0 $a1 $a2 $a3
		j end
		nop
	blue:
		bluePiece $a0 $a1 $a2 $a3
		j end
		nop
	yellow:
		yellowPiece $a0 $a1 $a2 $a3
		j end
		nop
	white:
		whitePiece $a0 $a1 $a2 $a3
		j end
		nop
	orange:
		orangePiece $a0 $a1 $a2 $a3
		j end
		nop
	purple:
		purplePiece $a0 $a1 $a2 $a3
		#j end
		#nop
	end:
	popWord $t0
	jr $ra
	nop

#Subrotine to move the piece
	MovePiece: #Takes 4 arguments, the pointers to the piece
		startFila
		and $t0 $0 $0

	loop:
		salvarMovimento
		addi $t0 $t0 1
		bgt $t0 19999 autoMove #Control time to move
		nop
		salvarMovimento
		mover $a0 $a1 $a2 $a3
		#salvarMovimento
		beq $v0 1 loop #If no move was made jump
		nop
		addi $t0 $t0 9999 #If move was made increment to drop a little faster
		j loop
		nop
	autoMove:
		salvarMovimento
		add $t0 $0 $0
		moveDown $a0 $a1 $a2 $a3
		salvarMovimento
		bne $v0 $0 stop	# if $v0 != 0 then
		nop
		j loop
		nop
	stop:
	jr $ra
	nop

printBaseInterface:
	la $a0 0x797979 #Gray Border Color
	#la $s1 0x10000000 #Pointer to the start of the display
	and $a1 $gp $gp
	and $v0 $0 $0 #Space for the Score Pointer
	and $v1 $0 $0 #Space for the Lines Pointer

	paintFullLine $a0 $a1 1
	printCleanLine $a0 $a1 1
	printNextLine $a0 $a1

	printNextBlockLine $a0 $a1 6

	printCleanLine $a0 $a1 1
	printScoreLine $a0 $a1
	printSmallBoxLine $a0 $a1
	and $t0 $v0 $v0
	printCleanLine $a0 $a1 2
	printLinesLine $a0 $a1
	printSmallBoxLine $a0 $a1
	and $v1 $v0 $v0
	and $v0 $t1 $t1
	printCleanLine $a0 $a1 15
	paintFullLine $a0 $a1 1
	jr $ra
	nop
