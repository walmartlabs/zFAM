*
*  PROGRAM:    ZFAM006
*  AUTHOR:     Rich Jackson and Randy Frerking
*  COMMENTS:   zFAM - z/OS File Access Manager
*
*              This program is called by zFAM browse (GT) program
*              zFAM004 to increment a 255 byte key by one bit.
*
*              The key is 255 bytes alphanumeric data.
*              This algorithm is used to increment a 255 byte field by
*              one bit, used for GT record search.
*
***********************************************************************
* Dynamic Storage Area (Start)                                        *
***********************************************************************
DFHEISTG DSECT
APPLID   DS    CL08               CICS Applid
SYSID    DS    CL04               CICS SYSID
*
***********************************************************************
* Dynamic Storage Area (End)                                          *
***********************************************************************
*
***********************************************************************
* DFHCOMMAREA                                                         *
***********************************************************************
*
DFHCA    DSECT
CA_TYPE  DS    CL02               Query string type
CA_ROWS  DS    CL04               Number of rows to return
CA_DELIM DS    CL01               Delimiter
CA_KEYS  DS    CL01               Keys Only request
CA_TTL   DS    CL01               TTL       request
         DS    CL07               Alignment
CA_KEY_L DS    F                  Keylength
CA_KEY   DS    CL255              Key
CA_LEN   EQU   *-CA_KEY           Length
***********************************************************************
* Control Section                                                     *
***********************************************************************
ZFAM006  DFHEIENT CODEREG=(R12),DATAREG=R10,EIBREG=R11
ZFAM006  AMODE 31
ZFAM006  RMODE 31
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'ZFAM006 '
         DC    CL48' -- zFAM GT browse key increment                '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
SYSDATE  DS   0H
***********************************************************************
* Address DFHCOMMAREA                                                 *
***********************************************************************
         L     R9,DFHEICAP             Load DFHCOMMAREA address
         USING DFHCA,R9                ... tell assembler
*
         LA    R2,CA_LEN               Set max length
         S     R2,=F'3'                Augment length
         LA    R3,CA_KEY               Set key address
*
         LA    R1,CA_LEN               Set max length
         S     R1,=F'4'                Subtract one word length
         LA    R3,0(R1,R3)             Point to last word
*
SY_SCAN  DS   0H
         CLC   0(4,R3),=X'FFFFFFFF'    Max value for a word?
         BC    B'1000',SY_NEXT         ... yes, get next word
         L     R4,0(R3)                Load current word into R4
         A     R4,=F'1'                Increment by one
         ST    R4,0(R3)                Save current word into R3
         BC    B'1111',SY_DONE         Done
*
SY_NEXT  DS   0H
         MVI   3(R3),X'00'             Roll last byte over
         S     R3,=F'1'                Point to previous byte/word
         BCT   R2,SY_SCAN              Continue scan
*
SY_DONE  DS   0H
*
***********************************************************************
* Return to caller                                                    *
**********************************************************************
RETURN   DS   0H
         EXEC CICS RETURN
*
*
***********************************************************************
* Literal Pool                                                        *
**********************************************************************
         LTORG
*
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
         PRINT ON
***********************************************************************
* End of Program                                                      *
**********************************************************************
         END   ZFAM006