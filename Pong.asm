STACK SEGMENT PARA STACK
	DB 64 DUP (' ') ;DB (DEFINE BYTES)
	; DUp Giver lov til at allokere flere bytes
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	WINDOW_WIDTH DW 140h                 ;window bredde (320 pixels)
	WINDOW_HEIGHT DW 0C8h                ;window højde (200 pixels)
	WINDOW_BOUNDS DW 6                   ;variabel brugt til at se kollisioner tidligt, bare et offset!
	
	VariabelNavn DW 0Ah		;DW Define Word
	
	TIME_AUX DB 0                        ;brugt til at se om tid er ændret
	
	BALL_ORIGINAL_X DW 0A0h              ;X position i starten af spillet
	BALL_ORIGINAL_Y DW 64h               ;Y position i starten af spillet
	BALL_X DW 0A0h                       ;current X position (column) af bolden
	BALL_Y DW 64h                        ;current Y position (line) af bolden
	BALL_SIZE DW 04h                     ;størrelse af bold (width og height) (i pixels)
	BALL_VELOCITY_X DW 05h               ;X (horizontal) velocity af bold
	BALL_VELOCITY_Y DW 02h               ;Y (vertical) velocity af bold
	
	PADDLE_LEFT_X DW 0Ah                 ;current X position af paddle 
	PADDLE_LEFT_Y DW 0Ah                 ;current Y position af paddle
	
	PADDLE_RIGHT_X DW 130h               ;current X position af paddle 
	PADDLE_LEFT_Y DW 0Ah                 ;current Y position af paddle
	
	PADDLE_WIDTH DW 05h                  ;default paddle width
	PADDLE_HEIGHT DW 1Fh                 ;default paddle height
	PADDLE_VELOCITY DW 05h               ;default paddle velocity

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK      ;assume as code,data and stack segments the respective registers
	PUSH DS                              ;push stack til DS segment
	SUB AX,AX                            ;clean AX register
	PUSH AX                              ;push AX til stack
	MOV AX,DATA                          ;Gem i AX registeret indhold fra DATA segmentet
	MOV DS,AX                            ;Gem i DS segment indhold fra AX
	POP AX                               ;release the top item from the stack to the AX register
	POP AX                               ;release the top item from the stack to the AX register
		
		CALL CLEAR_SCREEN                ;set initial video mode configurations
		
		CHECK_TIME:                      ;time checking loop
		
			MOV AH,2ch			 ;get the system time
			INT 21h    					 ;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL,TIME_AUX  			 ;er den nuværende tid lig med den forrige(TIME_AUX)?
			JE CHECK_TIME    		     ;if it is the same, check again
			
;           If it reaches this point, it's because the time has passed
  
			MOV TIME_AUX,DL              ;update time
			
			CALL CLEAR_SCREEN            ;clear the screen by restarting the video mode
			
			CALL MOVE_BALL               ;move the ball
			CALL DRAW_BALL               ;draw the ball
			
			CALL MOVE_PADDLES            ;move the two paddles (check for pressing of keys)
			CALL DRAW_PADDLES            ;draw the two paddles with the updated positions
			
			JMP CHECK_TIME               ;after everything checks time again
		
		RET
	MAIN ENDP
	
	MOVE_BALL PROC NEAR                  ;proccess the movement of the ball
		
;       Move the ball horizontally
		MOV AX,BALL_VELOCITY_X    
		ADD BALL_X,AX                   
		
;       Check if the ball has passed the left boundarie (BALL_X < 0 + WINDOW_BOUNDS)
;       If is colliding, restart its position		
		MOV AX,WINDOW_BOUNDS
		CMP BALL_X,AX                    ;BALL_X is compared with the left boundarie of the screen (0 + WINDOW_BOUNDS)          
		JNL RESET_POSITION_1  
		JMP RESET_POSITION	;if is less, reset position
		
;       Check if the ball has passed the right boundarie (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)
;       If is colliding, restart its position	
		RESET_POSITION_1:	
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX	                ;BALL_X is compared with the right boundarie of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)  
		JNG RESET_POSITION_2               ;if is greater, reset position
		JMP RESET_POSITION
		
		RESET_POSITION_2:
;       Move the ball vertically		
		MOV AX,BALL_VELOCITY_Y
		ADD BALL_Y,AX             
		
;       Check if the ball has passed the top boundarie (BALL_Y < 0 + WINDOW_BOUNDS)
;       If is colliding, reverse the velocity in Y
		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                    ;BALL_Y is compared with the top boundarie of the screen (0 + WINDOW_BOUNDS)
		JNL NEG_VELOCITY_Y_JMP                ;if is less reverve the velocity in Y
		JMP NEG_VELOCITY_Y

		NEG_VELOCITY_Y_JMP:
