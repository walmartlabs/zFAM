*
*  PROGRAM:    ZFAM040
*  AUTHOR:     Rich Jackson and Randy Frerking
*  COMMENTS:   zFAM - z/OS File Access Manager
*
*              This program is executed as the Query Mode DELETE
*              service called by zFAM001 control program.
*
*              This program will delete primary column index and
*              delete secondary column indexes when present.
*
***********************************************************************
* Start Dynamic Storage Area                                          *
***********************************************************************
DFHEISTG DSECT
REGSAVE  DS    16F                Register Save Area
*
BAS_REG  DS    F                  BAS return register
APPLID   DS    CL08               CICS Applid
SYSID    DS    CL04               CICS SYSID
USERID   DS    CL08               CICS USERID
PA_ADDR  DS    F                  Parser   Array address
PA_LEN   DS    F                  Parser   Array length
FK_ADDR  DS    F                  zFAM Key  record address
FK_LEN   DS    F                  zFAM Key  record length
FF_ADDR  DS    F                  zFAM File record address
FF_LEN   DS    F                  zFAM File record length
FD_ADDR  DS    F                  Field container address
FD_LEN   DS    F                  Field container length
*
FA_ADDR  DS    F                  FAxxFD document address
FA_LEN   DS    F                  FAxxFD document length
FA_RESP  DS    F                  FAxxFD container response
*
         DS   0F
W_INDEX  DS    F                  Parser array index
W_ADDR   DS    F                  Beginning data area address
W_COUNT  DS    CL08               Packed decimal field count
W_COLUMN DS    CL08               Packed decimal field column
         DS   0F
C_NAME   DS    CL16               Container name
C_LENGTH DS    F                  Container data length
C_RESP   DS    F                  Container response
         DS   0F
W_PRI_ID DS    CL01               Primary column ID flag
         DS   0F
SI_PTR   DS    F                  Secondary Index pointer
SI_FIELD DS    CL56               Secondary Index field
*
***********************************************************************
* zFAM090 communication area                                          *
* Logging for ZFAM040 exceptional conditions                          *
***********************************************************************
C_LOG    DS   0F
C_STATUS DS    CL03               HTTP Status code
C_REASON DS    CL02               Reason Code
C_USERID DS    CL08               UserID
C_PROG   DS    CL08               Service program name
C_FILE   DS    CL08               File name
C_FIELD  DS    CL16               Field name
E_LOG    EQU   *-C_LOG            Commarea Data length
L_LOG    DS    H                  Commarea length
*
***********************************************************************
* File resources.                                                     *
***********************************************************************
WK_FCT   DS   0F                  zFAM Key  structure FCT name
WK_TRAN  DS    CL04               zFAM transaction ID
WK_DD    DS    CL04               zFAM KEY  DD name
*
WK_LEN   DS    H                  zFAM Key  structure length
*
WF_FCT   DS   0F                  zFAM File structure FCT name
WF_TRAN  DS    CL04               zFAM transaction ID
WF_DD    DS    CL04               zFAM FILE DD name
*
WF_LEN   DS    H                  zFAM File structure length
*
***********************************************************************
* Primary Index information                                           *
***********************************************************************
         DS   0F
PI_TYPE  DS    CL01               Actual key type
         DS   0F
PI_COL   DS    CL04               Actual key column
         DS   0F
PI_LEN   DS    CL04               Actual key lenth
***********************************************************************
* FAxxKEY  record key.                                                *
***********************************************************************
         DS   0F
WK_KEY   DS    CL255              zFAM Key  record key
*
***********************************************************************
* FAxxFILE record key.                                                *
***********************************************************************
WF_KEY   DS   0F                  zFAM File description
WF_IDN   DS    CL06               IDN
WF_NC    DS    CL02               NC
WF_SEG   DS    H                  Segment number
WF_SUFX  DS    H                  Suffix  number
WF_NULL  DS    F                  Zeroes  (not used)
*
***********************************************************************
* Spanned Segment number                                              *
***********************************************************************
         DS   0F
SS_SEG   DS    H                  Spanned segment number
*
***********************************************************************
* Spanned segment status information                                  *
***********************************************************************
         DS   0F
W_LENGTH DS    CL08               Field length (spanned/remaining)
W_WIDTH  DS    F                  Field width
W_RA_B   DS    F                  Response array base
W_FF_A   DS    F                  FAxxFILE data  address
W_LO     DS    F                  Column range low
W_HI     DS    F                  Column range high
W_REL_D  DS    F                  Relative displacement
W_REL_L  DS    F                  Relative length
W_SEG    DS    H                  Current segment number
*
***********************************************************************
* Trace entry                                                         *
***********************************************************************
         DS   0F
W_46_M   DS    CL08               Trace entry paragraph
*
***********************************************************************
* zFAM column index resources                                         *
***********************************************************************
CI_FCT   DS   0F                  zFAM Column Index (FAxxSIxx)
CI_TRAN  DS    CL04               zFAM transaction ID
         DS    CL02               zFAM SI
CI_SI    DS    CL02               zFAM ID
*
CI_LEN   DS    H                  zFAM Column Index   length
CI_ID    DS    CL03               Column Index (zone   decimal)
*
W_ID     DS    CL02               Column Index (packed decimal)
*
***********************************************************************
* zFAM CI   store record buffer                                       *
***********************************************************************
         COPY ZFAMCIA
