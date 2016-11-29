*ASM XOPTS(CICS SP)
*
*  PROGRAM:    ZFAM010
*  AUTHOR:     Rich Jackson and Randy Frerking
*  COMMENTS:   zFAM - z/OS File Access Manager
*
*              This program is executed as the Query Mode POST service
*              and is called by the ZFAM001 control program.
*
***********************************************************************
* Start Dynamic Storage Area                                          *
***********************************************************************
DFHEISTG DSECT
REGSAVE  DS    16F                Register Save Area
BAS_REG  DS    F                  BAS return register
PK_REG   DS    F                  BAS return register PK_0010
PL_REG   DS    F                  BAS return register PL_0010
HH_REG   DS    F                  BAS return register HH_0010
FK_REG   DS    F                  BAS return register FK_0010
FF_REG   DS    F                  BAS return register FF_0010
CI_REG   DS    F                  BAS return register CI_0010
TR_REG   DS    F                  BAS return register TR_0010
APPLID   DS    CL08               CICS Applid
SYSID    DS    CL04               CICS SYSID
USERID   DS    CL08               CICS USERID
PA_ADDR  DS    F                  Parser   Array address
PA_LEN   DS    F                  Parser   Array length
FK_ADDR  DS    F                  zFAM Key  record address
FK_LEN   DS    F                  zFAM Key  record length
FF_ADDR  DS    F                  zFAM File record address
FF_DATA  DS    F                  zFAM File data   address
FF_LEN   DS    F                  zFAM File record length
LR_ADDR  DS    F                  zFAM File logical record  address
LR_LEN   DS    F                  zFAM File logical record  length
LS_ADDR  DS    F                  zFAM File logical segment address
LS_LEN   DS    F                  zFAM File logical segment length
FD_ADDR  DS    F                  FAxxFD document address
FD_LEN   DS    F                  FAxxFD document length
FC_ADDR  DS    F                  Field container address
FC_LEN   DS    F                  Field container length
PK_ADDR  DS    F                  Primary Key     address
PK_LEN   DS    F                  Primary Key     length
PK_RESP  DS    F                  Primary Key     EIBRESP
TL_ADDR  DS    F                  Time to Live    address
TL_LEN   DS    F                  Time to Live    length
MT_ADDR  DS    F                  Media type      address
MT_LEN   DS    F                  Media type      length
         DS   0F
PK_BITS  DS    CL01               Primary Key decision bits
         DS   0F
W_SEGS   DS    H                  Number of segments
         DS   0F
W_LENGTH DS    CL08               Packed decimal field length
W_COLUMN DS    CL08               Packed decimal field column
W_RECORD DS    CL08               Packed decimal record length
         DS   0F
C_NAME   DS    CL16               Field Name     (container name)
C_LENGTH DS    F                  Field Length   (container data)
C_RESP   DS    F                  Container response
         DS   0F
G_LENGTH DS    F                  GETMAIN length
         DS   0F
W_PRI_ID DS    CL01               Primary column ID flag
         DS   0F
W_TTL    DS    CL05               Time To Live - Zone Decimal format
*
***********************************************************************
* READ HTTPHEADER fields - Common                                     *
***********************************************************************
         DS   0F
L_HEADER DS    F                  HTTP header length
V_LENGTH DS    F                  HTTP header value length
*
***********************************************************************
* READ HTTPHEADER fields - Concat                                     *
***********************************************************************
         DS   0F
A_RESP   DS    F                  HTTP header response
A_VALUE  DS    CL03               HTTP header value
A_VAL_L  EQU   *-A_VALUE          HTTP header value field length
***********************************************************************
* READ HTTPHEADER fields - zFAM-UID                                   *
***********************************************************************
         DS   0F
B_RESP   DS    F                  HTTP header response
B_VALUE  DS    CL03               HTTP header value
B_VAL_L  EQU   *-B_VALUE          HTTP header value field length
***********************************************************************
* zFAM090 communication area                                          *
* Logging for ZFAM010 exceptional conditions                          *
***********************************************************************
C_LOG    DS   0F
C_STATUS DS    CL03               HTTP Status code
C_REASON DS    CL02               Reason Code
C_USERID DS    CL08               UserID
C_PROG   DS    CL08               Service program name
C_FILE   DS    CL08               zFAM file  name
C_FIELD  DS    CL16               zFAM field name
E_LOG    EQU   *-C_LOG            Commarea Data length
L_LOG    DS    H                  Commarea length
*
***********************************************************************
* zUID001 communication area                                          *
* Create zUID for primary or composite key.                           *
***********************************************************************
Z_001    DS   0F
Z_TYPE   DS    CL04               Type 'LINK'
Z_STATUS DS    CL03               Status code
         DS    CL01               Not used
Z_REASON DS    CL02               Reason code
         DS    CL02               Not used
Z_PGMID  DS    CL03               zUID program ID
         DS    CL01               Not used
Z_FORMAT DS    CL05               Format 'PLAIN'
         DS    CL03               Not used
Z_REG    DS    CL06               zUID registration type
         DS    CL02               Not used
Z_UID    DS    CL36               zUID
         DS    CL92               Not used
E_001    EQU   *-Z_001            Commarea Data length
L_001    DS    H                  Commarea length
*
***********************************************************************
* zFAM key  store   resources                                         *
***********************************************************************
WK_FCT   DS   0F                  zFAM Key  structure FCT name
WK_TRAN  DS    CL04               zFAM transaction ID
WK_DD    DS    CL04               zFAM KEY  DD name
*
WK_KL    DS    F                  zFAM KEY  keylength
*
WK_LEN   DS    H                  zFAM Key  structure length
*
***********************************************************************
* zFAM data store   resources                                         *
***********************************************************************
WF_FCT   DS   0F                  zFAM File structure FCT name
WF_TRAN  DS    CL04               zFAM transaction ID
WF_DD    DS    CL04               zFAM FILE DD name
*
WF_LEN   DS    H                  zFAM File structure length
*
***********************************************************************
* zFAM column index resources                                         *
***********************************************************************
CI_FCT   DS   0F                  zFAM Column Index   FCT name
CI_TRAN  DS    CL04               zFAM transaction ID
CI_DD    DS    CL04               zFAM CI   DD name
*
         DS   0F
CI_F_LEN DS    F                  zFAM CI field/key length
*
CI_LEN   DS    H                  zFAM Column Index   length
CI_ID    DS    CL03               Column Index (zone   decimal)
         DS   0H
W_ID     DS    CL02               Column Index (packed decimal)
*
***********************************************************************
* Primary Index information                                           *
***********************************************************************
         DS   0F
PI_TYPE  DS    CL01               Actual key type
         DS   0F
PI_COL   DS    CL07               Actual key column
         DS   0F
