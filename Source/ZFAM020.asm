*
*  PROGRAM:    ZFAM020
*  AUTHOR:     Rich Jackson and Randy Frerking
*  COMMENTS:   zFAM - z/OS File Access Manager
*
*              This program is executed as the Query Mode GET/SELECT
*              service called by the ZFAM001 control program.
*
*              This program will process primary column index requests
*              only.
*
***********************************************************************
* Start Dynamic Storage Area                                          *
***********************************************************************
DFHEISTG DSECT
REGSAVE  DS    16F                Register Save Area
BAS_REG  DS    F                  BAS return register
RJ_REG   DS    F                  BAS return register - RJ_00**
RX_REG   DS    F                  BAS return register - RX_00**
RD_REG   DS    F                  BAS return register - RD_00**
APPLID   DS    CL08               CICS Applid
SYSID    DS    CL04               CICS SYSID
USERID   DS    CL08               CICS USERID
RA_ADDR  DS    F                  Response Array address (base)
RA_PTR   DS    F                  Response array address (build)
RA_LEN   DS    F                  Response Array length
WS_LEN   DS    F                  WEB SEND Array length
PA_ADDR  DS    F                  Parser   Array address
PA_LEN   DS    F                  Parser   Array length
FK_ADDR  DS    F                  zFAM Key  record address
FK_LEN   DS    F                  zFAM Key  record length
FF_ADDR  DS    F                  zFAM File record address
FF_LEN   DS    F                  zFAM File record length
CI_ADDR  DS    F                  zFAM CI   record address
CI_LEN   DS    F                  zFAM CI   record length
FD_ADDR  DS    F                  Container field address
FD_LEN   DS    F                  Container field length
         DS   0F
W_INDEX  DS    F                  Parser array index
W_ADDR   DS    F                  Beginning data area address
W_F_LEN  DS    CL08               Packed decimal field length
W_T_LEN  DS    CL08               Packed decimal total length
W_COUNT  DS    CL08               Packed decimal field count
W_COLUMN DS    CL08               Packed decimal field column
W_PDWA   DS    CL08               Packed decimal field column
         DS   0F
C_NAME   DS    CL16               Field Name   (container name)
C_LENGTH DS    F                  Field Length (container data)
         DS   0F
W_PRI_ID DS    CL01               Primary column ID flag
*
***********************************************************************
* zFAM090 communication area                                          *
* Logging for ZFAM020 exceptional conditions                          *
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
         DS   0F
PI_NAME  DS    CL16               Primary key field name
***********************************************************************
* FAxxKEY  record key.                                                *
***********************************************************************
         DS   0F
WK_KEY   DS    CL255              zFAM Key  record key
*
***********************************************************************
* FAxxFILE record key.                                                *
***********************************************************************
WF_KEY   DS   0F                  zFAM File record key
WF_IDN   DS    CL06               ID Number
WF_NC    DS    CL02               Named Counter
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
* SELECT options.                                                     *
* Primary Key attributes must be included for SELECT requests using   *
* secondary column index.  This is necessary as the Primary Key must  *
* be returned on all SELECT requests.                                 *
***********************************************************************
O_TABLE  DS   0F
O_P_COL  DS    PL04               Primary Key column number
O_P_LEN  DS    PL04               Primary Key field length
O_P_TYPE DS    CL01               Primary Key field type
         DS    CL03               Alignment
O_P_NAME DS    CL16               Primary Key field name
*
O_FORM   DS    CL09               Format message
*                                 FIXED     - delimited by field size
*                                 XML       - tags using field name
*                                 JSON      - tags using field name
*                                 DELIMITER - field delimiter
*                                 Default   - FIXED
*
         DS    CL03               Alignment
*
O_DIST   DS    CL03               Distinct messages returned
*                                 YES       - Duplicates not returned
*                                 NO        - Duplicates returned
*                                 Default   - NO
*
         DS    CL01               Alignment
*
O_MODE   DS    CL08               Type of SELECT process
*                                 ONLINE    - Synchronous  request
*                                 OFFLINE   - Asynchronous request
*                                 Default   - ONLINE
*
O_SORT   DS    CL16               Sort order by field name
*                                 FieldName - Ascending sort by field
*                                 Default   - Primary key
*
O_ROWS   DS    CL06               Maximum rows returned
*                                 0         - All available rows
*                                 1-999999  - Maximum rows returned
*                                 Default   - 0 (All available)
*
         DS    CL02               Alignment
