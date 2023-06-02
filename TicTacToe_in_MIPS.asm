#-------------------------------------------------------------------------------------------#
.data 														# data declaration section

board: .word 0:9 												# tic tac toe board array

																# For drawing the board and pieces
horizontalBreak: .asciiz "-----\n" 									# horizontal bar between rows
verticalBar: .asciiz "|"											# vertical bar between columns
newLine: .asciiz "\n"												# new line
X: .asciiz "X"														# X
O: .asciiz "O"														# O

playerPrompt: .asciiz "Player: Where would you like to play?\n"	# prompt for player
computerPrompt: .asciiz "Computer plays: \n"					# prompt for computer
playerWinPrompt: .asciiz "Player wins!\n"						# player win prompt
computerWinPrompt: .asciiz "Computer wins!\n"					# computer win prompt
tiePrompt: .asciiz "Tie!\n"										# tie prompt
spotTaken: .asciiz "Spot Taken. \n"								# spot taken prompt
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
.text								# code section
#-------------------------------------------------------------------------------------------#
defaultBoard:							# make board array in its default state
	li $t1, 9 								# number to add and number of times to loop
	li $t2, 4 								# offset
	la $t0, board 							# address of board array stored in $t0
	insertLoop:								# loop to insert numbers 1 to 9 in board array
		beqz $t1, endDefaultBoard 				# break if assigned last value (0)
		sw $t1, 0($t0) 							# assigns the number to the array
		subi $t1, $t1, 1 						# decrement the number
		add $t0, $t0, $t2 						# adds the offset to the array address
		j insertLoop 							# repeat if not finished
	endDefaultBoard:							# acts as a break
jal printBoard								# print the board
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
playerTurn:								# Player's turn
											# To Understand where the human wants to play:
												# Get input about which square the humans wants to play on
													# Prompt the user to input a number from 1 to 9 
	la $a0, playerPrompt 								# load player prompt into $a0
	li $v0, 4											# evoke print call in $v0 (4 is print string)
	syscall												# print player prompt
													# Read where the user wants to play
	li $v0, 5   										# evoke read call in $v0
	syscall												# read user input (5 is read int)
	
												# Calculate offset to get actual location in array and check if spot is empty so we can actually play there
	sll $t0, $v0, 2 								# Multiply by 4
	li $t1, 36										# 36 is the offset of the last item in the array (9*4)
	sub $t0, $t1, $t0 								# $t0 has offset of where the item needs to go in the array

	la $t1, board									# load address of board array into $t1
	add $t1, $t1, $t0								# add offset to address of board array
	lw $t6, 0($t1)									# load the value at the offset into $t6
	sgt $t6, $t6, 10								# check if the value is greater than 10, if it is set $t6 to 1, if not set $t6 to 0. We do this because the ASCII value of X is 88 and the ascii value of O is 79. So if the value is greater than 10 it is either X or O and we can't play there.
	beqz $t6, spotEmpty 							# if $t6 is 0 then the spot is empty and we can play there
	la $a0, spotTaken								# if the spot is not empty then print spot taken
	li $v0, 4										# evoke print call in $v0 (4 is print string)
	syscall 										# print spot taken
	jal printBoard									# print the board
	j playerTurn									# repeat the player turn
	
	spotEmpty:								# When spot is empty
	la $t7, O#assumes player is O's 			# load O into $t7
	sw $t7, 0($t1)								# store O in the array at the offset
	jal printBoard								# print the board

											# Now that player has played a move successfully, check if the player has won
	jal	hasPlayerWon							# check if player has won
	jal isTie									# or if it is a tie
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
computerTurn:					# Computer's turn								
									# Randomly generate a square on which the computer wants to play on and see if it is empty
										# Generate a random number from 1 to 9 by seeding the random number generator with the time
											# Seed the random number generator
	li	$v0, 30									# get time in milliseconds (as a 64-bit value)
	syscall										# syscall to get time											
	move	$t0, $a0							# save the lower 32-bits of time
												# seed the random generator (just once)
	li	$a0, 1										# random generator id (will be used later)
	move 	$a1, $t0								# seed from time
	li	$v0, 40										# seed random number generator syscall
	syscall
											# Generate a random number from 1 to 9
	li	$a0, 1									# as said, this id is the same as random generator id
	li	$a1, 9									# upper bound of the range
	li	$v0, 42									# random int range
	syscall
										# See if the spot is empty
											# Calculate offset to get actual location in array and check if spot is empty so we canactually play there
												# Calculate offset
	sll $t0, $a0, 2 								# Multiply by 4
	li $t1, 36										# 36 is the offset of the last item in the array (9*4)
	sub $t0, $t1, $t0 								#$t0 has offset of where the item needs to go in the array
												# See if the spot is empty
	la $t1, board									# load address of board array into $t1
	add $t1, $t1, $t0								# add offset to address of board array
	lw $t6, 0($t1)									# load the value at the offset into $t6
	sgt $t6, $t6, 9									# check if the value is greater than 9, if it is set $t6 to 1, if not set $t6 to 0. We do this because the ASCII value of X is 88 and the ascii value of O is 79. So if the value is greater than 9 it is either X or O and we can't play there.
	beqz $t6, spotEmpty2							# if $t6 is 0 then the spot is empty and we can play there
	j computerTurn									# if the spot is not empty then repeat the computer turn and generate a new random number
											
	spotEmpty2:							# When spot is empty
		la $a0, computerPrompt				# load computer prompt into $a0
		li $v0, 4							# evoke print call in $v0 (4 is print string)
		syscall								# print computer prompt
		la $t7, X 							# load X into $t7
		sw $t7, 0($t1) 						# store X in the array at the offset
		jal printBoard						# print the board

										# Now that computer has played a move successfully, check if the computer has won
	jal	hasComputerWon						# check if computer has won
	jal isTie								# or if it is a tie
	j playerTurn							# if computer has not won repeat the player turn
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
exit:
	li $v0, 10 
	syscall
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
printBoard:
	addi $sp, $sp, -4 				#make room for new item on stack
	sw $ra, 0($sp)					#store return address on top of the stack
	la $t0, board 					#load address of board array into $t0
	li $t1, 9 						#number of numbers left to print
	la $t2, X
	la $t3, O
	printBoardLoop:
		lw $t7, 0($t0) 				#loads the number or symobl that we need to print
		beq $t7, $t2, printX 		#prints the ascii value if it is x or o
		beq $t7, $t3, printO		       
									#if it didn't jump and print X or O the spot is empty so we must print the int value 
		move $a0, $t7
		li $v0, 1       			# print int
			syscall
		printRet:
		subi $t1, $t1, 1
		beq $t1, 6, rowEnd
		beq $t1, 3, rowEnd
		beq $t1, 0, rowEnd
		jal printVertBar
		rowRet:
		addi $t0, $t0, 4 			#add offset to print next number
		beqz $t1, exitPrintBoard
		j printBoardLoop
			exitPrintBoard:
			lw $ra, 0($sp) 			#load return register from the stack
			addi $sp, $sp, 4 		#delete $ra from stack
			jr $ra					#return
	