*
***********************************************************************
* Start zFAM102 DFHCOMMAREA                                           *
***********************************************************************
         DS   0F
ZP_COMM  DS   0CL261              zFAM102 DFHCOMMAREA
ZP_TYPE  DS    CL06               Type of request
*                                 DELETE
*                                 CREATE
*                                 UPDATE
         DS    CL02               alignment
ZP_NAME  DS    CL16               zFAM record key name
ZP_KEY_L DS    H                  zFAM record key length
ZP_KEY   DS    CL255              zFAM record key
ZP_L     EQU   *-ZP_COMM          DFHCOMMAREA length
         DS   0H
ZP_LEN   DS    H                  DFHCOMMAREA length (LINK)
*
***********************************************************************
* End   zFAM102 DFHCOMMAREA                                           *
***********************************************************************
*
***********************************************************************
* Start Data Center document template resources                       *
***********************************************************************
         DS   0F
DC_RESP  DS    F                  FD response code
DC_LEN   DS    F                  FD document length
DC_TOKEN DS    CL16               FD document token
DC_DOCT  DS   0CL48
DC_TRAN  DS    CL04               FD EIBTRNID
DC_TYPE  DS    CL02               FD Type
DC_SPACE DS    CL42               FD Spaces
*
         DS   0F
DC_REC   DS   0CL172              Data Center record
         DS    CL06
DC_ENV   DS    CL02               Replication environment
         DS    CL02
DC_HOST  DS    CL160              Replication host name
         DS    CL02
***********************************************************************
* End   Data Center document template resources                       *
***********************************************************************
*
*
***********************************************************************
* End   Dynamic Storage Area                                          *
***********************************************************************
*
***********************************************************************
* Start Parser Array (maximum 256 fields)                             *
***********************************************************************
*
PA_DSECT DSECT
P_ID     DS    PL02               Field ID
P_SEC    DS    PL02               Field level security
P_COL    DS    PL04               Field column
P_LEN    DS    PL04               Field length
P_TYPE   DS    CL01               Field type
P_WHERE  DS    CL01               WHERE indicator
P_SEG    DS    H                  Field record segment
P_NAME   DS    CL16               Field Name
E_PA     EQU   *-P_ID             PA entry length
***********************************************************************
* End   Parser Array                                                  *
***********************************************************************
*
***********************************************************************
* Start Field Data     buffer                                         *
***********************************************************************
FD_DSECT DSECT
*
*
***********************************************************************
* End   Field Data     buffer                                         *
***********************************************************************
*
***********************************************************************
* zFAM KEY  store record buffer                                       *
***********************************************************************
         COPY ZFAMDKA
*
***********************************************************************
* zFAM FILE store record buffer                                       *
***********************************************************************
         COPY ZFAMDFA
*
*
***********************************************************************
* Start FAxxFD DOCTEMPLATE buffer (Field Definitions)                 *
***********************************************************************
*
FA_DSECT DSECT
         DS    CL03               ID=
F_ID     DS    CL03               Field ID
         DS    CL05               ,Col=
F_COL    DS    CL07               Field column number
         DS    CL05               ,Len=
F_LEN    DS    CL06               Field length
         DS    CL06               ,Type=
F_TYPE   DS    CL01               Field type (Character or Numeric)
         DS    CL05               ,Sec=
F_SEC    DS    CL02               Field security level
         DS    CL06               ,Name=
F_NAME   DS    CL16               Field name
         DS    CL01               end of field marker
         DS    CL02               CRLF
E_FA     EQU   *-FA_DSECT         Field Definition entry length
***********************************************************************
* End   FAxxSD DOCTEMPLATE buffer                                     *
***********************************************************************
*
***********************************************************************
***********************************************************************
* Control Section - ZFAM040                                           *
***********************************************************************
***********************************************************************
ZFAM040  DFHEIENT CODEREG=(R2,R3),DATAREG=R11,EIBREG=R12
ZFAM040  AMODE 31
ZFAM040  RMODE 31
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'ZFAM040 '
         DC    CL48' -- Query Mode DELETE service                   '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
SYSDATE  DS   0H
*                                                                     *
***********************************************************************
* Issue GETMAIN for parser array                                      *
***********************************************************************
SY_0000  DS   0H
         EXEC CICS GETMAIN                                             X
               SET(R5)                                                 X
               FLENGTH(S_PA_LEN)                                       X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         L     R4,PA_LEN               Load GETMAIN length
         ST    R5,PA_ADDR              Save GETMAIN address
         LA    R6,E_PA                 Load parser array entry length
         USING PA_DSECT,R5             ... tell assembler
*
***********************************************************************
* Issue GET CONTAINER for FAxxFD document template                    *
***********************************************************************
SY_0010  DS   0H
         MVC   C_NAME,C_FAXXFD         Move FAXXFD container name
         MVC   C_LENGTH,S_FD_LEN       Move FAXXFD container length
         BAS   R14,GC_0010             Issue GET CONTAINER
         MVC   FA_RESP,C_RESP          Save FAxxFD container response
         ST    R1,FA_ADDR              Save FAXXFD address
         MVC   FA_LEN,C_LENGTH         Move FAXXFD length
*
         L     R7,FA_LEN               Load FAXXFD length
         L     R8,FA_ADDR              Load FAXXFD address
         LA    R9,E_FA                 Load FAXXFD entry length
         USING FA_DSECT,R8             ... tell assembler