O_WITH   DS    CL02               Type of Read (WITH)
*                                 UR        - Uncommitted Read
*                                 CR        - Committed   Read
*                                 Default   - UR
*
         DS    CL02               Alignment
E_TABLE  EQU   *-O_TABLE          Length of Option table
*
***********************************************************************
* Spanned segment status information                                  *
***********************************************************************
         DS   0F
W_LENGTH DS    CL08               Field length (spanned/remaining)
W_WIDTH  DS    F                  Field width
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
* Chunked Message Transfer - JSON and XML initial message length.     *
***********************************************************************
         DS   0F
M_LENGTH DS    F                  HTTP initial message length
***********************************************************************
* RECEIVE Media Type                                                  *
* The following values override the OPTIONS(FORMAT=) parameter        *
***********************************************************************
         DS   0F
R_TYPE   DS    CL01               HTTP Media type - bit indicator
R_PLAIN  EQU   X'80'                                text/plain (fixed)
R_JSON   EQU   X'40'                                text/json
R_XML    EQU   X'20'                                text/xml
R_DELIM  EQU   X'10'                                text/delimited
         DS   0F
R_LENGTH DS    F                  HTTP WEB RECEIVE length
R_MEDIA  DS    CL56               HTTP Media type - text from client
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
* Start Response Array buffer                                         *
***********************************************************************
RA_DSECT DSECT
R_PRI    DS    CL255              Primary Key
R_FIELD  DS    CL01               Field entry
E_RA     EQU   *-R_PRI            RA entry length
*
*
***********************************************************************
* End   Response Array buffer                                         *
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
***********************************************************************
* zFAM FILE store record buffer                                       *
***********************************************************************
         COPY ZFAMDFA
*
*
*
***********************************************************************
***********************************************************************
* Control Section - ZFAM020                                           *
***********************************************************************
***********************************************************************
ZFAM020  DFHEIENT CODEREG=(R2,R3),DATAREG=R11,EIBREG=R12
ZFAM020  AMODE 31
ZFAM020  RMODE 31
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'ZFAM020 '
         DC    CL48' -- Query Mode SELECT service                   '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
SYSDATE  DS   0H
***********************************************************************
* Issue GET CONTAINER for Parser Array.                               *
***********************************************************************
SY_0000  DS   0H
         MVC   C_NAME,C_ARRAY          Move parser array container
         MVC   C_LENGTH,S_PA_LEN       Move parser array length
         BAS   R14,GC_0010             Issue GET CONTAINER
         ST    R9,PA_ADDR              Save parser array address
         MVC   PA_LEN,C_LENGTH         Move parser array length
***********************************************************************
* Issue WEB RECEIVE to obtain Media Type                              *
***********************************************************************
SY_0001  DS   0H
         EXEC CICS WEB RECEIVE                                         X
              MEDIATYPE(R_MEDIA)                                       X
              LENGTH   (R_LENGTH)                                      X
              SET      (R1)                                            X
              NOHANDLE
*
         XC   R_TYPE,R_TYPE            Clear RECEIVE Media Type
         OC   R_MEDIA,HEX_40           Set upper case
         CLC  R_MEDIA(10),M_PLAIN      text/plain requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_PLAIN           ... yes, set text/plain bit
         CLC  R_MEDIA(09),M_JSON       text/json  requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_JSON            ... yes, set text/json  bit
         CLC  R_MEDIA(08),M_XML        text/xml   requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_XML             ... yes, set text/xml   bit
         CLC  R_MEDIA(14),M_DELIM      text/delim requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_DELIM           ... yes, set text/delim bit
*
         CLC  R_MEDIA(16),A_JSON       application/json requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_JSON            ... yes, set text/json  bit
         CLC  R_MEDIA(15),A_XML        application/xml  requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_XML             ... yes, set text/xml   bit
*
***********************************************************************
* Issue GET CONTAINER for OPTIONS table.                              *
***********************************************************************
SY_0010  DS   0H
         MVC   C_NAME,C_OPTION         Move OPTIONS table container
         MVC   C_LENGTH,S_OT_LEN       Move OPTIONS table length
         BAS   R14,GC_0020             Issue GET CONTAINER
