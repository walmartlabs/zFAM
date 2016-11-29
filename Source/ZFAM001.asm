*
*  PROGRAM:    ZFAM001
*  AUTHOR:     Rich Jackson and Randy Frerking
*  COMMENTS:   zFAM - z/OS Frerking Access Manager
*
*              This program is executed as the initial zFAM HTTP/HTTPS
*              request to determine which zFAM execution mode.
*
*              When the query string is not zQl (or is not present),
*              this is Basic Mode.
*
*              When the query string is zQL,
*              this is Query Mode.
*
*              Basic Authentication is managed in this program for both
*              modes of operation.  Row and field level security are
*              performed in this program.
*
*              HTTP in Basic Mode is allowed under the following rules:
*                1).  Only for GET requests, and
*                2).  Only when Basic Mode Read Only is enabled
*
*              HTTP in Query Mode is allowed under the following rules:
*                1).  Only for GET requests, and
*                2).  Only when Query Mode Read Only is enabled
*
*              After performing Basic Authentication, field/row level
*              security, zQL parsing, field containers, etc, control
*              will be transfered to the following programs:
*
*              ZFAM002 - Basic Mode row level access
*                 POST   LINK to ZFAM011   When Column Index defined
*                 PUT    LINK to ZFAM031   When Column Index defined
*                 DELETE LINK to ZFAM041   When Column Index defined
*
*              ZFAM010 - Query Mode POST
*              ZFAM020 - Query Mode GET
*              ZFAM022 - Query Mode GET    when Column Index requested
*              ZFAM030 - Query Mode PUT
*              ZFAM040 - Query Mode DELETE
*
*
***********************************************************************
* Start Dynamic Storage Area                                          *
***********************************************************************
DFHEISTG DSECT
REGSAVE  DS    16F                Register Save Area
APPLID   DS    CL08               CICS Applid
SYSID    DS    CL04               CICS SYSID
SD_GM    DS    F                  FAxxSD GETMAIN address
FD_GM    DS    F                  FAxxFD GETMAIN address
SD_LEN   DS    F                  FAxxSD GETMAIN length
FD_LEN   DS    F                  FAxxFD GETMAIN length
PA_GM    DS    F                  Parser Array address
PA_LEN   DS    F                  Parser Array length
SD_RESP  DS    F                  FAxxSD DOCUMENT CREATE EIBRESP
FD_RESP  DS    F                  FAxxFD DOCUMENT CREATE EIBRESP
WR_ADDR  DS    F                  WEB RECEIVE buffer address
WR_LEN   DS    F                  WEB RECEIVE buffer address
QS_ADDR  DS    F                  Query string address
BAS_REG  DS    F                  BAS return register
         DS   0F
BM_PROG  DS    CL08               Basic Mode service program
QM_PROG  DS    CL08               Query Mode service program
W_ADDR   DS    F                  Beginning field/where address
W_LEN    DS    CL04               Packed  decimal field length
W_TOTAL  DS    CL08               Packed  decimal total length
W_COLUMN DS    CL08               Packed  decimal column number
W_PACK   DS    CL08               Packed  decimal work field
         DS   0F
X_NAME   DS    CL16               Field Name   (during search)
         DS   0F
W_NAME   DS    CL16               Field Name   (container name)
W_LENGTH DS    F                  Field Length (container data)
W_INDEX  DS    F                  Parser array index
         DS   0F
W_FIELDS DS    CL01               Command indicator
W_WHERE  DS    CL01               Command indicator
W_WITH   DS    CL01               Command indicator
W_TTL    DS    CL01               Command indicator
W_OPTION DS    CL01               Command indicator
W_FORM   DS    CL01               Command indicator
W_DIST   DS    CL01               Command indicator
W_MODE   DS    CL01               Command indicator
W_SORT   DS    CL01               Command indicator
W_ROWS   DS    CL01               Command indicator
*
W_CI     DS    CL01               FAxxFD CI indicator
*
W_SIGN   DS    CL01               Where sign
*
W_PREFIX DS    CL01               URI prefix
*                                 When a replicate request is sent
*                                 in the URI prefix, set this byte to
*                                 X'FF'.  This will be used to allow
*                                 HTTP requests for both BM and QM
*
***********************************************************************
* WEB EXTRACT fields                                                  *
***********************************************************************
         DS   0F
W_SCHEME DS    F                  Scheme (HTTP/HTTPS)
L_METHOD DS    F                  Method length
L_PATH   DS    F                  Path length
L_QUERY  DS    F                  Query string length
         DS   0F
W_METHOD DS    CL06               Method (GET, PUT, POST, DELETE)
E_METHOD EQU   *-W_METHOD         Method field length
         DS   0F
W_PATH   DS    CL512              Path information
E_PATH   EQU   *-W_PATH           Path field length
W_QUERY  DS    CL03               Query string information
E_QUERY  EQU   *-W_QUERY          Query field length
***********************************************************************
* READ HTTPHEADER fields - Authorization                              *
***********************************************************************
         DS   0F
L_HEADER DS    F                  HTTP header length
V_LENGTH DS    F                  HTTP header value length
*
A_VALUE  DS    CL64               HTTP header value
A_VAL_L  EQU   *-A_VALUE          HTTP header value field length
***********************************************************************
* READ HTTPHEADER fields - zFAM-Stream                                *
***********************************************************************
         DS   0F
Z_VALUE  DS    CL03               HTTP header value
Z_VAL_L  EQU   *-Z_VALUE          HTTP header value field length
***********************************************************************
* WEB RECEIVE fields                                                  *
***********************************************************************
         DS   0F
R_LENGTH DS    F                  WEB RECEIVE length
R_MAX    DS    F                  WEB RECEIVE maximum length
R_MEDIA  DS    CL56               WEB RECEIVE media type
***********************************************************************
* zDECODE communication area                                          *
* Base64Binary decoding of Basic Authentication credentials           *
***********************************************************************
C_DECODE DS   0F
C_RC     DS    CL02               Return code
         DS    CL02               Not used
C_USER   DS    CL08               UserID
C_PASS   DS    CL08               Password
C_ECODE  DS    CL24               Encoded UserID:Password
         DS    CL04               Not used
C_DCODE  DS    CL18               Decoded UserID:Password
E_DECODE EQU   *-C_DECODE         Communication data length
*
***********************************************************************
* zFAM090 communication area                                          *
* Logging for zFAM001 exceptional conditions                          *
***********************************************************************
C_LOG    DS   0F
C_STATUS DS    CL03               HTTP Status code
C_REASON DS    CL02               Reason Code
C_USERID DS    CL08               UserID
C_PROG   DS    CL08               Service program name
C_FILE   DS    CL08               File name
C_FIELD  DS    CL16               zQL field name in 412 condition
E_LOG    EQU   *-C_LOG            Commarea Data length
L_LOG    DS    H                  Commarea length
*
***********************************************************************
* Document Template names.                                            *
***********************************************************************
         DS   0F
SD_TOKEN DS    CL16               SD document token
SD_DOCT  DS   0CL48
SD_TRAN  DS    CL04               SD EIBTRNID
SD_TYPE  DS    CL02               SD Type
SD_SPACE DS    CL42               SD Spaces
         DS   0F
FD_TOKEN DS    CL16               FD document token
FD_DOCT  DS   0CL48
FD_TRAN  DS    CL04               FD EIBTRNID
FD_TYPE  DS    CL02               FD Type
FD_SPACE DS    CL42               FD Spaces
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
* End   Dynamic Storage Area                                          *
***********************************************************************
*
***********************************************************************
* Start FAxxSD DOCTEMPLATE buffer (Security Definitions)              *
***********************************************************************
*
SD_DSECT DSECT
B_TEXT   DS    CL22               Basic Mode Read Only - text
B_STATUS DS    CL03               Basic Mode Read Only - status
         DS    CL02               CRLF
Q_TEXT   DS    CL22               Query Mode Read Only - text
Q_STATUS DS    CL03               Query Mode Read Only - status
         DS    CL02               CRLF
E_PREFIX EQU   *-B_TEXT           Security Definition prefix length
*
SD_USER  DSECT
B_USER   DS    CL05               User=
S_USER   DS    CL08               UserID
         DS    CL01               ,
S_TYPE   DS    CL06               Type (Read, Write, Delete)
         DS    CL01               ,
E_SD     EQU   *-B_USER           Security levels displacement
S_LEVELS DS    CL33               Security levels
         DS    CL01               space
         DS    CL01               end of field marker
         DS    CL02               CRLF
E_USER   EQU   *-B_USER           User entry length
***********************************************************************
* End   FAxxSD DOCTEMPLATE buffer                                     *
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
* Start WEB RECEIVE buffer                                            *
***********************************************************************
*
WR_DSECT DSECT
***********************************************************************
* End   WEB RECEIVE buffer                                            *
***********************************************************************
*
***********************************************************************
* Start Data Container buffer                                         *
***********************************************************************
*
DC_DSECT DSECT
***********************************************************************
* End   Data Container buffer                                         *
***********************************************************************
*
***********************************************************************
* Start DFHCOMMAREA                                                   *
***********************************************************************
*
DFHCA    DSECT
C_QUERY  DS    CL8192             Query string information
***********************************************************************
* End   DFHCOMMAREA                                                   *
***********************************************************************
*
***********************************************************************
* Control Section - ZFAM001                                           *
***********************************************************************
***********************************************************************
ZFAM001  DFHEIENT CODEREG=(R2,R3,12),DATAREG=R10,EIBREG=R11
ZFAM001  AMODE 31
ZFAM001  RMODE 31
         B     SYSDATE                 BRANCH AROUND LITERALS
         DC    CL08'ZFAM001 '
         DC    CL48' -- Initial zFAM control service                '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
SYSDATE  DS   0H
***********************************************************************
* Extract relevant WEB information regarding this request.            *
* Since the WEB EXTRACT command moves the Query String 'into' an area *
* instead of setting a pointer, only a three byte area is defined for *
* the EXTRACT command.  The three bytes are used to determine whether *
* the request is basic mode or query mode (zQL).  When query mode,    *
* parse the DFHCOMMAREA for the beginning of the query string and     *
* save the pointer address.  This reduces the amount of DFHEISTG      *
* storage required for the Query String and eliminates a GETMAIN.     *
*                                                                     *
* Create Access-Control-Allow-Origin HTTP Header for all zFAM modules.*
*                                                                     *
***********************************************************************
SY_0010  DS   0H
         EXEC CICS WEB WRITE                                           X
               HTTPHEADER (H_ACAO)                                     X
               NAMELENGTH (H_ACAO_L)                                   X
               VALUE      (M_ACAO)                                     X
               VALUELENGTH(M_ACAO_L)                                   X
               NOHANDLE
*
         LA    R1,E_PATH               Load path   field length
         ST    R1,L_PATH               Save path   field length
         LA    R1,E_METHOD             Load method field length
         ST    R1,L_METHOD             Save method field length
         LA    R1,E_QUERY              Load query  field length
         ST    R1,L_QUERY              Save query  field length
*
         EXEC CICS WEB EXTRACT                                         X
               SCHEME(W_SCHEME)                                        X
               HTTPMETHOD(W_METHOD)                                    X
               METHODLENGTH(L_METHOD)                                  X
               PATH(W_PATH)                                            X
               PATHLENGTH(L_PATH)                                      X
               QUERYSTRING(W_QUERY)                                    X
               QUERYSTRLEN(L_QUERY)                                    X
               NOHANDLE
*
         CLC   W_PATH(10),REPLIC8      URI '/replicate' prefix?
         BC    B'0111',*+8             ... no,  continue
         MVI   W_PREFIX,X'FF'          ... yes, set replicate flag
*
         CLC   L_QUERY,MAX_QS          Query string maximum exceeded?
         BC    B'0010',ER_41401        ... yes, set return code
*
         CLC   EIBRESP2,=F'30'         Path length exceeded?
         BC    B'1000',ER_41402        ... yes, set return code
*
         CLC   W_SCHEME,DFHVALUE(HTTP) HTTP (non-SSL) request?
         BC    B'1000',SY_0050         ... yes, skip READ HTTPHEADER
*
         CLC   W_PATH(10),URI_DS       /datastore request?
         BC    B'0111',SY_0050         ... no,  skip HTTPHEADER
*
***********************************************************************
* Read HTTPHEADER to obtain Basic Authentication credentials.         *
***********************************************************************
SY_0020  DS   0H
         LA    R1,A_LENGTH             Load header name  length
         ST    R1,L_HEADER             Save header name  length
         LA    R1,A_VAL_L              Load value  field length
         ST    R1,V_LENGTH             Save value  field length
*
         EXEC CICS WEB READ HTTPHEADER(A_HEADER)                       X
               NAMELENGTH(L_HEADER)                                    X
               VALUE(A_VALUE)                                          X
               VALUELENGTH(V_LENGTH)                                   X
               NOHANDLE
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_40101        ... no,  set return message
*
         CLC   V_LENGTH,SIX            Value length greater than six?
         BC    B'1100',ER_40102        ... no,  set return message
*
***********************************************************************
* Call zDECODE.                                                       *
* Base64Binary decoding of Basic Authentication credentials           *
***********************************************************************
SY_0030  DS   0H
         MVC   C_ECODE,A_VALUE+6       Move encoded UserID:Password
         LA    R1,C_DECODE             Load zDECODE communication area
         ST    R13,DFHEIR13            Save R13 (old RSA)
         LA    R13,DFHEISA             Load R13 (new RSA)
         L     R15,DECODE              Load zDECODE address
         BASR  R14,R15                 Call zDECODE routine
         L     R13,DFHEIR13            Load R13
*
         OC    C_USER,HEX_40           Set upper case bits on
         MVC   C_USERID,C_USER         Move UserID to logging COMMAREA
*
         CLI   C_RC+1,X'F0'            Return Code zero?
         BC    B'0111',ER_40102        ... no,  STATUS(401)
*
         EXEC CICS VERIFY USERID(C_USER) PASSWORD(C_PASS)              X
               NOHANDLE
         OC    EIBRESP,EIBRESP         Return Code zero?
         BC    B'0111',ER_40103        ... no,  STATUS(401)
*
***********************************************************************
* Get Security DOCTEMPLATE (FAxxSD)                                   *
***********************************************************************
SY_0050  DS   0H
         EXEC CICS GETMAIN                                             X
               SET(R9)                                                 X
               FLENGTH(SD_GM_L)                                        X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         ST    R9,SD_GM                Save GETMAIN address
         USING SD_DSECT,R9             ... tell assembler
*
         MVC   SD_LEN,SD_GM_L          Set document length
         MVC   SD_TRAN(2),FA_PRE       Set document TransId prefix
         MVC   SD_TRAN+2(2),EIBTRNID+2 Set document TransID suffix
         MVC   SD_TYPE,=C'SD'          Set document type
         MVI   SD_SPACE,X'40'          Set first byte
         MVC   SD_SPACE+1(41),SD_SPACE Set remainder of bytes
*
         EXEC CICS DOCUMENT CREATE DOCTOKEN(SD_TOKEN)                  X
               TEMPLATE(SD_DOCT)                                       X
               RESP    (SD_RESP)                                       X
               NOHANDLE
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',SY_0060         ... no,  bypass RETRIEVE
*
         EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(SD_TOKEN)                X
               INTO     (SD_DSECT)                                     X
               LENGTH   (SD_LEN)                                       X
               MAXLENGTH(SD_LEN)                                       X
               RESP     (SD_RESP)                                      X
               DATAONLY                                                X
               NOHANDLE
*
         DROP  R9                      ... tell assembler