;       Check if the ball has passed the bottom boundarie (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
;       If is colliding, reverse the velocity in Y		
		MOV AX,WINDOW_HEIGHT	
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                    ;BALL_Y is compared with the bottom boundarie of the screen (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
		JG NEG_VELOCITY_Y		         ;if is greater reverve the velocity in Y
		
		
;       Check if the ball is colliding with the right paddle
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there's no collision check for the left paddle collisions
		
		MOV AX,PADDLE_RIGHT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there's no collision check for the left paddle collisions
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there's no collision check for the left paddle collisions
		
		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE  ;if there's no collision check for the left paddle collisions
		
;       If it reaches this point, the ball is colliding with the right paddle

		NEG BALL_VELOCITY_X              ;reverses the horizontal velocity of the ball
		RET                              
			

;       Check if the ball is colliding with the left paddle
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		
		;samme for den anden paddle
		
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_X
		JNG EXIT_PROC
		
		
		MOV AX,PADDLE_LEFT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL EXIT_PROC
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_Y
		JNG EXIT_PROC
		
		MOV AX,PADDLE_LEFT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL EXIT_PROC
		
		NEG BALL_VELOCITY_X
		RET
		
		RESET_POSITION:                  
			CALL RESET_BALL_POSITION     ;reset ball position to the center of the screen
			RET
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y   ;reverse the velocity in Y of the ball (BALL_VELOCITY_Y = - BALL_VELOCITY_Y)
			RET
		EXIT_PROC:
			RET
		
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR               ;process movement of the paddles
		
;       Left paddle movement
		
		;check if any key is being pressed (if not check the other paddle)
		MOV AH,01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT ;ZF = 1, JZ -> Jump If Zero
		
		;check which key is being pressed (AL = ASCII character)
		MOV AH,00h
		INT 16h
		
		;if it is 'w' or 'W' move up
		CMP AL,77h ;'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h ;'W'
		JE MOVE_LEFT_PADDLE_UP
		
		;if it is 's' or 'S' move down
		CMP AL,73h ;'s'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h ;'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		
;       Right paddle movement 
		CHECK_RIGHT_PADDLE_MOVEMENT:
		
			;if it is 'o' or 'O' move up
			CMP AL,6Fh ;'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4Fh ;'O'
			JE MOVE_RIGHT_PADDLE_UP
			
			;if it is 'l' or 'L' move down
			CMP AL,6Ch ;'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4Ch ;'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			
			;bevæger den højre paddle op
			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
		
		EXIT_PADDLE_MOVEMENT:
		
			RET
		
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR        ;restart ball position to the original position
		
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_BALL PROC NEAR                  
		
		MOV CX,BALL_X                    ;set the initial column (X)
		MOV DX,BALL_Y                    ;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch                   ;set the configuration to writing a pixel
			MOV AL,0Fh 					 ;choose white as color
			MOV BH,00h 					 ;set the page number 
			INT 10h    					 ;execute the configuration
			
			INC CX     					 ;CX = CX + 1
			MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X 				 ;the CX register goes back to the initial column
			INC DX       				 ;we advance one line
			
			MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		
		RET
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
		
		MOV CX,PADDLE_LEFT_X 			 ;set the initial column (X)
		MOV DX,PADDLE_LEFT_Y 			 ;set the initial line (Y)
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch 					 ;set the configuration to writing a pixel
			MOV AL,0Fh 					 ;choose white as color
			MOV BH,00h 					 ;set the page number 
			INT 10h    					 ;execute the configuration
			
			INC CX     				 	 ;CX = CX + 1
			MOV AX,CX         			 ;CX - PADDLE_LEFT_X > PADDLE_WIDTH (Y -> We go to the next line,N -> We continue to the next column
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			MOV CX,PADDLE_LEFT_X 		 ;the CX register goes back to the initial column
			INC DX       				 ;we advance one line
			
			MOV AX,DX            	     ;DX - PADDLE_LEFT_Y > PADDLE_HEIGHT (Y -> we exit this procedure,N -> we continue to the next line
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			
		MOV CX,PADDLE_RIGHT_X 			 ;set the initial column (X)
		MOV DX,PADDLE_RIGHT_Y 			 ;set the initial line (Y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0Ch 					 ;set the configuration to writing a pixel
			MOV AL,0Fh 					 ;choose white as color
			MOV BH,00h 					 ;set the page number 
			INT 10h    					 ;execute the configuration
			
			INC CX     					 ;CX = CX + 1
			MOV AX,CX         			 ;CX - PADDLE_RIGHT_X > PADDLE_WIDTH (Y -> We go to the next line,N -> We continue to the next column
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX,PADDLE_RIGHT_X		 ;the CX register goes back to the initial column
			INC DX       				 ;we advance one line
			
			MOV AX,DX            	     ;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Y -> we exit this procedure,N -> we continue to the next line
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
		RET
	DRAW_PADDLES ENDP
	
	CLEAR_SCREEN PROC NEAR               ;clear the screen by restarting the video mode
	
			MOV AH,00h                   ;set the configuration to video mode
			MOV AL,13h                   ;choose the video mode
			INT 10h    					 ;execute the configuration 
		
			MOV AH,0Bh 					 ;set the configuration
			MOV BH,00h 					 ;to the background color
			MOV BL,00h 					 ;choose black as background color
			INT 10h    					 ;execute the configuration
			
			RET
			
	CLEAR_SCREEN ENDP

CODE ENDS
END