***********************************************************************
* Scan FAXXFD for secondary column index fields, which will be used   *
* to build the Parser Array.                                          *
***********************************************************************
SY_0012  DS   0H
         CLC   F_ID,ZD_ONE+1           Column index?
         BC    B'0100',SY_0014         ... no,  get next FD entry
*
         MVC   P_NAME,F_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
*
         LA    R5,0(R6,R5)             Point to next PA entry
         L     R4,PA_LEN               Load PA length
         LA    R4,0(R6,R4)             Add  PA length
         ST    R4,PA_LEN               Save PA length
***********************************************************************
* Continue scan of FAxxFD until EOFD.                                 *
***********************************************************************
SY_0014  DS   0H
         LA    R8,0(R9,R8)             Point to next FD entry
         SR    R7,R9                   Reduce by an  FD entry length
         BC    B'0010',SY_0012         Continue FD scan
***********************************************************************
* Reset Parser Array registers.                                       *
***********************************************************************
SY_0030  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
*
         CLC   FA_RESP,=F'0'           FAxxFD container available?
         BC    B'0111',SY_0060         ... no,
***********************************************************************
* Scan parser array and mark the segment                              *
***********************************************************************
SY_0040  DS   0H
         XR    R14,R14                 Clear sign bits in register
         ZAP   W_COLUMN,P_COL          Move PA column to work area
         CVB   R15,W_COLUMN            Convert to binary
         D     R14,=F'32000'           Divide column by segment size
         LA    R15,1(,R15)             Relative to one
         STH   R15,P_SEG               Mark segment number
***********************************************************************
* Continue scan of parser array until EOPA                            *
***********************************************************************
SY_0042  DS   0H
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract PA entry length
         BC    B'0011',SY_0040         Continue PA scan
***********************************************************************
* Prepare to scan parser array for Primary Key.                       *
***********************************************************************
SY_0048  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
***********************************************************************
* Scan parser array for Primary Key                                   *
***********************************************************************
SY_0050  DS   0H
         CLC   P_ID,PD_ONE             Primary key?
         BC    B'1000',SY_0060         ... yes, GET the primary key
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract field entry length
         BC    B'0011',SY_0050         Continue scan until EOT
         BC    B'1111',ER_40001        EOT, STATUS(400)
***********************************************************************
* Issue GET CONTAINER for Primary Column Index                        *
***********************************************************************
SY_0060  DS   0H
         MVC   PI_TYPE,P_TYPE          Move field type
         MVC   PI_LEN,P_LEN            Move field length
         MVC   PI_COL,P_COL            Move field column
*
         ZAP   W_LENGTH,P_LEN          Move field length to work area
         CVB   R1,W_LENGTH             Convert to binary
         ST    R1,C_LENGTH             Move field length
         MVC   C_NAME,P_NAME           Move container name
*
         STH   R1,ZP_KEY_L             Move primary key length
         MVC   ZP_NAME,P_NAME          Move primary key name
*
         BAS   R14,GC_0010             Issue GET CONTAINER
*
         ST    R1,FD_ADDR              Save field data address
         MVC   FD_LEN,C_LENGTH         Move field data length
***********************************************************************
* Determine Primary Index field type and branch accordingly.          *
***********************************************************************
SY_0070  DS   0H
         OI    PI_TYPE,X'40'           Set upper case bit
         CLI   PI_TYPE,C'N'            Numeric?
         BC    B'1000',SY_0090         ... yes, set key accordingly
         BC    B'1111',SY_0080         ... no,  set key accordingly
***********************************************************************
* Set key as character.                                               *
***********************************************************************
SY_0080  DS   0H
         ZAP   W_LENGTH,PI_LEN         Move PA length to work area
         CVB   R6,W_LENGTH             Convert to binary
         MVI   WK_KEY,X'40'            Set first byte of key to space
         LR    R1,R6                   Load PI field length
         S     R1,=F'1'                Subtract one for space
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,WK_KEY              Load target field address
         LA    R14,1(,R14)             Point past space
         LA    R15,WK_KEY              Load source field address
         EX    R1,MVC_0080             Execute MVC instruction
*
         L     R1,FD_LEN               Load field data length
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,WK_KEY              Load FAxxKEY key address
         L     R15,FD_ADDR             Load field data address
         EX    R1,MVC_0081             Execute MVC instruction
*
         BC    B'1111',SY_0100         Read FAxxKEY
MVC_0080 MVC   0(0,R14),0(R15)         Initial with spaces
MVC_0081 MVC   0(0,R14),0(R15)         Move PI to key
***********************************************************************
* Set key as numeric.                                                 *
***********************************************************************
SY_0090  DS   0H
         ZAP   W_LENGTH,PI_LEN         Move PA length to work area
         CVB   R6,W_LENGTH             Convert to binary
         MVI   WK_KEY,X'F0'            Set first byte of key to zero
         LR    R1,R6                   Load PI field length
         S     R1,=F'1'                Subtract one for zero
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,WK_KEY              Load target field address
         LA    R14,1(,R14)             Point past zero
         LA    R15,WK_KEY              Load source field address
         EX    R1,MVC_0090             Execute MVC instruction
*
         L     R1,FD_LEN               Load field data length
         SR    R6,R1                   Subtract PI from maximum
*
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,WK_KEY              Load FAxxKEY key address
         LA    R14,0(R6,R14)           Adjust for field length
         L     R15,FD_ADDR             Load field data address
         EX    R1,MVC_0091             Execute MVC instruction