PI_LEN   DS    CL06               Actual key lenth
***********************************************************************
* Last column and length fields from FAxxFD to calculate GETMAIN.     *
***********************************************************************
         DS   0F
W_COL    DS    CL07               Last column from FAxxFD template
         DS   0F
W_LEN    DS    CL06               Last length from FAxxFD template
***********************************************************************
* zFAM KEY  store record buffer                                       *
***********************************************************************
         COPY ZFAMFKA
*
***********************************************************************
* zFAM CI   store record buffer                                       *
***********************************************************************
         COPY ZFAMCIA
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
* Named Counter fields                                                *
***********************************************************************
         DS   0F
W_NC     DS   0CL16               Named counter ID
W_NC_T   DS    CL04               Named counter transacstion ID
W_NC_S   DS    CL12               Named counter suffix
W_VALUE  DS    F                  Named counter value
*
***********************************************************************
* Absolute time fields                                                *
***********************************************************************
         DS   0F
W_TOD    DS    CL16               STCKE TOD absolute time
W_ABS    DS    CL08               Absolute time
*
***********************************************************************
* Media type                                                          *
***********************************************************************
         DS   0F
W_MEDIA  DS    CL56               Media type
*
***********************************************************************
* Trace entry                                                         *
***********************************************************************
         DS   0F
W_46_M   DS    CL08               Trace entry paragraph
*
***********************************************************************
* Document template fields                                            *
***********************************************************************
         DS   0F
DD_INFO  DS   0F                  DD Document information
DD_NAME  DS    CL04               DD name
DD_CRLF  DS    CL02
*
         DS   0F
DD_LEN   DS    F                  DD length
DD_RESP  DS    F                  Document EIBRESP
DD_TOKEN DS    CL16               FAxxFILE DDNAME document
DD_DOCT  DS   0CL48
DD_TRAN  DS    CL04               DD tranid
DD_TYPE  DS    CL02               DD type
DD_SPACE DS    CL42               DD spaces
*
***********************************************************************
* Primary key, zUID or Composite (Primary+zUID concatenation)         *
***********************************************************************
         DS   0F
ZI_ADDR  DS    F                  zQL INSERT Primary Key address
ZI_LEN   DS    F                  zQL INSERT Primary Key length
ZI_KEY   DS    CL255              zQL INSERT Primary Key
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
DC_RESP  DS    F                  DC response
DC_LEN   DS    F                  DC document length
DC_TOKEN DS    CL16               DC document token
DC_DOCT  DS   0CL48
DC_TRAN  DS    CL04               DC EIBTRNID
DC_TYPE  DS    CL02               DC Type
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
* Start FAxxFD DOCTEMPLATE buffer (Field Definitions)                 *
***********************************************************************
*
FD_DSECT DSECT
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
E_FD     EQU   *-FD_DSECT         Field Definition entry length
***********************************************************************
* End   FAxxSD DOCTEMPLATE buffer                                     *
***********************************************************************
*
***********************************************************************
* Start Field Container buffer                                        *
***********************************************************************
FC_DSECT DSECT
*
*
***********************************************************************
* End   Field Container buffer                                        *
***********************************************************************
*
*
***********************************************************************
* zFAM FILE store record buffer                                       *
***********************************************************************
         COPY ZFAMDFA
*
***********************************************************************
* Start Logical record buffer                                         *
***********************************************************************
LR_DSECT DSECT
*
***********************************************************************
* End   Logical record buffer                                         *
***********************************************************************
*
*
***********************************************************************
***********************************************************************
* Control Section - ZFAM010                                           *
***********************************************************************
***********************************************************************
ZFAM010  DFHEIENT CODEREG=(R2,R3),DATAREG=R11,EIBREG=R12
ZFAM010  AMODE 31
ZFAM010  RMODE 31
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'ZFAM010 '
         DC    CL48' -- Query Mode INSERT service                   '
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
         ST    R1,PA_ADDR              Save parser array address
         MVC   PA_LEN,C_LENGTH         Move parser array length
***********************************************************************
* Issue GET CONTAINER for Primary Key container                       *
***********************************************************************
SY_0010  DS   0H
         MVC   C_NAME,C_KEY            Move Primary Key container
         MVC   C_LENGTH,S_255          Move Primary Key length
         BAS   R14,GC_0010             Issue GET CONTAINER
         ST    R1,PK_ADDR              Save Primary key address
         MVC   PK_LEN,C_LENGTH         Move Primary key length
         MVC   PK_RESP,C_RESP          Move Primary key EIBRESP
***********************************************************************
* Issue GET CONTAINER for FAxxFD document template                    *
***********************************************************************
SY_0020  DS   0H
         MVC   C_NAME,C_FAXXFD         Move FAXXFD container name
         MVC   C_LENGTH,S_FD_LEN       Move FAXXFD container length
         BAS   R14,GC_0010             Issue GET CONTAINER
         ST    R1,FD_ADDR              Save FAXXFD address
         MVC   FD_LEN,C_LENGTH         Move FAXXFD length
*
         L     R4,FD_LEN               Load FAXXFD length
         L     R5,FD_ADDR              Load FAXXFD address
         LA    R6,E_FD                 Load FAXXFD entry length
         USING FD_DSECT,R5             ... tell assembler
***********************************************************************
* Scan FAXXFD for primary key                                         *
***********************************************************************
SY_0030  DS   0H
         CLC   F_ID,ZD_ONE             Primary key?
         BC    B'0111',SY_0040         ... no,  get next FD entry
         MVC   PI_TYPE,F_TYPE          Move field type
         MVC   PI_COL,F_COL            Move field column
         MVC   PI_LEN,F_LEN            Move field length
***********************************************************************
* Save last column and field length when EOFD                         *
***********************************************************************
SY_0040  DS   0H
         LA    R5,0(R6,R5)             Point to next FD entry
         SR    R4,R6                   Reduce by an  FD entry length
         BC    B'0010',SY_0030         Continue FD scan
         SR    R5,R6                   Point to last entry
         MVC   W_COL,F_COL             Move field column
         MVC   W_LEN,F_LEN             Move field length
***********************************************************************
* Calculate logical record size and issue GETMAIN.                    *
* Also GETMAIN for header and single physical segment.                *
***********************************************************************
SY_0050  DS   0H
         PACK  W_COLUMN,W_COL          Pack field column
         PACK  W_LENGTH,W_LEN          Pack field length
         ZAP   W_RECORD,W_COLUMN       Add column to record length
         AP    W_RECORD,W_LENGTH       Add length to record length
         CVB   R1,W_RECORD             Convert to binary
         BCTR  R1,0                    Subtract one
         ST    R1,G_LENGTH             Store GETMAIN length
         BAS   R14,GM_0010             Issue GETMAIN
         ST    R1,LR_ADDR              Save  GETMAIN address
         MVC   LR_LEN,G_LENGTH         Save  GETMAIN length
