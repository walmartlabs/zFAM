*
*  PROGRAM:    ZFAM022
*  AUTHOR:     Rich Jackson and Randy Frerking
*  COMMENTS:   zFAM - z/OS File Access Manager
*
*              This program is executed as the Query Mode GET/SELECT
*              service called by the ZFAM001 control program.
*
*              This program processes secondary column index requests
*              only.
*
***********************************************************************
* Start Dynamic Storage Area                                          *
***********************************************************************
DFHEISTG DSECT
REGSAVE  DS    16F                Register Save Area
BAS_REG  DS    F                  BAS return register
GM_REG   DS    F                  BAS return register - GM_0010
FM_REG   DS    F                  BAS return register - FM_0010
HH_REG   DS    F                  BAS return register - HH_00**
RJ_REG   DS    F                  BAS return register - RJ_00**
RX_REG   DS    F                  BAS return register - RX_00**
RD_REG   DS    F                  BAS return register - RD_00**
APPLID   DS    CL08               CICS Applid
SYSID    DS    CL04               CICS SYSID
USERID   DS    CL08               CICS USERID
G_LENGTH DS    F                  GETMAIN length
RA_ADDR  DS    F                  Response Array address (GETMAIN)
RA_LEN   DS    F                  Response Array length  (GETMAIN)
RA_PTR   DS    F                  Response Array address (transient)
WS_LEN   DS    F                  WEB SEND length
CI_PTR   DS    F                  CI staging     address (transient)
PA_ADDR  DS    F                  Parser   Array address
PA_LEN   DS    F                  Parser   Array length
FK_ADDR  DS    F                  zFAM Key  record address
FK_LEN   DS    F                  zFAM Key  record length
FF_ADDR  DS    F                  zFAM File record address
FF_LEN   DS    F                  zFAM File record length
CA_INIT  DS    F                  zFAM CI array address - Initial
CA_ADDR  DS    F                  zFAM CI array address - Current
CA_LEN   DS    F                  zFAM CI array length
CA_ENTRY DS    F                  zFAM CI array entry
CA_PTR   DS    F                  zFAM CI array pointer (during scan)
FD_ADDR  DS    F                  Container field address
FD_LEN   DS    F                  Container field length
         DS   0F
GM_SM    DS    CL01               GETMAIN small  buffer
GM_MD    DS    CL01               GETMAIN medium buffer
GM_LG    DS    CL01               GETMAIN larget buffer
         DS   0F
W_SEND   DS    F                  Total rows sent
W_RAE    DS    F                  Response Array Element length
W_INDEX  DS    F                  Parser array index
W_ADDR   DS    F                  Beginning data area address
W_ROWS   DS    CL08               Packed decimal ROWS  count
W_WHERE  DS    CL08               Packed decimal WHERE count
W_FIELDS DS    CL08               Packed decimal field length
W_COUNT  DS    CL08               Packed decimal field count
W_COLUMN DS    CL08               Packed decimal field column
W_PDWA   DS    CL08               Packed decimal work area
         DS   0F
M_ROWS   DS    CL04               HTTP Header message
         DS   0F
C_NAME   DS    CL16               Field Name   (container name)
C_LENGTH DS    F                  Field Length (container data)
         DS   0F
W_PRI_ID DS    CL01               Primary column ID flag
         DS   0F
***********************************************************************
* Secondary Column Index work area (staging for compare)              *
***********************************************************************
         DS   0F
C_STAGE  DS    CL256              Secondary CI staging area
***********************************************************************
* zFAM090 communication area                                          *
* Logging for ZFAM021 exceptional conditions                          *
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
* zFAM resources - Key store                                          *
***********************************************************************
WK_FCT   DS   0F                  zFAM Key  structure FCT name
WK_TRAN  DS    CL04               zFAM transaction ID
WK_DD    DS    CL04               zFAM KEY  DD name
*
WK_LEN   DS    H                  zFAM Key  structure length
*
***********************************************************************
* zFAM resources - File store                                         *
***********************************************************************
WF_FCT   DS   0F                  zFAM File structure FCT name
WF_TRAN  DS    CL04               zFAM transaction ID
WF_DS    DS    CL04               zFAM FILE Data Store
*
WF_LEN   DS    H                  zFAM File structure length
*
***********************************************************************
* zFAM resources - CI store                                           *
***********************************************************************
CI_FCT   DS   0F                  zFAM Column Index   FCT name
CI_TRAN  DS    CL04               zFAM transaction ID
CI_DD    DS   0CL04               zFAM FILE DD name
CI_CI    DS    CL02               CI
CI_ID    DS    CL02               Column index (zone   decimal)
*
CI_LEN   DS    H                  zFAM CI   structure length
         DS   0F
W_ID     DS    CL02               Column Index (packed decimal)
*
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
WF_IDN   DS    CL06               IDN
WF_NC    DS    CL02               NC
WF_SEG   DS    H                  Segment number
WF_SUFX  DS    H                  Suffix  number
WF_NULL  DS    F                  Zeroes  (not used)
*
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
* zFAM CI    store record                                             *
***********************************************************************
         DS   0F
         COPY ZFAMCIA
*
***********************************************************************
* READ HTTPHEADER fields                                              *
***********************************************************************
         DS   0F
L_HEADER DS    F                  HTTP header length
V_LENGTH DS    F                  HTTP header value length
*
***********************************************************************
* READ HTTPHEADER fields - TE                                         *
***********************************************************************
         DS   0F
T_VALUE  DS    CL08               HTTP header value
T_VAL_L  EQU   *-T_VALUE          HTTP header value field length
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
* Start Column ID array buffer                                        *
***********************************************************************
CA_DSECT DSECT
CA_ID    DS    PL02               Column ID number
CA_TYPE  DS    CL01               Field type
CA_WC    DS    CL01               Wildcard indicator
CA_F_LEN DS    PL04               Field length
CA_D_LEN DS    H                  CI data length
CA_WHERE DS    CL01               WHERE compare sign
         DS    CL05               alignment
CA_NAME  DS    CL16               Field name
CA_DATA  DS    CL256              CI data
E_CA_L   EQU   *-CA_ID            CI array entry length
*
***********************************************************************
* End   Column ID array buffer                                        *
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
*
***********************************************************************
* zFAM FILE store record buffer                                       *
***********************************************************************
         COPY ZFAMDFA
*
*
***********************************************************************
***********************************************************************
* Control Section - ZFAM022                                           *
***********************************************************************
***********************************************************************
ZFAM022  DFHEIENT CODEREG=(R2,R3),DATAREG=R11,EIBREG=R12
ZFAM022  AMODE 31
ZFAM022  RMODE 31
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'ZFAM022 '
         DC    CL48' -- Query Mode SELECT service - CI streaming    '
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
* Issue WEB READ HTTPHEADER for TE (trailers)                         *
***********************************************************************
SY_0005  DS   0H
         BAS   R14,HH_0010             Issue WEB READ HTTPHEADER