*
***********************************************************************
* Set RECEIVE Media Type using OPTIONS(FORMAT=xxxx) Parameter         *
* The OPTIONS and FORMAT parameter is the original means to request   *
* zQL response array format.  Now, both Media Type or OPTIONS/FORMAT  *
* can be specified with Media Type taking priority.                   *
***********************************************************************
SY_0011  DS   0H
         OC    R_TYPE,R_TYPE           Is RECEIVE Media Type zeroes?
         BC    B'0111',SY_0019         ... no,  RECEIVE has priority
*
         MVI  R_TYPE,R_PLAIN           Set FORMAT(FIXED) default
         CLC  O_FORM,S_FIXED           FORMAT(FIXED) requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_PLAIN           ... yes, set text/plain bit
         CLC  O_FORM,S_JSON            FORMAT(JSON ) requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_JSON            ... yes, set text/json  bit
         CLC  O_FORM,S_XML             FORMAT(XML  ) requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_XML             ... yes, set text/xml   bit
         CLC  O_FORM,S_DELIM           FORMAT(DELIM) requested?
         BC   B'0111',*+8              ... no,  continue
         MVI  R_TYPE,R_DELIM           ... yes, set text/delim bit
*
***********************************************************************
* Address Parser Array.                                               *
***********************************************************************
SY_0019  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
***********************************************************************
* Scan parser array and mark the segment                              *
***********************************************************************
SY_0020  DS   0H
         XR    R8,R8                   Clear sign bits in register
         ZAP   W_COLUMN,P_COL          Move PA column to work area
         CVB   R9,W_COLUMN             Convert to binary
         D     R8,=F'32000'            Divide column by segment size
         LA    R9,1(,R9)               Relative to one.
         STH   R9,P_SEG                Mark segment number
***********************************************************************
* Continue scan of parser array until EOPA                            *
***********************************************************************
SY_0022  DS   0H
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract PA entry length
         BC    B'0011',SY_0020         Continue PA scan
***********************************************************************
* Segment array initialization complete.                              *
* Prepare to scan parser array.                                       *
***********************************************************************
SY_0028  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
         OI    W_F_LEN+7,X'0C'         Set packed decimal sign bit
         OI    W_COUNT+7,X'0C'         Set packed decimal sign bit
***********************************************************************
* Scan parser array tallying field lengths                            *
***********************************************************************
SY_0030  DS   0H
         CLC   P_ID,PD_ONE             Primary key?
         BC    B'1000',SY_0035         ... yes, skip tally
         AP    W_F_LEN,P_LEN           Add field length to total
         AP    W_COUNT,PD_ONE          Increment field count
SY_0035  DS   0H
         CLC   P_ID,PD_ONE             Primary ID field?
         BC    B'0111',SY_0050         ... no,  continue parsing
         MVI   W_PRI_ID,C'Y'           ... yes, set primary ID flag
***********************************************************************
* Issue GET CONTAINER for Primary Column Index                        *
***********************************************************************
SY_0040  DS   0H
         MVC   PI_NAME,P_NAME          Move field name
         MVC   PI_TYPE,P_TYPE          Move field type
         MVC   PI_LEN,P_LEN            Move field length
         MVC   PI_COL,P_COL            Move field column
*
         MVC   C_NAME,P_NAME           Move container name
         MVC   C_LENGTH,P_LEN          Move field length
         AP    W_F_LEN,P_LEN           Add field length to total
         BAS   R14,GC_0010             Issue GET CONTAINER
*
         ST    R9,FD_ADDR              Save field data address
         MVC   FD_LEN,C_LENGTH         Move field data length
***********************************************************************
* Adjust field entry length then continue tallying field lengths      *
***********************************************************************
SY_0050  DS   0H
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract field entry length
         BC    B'0011',SY_0030         Continue scan until EOT
***********************************************************************
* Check results of scan and branch accordingly                        *
***********************************************************************
SY_0060  DS   0H
         CLI   W_PRI_ID,C'Y'           Primary ID flag set?
         BC    B'0111',ER_40001        ... no,  SYNTAX error
***********************************************************************
* Calculate GETMAIN length for Response Array                         *
***********************************************************************
SY_0070  DS   0H
         CVB   R1,W_F_LEN              Convert field length to binary
         XC    W_PDWA,W_PDWA           Clear packed decimal work area
         MVC   W_PDWA+4(4),PI_LEN      Move primary key length
         CVB   R13,W_PDWA              Convert key   length to binary
         AR    R1,R13                  Add key length to response
*
         CLI   R_TYPE,R_PLAIN          Delimit by fixed length?
         BC    B'1000',SY_0078         ... yes, set GETMAIN length