*
***********************************************************************
* Get Field    DOCTEMPLATE (FAxxFD)                                   *
***********************************************************************
SY_0060  DS   0H
         EXEC CICS GETMAIN                                             X
               SET(R9)                                                 X
               FLENGTH(FD_GM_L)                                        X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         ST    R9,FD_GM                Save GETMAIN address
         USING FD_DSECT,R9             ... tell assembler
*
         MVC   FD_LEN,FD_GM_L          Set document length
         MVC   FD_TRAN(2),FA_PRE       Set document TransId prefix
         MVC   FD_TRAN+2(2),EIBTRNID+2 Set document TransID suffix
         MVC   FD_TYPE,=C'FD'          Set document type
         MVI   FD_SPACE,X'40'          Set first byte
         MVC   FD_SPACE+1(41),FD_SPACE Set remainder of bytes
*
         EXEC CICS DOCUMENT CREATE DOCTOKEN(FD_TOKEN)                  X
               TEMPLATE(FD_DOCT)                                       X
               RESP    (FD_RESP)                                       X
               NOHANDLE
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',SY_0090         ... no,  bypass RETRIEVE
*
         EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(FD_TOKEN)                X
               INTO     (FD_DSECT)                                     X
               LENGTH   (FD_LEN)                                       X
               MAXLENGTH(FD_LEN)                                       X
               RESP     (FD_RESP)                                      X
               DATAONLY                                                X
               NOHANDLE
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',SY_0090         ... no,  bypass PUT CONTAINER
*
***********************************************************************
* This routine intentionally left blank.                              *
* The PUT CONTAINER for FAxxFD has been moved to BM_0400.             *
***********************************************************************
SY_0070  DS   0H
SY_0080  DS   0H
         BC    B'1111',SY_0090         Bypass PUT CONTAINER
         DROP  R9                      ... tell assembler
*
***********************************************************************
* Check mode of operation and branch accordingly.                     *
***********************************************************************
SY_0090  DS   0H
         CLC   L_QUERY,=F'3'           Three bytes present?
         BC    B'0100',BM_0010         ... no,  Basic mode request
*
         OC    W_QUERY(3),HEX_40       Set upper case bits
         CLC   W_QUERY(3),ZQL          Query Mode specified?
         BC    B'1000',QM_0010         ... yes, Query Mode request
         BC    B'0111',BM_0010         ... no,  Basic Mode request
*
***********************************************************************
* Basic Mode                                                          *
*                                                                     *
* Begin  security                                                     *
*                                                                     *
* When SCHEME is HTTP                                                 *
*     When GET                                                        *
*         When FAxxSD not defined (development only)                  *
*             XCTL ZFAM002                                            *
*         When FAxxSD is  defined (QA and production)                 *
*             When Basic Mode Read Only is enabled                    *
*                 XCTL ZFAM002                                        *
*             When Basic Mode Read Only is disabled                   *
*                 WEB SEND STATUS(401)                                *
*     When PUT, POST, DELETE                                          *
*         When FAxxSD is  defined (QA and production)                 *
*             WEB SEND STATUS(401)                                    *
*                                                                     *
* When SCHEME is HTTPS                                                *
*     When FAxxSD is defined (QA and production)                      *
*         Compare UserID with FAxxSD                                  *
*         When UserID not equal security level for type of access     *
*             WEB SEND STATUS(401)                                    *
*                                                                     *
* End of security                                                     *
*                                                                     *
* When FAxxFD and CI defined, ZFAM002 (Basic Mode) will perform the   *
*   appropriate process, then will transfer control to the following: *
*                                                                     *
*     When POST                                                       *
*         XCTL ZFAM011                                                *
*     When PUT                                                        *
*         XCTL ZFAM031                                                *
*     When DELETE                                                     *
*         XCTL ZFAM041                                                *
*                                                                     *
* At this point (all conditions confirm Basic Mode processing)        *
*     XCTL ZFAM002                                                    *
*                                                                     *
***********************************************************************
BM_0010  DS   0H
         CLI   W_PREFIX,X'FF'          URI '/replicate' prefix?
         BC    B'1000',BM_0300         ... yes, bypass security
*
         L     R9,SD_GM                Load FAxxSD address
         USING SD_DSECT,R9             ... tell assembler
         CLC   W_SCHEME,DFHVALUE(HTTP) HTTP request?
         BC    B'1000',BM_0100         ... yes, execute HTTP  security
         BC    B'0111',BM_0200         ... no,  execute HTTPS security
***********************************************************************
* SCHEME is HTTP.   Determine appropriate action                      *
***********************************************************************
BM_0100  DS   0H
         CLC   W_METHOD(3),S_GET       GET request?
         BC    B'0111',BM_0120         ... no,  check other methods
***********************************************************************
* SCHEME is HTTP  and this is a GET request                           *
***********************************************************************
BM_0110  DS   0H
         OC    SD_RESP,SD_RESP         FAxxSD defined?
         BC    B'0111',BM_0300         ... no,  Check for FAxxFD
*        BC    B'0111',BM_0500         ... no,  XCTL to ZFAM002
         OC    B_STATUS,HEX_40         Set upper case bits
         CLC   B_STATUS,S_YEA          BM Read Only enabled?
         BC    B'1000',BM_0300         ... yes, Check for FAxxFD
*        BC    B'1000',BM_0500         ... yes, XCTL to ZFAM002
         BC    B'0111',ER_40104        ... no,  STATUS(401)
***********************************************************************
* SCHEME is HTTP  and this is a PUT, POST, DELETE request             *
***********************************************************************
BM_0120  DS   0H
         OC    SD_RESP,SD_RESP         FAxxSD defined?
         BC    B'1000',ER_40105        ... yes, STATUS(401)
         BC    B'0111',BM_0300         ... no,  continue validation
***********************************************************************
* SCHEME is HTTPS.  Determine appropriate action                      *
***********************************************************************
BM_0200  DS   0H
         OC    SD_RESP,SD_RESP         FAxxSD defined?
         BC    B'0111',BM_0300         ... no,  continue validation
*
         LA    R4,E_USER               Load user  entry length
         L     R5,SD_LEN               Load SD template length
         LA    R6,E_PREFIX             Load SD prefix length
         SR    R5,R6                   Subtract prefix length
         AR    R9,R6                   Point to User entry
         USING SD_USER,R9              ... tell assembler
*
***********************************************************************
* Parse SD entry until EOT or a UserID match                          *
***********************************************************************
BM_0210  DS   0H
         CLC   S_USER,C_USER           UserID match FAxxSD?
         BC    B'1000',BM_0220         ... yes, check access level
BM_0211  DS    0H
         LA    R9,0(R4,R9)             Point to next entry
         SR    R5,R4                   Subtract user entry length
         BC    B'0010',BM_0210         Continue search
         BC    B'1111',ER_40106        EOT, STATUS(401)
***********************************************************************
* UserID matches FAxxSD entry.                                        *
* Now check HTTP METHOD and branch to compare with security entry     *
***********************************************************************
BM_0220  DS   0H
         OC    S_TYPE,HEX_40           Set upper case bits
         CLC   W_METHOD(4),S_POST      POST   request?
         BC    B'1000',BM_0221         ... yes, check SD type
         CLC   W_METHOD(3),S_GET       GET    request?
         BC    B'1000',BM_0222         ... yes, check SD type
         CLC   W_METHOD(3),S_PUT       PUT    request?
         BC    B'1000',BM_0223         ... yes, check SD type
         CLC   W_METHOD(6),S_DELETE    DELETE request?
         BC    B'1000',BM_0224         ... yes, check SD type
         BC    B'0111',ER_40001        ... no,  WEB SEND STATUS(400)
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* POST   must match request type of 'Write '                          *
***********************************************************************
BM_0221  DS   0H
         CLC   S_TYPE,S_WRITE          Security entry for 'Write'?
         BC    B'0111',BM_0211         ... no,  continue search
         OI    S_LEVELS,X'40'          Set upper case bit
         CLI   S_LEVELS,C'X'           Row level (0) set?
         BC    B'1000',BM_0300         ... yes, continue validation
         BC    B'1111',ER_40107        ... no,  STATUS(401)
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* GET    must match request type of 'Read  '                          *
***********************************************************************
BM_0222  DS   0H
         CLC   S_TYPE,S_READ           Security entry for 'Read'?
         BC    B'0111',BM_0211         ... no,  continue search
         OI    S_LEVELS,X'40'          Set upper case bit
         CLI   S_LEVELS,C'X'           Row level (0) set?
         BC    B'1000',BM_0300         ... yes, continue validation
         BC    B'1111',ER_40108        ... no,  STATUS(401)
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* PUT    must match request type of 'Write '                          *
***********************************************************************
BM_0223  DS   0H
         CLC   S_TYPE,S_WRITE          Security entry for 'Write'?
         BC    B'0111',BM_0211         ... no,  continue search
         OI    S_LEVELS,X'40'          Set upper case bit
         CLI   S_LEVELS,C'X'           Row level (0) set?
         BC    B'1000',BM_0300         ... yes, continue validation
         BC    B'1111',ER_40109        ... no,  STATUS(401)
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* DELETE must match request type of 'Delete'                          *
***********************************************************************
BM_0224  DS   0H
         CLC   S_TYPE,S_DELETE         Security entry for 'Delete'?
         BC    B'0111',BM_0211         ... no,  continue search
         OI    S_LEVELS,X'40'          Set upper case bit
         CLI   S_LEVELS,C'X'           Row level (0) set?
         BC    B'1000',BM_0300         ... yes, continue validation
         BC    B'1111',ER_40110        ... no,  STATUS(401)
*
***********************************************************************
* At this point, all validation rules have been performed for         *
* Basic Mode.  Prior to this routine, a BRANCH could have been made   *
* to XCTL to ZFAM002.  All other cases fall thru to this routine to   *
* determine if Basic Mode is being requested for a table that has     *
* fields defined.  If any of the fields are defined as Column Index,  *
* issue PUT CONTAINER for FAxxFD, which will be used by zFAM002 to    *
* LINK to program to process secondary column indexes.                *
***********************************************************************
BM_0300  DS   0H
         DROP  R9                      ... tell assembler
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         OC    FD_RESP,FD_RESP         FAxxFD defined?
         BC    B'0111',BM_0500         ... no,  XCTL ZFAM002
         LA    R4,E_FD                 Load field entry length
         L     R5,FD_LEN               Load FD template length
***********************************************************************
* Parse FD entry until EOT or a column index is encountered           *
***********************************************************************
BM_0310  DS   0H
         CLC   F_COL,=C'0000001'       Column number 1 (primary key)?
         BC    B'1000',BM_0320         ... yes, skip this one
         CLC   F_ID,=C'000'            Field ID number?
         BC    B'0010',BM_0400         ... no,  Basic Mode CI process
***********************************************************************
* Point to next entry until EOT                                       *
***********************************************************************
BM_0320  DS   0H
         LA    R9,0(R4,R9)             Point to next entry
         SR    R5,R4                   Subtract field entry length
         BC    B'0010',BM_0310         Continue search
         BC    B'1111',BM_0500         EOT, standard Basic Mode
***********************************************************************
* Basic Mode with FAxxFD and column index defined.                    *
* Transfer control to Basic Mode (row level) service program and      *
* provide the FXxxFD.  This will signal ZFAM002 to transfer control   *
* to the Column Index service program to insert/update the secondary  *
* Column Index stores.                                                *
***********************************************************************
BM_0400  DS   0H
         MVC   W_ADDR,FD_GM            Move FAxxFD address
         MVC   W_LENGTH,FD_LEN         Move FAxxFD length
         MVC   W_NAME,C_FAXXFD         Move FAxxFD container name
         BAS   R14,PC_0010             Issue PUT CONTAINER
***********************************************************************
* Basic Mode primary program.                                         *
***********************************************************************
BM_0500  DS   0H
         MVC   BM_PROG,ZFAM002         Move Basic Mode primary program
*
***********************************************************************
* Transfer control to Basic Mode (row level) program                  *
***********************************************************************
BM_0600  DS   0H
         EXEC CICS XCTL PROGRAM(BM_PROG)                               X
               CHANNEL(C_CHAN)                                         X
               NOHANDLE
         BC    B'1111',ER_50001        Oops, something's wrong!