*
         BC    B'1111',SY_0100         Read FAxxKEY
MVC_0090 MVC   0(0,R14),0(R15)         Initial with zeroes
MVC_0091 MVC   0(0,R14),0(R15)         Move PI to key
***********************************************************************
* Issue READ for FAxxKEY  using Primary Column Index.                 *
***********************************************************************
SY_0100  DS   0H
         LA    R1,E_DK                 Load KEY  record length
         STH   R1,WK_LEN               Save KEY  record length
         BAS   R14,FK_0010             Issue READ for KEY  structure
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_20401        ... no,  STATUS(204)
         ST    R10,FK_ADDR             Save KEY  buffer address
         MVC   FK_LEN,WK_LEN           Save KEY  buffer length
         USING DK_DSECT,R10            ... tell assembler
***********************************************************************
* Issue READ for FAxxFILE using Primary Column Index.                 *
***********************************************************************
SY_0110  DS   0H
         DROP  R10                     ... tell assembler
         L     R5,PA_ADDR              Load parser array address
         MVC   WF_LEN,S_DF_LEN         Move FILE record length
         MVC   WF_SEG,P_SEG            Set segment number
         BAS   R14,FF_0010             Issue READ for FILE structure
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_20402        ... no,  STATUS(204)
         ST    R10,FF_ADDR             Save FILE buffer address
         USING DF_DSECT,R10            ... tell assembler
         MVC   FF_LEN,WF_LEN           Save FILE buffer length
         LA    R1,DF_DATA              Load data portion
         ST    R1,W_FF_A               Save data portion
***********************************************************************
***********************************************************************
SY_0120  DS   0H
***********************************************************************
***********************************************************************
SY_0130  DS   0H
***********************************************************************
* Prepare to scan parser array for secondary column index fields.     *
***********************************************************************
SY_0140  DS   0H
         DROP  R5                      ... tell assembler
         L     R8,PA_LEN               Load parser   array length
         L     R9,PA_ADDR              Load parser   array address
         USING PA_DSECT,R9             ... tell assembler
***********************************************************************
* Scan Parser Array for field definitions.                            *
***********************************************************************
SY_0150  DS   0H
         CLC   P_ID,PD_ONE             Primary index?
         BC    B'1000',SY_0160         ... yes, get next entry
         CLC   P_ID,PD_NINES           Entry already processed?
         BC    B'1000',SY_0160         ... yes, get next entry
         BC    B'1111',SY_0170         ... no,  check HI/LO range
***********************************************************************
* Adjust Parser Array address and length                              *
***********************************************************************
SY_0160  DS   0H
         LA    R1,E_PA                 Load parser array entry length
         LA    R9,0(R1,R9)             Point to next PA entry
         SR    R8,R1                   Subtract PA entry length
         BC    B'0011',SY_0150         Continue when more entries
         BC    B'1111',SY_0250         Scan PA for unprocessed entries
***********************************************************************
* Check column number for HI/LO range for current segment             *
***********************************************************************
SY_0170  DS   0H
         MVC   W_ID,P_ID               Save Parser Array column ID
         ZAP   W_COLUMN,P_COL          Move PA column to work area
         CVB   R1,W_COLUMN             Load in R1
         C     R1,W_HI                 Is column beyond segment range?
         BC    B'0011',SY_0160         ... yes, get next PA entry
         C     R1,W_LO                 Is column before segment range?
         BC    B'0100',SY_0160         ... yes, get next PA entry
*
         MVC   P_ID,PD_NINES           Mark field as processed
*
***********************************************************************
* Calculate relative offset from current segment.                     *
*                                                                     *
* To calculate relative offset from current segment:                  *
* 1).  Subtract 1 from current segment number, giving the             *
*      relative segment number.                                       *
* 2).  Multiple relative segment number by 32,000 giving the          *
*      segment displacement.                                          *
* 3).  Subtract segment displacement from column number giving        *
*      relative displacement.                                         *
*                                                                     *
* For example, column 50 would be calculated as such:                 *
* 1).  Subtract 1 from current segment.  Segment 1 will contain       *
*      columns 1 thru 32,000.  So for column 50, the relative segment *
*      number for step 1 would be zero.                               *
* 2).  Multiply relative segment zero by 32,000 giving segment        *
*      displacement, which in this case is zero.                      *
* 3).  Subtract segment displacement from the column, which in this   *
*      case is 50, giving the relative displacement of 50.            *
*                                                                     *
* Another example, column 64,075 would be calculated as such:         *
* 1).  Subtract 1 from current segment.  Segment 3 will contain       *
*      columns 64,001 thru 96,000, so for column 64,075 the relative  *
*      segment for step 1 would be two.                               *
* 2).  Multiply relative segment two by 32,000, giving segment        *
*      displacement, which in this case would be 64,000.              *
* 3).  Subtract segment displacement from the column, which in this   *
*      case would be 64,000 from 64,075 resulting in a relative       *
*      displacement of 75                                             *
*                                                                     *
***********************************************************************
SY_0180  DS   0H
         XR    R6,R6                   Clear R6
*        LH    R7,DF_SEG               Load segment number
         LH    R7,W_SEG                Load current segment number
         S     R7,=F'1'                Get relative segment number
         M     R6,S_32K                Multiply by max segment size