***********************************************************************
* Issue GET CONTAINER for OPTIONS table.                              *
***********************************************************************
SY_0010  DS   0H
         MVC   C_NAME,C_OPTION         Move OPTIONS table container
         MVC   C_LENGTH,S_OT_LEN       Move OPTIONS table length
         BAS   R14,GC_0020             Issue GET CONTAINER
         PACK  W_ROWS,O_ROWS           Pack number of rows to return
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
* Scan parser array and mark the segment for FIELDS and WHERE entries *
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
* Segment initialization complete.                                    *
* Prepare to scan parser array.                                       *
***********************************************************************
SY_0028  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
         OI    W_FIELDS+7,X'0C'        Set packed decimal sign bits
         OI    W_COUNT+7,X'0C'         Set packed decimal sign bits
         OI    W_WHERE+7,X'0C'         Set packed decimal sign bits
***********************************************************************
* Scan parser array tallying field lengths and CI (WHERE) entries     *
***********************************************************************
SY_0030  DS   0H
         CLI   P_WHERE,C'N'            WHERE definition?
         BC    B'0111',SY_0032         ... yes, increment WHERE count
***********************************************************************
* Increase field length and increment field count                     *
***********************************************************************
         AP    W_FIELDS,P_LEN          Add field length to total
         AP    W_COUNT,PD_ONE          Increment field count
         BC    B'1111',SY_0034         Continue scan
***********************************************************************
* Increment CI (WHERE) count                                          *
***********************************************************************
SY_0032  DS   0H
         AP    W_WHERE,PD_ONE          Increment WHERE count
         BC    B'1111',SY_0034         Continue scan
***********************************************************************
* Adjust field entry length then continue tallying field lengths      *
* and CI (WHERE) entries.                                             *
***********************************************************************
SY_0034  DS   0H
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract field entry length
         BC    B'0011',SY_0030         Continue scan until EOPA
***********************************************************************
* Issue GETMAIN for Column Index array using CI (WHERE) count.        *
***********************************************************************
SY_0036  DS   0H
         LA    R1,E_CA_L               Load CI array entry length
         ST    R1,CA_ENTRY             Save CI array entry length
         XR    R14,R14                 Clear even register
         CVB   R15,W_WHERE             Convert CI WHERE count
         M     R14,CA_ENTRY            Multiply by entry length
         ST    R15,G_LENGTH            Save GETMAIN  length
         ST    R15,CA_LEN              Save CI array length
         BAS   R14,GM_0010             Issue GETMAIN
         ST    R1,CA_INIT              Save CI array address - Initial
         ST    R1,CA_ADDR              Save CI array address - Current
         ST    R1,CA_PTR               Save CI array pointer
***********************************************************************
* Column Index array is now available to load.                        *
* Prepare to scan Parser Array to obtain WHERE container names.       *
***********************************************************************
SY_0038  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
***********************************************************************
* Scan Parser Array for CI (WHERE) definitions.                       *
***********************************************************************
SY_0040  DS   0H
         CLI   P_WHERE,C'N'            WHERE definition?
         BC    B'1000',SY_0048         ... no,  continue PA scan
***********************************************************************
* Set CI array pointer, then issue GET CONTAINER for WHERE data.      *
* Filter fields greater than 256 bytes are not allowed.               *
***********************************************************************
         MVC   C_FIELD,P_NAME          Move field name for diagnostics
         CP    P_LEN,PD_256            Maximum filter length exceeded?
         BC    B'0010',ER_41201        ... yes, reject request
*
         MVC   C_LENGTH,MAX_CI         Load maximum CI data length
         MVC   C_NAME,P_NAME           Move WHERE container name
*
         BAS   R14,GC_0010             Issue GET CONTAINER
         ST    R9,FD_ADDR              Save field data address
         MVC   FD_LEN,C_LENGTH         Move field data length
*
         L     R7,CA_PTR               Load CI Array pointer
         USING CA_DSECT,R7             ... tell assembler
*
         MVC   CA_WHERE,P_WHERE        Move WHERE compare sign
         MVC   CA_NAME,P_NAME          Move Field name
         MVC   CA_ID,P_ID              Move Column ID number
         MVC   CA_F_LEN,P_LEN          Move Field length
         MVC   CA_TYPE,P_TYPE          Move field type
         L     R1,FD_LEN               Load CI data length
         STH   R1,CA_D_LEN             Save CI data length
*
         L     R14,FD_ADDR             Load CI data address
         MVI   CA_WC,C'*'              Set Wildcard to 'yes'
***********************************************************************
* Scan Secondary Column Index for wildcard '*'.                       *
***********************************************************************
SY_0041  DS   0H
         CLI   0(R14),C'*'             Wildcard present?
         BC    B'1000',SY_0042         ... yes, continue
         LA    R14,1(,R14)             Point to next byte
         BCT   R1,SY_0041              Continue parsing
         MVI   CA_WC,C' '              Set Wildcard to 'no'
***********************************************************************
* Select Secondary Column Index field type and branch accordingly.    *
***********************************************************************
SY_0042  DS   0H
         CLI   CA_WC,C'*'              Wildcard present?
         BC    B'1000',SY_0043         ... yes, treat as character
         CLI   CA_TYPE,C'C'            Character field type?
         BC    B'1000',SY_0043         ... yes, left  justify move
         CLI   CA_TYPE,C'N'            Numeric field type?
         BC    B'1000',SY_0045         ... yes, right justify move
***********************************************************************
* Left  justify CI data (character)                                   *
***********************************************************************
SY_0043  DS   0H
         LA    R14,CA_DATA             Load target address
         MVI   CA_DATA,X'40'           Set first byte to spaces
         ZAP   W_PDWA,CA_F_LEN         Move field length
         CVB   R1,W_PDWA               Convert to binary
         S     R1,=F'1'                Subtract for EX command
         LTR   R1,R1                   Length zero?
         BC    B'1000',*+12            ... yes, don't adjust
         LA    R14,1(,R14)             ... no,  adjust target address
         S     R1,=F'1'                ...      and adjust length
         LA    R15,CA_DATA             Load source address
         EX    R1,MVC_0042             Set  target to spaces
*
         L     R1,FD_LEN               Load field data length
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,CA_DATA             Load target address
         L     R15,FD_ADDR             Load source address
         EX    R1,MVC_0042             Execute MVC instruction
*
         BC    B'1111',SY_0046         Adjust CI Array pointer
MVC_0042 MVC   0(0,R14),0(R15)         Move WHERE to CI Array
*
***********************************************************************
* Right justify CI data (numeric)                                     *
***********************************************************************
SY_0045  DS   0H
         LA    R14,CA_DATA             Load target address
         MVI   CA_DATA,X'F0'           Set first byte to zeroes
         ZAP   W_PDWA,CA_F_LEN         Move field length
         CVB   R1,W_PDWA               Convert to binary
         S     R1,=F'1'                Subtract for EX command
         LTR   R1,R1                   Length zero?
         BC    B'1000',*+12            ... yes, don't adjust
         LA    R14,1(,R14)             ... no,  adjust target address
         S     R1,=F'1'                ...      and adjust length
         LA    R15,CA_DATA             Load source address
         EX    R1,MVC_0044             Set  target to zeroes