*
***********************************************************************
* Query Mode                                                          *
*                                                                     *
* When POST/PUT                                                       *
*     WEB RECEIVE                                                     *
*                                                                     *
* GETMAIN parser array storage                                        *
*                                                                     *
* Parse querystring (GET/DELETE) or buffer (POST/PUT)                 *
* Create primary key container                                        *
* Create field/data containers                                        *
* Create array of container names                                     *
* Create array container                                              *
* Create WITH UR/CR container (for LOCK logic)                        *
*                                                                     *
* Begin  Query Mode security                                          *
*                                                                     *
* When SCHEME is HTTP                                                 *
*     When GET                                                        *
*         When FAxxSD is  defined (QA and production)                 *
*             When Query Mode Read Only is disabled                   *
*                 WEB SEND STATUS(401)                                *
*             When Query Mode Read Only is enabled                    *
*                 Bypass field level security                         *
*         When FAxxSD not defined (development)                       *
*             Bypass security                                         *
*                                                                     *
*     When PUT, POST, DELETE                                          *
*         When FAxxSD is  defined (QA and production)                 *
*             WEB SEND STATUS(401)                                    *
*         When FAxxSD not defined (development)                       *
*             Bypass security                                         *
*                                                                     *
* When SCHEME is HTTPS                                                *
*     When FAxxSD is  defined (QA and production                      *
*         Parse FAxxSD until match on UserID                          *
*         When UserID not equal security level for type of access     *
*             WEB SEND STATUS(401)                                    *
*     When FAxxSD not defined (development)                           *
*         Bypass security                                             *
*                                                                     *
* End of Query Mode security                                          *
*                                                                     *
*                                                                     *
*                                                                     *
* When POST                                                           *
*         XCTL ZFAM010                                                *
*                                                                     *
* When GET                                                            *
*     When SELECT specifies primary column index                      *
*         XCTL ZFAM020                                                *
*     When SELECT specifies secondary column index                    *
*         XCTL ZFAM022                                                *
*                                                                     *
* When PUT                                                            *
*         XCTL ZFAM030                                                *
*                                                                     *
* When DELETE                                                         *
*         XCTL ZFAM040                                                *
*                                                                     *
*                                                                     *
***********************************************************************
***********************************************************************
* Query Mode process.                                                 *
***********************************************************************
***********************************************************************
*                                                                     *
***********************************************************************
* Issue GETMAIN for parser array                                      *
***********************************************************************
QM_0010  DS   0H
         OC    FD_RESP,FD_RESP         FAxxFD defined?
         BC    B'0111',ER_40505        ... no,  Query Mode not allowed
*
         EXEC CICS GETMAIN                                             X
               SET(R8)                                                 X
               FLENGTH(PA_GM_L)                                        X
               INITIMG(HEX_00)                                         X
               NOHANDLE
*
         ST    R8,PA_GM                Save GETMAIN address
         MVC   PA_LEN,PA_GM_L          Save GETMAIN length
***********************************************************************
* When POST/PUT requests, issue WEB RECEIVE                           *
***********************************************************************
QM_0020  DS   0H
         CLC   W_METHOD(6),S_DELETE    DELETE request?
         BC    B'1000',QM_0030         ... yes, nothing to receive
         CLC   W_METHOD(3),S_GET       GET    request?
         BC    B'1000',QM_0030         ... yes, nothing to receive
*
         MVC   R_LENGTH,S_WR_LEN       Move WEB RECEIVE length
         MVC   R_MAX,S_WR_LEN          Move WEB RECEIVE length
*
         EXEC CICS WEB RECEIVE                                         X
               SET(R8)                                                 X
               LENGTH   (R_LENGTH)                                     X
               MAXLENGTH(R_MAX)                                        X
               MEDIATYPE(R_MEDIA)                                      X
               SRVCONVERT                                              X
               NOHANDLE
         ST    R8,WR_ADDR              Save WEB RECEIVE buffer address
*
         CLC   EIBRESP2,=F'16'         MAXLENGTH exceeded?
         BC    B'1000',ER_41301        ... yes, set return code
*
         CLC   R_LENGTH,=F'00'         Length received is zero?
         BC    B'1000',ER_41101        ... yes, set return code
*
         OC    EIBRESP,EIBRESP         Normal response?
         BC    B'0111',ER_40003        ... no,  set return code
***********************************************************************
* Check method and branch accordingly                                 *
***********************************************************************
QM_0030  DS   0H
         CLC   W_METHOD(4),S_POST      POST   request?
         BC    B'1000',QM_0100         ... yes, parse POST   request
         CLC   W_METHOD(3),S_GET       GET    request?
         BC    B'1000',QM_0200         ... yes, parse GET    request
         CLC   W_METHOD(3),S_PUT       PUT    request?
         BC    B'1000',QM_0300         ... yes, parse PUT    request
         CLC   W_METHOD(6),S_DELETE    DELETE request?
         BC    B'1000',QM_0400         ... yes, parse DELETE request
         BC    B'1111',ER_40004        ... no,  send STATUS(400)
*
***********************************************************************
* Parse POST   request, using WEB RECEIVE input                       *
***********************************************************************
QM_0100  DS   0H
         L     R4,R_LENGTH             Load RECEIVE length
         L     R5,WR_ADDR              Load RECEIVE address
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(6,R5),S_INSERT        Is this an INSERT command?
         BC    B'0111',ER_40501        ... no,  invalid command
         LA    R5,6(,R5)               Point to next byte
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',QM_0500         INSERT with no fields
*                                      ... this is actually ok
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40006        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
***********************************************************************
* Check POST   request for zQL commands.                              *
* Valid commands are FIELDS and TTL.                                  *
***********************************************************************
QM_0110  DS   0H
         LA    R0,QM_0110              Mark the spot
         CLI   0(R5),C'('              Open parenthesis?
         BC    B'0111',ER_40006        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(3,R5),S_TTL           Is this a TTL    command?
         BC    B'1000',QM_0120         ... yes, process
         CLC   0(6,R5),S_FIELDS        Is this a FIELDS command?
         BC    B'1000',QM_0130         ... yes, process
         BC    B'1111',ER_40006        ... no,  syntax error
***********************************************************************
* Process TTL command                                                 *
***********************************************************************
QM_0120  DS   0H
         CLI   W_TTL,C'Y'              TTL   command performed?
         BC    B'1000',ER_40006        ... yes, syntax error
***********************************************************************
* Begin parsing TTL command                                           *
***********************************************************************
QM_0121  DS   0H
         LA    R0,QM_0121              Mark the spot
         LA    R5,3(,R5)               Point past command
         S     R4,=F'03'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
*
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40006        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
         XR    R1,R1                   Clear counter
         ST    R5,W_ADDR               Save beginning TTL address
***********************************************************************
* Determine length of TTL and perform editing.                        *
***********************************************************************
QM_0122  DS   0H
         LA    R0,QM_0122              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0123         ... yes, continue process
         CLI   0(R5),X'F0'             Compare TTL byte to zero
         BC    B'0100',ER_40006        ... when less, syntax error
         CLI   0(R5),X'FA'             Compare TTL byte to FA+
         BC    B'1010',ER_40006        ... when more, syntax error
         C     R1,=F'5'                Maximum TTL length?
         BC    B'0010',ER_40006        ... yes, syntax error
*
         LA    R1,1(,R1)               Increment TTL length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0122              Continue parsing
         BC    B'1100',ER_40006        Syntax error when EOQS
***********************************************************************
* Issue PUT CONTAINER for TTL field                                   *
***********************************************************************
QM_0123  DS   0H
         LA    R0,QM_0123              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
*
         CLI   0(R5),C')'              Close parenthesis?
         BC    B'0111',ER_40006        ... no,  syntax error
*
         MVI   W_TTL,C'Y'              Mark TTL command complete
*
         MVC   W_NAME,C_TTL            Move TTL container name
         ST    R1,W_LENGTH             Save data length
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R0,QM_0123              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1000',QM_0500         When zero, parsing complete
*
         CLI   0(R5),C','              Comma?
         BC    B'0111',ER_40006        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
         BC    B'1111',QM_0110         Continue POST parsing
***********************************************************************
* FIELDS command                                                      *
***********************************************************************
QM_0130  DS   0H
         CLI   W_FIELDS,C'Y'           FIELDS  command performed?
         BC    B'1000',ER_40006        ... yes, syntax error
*
         LA    R5,6(,R5)               Point past command
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
***********************************************************************
* Begin parsing FIELDS command                                        *
***********************************************************************
QM_0131  DS   0H
         LA    R0,QM_0131              Mark the spot
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40006        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1 (counter)
         ST    R5,W_ADDR               Save beginning address
         LR    R15,R5                  Load beginning address
***********************************************************************
* Determine field name length.                                        *
***********************************************************************
QM_0132  DS    0H
         LA    R0,QM_0132              Mark the spot
         CLI   0(R5),C'='              Equal sign?
         BC    B'1000',QM_0133         ... yes, process
         C     R1,=F'16'               Exceed maximum field length?
         BC    B'0011',ER_40006        ... yes, syntax error
         LA    R1,1(,R1)               Increment field name length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0132              Continue evaluation
         BC    B'1111',ER_40006        EOF, syntax error
***********************************************************************
* Address FAxxFD table                                                *
***********************************************************************
QM_0133  DS    0H
         LA    R0,QM_0133              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
*
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         L     R7,FD_LEN               Load FD table length
         LA    R6,E_FD                 Load FD entry length
         S     R1,ONE                  Adjust before EX command
***********************************************************************
* Verify the field name is in FAxxFD                                  *
***********************************************************************
QM_0134  DS    0H
         LA    R0,QM_0134              Mark the spot
         LA    R14,F_NAME              Point to field name
         EX    R1,CLC_0134             Field name match?
         BC    B'1000',QM_0135         ... yes, process
         LA    R9,0(R6,R9)             Point to next FD entry
         SR    R7,R6                   Reduce total length by an entry
         BC    B'0010',QM_0134         Continue search
         MVC   C_FIELD,HEX_40          Move spaces to field name
         LA    R14,C_FIELD             Point to field name
         EX    R1,MVC_0134             Move field name to diagnostics
         BC    B'1111',ER_41201        ... EOF, syntax error
CLC_0134 CLC   0(0,R14),0(R15)         Check field name
MVC_0134 MVC   0(0,R14),0(R15)         Move  field name
***********************************************************************
* Move field name to parser array                                     *
***********************************************************************
QM_0135  DS    0H
         LA    R0,QM_0135              Mark the spot
         MVC   W_NAME,HEX_40           Clear field
         LA    R14,W_NAME              Point to field name
         EX    R1,MVC_0135             Set container name
         L     R8,PA_GM                Load parser array address
         USING PA_DSECT,R8             ... tell assembler
*
         LA    R7,E_PA                 Load parser array entry length
         XR    R6,R6                   Clear even register
         L     R1,W_INDEX              Load PA index
         MR    R6,R1                   Multiply by entry length
         LA    R8,0(R7,R8)             Point to current PA entry
*
         LA    R1,1(,R1)               Increment PA index
         ST    R1,W_INDEX              Save PA index
         C     R1,MAX_PA               PA index exceeded?
         BC    B'0010',ER_41403        ... yes, STATUS(414)
*
         MVC   P_NAME,F_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
         BC    B'1111',QM_0136         Determine field length
*
MVC_0135 MVC   0(0,R14),0(R15)         Set container name
***********************************************************************
* Determine length of data for this field                             *
***********************************************************************
QM_0136  DS   0H
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0137         ... yes, PUT CONTAINER
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment field length
         C     R1,MAX_LEN              Field length exceed maximum?
         BCT   R4,QM_0136              Continue parsing
         BC    B'1111',ER_40006        Syntax error when zero
***********************************************************************
* Issue PUT CONTAINER for this field data                             *
***********************************************************************
QM_0137  DS   0H
         LA    R0,QM_0137              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when zero
*
         ST    R1,W_LENGTH             Save data length
         BAS   R14,PC_0010             Issue PUT CONTAINER
***********************************************************************
* When Column ID is 001, issue PUT CONTAINER for primary key          *
***********************************************************************
         CP    P_ID,S_ONE_PD           Primary Column ID?
         BC    B'0111',QM_0138         ... no,  continue process
         MVC   W_NAME,C_KEY            Move KEY container name
         BAS   R14,PC_0010             PUT CONTAINER with PRIMARY key
***********************************************************************
* Continue field syntax editing.                                      *
***********************************************************************
QM_0138  DS   0H
         LA    R0,QM_0138              Mark the spot
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'1000',QM_0139         ... yes, prepare to parse
*
         CLI   0(R5),C')'              Close Parenthesis?
         BC    B'0111',ER_40006        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',QM_0500         When zero, parsing is complete
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40006        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40006        When zero, syntax error
         MVI   W_FIELDS,C'Y'           Set FIELDS command complete
         BC    B'1111',QM_0110         Continue parsing
*
***********************************************************************
* Prepare to parse next FIELDS request                                *
***********************************************************************
QM_0139  DS   0H
         LA    R0,QM_0139              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40006        Syntax error when EOQS
         BC    B'1111',QM_0131         Continue with FIELDS
*
***********************************************************************
* Parse GET    request, using Query String                            *
* Since the WEB EXTRACT command moves the Query String 'into' an area *
* instead of setting a pointer, only a three byte area is defined for *
* the EXTRACT command.  The three bytes are used to determine whether *
* the request is basic mode or query mode (zQL).  When query mode,    *
* parse the DFHCOMMAREA for the beginning of the query string and     *
* save the pointer address.  This reduces the amount of DFHEISTG      *
* storage required for the Query String and eliminates a GETMAIN.     *
***********************************************************************
QM_0200  DS   0H
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
*
         MVC   O_P_NAME,F_NAME         Move field name     to OT
         MVC   O_P_TYPE,F_TYPE         Move field type     to OT
         PACK  O_P_COL,F_COL           Pack field column   to OT
         PACK  O_P_LEN,F_LEN           Pack field length   to OT
*
         MVC   O_FORM,S_FIXED          Set default OPTIONS FORMAT
         MVC   O_DIST,S_NO             Set default OPTIONS DISTINCT
         MVC   O_MODE,S_ON             Set default OPTIONS MODE
         MVC   O_ROWS,S_ZEROES         Set default OPTIONS ROWS
         MVC   O_SORT,HEX_40           Set default OPTIONS SORT
         MVC   O_WITH,S_UR             Set default OPTIONS WITH
*
         BAS   R14,TR_0010             Execute Trace entry
*
         BAS   R14,CA_0010             Parse DFHCOMMAREA for QS
         USING DFHCA,R5                ... tell assembler
         L     R4,L_QUERY              Load query string length
         LA    R5,3(,R5)               Skip past the ZQl command
         S     R4,=F'03'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(6,R5),S_SELECT        Is this a SELECT command?
         BC    B'0111',ER_40502        ... no,  invalid command
         LA    R5,6(,R5)               Point to next byte
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
***********************************************************************
* Check GET    request for zQL commands.                              *
* Valid commands are WHERE, WITH, FIELDS, and OPTIONS                 *
***********************************************************************
QM_0210  DS   0H
         LA    R0,QM_0210              Mark the spot
         CLI   0(R5),C'('              Open parenthesis?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         OC    0(4,R5),HEX_40          Set upper case bits
         CLC   0(4,R5),S_WITH          Is this a  WITH    command?
         BC    B'1000',QM_0220         ... yes, process
*
         OC    0(5,R5),HEX_40          Set upper case bits
         CLC   0(5,R5),S_WHERE         Is this a  WHERE   command?
         BC    B'1000',QM_0240         ... yes, process
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(6,R5),S_FIELDS        Is this a  FIELDS  command?
         BC    B'1000',QM_0230         ... yes, process
*
         OC    0(7,R5),HEX_40          Set upper case bits
         CLC   0(7,R5),S_OPTION        Is this an OPTIONS command?
         BC    B'1000',QM_0250         ... yes, process
         BC    B'1000',ER_40007        ... no,  syntax error
***********************************************************************
* WITH command                                                        *
***********************************************************************
QM_0220  DS   0H
         LA    R0,QM_0220              Mark the spot
         CLI   W_WITH,C'Y'             WITH   command performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,4(,R5)               Point past command
         S     R4,=F'04'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         OC    0(2,R5),HEX_40          Set upper case bits
         CLC   0(2,R5),S_UR            Uncommitted read request?
         BC    B'1000',QM_0221         ... yes, continue
         CLC   0(2,R5),S_CR            Committed   read request?
         BC    B'1000',QM_0221         ... yes, continue
         BC    B'1111',ER_40007        ... no,  syntax error
***********************************************************************
* Save WITH request and prepare for next parm.                        *
***********************************************************************
QM_0221  DS    0H
         LA    R0,QM_0221              Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,2(,R5)               Point to next byte
         S     R4,=F'02'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C')'              Close parenthesis
         BC    B'0111',ER_40007        ... no,  syntax error
*
***********************************************************************
* Move WITH UR/CR to OPTIONS table.                                   *
***********************************************************************
QM_0222  DS    0H
         MVI   W_WITH,C'Y'             Mark WITH command complete
*
         L     R1,W_ADDR               Load WITH address
         MVC   O_WITH,0(R1)            Move WITh parameter
*
         LA    R0,QM_0222              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1000',QM_0500         When zero, parsing complete
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         BC    B'1111',QM_0210         Continue parsing
***********************************************************************
* FIELDS command                                                      *
***********************************************************************
QM_0230  DS   0H
         LA    R0,QM_0230              Mark the spot
         CLI   W_FIELDS,C'Y'           FIELDS  command performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,6(,R5)               Point past command
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
***********************************************************************
* Begin parsing FIELDS command                                        *
***********************************************************************
QM_0231  DS   0H
         LA    R0,QM_0231              Mark the spot
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1 (counter)
         ST    R5,W_ADDR               Save beginning address
         LR    R15,R5                  Load beginning address
***********************************************************************
* Determine field name length.                                        *
***********************************************************************
QM_0232  DS    0H
         LA    R0,QM_0232              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0233         ... yes, process
         C     R1,=F'16'               Exceed maximum field length?
         BC    B'0011',ER_40007        ... yes, syntax error
         LA    R1,1(,R1)               Increment field name length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0232              Continue evaluation
         BC    B'1111',ER_40007        EOF, syntax error
***********************************************************************
* Address FAxxFD table                                                *
***********************************************************************
QM_0233  DS    0H
         LA    R0,QM_0233              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         L     R7,FD_LEN               Load FD table length
         LA    R6,E_FD                 Load FD entry length
         S     R1,ONE                  Adjust before EX command
***********************************************************************
* Verify the field name is in FAxxFD                                  *
***********************************************************************
QM_0234  DS    0H
         LA    R0,QM_0234              Mark the spot
         LA    R14,F_NAME              Point to field name
         EX    R1,CLC_0234             Field name match?
         BC    B'1000',QM_0235         ... yes, process
         LA    R9,0(R6,R9)             Point to next FD entry
         SR    R7,R6                   Reduce total length by an entry
         BC    B'0010',QM_0234         Continue search
         MVC   C_FIELD,HEX_40          Move spaces to field name
         LA    R14,C_FIELD             Point to field name
         EX    R1,MVC_0234             Move field name to diagnostics
         BC    B'1111',ER_41202        ... EOF, syntax error
CLC_0234 CLC   0(0,R14),0(R15)         Check field name
MVC_0234 MVC   0(0,R14),0(R15)         Move  field name
*
***********************************************************************
* Move field name to parser array                                     *
***********************************************************************
QM_0235  DS    0H
         LA    R0,QM_0235              Mark the spot
         MVC   W_NAME,HEX_40           Clear field
         LA    R14,W_NAME              Point to field name
         EX    R1,MVC_0235             Set container name
*
         L     R8,PA_GM                Load parser array address
         USING PA_DSECT,R8             ... tell assembler
*
         LA    R7,E_PA                 Load parser array entry length
         XR    R6,R6                   Clear even register
         L     R1,W_INDEX              Load PA index
         MR    R6,R1                   Multiply by entry length
         LA    R8,0(R7,R8)             Point to current PA entry
*
         LA    R1,1(,R1)               Increment PA index
         ST    R1,W_INDEX              Save PA index
         C     R1,MAX_PA               PA index exceeded?
         BC    B'0010',ER_41404        ... yes, STATUS(414)
*
         MVI   P_WHERE,C'N'            Move WHERE indicator (no)
         MVC   P_NAME,F_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'1000',QM_0236         ... yes, prepare to parse
*
         CLI   0(R5),C')'              Close Parenthesis?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',QM_0500         When zero, parsing is complete
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        When zero, syntax error
         MVI   W_FIELDS,C'Y'           Set FIELDS command complete
         BC    B'1111',QM_0210         Continue parsing
*
MVC_0235 MVC   0(0,R14),0(R15)         Set container name
***********************************************************************
* Prepare to parse next FIELDS request                                *
***********************************************************************
QM_0236  DS   0H
         LA    R0,QM_0236              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         BC    B'1111',QM_0231         Continue with FIELDS
***********************************************************************
* WHERE  command                                                      *
***********************************************************************
QM_0240  DS   0H
         CLI   W_WHERE,C'Y'            WHERE  command performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,5(,R5)               Point past command
         S     R4,=F'05'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
***********************************************************************
* Begin parsing WHERE command                                         *
***********************************************************************
QM_0241  DS   0H
         LA    R0,QM_0241              Mark the spot
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1 (counter)
         ST    R5,W_ADDR               Save beginning address
         LR    R15,R5                  Load beginning address
***********************************************************************
* Determine field name length.                                        *
***********************************************************************
QM_0242  DS    0H
         LA    R0,QM_0242              Mark the spot
         CLI   0(R5),C'='              Equal sign (end of field)?
         BC    B'1000',QM_0243         ... yes, process
*
         CLI   0(R5),C'>'              Greater Than sign (EOF)?
         BC    B'1000',QM_0243         ... yes, process
*
         CLI   0(R5),C'+'              GTEQ sign (EOF)?
         BC    B'1000',QM_0243         ... yes, process
*
         C     R1,=F'16'               Exceed maximum field length?
         BC    B'0011',ER_40007        ... yes, syntax error
         LA    R1,1(,R1)               Increment field name length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0242              Continue evaluation
         BC    B'1111',ER_40007        EOF, syntax error
***********************************************************************
* Address FAxxFD table                                                *
***********************************************************************
QM_0243  DS    0H
         MVC   W_SIGN,0(R5)            Move type of sign (= > +)
         LA    R0,QM_0243              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         L     R7,FD_LEN               Load FD table length
         LA    R6,E_FD                 Load FD entry length
         S     R1,ONE                  Adjust before EX command
***********************************************************************
* Verify the field name is in FAxxFD                                  *
***********************************************************************
QM_0244  DS    0H
         LA    R0,QM_0244              Mark the spot
         LA    R14,F_NAME              Point to field name
         EX    R1,CLC_0244             Field name match?
         BC    B'1000',QM_0245         ... yes, process
         LA    R9,0(R6,R9)             Point to next FD entry
         SR    R7,R6                   Reduce total length by an entry
         BC    B'0010',QM_0244         Continue search
         BC    B'1111',ER_40007        EOF, syntax error
CLC_0244 CLC   0(0,R14),0(R15)         Check field name
***********************************************************************
* Move field name to parser array                                     *
***********************************************************************
QM_0245  DS    0H
         LA    R0,QM_0245              Mark the spot
         MVC   W_NAME,HEX_40           Clear field
         LA    R14,W_NAME              Point to field name
         EX    R1,MVC_0245             Set container name
*
         L     R8,PA_GM                Load parser array address
         USING PA_DSECT,R8             ... tell assembler
*
         LA    R7,E_PA                 Load parser array entry length
         XR    R6,R6                   Clear even register
         L     R1,W_INDEX              Load PA index
         MR    R6,R1                   Multiply by entry length
         LA    R8,0(R7,R8)             Point to current PA entry
*
         LA    R1,1(,R1)               Increment PA index
         ST    R1,W_INDEX              Save PA index
         C     R1,MAX_PA               PA index exceeded?
         BC    B'0010',ER_41405        ... yes, STATUS(414)
*
*        MVI   P_WHERE,C'Y'            Move WHERE indicator
         MVC   P_WHERE,W_SIGN          Move WHERE sign     to PA
*
         MVC   P_NAME,F_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
         BC    B'1111',QM_0246         Determine field length
MVC_0245 MVC   0(0,R14),0(R15)         Set container name
***********************************************************************
* Determine length of data for this field                             *
***********************************************************************
QM_0246  DS   0H
         LA    R0,QM_0246              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0247         ... yes, PUT CONTAINER
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment field length
         C     R1,MAX_LEN              Field length exceed maximum?
         BC    B'1000',ER_40007        ... yes, syntax error
         BCT   R4,QM_0246              Continue parsing
         BC    B'1111',ER_40007        Syntax error when zero
***********************************************************************
* Issue PUT CONTAINER for field data                                  *
***********************************************************************
QM_0247  DS   0H
         LA    R0,QM_0247              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         ST    R1,W_LENGTH             Save field length
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R0,QM_0247              Mark the spot
*
         CLC   0(3,R5),S_AND           AND clause?
         BC    B'1000',QM_0248         ... yes, adjust address/length
*
         CLI   0(R5),C','              Is this byte a comma?
         BC    B'1000',QM_0249         ... yes, adjust address/length
*
         CLI   0(R5),C')'              Close parenthesis?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',QM_0500         When zero, parsing is complete
         CLI   0(R5),C','              Is the next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        When zero, sytax error
         MVI   W_WHERE,C'Y'            Set WHERE  command complete
         BC    B'1111',QM_0210         Continue parsing
*
***********************************************************************
* AND clause on WHERE statement                                       *
***********************************************************************
QM_0248  DS   0H
         LA    R0,QM_0248              Mark the spot
         LA    R5,3(,R5)               Point to past AND
         S     R4,=F'3'                Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         BC    B'1111',QM_0241         Continue WHERE parsing
***********************************************************************
* Comma between WHERE statements                                      *
***********************************************************************
QM_0249  DS   0H
         LA    R0,QM_0249              Mark the spot
         LA    R5,1(,R5)               Point to past AND
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         BC    B'1111',QM_0241         Continue WHERE parsing
***********************************************************************
* OPTIONS command                                                     *
***********************************************************************
QM_0250  DS   0H
         CLI   W_OPTION,C'Y'           OPTIONS command performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,7(,R5)               Point past command
         S     R4,=F'07'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
***********************************************************************
* Begin parsing OPTIONS command                                       *
* Valid parameters are FORMAT, DISTINCT, MODE, SORT and ROWS.         *
***********************************************************************
QM_0251  DS   0H
         LA    R0,QM_0251              Mark the spot
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLC   0(6,R5),S_FORMAT        Is this a  FORMAT   parm?
         BC    B'1000',QM_0252         ... yes, process
         CLC   0(8,R5),S_DIST          Is this a  DISTINCT parm?
         BC    B'1000',QM_0253         ... yes, process
         CLC   0(4,R5),S_MODE          Is this a  MODE     parm?
         BC    B'1000',QM_0254         ... yes, process
         CLC   0(4,R5),S_SORT          Is this a  SORT     parm?
         BC    B'1000',QM_0255         ... yes, process
         CLC   0(4,R5),S_ROWS          Is this a  ROWS     parm?
         BC    B'1000',QM_0256         ... yes, process
         BC    B'1111',ER_40007        ... no,  syntax error
*
***********************************************************************
* FORMAT   parameter specified.                                       *
***********************************************************************
QM_0252  DS   0H
         LA    R0,QM_0252              Mark the spot
         CLI   W_FORM,C'Y'             FORMAT   parm performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,6(,R5)               Point past command
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C'='              Equal sign?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLC   0(5,R5),S_FIXED         FIXED format?
         BC    B'1000',QM_0252A        ... yes, continue
         CLC   0(3,R5),S_XML           XML format?
         BC    B'1000',QM_0252B        ... yes, continue
         CLC   0(4,R5),S_JSON          JSON format?
         BC    B'1000',QM_0252C        ... yes, continue
         CLC   0(9,R5),S_DELIM         DELIMITER format?
         BC    B'1000',QM_0252D        ... yes, continue
*
         BC    B'1111',ER_40007        ... no,  syntax error
***********************************************************************
* Move FIXED format parameter to OPTIONS table                        *
***********************************************************************
QM_0252A DS    0H
         LA    R0,QM_0252A             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,5(,R5)               Point to next byte
         S     R4,=F'05'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_FORM,C'Y'             Mark FORMAT   parm complete
         MVC   O_FORM,S_FIXED          Move FIXED parm
         BC    B'1111',QM_025X         Continue FORMAT parsing
*
***********************************************************************
* Move XML   format parameter to OPTIONS table                        *
***********************************************************************
QM_0252B DS    0H
         LA    R0,QM_0252B             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,3(,R5)               Point to next byte
         S     R4,=F'03'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_FORM,C'Y'             Mark FORMAT   parm complete
         MVC   O_FORM,S_XML            Move XML   parm
         BC    B'1111',QM_025X         Continue FORMAT parsing
*
***********************************************************************
* Move JSON  format parameter to OPTIONS table                        *
***********************************************************************
QM_0252C DS    0H
         LA    R0,QM_0252C             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,4(,R5)               Point to next byte
         S     R4,=F'04'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_FORM,C'Y'             Mark FORMAT   parm complete
         MVC   O_FORM,S_JSON           Move JSON  parm
         BC    B'1111',QM_025X         Continue FORMAT parsing
*
***********************************************************************
* Move DELIMITER format parameter to OPTIONS table                    *
***********************************************************************
QM_0252D DS    0H
         LA    R0,QM_0252D             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,9(,R5)               Point to next byte
         S     R4,=F'09'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_FORM,C'Y'             Mark FORMAT   parm complete
         MVC   O_FORM,S_DELIM          Move DELIMITER parm
         BC    B'1111',QM_025X         Continue FORMAT parsing
*
***********************************************************************
* DISTINCT parameter specified.                                       *
***********************************************************************
QM_0253  DS   0H
         LA    R0,QM_0253              Mark the spot
         CLI   W_DIST,C'Y'             DISTINCT parm performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,8(,R5)               Point past command
         S     R4,=F'08'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C'='              Equal sign?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLC   0(3,R5),S_YES           DISTINCT=YES?
         BC    B'1000',QM_0253A        ... yes, continue
         CLC   0(2,R5),S_NO            DISTINCT=NO?
         BC    B'1000',QM_0253B        ... yes, continue
*
         BC    B'1111',ER_40007        ... no,  syntax error
***********************************************************************
* Move DISTINCT=YES to OPTIONS table                                  *
***********************************************************************
QM_0253A DS    0H
         LA    R0,QM_0253A             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,3(,R5)               Point to next byte
         S     R4,=F'03'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_DIST,C'Y'             Mark DISTINCT parm complete
         MVC   O_DIST,S_YES            Move DISTINCT=YES
         BC    B'1111',QM_025X         Continue FORMAT parsing
***********************************************************************
* Move DISTINCT=NO  to OPTIONS table                                  *
***********************************************************************
QM_0253B DS    0H
         LA    R0,QM_0253B             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,2(,R5)               Point to next byte
         S     R4,=F'02'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_DIST,C'Y'             Mark DISTINCT parm complete
         MVC   O_DIST,S_NO             Move DISTINCT=NO
         BC    B'1111',QM_025X         Continue FORMAT parsing
***********************************************************************
* MODE parameter specified.                                           *
***********************************************************************
QM_0254  DS   0H
         LA    R0,QM_0254              Mark the spot
         CLI   W_MODE,C'Y'             MODE     parm performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,4(,R5)               Point past command
         S     R4,=F'04'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C'='              Equal sign?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLC   0(6,R5),S_ON            MODE=ONLINE?
         BC    B'1000',QM_0254A        ... yes, continue
         CLC   0(7,R5),S_OFF           MODE=OFFLINE?
         BC    B'1000',QM_0254B        ... yes, continue
*
         BC    B'1111',ER_40007        ... no,  syntax error
***********************************************************************
* Move MODE=ONLINE  to OPTIONS table                                  *
***********************************************************************
QM_0254A DS    0H
         LA    R0,QM_0254A             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,6(,R5)               Point to next byte
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_MODE,C'Y'             Mark MODE     parm complete
         MVC   O_MODE,S_ON             Move MODE=ONLINE
         BC    B'1111',QM_025X         Continue FORMAT parsing
***********************************************************************
* Move MODE=OFLINE  to OPTIONS table                                  *
***********************************************************************
QM_0254B DS    0H
         LA    R0,QM_0254B             Mark the spot
         ST    R5,W_ADDR               Save current pointer address
         LA    R5,7(,R5)               Point to next byte
         S     R4,=F'07'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         CLI   0(R5),C')'              End bracket?
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         MVI   W_MODE,C'Y'             Mark MODE     parm complete
         MVC   O_MODE,S_OFF            Move MODE=OFFLINE
         BC    B'1111',QM_025X         Continue FORMAT parsing
***********************************************************************
* SORT parameter specified.                                           *
***********************************************************************
QM_0255  DS   0H
         LA    R0,QM_0255              Mark the spot
         CLI   W_SORT,C'Y'             SORT     parm performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,4(,R5)               Point past command
         S     R4,=F'04'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C'='              Equal sign?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
***********************************************************************
* Determine field name length for SORT                                *
***********************************************************************
QM_0255A DS   0H
         LA    R0,QM_0255A             Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0255B        ... yes, move to OPTIONS table
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment field name length
         C     R1,MAX_LEN              Field length exceed maximum?
         BC    B'1000',ER_40007        ... yes, syntax error
         BCT   R4,QM_0255A             Continue parsing
         BC    B'1111',ER_40007        Syntax error when zero
***********************************************************************
* Move field name to SORT entry of OPTIONS table                      *
***********************************************************************
QM_0255B DS   0H
         LA    R0,QM_0255B             Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         S     R1,=F'1'                Adjust field length
         L     R15,W_ADDR              Load field data address
         LA    R14,O_SORT              Load SORT field name
         EX    R1,MVC_0255             ... and move to OPTIONS table
*
         MVI   W_SORT,C'Y'             Mark MODE     parm complete
         BC    B'1111',QM_025X         Continue FORMAT parsing
*
MVC_0255 MVC   0(0,R14),0(R15)         Move field to OPTIONS table
*
***********************************************************************
* ROWS parameter specified.                                           *
***********************************************************************
QM_0256  DS   0H
         LA    R0,QM_0256              Mark the spot
         CLI   W_ROWS,C'Y'             ROWS     parm performed?
         BC    B'1000',ER_40007        ... yes, syntax error
*
         LA    R5,4(,R5)               Point past command
         S     R4,=F'04'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C'='              Equal sign?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
***********************************************************************
* Determine value of ROWS= parameter                                  *
***********************************************************************
QM_0256A DS   0H
         LA    R0,QM_0256A             Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0256B        ... yes, move to OPTIONS table
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment ROWS value length
         C     R1,=F'6'                Value exceed maximum?
         BC    B'1000',ER_40007        ... yes, syntax error
         BCT   R4,QM_0256A             Continue parsing
         BC    B'1111',ER_40007        Syntax error when zero
***********************************************************************
* Move value to ROWS entry of OPTIONS table                           *
***********************************************************************
QM_0256B DS   0H
         LA    R0,QM_0256B             Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         LA    R15,6                   Load max ROWS field length
         SR    R15,R1                  Subtract length
         LA    R14,O_ROWS              Load ROWS address in Object
         LA    R14,0(R15,R14)          Set target field
         L     R15,W_ADDR              Set source field
         S     R1,=F'1'                Adjust for MVC
         EX    R1,MVC_0256             Move ROWS to Oject table
*
         MVI   W_ROWS,C'Y'             Mark ROWS     parm complete
         BC    B'1111',QM_025X         Continue FORMAT parsing
*
MVC_0256 MVC   0(0,R14),0(R15)         Move ROWS to ZD work field
*
***********************************************************************
* When a comma is the next byte, continue with FORMAT parsing         *
***********************************************************************
QM_025X  DS    0H
         LA    R0,QM_025X              Mark the spot
         CLI   0(R5),C','              Comma?
         BC    B'0111',QM_025Z         ... no,  continue
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         BC    B'1111',QM_0251         Get next OPTIONS parm
***********************************************************************
* When a end parenthesis is the next byte,                            *
*   1).  When EOQS, parsing is complete                               *
*   2).  When not EOQS, continue SELECT parsing                       *
***********************************************************************
QM_025Z  DS    0H
         LA    R0,QM_025Z              Mark the spot
         CLI   0(R5),C')'              Close parenthesis
         BC    B'0111',ER_40007        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1000',QM_0500         When zero, parsing complete
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
         BC    B'1111',QM_0210         Continue parsing