*
         XR    R4,R4                   Clear R4
         L     R5,G_LENGTH             Load  GETMAIN length
         D     R4,S_32K                Divide by segment size
         A     R5,=F'1'                Set segments relative to 1
         STH   R5,W_SEGS               Save segment number
*
         L     R1,S_32K                Load segment size
         LA    R15,DF_E                Load zFAM file header length
         LA    R1,0(R15,R1)            Add header length to record
         ST    R1,G_LENGTH             Store GETMAIN length
         BAS   R14,GM_0010             Issue GETMAIN
         USING DF_DSECT,R1             ... tell assembler
         ST    R1,FF_ADDR              Save  GETMAIN address
         MVC   FF_LEN,G_LENGTH         Save  GETMAIN length
         LA    R1,DF_DATA              Load  data address
         ST    R1,FF_DATA              Save  data address
         DROP  R1                      ... tell assembler
*
***********************************************************************
* Issue GET CONTAINER for OPTIONS table.                              *
***********************************************************************
SY_0060  DS   0H
         MVC   C_NAME,C_OPTION         Move OPTIONS table container
         MVC   C_LENGTH,S_OT_LEN       Move OPTIONS table length
         BAS   R14,GC_0020             Issue GET CONTAINER
*
***********************************************************************
* Determine Primary Index field type and branch accordingly.          *
***********************************************************************
SY_0070  DS   0H
         BAS   R14,HH_0010             READ HTTPHEADER
*                                      ...  zFAM-Concat
*                                      ...  zFAM-UID
*
         BAS   R14,PK_0010             Process Primary Key
*
         OI    PI_TYPE,X'40'           Set upper case bit
         CLI   PI_TYPE,C'C'            Character?
         BC    B'1000',SY_0080         ... yes, set key character
         BC    B'1111',SY_0090         ... no,  set key numeric
***********************************************************************
* Set key as character.                                               *
***********************************************************************
SY_0080  DS   0H
         PACK  W_LENGTH,PI_LEN         Move PI length to work area
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
         L     R1,ZI_LEN               Load primary key length
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,WK_KEY              Load FAxxKEY key address
         L     R15,ZI_ADDR             Load primary key address
         EX    R1,MVC_0081             Execute MVC instruction
*
         PACK  W_LENGTH,PI_LEN         Move PI length to work area
         CVB   R1,W_LENGTH             Convert to binary
         S     R1,=F'1'                Subtract one for EX MVC
         L     R14,LR_ADDR             Load locial record address
         LA    R15,WK_KEY              Load primary  key  address
         EX    R1,MVC_0081             Execute MVC instruction
*
         BC    B'1111',SY_0100         WRITE FAxxKEY
MVC_0080 MVC   0(0,R14),0(R15)         Initial with spaces
MVC_0081 MVC   0(0,R14),0(R15)         Move PI to key
***********************************************************************
* Set key as numeric.                                                 *
***********************************************************************
SY_0090  DS   0H
         PACK  W_LENGTH,PI_LEN         Move PA length to work area
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
         L     R1,ZI_LEN               Load primary key length
         SR    R6,R1                   Subtract PI from maximum
*
         S     R1,=F'1'                Subtract one for EX MVC
         LA    R14,WK_KEY              Load FAxxKEY key address
         LA    R14,0(R6,R14)           Adjust for field length
         L     R15,ZI_ADDR             Load primary key address
         EX    R1,MVC_0091             Execute MVC instruction
*
         PACK  W_LENGTH,PI_LEN         Move PI length to work area
         CVB   R1,W_LENGTH             Convert to binary
         S     R1,=F'1'                Subtract one for EX MVC
         L     R14,LR_ADDR             Load locial record address
         LA    R15,WK_KEY              Load primary key address
         EX    R1,MVC_0091             Execute MVC instruction
*
         BC    B'1111',SY_0100         WRITE FAxxKEY
MVC_0090 MVC   0(0,R14),0(R15)         Initial with zeroes
MVC_0091 MVC   0(0,R14),0(R15)         Move PI to key
***********************************************************************
* Issue WRITE for FAxxKEY  using Primary Column Index                 *
***********************************************************************
SY_0100  DS   0H
         LA    R1,E_WK                 Load KEY  record length
         STH   R1,WK_LEN               Save KEY  record length
         BAS   R14,FK_0010             Issue WRITE for KEY  structure
         CLC   EIBRESP,=F'14'          Duplicate record?
         BC    B'1000',ER_40901        ... yes, STATUS(409)
         CLC   EIBRESP,=F'84'          File disabled?
         BC    B'1000',ER_50701        ... yes, STATUS(507)
         CLC   EIBRESP,=F'12'          File not found?
         BC    B'1000',ER_50702        ... yes, STATUS(507)
         CLC   EIBRESP,=F'18'          NOSPACE condition?
         BC    B'1000',ER_50703        ... yes, STATUS(507)
         CLC   EIBRESP,=F'19'          NOTOPEN condition?
         BC    B'1000',ER_50704        ... yes, STATUS(507)
         OC    EIBRESP,EIBRESP         Normal condition?
         BC    B'0111',ER_50705        ... no,  STATUS(507)
***********************************************************************
* Prepare to scan parser array for field definitions                  *
***********************************************************************
SY_0140  DS   0H
         DROP  R5                      ... tell assembler
*
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
         BC    B'1111',SY_0170         ... no,  check field type
***********************************************************************
* Adjust Parser Array address and length                              *
***********************************************************************
SY_0160  DS   0H
         LA    R1,E_PA                 Load parser array entry length
         LA    R9,0(R1,R9)             Point to next PA entry
         SR    R8,R1                   Subtract PA entry length
         BC    B'0011',SY_0150         Continue when more entries
         BC    B'1111',SY_0250         Prepare to write FAxxFILE
***********************************************************************
* Check field type and branch accordingly.                            *
***********************************************************************
SY_0170  DS   0H
         MVC   W_ID,P_ID               Save column ID for later
         MVC   P_ID,PD_NINES           Mark field as processed
*
         MVC   C_NAME,P_NAME           Move container name
         MVC   C_LENGTH,P_LEN          Move field length
         BAS   R14,GC_0010             Issue GET CONTAINER for field
         ST    R1,FC_ADDR              Save field data address
         MVC   FC_LEN,C_LENGTH         Move field data length
*
         CLI   P_TYPE,C'C'             Character field?
         BC    B'1000',SY_0180         ... yes, pad with spaces
         CLI   P_TYPE,C'N'             Numeric   field?
         BC    B'1000',SY_0190         ... yes, pad with zeroes
         BC    B'1111',ER_41201        Invalid field type