*
         XR    R14,R14                 Clear even register
         CVB   R15,W_COUNT             Convert field county to binary
*
         CLI   R_TYPE,R_XML            Delimit by XML  tags?
         BC    B'1000',SY_0072         ... yes, set length
         CLI   R_TYPE,R_JSON           Delimit by JSON tags?
         BC    B'1000',SY_0074         ... yes, set length
         CLI   R_TYPE,R_DELIM          Delimit by pipe character?
         BC    B'1000',SY_0076         ... yes, set length
         BC    B'1111',SY_0078         ... no,  default FIXED
***********************************************************************
* Include XML  tags in total length                                   *
***********************************************************************
SY_0072  DS   0H
         M     R14,=F'37'              Multiply count by XML  length
         AR    R1,R15                  Add XML  tags to field length
         BC    B'1111',SY_0078         Set GETMAIN length
***********************************************************************
* Include JSON tags in total length                                   *
***********************************************************************
SY_0074  DS   0H
         M     R14,=F'24'              Multiply count by JSON length
         AR    R1,R15                  Add JSON tags to field length
         A     R1,=F'32'               Add JSON tags to key field
         BC    B'1111',SY_0078         Set GETMAIN length
***********************************************************************
* Include PIPE tags in total length                                   *
***********************************************************************
SY_0076  DS   0H
         M     R14,=F'1'               Multiply count by PIPE length
         AR    R1,R15                  Add PIPE tags to field length
         BC    B'1111',SY_0078         Set GETMAIN length
***********************************************************************
* Issue GETMAIN for Response Array using total field length.          *
***********************************************************************
SY_0078  DS   0H
         ST    R1,C_LENGTH             Save in work area
         BAS   R14,GM_0010             Issue GETMAIN
         ST    R9,RA_ADDR              Save Response Array address
         MVC   RA_LEN,C_LENGTH         Save Response Array length
***********************************************************************
* Determine Primary Index field type and branch when numeric.         *
* Set key as character.                                               *
***********************************************************************
SY_0080  DS   0H
         OI    PI_TYPE,X'40'           Set upper case bit
         CLI   PI_TYPE,C'N'            Numeric?
         BC    B'1000',SY_0090         ... yes, set key accordingly
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
         L     R5,PA_ADDR              Load Parser Array address
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
* Initialize Response Array and Primary column index.                 *
***********************************************************************
SY_0120  DS   0H
         DROP  R5                      ... tell assembler
         L     R8,PA_LEN               Load parser   array length
         L     R9,PA_ADDR              Load parser   array address
         USING PA_DSECT,R9             ... tell assembler
*
         L     R5,RA_LEN               Load response array length
         L     R4,RA_ADDR              Load response array address
         USING RA_DSECT,R4             ... tell assembler
         ST    R4,RA_PTR               Save RA pointer
*
         STM   0,15,REGSAVE            Save registers
         LA    R14,HEX_00              Load source address
         LA    R15,0                   Load source length
         ICM   R15,B'1000',HEX_00      Move pad byte
         MVCL  R4,R14                  Move nulls to response array
         LM    0,15,REGSAVE            Load registers
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0010             ... yes, create JSON tag
*
         L     R4,RA_PTR               Load RA pointer
         ZAP   W_LENGTH,PI_LEN         Move field data length
         CVB   R1,W_LENGTH             Load into register
         S     R1,=F'1'                Subtract one for EX MVC
         LR    R14,R4                  Load RA primary key address
         L     R15,W_FF_A              Load field data address
         ZAP   W_COLUMN,PI_COL         Move field column
         CVB   R6,W_COLUMN             Load into register
         S     R6,=F'1'                Make relative to zero
         LA    R15,0(R6,R15)           Adjust address with column
         EX    R1,MVC_0120             Execute MVC instruction
         BC    B'1111',SY_0130         Skip EX MVC
MVC_0120 MVC   0(0,R14),0(R15)         Move primaary key to RA
***********************************************************************
* Adjust Response Array address and length                            *
***********************************************************************
SY_0130  DS   0H
         ZAP   W_LENGTH,PI_LEN         Move field data length
         CVB   R1,W_LENGTH             Load into register
         SR    R5,R1                   Adjust Response Array length
         LA    R4,0(R1,R4)             Point to first field
         ST    R4,RA_PTR               Save as Response Array base
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0020             ... yes, create JSON tag
*
***********************************************************************
* Prepare to scan parser array for field definitions                  *
***********************************************************************
SY_0140  DS   0H
         L     R8,PA_LEN               Load parser   array length
         L     R9,PA_ADDR              Load parser   array address