*                                      ... giving segment displacement
         ZAP   W_COLUMN,P_COL          Load column number
         CVB   R1,W_COLUMN             Convert from PD to binary
         SR    R1,R7                   Subtract segment displacement
*                                      ... giving relative displacement
         S     R1,=F'1'                ... then make relative to zero
         ST    R1,W_REL_D              Save relative displacement
*
         ZAP   W_LENGTH,P_LEN          Set source length
         XC    SI_FIELD,SI_FIELD       Clear Secondary Index field
         LA    R4,SI_FIELD             Load  Secondary Index field
         ST    R4,SI_PTR               Save as Secondary Index pointer
*
***********************************************************************
* Calculate width to determine if field spans a segment.              *
***********************************************************************
SY_0185  DS   0H
         L     R1,W_REL_D              Load relative displacement
         CVB   R6,W_LENGTH             Convert length to binary
         AR    R6,R1                   Add relative displacement
         ST    R6,W_WIDTH              Save field width
         C     R6,S_32K                Wider than 32K?
         BC    B'0011',SY_0200         ... yes, spanned segment
***********************************************************************
* Move field to Secondary Index field.                                *
***********************************************************************
SY_0190  DS   0H
         STM   0,15,REGSAVE            Save registers
         CVB   R7,W_LENGTH             Set source length
         L     R1,W_REL_D              Load relative displacement
         L     R6,W_FF_A               Set source address
         LA    R6,0(R1,R6)             Add relative displacement
         LR    R5,R7                   Set target length
*
         L     R4,SI_PTR               Set target address
*
         MVCL  R4,R6                   Move field to Secondary Index
         LM    0,15,REGSAVE            Load registers
*
         BC    B'1111',SY_0300         Delete Secondary Column Index
***********************************************************************
* Field spans segments.                                               *
***********************************************************************
SY_0200  DS   0H
         STM   0,15,REGSAVE            Save registers
         L     R1,W_REL_D              Load relative displacement
         L     R6,W_WIDTH              Load field width
         SR    R6,R1                   Subtract relative displacement
         ST    R6,W_WIDTH              Save field width
***********************************************************************
* Move spanned segment field to Secondary Index                       *
***********************************************************************
SY_0210  DS   0H
         L     R6,W_REL_D              Load relative displacement
         L     R1,S_32K                Load 32K length
         SR    R1,R6                   Subtract relative displacement
         ST    R1,W_REL_L              Set relative length
         L     R6,W_FF_A               Set source address
         L     R15,W_REL_D             Load relative displacement
         LA    R6,0(R15,R6)            Adjust relative displacement
         LR    R5,R1                   Set source length
         LR    R7,R1                   Set target length
*
         L     R4,SI_PTR               Set target address
*
         MVCL  R4,R6                   Move field to Response Array
*
         L     R1,W_REL_L              Load relative length
         L     R4,SI_PTR               Load current SI pointer
         LA    R4,0(R1,R4)             Load the new SI pointer
         ST    R4,SI_PTR               Save the new SI pointer
*
         CVB   R1,W_LENGTH             Convert current field length
         S     R1,W_REL_L              Subtract relative length
         CVD   R1,W_LENGTH             Save remaining length
*
         XC    W_REL_D,W_REL_D         Zero relative displacement
         L     R1,W_WIDTH              Load width
         L     R15,W_REL_L             Load relative length
         SR    R1,R15                  Subtract relative length
         ST    R1,W_WIDTH              Save width
*
         LH    R1,WF_SEG               Load segment number
         LA    R1,1(0,R1)              Increment by one
         STH   R1,WF_SEG               Save segment number
*
         MVC   WF_LEN,S_DF_LEN         Move FILE record length
         BAS   R14,FF_0010             Issue READ for FILE structure
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_20403        ... no,  STATUS(204)
         ST    R10,FF_ADDR             Save FILE buffer address
         USING DF_DSECT,R10            ... tell assembler
         LA    R1,DF_DATA              Load data portion
         ST    R1,W_FF_A               Save data portion
         MVC   FF_LEN,WF_LEN           Save FILE buffer length
         MVC   SS_SEG,WF_SEG           Save spanned segment number
*
         CLC   W_WIDTH,S_32K           Width more than 32K?
         BC    B'0011',SY_0210         ... yes, move spanned segments
*
***********************************************************************
* Move remainder of spanned segment field to Response Array.          *
***********************************************************************
SY_0220  DS   0H
         L     R1,W_REL_D              Load relative displacement
         BC    B'1111',SY_0185         Move remainder to RA
***********************************************************************
* Scan parser array if there are any fields that are yet to be        *
* processed.  When fields in the parser array are not on the current  *
* record segment, the entry is skipped requiring the parser array to  *
* be scanned until all entries are tagged as processed by the '999'   *
* P_ID.                                                               *
***********************************************************************
SY_0250  DS   0H
         L     R8,PA_LEN               Load parser array length
         L     R9,PA_ADDR              Load parser array address
         LA    R1,E_PA                 Load parser array entry length
***********************************************************************
* Search for unprocessed parser array entry                           *
***********************************************************************
SY_0260  DS   0H
         CLC   P_ID,PD_ONE             Primary index?
         BC    B'1000',SY_0270         ... yes, continue
         CLC   P_ID,PD_NINES           Processed entry?
         BC    B'1000',SY_0270         ... yes, continue
         L     R8,PA_LEN               Load parser array length
         L     R9,PA_ADDR              Load parser array address