printVertBar: 						#prints |
la $a0, verticalBar
	li $v0, 4 						#print string
	syscall
	jr $ra  
    
printHorizontalBreak: 				#prints -----\n
	la $a0, horizontalBreak
	li $v0, 4
	syscall
	jr $ra
    
printNewLine: 						#prints \n
	la $a0, newLine
	li $v0, 4
	syscall
	jr $ra
    
printX:
    la $a0, X
    li $v0, 4
   	syscall
    j printRet
    
printO:
    la $a0, O
    li $v0, 4
    syscall
    j printRet     
    	
rowEnd:
	jal printNewLine
	jal printHorizontalBreak
	j rowRet
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
hasPlayerWon:
	#check if rows has a win condition of three O's in a row.
		#row 1
		row1P:
			la $t0, board
			la $t1, O
			lw $t2, 0($t0)
			lw $t3, 4($t0)
			lw $t4, 8($t0)
			bne $t1, $t2, row2P
			bne $t1, $t3, row2P
			bne $t1, $t4, row2P
			#row 1 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

		#row 2
		row2P:
			lw $t2, 12($t0)
			lw $t3, 16($t0)
			lw $t4, 20($t0)
			bne $t1, $t2, row3P
			bne $t1, $t3, row3P
			bne $t1, $t4, row3P
			#row 2 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

		#row 3
		row3P:
			lw $t2, 24($t0)
			lw $t3, 28($t0)
			lw $t4, 32($t0)
			bne $t1, $t2, col1P
			bne $t1, $t3, col1P
			bne $t1, $t4, col1P
			#row 3 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

	#check if columns has a win condition of three O's in a row.
		#col1
		col1P:
			lw $t2, 0($t0)
			lw $t3, 12($t0)
			lw $t4, 24($t0)
			bne $t1, $t2, col2P
			bne $t1, $t3, col2P
			bne $t1, $t4, col2P
			#col1 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

		#col2
		col2P:
			lw $t2, 4($t0)
			lw $t3, 16($t0)
			lw $t4, 28($t0)
			bne $t1, $t2, col3P
			bne $t1, $t3, col3P
			bne $t1, $t4, col3P
			#col2 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

		#col3
		col3P:
			lw $t2, 8($t0)
			lw $t3, 20($t0)
			lw $t4, 32($t0)
			bne $t1, $t2, diag1P
			bne $t1, $t3, diag1P
			bne $t1, $t4, diag1P
			#col3 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

	#check if diagonals has a win condition of three O's in a row.
		#diag1
		diag1P:
			lw $t2, 0($t0)
			lw $t3, 16($t0)
			lw $t4, 32($t0)
			bne $t1, $t2, diag2P
			bne $t1, $t3, diag2P
			bne $t1, $t4, diag2P
			#diag1 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit

		#diag2
		diag2P:
			lw $t2, 8($t0)
			lw $t3, 16($t0)
			lw $t4, 24($t0)
			bne $t1, $t2, playerNotWon
			bne $t1, $t3, playerNotWon
			bne $t1, $t4, playerNotWon
			#diag2 has a win condition
			la $a0, playerWinPrompt
			li $v0, 4
			syscall
			j exit
	
	#Player has not won
	playerNotWon:
		jr $ra
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
hasComputerWon:
	#check if rows has a win condition of three X's in a row.
		#row 1
		row1C:
			la $t0, board
			la $t1, X
			lw $t2, 0($t0)
			lw $t3, 4($t0)
			lw $t4, 8($t0)
			bne $t1, $t2, row2C
			bne $t1, $t3, row2C
			bne $t1, $t4, row2C
			#row 1 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

		#row 2
		row2C:
			lw $t2, 12($t0)
			lw $t3, 16($t0)
			lw $t4, 20($t0)
			bne $t1, $t2, row3C
			bne $t1, $t3, row3C
			bne $t1, $t4, row3C
			#row 2 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

		#row 3
		row3C:
			lw $t2, 24($t0)
			lw $t3, 28($t0)
			lw $t4, 32($t0)
			bne $t1, $t2, col1C
			bne $t1, $t3, col1C
			bne $t1, $t4, col1C
			#row 3 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

	#check if columns has a win condition of three X's in a row.
		#col1
		col1C:
			lw $t2, 0($t0)
			lw $t3, 12($t0)
			lw $t4, 24($t0)
			bne $t1, $t2, col2C
			bne $t1, $t3, col2C
			bne $t1, $t4, col2C
			#col1 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

		#col2
		col2C:
			lw $t2, 4($t0)
			lw $t3, 16($t0)
			lw $t4, 28($t0)
			bne $t1, $t2, col3C
			bne $t1, $t3, col3C
			bne $t1, $t4, col3C
			#col2 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

		#col3
		col3C:
			lw $t2, 8($t0)
			lw $t3, 20($t0)
			lw $t4, 32($t0)
			bne $t1, $t2, diag1C
			bne $t1, $t3, diag1C
			bne $t1, $t4, diag1C
			#col3 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

	#check if diagonals has a win condition of three X's in a row.
		#diag1
		diag1C:
			lw $t2, 0($t0)
			lw $t3, 16($t0)
			lw $t4, 32($t0)
			bne $t1, $t2, diag2C
			bne $t1, $t3, diag2C
			bne $t1, $t4, diag2C
			#diag1 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

		#diag2
		diag2C:
			lw $t2, 8($t0)
			lw $t3, 16($t0)
			lw $t4, 24($t0)
			bne $t1, $t2, computerNotWon
			bne $t1, $t3, computerNotWon
			bne $t1, $t4, computerNotWon
			#diag2 has a win condition
			la $a0, computerWinPrompt
			li $v0, 4
			syscall
			j exit

	#Computer has not won
	computerNotWon:
		jr $ra
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#
#Check if its a tie
isTie:
	#check if the array is full by checking if there are no numbers left in the array
	li $t1, 9 #number of times to loop
	li $t2, 4 #offset
	la $t0, board
	loop:
		beqz $t1, break #break if assigned last value (0)
		#sw $t1, 0($t0) #assigns the number to the array
		lw $t3, 0($t0) #loads the value from the array
		beq $t3, $t1, notTie #break if the value is the same as the number
		subi $t1, $t1, 1 #decrement the number
		add $t0, $t0, $t2 #adds the offset to the array address
		j loop #repeat if not finished

	#array is full
	break:
		la $a0, tiePrompt
		li $v0, 4
		syscall
		j exit

	notTie:
		jr $ra
#-------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------#