*
***********************************************************************
* Process alphameric field by initializing with spaces, then move the *
* zQL presented field to the virtual record.                          *
***********************************************************************
SY_0180  DS   0H
         STM   0,15,REGSAVE            Save registers
*
         ZAP   W_LENGTH,P_LEN          Move field length to work area
         CVB   R7,W_LENGTH             Set target length
         ZAP   W_COLUMN,P_COL          Move field column to work area
         CVB   R1,W_COLUMN             Set target displacement
         S     R1,ONE                  Set target relative to zero
         L     R6,LR_ADDR              Set target address
         LA    R6,0(R1,R6)             Add column displacement
         LA    R5,1                    Set source length
         ICM   R5,B'1000',HEX_40       Set pad byte
         LA    R4,HEX_40               Set source address
         MVCL  R6,R4                   Move zeroes to field
*
         L     R7,FC_LEN               Load target data length
         CVB   R1,W_COLUMN             Set target displacement
         S     R1,ONE                  Set target relative to zero
         L     R6,LR_ADDR              Set target address
         LA    R6,0(R1,R6)             Add column displacement
         L     R5,FC_LEN               Load source length
         L     R4,FC_ADDR              Load source address
         MVCL  R6,R4                   Move source to target
*
         CLC   W_ID,PD_ONE             Secondary column index?
         BC    B'1100',SY_0185         ... no,  continue process
*
         XC    CI_KEY,CI_KEY           Set  secondary CI key to nulls
         CVB   R5,W_LENGTH             Set  source data length
         CVB   R1,W_COLUMN             Set  source displacement
         S     R1,ONE                  Set  source relative to zero
         L     R4,LR_ADDR              Set  source address
         LA    R4,0(R1,R4)             Add  column displacement
         LR    R7,R5                   Load target data length
         ST    R5,CI_F_LEN             Save target data length
         LA    R6,CI_KEY               Load target data address
         MVCL  R6,R4                   Move source to target
         BAS   R14,CI_0010             WRITE FAxxCIxx file
***********************************************************************
* Process alphameric field complete.                                  *
***********************************************************************
SY_0185  DS   0H
         LM    0,15,REGSAVE            Load registers
         BC    B'1111',SY_0140         Continue Parser Array process
*
***********************************************************************
* Process numeric field by initializing with zeroes, then move the    *
* zQL presented field to the virtual record.                          *
***********************************************************************
SY_0190  DS   0H
         STM   0,15,REGSAVE            Save registers
*
         ZAP   W_LENGTH,P_LEN          Move field length to work area
         CVB   R7,W_LENGTH             Set target length
         ZAP   W_COLUMN,P_COL          Move field column to work area
         CVB   R1,W_COLUMN             Set target displacement
         S     R1,ONE                  Set target relative to zero
         L     R6,LR_ADDR              Set target address
         LA    R6,0(R1,R6)             Add column displacement
         LA    R5,1                    Set source length
         ICM   R5,B'1000',ZD_ZERO      Set pad byte
         LA    R4,ZD_ZERO              Set source address
         MVCL  R6,R4                   Move zeroes to field
*
         L     R7,FC_LEN               Load target data length
         CVB   R1,W_COLUMN             Set target displacement
         S     R1,ONE                  Set target relative to zero
         L     R6,LR_ADDR              Set target address
         LA    R6,0(R1,R6)             Add column displacement
*
         ZAP   W_LENGTH,P_LEN          Move field length to work area
         CVB   R1,W_LENGTH             Convert to binary
         SR    R1,R7                   Subtract data length
         LA    R6,0(R1,R6)             Right justify numeric field
*
         L     R5,FC_LEN               Load source length
         L     R4,FC_ADDR              Load source address
         MVCL  R6,R4                   Move source to target
*
         CLC   W_ID,PD_ONE             Secondary column index?
         BC    B'1100',SY_0195         ... no,  continue process
*
         XC    CI_KEY,CI_KEY           Set  secondary CI key to nulls
         CVB   R5,W_LENGTH             Set  source data length
         CVB   R1,W_COLUMN             Set  source displacement
         S     R1,ONE                  Set  source relative to zero
         L     R4,LR_ADDR              Set  source address
         LA    R4,0(R1,R4)             Add  column displacement
         LR    R7,R5                   Load target data length
         ST    R5,CI_F_LEN             Save target data length
         LA    R6,CI_KEY               Load target data address
         MVCL  R6,R4                   Move source to target
         BAS   R14,CI_0010             WRITE FAxxCIxx file
***********************************************************************
* Process numeric field complete.                                     *
***********************************************************************
SY_0195  DS   0H
         LM    0,15,REGSAVE            Load registers
         BC    B'1111',SY_0140         Continue Parser Array process
***********************************************************************
* Prepare to write FAxxFILE, which can span multiple segments.        *
***********************************************************************
SY_0250  DS   0H
         MVC   LS_LEN,LR_LEN           Move LR length  to LS length
         MVC   LS_ADDR,LR_ADDR         Move LR address to LS address
         L     R4,LR_ADDR              Load logical record address
         L     R8,FF_DATA              Load segment record address
***********************************************************************
* Set segment length using logical segment length                     *
***********************************************************************
SY_0260  DS   0H
         L     R5,S_32K                Load maximum segment length
         CLC   LS_LEN,S_32K            LS length greater than 32K?
         BC    B'0010',SY_0270         ... yes, continue
         L     R5,LS_LEN               ... no,  use remaining LS length
         XC    LS_LEN,LS_LEN           Clear the remaining LS length
***********************************************************************
* Move logical record to segment.                                     *
***********************************************************************
SY_0270  DS   0H
         LA    R1,DF_E                 Load FAxxFILE header length
         AR    R1,R5                   Load current segment length
         STH   R1,WF_LEN               Save record/segment length
*
         LR    R9,R5                   Load source length
         MVCL  R8,R4                   Move logical segment
*
         BAS   R14,FF_0010             Issue WRITE for FILE structure
*
         CLC   EIBRESP,=F'14'          Duplicate record?
         BC    B'1000',ER_40902        ... yes, STATUS(409)
         CLC   EIBRESP,=F'84'          File disabled?
         BC    B'1000',ER_50701        ... yes, STATUS(507)
         CLC   EIBRESP,=F'12'          File not found?
         BC    B'1000',ER_50702        ... yes, STATUS(507)
         CLC   EIBRESP,=F'18'          NOSPACE condition?
         BC    B'1000',ER_50703        ... yes, STATUS(507)
         CLC   EIBRESP,=F'19'          NOTOPEN condition?
         BC    B'1000',ER_50704        ... yes, STATUS(507)
         OC    EIBRESP,EIBRESP         Normal condition?
         BC    B'0111',ER_50705        ... no,  STATUS(507)