*
         CVB   R13,W_PDWA              Convert field length to binary
         L     R1,FD_LEN               Load field data length
         SR    R13,R1                  Subtract from maximum
*
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,CA_DATA             Load target addres
         LA    R14,0(R13,R14)          Adjust for field length
         L     R15,FD_ADDR             Load source address
         EX    R1,MVC_0044             Execute MVC instruction
*
         BC    B'1111',SY_0046         Adjust CI Array pointer
MVC_0044 MVC   0(0,R14),0(R15)         Move WHERE to CI Array
*
***********************************************************************
* Adjust CI Array pointer.                                            *
***********************************************************************
SY_0046  DS   0H
         LA    R1,E_CA_L               Load CI Array entry length
         LA    R7,0(R1,R7)             Point to next entry
         ST    R7,CA_PTR               Save CI Array pointer
***********************************************************************
* Adjust field entry length then continue parser array scan for       *
* CI (WHERE) entries.                                                 *
***********************************************************************
SY_0048  DS   0H
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract field entry length
         BC    B'0011',SY_0040         Continue scan until EOPA
***********************************************************************
* Calculate GETMAIN length for Response Array.  The Primary Key is    *
* included in the Response Array length.                              *
***********************************************************************
SY_0050  DS   0H
         CVB   R1,W_FIELDS             Convert field length to binary
         XC    W_PDWA,W_PDWA           Clear packed decimal work area
         MVC   W_PDWA+4(4),O_P_LEN     Move primary key length
         CVB   R13,W_PDWA              Convert key   length to binary
         AR    R1,R13                  Add key length to response
*
         CLI   R_TYPE,R_PLAIN          Delimit by fixed length?
         BC    B'1000',SY_0058         ... yes, set GETMAIN length
*
         XR    R14,R14                 Clear even register
         CVB   R15,W_COUNT             Convert field count to binary
*
         CLI   R_TYPE,R_XML            Delimit by XML  tags?
         BC    B'1000',SY_0052         ... yes, set length
         CLI   R_TYPE,R_JSON           Delimit by JSON tags?
         BC    B'1000',SY_0054         ... yes, set length
         CLI   R_TYPE,R_DELIM          Delimit by pipe character?
         BC    B'1000',SY_0056         ... yes, set length
         BC    B'1111',SY_0058         ... no,  default FIXED
***********************************************************************
* Include XML  tags in total length                                   *
***********************************************************************
SY_0052  DS   0H
         M     R14,=F'37'              Multiply count by XML  length
         AR    R1,R15                  Add XML  tags to field length
         A     R1,=F'37'               Add XML  tags to key field
         BC    B'1111',SY_0060         Set GETMAIN length
***********************************************************************
* Include JSON tags in total length                                   *
***********************************************************************
SY_0054  DS   0H
         M     R14,=F'24'              Multiply count by JSON length
         AR    R1,R15                  Add JSON tags to field length
         A     R1,=F'32'               Add JSON tags to key field
*
         BC    B'1111',SY_0060         Set GETMAIN length
***********************************************************************
* Include PIPE tags in total length                                   *
***********************************************************************
SY_0056  DS   0H
         M     R14,=F'1'               Multiply count by PIPE length
         AR    R1,R15                  Add PIPE tags to field length
         A     R1,=F'1'                Add PIPE tags to key field
         BC    B'1111',SY_0060         Set GETMAIN length
***********************************************************************
* Include Key length in total length                                  *
***********************************************************************
SY_0058  DS   0H
         A     R1,=F'0'                Add keylength and key field
         BC    B'1111',SY_0060         Set GETMAIN length
***********************************************************************
* Issue GETMAIN for Response Array.  This buffer will include the     *
* Primary Key field, as well as each selected field.                  *
***********************************************************************
SY_0060  DS   0H
         ST    R1,W_RAE                Save Response Array element
         ST    R1,G_LENGTH             Save in work area
         CLC   G_LENGTH,S_GM_Max       Exceed maximum buffer size?
         BC    B'0011',SY_0920         ... yes, send HTTP status 206
         BAS   R14,GM_0010             Issue GETMAIN
         ST    R1,RA_ADDR              Save Response Array address
         MVC   RA_LEN,G_LENGTH         Save Response Array length
*
***********************************************************************
* The first WHERE field is used for Secondary Column Index search,    *
* while all other fields are used as filters within the primary data. *
***********************************************************************
SY_0062  DS   0H
         L     R7,CA_INIT              Load CI array initial address
         LA    R1,E_CA_L               Load CI array entry length
         L     R13,CA_LEN              Load CI array length
***********************************************************************
* Scan Column Index array for Secondary Column Index.                 *
***********************************************************************
SY_0063  DS   0H
         CP    CA_ID,PD_ONE            Primary Index?
         BC    B'0011',SY_0064         ... no,  continue
         LA    R7,0(R1,R7)             Point to next entry address
         SR    R13,R1                  Subtract entry length
         BC    B'0010',SY_0063         Continue scan
         BC    B'1101',ER_50705        This should never happen
***********************************************************************
* Secondary Column Index found in table.  Set CA_ADDR accordingly.    *
***********************************************************************
SY_0064  DS   0H
         ST    R7,CA_ADDR              Save Secondary CI address
***********************************************************************
* Set Column Index record key.                                        *
* Secondary Column Index maximum field length is 56 bytes.            *
***********************************************************************
SY_0070  DS   0H
         MVC   C_FIELD,CA_NAME         Move field name for diagnostics
         CP    CA_F_LEN,PD_56          Maximum CI length exceeded?
         BC    B'0010',ER_41202        ... yes, reject request
*
         L     R7,CA_ADDR              Load first CI Array key
         MVC   CI_FIELD,CA_DATA        Move CI data to record key
*
***********************************************************************
* Prepare to scan Parser Array to find first Secondary CI entry.      *
***********************************************************************
SY_0071  DS   0H
         L     R4,PA_LEN               Load parser array length
         L     R5,PA_ADDR              Load parser array address
         USING PA_DSECT,R5             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
***********************************************************************
* Note:  A field can be both WHERE and FIELD, which means there can   *
* be two entries in the parser array.  The field selected as the      *
* Secondary Column Index must be set as 'ineligible' in the Parser    *
* Array to keep from processing twice as an index.                    *
***********************************************************************
SY_0072  DS   0H
         CLC   P_ID,PD_ONE             Primary index?
         BC    B'1000',SY_0075         ... yes, get next entry
         CLI   P_WHERE,C'N'            WHERE indicator?
         BC    B'0111',SY_0077         ... yes, set as ineligible