*
***********************************************************************
* Parse PUT    request, using WEB RECEIVE input                       *
***********************************************************************
QM_0300  DS   0H
         L     R4,R_LENGTH             Load RECEIVE length
         L     R5,WR_ADDR              Load RECEIVE address
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(6,R5),S_UPDATE        Is this an UPDATE command?
         BC    B'0111',ER_40503        ... no,  invalid command
         LA    R5,6(,R5)               Point to next byte
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40007        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40007        Syntax error when EOQS
***********************************************************************
* Check PUT    request for zQL commands.                              *
* Valid commands are FIELDS, TTL and WHERE.                           *
***********************************************************************
QM_0310  DS   0H
         LA    R0,QM_0310              Mark the spot
         CLI   0(R5),C'('              Open parenthesis?
         BC    B'0111',ER_40008        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(3,R5),S_TTL           Is this a TTL    command?
         BC    B'1000',QM_0320         ... yes, process
         CLC   0(6,R5),S_FIELDS        Is this a FIELDS command?
         BC    B'1000',QM_0330         ... yes, process
         CLC   0(5,R5),S_WHERE         Is this a WHERE  command?
         BC    B'1000',QM_0340         ... yes, process
         BC    B'1000',ER_40008        ... no,  syntax error
***********************************************************************
* Process TTL command                                                 *
***********************************************************************
QM_0320  DS   0H
         CLI   W_TTL,C'Y'              TTL   command performed?
         BC    B'1000',ER_40008        ... yes, syntax error