*
         CLC   LS_LEN,S_32K            LS length greater than 32K?
         BC    B'1100',SY_0300         ... no,  WRITE complete
*
         L     R1,LS_LEN               Load logical segment length
         S     R1,S_32K                Subtract a segment length
         ST    R1,LS_LEN               Save logical segment length
*
         L     R4,LS_ADDR              Load logical segment address
         A     R4,S_32K                Increment by a segment length
         ST    R4,LS_ADDR              Save logical segment address
         L     R8,FF_DATA              Load segment record address
*
         BC    B'1111',SY_0260         Continue writing segments
*
***********************************************************************
* Send response                                                       *
***********************************************************************
SY_0300  DS   0H
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
***********************************************************************
* Issue GETMAIN.                                                      *
***********************************************************************
GM_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS GETMAIN                                             X
               SET(R1)                                                 X
               FLENGTH(G_LENGTH)                                       X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue WRITE for FAxxKEY structure                                   *
***********************************************************************
FK_0010  DS   0H
         ST    R14,FK_REG              Save return register
         MVC   WK_FCT(08),SK_FCT       Move KEY  structure name
         MVC   WK_TRAN,EIBTRNID        Move KEY  structure ID
***********************************************************************
* Inquire on FCT name to get FAxxKEY  keylength                       *
***********************************************************************
FK_0020  DS   0H
         EXEC CICS INQUIRE FILE(WK_FCT)                                X
               KEYLENGTH(WK_KL)                                        X
               NOHANDLE
*
***********************************************************************
* Issue GET COUNTER for internal FAxxFILE key.                        *
***********************************************************************
FK_0030  DS   0H
         MVC   W_NC_T,EIBTRNID         Move to NC name
         MVC   W_NC_S,C_SUFFIX         Move to NC name
*
         EXEC CICS GET COUNTER(W_NC)                                   X
               VALUE(W_VALUE)                                          X
               NOHANDLE
*
         L     R1,W_VALUE              Load counter value
         STH   R1,WK_F_NC              Save counter value
*
***********************************************************************
* Issue STCKE for TOD absolute time, then use as the ID Number.       *
* Note:  ID number is a portion of absolute time that will roll over  *
*        to zeroes sometime in the year 34,000, which then gives us   *
*        approximately 114 years before the chance of a duplicate.    *
*        The six byte TOD has a resolution to the microsecond.        *
*        With the named counter appended to the TOD, the internal key *
*        can handle 65,535 requests per microsecond, making this a    *
*        very robust algorithm without the potential for a duplicate. *
*        I'm sure the MainFrame will still be running our core        *
*        business worldwide during this time, however I figure the    *
*        Unix/Linux world will have been obsolete several millenium.  *
***********************************************************************
FK_0040  DS   0H
         EXEC CICS ASKTIME ABSTIME(W_ABS)                              X
               NOHANDLE
         STCKE W_TOD                   Get TOD absolute time
         MVC   WK_F_IDN,W_TOD          Move ID number
*
***********************************************************************
* Get FAxxFILE DDNAME, as there are multiple Data Stores per table.   *
***********************************************************************
FK_0050  DS   0H
         MVC   DD_LEN,=F'6'            Set DDNAME document length
         MVC   DD_TRAN,EIBTRNID        Set Document Template name
         MVC   DD_TYPE,=C'DD'          Set Document Template name
         MVI   DD_SPACE,X'40'          Set first byte
         MVC   DD_SPACE+1(41),DD_SPACE Set remainder of bytes
*
         EXEC CICS DOCUMENT CREATE DOCTOKEN(DD_TOKEN)                  X
               TEMPLATE(DD_DOCT)                                       X
               RESP    (DD_RESP)                                       X
               NOHANDLE
*
         EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(DD_TOKEN)                X
               INTO      (DD_INFO)                                     X
               LENGTH    (DD_LEN)                                      X
               MAXLENGTH (DD_LEN)                                      X
               DATAONLY                                                X
               NOHANDLE
*
         MVC   WK_F_DD,S_FILE          Move default Data Store DDNAME
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',FK_0060         ... no,  use default DDNAME
         MVC   WK_F_DD,DD_NAME         Move FILE DDNAME
*
***********************************************************************
* Issue GET CONTAINER for Media type                                  *
***********************************************************************
FK_0060  DS   0H
         MVC   C_NAME,C_MEDIA          Move MEDIA container name
         MVC   C_LENGTH,S_56           Move MEDIA container length
         BAS   R14,GC_0010             Issue GET CONTAINER
*
         ST    R1,MT_ADDR              Save media type address
         MVC   MT_LEN,C_LENGTH         Save media type length
         MVC   W_MEDIA,0(R1)           Move media type to work area
*
         LA    R14,W_MEDIA             Load media type address
         LA    R15,56                  Load media type length
***********************************************************************
* Replace nulls with spaces in Media Type.                            *
***********************************************************************
FK_0070  DS   0H
         CLI   0(R14),X'00'            Null?
         BC    B'0111',*+8             ... no,  check next byte
         MVI   0(R14),X'40'            Replace null with space
         LA    R14,1(,R14)             Point to next byte
         BCT   R15,FK_0070             Continue checking for nulls
***********************************************************************
* Issue GET CONTAINER for TTL                                         *
***********************************************************************
FK_0080  DS   0H
         MVC   W_TTL,ZD_2555           Move 2555 days to TTL (7 years)
*
         MVC   C_NAME,C_TTL            Move TTL container name
         MVC   C_LENGTH,FIVE           Move TTL container length
         BAS   R14,GC_0010             Issue GET CONTAINER
         OC    C_RESP,C_RESP           Normal response?
         BC    B'0111',FK_0090         ... no,  use default TTL
*
         ST    R1,TL_ADDR              Save TTL address
         MVC   TL_LEN,C_LENGTH         Save TTL length
         MVC   W_TTL,ZD_ZERO           Move zeroes to target TTL
*
         L     R1,C_LENGTH             Load TTL length received
         L     R15,FIVE                Load maximum TTL length
         SR    R15,R1                  Subtract to get displacement
         LA    R14,W_TTL               Point to target TTL
         LA    R14,0(R15,R14)          Load target address
         L     R15,TL_ADDR             Load source address
         BCTR  R1,0                    Subtract one for execute
         EX    R1,MVC_FK80             Move TTL to target
         BC    B'1111',FK_0090         Continue process