***********************************************************************
* Point to next Parser Array entry.                                   *
***********************************************************************
SY_0075  DS   0H
         LA    R5,0(R6,R5)             Point to next PA entry
         SR    R4,R6                   Subtract field entry length
         BC    B'0011',SY_0072         Continue scan until EOPA
***********************************************************************
* Mark the Secondary Column Index as 'ineligible' in the Parser Array *
***********************************************************************
SY_0077  DS   0H
         MVC   P_ID,PD_NINES           Mark as ineligible
*
*
         CLI   CA_WC,C'*'              Wildcard present in WHERE?
         BC    B'0111',SY_0080         ... no,  continue process
*
         LA    R14,CI_FIELD            Load CI field address
         LA    R1,56                   Load CI field length maximum
***********************************************************************
* Check for wildcard '*' and set to null.                             *
***********************************************************************
SY_0078  DS   0H
         CLI   0(R14),C'*'             Wildcard?
         BC    B'1000',SY_0079         ... yes, set to null
         LA    R14,1(,R14)             Point to next byte
         BCT   R1,SY_0078              Continue parsing
         BC    B'1111',SY_0080         No wildcard, continue process
***********************************************************************
* Set wildcard and remaining fields to null                           *
***********************************************************************
SY_0079  DS   0H
         MVI   0(R14),X'00'            Set to null
         LA    R14,1(,R14)             Point to next byte
         BCT   R1,SY_0079              Continue nullifying
***********************************************************************
* Access Secondary Column Index.                                      *
***********************************************************************
SY_0080  DS   0H
         MVC   CI_TRAN,EIBTRNID        Move CI DDNAME FA##
         MVC   CI_CI,=C'CI'            Move CI DDNAME CI*
         UNPK  CI_ID,CA_ID             Unpack CI number into DDNAME
         OI    CI_ID+1,X'F0'           Set sign bits
         XC    CI_IDN,CI_IDN           Clear IDN
         XC    CI_NC,CI_NC             Clear NC
*
         EXEC CICS STARTBR FILE(CI_FCT)                                X
              RIDFLD(CI_KEY)                                           X
              GTEQ                                                     X
              NOHANDLE
*
         CLC   EIBRESP,=F'13'          NOTFND  condition?
         BC    B'1000',ER_20401        ... yes, STATUS(204)
         OC    EIBRESP,EIBRESP         Normal condition?
         BC    B'0111',ER_50701        ... no,  File I/O error
*
***********************************************************************
* Issue READNEXT until EOF or key range is exceeded.                  *
***********************************************************************
SY_0090  DS   0H
         L     R7,CA_ADDR              Load first CI Array key
*
         LA    R1,E_CI                 Load CI record length
         STH   R1,CI_LEN               Save CI record length
*
         EXEC CICS READNEXT FILE(CI_FCT)                               X
              RIDFLD(CI_KEY)                                           X
              INTO  (CI_REC)                                           X
              LENGTH(CI_LEN)                                           X
              NOHANDLE
*
         CLC   EIBRESP,=F'20'          ENDFILE condition?
         BC    B'1000',SY_0900         ... yes, issue WEB SEND
         CLC   EIBRESP,=F'13'          NOTFND  condition?
         BC    B'1000',SY_0900         ... yes, issue WEB SEND
*
         OC    EIBRESP,EIBRESP         Normal condition?
         BC    B'0111',ER_50702        ... no,  File I/O error
*
         L     R1,W_SEND               Load current send count
*
         CP    W_ROWS,=PL8'0'          Rows set to zero?
         BC    B'1000',SY_0092         ... yes, get all qualified rows
*
         CVB   R14,W_ROWS              Convert maximum row count
         CR    R1,R14                  Send count GT/EQ row count?
         BC    B'1011',SY_0900         ... yes, issue WEB SEND
*
***********************************************************************
* Address Column Index and set maximum length.                        *
***********************************************************************
SY_0092  DS   0H
         ZAP   W_PDWA,CA_F_LEN         Move CA field length
         CVB   R1,W_PDWA               Convert to binary
***********************************************************************
* Check WHERE field for wildcard '*'.                                 *
***********************************************************************
SY_0094  DS   0H
         CLI   CA_WC,C'*'              Wildcard?
         BC    B'0111',SY_0096         ... no,  use CA field length
         LH    R1,CA_D_LEN             ... yes, use CA data  length
***********************************************************************
* Compare CI record and WHERE field using full or wildcard length.    *
***********************************************************************
SY_0096  DS   0H
         LA    R14,CA_DATA             Load WHERE field   address
         LA    R15,CI_FIELD            Load CI record key address
         S     R1,=F'1'                Subtract one for EX instruction
*
         CLI   CA_WC,C'*'              Wildcard present?
         BC    B'0111',*+8             ... no,  continue process
         S     R1,=F'1'                Subtract one for '*'
*
         CLI   CA_WHERE,C'='           EQ condition?
         BC    B'1000',SY_96EQ         ... yes, compare
         CLI   CA_WHERE,C'>'           GT condition?
         BC    B'1000',SY_96GT         ... yes, compare
         CLI   CA_WHERE,C'+'           GE condition?
         BC    B'1000',SY_96GE         ... yes, compare
*
SY_96EQ  DS   0H
         EX    R1,CLC_0096             CI Record EQ WHERE?
         BC    B'1000',SY_0100         ... yes, continue process
         BC    B'1111',SY_0900         ... no,  issue WEB SEND
*
SY_96GT  DS   0H
         EX    R1,CLC_0096             CI Record GT WHERE?
         BC    B'0010',SY_0100         ... yes, continue process
         BC    B'1111',SY_0900         ... no,  issue WEB SEND
*
SY_96GE  DS   0H
         EX    R1,CLC_0096             CI Record GE WHERE?
         BC    B'1010',SY_0100         ... yes, continue process
         BC    B'1111',SY_0900         ... no,  issue WEB SEND
*
*
CLC_0096 CLC   0(0,R15),0(R14)         Compare CI Record and WHERE
*
***********************************************************************
* Trace where we are.                                                 *
***********************************************************************
sy_0100  DS   0H
         MVC   W_46_M,=C'SY_0100 '     Move trace entry
         BAS   R14,TR_0010             Call trace routine
*
***********************************************************************
* Issue READ for FAxxFILE using Primary Column Index.                 *
***********************************************************************
SY_0110  DS   0H
         MVC   WF_LEN,S_DF_LEN         Move FILE record length
         XC    WF_SUFX,WF_SUFX         Clear key suffix
         XC    WF_NULL,WF_NULL         Clear key null field
         MVC   WF_IDN,CI_IDN           Move ID number
         MVC   WF_NC,CI_NC             Move named counter value
*
         MVC   WF_SEG,=H'01'           Segment number for primary key
         BAS   R14,FF_0010             Issue READ for FILE structure