*
         MVC   WF_LEN,S_DF_LEN         Move FILE record length
         MVC   WF_SEG,P_SEG            Set segment number
         BAS   R14,FF_0010             Issue READ for FILE structure
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_20405        ... no,  STATUS(204)
         ST    R10,FF_ADDR             Save FILE buffer address
         USING DF_DSECT,R10            ... tell assembler
         MVC   FF_LEN,WF_LEN           Save FILE buffer length
         LA    R1,DF_DATA              Load data portion
         ST    R1,W_FF_A               Save data portion
*
         BC    B'1111',SY_0300         Delete Secondary Column Index
***********************************************************************
* Check parser array entries until EOPA                               *
***********************************************************************
SY_0270  DS   0H
         LA    R9,0(R1,R9)             Point to next PA entry
         SR    R8,R1                   Subtract PA entry length
         BC    B'0011',SY_0260         Continue when more PA entries
         BC    B'1111',SY_0800         Delete Primary key/file records
*
***********************************************************************
* Create Secondary Column Index key                                   *
***********************************************************************
SY_0300  DS   0H
         XC    CI_KEY,CI_KEY           Clear column index key
         ZAP   W_LENGTH,P_LEN          Move field length to work area
         CVB   R1,W_LENGTH             Convert to binary
*
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,CI_FIELD            Load FAxxCIxx key address
         LA    R15,SI_FIELD            Load secondary index
         EX    R1,MVC_0300             Execute MVC instruction
*
         BC    B'1111',SY_0310         Delete FAxxCIxx
MVC_0300 MVC   0(0,R14),0(R15)         Move secondary index key
*
***********************************************************************
* Delete Secondary Column Index                                       *
***********************************************************************
SY_0310  DS   0H
         L     R10,FK_ADDR             Load KEY  buffer address
         USING DK_DSECT,R10            ... tell assembler
*
         MVC   CI_FCT(8),SI_FCT        Move SI FCT template
         MVC   CI_FCT+2(2),EIBTRNID+2  Move TrandID as SI prefix
*        MVC   CI_FCT(4),EIBTRNID      Move TrandID as SI prefix
         UNPK  CI_SI,W_ID              Unpack secondary index
         OI    CI_SI+1,X'F0'           Set sign bit
*
         MVC   CI_NC,DK_F_NC           Move named counter to key
         MVC   CI_IDN,DK_F_IDN         Move ID number     to key
*
*
         EXEC CICS DELETE FILE(CI_FCT)                                 X
               RIDFLD (CI_KEY)                                         X
               NOHANDLE
*
         BC    B'1111',SY_0140         Process parser array
*
***********************************************************************
* Delete Primary Key and File records.                                *
***********************************************************************
SY_0800  DS   0H
         L     R10,FK_ADDR             Load KEY  buffer address
         USING DK_DSECT,R10            ... tell assembler
         EXEC CICS DELETE FILE(WK_FCT)                                 X
              RIDFLD(DK_KEY)                                           X
              NOHANDLE
*
         DROP  R10                     ... tell assembler
         L     R10,FF_ADDR             Load KEY  buffer address
         USING DF_DSECT,R10            ... tell assembler
         MVC   WF_TRAN,=C'FA'          Move FILE prefix
         MVC   WF_TRAN+2(2),EIBTRNID+2 Move FILE structure ID
*        MVC   WF_TRAN,EIBTRNID        Move FILE structure ID
         EXEC CICS DELETE FILE(WF_FCT)                                 X
              RIDFLD(WF_KEY)                                           X
              KEYLENGTH(S_GEN_L)                                       X
              GENERIC                                                  X
              NOHANDLE
*
*
         BAS   R14,ZR_0010             zFAM replication when enabled
         BAS   R14,WS_0010             Issue WEB SEND
         BC    B'1111',RETURN          Return to CICS
*
***********************************************************************
* Return to caller                                                    *
**********************************************************************
RETURN   DS   0H
         EXEC CICS RETURN
*
***********************************************************************
* Issue GET CONTAINER (SET Register)                                  *
* This is used for Parser Array, Primary Index and individual fields  *
***********************************************************************
GC_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS GET CONTAINER(C_NAME)                               X
               SET(R1)                                                 X
               FLENGTH(C_LENGTH)                                       X
               CHANNEL(C_CHAN)                                         X
               RESP   (C_RESP)                                         X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
*
***********************************************************************
* Issue GETMAIN for Response Array                                    *
***********************************************************************
GM_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS GETMAIN                                             X
               SET(R9)                                                 X
               FLENGTH(C_LENGTH)                                       X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue READ for FAxxKEY  structure                                   *
***********************************************************************
FK_0010  DS   0H
         ST    R14,BAS_REG             Save return register
         MVC   WK_FCT(08),SK_FCT       Move KEY  structure name
         MVC   WK_TRAN(2),=C'FA'       Move KEY  structure ID
         MVC   WK_TRAN+2(2),EIBTRNID+2 Move KEY  structure ID
*        MVC   WK_TRAN,EIBTRNID        Move KEY  structure ID
*
         EXEC CICS READ FILE(WK_FCT)                                   X
               SET(R10)                                                X
               RIDFLD (WK_KEY)                                         X
               LENGTH (WK_LEN)                                         X
               NOHANDLE
*
         USING DK_DSECT,R10            ... tell assembler
