*
*  PROGRAM:    ZUIDSTCK
*  AUTHOR:     Randy Frerking.
*  DATE:       June 29, 2014
*  COMMENTS:   Get STCKE TOD for COBOL program.
*
*
***********************************************************************
* Application dynamic storage area - start                            *
***********************************************************************
DSA      DSECT
EISTOD   DS    CL16               STCKE TOD time
*
***********************************************************************
* Application dynamic storage area - end                              *
***********************************************************************
*
*
***********************************************************************
* Control Section                                                     *
***********************************************************************
ZUIDSTCK AMODE 31
ZUIDSTCK RMODE 31
ZUIDSTCK CSECT
         STM   R14,R12,12(R13)         Save registers
         L     R1,0(R1)                Load parameter address
         USING DSA,R1                  ... tell assember
         STCKE EISTOD                  Save STCKE TOD
*
         LM    R14,R12,12(R13)         Load Registers
         XR    R15,R15                 Clear R15 (RC)
         BR    R14                     Return to calling program
*
         DC    CL08'ZUIDSTCK  '
         DC    CL48' -- Get STCKE TOD for COBOL program             '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
*
***********************************************************************
* Literal Pool                                                        *
***********************************************************************
         LTORG
         DS   0F
*
***********************************************************************
* Register assignments                                                *
***********************************************************************
         DS   0F
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
*
***********************************************************************
* End of Program                                                      *
***********************************************************************
         END   ZUIDSTCK