*
         CLC   EIBRESP,=F'13'          NOTFND  condition?
         BC    B'1000',SY_0890         ... yes, delete CI record
         OC    EIBRESP,EIBRESP         Normal condition?
         BC    B'0111',ER_50703        ... no,  File I/O error
*
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
         ICM   R15,B'1000',HEX_00      Set pad byte
         MVCL  R4,R14                  Move nulls to Response Array
         LM    0,15,REGSAVE            Load registers
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0010             ... yes, create JSON tag
*
         L     R4,RA_PTR               Load RA pointer
         ZAP   W_LENGTH,O_P_LEN        Move primary key length
         CVB   R1,W_LENGTH             Load into register
         S     R1,=F'1'                Subtract one for EX MVC
         LR    R14,R4                  Load RA primary key address
         L     R15,W_FF_A              Load field data address
         ZAP   W_COLUMN,O_P_COL        Move field column
         CVB   R6,W_COLUMN             Load into register
         S     R6,=F'1'                Make relative to zero
         LA    R15,0(R6,R15)           Adjust address with column
         EX    R1,MVC_0120             Execute MVC instruction
         BC    B'1111',SY_0130         Skip EX MVC
MVC_0120 MVC   0(0,R14),0(R15)         Move primary key to RA
***********************************************************************
* Adjust Response Array address and length                            *
***********************************************************************
SY_0130  DS   0H
         ZAP   W_LENGTH,O_P_LEN        Move field data length
         CVB   R1,W_LENGTH             Load into register
         SR    R5,R1                   Adjust Response Array length
         LA    R4,0(R1,R4)             Point to first field
         ST    R4,RA_PTR               Save as Response Array base
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0020             ... yes, create JSON tag
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
         CLC   P_ID,PD_NINES           Ineligible field?
         BC    B'1000',SY_0165         ... yes, get next entry
*
         TM    P_ID,X'80'              Entry already processed?
         BC    B'0001',SY_0160         ... yes, get next entry
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
         OI    P_ID,X'80'              Mark field as processed
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
*
         CLI   P_WHERE,C'N'            WHERE field?
         BC    B'0111',SY_0400         ... yes, process accordingly
*
         L     R4,RA_PTR               Load target address
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
         L     R4,RA_PTR               Load target address
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
*
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
         L     R1,W_REL_L              Load relative field length
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
         TM    P_ID,X'80'              Processed entry?
         BC    B'0001',SY_0270         ... yes, continue
         L     R8,PA_LEN               Load parser array length
         L     R9,PA_ADDR              Load parser array address
*
         MVC   WF_LEN,S_DF_LEN         Move FILE record length
         MVC   WF_SEG,P_SEG            Set segment number
         BAS   R14,FF_0010             Issue READ for FILE structure
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_20404        ... no,  STATUS(204)
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
         BC    B'1111',SY_0800         Send chunked message to client
*
********************************************************************
* Secondary Column Index Section                                      *
***********************************************************************
SY_0400  DS   0H
         XC    C_STAGE,C_STAGE         Null CI staging field
         LA    R1,C_STAGE              Load CI staging field address
         ST    R1,CI_PTR               Save CI staging field address
***********************************************************************
* Calculate width to determine if field spans a segment.              *
***********************************************************************
SY_0485  DS   0H
         L     R1,W_REL_D              Load relative displacement
         CVB   R6,W_LENGTH             Convert length to binary
         AR    R6,R1                   Add relative displacement
         ST    R6,W_WIDTH              Save field width
         C     R6,S_32K                Wider than 32K?
         BC    B'0011',SY_0500         ... yes, spanned segment
***********************************************************************
* Move WHERE field to staging area for compare.                       *
***********************************************************************
SY_0490  DS   0H
         STM   0,15,REGSAVE            Save registers
         CVB   R7,W_LENGTH             Set source length
         L     R1,W_REL_D              Load relative displacement
         L     R6,W_FF_A               Set source address
         LA    R6,0(R1,R6)             Add relative displacement
         LR    R5,R7                   Set target length
*
         L     R4,CI_PTR               Set target address
*
         MVCL  R4,R6                   Move field to Staging area
         LM    0,15,REGSAVE            Load registers
*
         BC    B'1111',SY_0600         Compare WHERE field with record
***********************************************************************
* WHERE field spans segments                                          *
***********************************************************************
SY_0500  DS   0H
         STM   0,15,REGSAVE            Save registers
         L     R1,W_REL_D              Load relative displacement
         L     R6,W_WIDTH              Load field width
         SR    R6,R1                   Subtract relative displacement
         ST    R6,W_WIDTH              Save field width
***********************************************************************
* Move spanned segment WHERE field to staging area                    *
***********************************************************************
SY_0510  DS   0H
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
         L     R4,CI_PTR               Set target address
*
         MVCL  R4,R6                   Move field to Staging area
*
         L     R1,W_REL_L              Load relative field length
         L     R4,CI_PTR               Load current CI staging pointer
         LA    R4,0(R1,R4)             Load the new CI staging pointer
         ST    R4,CI_PTR               Save the new CI staging pointer
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
         BC    B'0111',ER_20405        ... no,  STATUS(204)
         ST    R10,FF_ADDR             Save FILE buffer address
         USING DF_DSECT,R10            ... tell assembler
         LA    R1,DF_DATA              Load data portion
         ST    R1,W_FF_A               Save data portion
         MVC   FF_LEN,WF_LEN           Save FILE buffer length
         MVC   SS_SEG,WF_SEG           Save spanned segment number
*
         L     R1,W_REL_D              Load relative displacement
         BC    B'1111',SY_0485         Move remainder to RA
***********************************************************************
* Compare WHERE field from file buffer with Column Index Array        *
***********************************************************************
SY_0600  DS   0H
         DROP  R7                      ... tell assembler
*
         STM   0,15,REGSAVE            Save registers
         LA    R1,E_CA_L               Load CI array entry length
         L     R13,CA_LEN              Load CI array length
         L     R10,CA_INIT             Load CI array initial address
*        L     R10,CA_ADDR             Load CI array address
         USING CA_DSECT,R10            ... tell assembler
***********************************************************************
* Scan Column Index array for match with current Parser Array         *
***********************************************************************
SY_0610  DS   0H
         CLC   CA_NAME,P_NAME          Field name match?
         BC    B'1000',SY_0620         ... yes, continue
         LA    R10,0(R1,R10)           Point to next entry address
         SR    R13,R1                  Subtract entry length
         BC    B'0010',SY_0610         Continue scan
         BC    B'1101',ER_50704        This should never happen
***********************************************************************
* Scan Column Index array for possible wildcard '*'                   *
***********************************************************************
SY_0620  DS   0H
         ZAP   W_PDWA,CA_F_LEN         Move CA field length
         CVB   R1,W_PDWA               Convert to binary