*
         MVC   WF_DD,DK_DD             Move FILE structure name
         MVC   WF_IDN,DK_F_IDN         Move FILE IDN
         MVC   WF_NC,DK_F_NC           Move FILE NC
*
         DROP  R10                     ... tell assembler
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue READ for FAxxFILE structure                                   *
* When the spanned segment number is equal to the WF_SEG, then the    *
* segment has already been read during spanned segment processing.    *
***********************************************************************
FF_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         CLC   SS_SEG,WF_SEG           Segment numbers equal?
         BC    B'1000',FF_0020         ... yes, record is in the buffer
*
         MVC   WF_TRAN(2),=C'FA'       Move FILE structure ID
         MVC   WF_TRAN+2(2),EIBTRNID+2 Move FILE structure ID
*        MVC   WF_TRAN,EIBTRNID        Move FILE structure ID
*
         EXEC CICS READ FILE(WF_FCT)                                   X
               SET(R10)                                                X
               RIDFLD (WF_KEY)                                         X
               LENGTH (WF_LEN)                                         X
               NOHANDLE
*
         USING DF_DSECT,R10            ... tell assembler
*
         MVC   W_SEG,DF_SEG            Save segment number
         LH    R1,DF_SEG               Load segment number
         XR    R6,R6                   Clear R6
         L     R7,S_32K                Load maximum segment size
         MR    R6,R1                   Create Column HI range
         ST    R7,W_HI                 Save as segment HI range
         S     R7,S_32K                Subtract segment size
         A     R7,=F'1'                Add one to create segment LO
         ST    R7,W_LO                 Save as segment LO range
*
FF_0020  DS   0H
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
         DROP  R10                     ... tell assembler
*
***********************************************************************
* Issue REWRITE for FAxxFILE structure.                               *
***********************************************************************
FF_0030  DS   0H
         ST    R14,BAS_REG             Save return register
*
         L     R10,FF_ADDR             Load FAxxFILE record buffer
         USING DF_DSECT,R10            ... tell assembler
*
         EXEC CICS REWRITE FILE(WF_FCT)                                X
               FROM(DF_DSECT)                                          X
               LENGTH (WF_LEN)                                         X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
         DROP  R10                     ... tell assembler
*
***********************************************************************
* Transfer control to error logging program zFAM090                   *
***********************************************************************
PC_0010  DS   0H
         LA    R1,E_LOG                Load COMMAREA length
         STH   R1,L_LOG                Save COMMAREA length
*
         EXEC CICS XCTL PROGRAM(ZFAM090)                               X
               COMMAREA(C_LOG)                                         X
               LENGTH  (L_LOG)                                         X
               NOHANDLE
*
         EXEC CICS WEB SEND                                            X
               FROM      (H_CRLF)                                      X
               FROMLENGTH(H_TWO)                                       X
               ACTION    (H_ACTION)                                    X
               MEDIATYPE (H_MEDIA)                                     X
               STATUSCODE(H_500)                                       X
               STATUSTEXT(H_500_T)                                     X
               STATUSLEN (H_500_L)                                     X
               SRVCONVERT                                              X
               NOHANDLE
*
         BC    B'1111',RETURN          Return (if XCTL fails)
***********************************************************************
* Send response (WEB SEND)                                            *
***********************************************************************
WS_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS WEB SEND                                            X
               FROM      (H_200_T)                                     X
               FROMLENGTH(H_200_L)                                     X
               ACTION    (H_ACTION)                                    X
               MEDIATYPE (H_MEDIA)                                     X
               STATUSCODE(H_200)                                       X
               STATUSTEXT(H_200_T)                                     X
               STATUSLEN (H_200_L)                                     X
               SRVCONVERT                                              X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue TRACE command.                                                *
***********************************************************************
TR_0010  DS   0H
         ST    R14,BAS_REG             Save return register
         STM   0,15,REGSAVE            Save registers
*
*        BC    B'1111',TR_0020         Bypass trace
*
         EXEC CICS ENTER TRACENUM(T_46)                                X
               FROM(W_46_M)                                            X
               FROMLENGTH(T_LEN)                                       X
               RESOURCE(T_RES)                                         X
               NOHANDLE
*
TR_0020  DS   0H
         LM    0,15,REGSAVE            Load registers
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* zFAM Replication  - start                                           *
***********************************************************************
ZR_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
***********************************************************************
* Retrieve Data Center document template                              *
***********************************************************************
ZR_0020  DS   0H
         MVC   DC_LEN,DC_DT_L          Set document length
         MVC   DC_TRAN(2),=C'FA'       Set document TransID
         MVC   DC_TRAN+2(2),EIBTRNID+2 Set document TransID
*        MVC   DC_TRAN,EIBTRNID        Set document TransID
         MVC   DC_TYPE,=C'DC'          Set document type
         MVI   DC_SPACE,X'40'          Set first byte
         MVC   DC_SPACE+1(41),DC_SPACE Set remainder of bytes
*
         EXEC CICS DOCUMENT CREATE DOCTOKEN(DC_TOKEN)                  X
               TEMPLATE(DC_DOCT)                                       X
               RESP    (DC_RESP)                                       X
               NOHANDLE
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ZR_0099         ... no,  bypass RETRIEVE
*
         EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(DC_TOKEN)                X
               INTO     (DC_REC)                                       X
               LENGTH   (DC_LEN)                                       X
               MAXLENGTH(DC_LEN)                                       X
               RESP     (DC_RESP)                                      X
               DATAONLY                                                X
               NOHANDLE
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ZR_0099         ... no,  bypass zFAM102
*
         CLC   DC_ENV,ZP_AS            Active/Standby environment?
         BC    B'0111',ZR_0099         ... no,  bypass zFAM102