***********************************************************************
* Begin parsing TTL command                                           *
***********************************************************************
QM_0321  DS   0H
         LA    R0,QM_0321              Mark the spot
         LA    R5,3(,R5)               Point past command
         S     R4,=F'03'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40008        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
         XR    R1,R1                   Clear counter
         ST    R5,W_ADDR               Save beginning TTL address
         LR    R15,R5                  Load beginning TTL address
***********************************************************************
* Determine length of TTL and perform editing.                        *
***********************************************************************
QM_0322  DS   0H
         LA    R0,QM_0322              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0323         ... yes, continue process
         CLI   0(R5),X'F0'             Compare TTL byte to zero
         BC    B'0100',ER_40008        ... when less, syntax error
         CLI   0(R5),X'FA'             Compare TTL byte to FA+
         BC    B'1010',ER_40008        ... when more, syntax error
         C     R1,=F'5'                Maximum TTL length?
         BC    B'0010',ER_40008        ... yes, syntax error
*
         LA    R1,1(,R1)               Increment TTL length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0322              Continue parsing
         BC    B'1100',ER_40008        Syntax error when EOQS
***********************************************************************
* Issue PUT CONTAINER for TTL field                                   *
***********************************************************************
QM_0323  DS   0H
         LA    R0,QM_0323              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         CLI   0(R5),C')'              Close parenthesis?
         BC    B'0111',ER_40008        ... no,  syntax error
*
         MVI   W_TTL,C'Y'              Mark TTL command complete
*
         MVC   W_NAME,C_TTL            Move TTL container name
         ST    R1,W_LENGTH             Save data length
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R0,QM_0323              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1000',QM_0500         When zero, parsing complete
*
         CLI   0(R5),C','              Comma?
         BC    B'0111',ER_40008        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
         BC    B'1111',QM_0310         Continue PUT  parsing
***********************************************************************
* FIELDS command                                                      *
***********************************************************************
QM_0330  DS   0H
         CLI   W_FIELDS,C'Y'           FIELDS  command performed?
         BC    B'1000',ER_40008        ... yes, syntax error
*
         LA    R5,6(,R5)               Point past command
         S     R4,=F'06'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
***********************************************************************
* Begin parsing FIELDS command                                        *
***********************************************************************
QM_0331  DS   0H
         LA    R0,QM_0331              Mark the spot
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40008        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1 (counter)
         ST    R5,W_ADDR               Save beginning address
         LR    R15,R5                  Load beginning address
***********************************************************************
* Determine field name length.                                        *
***********************************************************************
QM_0332  DS    0H
         LA    R0,QM_0332              Mark the spot
         CLI   0(R5),C'='              Equal sign (end of field)?
         BC    B'1000',QM_0333         ... yes, process
         C     R1,=F'16'               Exceed maximum field length?
         BC    B'0011',ER_40008        ... yes, syntax error
         LA    R1,1(,R1)               Increment field name length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0332              Continue evaluation
         BC    B'1111',ER_40008        EOF, syntax error
***********************************************************************
* Address FAxxFD table                                                *
***********************************************************************
QM_0333  DS    0H
         LA    R0,QM_0332              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         L     R7,FD_LEN               Load FD table length
         LA    R6,E_FD                 Load FD entry length
         S     R1,ONE                  Adjust before EX command
***********************************************************************
* Verify the field name is in FAxxFD                                  *
***********************************************************************
QM_0334  DS    0H
         LA    R0,QM_0334              Mark the spot
         LA    R14,F_NAME              Point to field name
         EX    R1,CLC_0334             Field name match?
         BC    B'1000',QM_0335         ... yes, process
         LA    R9,0(R6,R9)             Point to next FD entry
         SR    R7,R6                   Reduce total length by an entry
         BC    B'0010',QM_0334         Continue search
         MVC   C_FIELD,HEX_40          Move spaces to field name
         LA    R14,C_FIELD             Point to field name
         EX    R1,MVC_0334             Move field name to diagnostics
         BC    B'1111',ER_41203        ... EOF, syntax error
CLC_0334 CLC   0(0,R14),0(R15)         Check field name
MVC_0334 MVC   0(0,R14),0(R15)         Move  field name
*
***********************************************************************
* Move field name to parser array                                     *
***********************************************************************
QM_0335  DS    0H
         LA    R0,QM_0335              Mark the spot
         MVC   W_NAME,HEX_40           Clear field
         LA    R14,W_NAME              Point to field name
         EX    R1,MVC_0335             Set container name
*
         L     R8,PA_GM                Load parser array address
         USING PA_DSECT,R8             ... tell assembler
*
         LA    R7,E_PA                 Load parser array entry length
         XR    R6,R6                   Clear even register
         L     R1,W_INDEX              Load PA index
         MR    R6,R1                   Multiply by entry length
         LA    R8,0(R7,R8)             Point to current PA entry
*
         LA    R1,1(,R1)               Increment PA index
         ST    R1,W_INDEX              Save PA index
         C     R1,MAX_PA               PA index exceeded?
         BC    B'0010',ER_41406        ... yes, STATUS(414)
*
         MVC   P_NAME,F_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
         BC    B'1111',QM_0336         Determine field length
MVC_0335 MVC   0(0,R14),0(R15)         Set container name
***********************************************************************
* Determine length of data for this field                             *
***********************************************************************
QM_0336  DS   0H
         LA    R0,QM_0336              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0337         ... yes, PUT CONTAINER
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment field length
         C     R1,MAX_LEN              Field length exceed maximum?
         BC    B'1000',ER_40008        ... yes, syntax error
         BCT   R4,QM_0336              Continue parsing
         BC    B'1111',ER_40008        Syntax error when zero
***********************************************************************
* Issue PUT CONTAINER for this data field                             *
***********************************************************************
QM_0337  DS   0H
         LA    R0,QM_0337              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         ST    R1,W_LENGTH             Save field length
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R0,QM_0337              Mark the spot
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'1000',QM_0338         ... yes, prepare to parse
*
         CLI   0(R5),C')'              Close Parenthesis?
         BC    B'0111',ER_40008        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',QM_0500         When zero, parsing is complete
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40008        ... yes, prepar to parse
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40008        When zero, syntax error
         MVI   W_FIELDS,C'Y'           Set FIELDS command complete
         BC    B'1111',QM_0310         Continue parsing
*
***********************************************************************
* Prepare to parse next FIELDS request                                *
***********************************************************************
QM_0338  DS   0H
         LA    R0,QM_0336              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
         BC    B'1111',QM_0331         Continue with FIELDS
***********************************************************************
* WHERE  command                                                      *
***********************************************************************
QM_0340  DS   0H
         CLI   W_WHERE,C'Y'            WHERE  command performed?
         BC    B'1000',ER_40008        ... yes, syntax error
*
         LA    R5,5(,R5)               Point past command
         S     R4,=F'05'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
***********************************************************************
* Begin parsing WHERE command                                         *
***********************************************************************
QM_0341  DS   0H
         LA    R0,QM_0341              Mark the spot
         CLI   0(R5),C'('              Begin bracket?
         BC    B'0111',ER_40008        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1 (counter)
         ST    R5,W_ADDR               Save beginning address
         LR    R15,R5                  Load beginning address
***********************************************************************
* Determine field name length.                                        *
***********************************************************************
QM_0342  DS    0H
         LA    R0,QM_0342              Mark the spot
         CLI   0(R5),C'='              Equal sign (end of field)?
         BC    B'1000',QM_0343         ... yes, process
         C     R1,=F'16'               Exceed maximum field length?
         BC    B'0011',ER_40008        ... yes, syntax error
         LA    R1,1(,R1)               Increment field name length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0342              Continue evaluation
         BC    B'1111',ER_40008        EOF, syntax error
***********************************************************************
* Address FAxxFD table                                                *
***********************************************************************
QM_0343  DS    0H
         LA    R0,QM_0343              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         L     R7,FD_LEN               Load FD table length
         LA    R6,E_FD                 Load FD entry length
         S     R1,ONE                  Adjust before EX command
***********************************************************************
* Verify the field name is in FAxxFD                                  *
***********************************************************************
QM_0344  DS    0H
         LA    R0,QM_0344              Mark the spot
         LA    R14,F_NAME              Point to field name
         EX    R1,CLC_0344             Field name match?
         BC    B'1000',QM_0345         ... yes, process
         LA    R9,0(R6,R9)             Point to next FD entry
         SR    R7,R6                   Reduce total length by an entry
         BC    B'0010',QM_0344         Continue search
         BC    B'1111',ER_40008        EOF, syntax error
CLC_0344 CLC   0(0,R14),0(R15)         Check field name
***********************************************************************
* Move field name to parser array                                     *
***********************************************************************
QM_0345  DS    0H
         MVC   W_NAME,HEX_40           Clear field
         LA    R14,W_NAME              Point to field name
         EX    R1,MVC_0345             Set container name
*
         L     R8,PA_GM                Load parser array address
         USING PA_DSECT,R8             ... tell assembler
*
         LA    R7,E_PA                 Load parser array entry length
         XR    R6,R6                   Clear even register
         L     R1,W_INDEX              Load PA index
         MR    R6,R1                   Multiply by entry length
         LA    R8,0(R7,R8)             Point to current PA entry
*
         LA    R1,1(,R1)               Increment PA index
         ST    R1,W_INDEX              Save PA index
         C     R1,MAX_PA               PA index exceeded?
         BC    B'0010',ER_41407        ... yes, STATUS(414)
*
         MVC   P_NAME,F_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
         BC    B'1111',QM_0346         Determine field length
MVC_0345 MVC   0(0,R14),0(R15)         Set container name
***********************************************************************
* Determine length of data for this field                             *
***********************************************************************
QM_0346  DS    0H
         LA    R0,QM_0346              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0347         ... yes, PUT CONTAINER
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment field length
         C     R1,MAX_LEN              Field length exceed maximum?
         BC    B'1000',ER_40008        ... yes, syntax error
         BCT   R4,QM_0336              Continue parsing
         BC    B'1111',ER_40008        Syntax error when zero
***********************************************************************
* Issue PUT CONTAINER for this data field                             *
***********************************************************************
QM_0347  DS   0H
         LA    R0,QM_0337              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'01'               Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
*
         ST    R1,W_LENGTH             Save field length
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R0,QM_0347              Mark the spot
*
         CLI   0(R5),C')'              Close parenthesis?
         BC    B'0111',ER_40008        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',QM_0500         When zero, parsing complete
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40008        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40008        Syntax error when EOQS
         MVI   W_WHERE,C'Y'            Set WHERE  command complete
         BC    B'1111',QM_0310         Continue parsing
*
***********************************************************************
* Parse DELETE request, using the Query String                        *
* Since the WEB EXTRACT command moves the Query String 'into' an area *
* instead of setting a pointer, only a three byte area is defined for *
* the EXTRACT command.  The three bytes are used to determine whether *
* the request is basic mode or query mode (zQL).  When query mode,    *
* parse the DFHCOMMAREA for the beginning of the query string and     *
* save the pointer address.  This reduces the amount of DFHEISTG      *
* storage required for the Query String and eliminates a GETMAIN.     *
***********************************************************************
QM_0400  DS   0H
         LA    R0,QM_0400              Mark the spot
         BAS   R14,CA_0010             Parse DFHCOMMAREA for QS
         USING DFHCA,R5                ... tell assembler
         L     R4,L_QUERY              Load query string length
         LA    R5,3(,R5)               Skip past the zQL command
         S     R4,=F'3'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40009        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         OC    0(6,R5),HEX_40          Set upper case bits
         CLC   0(6,R5),S_DELETE        Is this a DELETE command?
         BC    B'0111',ER_40504        ... no,  invalid command
         LA    R5,6(,R5)               Point to next byte
         S     R4,=F'6'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         CLI   0(R5),C','              Is next byte a comma?
         BC    B'0111',ER_40009        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         CLI   0(R5),C'('              Open parenthesis?
         BC    B'0111',ER_40009        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         OC    0(5,R5),HEX_40          Set upper case bits
         CLC   0(5,R5),S_WHERE         Is this a WHERE statement?
         BC    B'0111',ER_40009        ... no,  syntax error
         LA    R5,5(,R5)               Point to next byte
         S     R4,=F'5'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         CLI   0(R5),C'('              Begin Bracket?
         BC    B'0111',ER_40009        ... no,  syntax error
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field name address
         LR    R15,R5                  Load field name address