***********************************************************************
* Check WHERE field for wildcard '*'.                                 *
***********************************************************************
SY_0630  DS   0H
         CLI   0(R14),C'*'             Wildcard?
         BC    B'0111',SY_0640         ... no,  use CA field length
         LH    R1,CA_D_LEN             ... yes, use CA data  length
***********************************************************************
* Compare Column Index array with column field in current record.     *
***********************************************************************
SY_0640  DS   0H
         LA    R14,C_STAGE             Load record data address
         LA    R15,CA_DATA             Load WHERE  data address
         S     R1,=F'1'                Subtract one for EX instruction
*
         CLI   CA_WC,C'*'              Wildcard present?
         BC    B'0111',*+8             ... no,  continue process
         S     R1,=F'1'                Subtract one for '*'
*
         CLI   CA_WHERE,C'='           EQ condition?
         BC    B'1000',SY_640EQ        ... yes, compare
         CLI   CA_WHERE,C'>'           GT condition?
         BC    B'1000',SY_640GT        ... yes, compare
         CLI   CA_WHERE,C'+'           GE condition?
         BC    B'1000',SY_640GE        ... yes, compare
*
SY_640EQ DS   0H
         EX    R1,CLC_0640             WHERE EQ Record field?
         BC    B'1000',SY_0650         ... yes, continue process
         BC    B'1111',SY_0880         ... no,  bypass this record
*
SY_640GT DS   0H
         EX    R1,CLC_0640             WHERE GT Record field?
         BC    B'0010',SY_0650         ... yes, continue process
         BC    B'1111',SY_0880         ... no,  bypass this record
*
SY_640GE DS   0H
         EX    R1,CLC_0640             WHERE GE Record field?
         BC    B'1010',SY_0650         ... yes, continue process
         BC    B'1111',SY_0880         ... no,  bypass this record
*
CLC_0640 CLC   0(0,R15),0(R14)         Compare WHERE and CI Record
*
***********************************************************************
* CI record and WHERE field match.  Continue parser array process.    *
***********************************************************************
SY_0650  DS   0H
         BC    B'1111',SY_0140         Continue parser array process
*
***********************************************************************
* Send each response array as a 'chunked' message.                    *
***********************************************************************
SY_0800  DS   0H
         L     R4,RA_PTR               Load RA pointer
*
         CLI   R_TYPE,R_JSON           Result set JSON?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0050             ... yes, create JSON tag
*
         L     R1,W_SEND               Load current send count
         LA    R1,1(,R1)               Add  one to  send count
         ST    R1,W_SEND               Save current send count
*
         BAS   R14,WS_0010             Send chunked message
         BAS   R14,RP_0010             Reset Parser  Array
*
         BC    B'1111',SY_0090         Read Secondary Column Index
