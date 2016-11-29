*
*  PROGRAM:    L8WAIT
*  AUTHOR:     Randy Frerking.
*  COMMENTS:   zFAM - z/OS File Access Manager.
*
*              Issue z/OS STIMERM macro.
*              This program must be defined as Threadsafe (Required),
*              OpenAPI and CICSKey to execeute on an L8 TCB.
*
*              Default wait is 2.5 milliseconds
*
***********************************************************************
* Dynamic Storage Area    (start)                                     *
***********************************************************************
DFHEISTG DSECT
STIMERID DS    CL04               STIMERM ID
MS_WAIT  DS    F                  Fullword 01ms to 900ms WAIT
*
***********************************************************************
* Dynamic Storage Area    (end  )                                     *
***********************************************************************
*
***********************************************************************
* DFHCOMMAREA from requesting program  (start)                        *
***********************************************************************
CACBAR   EQU   12
DFHCA    DSECT
CA_RC    DS    CL04               RETURN CODE
CA_WAIT  DS    F                  Fullword from 1 (10ms) to 90 (900ms)
CA_LEN   EQU   *-DFHCA
***********************************************************************
* DFHCOMMAREA from requesting program  (end  )                        *
***********************************************************************
*
***********************************************************************
* Control Section                                                     *
***********************************************************************
L8WAIT   DFHEIENT CODEREG=(2),DATAREG=10,EIBREG=11
L8WAIT   AMODE 31
L8WAIT   RMODE ANY
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'L8WAIT  '
         DC    CL48' -- z/OS STIMERM running on an L8 TCB  '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
SYSDATE  DS   0H
***********************************************************************
* ENTER TRACENUM before STIMERM                                       *
***********************************************************************
SY_0010  DS   0H
         EXEC CICS ENTER TRACENUM(T_35)                                X
              FROM(T_35_M)                                             X
              FROMLENGTH(T_LEN)                                        X
              RESOURCE(T_RES)                                          X
              NOHANDLE
***********************************************************************
* Address DFHCOMMAREA.  If not present, use 2.5 millisecond default.  *
***********************************************************************
SY_0020  DS   0H
         LA    R1,CA_LEN               Load DSECT length
         LH    R15,EIBCALEN            Load DFHCOMMAREA length
         CR    R1,R15                  Valid length?
         BC    B'0111',SY_0800         ... no,  use 2.5ms default
         L     R12,DFHEICAP            Load DFHCOMMAREA
         USING DFHCA,R12               ... tell assembler
***********************************************************************
* The valid range accepted is 1, which equates to 10 milliseconds     *
* thru 90, which equates to 900 milliseconds.  Any value less than 1  *
* will be set to 1 and any value greater than 90 will be set to 90.   *
***********************************************************************
SY_0030  DS   0H
         MVC   CA_RC,RC_0001           Set RC for default
         MVC   MS_WAIT,=F'1'           Set default 10 milliseconds
         CLC   CA_WAIT,=F'0'           Zero or less?
         BC    B'1100',SY_0100         ... yes, use 10ms default
         MVC   CA_RC,RC_0090           Set RC for default
         MVC   MS_WAIT,=F'90'          Set maximum 900 milliseconds
         CLC   CA_WAIT,=F'90'          Greater than 900 milliseconds?
         BC    B'0011',SY_0100         ... yes, use 900ms default
         MVC   MS_WAIT,CA_WAIT         Use requested interval
         MVC   CA_RC,RC_0000           Set RC for requested wait
***********************************************************************
* Issue z/OS STIMERM.                                                 *
* Using fullword binary value of 1 (10ms) thru 90 (900ms)             *
***********************************************************************
SY_0100  DS   0H
         LA   R3,STIMERID              Load STIMER ID
         LA   R4,MS_WAIT               Load wait time
         STIMERM SET,BINTVL=(R4),WAIT=YES,ID=(R3)
         BC   B'1111',SY_0900          Exit trace
***********************************************************************
* Issue z/OS STIMERM.                                                 *
* 2.5 milliseconds (2500 microseconds)                                *
***********************************************************************
SY_0800  DS   0H
         LA   R3,STIMERID              Load STIMER ID
         STIMERM SET,MICVL=MIC2500,WAIT=YES,ID=(R3)
***********************************************************************
* ENTER TRACE after  STIMERM                                          *
***********************************************************************
SY_0900  DS   0H
*
         EXEC CICS ENTER TRACENUM(T_46)                                X
              FROM(T_46_M)                                             X
              FROMLENGTH(T_LEN)                                        X
              RESOURCE(T_RES)                                          X
              NOHANDLE
***********************************************************************
* Return to calling program                                           *
***********************************************************************
RETURN   DS   0H
         EXEC CICS RETURN
***********************************************************************
* Literal Pool                                                        *
***********************************************************************
         LTORG
*
RC_0001  DC    CL04'0010'              Default RC for  10MS
RC_0090  DC    CL04'0900'              Default RC for 900MS
RC_0000  DC    CL04'0000'              Default RC for requested wait
*
T_35     DC    H'35'                   TRACE number  before STIMERM
T_46     DC    H'46'                   TRACE number  after  STIMERM
T_35_M   DC    CL08'GoodNite'          TRACE message before STIMERM
T_46_M   DC    CL08'Wake-Up!'          TRACE message after  STIMERM
T_RES    DC    CL08'L8WAIT    '        TRACE resource
T_LEN    DC    H'08'                   TRACE message length
         DS   0D
MIC0256  DC    F'0'                    1st word
         DC    F'01048576'             0.2 milliseconds
         DS   0D
MIC1024  DC    F'0'                    1st word
         DC    F'04194304'             1.0 milliseconds
         DS   0D
MIC2500  DC    F'0'                    1st word
         DC    F'10240000'             2.5 milliseconds
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
         END   L8WAIT