***********************************************************************
* Scan Parser Array for field definitions.                            *
***********************************************************************
SY_0150  DS   0H
         CLC   P_ID,PD_ONE             Primary index?
         BC    B'1000',SY_0165         ... yes, get next entry
         CLC   P_ID,PD_NINES           Entry already processed?
         BC    B'1000',SY_0160         ... yes, get next entry
         BC    B'1111',SY_0170         ... no,  check HI/LO range
***********************************************************************
* Adjust Parser Array address and length                              *
***********************************************************************
SY_0160  DS   0H
SY_0165  DS   0H
         LA    R1,E_PA                 Load parser array entry length
         LA    R9,0(R1,R9)             Point to next PA entry
         SR    R8,R1                   Subtract PA entry length
         BC    B'0011',SY_0150         Continue when more entries
         BC    B'1111',SY_0250         Scan PA for unprocessed entries
***********************************************************************
* Check column number for HI/LO range for current segment             *
***********************************************************************
SY_0170  DS   0H
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
         L     R4,RA_PTR               Load RA pointer
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0030             ... yes, create JSON tag
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
* Move field to Response Array.                                       *
***********************************************************************
SY_0190  DS   0H
         STM   0,15,REGSAVE            Save registers
         CVB   R7,W_LENGTH             Set source length
         L     R1,W_REL_D              Load relative displacement
         L     R6,W_FF_A               Set source address
         LA    R6,0(R1,R6)             Add relative displacement
         LR    R5,R7                   Set target length
*
         L     R4,RA_PTR               Set target address
*
         MVCL  R4,R6                   Move field to Response Array
         LM    0,15,REGSAVE            Load registers
*
         CVB   R1,W_LENGTH             Load field length
         L     R4,RA_PTR               Load current RA pointer
         LA    R4,0(R1,R4)             Load the new RA pointer
         ST    R4,RA_PTR               Save the new RA pointer
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0040             ... yes, create JSON tag
*
         BC    B'1111',SY_0140         Continue Parser Array process
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
* Move spanned segment field to Response Array                        *
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
         L     R4,RA_PTR               Set target address
*
         MVCL  R4,R6                   Move field to Response Array
*
         L     R1,W_REL_L              Load relative length
         L     R4,RA_PTR               Load current RA pointer
         LA    R4,0(R1,R4)             Load the new RA pointer
         ST    R4,RA_PTR               Save the new RA pointer
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
         BC    B'1111',SY_0140         Process parser array
***********************************************************************
* Check parser array entries until EOPA                               *
***********************************************************************
SY_0270  DS   0H
         LA    R9,0(R1,R9)             point to next PA entry
         SR    R8,R1                   Subtract PA entry length
         BC    B'0011',SY_0260         Continue when more PA entries
         BC    B'1111',SY_0300         Send response array when EOPA
*
***********************************************************************
* Send response                                                       *
***********************************************************************
SY_0300  DS   0H
         L     r4,RA_PTR               Load RA pointer
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0050             ... yes, create JSON tag
*
         BAS   R14,WS_0010             Issue WEB SEND
         BC    B'1111',RETURN          Return to CICS
***********************************************************************
* Secondar Column Index section                                       *
***********************************************************************
SY_0400  DS   0H
*
***********************************************************************
* Return to caller                                                    *
**********************************************************************
RETURN   DS   0H
         EXEC CICS RETURN
*
***********************************************************************
* Issue GET CONTAINER (SET Register)                                  *
* This is used for Parser Array and Primary Column Index              *
***********************************************************************
GC_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS GET CONTAINER(C_NAME)                               X
               SET(R9)                                                 X
               FLENGTH(C_LENGTH)                                       X
               CHANNEL(C_CHAN)                                         X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue GET CONTAINER for Options Table (INTO EISTG)                  *
***********************************************************************
GC_0020  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS GET CONTAINER(C_NAME)                               X
               INTO(O_TABLE)                                           X
               FLENGTH(C_LENGTH)                                       X
               CHANNEL(C_CHAN)                                         X
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
         MVC   WK_TRAN,EIBTRNID        Move KEY  structure ID
*
         CLC   O_WITH,=C'UR'           Uncommitted read request?
         BC    B'1000',FK_00UR         ... yes, issue READ w/o UPDATE
         BC    B'0111',FK_00CR         ... no,  issue READ w/  UPDATE