*
***********************************************************************
* When processing multiple secondary indexes from a WHERE clause,     *
* only one is used to access a Column Index (FAxxCI##) store.  All    *
* other CI's will be compared to the current data store record.       *
* When any of the other CI's don't match the corresponding field in   *
* the record, the information on this record will not be returned.    *
* Simply leave the Response Array pointer where it is and the next    *
* matching record information will be placed in the response array    *
* and will overlay any residual information that was in flight.       *
***********************************************************************
SY_0880  DS   0H
         BAS   R14,RP_0010             Reset Parser  Array
*
         BC    B'1111',SY_0090         Read Secondary Column Index
*
***********************************************************************
* When the Primary Key record is not found, delete the secondary CI   *
* record.  Reset parser array, then continue with READNEXT of         *
* secondary CI records.                                               *
***********************************************************************
SY_0890  DS   0H
         EXEC CICS DELETE                                              X
              FILE  (CI_FCT)                                           X
              RIDFLD(CI_KEY)                                           X
              NOHANDLE
*
         BAS   R14,RP_0010             Reset Parser  Array
*
         BC    B'1111',SY_0090         Read Secondary Column Index
*
***********************************************************************
* Send final chunked information                                      *
***********************************************************************
SY_0900  DS   0H
         BAS   R14,WS_0030             Issue WEB SEND CHUNKEND
         BC    B'1111',RETURN          Return to CICS
*
***********************************************************************
* Response array size exceeds maximum buffer size                     *
* Send response with STATUS(206)                                      *
***********************************************************************
SY_0920  DS   0H
         BAS   R14,WS_0020             Issue WEB SEND
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
* Issue GETMAIN for various control blocks                            *
***********************************************************************
GM_0010  DS   0H
         ST    R14,GM_REG              Save return register
*
         EXEC CICS GETMAIN                                             X
               SET(R1)                                                 X
               FLENGTH(G_LENGTH)                                       X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         L     R14,GM_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue FREEMAIN for various control blocks                           *
***********************************************************************
FM_0010  DS   0H
         ST    R14,FM_REG              Save return register
*
         EXEC CICS FREEMAIN                                            X
               DATAPOINTER(R1)                                         X
               NOHANDLE
*
         L     R14,FM_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue READ for FAxxFILE structure                                   *
* When the spanned segment number is equal to the WF_SEG, then the    *
* segment has already been read during spanned segment processing.    *
***********************************************************************
FF_0010  DS   0H
         DROP  R10                     ... tell assembler
         ST    R14,BAS_REG             Save return register
*
         CLC   SS_SEG,WF_SEG           Segment numbers equal?
         BC    B'1000',FF_0020         ... yes, record is in the buffer
*
         MVC   WF_TRAN,EIBTRNID        Move FILE structure ID
         MVC   WF_DS,CI_DS             Move FILE data store
*
         EXEC CICS READ FILE(WF_FCT)                                   X
               SET(R10)                                                X
               RIDFLD (WF_KEY)                                         X
               LENGTH (WF_LEN)                                         X
               NOHANDLE
*
         USING DF_DSECT,R10            ... tell assembler
*
         MVC   W_SEG,DF_SEG            Move current segment number
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
*
***********************************************************************
* Reset Parser Array.                                                 *
***********************************************************************
RP_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         STM   0,15,REGSAVE            Save registers
         L     R8,PA_LEN               Load parser array length
         L     R9,PA_ADDR              Load parser array address
         USING PA_DSECT,R9             ... tell assembler
         LA    R6,E_PA                 Load parser array entry length
***********************************************************************
* Scan Parser Array and reset Column ID process indicator.            *
* Note:  Don't reset an ineligible Column ID.                         *
***********************************************************************
RP_0020  DS   0H
         CP    P_ID,PD_NINES           Ineligible Column Index?
         BC    B'1000',*+8             ... yes, leave as is
         NI    P_ID,X'7F'              Flip off bit '8'
         LA    R9,0(R6,R9)             Point to next PA entry
         SR    R8,R6                   Subtract field entry length
         BC    B'0011',RP_0020         Continue scan until EOPA
***********************************************************************
* Return to calling routine.                                          *
***********************************************************************
RP_0030  DS   0H
         LM    0,15,REGSAVE            Save registers
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
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
* Send chunked messages.                                              *
* Here's the rules regarding sending chunked messages for the         *
* result set:                                                         *
*                                                                     *
* When this routine is called and the number of matching records read *
* is zero, send an HTTP status code 204.                              *
*                                                                     *
* When the number of matching records read is one, send the result    *
* set and include the HTTP parameters.                                *
* This will include Fixed Format, JSON, XML and Pipe delimited.       *
*                                                                     *
* When the number of matching records read is greater than one,       *
* send only the result set and exclude the HTTP parameters.           *
* This will include Fixed Format, JSON, XML and Pipe delimited.       *
*                                                                     *
***********************************************************************
WS_0010  DS   0H
         ST    R14,BAS_REG             Save return register
         L     R4,RA_ADDR              Load response array address
         USING RA_DSECT,R4             ... tell assembler
*
         OC    W_SEND,W_SEND           Any records to be returned?
         BC    B'1000',ER_20408        ... no,  STATUS(204)
*
         CLC   W_SEND,ONE              First record?
         BC    B'0111',WS_0018         ... no,  send data only
         BC    B'1111',WS_0016         ... yes, send data and parms
*
***********************************************************************
* Start Chunked Message Transfer, which includes the HTTP parameters  *
* and the result set.                                                 *
***********************************************************************
WS_0016  DS   0H
         MVC   WS_LEN,RA_LEN           Set WEB SEND length
*
         CLC   T_VALUE,TRAILERS        Trailers allowed?
         BC    B'0111',*+8             ... no,  bypass Trailer header
         BAS   R14,HH_0020             Write Trailer header
*
         CLI   R_TYPE,R_JSON           JSON format requested?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0060             ... yes, get RA length
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
               CHUNKYES                                                X
               NOHANDLE
*
         BC    B'1111',WS_0019         Continue process
*
***********************************************************************
* Chunked Message Transfer has been started already, so this routine  *
* will send only the result set and exclude the HTTP parameters.      *
***********************************************************************
WS_0018  DS   0H
         MVC   WS_LEN,RA_LEN           Set WEB SEND length
*
         CLI   R_TYPE,R_JSON           JSON format requested?
         BC    B'0111',*+8             ... no,  continue
         BAS   R14,RJ_0060             ... yes, get RA length
*
         EXEC CICS WEB SEND                                            X
               FROM      (RA_DSECT)                                    X
               FROMLENGTH(WS_LEN)                                      X
               CHUNKYES                                                X
               NOHANDLE
*
         BC    B'1111',WS_0019         Continue process
*
***********************************************************************
* Return to calling routine.                                          *
***********************************************************************
WS_0019  DS   0H
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* The maximum result set buffer is 1mb.  When zFAM022 is building the *
* result set and the buffer is full, partial results will be returned.*
* Send response (WEB SEND) STATUS(206)                                *
***********************************************************************
WS_0020  DS   0H
         ST    R14,BAS_REG             Save return register
         L     R4,RA_ADDR              Load response array address
         USING RA_DSECT,R4             ... tell assembler
*
         CLC   T_VALUE,TRAILERS        Trailers allowed?
         BC    B'0111',*+8             ... no,  bypass Trailer header
         BAS   R14,HH_0030             Create HTTP Header
*
         EXEC CICS WEB SEND                                            X
               FROM      (H_206_T)                                     X
               FROMLENGTH(H_206_L)                                     X
               ACTION    (H_ACTION)                                    X
               MEDIATYPE (H_MEDIA)                                     X
               STATUSCODE(H_206)                                       X
               STATUSTEXT(H_206_T)                                     X
               STATUSLEN (H_206_L)                                     X
               SRVCONVERT                                              X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* All result sets have been sent.  When JSON or XML result set has    *
* been requeted, send the final control characters before sending the *
* trailing headers and ending the Chunked Message Transfer.           *
***********************************************************************
WS_0030  DS   0H
         ST    R14,BAS_REG             Save return register
         L     R4,RA_ADDR              Load response array address
         USING RA_DSECT,R4             ... tell assembler
*
         OC    W_SEND,W_SEND           Any records to be returned?
         BC    B'1000',ER_20408        ... no,  STATUS(204)
*
         CLI   R_TYPE,R_JSON           JSON format requested?
         BC    B'1000',WS_0032         ... yes, process accordinly.
*
         CLI   R_TYPE,R_XML            XML  format requested?
         BC    B'1000',WS_0034         ... yes, process accordinly.
*
         BC    B'1111',WS_0039         Process as Fixed or Delimited.
*
***********************************************************************
* All result sets have been sent.  Send the JSON trailing array       *
* character before sending the trailing headers and ending the        *
* Chunked Message Transfer.                                           *
***********************************************************************
WS_0032  DS   0H
         LA    R1,T_JSON_L             Load JSON trailer length
         ST    R1,M_LENGTH             Save JSON trailer length
*
         EXEC CICS WEB SEND                                            X
               FROM      (T_JSON)                                      X
               FROMLENGTH(M_LENGTH)                                    X
               CHUNKYES                                                X
               NOHANDLE
*
         BC    B'1111',WS_0039         Process as Fixed or Delimited.
*
***********************************************************************
* All result sets have been sent.  Send the XML  trailing array       *
* character before sending the trailing headers and ending the        *
* Chunked Message Transfer.                                           *
***********************************************************************
WS_0034  DS   0H
         LA    R1,T_XML_L              Load XML  trailer length
         ST    R1,M_LENGTH             Save XML  trailer length
*
         EXEC CICS WEB SEND                                            X
               FROM      (T_XML)                                       X
               FROMLENGTH(M_LENGTH)                                    X
               CHUNKYES                                                X
               NOHANDLE
*
         BC    B'1111',WS_0039         Process as Fixed or Delimited.
***********************************************************************
* All result sets have been sent.  Send the trailing headers and end  *
* the Chunked Message Transfer.                                       *
***********************************************************************
WS_0039  DS   0H
         CLC   T_VALUE,TRAILERS        Trailers allowed?
         BC    B'0111',*+8             ... no,  bypass Trailer header
         BAS   R14,HH_0030             Create HTTP Header
*
         EXEC CICS WEB SEND                                            X
               CHUNKEND                                                X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Check  HTTP Header for TE (trailers).                               *
***********************************************************************
HH_0010  DS   0H
         ST    R14,HH_REG              Save return register
*
         LA    R1,T_LENGTH             Load header name  length
         ST    R1,L_HEADER             Save header name  length
         LA    R1,T_VAL_L              Load value  field length
         ST    R1,V_LENGTH             Save value  field length
*
         EXEC CICS WEB READ HTTPHEADER(T_HEADER)                       X
               NAMELENGTH(L_HEADER)                                    X
               VALUE(T_VALUE)                                          X
               VALUELENGTH(V_LENGTH)                                   X
               NOHANDLE
*
         OC    T_VALUE,HEX_40          Set upper case bits
*
         L     R14,HH_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Create HTTP Header for subsequent 'Trailers'.                       *
***********************************************************************
HH_0020  DS   0H
         ST    R14,HH_REG              Save return register
*
         EXEC CICS WEB WRITE                                           X
               HTTPHEADER (H_HEAD)                                     X
               NAMELENGTH (H_HEAD_L)                                   X
               VALUE      (M_HEAD)                                     X
               VALUELENGTH(M_HEAD_L)                                   X
               NOHANDLE
*
         L     R14,HH_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Create HTTP Header.                                                 *
***********************************************************************
HH_0030  DS   0H
         ST    R14,HH_REG              Save return register
*
         L     R1,W_SEND               Load SEND count
         CVD   R1,W_PDWA               Convert to packed decimal
         UNPK  M_ROWS,W_PDWA           Unpack READ count
         OI    M_ROWS+3,X'F0'          Set sign bits
*
         EXEC CICS WEB WRITE                                           X
               HTTPHEADER (H_ROWS)                                     X
               NAMELENGTH (H_ROWS_L)                                   X
               VALUE      (M_ROWS)                                     X
               VALUELENGTH(M_ROWS_L)                                   X
               NOHANDLE
*
         L     R14,HH_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* JSON pre-key tags - begin.                                          *
* When processing the first record, include the square bracket, which *
* indicates the beginning of the array.                               *
* When processing beyond the first record, include the comma, which   *
* separates each record in the array.                                 *
***********************************************************************
RJ_0010  DS   0H
         ST    R14,RJ_REG              Save return register
*
         STM   0,15,REGSAVE            Save all registers
*
         L     R4,RA_PTR               Load response array pointer
         CLC   W_SEND,ONE              First record?
         BC    B'0100',RJ_0012         ... yes, insert a left bracket
***********************************************************************
* Insert comma, which separates each record in the array.             *
***********************************************************************
RJ_0011  DS   0H
         MVI   0(R4),C','              Insert a comma
         LA    R4,1(0,R4)              Bump RA
         BC    B'1111',RJ_0013         Continue with Primary key
***********************************************************************
* Insert left square bracket to indicate beginning of the array.      *
***********************************************************************
RJ_0012  DS   0H
         MVI   0(R4),X'BA'             Move left square bracket
         LA    R4,1(0,R4)              Bump RA
***********************************************************************
* Create Primary key JSON tag.                                        *
***********************************************************************
RJ_0013  DS   0H
         MVI   0(R4),C'{'              Move JSON bracket
         MVI   1(R4),C'"'              Move double quote
         LA    R4,2(0,R4)              Bump RA
*
         LA    R6,O_P_NAME             Load Primary name address
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
         CLI   O_P_TYPE,C'N'           Numeric field?
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
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20402 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20403 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20404 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20405 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20406 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'06'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20407 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'07'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(204)                                                         *
***********************************************************************
ER_20408 DS   0H
         MVC   C_STATUS,S_204          Set STATUS
         MVC   C_REASON,=C'08'         Set REASON
         MVC   C_FILE,EIBDS            Set FCT name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(412)                                                         *
***********************************************************************
ER_41201 DS   0H
         MVC   C_STATUS,S_412          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(412)                                                         *
***********************************************************************
ER_41202 DS   0H
         MVC   C_STATUS,S_412          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50701 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50702 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50703 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50704 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50705 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
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
S_412    DC    CL03'412'               HTTP STATUS(412)
         DS   0F
S_507    DC    CL03'507'               HTTP STATUS(507)
         DS   0F
ONE      DC    F'1'                    One
TWO      DC    F'2'                    Two
S_CYCLES DC    F'100'                  I/O cycles in a 'lap'
MAX_CI   DC    F'256'                  Maximum CI data length
S_OT_LEN DC    F'80'                   OPTIONS  table maximum length
S_PA_LEN DC    F'8192'                 Parser   Array maximum length
S_FD_LEN DC    F'65000'                Field Define   maximum length
S_RA_LEN DC    F'3200000'              Response Array maximum length
         DS   0F
S_DF_LEN DC    H'32700'                FAxxFILE       maximum length
         DS   0F
S_32K    DC    F'32000'                Maximum segment length
         DS   0F
S_GM_Max DC    F'1000255'              GETMAIN max    buffer size
         DS   0F
PD_ZERO  DC    XL02'000F'              Packed decimal zeroes
PD_ONE   DC    XL02'001F'              Packed decimal zeroes
PD_NINES DC    XL02'999F'              Packed decimal nines
PD_56    DC    XL04'0000056F'          Packed decimal  56
PD_256   DC    XL04'0000256F'          Packed decimal 256
ZD_ONE   DC    CL04'0001'              Zoned  decimal 0001
ZD_ZERO  DC    CL06'000000'            Zoned  decimal 000000
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
H_500_T  DC    CL16'03 Service unava'  HTTP STATUS TEXT Message
         DC    CL16'ilable and loggi'  ... continued
         DC    CL16'ng disabled     '  ... and complete
         DS   0F
H_200    DC    H'200'                  HTTP STATUS(200)
H_200_L  DC    F'32'                   HTTP STATUS TEXT Length
H_200_T  DC    CL16'00 Request succe'  HTTP STATUS TEXT Message
         DC    CL16'ssful.          '  ... continued
*
         DS   0F
H_206    DC    H'206'                  HTTP STATUS(206)
H_206_L  DC    F'64'                   HTTP STATUS TEXT Length
H_206_T  DC    CL16'206 01-022 Respo'  HTTP STATUS TEXT Message
         DC    CL16'nse requested ex'  ... continued
         DC    CL16'ceeds maximum 1m'  ... and more
         DC    CL16'b buffer        '  ... and complete
*
         DS   0F
H_ACTION DC    F'02'                   HTTP SEND ACTION(IMMEDIATE)
H_MEDIA  DC    CL56'text/plain'        HTTP Media type
         DS   0F
M_ROWS_L DC    F'04'                   HTTP Header message length
H_ROWS_L DC    F'09'                   HTTP Header length
H_ROWS   DC    CL09'zFAM-Rows'         HTTP Header
         DS   0F
M_HEAD_L DC    F'09'                   HTTP Header message length
M_HEAD   DC    CL09'zFAM-Rows'         HTTP Header message
H_HEAD_L DC    F'07'                   HTTP Header length
H_HEAD   DC    CL07'Trailer'           HTTP Header
         DS   0F
T_HEADER DC    CL02'TE'                HTTP header (TE)
T_LENGTH EQU   *-T_HEADER              HTTP header field length
         DS   0F
TRAILERS DC    CL08'TRAILERS'          HTTP header (TE)
         DS   0F
***********************************************************************
* Trace resources                                                     *
***********************************************************************
T_46     DC    H'46'                   Trace number
T_46_M   DC    CL08'Build RA'          Trace message
T_RES    DC    CL08'zFAM022 '          Trace resource
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
* End of Program - ZFAM022                                            *
**********************************************************************
         END   ZFAM022