***********************************************************************
* Determine primary key field length                                  *
***********************************************************************
QM_0410  DS   0H
         LA    R0,QM_0410              Mark the spot
         CLI   0(R5),C'='              Equal sign (end of field)?
         BC    B'1000',QM_0420         ... yes, continue
         C     R1,=F'16'               Exceed maximum field length?
         BC    B'0011',ER_40009        ... yes, syntax error
         LA    R1,1(,R1)               Add one to field length
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,QM_0410              Continue parsing
         BC    B'1111',ER_40009        EOF, syntax error
***********************************************************************
* Address FAxxFD table.                                               *
* Validate  primary key field selected.                               *
***********************************************************************
QM_0420  DS   0H
         LA    R0,QM_0420              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error wehn EOQS
*
         L     R9,FD_GM                Load FAxxFD address
         USING FD_DSECT,R9             ... tell assembler
         S     R1,ONE                  Adjust before EX command
         LA    R14,F_NAME              Point to field name
         EX    R1,CLC_0420             Primary key selected?
         BC    B'0111',ER_40009        ... no,  syntax error
*
         MVC   W_NAME,HEX_40           Clear field
         LA    R14,W_NAME              Point to field name
         EX    R1,MVC_0420             Set container name
*
         L     R8,PA_GM                Load parser array address
         USING PA_DSECT,R8             ... tell assembler
         MVC   P_NAME,W_NAME           Move field name     to PA
         MVC   P_TYPE,F_TYPE           Move field type     to PA
         PACK  P_SEC,F_SEC             Pack field security to PA
         PACK  P_ID,F_ID               Pack field ID       to PA
         PACK  P_COL,F_COL             Pack field column   to PA
         PACK  P_LEN,F_LEN             Pack field length   to PA
         MVC   W_INDEX,=F'1'           Set PA index to one
*
         XR    R1,R1                   Clear R1
         ST    R5,W_ADDR               Save field data address
         BC    B'1111',QM_0430         Determine field length
CLC_0420 CLC   0(0,R14),0(R15)         Check field name
MVC_0420 MVC   0(0,R14),0(R15)         Move  field name
***********************************************************************
* Determine length of primary key data                                *
***********************************************************************
QM_0430  DS   0H
         LA    R0,QM_0430              Mark the spot
         CLI   0(R5),C')'              End bracket?
         BC    B'1000',QM_0440         ... yes, PUT CONTAINER
         LA    R5,1(,R5)               Point to next byte
         LA    R1,1(,R1)               Increment field length
         C     R1,MAX_LEN              Field length exceed maximum?
         BC    B'1010',ER_40009        ... yes, syntax error
         BCT   R4,QM_0430              Continue parse
         BC    B'1111',ER_40009        Syntax error when zero
***********************************************************************
* Issue PUT CONTAINER for primary key field                           *
***********************************************************************
QM_0440  DS   0H
         LA    R0,QM_0440              Mark the spot
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',ER_40009        Syntax error when EOQS
*
         ST    R1,W_LENGTH             Save data length
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R0,QM_0440              Mark the spot
         CLI   0(R5),C')'              Close parenthesis?
         BC    B'0111',ER_40009        ... no,  syntax error
*
         LA    R5,1(,R5)               Point to next byte
         S     R4,=F'1'                Adjust remaining length
         BC    B'1100',QM_0500         When zero, parsing is complete
         BC    B'0011',ER_40009        Syntax error when more available
*
***********************************************************************
* Issue PUT CONTAINER for parsing array                               *
***********************************************************************
QM_0500  DS   0H
         MVC   W_NAME,C_ARRAY          Move ARRAY   container name
         MVC   W_ADDR,PA_GM            Move parser array address
*
         LA    R7,E_PA                 Load parser array entry length
         XR    R6,R6                   Clear even register
         L     R1,W_INDEX              Load PA index
         MR    R6,R1                   Multiply by entry length
         ST    R7,W_LENGTH             Save parser array length
*
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
***********************************************************************
* Issue PUT CONTAINER for Options table                               *
***********************************************************************
QM_0510  DS   0H
         MVC   W_NAME,C_OPTION         Move OPTIONS container name
         LA    R1,E_TABLE              Load OPTIONS table length
         ST    R1,W_LENGTH             Save OPTIONS table length
*
         LA    R6,O_TABLE              Load OPTIONS table address
         ST    R6,W_ADDR               Save OPTIONS table adress
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
***********************************************************************
***********************************************************************
* Query Security process.                                             *
***********************************************************************
***********************************************************************
QS_0010  DS   0H
         DROP  R9                      ... tell assembler
         CLI   W_PREFIX,X'FF'          URI '/replicate' prefix?
         BC    B'1000',QS_0400         ... yes, bypass security
*
         L     R9,SD_GM                Load FAxxSD address
         USING SD_DSECT,R9             ... tell assembler
         CLC   W_SCHEME,DFHVALUE(HTTP) HTTP request?
         BC    B'1000',QS_0100         ... yes, execute HTTP  security
         BC    B'0111',QS_0200         ... no,  execute HTTPS security
***********************************************************************
* SCHEME is HTTP.   Determine appropriate action                      *
***********************************************************************
QS_0100  DS   0H
         CLC   W_METHOD(3),S_GET       GET request?
         BC    B'0111',QS_0120         ... no,  check other methods
***********************************************************************
* SCHEME is HTTP  and this is a GET request                           *
***********************************************************************
QS_0110  DS   0H
         OC    SD_RESP,SD_RESP         FAxxSD defined?
         BC    B'0111',QS_0400         ... no,  bypass security
         OC    Q_STATUS,HEX_40         Set upper case bits
         CLC   Q_STATUS,S_YEA          QM Read Only enabled?
         BC    B'1000',QS_0400         ... yes, bypass security
         BC    B'0111',ER_40111        ... no,  STATUS(401)
***********************************************************************
* SCHEME is HTTP  and this is a PUT, POST, DELETE request             *
***********************************************************************
QS_0120  DS   0H
         OC    SD_RESP,SD_RESP         FAxxSD defined?
         BC    B'1000',ER_40112        ... yes, STATUS(401)
         BC    B'0111',QS_0400         ... no,  bypass security
***********************************************************************
* SCHEME is HTTPS.  Determine appropriate action                      *
***********************************************************************
QS_0200  DS   0H
         OC    SD_RESP,SD_RESP         FAxxSD defined?
         BC    B'0111',QS_0400         ... no,  bypass security
*
         LA    R4,E_USER               Load user  entry length
         L     R5,SD_LEN               Load SD template length
         LA    R6,E_PREFIX             Load SD prefix length
         SR    R5,R6                   Subtract prefix length
         AR    R9,R6                   Point to User entry
         USING SD_USER,R9              ... tell assembler
***********************************************************************
* Parse SD entry until EOT or a UserID match                          *
***********************************************************************
QS_0210  DS   0H
         CLC   S_USER,C_USER           UserID match FAxxSD?
         BC    B'1000',QS_0220         ... yes, check request type
QS_0211  DS   0H
         LA    R9,0(R4,R9)             Point to next entry
         SR    R5,R4                   Subtract user entry length
         BC    B'0010',QS_0210         Continue search
         BC    B'1111',ER_40113        EOT, STATUS(401)
***********************************************************************
* UserID matches FAxxSD entry.                                        *
* Now check HTTP METHOD and branch to compare with security entry     *
***********************************************************************
QS_0220  DS   0H
         OC    S_TYPE,HEX_40           Set upper case bits
         CLC   W_METHOD(4),S_POST      POST   request?
         BC    B'1000',QS_0221         ... yes, check SD type
         CLC   W_METHOD(3),S_GET       GET    request?
         BC    B'1000',QS_0222         ... yes, check SD type
         CLC   W_METHOD(3),S_PUT       PUT    request?
         BC    B'1000',QS_0223         ... yes, check SD type
         CLC   W_METHOD(6),S_DELETE    DELETE request?
         BC    B'1000',QS_0224         ... yes, check SD type
         BC    B'0111',ER_40005        ... no,  WEB SEND STATUS(400)
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* POST   must match security type of 'Write '                         *
***********************************************************************
QS_0221  DS   0H
         CLC   S_TYPE,S_WRITE          Security entry for 'Write'?
         BC    B'0111',QS_0211         ... no,  continue search
         BC    B'1111',QS_0300         ... yes, field level security
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* GET    must match security type of 'Read  '                         *
***********************************************************************
QS_0222  DS   0H
         CLC   S_TYPE,S_READ           Security entry for 'Read'?
         BC    B'0111',QS_0211         ... no,  continue search
         BC    B'1111',QS_0300         ... yes, field level security
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* PUT    must match security type of 'Write '                         *
***********************************************************************
QS_0223  DS   0H
         CLC   S_TYPE,S_WRITE          Security entry for 'Write'?
         BC    B'0111',QS_0211         ... no,  continue search
         BC    B'1111',QS_0300         ... yes, field level security
***********************************************************************
* FAxxSD security entry must match HTTP METHOD                        *
* DELETE must match security type of 'Delete'                         *
***********************************************************************
QS_0224  DS   0H
         CLC   S_TYPE,S_DELETE         Security entry for 'Delete'?
         BC    B'0111',QS_0211         ... no,  continue search
         BC    B'1111',QS_0300         ... yes, field level security
***********************************************************************
* At this point, the Parser Array has every field presented in the    *
* zQL request along with the security level.                          *
* Compare the UserID security level with each field level in the      *
* Parser Array.                                                       *
***********************************************************************
QS_0300  DS   0H
         L     R4,W_INDEX              Load PA index (# of entries)
         LA    R6,E_PA                 Load PA entry length
         L     R8,PA_GM                Load PA entry address
         LTR   R9,R9                   R9 points to current UserID
***********************************************************************
* The field security level is in the Parser Array.  Use this security *
* level as a displacement into the UserID security level array.       *
***********************************************************************
QS_0310  DS   0H
         LA    R5,S_LEVELS             Load UserID security levels
         ZAP   W_PACK,P_SEC            Pack field security level
         CVB   R7,W_PACK               Convert to index
         LA    R5,0(R7,R5)             Point to UserID security byte
         OI    0(R5),X'40'             Set upper case
         CLI   0(R5),C'X'              Field level permitted?
         BC    B'0111',ER_40114        ... no,  set reason code
         LA    R8,0(R6,R8)             Point to next PA entry
         BCT   R4,QS_0310              Continue PA scan
         BC    B'1111',QS_0400         CI and segment validation
***********************************************************************
* Check method and branch accordingly to set the appropriate          *
* Query Mode service program.                                         *
***********************************************************************
QS_0400  DS   0H
         CLC   W_METHOD(4),S_POST      POST   request?
         BC    B'1000',QS_0410         ... yes, set service name
         CLC   W_METHOD(3),S_GET       GET    request?
         BC    B'1000',QS_0420         ... yes, set service name
         CLC   W_METHOD(3),S_PUT       PUT    request?
         BC    B'1000',QS_0430         ... yes, set service name
         CLC   W_METHOD(6),S_DELETE    DELETE request?
         BC    B'1000',QS_0440         ... yes, set service name
***********************************************************************
* Query Mode POST   service program                                   *
***********************************************************************
QS_0410  DS   0H
         MVC   W_ADDR,FD_GM            Move FAxxFD address
         MVC   W_LENGTH,FD_LEN         Move FAxxFD length
         MVC   W_NAME,C_FAXXFD         Move FAxxFD container name
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         LA    R1,R_MEDIA              Load media address
         ST    R1,W_ADDR               Save media address
         MVC   W_LENGTH,L_MEDIA        Move media length
         MVC   W_NAME,C_MEDIA          Move media container name
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         MVC   QM_PROG,ZFAM010         Set Query Mode POST   program
         BC    B'1111',QS_0500         Branch to XCTL routine
***********************************************************************
* Query Mode GET    service program                                   *
* Use Column Index indicator, which is set to 0 or 1, as the          *
* program suffix.  The CI indicator is set when a WHERE statement     *
* specifies a secondary column index.                                 *
***********************************************************************
QS_0420  DS   0H
         BAS   R14,QS_0480             Scan PA for column index
*
         MVC   QM_PROG,ZFAM020         Set Query Mode GET    program
         MVC   QM_PROG+6(1),W_CI       Set CI indicator
         BC    B'1111',QS_0500         Branch to XCTL routine
***********************************************************************
* Query Mode PUT    service program                                   *
*                                                                     *
* Check the fields in the parser array for the following conditions   *
*                                                                     *
* 1).  Field larger than 32,000                                       *
* 2).  Field spans a 32,000 byte segment                              *
* *).  Update to a secondary column index                             *
*                                                                     *
* If any of these conditions occur for a PUT request, control is      *
* transferred to a Query Mode program to handle spanned segment       *
* records.                                                            *
***********************************************************************
QS_0430  DS   0H
         DROP  R9                      ... tell assemmbler
         LA    R4,E_PA                 Load Parser Array entry length
         L     R5,W_INDEX              Load Parser Array index (count)
         L     R8,PA_GM                Load Parser Array address
         USING PA_DSECT,R8             ... tell assembler
***********************************************************************
* When a secondary CI is updated, branch to XCTL routine.             *
* segments.                                                           *
***********************************************************************
QS_0431  DS   0H
         XR    R6,R6                   Clear R6
         ZAP   W_COLUMN,P_COL          Load column number
         CVB   R7,W_COLUMN             Convert column to binary
         D     R6,=F'32000'            Divide column by segment size
*                                      Giving relative segment
         XR    R6,R6                   Clear R6
         M     R6,=F'32000'            Multiply by segment size
*                                      Giving segment displacement
         CVB   R6,W_COLUMN             Convert column to binary
         SR    R6,R7                   Subtract segment displacement
*                                      from column giving
*                                      relative displacement
         S     R7,=F'1'                Make relative to zero
         ZAP   W_PACK,P_LEN            Load field length
         CVB   R7,W_PACK               Convert length to binary
         AR    R6,R7                   Add field length to relative
*                                      displacement giving width
         C     R6,=F'32000'            Width greater than a segment?
         BC    B'0010',QS_0434         ... branch when spanned segment
*
***********************************************************************
* Point to parser array entry and continue to scan                    *
***********************************************************************
QS_0432  DS   0H
         LA    R8,0(R4,R8)             Point to next entry
         BCT   R5,QS_0431              Continue parser array scan
         BC    B'1111',QS_0433         EOT,  no spanned segments
***********************************************************************
* Query Mode PUT    service program                                   *
***********************************************************************
QS_0433  DS   0H
         MVC   QM_PROG,ZFAM030         Set Query Mode PUT    program
         BC    B'1111',QS_0500         Branch to XCTL routine
***********************************************************************
* Query Mode PUT    service program for these conditions:             *
* Secondary CI updates                                                *
* Updated fields span segments                                        *
***********************************************************************
QS_0434  DS   0H
         MVC   QM_PROG,ZFAM030         Set Query Mode PUT    program
         BC    B'1111',QS_0500         Branch to XCTL routine