*
***********************************************************************
* Uncommitted READ (WITH(UR))                                         *
***********************************************************************
FK_00UR  DS   0H
         EXEC CICS READ FILE(WK_FCT)                                   X
               SET(R10)                                                X
               RIDFLD (WK_KEY)                                         X
               LENGTH (WK_LEN)                                         X
               NOHANDLE
         BC    B'1111',FK_0020         Continue process
*
***********************************************************************
* Committed READ   (WITH(CR))                                         *
***********************************************************************
FK_00CR  DS   0H
         EXEC CICS READ FILE(WK_FCT)                                   X
               SET(R10)                                                X
               RIDFLD (WK_KEY)                                         X
               LENGTH (WK_LEN)                                         X
               UPDATE                                                  X
               NOHANDLE
         BC    B'1111',FK_0020         Continue process
*
***********************************************************************
* Set FILE structure key fields and return                            *
***********************************************************************
FK_0020  DS   0H
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
         MVC   WF_TRAN,EIBTRNID        Move FILE structure ID
*
         EXEC CICS READ FILE(WF_FCT)                                   X
               SET(R10)                                                X
               RIDFLD (WF_KEY)                                         X
               LENGTH (WF_LEN)                                         X
               NOHANDLE
*
         USING DF_DSECT,R10            ... tell assembler
*
         MVC   W_SEG,DF_SEG            Move segment number
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
         L     R4,RA_ADDR              Load response array address
         USING RA_DSECT,R4             ... tell assembler
*
         MVC   WS_LEN,RA_LEN           Set WEB SEND length
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0060             ... yes, get RA length
*
         EXEC CICS WEB WRITE                                           X
               HTTPHEADER (H_ROWS)                                     X
               NAMELENGTH (H_ROWS_L)                                   X
               VALUE      (M_ROWS)                                     X
               VALUELENGTH(M_ROWS_L)                                   X
               NOHANDLE
*
         EXEC CICS WEB SEND                                            X
               FROM      (RA_DSECT)                                    X
               FROMLENGTH(WS_LEN)                                      X
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
* JSON pre-key tags - begin.                                          *
***********************************************************************
RJ_0010  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         L     R4,RA_PTR               Load response array pointer
***********************************************************************
* Create Primary key JSON tag.                                        *
***********************************************************************
RJ_0013  DS   0H
         MVI   0(R4),C'{'              Move JSON bracket
         MVI   1(R4),C'"'              Move double quote
         LA    R4,2(0,R4)              Bump RA
*
         LA    R6,PI_NAME              Load Primary name address
         LA    R5,16                   Load Primary name max length
***********************************************************************
* Space marks end of Primary Key name                                 *
***********************************************************************
RJ_0014  DS   0H
         CLI   0(R6),C' '              End of Primary name?
         BC    B'1000',RJ_0015         ... yes, mark JSON field end
         MVC   0(1,R4),0(R6)           ... no,  use to create JSON tag
         LA    R4,1(,R4)               Bump RA
         LA    R6,1(,R6)               Bump Primary name pointer
         BCT   R5,RJ_0014              Continue moving Primary name
***********************************************************************
* Mark end of Primary key JSON tag.  When the field is 'character'    *
* set the double quotes before data is moved to the response array.   *
***********************************************************************
RJ_0015  DS   0H
         MVI   0(R4),C'"'              Move double quote
         MVI   1(R4),C':'              Move colon
         LA    R4,2(,R4)               Bump RA
         CLI   PI_TYPE,C'N'            Numeric field?
         BC    B'1000',RJ_0019         ... yes, continue
         MVI   0(R4),C'"'              ... no,  move double quote
         LA    R4,1(,R4)               Bump RA
***********************************************************************
* JSON pre-key tags - finish.                                         *
***********************************************************************
RJ_0019  DS   0H
         ST    R4,RA_PTR               Save RA pointer
         LM    0,15,REGSAVE            Load all registers
         L     R14,RJ_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* JSON post-key tags - begin.                                         *
* When processing character field, include the double quote.          *
***********************************************************************
RJ_0020  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         L     R4,RA_PTR               Load response array pointer
         CLI   O_P_TYPE,C'N'           Numeric field?
         BC    B'1000',RJ_0021         ... yes, continue
         MVI   0(R4),C'"'              ... no,  move double quote
         LA    R4,1(,R4)               Bump RA