*
***********************************************************************
* LINK to zFAM replication program zFAM102 (Query Mode)               *
***********************************************************************
ZR_0030  DS   0H
         MVC   ZP_TYPE,ZP_DEL          Move DELETE replication type
         MVC   ZP_KEY,WK_KEY           Move primary key
         LA    R1,ZP_L                 Load DFHCOMMAREA length
         STH   R1,ZP_LEN               Save DFHCOMMAREA length
*
         EXEC CICS LINK                                                X
               PROGRAM (ZFAM102)                                       X
               COMMAREA(ZP_COMM)                                       X
               LENGTH  (ZP_LEN)                                        X
               NOHANDLE
*
***********************************************************************
* zFAM Replication  - end                                             *
***********************************************************************
ZR_0099  DS   0H
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
         DS   0F
ZFAM102  DC    CL08'ZFAM102 '          Replication program
ZP_CRE   DC    CL06'CREATE'            CREATE replication type
ZP_UPD   DC    CL06'UPDATE'            UPDATE replication type
ZP_DEL   DC    CL06'DELETE'            DELETE replication type
*
ZP_AA    DC    CL02'AA'                Active/Active  environment
ZP_AS    DC    CL02'AS'                Active/Standby environment
ZP_A1    DC    CL02'A1'                Active/Single  environment
*
DC_DT_L  DC    F'00172'                FAxxDC Document template length
*
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20401 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20402 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20403 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20404 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20405 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40001 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
*
***********************************************************************
* Define Constant fields                                              *
***********************************************************************
*
         DS   0F
HEX_00   DC    XL01'00'                Nulls
         DS   0F
HEX_40   DC    16XL01'40'              Spaces
         DS   0F
S_204    DC    CL03'204'               HTTP STATUS(204)
         DS   0F
S_400    DC    CL03'400'               HTTP STATUS(400)
         DS   0F
ONE      DC    F'1'                    One
FIVE     DC    F'5'                    Five
S_OT_LEN DC    F'80'                   OPTIONS  table maximum length
S_PA_LEN DC    F'8192'                 Parser   Array maximum length
S_FD_LEN DC    F'65000'                Field Define   maximum length
         DS   0F
S_DF_LEN DC    H'32700'                FAxxFILE       maximum length
         DS   0F
S_32K    DC    F'32000'                Maximum segment length
         DS   0F
S_GEN_L  DC    H'8'                    Generic keylength for DELETE
         DS   0F
PD_ZERO  DC    XL02'000F'              Packed decimal zeroes
PD_ONE   DC    XL02'001F'              Packed decimal zeroes
PD_NINES DC    XL02'999F'              Packed decimal nines
ZD_ZERO  DC    CL05'00000'             Zoned  decimal 00000
ZD_ONE   DC    CL04'0001'              Zoned  decimal 0001
         DS   0F
ZFAM090  DC    CL08'ZFAM090 '          zFAM Logging and error program
SK_FCT   DC    CL08'FAxxKEY '          zFAM KEY  structure
SF_FCT   DC    CL08'FAxxFILE'          zFAM FILE structure
SI_FCT   DC    CL08'FAxxCIxx'          zFAM CI   structure
C_CHAN   DC    CL16'ZFAM-CHANNEL    '  zFAM channel
C_OPTION DC    CL16'ZFAM-OPTIONS    '  OPTIONS container
C_TTL    DC    CL16'ZFAM-TTL        '  TTL container
C_ARRAY  DC    CL16'ZFAM-ARRAY      '  ARRAY container
C_FAXXFD DC    CL16'ZFAM-FAXXFD     '  Field description document
         DS   0F
***********************************************************************
* HTTP resources                                                      *
***********************************************************************
H_TWO    DC    F'2'                    Length of CRLF
H_CRLF   DC    XL02'0D25'              Carriage Return Line Feed
H_500    DC    H'500'                  HTTP STATUS(500)
H_500_L  DC    F'48'                   HTTP STATUS TEXT Length
H_500_T  DC    CL16'03 Service unava'  HTTP STATUS TEXT Length
         DC    CL16'ilable and loggi'  ... continued
         DC    CL16'ng disabled     '  ... and complete
         DS   0F
H_200    DC    H'200'                  HTTP STATUS(200)
H_200_L  DC    F'32'                   HTTP STATUS TEXT Length
H_200_T  DC    CL16'00 Request succe'  HTTP STATUS TEXT Length
         DC    CL16'ssful.          '  ... continued
         DS   0F
H_ACTION DC    F'02'                   HTTP SEND ACTION(IMMEDIATE)
H_MEDIA  DC    CL56'text/plain'        HTTP Media type
         DS   0F
***********************************************************************
* Trace resources                                                     *
***********************************************************************
T_46     DC    H'46'                   Trace number
T_RES    DC    CL08'ZFAM040 '          Trace resource
T_LEN    DC    H'08'                   Trace resource length
*
***********************************************************************
* Literal Pool                                                        *
***********************************************************************
         LTORG
*
*
***********************************************************************
* Register assignment                                                 *
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
         PRINT ON
***********************************************************************
* End of Program - ZFAM040                                            *
**********************************************************************
         END   ZFAM040