***********************************************************************
* Query Mode DELETE service program                                   *
***********************************************************************
QS_0440  DS   0H
         MVC   W_ADDR,FD_GM            Move FAxxFD address
         MVC   W_LENGTH,FD_LEN         Move FAxxFD length
         MVC   W_NAME,C_FAXXFD         Move FAxxFD container name
         BAS   R14,PC_0010             Issue PUT CONTAINER
*
         MVC   QM_PROG,ZFAM040         Set Query Mode DELETE program
         BC    B'1111',QS_0500         Branch to XCTL routine
***********************************************************************
* Check the fields in the Parser Array for any CI definitions in a    *
* WHERE statement.                                                    *
***********************************************************************
QS_0480  DS   0H
         ST    R14,BAS_REG             Save return register
*
         LA    R4,E_PA                 Load Parser Array entry length
         L     R5,W_INDEX              Load Parser Array index (count)
         L     R8,PA_GM                Load Parser Array address
         USING PA_DSECT,R8             ... tell assembler
         MVI   W_CI,C'0'               Set CI indicator off
***********************************************************************
* Check fiels for WHERE indicator and when the field is a secondary   *
* column index, mark it.                                              *
***********************************************************************
QS_0481  DS   0H
         CLI   P_WHERE,C'N'            WHERE indicator set?
         BC    B'1000',QS_0482         ... no,  must be a FIELD
         CP    P_ID,S_ONE_PD           Primary CI or field?
         BC    B'1100',QS_0482         ... yes, continue
         MVI   W_CI,C'1'               Set CI indicator on
***********************************************************************
* Point to parser array entry and continue to scan                    *
***********************************************************************
QS_0482  DS   0H
         LA    R8,0(R4,R8)             Point to next entry
         BCT   R5,QS_0481              Continue parser array scan
         CLI   W_CI,C'1'               Secondary CI indicator set?
         BC    B'0100',QS_0489         ... no,  bypass HTTP header
*
***********************************************************************
* Read HTTPHEADER for zFAM-Stream option.                             *
***********************************************************************
QS_0483  DS   0H
         LA    R1,Z_LENGTH             Load header name  length
         ST    R1,L_HEADER             Save header name  length
         LA    R1,Z_VAL_L              Load value  field length
         ST    R1,V_LENGTH             Save value  field length
*
         EXEC CICS WEB READ HTTPHEADER(Z_HEADER)                       X
               NAMELENGTH(L_HEADER)                                    X
               VALUE(Z_VALUE)                                          X
               VALUELENGTH(V_LENGTH)                                   X
               NOHANDLE
*
***********************************************************************
* Set program suffix for zFAM022, which will process WHERE requests   *
* with secondary column indexes as the first field in the statement.  *
**********************************************************************
         MVI   W_CI,C'2'               Set zFAM022 program suffix
***********************************************************************
* Return to calling routine.                                          *
***********************************************************************
QS_0489  DS   0H
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Transfer control (XCTL) to Query mode process                       *
***********************************************************************
QS_0500  DS   0H
         EXEC CICS XCTL PROGRAM(QM_PROG)                               X
               CHANNEL(C_CHAN)                                         X
               NOHANDLE
         BC    B'1111',ER_50002        Houston, we have a problem
*
***********************************************************************
* Return to caller                                                    *
**********************************************************************
RETURN   DS   0H
         EXEC CICS RETURN
*
***********************************************************************
* Issue TRACE command.                                                *
***********************************************************************
TR_0010  DS   0H
         ST    R14,BAS_REG             Save return register
*
         EXEC CICS ENTER TRACENUM(T_46)                                X
               FROM(T_46_M)                                            X
               FROMLENGTH(T_LEN)                                       X
               RESOURCE(T_RES)                                         X
               NOHANDLE
*
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Issue PUT CONTAINER for various artifacts.                          *
* Note:  Artifacts is a cool 'architect' buzz term, which according   *
*        to Thesaurus means objects, articles, items, things, pieces, *
*        relics, etc.  Not sure why architects use such big words.  I *
*        had to look this up to see what 'artifacts' really means.    *
***********************************************************************
PC_0010  DS   0H
         ST    R14,BAS_REG             Save return register
         L     R6,W_ADDR               Load field data address
         USING DC_DSECT,R6             ... tell assembler
         EXEC CICS PUT CONTAINER(W_NAME)                               X
               FROM(DC_DSECT)                                          X
               FLENGTH(W_LENGTH)                                       X
               CHANNEL(C_CHAN)                                         X
               NOHANDLE
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Parse DFHCOMMAREA to find query string on POST/PUT requests         *
* This routine will only be called when the EXTRACT command receives  *
* a QUERYSTRLEN between 3 and 8192 bytes.                             *
***********************************************************************
CA_0010  DS   0H
         ST    R14,BAS_REG             Save return register
         LH    R4,EIBCALEN             Load DFHCOMMAREA length
         L     R5,DFHEICAP             Load DFHCOMMAREA address
***********************************************************************
* Query string begins with '?'.                                       *
***********************************************************************
CA_0020  DS   0H
         CLI   0(R5),C'?'              Query string?
         BC    B'1000',CA_0030         ... yes, save the address
         LA    R5,1(,R5)               Point to next byte
         BCT   R4,CA_0020              Continue QS search
         BC    B'1111',ER_40010        Malformed syntax
***********************************************************************
* Point past '?' to first byte of query string                        *
***********************************************************************
CA_0030  DS   0H
         LA    R5,1(,R5)               Point to next byte
         ST    R5,QS_ADDR              Save Query String address
         L     R14,BAS_REG             Load return register
         BCR   B'1111',R14             Return to calling routine
*
***********************************************************************
* Transfer control (XCTL) to Logging program.                         *
***********************************************************************
ER_XCTL  DS   0H
         STM   R0,R15,REGSAVE          Save registers
         LA    R1,E_LOG                Load COMMAREA length
         STH   R1,L_LOG                Save COMMAREA length
*
         EXEC CICS XCTL PROGRAM(ZFAM090)                               X
               COMMAREA(C_LOG)                                         X
               LENGTH(L_LOG)                                           X
               NOHANDLE
*
         EXEC CICS WEB SEND                                            X
               FROM      (H_CRLF)                                      X
               FROMLENGTH(H_TWO)                                       X
               ACTION    (H_ACTION)                                    X
               MEDIATYPE (H_MEDIA)                                     X
               STATUSCODE(H_STAT)                                      X
               STATUSTEXT(H_TEXT)                                      X
               STATUSLEN (H_LEN)                                       X
               SRVCONVERT                                              X
               NOHANDLE
*
         BC    B'1111',RETURN          Return (if XCTL fails)
*
***********************************************************************
* STATUS(400) RETURN CODE(01)                                         *
***********************************************************************
ER_40001 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(02)                                         *
***********************************************************************
ER_40002 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(03)                                         *
***********************************************************************
ER_40003 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(04)                                         *
***********************************************************************
ER_40004 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(05)                                         *
***********************************************************************
ER_40005 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(06)                                         *
***********************************************************************
ER_40006 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'06'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(07)                                         *
***********************************************************************
ER_40007 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'07'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(08)                                         *
***********************************************************************
ER_40008 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'08'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(09)                                         *
***********************************************************************
ER_40009 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'09'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(400) RETURN CODE(10)                                         *
***********************************************************************
ER_40010 DS   0H
         MVC   C_STATUS,S_400          Set STATUS
         MVC   C_REASON,=C'10'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(01)                                         *
***********************************************************************
ER_40101 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(02)                                         *
***********************************************************************
ER_40102 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(03)                                         *
***********************************************************************
ER_40103 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(04)                                         *
***********************************************************************
ER_40104 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(05)                                         *
***********************************************************************
ER_40105 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(06)                                         *
***********************************************************************
ER_40106 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'06'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(07)                                         *
***********************************************************************
ER_40107 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'07'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(08)                                         *
***********************************************************************
ER_40108 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'08'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(09)                                         *
***********************************************************************
ER_40109 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'09'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(10)                                         *
***********************************************************************
ER_40110 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'10'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(11)                                         *
***********************************************************************
ER_40111 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'11'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(12)                                         *
***********************************************************************
ER_40112 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'12'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(13)                                         *
***********************************************************************
ER_40113 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'13'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(401) RETURN CODE(14)                                         *
***********************************************************************
ER_40114 DS   0H
         MVC   C_STATUS,S_401          Set STATUS
         MVC   C_REASON,=C'14'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(405) RETURN CODE(01)                                         *
***********************************************************************
ER_40501 DS   0H
         MVC   C_STATUS,S_405          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(402) RETURN CODE(02)                                         *
***********************************************************************
ER_40502 DS   0H
         MVC   C_STATUS,S_405          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(403) RETURN CODE(01)                                         *
***********************************************************************
ER_40503 DS   0H
         MVC   C_STATUS,S_405          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(404) RETURN CODE(01)                                         *
***********************************************************************
ER_40504 DS   0H
         MVC   C_STATUS,S_405          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(405) RETURN CODE(05)                                         *
***********************************************************************
ER_40505 DS   0H
         MVC   C_STATUS,S_405          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(411) RETURN CODE(01)                                         *
***********************************************************************
ER_41101 DS   0H
         MVC   C_STATUS,S_411          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(412) RETURN CODE(01)                                         *
***********************************************************************
ER_41201 DS   0H
         MVC   C_STATUS,S_412          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(412) RETURN CODE(02)                                         *
***********************************************************************
ER_41202 DS   0H
         MVC   C_STATUS,S_412          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(412) RETURN CODE(03)                                         *
***********************************************************************
ER_41203 DS   0H
         MVC   C_STATUS,S_412          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(413) RETURN CODE(01)                                         *
***********************************************************************
ER_41301 DS   0H
         MVC   C_STATUS,S_413          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(01)                                         *
***********************************************************************
ER_41401 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(02)                                         *
***********************************************************************
ER_41402 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(03)                                         *
***********************************************************************
ER_41403 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'03'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(04)                                         *
***********************************************************************
ER_41404 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'04'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(05)                                         *
***********************************************************************
ER_41405 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'05'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(06)                                         *
***********************************************************************
ER_41406 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'06'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(414) RETURN CODE(07)                                         *
***********************************************************************
ER_41407 DS   0H
         MVC   C_STATUS,S_414          Set STATUS
         MVC   C_REASON,=C'07'         Set REASON
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(500) RETURN CODE(01)                                         *
***********************************************************************
ER_50001 DS   0H
         MVC   C_STATUS,S_500          Set STATUS
         MVC   C_REASON,=C'01'         Set REASON
         MVC   C_PROG,BM_PROG          Set Basic Mode program name
         BC    B'1111',ER_XCTL         Transfer control to logging
***********************************************************************
* STATUS(500) RETURN CODE(02)                                         *
***********************************************************************
ER_50002 DS   0H
         MVC   C_STATUS,S_500          Set STATUS
         MVC   C_REASON,=C'02'         Set REASON
         MVC   C_PROG,QM_PROG          Set Query Mode program name
         BC    B'1111',ER_XCTL         Transfer control to logging
*
***********************************************************************
* Define Constant fields                                              *
***********************************************************************
*
         DS   0F
DECODE   DC    V(ZDECODE)              ZDECODE subroutine
         DS   0F
REPLIC8  DC    CL10'/replicate'        zFAM replication
URI_DS   DC    CL10'/datastore'        datastore URI
         DS   0H
FA_PRE   DC    CL02'FA'                zFAM transaction prefix
HEX_00   DC    XL01'00'                Nulls
         DS   0F
HEX_40   DC    16XL01'40'              Spaces
         DS   0F
ZQL      DC    CL03'ZQL'               zQL query string
         DS   0F
S_400    DC    CL03'400'               HTTP STATUS(400)
         DS   0F
S_401    DC    CL03'401'               HTTP STATUS(401)
         DS   0F
S_403    DC    CL03'403'               HTTP STATUS(403)
         DS   0F
S_405    DC    CL03'405'               HTTP STATUS(405)
         DS   0F
S_411    DC    CL03'411'               HTTP STATUS(411)
         DS   0F
S_412    DC    CL03'412'               HTTP STATUS(412)
         DS   0F
S_413    DC    CL03'413'               HTTP STATUS(413)
         DS   0F
S_414    DC    CL03'414'               HTTP STATUS(414)
         DS   0F
S_500    DC    CL03'500'               HTTP STATUS(500)
         DS   0F
ONE      DC    F'00001'                One
SIX      DC    F'00006'                Six
SD_GM_L  DC    F'16384'                FAxxSD GETMAIN length
FD_GM_L  DC    F'68000'                FAxxFD GETMAIN length
PA_GM_L  DC    F'8192'                 Parser array length
MAX_QS   DC    F'8192'                 Query String maximum length
MAX_PA   DC    F'256'                  Parser array maximum entries
MAX_LEN  DC    F'64000'                Field data   maximum length
S_WR_LEN DC    F'3200000'              Set maximum receive length
         DS   0F
S_ONE_PD DC    PL2'1'                  Packed decimal one
S_ZEROPD DC    PL4'0'                  Packed decimal zeroes
S_32K    DC    PL4'32000'              Packed decimal 32,000
         DS   0F
ZBASIC   DC    CL08'ZBASIC  '          zBASIC Basic Authentication
ZFAM002  DC    CL08'ZFAM002 '          Basic mode
ZFAM010  DC    CL08'ZFAM010 '          Query mode POST
ZFAM011  DC    CL08'ZFAM011 '          Basic mode POST   (CI defined)
ZFAM020  DC    CL08'ZFAM020 '          Query mode GET
ZFAM021  DC    CL08'ZFAM021 '          Query mode GET    (not used)
ZFAM022  DC    CL08'ZFAM022 '          Query mode GET    (CI requested)
ZFAM030  DC    CL08'ZFAM030 '          Query mode PUT
ZFAM031  DC    CL08'ZFAM031 '          Basic mode PUT    (CI defined)
ZFAM040  DC    CL08'ZFAM040 '          Query mode DELETE
ZFAM041  DC    CL08'ZFAM041 '          Basic mode DELETE (CI defined)
ZFAM090  DC    CL08'ZFAM090 '          Logging program for zFAM001
*
         DS   0F
S_YEA    DC    CL03'YEA'               Read Only enabled
         DS   0F
S_NAY    DC    CL03'NAY'               Read Only disabled
*
         DS   0F
S_FIELDS DC    CL06'FIELDS'            FIELDS  command
         DS   0F
S_WHERE  DC    CL05'WHERE'             WHERE   command
         DS   0F
S_VIEW   DC    CL04'VIEW'              VIEW    command
         DS   0F
S_WITH   DC    CL04'WITH'              WITH    command
         DS   0F
S_AND    DC    CL03'AND'               AND     command
         DS   0F
S_TTL    DC    CL03'TTL'               TTL     command
         DS   0F
S_GET    DC    CL06'GET   '            GET     request
         DS   0F
S_SELECT DC    CL06'SELECT'            SELECT  request
         DS   0F
S_PUT    DC    CL06'PUT   '            PUT     request
         DS   0F
S_UPDATE DC    CL06'UPDATE'            UPDATE  request
         DS   0F
S_POST   DC    CL06'POST  '            POST    request
         DS   0F
S_INSERT DC    CL06'INSERT'            INSERT  request
         DS   0F
S_DELETE DC    CL06'DELETE'            DELETE  request
*                                      DELETE  security type
         DS   0F
S_READ   DC    CL06'READ  '            READ    security type
         DS   0F