***********************************************************************
* The comma to separate JSON fields is moved before each data field   *
* is created.  This insures that a trailing comma is not included in  *
* the response array.                                                 *
***********************************************************************
RJ_0021  DS   0H
***********************************************************************
* JSON post-key tags - finish.                                        *
***********************************************************************
RJ_0029  DS   0H
         ST    R4,RA_PTR               Save RA pointer
         LM    0,15,REGSAVE            Load all registers
         L     R14,RJ_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* JSON pre-field tags - begin.                                        *
* Include the comma, which separates each record in the array.        *
***********************************************************************
RJ_0030  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         L     R4,RA_PTR               Load response array pointer
         MVI   0(R4),C','              Move a comma
         LA    R4,1(0,R4)              Bump RA
***********************************************************************
* Create field JSON tag.                                              *
***********************************************************************
RJ_0031  DS   0H
         MVI   0(R4),C'"'              Move double quote
         LA    R4,1(0,R4)              Bump RA
*
         LA    R6,P_NAME               Load PA field name address
         LA    R5,16                   Load PA field name max length
***********************************************************************
* Space marks end of field names                                      *
***********************************************************************
RJ_0032  DS   0H
         CLI   0(R6),C' '              End of field name?
         BC    B'1000',RJ_0033         ... yes, mark JSON field end
         MVC   0(1,R4),0(R6)           ... no,  use to create JSON tag
         LA    R4,1(,R4)               Bump RA
         LA    R6,1(,R6)               Bump Primary name pointer
         BCT   R5,RJ_0032              Continue moving field name
***********************************************************************
* Mark end of field name JSON tag.  When the field is 'character'     *
* set the double quotes before data is moved to the response array.   *
***********************************************************************
RJ_0033  DS   0H
         MVI   0(R4),C'"'              Move double quote
         MVI   1(R4),C':'              Move colon
         LA    R4,2(,R4)               Bump RA
         CLI   P_TYPE,C'N'             Numeric field?
         BC    B'1000',RJ_0039         ... yes, continue
         MVI   0(R4),C'"'              ... no,  move double quote
         LA    R4,1(,R4)               Bump RA
***********************************************************************
* JSON pre-field tags - finish.                                       *
***********************************************************************
RJ_0039  DS   0H
         ST    R4,RA_PTR               Save RA pointer
         LM    0,15,REGSAVE            Load all registers
         L     R14,RJ_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* JSON post-field tags - begin.                                       *
* When processing character field, include the double quote.          *
***********************************************************************
RJ_0040  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         L     R4,RA_PTR               Load response array pointer
         CLI   P_TYPE,C'N'             Numeric field?
         BC    B'1000',RJ_0041         ... yes, continue
         MVI   0(R4),C'"'              ... no,  move double quote
         LA    R4,1(,R4)               Bump RA
***********************************************************************
* The comma to separate JSON fields is moved before each data field   *
* is created.  This insures that a trailing comma is not included in  *
* the response array.                                                 *
***********************************************************************
RJ_0041  DS   0H
***********************************************************************
* JSON post-field tags - finish.                                      *
***********************************************************************
RJ_0049  DS   0H
         ST    R4,RA_PTR               Save RA pointer
         LM    0,15,REGSAVE            Load all registers
         L     R14,RJ_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* JSON end of array indicator.                                        *
***********************************************************************
RJ_0050  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         L     R4,RA_PTR               Load response array pointer
         MVI   0(R4),C'}'              Move JSON end of array marker
         LA    R4,1(,R4)               Bump RA
         ST    R4,RA_PTR               Save RA pointer
*
         LM    0,15,REGSAVE            Load all registers
         L     R14,RJ_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Set WEB SEND length by scanning Response Array until hitting a null *
* character.  The GETMAIN for the Response Array is calculated using  *
* the maximum field names of 16 bytes, however the actual field names *
* can be from 1-16 bytes.                                             *
***********************************************************************
RJ_0060  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         XR    R15,R15                 Response Array counter
         L     R6,RA_ADDR              Load response array address
         L     R5,RA_LEN               Load response array length
***********************************************************************
* Search Response Array for null character                            *
***********************************************************************
RJ_0061  DS   0H
         CLI   0(R6),X'00'             Null character?
         BC    B'1000',RJ_0062         ... yes, set WEB SEND length
         LA    R15,1(0,R15)            Add 1 to RA counter
         LA    R6,1(,R6)               Bump RA pointer
         BCT   R5,RJ_0061              Continue searching for null