MVC_FK80 MVC   0(0,R14),0(R15)         Move source TTL to target
*
***********************************************************************
* Set object type as text or bits (short for Binary digITS)           *
***********************************************************************
FK_0090  DS   0H
         MVC   WK_F_OBJ,C_TEXT         Set object to text
         CLC   W_MEDIA(4),C_TEXT       Media type some form of text?
         BC    B'1000',FK_0100         ... yes, continue
         MVC   WK_F_OBJ,C_BITS         Set object to binary digits
***********************************************************************
* Issue WRITE to FAxxKEY (key store)                                  *
***********************************************************************
FK_0100  DS   0H
*
         EXEC CICS WRITE FILE(WK_FCT)                                  X
               FROM(WK_REC)                                            X
               RIDFLD (WK_KEY)                                         X
               LENGTH (WK_LEN)                                         X
               NOHANDLE
*
         L     R14,FK_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* FAxxFILE process                                                    *
* Initializse FAxxFILE fields                                         *
***********************************************************************
FF_0010  DS   0H
         ST    R14,FF_REG              Save return register
*
         L     R10,FF_ADDR             Load FAxxFILE address
         USING DF_DSECT,R10            ... tell assembler
*
         MVC   WF_FCT(08),SF_FCT       Move FILE structure name
         MVC   WF_TRAN,EIBTRNID        Move FILE structure TranID
         MVC   WF_DD,WK_F_DD           Move FILE structure DDNAME
*
         MVC   DF_IDN,WK_F_IDN         Move FILE IDN
         MVC   DF_NC,WK_F_NC           Move FILE NC
*
         LH    R1,DF_SEG               Load previous segment
         A     R1,=F'1'                Add  one to segment
         STH   R1,DF_SEG               Save current  segment
*
         MVC   DF_SEGS,W_SEGS          Move number of segments
         MVC   DF_K_KEY,WK_KEY         Sync key and data store
         MVC   DF_ABS,W_ABS            Move absolute time to buffer
         MVC   DF_MEDIA,W_MEDIA        Move media type    to buffer
***********************************************************************
* Set TTL                                                             *
***********************************************************************
FF_0020  DS   0H
         MVI   DF_TYPE,C'D'            Move D(ays) to retention type
         PACK  DF_TTL,W_TTL            Pack TTL in record buffer
*
***********************************************************************
* Issue WRITE of FAxxFILE structure.                                  *
***********************************************************************
FF_0100  DS   0H
*
         EXEC CICS WRITE FILE(WF_FCT)                                  X
               FROM   (DF_DSECT)                                       X
               RIDFLD (DF_KEY)                                         X
               LENGTH (WF_LEN)                                         X
               NOHANDLE
*
***********************************************************************
* FAxxFILE process complete.                                          *
***********************************************************************
FF_0090  DS   0H
         L     R14,FF_REG              Load return register
         BCR   B'1111',R14             Return to caller
         DROP  R10                     ... tell assembler
*
***********************************************************************
* Issue WRITE for FAxxCIxx structure                                  *
***********************************************************************
CI_0010  DS   0H
         ST    R14,CI_REG              Save return register
         MVC   CI_FCT(08),SI_FCT       Move CI   structure name
         MVC   CI_TRAN,EIBTRNID        Move CI   structure ID
         UNPK  CI_ID,W_ID              Unpack CI number
         OI    CI_ID+2,X'F0'           Set sign bits
         MVC   CI_DD+2(2),CI_ID+1      Move CI number
*
         MVC   CI_NC,WK_F_NC           Move named counter to key
         MVC   CI_IDN,WK_F_IDN         Move ID number
         MVC   CI_DS,WK_F_DD           Move FILE DDNAME
*
         LA    R1,E_CI                 Load CI record length
         STH   R1,CI_LEN               Save CI record length
*
         LA    R15,KEY_40              Load address of spaces
         LA    R14,CI_FIELD            Load address of CI key
         L     R1,CI_F_LEN             Load CI key length
         S     R1,=F'1'                Subtract one for EX instruction
         EX    R1,CLC_0010             CI Key spaces or nulls?
         BC    B'1100',CI_0011         ... yes, bypass WRITE CI
*
         EXEC CICS WRITE FILE(CI_FCT)                                  X
               FROM(CI_REC)                                            X
               RIDFLD (CI_KEY)                                         X
               LENGTH (CI_LEN)                                         X
               NOHANDLE
*
CI_0011  DS   0H
         L     R14,CI_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
CLC_0010 CLC   0(0,R14),0(R15)         Check field for spaces/nulls
KEY_40   DC    56XL01'40'              Space fields
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
* LINK to zUID001 service                                             *
***********************************************************************
PL_0010  DS   0H
         ST    R14,PL_REG              Save return register
*
         MVC   Z_TYPE,S_TYPE           Move LINK  to zUID type
         MVC   Z_FORMAT,S_FORMAT       Move PLAIN to zUID format
         LA    R1,E_001                Load COMMAREA length
         STH   R1,L_001                Save COMMAREA length
*
         EXEC CICS LINK PROGRAM(ZUID001)                               X
               COMMAREA(Z_001)                                         X
               LENGTH  (L_001)                                         X
               NOHANDLE
*
         L     R14,PL_REG              Load return register
         BCR   B'1111',R14             Return to caller
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
         ST    R14,TR_REG              Save return register
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
         L     R14,TR_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Read HTTPHEADER for zFAM-UID   (A_HEADER, A_VALUE)                  *
* and  HTTPHEADER for zFAM-Concat(B_HEADER, B_VALUE)                  *
***********************************************************************
HH_0010  DS   0H
         ST    R14,HH_REG              Save return register
         LA    R1,A_LENGTH             Load header name  length
         ST    R1,L_HEADER             Save header name  length
         LA    R1,A_VAL_L              Load value  field length
         ST    R1,V_LENGTH             Save value  field length
*
         EXEC CICS WEB READ HTTPHEADER(A_HEADER)                       X
               NAMELENGTH(L_HEADER)                                    X
               VALUE(A_VALUE)                                          X
               VALUELENGTH(V_LENGTH)                                   X
               RESP(A_RESP)                                            X
               NOHANDLE
*
         OC    A_VALUE,HEX_40          Set upper case bits
*
         LA    R1,B_LENGTH             Load header name  length
         ST    R1,L_HEADER             Save header name  length
         LA    R1,B_VAL_L              Load value  field length
         ST    R1,V_LENGTH             Save value  field length
*
         EXEC CICS WEB READ HTTPHEADER(B_HEADER)                       X
               NAMELENGTH(L_HEADER)                                    X
               VALUE(B_VALUE)                                          X
               VALUELENGTH(V_LENGTH)                                   X
               RESP(B_RESP)                                            X
               NOHANDLE
*
         OC    B_VALUE,HEX_40          Set upper case bits
*
         XC    PK_BITS,PK_BITS         Clear decision bits