S_WRITE  DC    CL06'WRITE '            WRITE   security type
         DS   0F
S_OPTION DC    CL07'OPTIONS'           OPTIONS command
         DS   0F
S_CR     DC    CL02'CR'                WITH CR (Committed   Reads)
         DS   0F
S_UR     DC    CL02'UR'                WITH UR (Uncommitted Reads)
*                                      Default OPTION WITH
         DS   0F
S_FORMAT DC    CL06'FORMAT'            OPTION FORMAT
         DS   0F
S_DIST   DC    CL08'DISTINCT'          OPTION DISTINCT
         DS   0F
S_MODE   DC    CL04'MODE'              OPTION MODE
         DS   0F
S_SORT   DC    CL04'SORT'              OPTION SORT
         DS   0F
S_ROWS   DC    CL04'ROWS'              OPTION ROWS
         DS   0F
S_FIXED  DC    CL09'FIXED    '         OPTION FORMAT   (default)
         DS   0F
S_XML    DC    CL09'XML      '         OPTION FORMAT
         DS   0F
S_JSON   DC    CL09'JSON     '         OPTION FORMAT
         DS   0F
S_DELIM  DC    CL09'DELIMITER'         OPTION FORMAT
         DS   0F
S_NO     DC    CL02'NO'                OPTION DISTINCT (default)
         DS   0F
S_YES    DC    CL03'YES'               OPTION DISTINCT
*
         DS   0F
S_ON     DC    CL08'ONLINE  '          OPTION MODE     (default)
         DS   0F
S_OFF    DC    CL08'OFFLINE '          OPTION MODE
         DS   0F
S_ZEROES DC    CL06'000000'            OPTION ROWS     (default)
         DS   0F
*
         DS   0F
A_HEADER DC    CL13'Authorization'     HTTP Header (Authorization)
A_LENGTH EQU   *-A_HEADER              HTTP header field length
         DS   0F
Z_HEADER DC    CL11'zFAM-Stream'       HTTP header (zFAM-Stream)
Z_LENGTH EQU   *-Z_HEADER              HTTP header field length
         DS   0F
M_ACAO_L DC    F'01'                   HTTP value  length
M_ACAO   DC    CL01'*'                 HTTP value  field
H_ACAO_L DC    F'27'                   HTTP header length
H_ACAO   DC    CL16'Access-Control-A'  HTTP header field
         DC    CL11'llow-Origin'       HTTP header field
         DS   0F
C_CHAN   DC    CL16'ZFAM-CHANNEL    '  zFAM channel
C_OPTION DC    CL16'ZFAM-OPTIONS    '  OPTIONS container
C_TTL    DC    CL16'ZFAM-TTL        '  TTL container
C_ARRAY  DC    CL16'ZFAM-ARRAY      '  ARRAY container
C_FAXXFD DC    CL16'ZFAM-FAXXFD     '  Field Description document
C_KEY    DC    CL16'ZFAM-KEY        '  Primary CI key
C_MEDIA  DC    CL16'ZFAM-MEDIA      '  Media type
         DS   0F
***********************************************************************
* Trace resources                                                     *
***********************************************************************
T_46     DC    H'46'                   Trace number
T_46_M   DC    CL08'OBJECTS '          Trace message
T_RES    DC    CL08'zFAM001 '          Trace resource
T_LEN    DC    H'08'                   Trace resource length
***********************************************************************
* Internal error resources                                            *
***********************************************************************
H_TWO    DC    F'2'                    Length of CRLF
H_CRLF   DC    XL02'0D25'              Carriage Return Line Feed
H_STAT   DC    H'500'                  HTTP STATUS(500)
H_ACTION DC    F'02'                   HTTP SEND ACTION(IMMEDIATE)
H_LEN    DC    F'48'                   HTTP STATUS TEXT Length
H_TEXT   DC    CL16'03-001 Service u'  HTTP STATUS TEXT Length
         DC    CL16'navailable and l'  ... continued
         DC    CL16'ogging disabled '  ... and complete
H_MEDIA  DC    CL56'text/plain'        HTTP Media type
         DS   0F
L_MEDIA  DC    F'00056'                Media type length
         DS   0F
*
***********************************************************************
* Literal Pool                                                        *
***********************************************************************
         LTORG
*
***********************************************************************
* Communication area between zFAM001 and ZDECODE                      *
***********************************************************************
ZFAM_CA  DSECT
ZD_RC    DS    CL02               Return Code
         DS    CL02               not used (alignment)
ZD_USER  DS    CL08               UserID
ZD_PASS  DS    CL08               Password
ZD_ENC   DS    CL24               Encoded field (max 24 bytes)
         DS    CL04               not used (alignment)
ZD_DEC   DS    CL18               Decoded field (max 18 byte)
ZD_L     EQU   *-ZD_RC            ZFAM_CA length
*
*
***********************************************************************
* Control Section - ZDECODE                                           *
***********************************************************************
ZDECODE  AMODE 31
ZDECODE  RMODE 31
ZDECODE  CSECT
***********************************************************************
* Establish addressibility                                            *
***********************************************************************
ZD_0010  DS   0H
         STM   R14,R12,12(R13)         Save registers
         LR    R10,R15                 Load base register
         USING ZDECODE,R10             ... tell assembler
         LR    R9,R1                   Load work area address
         USING ZFAM_CA,R9              ... tell assembler
         B     ZD_DATE                 Branch around literals
         DC    CL08'ZDECODE '
         DC    CL48' -- Base64Binary decode Basic Authentication    '
         DC    CL08'        '
         DC    CL08'&SYSDATE'
         DC    CL08'        '
         DC    CL08'&SYSTIME'
ZD_DATE  DS   0H
***********************************************************************
* Decode Base64Binary UserID:Password                                 *
***********************************************************************
ZD_0020  DS   0H
         MVC   ZD_DEC,ASCII_20         Initialize to ASCII spaces
         LA    R2,6                    Load Octet count
         LA    R3,ZD_ENC               Address encoded field (source)
         LA    R6,ZD_DEC               Address decoded field (target)
*
***********************************************************************
* Process six octets                                                  *
* R4 and R5 are used as the even/odd pair registers for SLL and SLDL  *
* instructions.                                                       *
***********************************************************************
ZD_0030  DS   0H
         SR    R4,R4                   Clear R4
         SR    R5,R5                   Clear R5
*
         BAS   R14,ZD_1000             Decode four bytes into three
         BCT   R2,ZD_0030              ... for each octet
***********************************************************************
* At this point, the UserID:Password has been decoded and converted   *
* from ASCII to EBCDIC.                                               *
* Move decoded and converted UserID                                   *
***********************************************************************
ZD_0100  DS   0H
         MVC   ZD_USER,EIGHT_40        Initialize to spaces
         MVC   ZD_PASS,EIGHT_40        Initialize to spaces
*
         LA    R2,8                    Set max field length
         LA    R3,ZD_DEC               Address decoded field (source)
         LA    R6,ZD_USER              Address UserID  field (target)
*
***********************************************************************
* Move decoded/converted field until ':' has been encountered.        *
***********************************************************************
ZD_0110  DS   0H
         MVC   0(1,R6),0(R3)           Move byte to UserId
         LA    R3,1(,R3)               Increment source field
         LA    R6,1(,R6)               Increment target field
         CLI   0(R3),C':'              Colon?
         BC    B'1000',ZD_0200         ... yes, process Password
         BCT   R2,ZD_0110              ... no,  continue
***********************************************************************
* At this point, the UserID has been moved.  Now, move the Password   *
***********************************************************************
ZD_0200  DS   0H
         LA    R2,8                    Set max field length
         LA    R3,1(,R3)               skip past ':'
         LA    R6,ZD_PASS              Address Password field (target)
***********************************************************************
* Move decoded/converted field until spaces or nulls are encountered. *
***********************************************************************
ZD_0210  DS   0H
         MVC   0(1,R6),0(R3)           Move byte to UserId
         LA    R3,1(,R3)               Increment source field
         LA    R6,1(,R6)               Increment target field
         CLI   0(R3),X'00'             Null?
         BC    B'1000',ZD_0300         ... yes, decode complete
         CLI   0(R3),X'40'             Space?
         BC    B'1000',ZD_0300         ... yes, decode complete
         BCT   R2,ZD_0210              ... no,  continue
***********************************************************************
* At this point, the UserID and Password have been moved.             *
***********************************************************************
ZD_0300  DS   0H
         MVC   ZD_RC,=C'00'            Set default return code
*
***********************************************************************
* Return to calling routine                                           *
***********************************************************************
ZD_0900  DS   0H
         LM    R14,R12,12(R13)         Load registers
         BCR   B'1111',R14             Return to caller
*
***********************************************************************
* Decode Base64Binary                                                 *
***********************************************************************
ZD_1000  DS   0H
*
***********************************************************************
* This routine will convert the first of four encoded bytes.          *
***********************************************************************
ZD_1010  DS   0H
         CLI   0(R3),X'7E'             EOF (=)?
         BC    B'1000',RC_0012         ... yes, invalid encode
         SR    R5,R5                   Clear odd register
         IC    R5,0(R3)                Load first encoded byte
         LA    R3,1(,R3)               Point to next encoded byte
         IC    R5,B64XLT(R5)           Translate from B64 alphabet
         SLL   R5,26                   Shift out the 2 Hi order bits
         SLDL  R4,6                    Merge 6 bits of R5 into R4
*
***********************************************************************
* This routine will convert the second of four encoded bytes.         *
***********************************************************************
ZD_1020  DS   0H
         CLI   0(R3),X'7E'             EOF (=)?
         BC    B'1000',RC_0012         ... yes, invalid encode
         SR    R5,R5                   Clear odd register
         IC    R5,0(R3)                Load first encoded byte
         LA    R3,1(,R3)               Point to next encoded byte
         IC    R5,B64XLT(R5)           Translate from B64 alphabet
         SLL   R5,26                   Shift out the 2 Hi order bits
         SLDL  R4,6                    Merge 6 bits of R5 into R4
***********************************************************************
* This routine will convert the third of four encoded bytes.          *
***********************************************************************
ZD_1030  DS   0H
         CLI   0(R3),X'7E'             EOF (=)?
         BC    B'1000',ZD_1100         ... yes, process one octet
         SR    R5,R5                   Clear odd register
         IC    R5,0(R3)                Load first encoded byte
         LA    R3,1(,R3)               Point to next encoded byte
         IC    R5,B64XLT(R5)           Translate from B64 alphabet
         SLL   R5,26                   Shift out the 2 Hi order bits
         SLDL  R4,6                    Merge 6 bits of R5 into R4
***********************************************************************
* This routine will convert the fourth of four encoded bytes.         *
***********************************************************************
ZD_1040  DS   0H
         CLI   0(R3),X'7E'             EOF (=)?
         BC    B'1000',ZD_1200         ... yes, process two octets
         SR    R5,R5                   Clear odd register
         IC    R5,0(R3)                Load first encoded byte
         LA    R3,1(,R3)               Point to next encoded byte
         IC    R5,B64XLT(R5)           Translate from B64 alphabet
         SLL   R5,26                   Shift out the 2 Hi order bits
         SLDL  R4,6                    Merge 6 bits of R5 into R4
***********************************************************************
* Process the three decoded bytes.                                    *
***********************************************************************
ZD_1050  DS   0H
         STCM  R4,7,0(R6)              Save three decoded bytes
         TR    0(3,R6),A_TO_E          Convert to EBCDIC
         LA    R6,3(R6)                Increment pointer
         BCR   B'1111',R14             Return to caller
***********************************************************************
* Process single octet                                                *
***********************************************************************
ZD_1100  DS   0H
         SLL   R4,12                   Shift a null digit into R4
         STCM  R4,4,0(R6)              Save single octet
         TR    0(3,R6),A_TO_E          Convert to EBCDIC
         LA    R2,1                    Set counter to end process
         BCR   B'1111',R14             Return to caller
***********************************************************************
* Process double octet                                                *
***********************************************************************
ZD_1200  DS   0H
         SLL   R4,6                    Shift a null digit into R4
         STCM  R4,6,0(R6)              Save double octet
         TR    0(3,R6),A_TO_E          Convert to EBCDIC
         LA    R2,1                    Set counter to end process
         BCR   B'1111',R14             Return to caller
***********************************************************************
* Return code 12 - Invalid encode field provided                      *
***********************************************************************
RC_0012  DS   0H
         MVC   ZD_RC,=C'12'            Set return code 12
         BC    B'1111',ZD_0900         Return to caller
*
*
***********************************************************************
* Literal Pool                                                        *
***********************************************************************
         LTORG
*
         DS   0F
EIGHT_40 DC    08XL01'40'              EBCDIC spaces
ASCII_20 DC    18XL01'20'              ASCII  spaces
*
         DS   0F
*
***********************************************************************
* Translate table                                                     *
* Base64Binary alphabet and corresponding six bit representation      *
***********************************************************************
         DS   0F
B64XLT   DC    XL16'00000000000000000000000000000000'       00-0F
         DC    XL16'00000000000000000000000000000000'       10-1F
         DC    XL16'00000000000000000000000000000000'       20-2F
         DC    XL16'00000000000000000000000000000000'       30-3F
         DC    XL16'00000000000000000000000000003E00'       40-4F
         DC    XL16'00000000000000000000000000000000'       50-5F
         DC    XL16'003F0000000000000000000000000000'       60-6F
         DC    XL16'00000000000000000000000000000000'       70-7F
         DC    XL16'001A1B1C1D1E1F202122000000000000'       80-8F
         DC    XL16'00232425262728292A2B000000000000'       90-9F
         DC    XL16'00002C2D2E2F30313233000000000000'       A0-AF
         DC    XL16'00000000000000000000000000000000'       B0-BF
         DC    XL16'00000102030405060708000000000000'       C0-CF
         DC    XL16'00090A0B0C0D0E0F1011000000000000'       D0-DF
         DC    XL16'00001213141516171819000000000000'       E0-EF
         DC    XL16'3435363738393A3B3C3D000000000000'       F0-FF
*
***********************************************************************
* Translate table                                                     *
* ASCII to EBCDIC                                                     *
***********************************************************************
         DS   0F
A_TO_E   DC    XL16'00000000000000000000000000000000'       00-0F
         DC    XL16'00000000000000000000000000000000'       10-1F
         DC    XL16'405A7F7B5B6C507D4D5D5C4E6B604B61'       20-2F
         DC    XL16'F0F1F2F3F4F5F6F7F8F97A5E4C7E6E6F'       30-3F
         DC    XL16'7CC1C2C3C4C5C6C7C8C9D1D2D3D4D5D6'       40-4F
         DC    XL16'D7D8D9E2E3E4E5E6E7E8E9BAE0BB5F6D'       50-5F
         DC    XL16'79818283848586878889919293949596'       60-6F
         DC    XL16'979899A2A3A4A5A6A7A8A9C06AD0A107'       70-7F
         DC    XL16'00000000000000000000000000000000'       80-8F
         DC    XL16'00000000000000000000000000000000'       90-9F
         DC    XL16'00000000000000000000000000000000'       A0-AF
         DC    XL16'00000000000000000000000000000000'       B0-BF
         DC    XL16'00000000000000000000000000000000'       C0-CF
         DC    XL16'00000000000000000000000000000000'       D0-DF
         DC    XL16'00000000000000000000000000000000'       E0-EF
         DC    XL16'00000000000000000000000000000000'       F0-FF
*
         DS   0F
*
         PRINT ON
***********************************************************************
* End of Program - ZDECODE                                            *
**********************************************************************
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
* End of Program - ZFAM001                                            *
**********************************************************************
         END   ZFAM001