***********************************************************************
* Set WEB SEND length using R15 counter.                              *
***********************************************************************
RJ_0062  DS   0H
         ST    R15,WS_LEN              Save WEB SEND length
*
         LM    0,15,REGSAVE            Load all registers
         L     R14,RJ_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
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
S_OT_LEN DC    F'80'                   OPTIONS  table maximum length
S_PA_LEN DC    F'8192'                 Parser   Array maximum length
S_FD_LEN DC    F'65000'                Field Define   maximum length
S_RA_LEN DC    F'3200000'              Response Array maximum length
         DS   0F
S_DF_LEN DC    H'32700'                FAxxFILE       maximum length
         DS   0F
S_32K    DC    F'32000'                Maximum segment length
         DS   0F
PD_ZERO  DC    XL02'000F'              Packed decimal zeroes
PD_ONE   DC    XL02'001F'              Packed decimal zeroes
PD_NINES DC    XL02'999F'              Packed decimal nines
ZD_ONE   DC    CL04'0001'              Zoned  decimal 0001
         DS   0F
ZFAM090  DC    CL08'ZFAM090 '          zFAM Loggin and error program
SK_FCT   DC    CL08'FAxxKEY '          zFAM KEY  structure
SF_FCT   DC    CL08'FAxxFILE'          zFAM FILE structure
C_CHAN   DC    CL16'ZFAM-CHANNEL    '  zFAM channel
C_OPTION DC    CL16'ZFAM-OPTIONS    '  OPTIONS container
C_TTL    DC    CL16'ZFAM-TTL        '  TTL container
C_ARRAY  DC    CL16'ZFAM-ARRAY      '  ARRAY container
         DS   0F
S_FIXED  DC    CL09'FIXED    '         Format FIXED
         DS   0F
S_XML    DC    CL09'XML      '         Format XML
         DS   0F
S_JSON   DC    CL09'JSON     '         Format JSON
         DS   0F
S_DELIM  DC    CL09'DELIMITER'         Format DELIMITER
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
M_ROWS_L DC    F'04'                   HTTP Header message length
M_ROWS   DC    CL04'0001'              HTTP Header message
H_ROWS_L DC    F'09'                   HTTP Header length
H_ROWS   DC    CL09'zFAM-Rows'         HTTP Header
         DS   0F
***********************************************************************
* Trace resources                                                     *
***********************************************************************
T_46     DC    H'46'                   Trace number
T_46_M   DC    CL08'Build RA'          Trace message
T_RES    DC    CL08'zFAM020 '          Trace resource
T_LEN    DC    H'08'                   Trace resource length
*
***********************************************************************
* Media type resources                                                *
***********************************************************************
         DS   0H
M_PLAIN  DC    CL10'TEXT/PLAIN'        Equates to FORMAT=FIXED
M_JSON   DC    CL09'TEXT/JSON'         Equates to FORMAT=JSON
M_XML    DC    CL08'TEXT/XML'          Equates to FORMAT=XML
M_DELIM  DC    CL14'TEXT/DELIMITED'    Equates to FORMAT=DELIMITED
         DS   0H
A_JSON   DC    CL16'APPLICATION/JSON'  Equates to FORMAT=JSON
A_XML    DC    CL15'APPLICATION/XML'   Equates to FORMAT=XML
***********************************************************************
* JSON characters.                                                    *
***********************************************************************
         DS   0H
T_JSON   DC    XL01'BB'                JSON trailer
T_JSON_L EQU   *-T_JSON                JSON trailer length
         DS   0H
H_XML    DC    CL16'<zFAM_ResultsArr'  XML  header
         DC    CL03'ay>'
H_XML_L  EQU   *-H_XML                 XML  header  length
         DS   0H
T_XML    DC    CL16'</zFAM_ResultsAr'  XML  trailer
         DC    CL04'ray>'
T_XML_L  EQU   *-T_XML                 XML  trailer length
         DS   0H
L_SQUIG  DC    CL01'{'                 Left  squiggle bracket
R_SQUIG  DC    CL01'}'                 Right squiggle bracket
L_SQUARE DC    XL01'BA'                Left  square   bracket
R_SQUARE DC    XL01'BB'                Right square   bracket
A_COMMA  DC    CL01','                 A comma
D_QUOTE  DC    CL01'"'                 Double quote
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
* End of Program - ZFAM020                                            *
**********************************************************************
         END   ZFAM020