*
         L     R14,HH_REG              Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* The Primary Key container is required, unless zFAM-UID is in the    *
* request header.  Here's the requirements for the Primary Key:       *
*                                                                     *
*  1). If Primary Key is omitted and zFAM-UID is not present, issue   *
*      HTTP status code 400-01.                                       *
*                                                                     *
*  2). If Primary Key is provided and zFAM-UID is present, and        *
*      zFAM-Concat is not present, issue HTTP status code 400-02,     *
*      as this combination is invalid.                                *
*                                                                     *
*  3). If Primary Key is provided and zFAM-UID is not present, and    *
*      zFAM-Concat is present, issue HTTP status code 400-03,         *
*      as this combination is invalid.                                *
*                                                                     *
*  4). If Primary Key is omitted and zFAM-UID is present, and         *
*      zFAM-Concat is present, issue HTTP status code 400-04,         *
*      as this combination is invalid.                                *
*                                                                     *
*  5). If Primary Key and zUID concatenation length exceeds FAxxFD    *
*      definition, issue an HTTP status code 400-05.                  *
*                                                                     *
*  6). If Primary Key length exceeds FAxxFD definition, issue an      *
*      HTTP status code 400-06.                                       *
*                                                                     *
*  7). If zUID exceeds FAxxFD for Primary Key length, issue an        *
*      HTTP status code 400-07.                                       *
*                                                                     *
*  8). If Primary Key is provided and zFAM-UID is present, and        *
*      zFAM-Concat is present, Primary Key and zUID are concatentated *
*      to create a composite key.                                     *
*                                                                     *
*  9). If Primary Key is omitted  and zFAM-UID is present, and        *
*      zFAM-Concat is not present, then zUID as Primary Key.          *
*                                                                     *
* 10). If Primary Key is provided and zFAM-UID is not present, and    *
*      zFAM-Concat is not present, then just use the Primary Key.     *
*                                                                     *
***********************************************************************
*                                                                     *
* Set Primary Key decision bits.                                      *
*                                                                     *
* 1000 0000   Primary Key present                                     *
* 0100 0000   zFAM-UID: Yes requested                                 *
* 0010 0000   zFAM-Concat: Yes requested                              *
* 0000 0000   Not used currently                                      *
*                                                                     *
***********************************************************************
PK_0010  DS   0H
         ST    R14,PK_REG              Save return register
         OC    PK_RESP,PK_RESP         Primary Key provided?
         BC    B'0111',*+8             ... no,  continue
         OI    PK_BITS,B'10000000'     ... yes, set flag
*
         CLC   A_VALUE,YES             zFAM-UID: Yes requested?
         BC    B'0111',*+8             ... no,  continue
         OI    PK_BITS,B'01000000'     ... yes, set flag
*
         CLC   B_VALUE,YES             zFAM-Concat: Yes requested?
         BC    B'0111',*+8             ... no,  continue
         OI    PK_BITS,B'00100000'     ... yes, set flag
*
         TM    PK_BITS,B'11000000'     Requirement #1?
         BC    B'1000',ER_40001        ... yes, HTTP status 400-01
*
         CLI   PK_BITS,B'11000000'     Requirement #2?
         BC    B'1000',ER_40002        ... yes, HTTP status 400-02
*
         CLI   PK_BITS,B'10100000'     Requirement #3?
         BC    B'1000',ER_40003        ... yes, HTTP status 400-03
*
         CLI   PK_BITS,B'01100000'     Requirement #4?
         BC    B'1000',ER_40004        ... yes, HTTP status 400-04
*
         TM    PK_BITS,B'11100000'     Requirement #8?
         BC    B'0001',PK_0800         ... yes, create composite key
*
         CLI   PK_BITS,B'01000000'     Requirement #9?
         BC    B'1000',PK_0900         ... yes, use zUID as Key
*
         CLI   PK_BITS,B'10000000'     Requirement #10?
         BC    B'1000',PK_1000         ... yes, use Primary Key
*
***********************************************************************
* Concatenate Primary Key and zUID to create a composite key.         *
***********************************************************************
PK_0800  DS   0H
         L     R14,PK_LEN              INSERT provided key (length)
         A     R14,=F'32'              Add zUID length
*
         PACK  W_LENGTH,PI_LEN         Pack Key length from FAxxFD
         CVB   R15,W_LENGTH            Convert to binary
*
         CR    R14,R15                 Composite key exceeds FAxxFD?
         BC    B'0010',ER_40006        ... yes, HTTP status 400-06
*
         ST    R14,ZI_LEN              Save zQL INSERT key length
         LA    R14,ZI_KEY              Load target address
         L     R15,PK_ADDR             Load source address
         L     R1,PK_LEN               Load source length
         S     R1,=F'1'                Subtract one for EX instruction
         EX    R1,MVC_PK01             Execute MVC instruction
*
         BAS   R14,PL_0010             LINK to zUID001 service
         LA    R14,ZI_KEY              Load target address
         L     R1,PK_LEN               Load INSERT key length
         LA    R14,0(R1,R14)           Skip past INSERT key
         LA    R15,Z_UID               Load source address
         L     R1,=F'32'               Load zUID length
         S     R1,=F'1'                Subtract one for EX instruction
         EX    R1,MVC_PK01             Execute MVC instruction
*
         LA    R14,ZI_KEY              Load composite key address
         ST    R14,ZI_ADDR             Save composite key address
         BC    B'1111',PK_9000         Composite key create complete
*
***********************************************************************
* zUID as Primary Key.                                                *
***********************************************************************
PK_0900  DS   0H
         L     R14,=F'32'              Load zUID length
*
         PACK  W_LENGTH,PI_LEN         Pack Key length from FAxxFD
         CVB   R15,W_LENGTH            Convert to binary
*
         CR    R14,R15                 zUID key exceeds FAxxFD?
         BC    B'0010',ER_40007        ... yes, HTTP status 400-07
*
         BAS   R14,PL_0010             LINK to zUID001 service
         LA    R14,ZI_KEY              Load target address
         LA    R15,Z_UID               Load source address
         L     R1,=F'32'               Load zUID length
         ST    R1,ZI_LEN               Save zQL INSERT key length
         S     R1,=F'1'                Subtract one for EX instruction
         EX    R1,MVC_PK01             Execute MVC instruction
*
         LA    R14,ZI_KEY              Load zUID key address
         ST    R14,ZI_ADDR             Save zUID key address
         BC    B'1111',PK_9000         zUID key create complete
***********************************************************************
* INSERT provided Primary Key                                         *
***********************************************************************
PK_1000  DS   0H
*
         L     R14,PK_LEN              INSERT provided key (length)
*
         PACK  W_LENGTH,PI_LEN         Pack Key length from FAxxFD
         CVB   R15,W_LENGTH            Convert to binary
*
         CR    R14,R15                 INSERT key exceeds FAxxFD?
         BC    B'0010',ER_40005        ... yes, HTTP status 400-05
*
         ST    R14,ZI_LEN              Save zQL INSERT key length
         LA    R14,ZI_KEY              Load target address
         L     R15,PK_ADDR             Load source address
         L     R1,PK_LEN               Load source length
         S     R1,=F'1'                Subtract one for EX instruction
         EX    R1,MVC_PK01             Execute MVC instruction
*
         LA    R14,ZI_KEY              Load INSERT key address
         ST    R14,ZI_ADDR             Save INSERT key address
         BC    B'1111',PK_9000         INSERT key create complete
*
***********************************************************************
* Primary, zUID and Composite Key MVC instruction                     *
***********************************************************************
         DS   0F
MVC_PK01 MVC   0(0,R14),0(R15)         Move source to target
*
***********************************************************************
* End Primary Key decision logic.                                     *
***********************************************************************
PK_9000  DS   0H
         L     R14,PK_REG              Load return register
         BCR   B'1111',R14             Return to caller
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
         MVC   DC_TRAN,EIBTRNID        Set document TransID
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
         PACK  W_LENGTH,PI_LEN         Move PI length to work area
         CVB   R1,W_LENGTH             Convert to binary
         STH   R1,ZP_KEY_L             Save PI length to DFHCOMMAREA
         MVC   ZP_TYPE,ZP_CRE          Move CREATE replication type
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
ZP_AA    DC    CL02'AA'                Active/Active
ZP_AS    DC    CL02'AS'                Active/Standby
ZP_A1    DC    CL02'A1'                Active/Single
*
DC_DT_L  DC    F'00172'                FAxxDC Document template length
*
*
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40001 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40002 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40003 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40004 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40005 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40006 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'06'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(400)                                                         *
***********************************************************************
ER_40007 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'07'         Set REASON
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(409)                                                         *
***********************************************************************
ER_40901 DS   0H
         MVC   C_STATUS,S_409          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(409)                                                         *
***********************************************************************
ER_40902 DS   0H
         MVC   C_STATUS,S_409          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(412)                                                         *
***********************************************************************
ER_41201 DS   0H
         MVC   C_STATUS,S_412          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         MVC   C_FIELD,P_NAME          Set field name
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50701 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50702 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50703 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50704 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
***********************************************************************
* STATUS(507)                                                         *
***********************************************************************
ER_50705 DS   0H
         MVC   C_STATUS,S_507          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         MVC   C_FILE,EIBDS            Set EIBDS
         BC    B'1111',PC_0010         Transfer control to logging
*
***********************************************************************
* Define Constant fields                                              *
***********************************************************************
*
         DS   0F
YES      DC    CL03'YES'               YES request
         DS   0F
HEX_00   DC    XL01'00'                Nulls
         DS   0F
HEX_40   DC    16XL01'40'              Spaces
         DS   0F
S_400    DC    CL03'400'               HTTP STATUS(400)
         DS   0F
S_409    DC    CL03'409'               HTTP STATUS(409)
         DS   0F
S_412    DC    CL03'412'               HTTP STATUS(412)
         DS   0F
S_507    DC    CL03'507'               HTTP STATUS(507)
         DS   0F
ONE      DC    F'1'                    One
FIVE     DC    F'5'                    Five
S_56     DC    F'56'                   Media type      maximum length
S_OT_LEN DC    F'80'                   OPTIONS  table  maximum length
S_PA_LEN DC    F'8192'                 Parser   Array  maximum length
S_255    DC    F'255'                  Primary Key     maximum length
S_FD_LEN DC    F'65000'                Field Define    maximum length
S_FC_LEN DC    F'256000'               Field Container maximum length
S_RA_LEN DC    F'3200000'              Response Array  maximum length
         DS   0F
S_DF_LEN DC    H'32700'                FAxxFILE        maximum length
         DS   0F
S_32K    DC    F'32000'                Maximum segment length
         DS   0F
PD_ZERO  DC    XL02'000F'              Packed decimal  zeroes
PD_ONE   DC    XL02'001F'              Packed decimal  zeroes
PD_NINES DC    XL02'999F'              Packed decimal  nines
ZD_ZERO  DC    CL05'00000'             Zoned  decimal  zeroes
ZD_2555  DC    CL05'02555'             Packed decimal  2555 (1 year)
ZD_ONE   DC    CL04'001'               Zoned  decimal   001
         DS   0F
ZUID001  DC    CL08'ZUID001 '          zUID service
ZFAM090  DC    CL08'ZFAM090 '          zFAM Logging and error program
SK_FCT   DC    CL08'FAxxKEY '          zFAM KEY  structure
SF_FCT   DC    CL08'FAxxFILE'          zFAM FILE structure
SI_FCT   DC    CL08'FAxxCIxx'          zFAM CI   structure
C_CHAN   DC    CL16'ZFAM-CHANNEL    '  zFAM channel
C_OPTION DC    CL16'ZFAM-OPTIONS    '  OPTIONS container
C_TTL    DC    CL16'ZFAM-TTL        '  TTL container
C_ARRAY  DC    CL16'ZFAM-ARRAY      '  ARRAY container
C_FAXXFD DC    CL16'ZFAM-FAXXFD     '  Field description document
C_KEY    DC    CL16'ZFAM-KEY        '  Primary CI key
C_MEDIA  DC    CL16'ZFAM-MEDIA      '  Media type
         DS   0F
C_SUFFIX DC    CL12'_ZFAM       '      Named Counter suffix
         DS   0F
C_TEXT   DC    CL04'text'              Object type text
         DS   0F
C_BITS   DC    CL04'bits'              Object type binary digits
         DS   0F
S_FILE   DC    CL04'FILE'              Default Data Store suffix
         DS   0F
S_TYPE   DC    CL04'LINK'              zUID type LINK
         DS   0F
S_FORMAT DC    CL05'PLAIN'             zUID format PLAIN
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
T_46_M   DC    CL08'Build RA'          Trace message
T_RES    DC    CL08'ZFAM010 '          Trace resource
T_LEN    DC    H'08'                   Trace resource length
***********************************************************************
* HTTP header resources                                               *
***********************************************************************
         DS   0F
A_HEADER DC    CL08'zFAM-UID'          HTTP header (zFAM-UID)
A_LENGTH EQU   *-A_HEADER              HTTP header field length
         DS   0F
B_HEADER DC    CL11'zFAM-Concat'       HTTP header (zFAM-Concat)
B_LENGTH EQU   *-B_HEADER              HTTP header field length
         DS   0F
         DS   0F
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
* End of Program - ZFAM010                                            *
**********************************************************************
         END   ZFAM010