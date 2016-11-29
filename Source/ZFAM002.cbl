       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM002.
       AUTHOR.  Rich Jackson and Randy Frerking.
      *****************************************************************
      *                                                               *
      * zFAM - z/OS Frerking Access Manager.                          *
      *                                                               *
      * This is the primary Basic Mode zFAM program, which performs   *
      * the following functions:                                      *
      *                                                               *
      * POST   - Create record in   zFAM.                             *
      * GET    - Read   record from zFAM.                             *
      * PUT    - Update record in   zFAM.                             *
      * DELETE - Delete record from zFAM.                             *
      *                                                               *
      * The zFAM  KEY  store will utilize VSAM/RLS.                   *
      * The zFAM  FILE store will utilize VSAM/RLS, but can also      *
      * be defined as a Coupling Facility Data Table (CFDT) or as a   *
      * CICS Shared Data Table, both User Maintained Table (UMT) and  *
      * CICS Maintained Table (CMT).                                  *
      *                                                               *
      * zFAM Basic Mode supports text records in user defined data    *
      * structures, XML and JSON, as well as binary objects, such as  *
      * GIF, JPEG, PDF and videos.                                    *
      *                                                               *
      * Maximum record size for text   records is 3.2MB.              *
      * Maximum record size for binary records is 2GB.                *
      *                                                               *
      * The KEY store record contains the DDNAME suffix for the FILE  *
      * store, of which there can be 100 different datasets.  This    *
      * record also contains the key to the FILE store record.        *
      *                                                               *
      * Date       UserID   Description                               *
      * ---------- -------- ----------------------------------------- *
      *                                                               *
      *                                                               *
      *****************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *****************************************************************
      * DEFINE LOCAL VARIABLES                                        *
      *****************************************************************
       01  HEX-INDEX              PIC S9(04) COMP.
       01  DELIMITER-FOUND        PIC  X(01) VALUE LOW-VALUES.

       01  USERID                 PIC  X(08) VALUE SPACES.
       01  APPLID                 PIC  X(08) VALUE SPACES.
       01  SYSID                  PIC  X(04) VALUE SPACES.
       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  BINARY-ZEROES          PIC  X(01) VALUE LOW-VALUES.
       01  ZBASIC                 PIC  X(08) VALUE 'ZBASIC  '.
       01  ZFAM003                PIC  X(08) VALUE 'ZFAM003 '.
       01  ZFAM004                PIC  X(08) VALUE 'ZFAM004 '.
       01  ZFAM005                PIC  X(08) VALUE 'ZFAM005 '.
       01  ZFAM007                PIC  X(08) VALUE 'ZFAM007 '.
       01  ZFAM008                PIC  X(08) VALUE 'ZFAM008 '.
       01  ZFAM009                PIC  X(08) VALUE 'ZFAM009 '.
       01  ZFAM011                PIC  X(08) VALUE 'ZFAM011 '.
       01  ZFAM031                PIC  X(08) VALUE 'ZFAM031 '.
       01  ZFAM041                PIC  X(08) VALUE 'ZFAM041 '.
       01  ZFAM090                PIC  X(08) VALUE 'ZFAM090 '.

       01  STATUS-204             PIC  9(03) VALUE 204.
       01  STATUS-400             PIC  9(03) VALUE 400.
       01  STATUS-409             PIC  9(03) VALUE 409.
       01  STATUS-411             PIC  9(03) VALUE 411.
       01  STATUS-413             PIC  9(03) VALUE 413.
       01  STATUS-414             PIC  9(03) VALUE 414.
       01  STATUS-507             PIC  9(03) VALUE 507.

       01  ZFAM090-COMMAREA.
           02  CA090-STATUS       PIC  9(03) VALUE ZEROES.
           02  CA090-REASON       PIC  9(02) VALUE ZEROES.
           02  CA090-USERID       PIC  X(08) VALUE SPACES.
           02  CA090-PROGRAM      PIC  X(08) VALUE SPACES.
           02  CA090-FILE         PIC  X(08) VALUE SPACES.
           02  CA090-FIELD        PIC  X(16) VALUE SPACES.
           02  CA090-KEY          PIC X(255) VALUE SPACES.

       01  INTERNAL-KEY           PIC  X(08) VALUE LOW-VALUES.
       01  ZRECOVERY              PIC  X(10) VALUE '/zRecovery'.
       01  ZCOMPLETE              PIC  X(10) VALUE '/zComplete'.
       01  DATASTORE              PIC  X(10) VALUE '/datastore'.
       01  READ-ONLY              PIC  X(10) VALUE '/read-only'.
       01  REPLICATE              PIC  X(10) VALUE '/replicate'.
       01  DEPLICATE              PIC  X(10) VALUE '/deplicate'.
       01  CRLF                   PIC  X(02) VALUE X'0D25'.
       01  BINARY-ZERO            PIC  X(01) VALUE X'00'.

       01  LINKAGE-ADDRESSES.
           02  ZFAM-ADDRESS       USAGE POINTER.
           02  ZFAM-ADDRESS-X     REDEFINES ZFAM-ADDRESS
                                  PIC S9(08) COMP.

           02  SAVE-ADDRESS       USAGE POINTER.
           02  SAVE-ADDRESS-X     REDEFINES SAVE-ADDRESS
                                  PIC S9(08) COMP.

           02  FAXXFD-ADDRESS     USAGE POINTER.
           02  FAXXFD-ADDRESS-X   REDEFINES FAXXFD-ADDRESS
                                  PIC S9(08) COMP.

           02  RECORD-ADDRESS     USAGE POINTER.
           02  RECORD-ADDRESS-X   REDEFINES RECORD-ADDRESS
                                  PIC S9(08) COMP.

       01  GETMAIN-LENGTH         PIC S9(08) COMP VALUE ZEROES.

       01  ZFAM-COUNTER.
           02  NC-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(07) VALUE '_ZFAM  '.
           02  FILLER             PIC  X(05) VALUE SPACES.

       01  T_LEN                  PIC S9(04) COMP VALUE 8.
       01  T_46                   PIC S9(04) COMP VALUE 46.
       01  T_46_M                 PIC  X(08) VALUE SPACES.
       01  T_RES                  PIC  X(08) VALUE 'ZFAM002 '.

       01  QS-PROGRAM             PIC  X(08) VALUE SPACES.
       01  ROWS-REQUEST           PIC  X(01) VALUE 'N'.
       01  ROWS-TEXT              PIC  X(04) VALUE LOW-VALUES.
       01  ROWS-PARM              PIC  X(04) VALUE LOW-VALUES.
       01  ROWS-COUNT             PIC  9(04) VALUE 1.
       01  ROWS-FILLER            PIC  X(04) VALUE LOW-VALUES.
       01  DELIM-TEXT             PIC  X(05) VALUE LOW-VALUES.
       01  DELIM-MARKER           PIC  X(03) VALUE LOW-VALUES.
       01  PIPE-DELIM             PIC  X(01) VALUE X'4F'.

       01  FILLER.
           02  ZFAM-NC-VALUE      PIC  9(16) COMP VALUE ZEROES.
           02  FILLER REDEFINES ZFAM-NC-VALUE.
               05  FILLER         PIC  X(06).
               05  ZFAM-NC-HW     PIC  X(02).

       01  FILLER.
           02  WS-ABS             PIC S9(15) VALUE ZEROES COMP-3.
           02  FILLER REDEFINES WS-ABS.
               05  FILLER         PIC  X(01).
               05  WS-IDN         PIC  X(06).
               05  FILLER         PIC  X(01).

       01  QS-INDEX               PIC S9(04) COMP VALUE ZEROES.

       01  FILLER.
           05  GET-PARMS          PIC  X(50).
           05  FILLER REDEFINES GET-PARMS.
               10  GET-PARM       PIC  X(10) OCCURS 5 TIMES.

       01  ZFAM-NC-INCREMENT      PIC  9(16) COMP VALUE  1.
       01  WEBRESP                PIC S9(08) COMP VALUE ZEROES.
       01  FK-RESP                PIC S9(08) COMP VALUE ZEROES.
       01  TWENTY-FOUR-HOURS      PIC S9(08) COMP VALUE 86400.
       01  36500-DAYS             PIC S9(08) COMP VALUE 36500.
       01  TWO-FIFTY-FIVE         PIC S9(08) COMP VALUE 255.
       01  ONE-HUNDRED            PIC S9(08) COMP VALUE 100.
       01  100-YEARS              PIC S9(08) COMP VALUE 100.
       01  FIFTY                  PIC S9(08) COMP VALUE 50.
       01  THIRTY                 PIC S9(08) COMP VALUE 30.
       01  TWELVE                 PIC S9(08) COMP VALUE 12.
       01  TEN                    PIC S9(08) COMP VALUE 10.
       01  EIGHT                  PIC S9(08) COMP VALUE  8.
       01  SEVEN                  PIC S9(08) COMP VALUE  7.
       01  SIX                    PIC S9(08) COMP VALUE  6.
       01  FIVE                   PIC S9(08) COMP VALUE  5.
       01  TWO                    PIC S9(08) COMP VALUE  2.
       01  ONE                    PIC S9(08) COMP VALUE  1.
       01  ONE-YEAR               PIC S9(08) COMP VALUE  1.
       01  ONE-DAY                PIC S9(08) COMP VALUE  1.
       01  HTTP-NAME-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  HTTP-VALUE-LENGTH      PIC S9(08) COMP VALUE ZEROES.
       01  CLIENT-CONVERT         PIC S9(08) COMP VALUE ZEROES.
       01  SIXTY-FIVE-KB          PIC  9(04) COMP VALUE 65535.

      *****************************************************************
      * zUIDSTCK resources to obtain TOD for IDN.                     *
      *****************************************************************
       01  ZUIDSTCK               PIC  X(08) VALUE 'ZUIDSTCK'.
       01  THE-TOD                PIC  X(16) VALUE LOW-VALUES.

      *****************************************************************
      * Unique key and module                                         *
      *****************************************************************
       01  THE-MODULO-KEY.
           02  THE-MODULO         PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(01) VALUE '/'.
           02  THE-UNIQUE-KEY     PIC  X(32) VALUE LOW-VALUES.

      *****************************************************************
      * Named Counter parameters for modulo generation.               *
      *****************************************************************
       01  ZFAM-MOD-RESP          PIC S9(08) COMP VALUE ZERO.

       01  ZFAM-MOD-COUNTER.
           02  NC-MOD-TRANID      PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(06) VALUE '_ZFAM_'.
           02  FILLER             PIC  X(06) VALUE 'MODULO'.

       01  ZFAM-MOD-VALUE         PIC S9(08) COMP VALUE ZERO.
       01  ZFAM-MOD-MINIMUM       PIC S9(08) COMP VALUE 1.
       01  ZFAM-MOD-MAXIMUM       PIC S9(08) COMP VALUE 99.
       01  ZFAM-MOD-INCREMENT     PIC S9(08) COMP VALUE 1.

      *****************************************************************
      * Global enqueue parameters for modulo generation.              *
      *****************************************************************
       01  ZFAM-MOD-ENQUEUE.
           02  FILLER             PIC  X(08) VALUE 'CICSGRS_'.
           02  NQ-MOD-TRANID      PIC  X(04) VALUE 'FA##'.

       01  NQ-MOD-LENGTH          PIC S9(04) COMP VALUE 12.
       01  ENQRESP                PIC S9(08) COMP VALUE 00.

      *****************************************************************
      * HTTP headers to key range for DELETE process.                 *
      *****************************************************************
       01  END-RESPONSE           PIC S9(08) COMP VALUE ZEROES.
       01  HEADER-END-LENGTH      PIC S9(08) COMP VALUE 13.
       01  HEADER-END             PIC  X(13) VALUE 'zFAM-RangeEnd'.
       01  END-VALUE-LENGTH       PIC S9(08) COMP VALUE 255.
       01  END-VALUE              PIC X(255) VALUE LOW-VALUES.

       01  BEGIN-RESPONSE         PIC S9(08) COMP VALUE ZEROES.
       01  HEADER-BEGIN-LENGTH    PIC S9(08) COMP VALUE 15.
       01  HEADER-BEGIN           PIC  X(15) VALUE 'zFAM-RangeBegin'.
       01  BEGIN-VALUE-LENGTH     PIC S9(08) COMP VALUE 255.
       01  BEGIN-VALUE            PIC X(255) VALUE LOW-VALUES.

      *****************************************************************
      * HTTP headers for Event Control Record (ECR)                   *
      *****************************************************************
       01  HTTP-ECR               PIC  X(08) VALUE 'zFAM-ECR'.
       01  HTTP-ECR-VALUE         PIC  X(03) VALUE SPACES.
       01  ZFAM-ECR-LENGTH        PIC S9(08) COMP VALUE ZEROES.
       01  ECR-VALUE-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  ECR-RESP               PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * HTTP headers for LOB messages.                                *
      *****************************************************************
       01  HTTP-LOB               PIC  X(08) VALUE 'zFAM-LOB'.
       01  HTTP-LOB-VALUE         PIC  X(03) VALUE SPACES.
       01  ZFAM-LOB-LENGTH        PIC S9(08) COMP VALUE ZEROES.
       01  LOB-VALUE-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  LOB-RESP               PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * HTTP headers for APPEND messages.                             *
      *****************************************************************
       01  HTTP-APP               PIC  X(11) VALUE 'zFAM-Append'.
       01  HTTP-APP-VALUE         PIC  X(03) VALUE SPACES.
       01  ZFAM-APP-LENGTH        PIC S9(08) COMP VALUE ZEROES.
       01  APP-VALUE-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  APP-RESP               PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * HTTP headers for TTL    messages.                             *
      *****************************************************************
       01  HTTP-TTL               PIC  X(08) VALUE 'zFAM-TTL'.
       01  HTTP-TTL-VALUE         PIC  9(05) VALUE ZEROES.
       01  HTTP-TTL-LENGTH        PIC S9(08) COMP VALUE 08.
       01  TTL-VALUE-LENGTH       PIC S9(08) COMP VALUE 05.
       01  TTL-RESP               PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * HTTP headers to support key and modulo generation.            *
      *****************************************************************

       01  HTTP-UID               PIC  X(08) VALUE 'zFAM-UID'.
       01  HTTP-UID-VALUE         PIC  X(03) VALUE SPACES.
       01  HTTP-MODULO            PIC  X(11) VALUE 'zFAM-Modulo'.
       01  HTTP-MODULO-VALUE      PIC  9(02) VALUE ZEROES.
       01  ZFAM-UID-LENGTH        PIC S9(08) COMP VALUE ZEROES.
       01  ZFAM-MODULO-LENGTH     PIC S9(08) COMP VALUE ZEROES.
       01  UID-VALUE-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  MODULO-VALUE-LENGTH    PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * Content-Type header processing                                *
      *****************************************************************

       01  HTTP-CONTENT           PIC  X(12) VALUE 'Content-Type'.
       01  HTTP-CONTENT-VALUE     PIC  X(64) VALUE SPACES.
       01  HTTP-CONTENT-LENGTH    PIC S9(08) COMP VALUE 12.
       01  CONTENT-VALUE-LENGTH   PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * Logical row level locking HTTP Headers                        *
      *****************************************************************

       01  HTTP-LOCK              PIC  X(09) VALUE 'zFAM-Lock'.
       01  HTTP-LOCK-VALUE        PIC  X(03) VALUE SPACES.
       01  HTTP-TIME              PIC  X(09) VALUE 'zFAM-Time'.
       01  HTTP-TIME-VALUE        PIC  9(01) VALUE ZEROES.
       01  HTTP-ACTION            PIC  X(11) VALUE 'zFAM-Action'.
       01  HTTP-ACTION-VALUE      PIC  X(06) VALUE SPACES.
       01  HTTP-LOCKID            PIC  X(11) VALUE 'zFAM-LockID'.
       01  HTTP-LOCKID-VALUE      PIC  X(32) VALUE SPACES.
       01  HTTP-STATUS            PIC  X(11) VALUE 'zFAM-Status'.
       01  HTTP-STATUS-VALUE      PIC  X(16) VALUE SPACES.

       01  ZFAM-LOCK-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  ZFAM-TIME-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  ZFAM-ACTION-LENGTH     PIC S9(08) COMP VALUE ZEROES.
       01  ZFAM-LOCKID-LENGTH     PIC S9(08) COMP VALUE ZEROES.
       01  ZFAM-STATUS-LENGTH     PIC S9(08) COMP VALUE ZEROES.

       01  LOCK-VALUE-LENGTH      PIC S9(08) COMP VALUE ZEROES.
       01  TIME-VALUE-LENGTH      PIC S9(08) COMP VALUE ZEROES.
       01  ACTION-VALUE-LENGTH    PIC S9(08) COMP VALUE ZEROES.
       01  LOCKID-VALUE-LENGTH    PIC S9(08) COMP VALUE ZEROES.
       01  STATUS-VALUE-LENGTH    PIC S9(08) COMP VALUE ZEROES.

       01  LOCK-SUCCESSFUL        PIC  X(16) VALUE 'Lock successful '.
       01  LOCK-REJECTED          PIC  X(16) VALUE 'Lock rejected   '.
       01  LOCK-NOT-ACTIVE        PIC  X(16) VALUE 'Lock not active '.

      *****************************************************************
      * ZUID001 commarea information                                  *
      *****************************************************************
       01  COMMAREA-LENGTH        PIC S9(04) COMP VALUE 160.

       01  ZUID001                PIC  X(08) VALUE 'ZUID001 '.

       01  ZUID001-COMMAREA.
           02  ZUID-TYPE          PIC  X(04) VALUE 'LINK'.
           02  ZUID-STATUS-CODE   PIC  X(03).
           02  FILLER             PIC  X(01).
           02  ZUID-REASON-CODE   PIC  X(02).
           02  FILLER             PIC  X(02).
           02  ZUID-PROGRAM-ID    PIC  X(03).
           02  FILLER             PIC  X(01).
           02  ZUID-FORMAT        PIC  X(05).
           02  FILLER             PIC  X(03).
           02  ZUID-REGISTRY      PIC  X(06).
           02  FILLER             PIC  X(02).
           02  ZUID-UID           PIC  X(36).
           02  FILLER             PIC  X(92).
           02  ZUID-CUSTOM-TEXT   PIC  X(1024).

      *****************************************************************
      * L8WAIT  commarea information                                  *
      *****************************************************************
       01  L8WAIT                 PIC  X(08) VALUE 'L8WAIT  '.
       01  L8WAIT-COMMAREA.
           02  L8-RETURN-CODE     PIC  X(04) VALUE SPACES.
           02  INTERVAL           PIC S9(08) COMP  VALUE 10.

      *****************************************************************
      * Row Level Locking control fields - start                      *
      *****************************************************************
       01  LOCK-OBTAINED          PIC  X(01) VALUE SPACES.
       01  ROW-LOCKED             PIC  X(01) VALUE SPACES.
       01  WAIT-COUNT             PIC S9(04) COMP  VALUE ZEROES.

      *****************************************************************
      * Row Level Locking control fields - end                        *
      *****************************************************************

       01  HTTP-HEADER            PIC  X(13) VALUE 'Authorization'.
       01  HTTP-HEADER-VALUE      PIC  X(64) VALUE SPACES.

       01  ZFAM003-COMM-AREA.
           02  CA-TYPE            PIC  X(03) VALUE 'SDR'.
           02  CA-URI-FIELD-01    PIC  X(10) VALUE SPACES.

       01  ZBASIC-COMM-AREA.
           02  CA-RETURN-CODE     PIC  X(02) VALUE '00'.
           02  FILLER             PIC  X(02) VALUE SPACES.
           02  CA-USERID          PIC  X(08) VALUE SPACES.
           02  CA-PASSWORD        PIC  X(08) VALUE SPACES.
           02  CA-ENCODE          PIC  X(24) VALUE SPACES.
           02  FILLER             PIC  X(04) VALUE SPACES.
           02  CA-DECODE          PIC  X(18) VALUE SPACES.

       01  HTTP-STATUS-200        PIC S9(04) COMP VALUE 200.
       01  HTTP-STATUS-201        PIC S9(04) COMP VALUE 201.
       01  HTTP-STATUS-401        PIC S9(04) COMP VALUE 401.
       01  HTTP-STATUS-409        PIC S9(04) COMP VALUE 409.
       01  HTTP-STATUS-503        PIC S9(04) COMP VALUE 503.

       01  HTTP-OK                PIC  X(02) VALUE 'OK'.

       01  HTTP-503-99-LENGTH     PIC S9(08) COMP VALUE 48.
       01  HTTP-503-99-TEXT.
           02  FILLER             PIC  X(16) VALUE '99-002 Service u'.
           02  FILLER             PIC  X(16) VALUE 'navailable and l'.
           02  FILLER             PIC  X(16) VALUE 'ogging disabled '.

       01  HTTP-ABSTIME-LENGTH    PIC S9(08) COMP VALUE 15.
       01  FILLER.
           02  HTTP-ABSTIME       PIC  9(15) VALUE ZEROES.

       01  HTTP-ABEND-LENGTH      PIC S9(08) COMP VALUE 34.
       01  HTTP-ABEND.
           02  FILLER             PIC  X(16) VALUE 'Task abended wit'.
           02  FILLER             PIC  X(14) VALUE 'h abend code: '.
           02  HTTP-ABEND-CODE    PIC  X(04) VALUE SPACES.


       01  TEXT-ANYTHING          PIC  X(04) VALUE 'text'.
       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.
       01  TEXT-HTML              PIC  X(56) VALUE 'text/html'.
       01  APPLICATION-XML        PIC  X(56) VALUE 'application/xml'.
       01  APPLICATION-JSON       PIC  X(56) VALUE 'application/json'.

       01  AUTHENTICATE           PIC  X(01) VALUE SPACES.
       01  PROCESS-COMPLETE       PIC  X(01) VALUE SPACES.
       01  FF-SUCCESSFUL          PIC  X(01) VALUE SPACES.

       01  HTTP-AUTH-LENGTH       PIC S9(08) COMP VALUE 32.
       01  HTTP-AUTH-ERROR.
           02  FILLER             PIC  X(16) VALUE 'Basic Authentica'.
           02  FILLER             PIC  X(16) VALUE 'tion failed     '.

       01  CURRENT-ABS            PIC S9(15) VALUE ZEROES COMP-3.
       01  RELATIVE-TIME          PIC S9(15) VALUE ZEROES COMP-3.

       01  GET-COMMAREA.
           02  GET-CA-TYPE        PIC  X(02) VALUE SPACES.
           02  GET-CA-ROWS        PIC  9(04) VALUE ZEROES.
           02  GET-CA-DELIM       PIC  X(01) VALUE LOW-VALUES.
           02  GET-CA-KEYS        PIC  X(01) VALUE LOW-VALUES.
           02  GET-CA-TTL         PIC  X(01) VALUE LOW-VALUES.
           02  FILLER             PIC  X(07) VALUE LOW-VALUES.
           02  GET-CA-KEY-LENGTH  PIC S9(08) VALUE ZEROES COMP.
           02  GET-CA-KEY         PIC X(255) VALUE LOW-VALUES.

       01  GET-ROWS               PIC  9(04) VALUE ZEROES.

       01  GET-EQ                 PIC  X(02) VALUE 'eq'.
       01  GET-GE                 PIC  X(02) VALUE 'ge'.
       01  GET-GT                 PIC  X(02) VALUE 'gt'.
       01  GET-LE                 PIC  X(02) VALUE 'le'.
       01  GET-LT                 PIC  X(02) VALUE 'lt'.

       01  RET-TTL                PIC  X(10) VALUE 'ttl       '.
       01  RET-YEARS              PIC  X(10) VALUE 'ret-years '.
       01  RET-DAYS               PIC  X(10) VALUE 'ret-days  '.

       01  RET-INTERVAL           PIC  9(05) VALUE ZEROES.
       01  RET-MILLISECONDS       PIC S9(15) VALUE ZEROES COMP-3.
       01  FILLER.
           02  RET-SEC-MS.
               03  RET-SECONDS    PIC  9(06) VALUE ZEROES.
               03  FILLER         PIC  9(03) VALUE ZEROES.
           02  FILLER REDEFINES RET-SEC-MS.
               03  RET-TIME       PIC  9(09).

       01  LOCK-MILLISECONDS      PIC S9(15) VALUE ZEROES COMP-3.
       01  FILLER.
           02  LOCK-SEC-MS.
               03  LOCK-SECONDS   PIC  9(06) VALUE ZEROES.
               03  FILLER         PIC  9(03) VALUE ZEROES.
           02  FILLER REDEFINES LOCK-SEC-MS.
               03  LOCK-TIME      PIC  9(09).

       01  URI-FIELD-00           PIC  X(01).
       01  URI-FIELD-01           PIC  X(64).
       01  URI-FIELD-02           PIC  X(64).
       01  URI-FIELD-03           PIC  X(64).
       01  URI-FIELD-04           PIC  X(64).
       01  URI-FIELD-05           PIC  X(64).
       01  URI-FIELD-06           PIC  X(64).
       01  URI-KEY                PIC X(255) VALUE LOW-VALUES.
       01  URI-KEY-LENGTH         PIC S9(08) COMP VALUE ZEROES.
       01  URI-PATH-POINTER       PIC S9(08) COMP VALUE ZEROES.
       01  URI-PATH-LENGTH        PIC S9(08) COMP VALUE ZEROES.

       01  WEB-MEDIA-TYPE         PIC  X(56).
       01  SPACE-COUNTER          PIC S9(04) COMP VALUE ZEROES.
       01  SLASH-COUNTER          PIC S9(04) COMP VALUE ZEROES.
       01  SLASH                  PIC  X(01) VALUE '/'.
       01  EQUAL-SIGN             PIC  X(01) VALUE '='.
       01  QUERY-TEXT             PIC  X(10) VALUE SPACES.
       01  DELETE-REQUEST         PIC  X(06) VALUE 'Delete'.
       01  DELETE-TEXT            PIC  X(01) VALUE SPACES.

       01  RET-TYPE               PIC  X(03) VALUE SPACES.
       01  LAST-ACCESS-TIME       PIC  X(03) VALUE 'LAT'.

       01  SEND-LENGTH            PIC S9(08) COMP VALUE ZEROES.
       01  TWO-HUNDRED-MB         PIC S9(08) COMP VALUE 208000000.
       01  TWO-HUNDRED-FIFTY-MB   PIC S9(08) COMP VALUE 258000000.
       01  RECEIVE-LENGTH         PIC S9(08) COMP VALUE 3200000.
       01  MAXIMUM-LENGTH         PIC S9(08) COMP VALUE 3200000.
       01  THREE-POINT-TWO-MB     PIC S9(08) COMP VALUE 3200000.
       01  THIRTY-TWO-KB          PIC S9(08) COMP VALUE 32000.
       01  MAX-SEGMENT-COUNT      PIC S9(08) COMP VALUE ZEROES.
       01  MAX-SEGMENT-TOTAL      PIC S9(08) COMP VALUE ZEROES.
       01  APPEND-SEGMENT         PIC S9(08) COMP VALUE ZEROES.
       01  SEGMENT-COUNT          PIC S9(08) COMP VALUE ZEROES.
       01  SEGMENT-REMAINDER      PIC S9(08) COMP VALUE ZEROES.
       01  UNSEGMENTED-LENGTH     PIC S9(08) COMP VALUE ZEROES.
       01  SEND-ACTION            PIC S9(08) COMP VALUE ZEROES.

       01  ZFAM-CONTAINER         PIC  X(16) VALUE 'ZFAM-CONTAINER'.
       01  ZFAM-CHANNEL           PIC  X(16) VALUE 'ZFAM-CHANNEL  '.
       01  ZFAM-PROCESS           PIC  X(16) VALUE 'ZFAM-PROCESS  '.
       01  ZFAM-FAXXFD            PIC  X(16) VALUE 'ZFAM-FAXXFD   '.
       01  ZFAM-NEW-REC           PIC  X(16) VALUE 'ZFAM-NEW-REC  '.
       01  ZFAM-OLD-REC           PIC  X(16) VALUE 'ZFAM-OLD-REC  '.
       01  ZFAM-NEW-KEY           PIC  X(16) VALUE 'ZFAM-NEW-KEY  '.
       01  ZFAM-OLD-KEY           PIC  X(16) VALUE 'ZFAM-OLD-KEY  '.

       01  PROCESS-DELETE         PIC  X(06) VALUE 'DELETE'.
       01  PROCESS-INSERT         PIC  X(06) VALUE 'INSERT'.
       01  PROCESS-LENGTH         PIC S9(08) COMP VALUE ZEROES.

       01  CONTAINER-LENGTH       PIC S9(08) COMP VALUE ZEROES.

       01  SESSION-TOKEN          PIC  9(18) COMP VALUE ZEROES.

       01  SERVER-CONVERT         PIC S9(08) COMP VALUE ZEROES.
       01  WEB-METHOD             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-HOST-LENGTH        PIC S9(08) COMP VALUE 120.
       01  WEB-HTTPMETHOD-LENGTH  PIC S9(08) COMP VALUE 10.
       01  WEB-HTTPVERSION-LENGTH PIC S9(08) COMP VALUE 15.
       01  WEB-PATH-LENGTH        PIC S9(08) COMP VALUE 512.
       01  WEB-QUERYSTRING-LENGTH PIC S9(08) COMP VALUE 256.
       01  WEB-REQUESTTYPE        PIC S9(08) COMP VALUE ZEROES.
       01  WEB-PORT               PIC S9(08) COMP VALUE ZEROES.
       01  WEB-PORT-NUMBER        PIC  9(05)      VALUE ZEROES.

       01  WEB-HTTPMETHOD         PIC  X(10) VALUE SPACES.
       01  WEB-HTTP-PUT           PIC  X(10) VALUE 'PUT'.
       01  WEB-HTTP-GET           PIC  X(10) VALUE 'GET'.
       01  WEB-HTTP-POST          PIC  X(10) VALUE 'POST'.
       01  WEB-HTTP-DELETE        PIC  X(10) VALUE 'DELETE'.

       01  WEB-HTTPVERSION        PIC  X(15) VALUE SPACES.

       01  WEB-HOST               PIC X(120) VALUE SPACES.
       01  WEB-PATH               PIC X(512) VALUE LOW-VALUES.
       01  WEB-QUERYSTRING        PIC X(256) VALUE SPACES.

       01  URL-SCHEME-NAME        PIC  X(16) VALUE SPACES.
       01  URL-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  URL-PORT               PIC S9(08) COMP VALUE ZEROES.
       01  URL-HOST-NAME          PIC  X(80) VALUE SPACES.
       01  URL-HOST-NAME-LENGTH   PIC S9(08) COMP VALUE 80.
       01  WEB-STATUS-CODE        PIC S9(04) COMP VALUE 00.
       01  WEB-STATUS-LENGTH      PIC S9(08) COMP VALUE 24.
       01  WEB-STATUS-TEXT        PIC  X(24) VALUE SPACES.

       01  CONVERSE-LENGTH        PIC S9(08) COMP VALUE 40.
       01  CONVERSE-RESPONSE      PIC  X(40) VALUE SPACES.

      *****************************************************************
      * Message resources                                             *
      *****************************************************************

       01  FC-READ                PIC  X(07) VALUE 'READ   '.
       01  FC-WRITE               PIC  X(07) VALUE 'WRITE  '.
       01  FC-REWRITE             PIC  X(07) VALUE 'REWRITE'.
       01  CSSL                   PIC  X(04) VALUE '@tdq@'.
       01  TD-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  TD-FLENGTH             PIC S9(08) COMP VALUE ZEROES.

       01  TD-RECORD.
           02  TD-DATE            PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TIME            PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TRANID          PIC  X(04).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-MESSAGE         PIC  X(90) VALUE SPACES.

       01  50702-MESSAGE.
           02  FILLER             PIC  X(16) VALUE 'GET/READ primary'.
           02  FILLER             PIC  X(16) VALUE ' key references '.
           02  FILLER             PIC  X(16) VALUE 'an internal key '.
           02  FILLER             PIC  X(16) VALUE 'on *FILE that do'.
           02  FILLER             PIC  X(16) VALUE 'es not exist:   '.
           02  FILLER             PIC  X(02) VALUE SPACES.
           02  50702-KEY          PIC  X(08) VALUE 'xxxxxxxx'.

       01  FAxxFILE-ERROR.
           02  FE-DS              PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  FE-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  FE-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  FE-RESP2           PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  FE-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(13) VALUE SPACES.

       01  FAxxKEY-ERROR.
           02  KE-DS              PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  KE-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  KE-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  KE-RESP2           PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  KE-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(13) VALUE SPACES.

       01  NC-ERROR.
           02  FILLER             PIC  X(16) VALUE 'DEFINE Modulo Na'.
           02  FILLER             PIC  X(16) VALUE 'med Counter erro'.
           02  FILLER             PIC  X(03) VALUE 'r -'.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  NC-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  NC-RESP2           PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(08) VALUE SPACES.

       01  ABEND-MESSAGE.
           02  FILLER             PIC  X(09) VALUE 'zFAM002: '.
           02  FILLER             PIC  X(16) VALUE 'Task abended whe'.
           02  FILLER             PIC  X(16) VALUE 'n accessing file'.
           02  FILLER             PIC  X(02) VALUE ': '.
           02  AM-DS              PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(13) VALUE ' Abend code: '.
           02  AM-ABEND-CODE      PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(18) VALUE SPACES.

      *****************************************************************
      * Document template resources                                   *
      *****************************************************************

       01  DC-TOKEN               PIC  X(16) VALUE SPACES.
       01  DC-LENGTH              PIC S9(08) COMP VALUE ZEROES.
       01  THE-OTHER-DC-LENGTH    PIC S9(08) COMP VALUE ZEROES.

       01  ZFAM-DC.
           02  DC-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(02) VALUE 'DC'.
           02  FILLER             PIC  X(42) VALUE SPACES.

       01  DC-CONTROL.
           02  FILLER             PIC  X(06).
           02  DC-TYPE            PIC  X(02) VALUE SPACES.
           02  DC-CRLF            PIC  X(02).
           02  THE-OTHER-DC       PIC X(160) VALUE SPACES.
           02  FILLER             PIC  X(02).

       01  ACTIVE-SINGLE          PIC  X(02) VALUE 'A1'.
       01  ACTIVE-ACTIVE          PIC  X(02) VALUE 'AA'.
       01  ACTIVE-STANDBY         PIC  X(02) VALUE 'AS'.

       01  DD-TOKEN               PIC  X(16) VALUE SPACES.
       01  DD-LENGTH              PIC S9(08) COMP VALUE ZEROES.

       01  ZFAM-DD.
           02  DD-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(02) VALUE 'DD'.
           02  FILLER             PIC  X(42) VALUE SPACES.

       01  DD-INFORMATION.
           02  DD-NAME            PIC  X(04) VALUE SPACES.
           02  DD-CRLF            PIC  X(02).

      *****************************************************************
      * File resources                                                *
      *****************************************************************

       01  READ-KEY               PIC  X(01) VALUE 'N'.

       01  FK-FCT.
           02  FK-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(04) VALUE 'KEY '.

       01  FF-FCT.
           02  FF-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FF-DDNAME          PIC  X(04) VALUE 'FILE'.

       01  FK-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  FF-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  DELETE-LENGTH          PIC S9(04) COMP VALUE 8.

       COPY ZFAMFKC.

       COPY ZFAMFFC.

       01  DELETE-RECORD.
           02  DELETE-KEY-16.
               05  DELETE-KEY     PIC  X(08).
               05  DELETE-SEGMENT PIC  9(04) VALUE ZEROES COMP.
               05  DELETE-SUFFIX  PIC  9(04) VALUE ZEROES COMP.
               05  DELETE-ZEROES  PIC  9(08) VALUE ZEROES COMP.

       01  ZFAM-LENGTH            PIC S9(08) COMP VALUE ZEROES.

       COPY ZFAMHEX.

      *****************************************************************
      * Dynamic Storage                                               *
      *****************************************************************
       LINKAGE SECTION.
       01  DFHCOMMAREA            PIC  X(01).

      *****************************************************************
      * zFAM  message.                                                *
      * This is the response message buffer.                          *
      *****************************************************************
       01  ZFAM-MESSAGE           PIC  X(32000).

       PROCEDURE DIVISION.

      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 1000-ACCESS-PARMS       THRU 1000-EXIT.
           PERFORM 2000-PROCESS-REQUEST    THRU 2000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Access parms.                                                 *
      *****************************************************************
       1000-ACCESS-PARMS.
           EXEC CICS HANDLE ABEND LABEL(9996-ABEND) NOHANDLE
           END-EXEC.

           EXEC CICS ASKTIME ABSTIME(WS-ABS) NOHANDLE
           END-EXEC.

           EXEC CICS ASSIGN  CHANNEL(ZFAM-CHANNEL) NOHANDLE
           END-EXEC.

           EXEC CICS WEB EXTRACT
                SCHEME(WEB-SCHEME)
                HOST(WEB-HOST)
                HOSTLENGTH(WEB-HOST-LENGTH)
                HTTPMETHOD(WEB-HTTPMETHOD)
                METHODLENGTH(WEB-HTTPMETHOD-LENGTH)
                HTTPVERSION(WEB-HTTPVERSION)
                VERSIONLEN(WEB-HTTPVERSION-LENGTH)
                PATH(WEB-PATH)
                PATHLENGTH(WEB-PATH-LENGTH)
                PORTNUMBER(WEB-PORT)
                QUERYSTRING(WEB-QUERYSTRING)
                QUERYSTRLEN(WEB-QUERYSTRING-LENGTH)
                REQUESTTYPE(WEB-REQUESTTYPE)
                NOHANDLE
           END-EXEC.


           MOVE WEB-PORT TO WEB-PORT-NUMBER.

           IF  WEB-PATH-LENGTH GREATER THAN ZEROES
               PERFORM 1100-PARSE-URI  THRU 1100-EXIT
                   WITH TEST AFTER
                   VARYING URI-PATH-POINTER FROM  1 BY 1
                   UNTIL   URI-PATH-POINTER EQUAL TO WEB-PATH-LENGTH
                   OR      SLASH-COUNTER    EQUAL SEVEN

               PERFORM 1150-CHECK-URI  THRU 1150-EXIT
               PERFORM 1160-MOVE-URI   THRU 1160-EXIT

               UNSTRING WEB-PATH(1:WEB-PATH-LENGTH)
               DELIMITED BY ALL '/'
               INTO URI-FIELD-00
                    URI-FIELD-01
                    URI-FIELD-02
                    URI-FIELD-03
                    URI-FIELD-04
                    URI-FIELD-05
                    URI-FIELD-06.

           PERFORM 1300-QUERY-STRING      THRU 1300-EXIT.
           PERFORM 1500-READ-TTL          THRU 1500-EXIT.
           PERFORM 1600-READ-LOB          THRU 1600-EXIT.
           PERFORM 1610-READ-APP          THRU 1610-EXIT.
           PERFORM 1620-READ-ECR          THRU 1620-EXIT.

           IF  HTTP-ECR-VALUE NOT EQUAL 'Yes'
               PERFORM 1010-RECEIVE       THRU 1010-EXIT.

           MOVE EIBTRNID(3:2)               TO NC-TRANID(3:2).
           MOVE EIBTRNID(3:2)               TO FK-TRANID(3:2).
           MOVE EIBTRNID(3:2)               TO FF-TRANID(3:2).
           MOVE EIBTRNID(3:2)               TO DD-TRANID(3:2).
           MOVE EIBTRNID(3:2)               TO DC-TRANID(3:2).

       1000-EXIT.
           EXIT.

      *****************************************************************
      * Sending payload on a GET or DELETE is not permitted.          *
      * Sending payload is only permitted on POST or PUT.             *
      * When processing an Event Control Record (ECR), a payload is   *
      * not provided, therefore a RECEIVE is not performed.           *
      *****************************************************************
       1010-RECEIVE.

           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-POST
           OR  WEB-HTTPMETHOD EQUAL WEB-HTTP-PUT

      *****************************************************************
      * DO NOT specify TOCONTAINER on the RECEIVE, because this       *
      * option causes conversion of the content.                      *
      * However, when MEDIATYPE is 'text/*', convert the data, as     *
      * this information is accessed by both z/OS applications        *
      * and those applications in darkness (Unix/Linux based).        *
      *****************************************************************

               EXEC CICS WEB RECEIVE
                    SET      (ZFAM-ADDRESS)
                    LENGTH   (RECEIVE-LENGTH)
                    MAXLENGTH(MAXIMUM-LENGTH)
                    MEDIATYPE(WEB-MEDIA-TYPE)
                    RESP     (WEBRESP)
                    NOSRVCONVERT
                    NOHANDLE
               END-EXEC

               IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
               OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
               OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
                   EXEC CICS WEB RECEIVE
                        SET      (ZFAM-ADDRESS)
                        LENGTH   (RECEIVE-LENGTH)
                        MAXLENGTH(MAXIMUM-LENGTH)
                        MEDIATYPE(WEB-MEDIA-TYPE)
                        RESP     (WEBRESP)
                        SRVCONVERT
                        NOHANDLE
                   END-EXEC.

           IF  WEBRESP     EQUAL DFHRESP(LENGERR)
               MOVE STATUS-413              TO CA090-STATUS
               MOVE '01'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  WEBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE STATUS-400              TO CA090-STATUS
               MOVE '01'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  RECEIVE-LENGTH EQUAL ZEROES
               MOVE STATUS-411              TO CA090-STATUS
               MOVE '01'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       1010-EXIT.
           EXIT.

      *****************************************************************
      * Parse WEB-PATH to determine length of path prefix preceeding  *
      * the URI-KEY.  This will be used to determine the URI-KEY      *
      * length which is used on the UNSTRING command.  Without the    *
      * URI-KEY length, the UNSTRING command pads the URI-KEY with    *
      * spaces.  The URI-KEY needs to be padded with low-values to    *
      * allow zFAM   to support QueryString KEY search patterns.      *
      *****************************************************************
       1100-PARSE-URI.
           ADD ONE     TO URI-PATH-LENGTH.
           IF  WEB-PATH(URI-PATH-POINTER:1) EQUAL SLASH
               ADD ONE TO SLASH-COUNTER.

       1100-EXIT.
           EXIT.

      *****************************************************************
      * Check URI for the correct number of slashes.                  *
      * /datastore/zFAM/cc/div/BU_SBU/application/key                 *
      * There must be seven, otherwise reject with STATUS(400).       *
      *****************************************************************
       1150-CHECK-URI.
           IF  SLASH-COUNTER NOT EQUAL SEVEN
               MOVE STATUS-400              TO CA090-STATUS
               MOVE '02'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       1150-EXIT.
           EXIT.

      *****************************************************************
      * Move URI key when present.                                    *
      * When ?Delete=* is present, the key is ignored.  In this case, *
      * a URI key is probably not present.                            *
      *****************************************************************
       1160-MOVE-URI.
           SUBTRACT   URI-PATH-POINTER  FROM   WEB-PATH-LENGTH
               GIVING URI-PATH-LENGTH.

           IF  URI-PATH-LENGTH GREATER THAN TWO-FIFTY-FIVE
               MOVE STATUS-400              TO CA090-STATUS
               MOVE '03'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           ADD  ONE   TO URI-PATH-POINTER.
           IF  URI-PATH-LENGTH GREATER THAN ZEROES
               MOVE URI-PATH-LENGTH         TO URI-KEY-LENGTH
               MOVE WEB-PATH(URI-PATH-POINTER:URI-PATH-LENGTH)
               TO   URI-KEY(1:URI-PATH-LENGTH).

       1160-EXIT.
           EXIT.

      *****************************************************************
      * Process query string.                                         *
      * In this paragraph, all special processing must be handled in  *
      * one of the PERFORM statements and must XCTL from the standard *
      * zFAM002 program.  After special processing has been checked,  *
      * this paragraph will check the KEY length as determined in the *
      * 1160-MOVE-URI paragraph.  If the KEY length (URI-PATH-LENGTH) *
      * is zero, then issue a 400 status code, as the key must be     *
      * provided on all non-special processing.                       *
      *                                                               *
      * For POST processing, the keylength check will be performed    *
      * after checking the HTTP Header called zFAM-UID.               *
      *                                                               *
      * For DELETE processing, the keylength check will be performed  *
      * after checking the HTTP Header called zFAM-RangeBegin and     *
      * zFAM-RangeEnd.                                                *
      *****************************************************************
       1300-QUERY-STRING.
           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-POST
           OR  WEB-HTTPMETHOD EQUAL WEB-HTTP-PUT
               PERFORM 1310-RETENTION     THRU 1310-EXIT.

           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-GET
               PERFORM 1330-GET           THRU 1330-EXIT.

           IF  WEB-HTTPMETHOD  EQUAL WEB-HTTP-GET
           IF  URI-PATH-LENGTH EQUAL ZEROES
               MOVE STATUS-400              TO CA090-STATUS
               MOVE '04'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  WEB-HTTPMETHOD  EQUAL WEB-HTTP-PUT
           IF  URI-PATH-LENGTH EQUAL ZEROES
               MOVE STATUS-400              TO CA090-STATUS
               MOVE '05'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       1300-EXIT.
           EXIT.

      *****************************************************************
      * Process query string for POST/PUT retention period.           *
      * There are three retention period formats using the query      *
      * string:                                                       *
      *                                                               *
      * ?ttl=99999      expressed in days,  maximum of 36500.         *
      * ?ret-days=999   expressed in days,  maximum of 36500.         *
      * ?ret-years=999  expressed in years, maximum of 100.           *
      *                                                               *
      * When the query string is not provided or is in error, the     *
      * default is set to 7 years.                                    *
      *****************************************************************
       1310-RETENTION.
           MOVE SEVEN                  TO FF-RETENTION
                                          FK-RETENTION.
           MOVE 'Y'                    TO FF-RETENTION-TYPE
                                          FK-RETENTION-TYPE.

           IF WEB-QUERYSTRING-LENGTH > +0
               UNSTRING WEB-QUERYSTRING(1:WEB-QUERYSTRING-LENGTH)
               DELIMITED BY ALL '='
               INTO QUERY-TEXT
                    RET-INTERVAL.

           IF  QUERY-TEXT EQUAL RET-YEARS
               PERFORM 1311-YEARS    THRU 1311-EXIT.

           IF  QUERY-TEXT EQUAL RET-DAYS
               PERFORM 1312-DAYS     THRU 1312-EXIT.

           IF  QUERY-TEXT EQUAL RET-TTL
               PERFORM 1313-TTL      THRU 1313-EXIT.

       1310-EXIT.
           EXIT.

      *****************************************************************
      * Process RET query string for POST/PUT.                        *
      * Query text specified 'years', so edit accordingly.            *
      *****************************************************************
       1311-YEARS.
           MOVE 'Y'                    TO FF-RETENTION-TYPE
                                          FK-RETENTION-TYPE.
           IF  RET-INTERVAL NUMERIC
               MOVE RET-INTERVAL       TO FF-RETENTION
                                          FK-RETENTION.

           IF  FF-RETENTION LESS     THAN ONE-YEAR
               MOVE ONE-YEAR           TO FF-RETENTION
                                          FK-RETENTION.

           IF  FF-RETENTION GREATER  THAN 100-YEARS
               MOVE 100-YEARS          TO FF-RETENTION
                                          FK-RETENTION.

       1311-EXIT.
           EXIT.

      *****************************************************************
      * Process RET query string for POST/PUT.                        *
      * Query text specified 'days', so edit accordingly.             *
      *****************************************************************
       1312-DAYS.
           MOVE 'D'                    TO FF-RETENTION-TYPE
                                          FK-RETENTION-TYPE.
           IF  RET-INTERVAL NUMERIC
               MOVE RET-INTERVAL       TO FF-RETENTION
                                          FK-RETENTION.

           IF  FF-RETENTION LESS     THAN ONE-DAY
               MOVE ONE-DAY            TO FF-RETENTION
                                          FK-RETENTION.

           IF  FF-RETENTION GREATER  THAN 36500-DAYS
               MOVE 36500-DAYS         TO FF-RETENTION
                                          FK-RETENTION.

       1312-EXIT.
           EXIT.

      *****************************************************************
      * Process RET query string for POST/PUT.                        *
      * Query text specified 'ttl',  so edit accordingly.             *
      *****************************************************************
       1313-TTL.
           MOVE 'D'                    TO FF-RETENTION-TYPE.
           IF  RET-INTERVAL NUMERIC
               MOVE RET-INTERVAL       TO FF-RETENTION.

           IF  FF-RETENTION LESS     THAN ONE-DAY
               MOVE ONE-DAY            TO FF-RETENTION.

           IF  FF-RETENTION GREATER  THAN 36500-DAYS
               MOVE 36500-DAYS         TO FF-RETENTION.

       1313-EXIT.
           EXIT.

      *****************************************************************
      * Process ?Delete=* query string for DELETE.                    *
      * When ?Delete is set to '*', XCTL to zFAM003 to delete all     *
      * records between zFAM-RangeBegin and zFAM-RangeEnd values.     *
      *****************************************************************
       1320-DELETE.
           IF WEB-QUERYSTRING-LENGTH EQUAL EIGHT
               UNSTRING WEB-QUERYSTRING(1:WEB-QUERYSTRING-LENGTH)
               DELIMITED BY ALL '='
               INTO QUERY-TEXT
                    DELETE-TEXT
               PERFORM 1325-DELETE-TYPE    THRU 1325-EXIT
               IF  DELETE-TEXT EQUAL '*'
               AND QUERY-TEXT  EQUAL DELETE-REQUEST
                   EXEC CICS XCTL PROGRAM(ZFAM003)
                        COMMAREA(ZFAM003-COMM-AREA)
                        NOHANDLE
                   END-EXEC.

       1320-EXIT.
           EXIT.

      *****************************************************************
      * Extract Delete type from URIMAP                               *
      * The two types are:                                            *
      *   .ADR - Asynchronous Delete Request                          *
      *   .SDR -  Synchronous Delete Request                          *
      *****************************************************************
       1325-DELETE-TYPE.
           UNSTRING URI-FIELD-06
               DELIMITED BY ALL '.'
               INTO URI-FIELD-00
                    CA-TYPE.

           MOVE WEB-PATH(1:10) TO CA-URI-FIELD-01.

       1325-EXIT.
           EXIT.

      *****************************************************************
      * Process query string for GET request.                         *
      *****************************************************************
       1330-GET.
           MOVE GET-EQ                 TO GET-CA-TYPE.
           MOVE ONE                    TO GET-CA-ROWS.
           MOVE LOW-VALUES             TO GET-CA-DELIM.
           MOVE 'N'                    TO GET-CA-KEYS.
           MOVE 'N'                    TO GET-CA-TTL.

           IF WEB-QUERYSTRING-LENGTH > +0
               UNSTRING WEB-QUERYSTRING(1:WEB-QUERYSTRING-LENGTH)
               DELIMITED BY ALL ','
               INTO GET-PARM(1)
                    GET-PARM(2)
                    GET-PARM(3)
                    GET-PARM(4)
                    GET-PARM(5).

           MOVE '1330'               TO T_46_M.
           PERFORM 9995-TRACE      THRU 9995-EXIT.

           PERFORM 1400-GET-PARMS  THRU 1400-EXIT
               WITH TEST AFTER
               VARYING QS-INDEX FROM 1 BY 1 UNTIL QS-INDEX = 5.

           MOVE URI-KEY-LENGTH       TO GET-CA-KEY-LENGTH.
           MOVE URI-KEY              TO GET-CA-KEY.

           MOVE SPACES               TO QS-PROGRAM.

           IF  GET-CA-TYPE = 'ex'
               MOVE ZFAM004          TO QS-PROGRAM.

           IF  GET-CA-TYPE = 'gt'
           OR  GET-CA-TYPE = 'ge'
               IF  ROWS-REQUEST = 'N'
                   MOVE ZFAM004      TO QS-PROGRAM.

           IF  GET-CA-TYPE = 'lt'
           OR  GET-CA-TYPE = 'le'
               IF  ROWS-REQUEST = 'N'
                   MOVE ZFAM005      TO QS-PROGRAM.

           IF  GET-CA-TYPE = 'gt'
           OR  GET-CA-TYPE = 'ge'
               IF  ROWS-REQUEST = 'Y'
                   MOVE ZFAM007      TO QS-PROGRAM.

           IF  GET-CA-TYPE = 'lt'
           OR  GET-CA-TYPE = 'le'
               IF  ROWS-REQUEST = 'Y'
                   MOVE ZFAM008      TO QS-PROGRAM.

           IF  GET-CA-KEYS = 'Y'
               MOVE ZFAM009          TO QS-PROGRAM.

           IF  QS-PROGRAM NOT = SPACES
               EXEC CICS XCTL PROGRAM(QS-PROGRAM)
                    COMMAREA(GET-COMMAREA)
                    NOHANDLE
               END-EXEC
               PERFORM 9000-RETURN THRU 9000-EXIT.

       1330-EXIT.
           EXIT.

      *****************************************************************
      * Process query string parameters for the GET request.          *
      * Invalid parameters are ignored.                               *
      *****************************************************************
       1400-GET-PARMS.
           IF  GET-PARM(QS-INDEX)(1:2) EQUAL 'gt'
           OR  GET-PARM(QS-INDEX)(1:2) EQUAL 'ge'
           OR  GET-PARM(QS-INDEX)(1:2) EQUAL 'lt'
           OR  GET-PARM(QS-INDEX)(1:2) EQUAL 'le'
           OR  GET-PARM(QS-INDEX)(1:2) EQUAL 'ex'
               PERFORM 1410-TYPE       THRU 1410-EXIT.

           IF  GET-PARM(QS-INDEX)(1:4) EQUAL 'rows'
               PERFORM 1420-ROWS       THRU 1420-EXIT.

           IF  GET-PARM(QS-INDEX)(1:5) EQUAL 'delim'
               PERFORM 1430-DELIM      THRU 1430-EXIT.

           IF  GET-PARM(QS-INDEX)(1:8) EQUAL 'keysonly'
               PERFORM 1440-KEYSONLY   THRU 1440-EXIT.

           IF  GET-PARM(QS-INDEX)(1:3)  EQUAL 'ttl'
               PERFORM 1450-TTL        THRU 1450-EXIT.

       1400-EXIT.
           EXIT.

      *****************************************************************
      * Process query string parameter  TYPE.                         *
      *****************************************************************
       1410-TYPE.
           MOVE '1410'          TO T_46_M.
           PERFORM 9995-TRACE THRU 9995-EXIT.

           MOVE GET-PARM(QS-INDEX)(1:2) TO GET-CA-TYPE.

       1410-EXIT.
           EXIT.

      *****************************************************************
      * Process query string parameter  ROWS.                         *
      *****************************************************************
       1420-ROWS.
           UNSTRING GET-PARM(QS-INDEX) DELIMITED BY '='
               INTO ROWS-TEXT
                    ROWS-PARM.

           UNSTRING ROWS-PARM          DELIMITED BY SPACES
               INTO ROWS-COUNT
                    ROWS-FILLER.

           MOVE '1420'          TO T_46_M.
           PERFORM 9995-TRACE THRU 9995-EXIT.

           IF  ROWS-COUNT NUMERIC
               MOVE ROWS-COUNT TO GET-CA-ROWS.

           IF  ROWS-COUNT NOT NUMERIC
               MOVE 1          TO GET-CA-ROWS.

           MOVE 'Y'            TO ROWS-REQUEST.

       1420-EXIT.
           EXIT.

      *****************************************************************
      * Process query string parameter  DELIM.                        *
      *****************************************************************
       1430-DELIM.
           UNSTRING GET-PARM(QS-INDEX) DELIMITED BY '='
               INTO DELIM-TEXT
                    DELIM-MARKER.

           MOVE '1430'                    TO T_46_M.
           PERFORM 9995-TRACE           THRU 9995-EXIT.

           INSPECT DELIM-MARKER(2:2)
               CONVERTING "abcdefghijklmnopqrstuvwxyz"
                       TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ".

           MOVE DELIM-MARKER(1:1)         TO GET-CA-DELIM.
           IF  DELIM-MARKER(1:1) EQUAL '%'
               MOVE PIPE-DELIM            TO GET-CA-DELIM
               PERFORM 1431-HEX          THRU 1431-EXIT
                   WITH TEST AFTER
                   VARYING HEX-INDEX     FROM 1 BY 1 UNTIL
                   DELIMITER-FOUND       EQUAL 'Y'   OR
                   CHAR-VALUE(HEX-INDEX) EQUAL HIGH-VALUE.

       1430-EXIT.
           EXIT.

      *****************************************************************
      * Convert %xx to single byte.                                   *
      *****************************************************************
       1431-HEX.
           IF  CHAR-VALUE(HEX-INDEX) EQUAL DELIM-MARKER(2:2)
               MOVE 'Y'                   to DELIMITER-FOUND
               MOVE HEX-VALUE(HEX-INDEX)  TO GET-CA-DELIM.

       1431-EXIT.
           EXIT.

      *****************************************************************
      * Process query string parameter  KEYSONLY.                     *
      *****************************************************************
       1440-KEYSONLY.
           MOVE '1440'          TO T_46_M.
           PERFORM 9995-TRACE THRU 9995-EXIT.

           MOVE 'Y'            TO GET-CA-KEYS.

       1440-EXIT.
           EXIT.

      *****************************************************************
      * Process query string parameter  TTL.                          *
      *****************************************************************
       1450-TTL.
           MOVE '1450'          TO T_46_M.
           PERFORM 9995-TRACE THRU 9995-EXIT.

           MOVE 'Y'            TO GET-CA-TTL.

       1450-EXIT.
           EXIT.

      *****************************************************************
      * Issue READ for HTTP header - TTL.                             *
      *****************************************************************
       1500-READ-TTL.
           MOVE LENGTH OF HTTP-TTL            TO HTTP-TTL-LENGTH.
           MOVE LENGTH OF HTTP-TTL-VALUE      TO TTL-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-TTL)
                NAMELENGTH (HTTP-TTL-LENGTH)
                VALUE      (HTTP-TTL-VALUE)
                VALUELENGTH(TTL-VALUE-LENGTH)
                RESP       (TTL-RESP)
                NOHANDLE
           END-EXEC.

           IF  TTL-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 1510-EDIT-TTL        THRU 1510-EXIT.

       1500-EXIT.
           EXIT.

      *****************************************************************
      * Process HTTP-TTL header parameter.                            *
      *****************************************************************
       1510-EDIT-TTL.
           MOVE 'D'                    TO FF-RETENTION-TYPE
                                          FK-RETENTION-TYPE.
           IF  HTTP-TTL-VALUE NUMERIC
               MOVE HTTP-TTL-VALUE     TO FF-RETENTION
                                          FK-RETENTION.

           IF  FF-RETENTION LESS     THAN ONE-DAY
               MOVE ONE-DAY            TO FF-RETENTION
                                          FK-RETENTION.

           IF  FF-RETENTION GREATER  THAN 36500-DAYS
               MOVE 36500-DAYS         TO FF-RETENTION
                                          FK-RETENTION.

       1510-EXIT.
           EXIT.

      *****************************************************************
      * Issue READ for HTTP header - LOB.                             *
      *****************************************************************
       1600-READ-LOB.
           MOVE LENGTH OF HTTP-LOB            TO ZFAM-LOB-LENGTH.
           MOVE LENGTH OF HTTP-LOB-VALUE      TO LOB-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-LOB)
                NAMELENGTH (ZFAM-LOB-LENGTH)
                VALUE      (HTTP-LOB-VALUE)
                VALUELENGTH(LOB-VALUE-LENGTH)
                RESP       (LOB-RESP)
                NOHANDLE
           END-EXEC.

           IF  LOB-RESP EQUAL DFHRESP(NORMAL)
               IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-POST
               OR  WEB-HTTPMETHOD EQUAL WEB-HTTP-PUT
                   MOVE TWO-HUNDRED-FIFTY-MB  TO MAXIMUM-LENGTH.

       1600-EXIT.
           EXIT.

      *****************************************************************
      * Issue READ for HTTP header - zFAM-Append.                     *
      *****************************************************************
       1610-READ-APP.
           MOVE LENGTH OF HTTP-APP            TO ZFAM-APP-LENGTH.
           MOVE LENGTH OF HTTP-APP-VALUE      TO APP-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-APP)
                NAMELENGTH (ZFAM-APP-LENGTH)
                VALUE      (HTTP-APP-VALUE)
                VALUELENGTH(APP-VALUE-LENGTH)
                RESP       (APP-RESP)
                NOHANDLE
           END-EXEC.

           IF  APP-RESP EQUAL DFHRESP(NORMAL)
               IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-PUT
                   MOVE TWO-HUNDRED-FIFTY-MB  TO MAXIMUM-LENGTH.

       1610-EXIT.
           EXIT.

      *****************************************************************
      * Issue READ for HTTP header - zFAM-ECR. (Event Control Record) *
      *****************************************************************
       1620-READ-ECR.
           MOVE LENGTH OF HTTP-ECR            TO ZFAM-ECR-LENGTH.
           MOVE LENGTH OF HTTP-ECR-VALUE      TO ECR-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-ECR)
                NAMELENGTH (ZFAM-ECR-LENGTH)
                VALUE      (HTTP-ECR-VALUE)
                VALUELENGTH(ECR-VALUE-LENGTH)
                RESP       (ECR-RESP)
                NOHANDLE
           END-EXEC.

       1620-EXIT.
           EXIT.

      *****************************************************************
      * Process HTTP request.                                         *
      *****************************************************************
       2000-PROCESS-REQUEST.
           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-GET
               PERFORM 3000-READ-ZFAM      THRU 3000-EXIT
               PERFORM 3600-SEND-RESPONSE  THRU 3600-EXIT.

           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-POST
               PERFORM 4000-GET-COUNTER    THRU 4000-EXIT
               PERFORM 4100-WRITE-KEY      THRU 4100-EXIT
               PERFORM 4200-PROCESS-FILE   THRU 4200-EXIT
               PERFORM 4300-SEND-RESPONSE  THRU 4300-EXIT.

           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-DELETE
               PERFORM 5000-READ-KEY       THRU 5000-EXIT
               PERFORM 5100-DELETE-KEY     THRU 5100-EXIT
               PERFORM 5200-DELETE-FILE    THRU 5200-EXIT
                   WITH TEST AFTER
                   VARYING FF-SEGMENT      FROM 1 BY 1
                   UNTIL EIBRESP NOT EQUAL DFHRESP(NORMAL)
               PERFORM 5300-SEND-RESPONSE  THRU 5300-EXIT.

           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-PUT
           AND APP-RESP NOT   EQUAL DFHRESP(NORMAL)
               PERFORM 6000-READ-KEY       THRU 6000-EXIT
               PERFORM 6100-GET-COUNTER    THRU 6100-EXIT
               PERFORM 6200-PROCESS-FILE   THRU 6200-EXIT
               PERFORM 6300-REWRITE-KEY    THRU 6300-EXIT
               PERFORM 6400-SEND-RESPONSE  THRU 6400-EXIT.

           IF  WEB-HTTPMETHOD EQUAL WEB-HTTP-PUT
           AND APP-RESP       EQUAL DFHRESP(NORMAL)
               PERFORM 7000-READ-KEY       THRU 7000-EXIT
               PERFORM 7200-PROCESS-FILE   THRU 7200-EXIT
               PERFORM 7300-REWRITE-FK     THRU 7300-EXIT
               PERFORM 7400-SEND-RESPONSE  THRU 7400-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Perform the READ process.                                     *
      *****************************************************************
       3000-READ-ZFAM.
           IF  LOB-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 3700-LOB        THRU 3700-EXIT.

           PERFORM 3100-READ-PROCESS   THRU 3100-EXIT
               WITH TEST AFTER
               UNTIL PROCESS-COMPLETE  EQUAL 'Y'.
       3000-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      *                                                               *
      * Read the KEY store, which containes the FILE/DATA store key.  *
      *                                                               *
      * Read the FILE/DATA store, which contains the zFAM data as     *
      * record segments.                                              *
      *****************************************************************
       3100-READ-PROCESS.
           MOVE 'Y'                          TO PROCESS-COMPLETE.

           PERFORM 3120-GET-HEADERS        THRU 3120-EXIT.
           IF  HTTP-LOCK-VALUE NOT EQUAL 'yes'
               PERFORM 3200-READ-KEY       THRU 3200-EXIT.

           IF  HTTP-LOCK-VALUE     EQUAL 'yes'
               PERFORM 3220-LOCK-PROCESS   THRU 3220-EXIT
               WITH TEST AFTER
               UNTIL LOCK-OBTAINED EQUAL 'Y'.

           IF  FK-ECR NOT EQUAL 'Y'
               PERFORM 3300-READ-FILE      THRU 3300-EXIT.

           IF  FK-ECR NOT EQUAL 'Y'
               IF  FF-SUCCESSFUL   EQUAL 'Y'
                   PERFORM 3400-STAGE      THRU 3400-EXIT.
       3100-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Get HTTP headers for row level locking.                       *
      *****************************************************************
       3120-GET-HEADERS.
           MOVE LENGTH OF HTTP-LOCK           TO ZFAM-LOCK-LENGTH.
           MOVE LENGTH OF HTTP-LOCK-VALUE     TO LOCK-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-LOCK)
                NAMELENGTH (ZFAM-LOCK-LENGTH)
                VALUE      (HTTP-LOCK-VALUE)
                VALUELENGTH(LOCK-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'no '                     TO HTTP-LOCK-VALUE.

           MOVE LENGTH OF HTTP-TIME           TO ZFAM-TIME-LENGTH.
           MOVE LENGTH OF HTTP-TIME-VALUE     TO TIME-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-TIME)
                NAMELENGTH (ZFAM-TIME-LENGTH)
                VALUE      (HTTP-TIME-VALUE)
                VALUELENGTH(TIME-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FIVE                      TO HTTP-TIME-VALUE.

           IF  HTTP-TIME-VALUE NOT NUMERIC
               MOVE FIVE                      TO HTTP-TIME-VALUE.

           IF  HTTP-TIME-VALUE LESS THAN ONE
               MOVE ONE                       TO HTTP-TIME-VALUE.

           IF  HTTP-TIME-VALUE GREATER THAN FIVE
               MOVE FIVE                      TO HTTP-TIME-VALUE.

           MOVE LENGTH OF HTTP-ACTION         TO ZFAM-ACTION-LENGTH.
           MOVE LENGTH OF HTTP-ACTION-VALUE   TO ACTION-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-ACTION)
                NAMELENGTH (ZFAM-ACTION-LENGTH)
                VALUE      (HTTP-ACTION-VALUE)
                VALUELENGTH(ACTION-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'wait  '                  TO HTTP-ACTION-VALUE.

           IF  HTTP-ACTION-VALUE NOT EQUAL 'nowait'   AND
               HTTP-ACTION-VALUE NOT EQUAL 'wait  '
               MOVE 'wait  '                  TO HTTP-ACTION-VALUE.

       3120-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Read zFAM KEY store.                                          *
      *****************************************************************
       3200-READ-KEY.

           MOVE URI-KEY TO FK-KEY.
           MOVE LENGTH  OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE '3200'                      TO KE-PARAGRAPH
           PERFORM 3290-CHECK-RESPONSE    THRU 3290-EXIT.

           IF  FK-LOB EQUAL 'L'
               MOVE 'Y'                     TO READ-KEY
               PERFORM 3700-LOB           THRU 3700-EXIT.

       3200-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Get row level lock.                                           *
      *****************************************************************
       3220-LOCK-PROCESS.
           MOVE 'N' TO LOCK-OBTAINED.
           MOVE 'Y' TO ROW-LOCKED.

           PERFORM 3230-READ-KEY-UPDATE    THRU 3230-EXIT.
           PERFORM 3240-CHECK-LOCK         THRU 3240-EXIT.
           IF  ROW-LOCKED EQUAL 'N'
               PERFORM 3250-REWRITE-KEY    THRU 3250-EXIT.

           IF  ROW-LOCKED EQUAL 'Y'
               PERFORM 3260-UNLOCK-KEY     THRU 3260-EXIT
               PERFORM 3270-WAIT           THRU 3270-EXIT.
       3220-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Issue READ UPDATE for KEY store record when row level lock    *
      * has been requested.                                           *
      *****************************************************************
       3230-READ-KEY-UPDATE.
           MOVE URI-KEY                      TO FK-KEY.
           MOVE LENGTH  OF FK-RECORD         TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                UPDATE
                NOHANDLE
           END-EXEC.

           MOVE '3230'                       TO KE-PARAGRAPH.
           PERFORM 3290-CHECK-RESPONSE     THRU 3290-EXIT.

           IF  FK-LOB EQUAL 'L'
           AND FK-SEGMENTS GREATER THAN ONE-HUNDRED
               MOVE 'Y'                     TO READ-KEY
               PERFORM 3700-LOB           THRU 3700-EXIT.

       3230-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Check for an active lock.                                     *
      *****************************************************************
       3240-CHECK-LOCK.
           IF  FK-UID     EQUAL SPACES
           OR  FK-UID     EQUAL LOW-VALUES
           OR  FK-UID     EQUAL ZUID-UID
               MOVE 'Y' TO LOCK-OBTAINED
               MOVE 'N' TO ROW-LOCKED
           ELSE
               PERFORM 3242-CHECK-EXPIRED  THRU 3242-EXIT.

       3240-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Check for an expired lock.                                    *
      *****************************************************************
       3242-CHECK-EXPIRED.
           IF  HTTP-ACTION-VALUE EQUAL 'nowait'
               PERFORM 3280-LOCK-FAIL THRU 3280-EXIT.

           SUBTRACT FK-ABS FROM WS-ABS GIVING RELATIVE-TIME.

           MOVE FK-LOCK-TIME            TO LOCK-SECONDS.
           MOVE LOCK-TIME               TO LOCK-MILLISECONDS.

           IF  RELATIVE-TIME GREATER THAN LOCK-MILLISECONDS
           OR  RELATIVE-TIME EQUAL        LOCK-MILLISECONDS
               MOVE 'Y'                 TO LOCK-OBTAINED
               MOVE 'N'                 TO ROW-LOCKED.

       3242-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Issue REWRITE for FAxxKEY with ROW LEVEL LOCKING parameters.  *
      *****************************************************************
       3250-REWRITE-KEY.
           MOVE 'PLAIN'                      TO ZUID-FORMAT.
           MOVE 'LINK'                       TO ZUID-TYPE.

           EXEC CICS LINK
                PROGRAM (ZUID001)
                COMMAREA(ZUID001-COMMAREA)
                LENGTH  (COMMAREA-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE ZUID-UID                     TO FK-UID.
           MOVE WS-ABS                       TO FK-ABS.
           MOVE HTTP-TIME-VALUE              TO FK-LOCK-TIME.

           EXEC CICS REWRITE FILE(FK-FCT)
                FROM(FK-RECORD)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF HTTP-STATUS        TO ZFAM-STATUS-LENGTH.
           MOVE LENGTH OF HTTP-STATUS-VALUE  TO STATUS-VALUE-LENGTH.
           MOVE LOCK-SUCCESSFUL              TO HTTP-STATUS-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-STATUS)
                NAMELENGTH (ZFAM-STATUS-LENGTH)
                VALUE      (HTTP-STATUS-VALUE)
                VALUELENGTH(STATUS-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF HTTP-LOCKID        TO ZFAM-LOCKID-LENGTH.
           MOVE LENGTH OF HTTP-LOCKID-VALUE  TO LOCKID-VALUE-LENGTH.
           MOVE ZUID-UID                     TO HTTP-LOCKID-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-LOCKID)
                NAMELENGTH (ZFAM-LOCKID-LENGTH)
                VALUE      (HTTP-LOCKID-VALUE)
                VALUELENGTH(LOCKID-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

       3250-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Issue UNLOCK  for KEY store record.                           *
      *****************************************************************
       3260-UNLOCK-KEY.
           EXEC CICS UNLOCK  FILE(FK-FCT)
                NOHANDLE
           END-EXEC.

       3260-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Issue 'wait' for an active lock to be released or expire.     *
      * This routine will call L8WAIT for 100 milliseconds up to      *
      * 50 times, before returning a 'locked' status.                 *
      *****************************************************************
       3270-WAIT.
           ADD ONE TO WAIT-COUNT.

           EXEC CICS LINK PROGRAM(L8WAIT)
                COMMAREA(L8WAIT-COMMAREA)
                NOHANDLE
           END-EXEC.

           IF  WAIT-COUNT EQUAL        FIFTY
           OR  WAIT-COUNT GREATER THAN FIFTY
               PERFORM 3280-LOCK-FAIL     THRU 3280-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       3270-EXIT.
           EXIT.

      *****************************************************************
      * Unable to establish row level locking.                        *
      * Create a status header and send a response.                   *
      *****************************************************************
       3280-LOCK-FAIL.
           MOVE LENGTH OF HTTP-STATUS         TO ZFAM-STATUS-LENGTH.
           MOVE LENGTH OF HTTP-STATUS-VALUE   TO STATUS-VALUE-LENGTH.

           MOVE LOCK-REJECTED                 TO HTTP-STATUS-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-STATUS)
                NAMELENGTH (ZFAM-STATUS-LENGTH)
                VALUE      (HTTP-STATUS-VALUE)
                VALUELENGTH(STATUS-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE STATUS-409                    TO CA090-STATUS
           MOVE '01'                          TO CA090-REASON
           PERFORM 9998-ZFAM090             THRU 9998-EXIT.

       3280-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Check READ KEY store response.                                *
      *****************************************************************
       3290-CHECK-RESPONSE.
           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-204              TO CA090-STATUS
               MOVE '01'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                  TO KE-FN
               MOVE '3290'                   TO KE-PARAGRAPH
               PERFORM 9200-KEY-ERROR      THRU 9200-EXIT
               MOVE EIBDS                    TO CA090-FILE
               MOVE STATUS-507               TO CA090-STATUS
               MOVE '01'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

           IF  FK-DDNAME NOT EQUAL SPACES
               MOVE FK-DDNAME               TO FF-DDNAME.

           IF  FK-FF-KEY EQUAL INTERNAL-KEY
               MOVE FK-FF-KEY               TO 50702-KEY
               MOVE 50702-MESSAGE           TO TD-MESSAGE
               PERFORM 9900-WRITE-CSSL    THRU 9900-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '02'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       3290-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Read zFAM FILE store.                                         *
      * Only update access timestamp when LAT is present in the URI.  *
      * A logical record can span one hundred physical records.       *
      *****************************************************************
       3300-READ-FILE.
           MOVE 'Y'                         TO FF-SUCCESSFUL.

           UNSTRING URI-FIELD-06
               DELIMITED BY ALL '.'
               INTO URI-FIELD-00
                    RET-TYPE.

           MOVE FK-FF-KEY                   TO FF-KEY.
           MOVE ZEROES                      TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD         TO FF-LENGTH.

           MOVE ONE                         TO FF-SEGMENT.

           IF  RET-TYPE EQUAL LAST-ACCESS-TIME
               EXEC CICS READ FILE(FF-FCT)
                    INTO(FF-RECORD)
                    RIDFLD(FF-KEY-16)
                    LENGTH(FF-LENGTH)
                    UPDATE
                    NOHANDLE
               END-EXEC

               MOVE WS-ABS                  TO FF-ABS

               MOVE FC-REWRITE              TO FE-FN

               EXEC CICS REWRITE FILE(FF-FCT)
                    FROM(FF-RECORD)
                    LENGTH(FF-LENGTH)
                    NOHANDLE
               END-EXEC
           ELSE
               MOVE FC-READ                 TO FE-FN
               EXEC CICS READ FILE(FF-FCT)
                    INTO(FF-RECORD)
                    RIDFLD(FF-KEY-16)
                    LENGTH(FF-LENGTH)
                    NOHANDLE
               END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NOTFND)
               MOVE FK-FF-KEY               TO INTERNAL-KEY
               MOVE 'N'                     TO PROCESS-COMPLETE
               MOVE 'N'                     TO FF-SUCCESSFUL.

           IF  EIBRESP EQUAL DFHRESP(NOTFND)
           OR  EIBRESP EQUAL DFHRESP(NORMAL)
               NEXT SENTENCE
           ELSE
               MOVE FC-READ                 TO FE-FN
               MOVE '3300'                  TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR    THRU 9100-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '03'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       3300-EXIT.
           EXIT.

      *****************************************************************
      * Issue GETMAIN only when multiple segments.                    *
      * When the logical record is a single segment, set the          *
      * ZFAM-MESSAGE buffer in the LINKAGE SECTION to the record      *
      * buffer address.                                               *
      *****************************************************************
       3400-STAGE.
           IF  FF-SEGMENT EQUAL ZEROES
               MOVE ONE                        TO FF-SEGMENT.

           IF  FF-SEGMENTS EQUAL ONE
               SUBTRACT FF-PREFIX            FROM FF-LENGTH
               SET  ADDRESS OF ZFAM-MESSAGE    TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               MULTIPLY FF-SEGMENTS BY THIRTY-TWO-KB
                   GIVING GETMAIN-LENGTH

               EXEC CICS GETMAIN SET(ZFAM-ADDRESS)
                    FLENGTH(GETMAIN-LENGTH)
                    INITIMG(BINARY-ZEROES)
                    NOHANDLE
               END-EXEC

               SET ADDRESS OF ZFAM-MESSAGE     TO ZFAM-ADDRESS
               MOVE ZFAM-ADDRESS-X             TO SAVE-ADDRESS-X

               SUBTRACT FF-PREFIX            FROM FF-LENGTH
               MOVE FF-DATA(1:FF-LENGTH)       TO ZFAM-MESSAGE
               ADD  FF-LENGTH                  TO ZFAM-ADDRESS-X.

           ADD  ONE                            TO FF-SEGMENT.
           MOVE FF-LENGTH                      TO ZFAM-LENGTH.

           IF  FF-SEGMENTS GREATER THAN ONE
               PERFORM 3500-READ-SEGMENTS    THRU 3500-EXIT
                   WITH TEST AFTER
                   UNTIL FF-SEGMENT GREATER  THAN FF-SEGMENTS
                   OR    FF-SUCCESSFUL EQUAL 'N'.

       3400-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Read zFAM FILE segment records                                *
      *****************************************************************
       3500-READ-SEGMENTS.
           SET ADDRESS OF ZFAM-MESSAGE         TO ZFAM-ADDRESS.
           MOVE LENGTH OF FF-RECORD            TO FF-LENGTH.

           EXEC CICS READ FILE(FF-FCT)
                INTO(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               SUBTRACT FF-PREFIX            FROM FF-LENGTH
               MOVE FF-DATA(1:FF-LENGTH)       TO ZFAM-MESSAGE
               ADD  FF-LENGTH                  TO ZFAM-ADDRESS-X
               ADD  ONE                        TO FF-SEGMENT
               ADD  FF-LENGTH                  TO ZFAM-LENGTH.

           IF  EIBRESP EQUAL DFHRESP(NOTFND)
               MOVE 'N'                        TO PROCESS-COMPLETE
               MOVE 'N'                        TO FF-SUCCESSFUL
               MOVE FK-FF-KEY                  TO INTERNAL-KEY
               PERFORM 3510-FREEMAIN         THRU 3510-EXIT.

           IF  EIBRESP EQUAL DFHRESP(NOTFND)
           OR  EIBRESP EQUAL DFHRESP(NORMAL)
               NEXT SENTENCE
           ELSE
               MOVE FC-READ                    TO FE-FN
               MOVE '3500'                     TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR       THRU 9100-EXIT
               MOVE EIBDS                      TO CA090-FILE
               MOVE STATUS-507                 TO CA090-STATUS
               MOVE '04'                       TO CA090-REASON
               PERFORM 9998-ZFAM090          THRU 9998-EXIT.

       3500-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * FREEMAIN message segment buffer                               *
      * This is required to reprocess a READ request when a KEY store *
      * record has performed an internal key swap for the FILE/DATA   *
      * store record on an UPDATE (PUT).                              *
      *****************************************************************
       3510-FREEMAIN.
           EXEC CICS FREEMAIN
                DATAPOINTER(SAVE-ADDRESS)
                NOHANDLE
           END-EXEC.

       3510-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Send zFAM response.                                           *
      *****************************************************************
       3600-SEND-RESPONSE.
           IF  FK-ECR NOT EQUAL 'Y'
               PERFORM 3610-SEND-RECORD    THRU 3610-EXIT.

           IF  FK-ECR     EQUAL 'Y'
               PERFORM 3620-SEND-ECR       THRU 3620-EXIT.

       3600-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Send zFAM record.                                             *
      *                                                               *
      * When MEDIATYPE is 'text/*', convert the data, as this         *
      * information is accessed by both z/OS applications             *
      * and those applications in darkness (Unix/Linux based).        *
      *****************************************************************
       3610-SEND-RECORD.
           IF  FF-SEGMENTS EQUAL ONE
               SET ADDRESS OF ZFAM-MESSAGE   TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               SET ADDRESS OF ZFAM-MESSAGE   TO SAVE-ADDRESS.

           MOVE FF-MEDIA                     TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN               TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)          TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               EXEC CICS WEB SEND
                    FROM      (ZFAM-MESSAGE)
                    FROMLENGTH(ZFAM-LENGTH)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    STATUSCODE(HTTP-STATUS-200)
                    STATUSTEXT(HTTP-OK)
                    ACTION    (SEND-ACTION)
                    SRVCONVERT
                    NOHANDLE
               END-EXEC
           ELSE
               EXEC CICS WEB SEND
                    FROM      (ZFAM-MESSAGE)
                    FROMLENGTH(ZFAM-LENGTH)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    STATUSCODE(HTTP-STATUS-200)
                    STATUSTEXT(HTTP-OK)
                    ACTION    (SEND-ACTION)
                    NOSRVCONVERT
                    NOHANDLE
               END-EXEC.

       3610-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Send zFAM Event Control Record.                               *
      *                                                               *
      * An Event Control Record is Record Key only and corresponding  *
      * zFAM header.                                                  *
      *****************************************************************
       3620-SEND-ECR.
           PERFORM 9400-WRITE-ECR    THRU 9400-EXIT.

           MOVE TEXT-PLAIN             TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)    TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           EXEC CICS WEB SEND
                FROM      (URI-KEY)
                FROMLENGTH(URI-KEY-LENGTH)
                MEDIATYPE (WEB-MEDIA-TYPE)
                STATUSCODE(HTTP-STATUS-200)
                STATUSTEXT(HTTP-OK)
                ACTION    (SEND-ACTION)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       3620-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Process LOB requests.                                         *
      *****************************************************************
       3700-LOB.
           IF  READ-KEY NOT EQUAL 'Y'
               PERFORM 3200-READ-KEY        THRU 3200-EXIT.

           MOVE ONE                           TO FF-SEGMENT.

           IF  FK-LOB     EQUAL 'L'
               PERFORM 3710-READ-FILE       THRU 3710-EXIT
                   WITH TEST AFTER
                   VARYING FF-SEGMENT FROM 1 BY 1
                   UNTIL   FF-SEGMENT EQUAL        FK-SEGMENTS
                   OR      FF-SEGMENT GREATER THAN FK-SEGMENTS.

           IF  FK-LOB NOT EQUAL 'L'
               PERFORM 3710-READ-FILE       THRU 3710-EXIT
                   WITH TEST AFTER
                   VARYING FF-SEGMENT FROM 1 BY 1
                   UNTIL   FF-SEGMENT EQUAL        FF-SEGMENTS
                   OR      FF-SEGMENT GREATER THAN FF-SEGMENTS.

           EXEC CICS WEB SEND
                CHUNKEND
                NOHANDLE
           END-EXEC.

           PERFORM 9000-RETURN      THRU 9000-EXIT.

       3700-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Read file store and send each segment as a chunked message.   *
      *****************************************************************
       3710-READ-FILE.
           MOVE FK-FF-KEY                  TO FF-KEY.
           MOVE ZEROES                     TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD        TO FF-LENGTH.

           MOVE FC-READ                    TO FE-FN
           EXEC CICS READ FILE(FF-FCT)
                INTO(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                TO FE-FN
               MOVE '3710'                 TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR   THRU 9100-EXIT
               MOVE EIBDS                  TO CA090-FILE
               MOVE STATUS-507             TO CA090-STATUS
               MOVE '10'                   TO CA090-REASON
               PERFORM 9998-ZFAM090      THRU 9998-EXIT.

           PERFORM 3720-SEND             THRU 3720-EXIT.

       3710-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET.                                                     *
      * Send each segment as a message chunk.                         *
      *****************************************************************
       3720-SEND.
           MOVE FF-MEDIA                     TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN               TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)          TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE DFHVALUE(SRVCONVERT)     TO SERVER-CONVERT
           ELSE
               MOVE DFHVALUE(NOSRVCONVERT)   TO SERVER-CONVERT.

           SUBTRACT FF-PREFIX              FROM FF-LENGTH
           MOVE FF-LENGTH                    TO ZFAM-LENGTH.

           IF  FF-SEGMENT EQUAL ONE
               EXEC CICS WEB SEND
                    FROM      (FF-DATA)
                    FROMLENGTH(ZFAM-LENGTH)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    STATUSCODE(HTTP-STATUS-200)
                    STATUSTEXT(HTTP-OK)
                    ACTION    (SEND-ACTION)
                    SERVERCONV(SERVER-CONVERT)
                    CHUNKYES
                    NOHANDLE
               END-EXEC.

           IF  FF-SEGMENT NOT EQUAL ONE
               EXEC CICS WEB SEND
                    FROM      (FF-DATA)
                    FROMLENGTH(ZFAM-LENGTH)
                    CHUNKYES
                    NOHANDLE
               END-EXEC.

       3720-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Get counter, which is used as zFAM FILE internal key.         *
      *****************************************************************
       4000-GET-COUNTER.

           EXEC CICS GET DCOUNTER(ZFAM-COUNTER)
                VALUE(ZFAM-NC-VALUE)
                INCREMENT(ZFAM-NC-INCREMENT)
                NOHANDLE
           END-EXEC.

       4000-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Write zFAM KEY store record.                                  *
      * If the record exists, send a HTTP status 409 and an HTTP text *
      * indicating a duplicate record condition.                      *
      *****************************************************************
       4100-WRITE-KEY.
           MOVE URI-KEY                     TO FK-KEY.
           MOVE LENGTH OF FK-RECORD         TO FK-LENGTH.

           PERFORM 4700-GET-HEADER        THRU 4700-EXIT.

           IF  HTTP-UID-VALUE NOT EQUAL 'yes'
           IF  URI-PATH-LENGTH EQUAL ZEROES
               MOVE STATUS-400              TO CA090-STATUS
               MOVE '07'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           CALL ZUIDSTCK USING BY REFERENCE THE-TOD.
           MOVE THE-TOD(1:6)                TO FK-FF-IDN.
           MOVE ZFAM-NC-HW                  TO FK-FF-NC.

           MOVE WS-ABS                      TO FK-ABS.
           IF  HTTP-ECR-VALUE EQUAL 'Yes'
               MOVE HIGH-VALUES             TO FK-FF-KEY
               MOVE 'Y'                     TO FK-ECR.

           PERFORM 8400-DDNAME            THRU 8400-EXIT.
           MOVE FF-DDNAME                   TO FK-DDNAME.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE 'text'                  TO FK-OBJECT
           ELSE
               MOVE 'bits'                  TO FK-OBJECT.

           PERFORM 9001-SEGMENTS          THRU 9001-EXIT.

           MOVE MAX-SEGMENT-COUNT           TO FK-SEGMENTS.
           IF  LOB-RESP EQUAL DFHRESP(NORMAL)
               MOVE 'L'                     TO FK-LOB.

           EXEC CICS WRITE FILE(FK-FCT)
                FROM(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                RESP(FK-RESP)
                NOHANDLE
           END-EXEC.

           IF  FK-RESP EQUAL DFHRESP(DUPREC)
               PERFORM 9400-WRITE-ECR     THRU 9400-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-409              TO CA090-STATUS
               MOVE '02'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  FK-RESP NOT EQUAL DFHRESP(NORMAL)
               MOVE '4100'                  TO KE-PARAGRAPH
               MOVE FC-WRITE                TO KE-FN
               PERFORM 9200-KEY-ERROR     THRU 9200-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '05'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       4100-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * When the zFAM-ECR header is present, do not process the       *
      * File Store information, as only the Key Store record will be  *
      * created.                                                      *
      *****************************************************************
       4200-PROCESS-FILE.
           IF  HTTP-ECR-VALUE NOT EQUAL 'Yes'
               PERFORM 4210-FILE-STORE    THRU 4210-EXIT.

       4200-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Write zFAM FILE store record                                  *
      * Store media-type for POST in FILE record.                     *
      * The media-type will be used for subsequent GET requests       *
      *****************************************************************
       4210-FILE-STORE.
           MOVE ZFAM-ADDRESS-X              TO SAVE-ADDRESS-X.

           MOVE FK-KEY                      TO FF-FK-KEY.
           MOVE FK-FF-KEY                   TO FF-KEY.
           MOVE ZEROES                      TO FF-ZEROES.
           MOVE WEB-MEDIA-TYPE              TO FF-MEDIA.

           MOVE MAX-SEGMENT-COUNT           TO FF-SEGMENTS.

           MOVE WS-ABS                      TO FF-ABS.

           PERFORM 4400-WRITE-FILE        THRU 4400-EXIT
               WITH TEST AFTER
               VARYING SEGMENT-COUNT FROM 1 BY 1 UNTIL
                       SEGMENT-COUNT EQUAL  MAX-SEGMENT-COUNT.

           PERFORM 4800-CI-PROCESS        THRU 4800-EXIT.

       4210-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Replicate across active/active Data Center.                   *
      * Send POST response.                                           *
      * Set IMMEDIATE action on WEB SEND command.                     *
      * Get URL and replication type from document template.          *
      * When ACTIVE-SINGLE,  there is no Data Center replication.     *
      * When ACTIVE-ACTIVE,  perfrom Data Center replicaiton before   *
      *      sending the response to the client.                      *
      * When ACTIVE-STANDBY, perform Data Center replication after    *
      *      sending the response to the client.                      *
      *****************************************************************
       4300-SEND-RESPONSE.
           IF  HTTP-UID-VALUE EQUAL 'yes'
               PERFORM 4310-WRITE-UID     THRU 4310-EXIT.

           IF  HTTP-MODULO-VALUE GREATER  THAN ZEROES
               PERFORM 4320-WRITE-MODULO  THRU 4320-EXIT.

           IF  LOB-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 4330-WRITE-LOB     THRU 4330-EXIT.

           IF  ECR-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 9400-WRITE-ECR     THRU 9400-EXIT.

           PERFORM 8000-GET-URL           THRU 8000-EXIT.

           IF  DC-TYPE        EQUAL ACTIVE-ACTIVE
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 4500-REPLICATE     THRU 4500-EXIT.

           MOVE DFHVALUE(IMMEDIATE)         TO SEND-ACTION.

           EXEC CICS WEB SEND
                FROM      (CRLF)
                FROMLENGTH(TWO)
                MEDIATYPE (TEXT-PLAIN)
                ACTION    (SEND-ACTION)
                STATUSCODE(HTTP-STATUS-200)
                STATUSTEXT(HTTP-OK)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

           IF  DC-TYPE        EQUAL ACTIVE-STANDBY
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 4500-REPLICATE     THRU 4500-EXIT.

       4300-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE HTTPHEADER for the zUID created.                  *
      *****************************************************************
       4310-WRITE-UID.
           MOVE LENGTH OF HTTP-UID          TO ZFAM-UID-LENGTH.
           MOVE LENGTH OF THE-UNIQUE-KEY    TO UID-VALUE-LENGTH.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-UID)
                NAMELENGTH (ZFAM-UID-LENGTH)
                VALUE      (THE-UNIQUE-KEY)
                VALUELENGTH(UID-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

       4310-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE HTTPHEADER for the Modulo created.                *
      *****************************************************************
       4320-WRITE-MODULO.
           MOVE LENGTH OF HTTP-MODULO       TO ZFAM-MODULO-LENGTH.
           MOVE LENGTH OF THE-MODULO        TO MODULO-VALUE-LENGTH.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-MODULO)
                NAMELENGTH (ZFAM-MODULO-LENGTH)
                VALUE      (THE-MODULO)
                VALUELENGTH(MODULO-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.


       4320-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE HTTPHEADER for the LOB replication.               *
      *****************************************************************
       4330-WRITE-LOB.
           MOVE LENGTH OF HTTP-LOB          TO ZFAM-LOB-LENGTH.
           MOVE LENGTH OF HTTP-LOB-VALUE    TO LOB-VALUE-LENGTH.
           MOVE 'Yes'                       TO HTTP-LOB-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-LOB)
                NAMELENGTH (ZFAM-LOB-LENGTH)
                VALUE      (HTTP-LOB-VALUE)
                VALUELENGTH(LOB-VALUE-LENGTH)
                RESP       (LOB-RESP)
                NOHANDLE
           END-EXEC.

       4330-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Write zFAM FILE store record.                                 *
      * A logical record can span one hundred 32,000 byte segments.   *
      *****************************************************************
       4400-WRITE-FILE.
           SET ADDRESS OF ZFAM-MESSAGE      TO ZFAM-ADDRESS.
           MOVE SEGMENT-COUNT               TO FF-SEGMENT.

           IF  UNSEGMENTED-LENGTH LESS THAN OR EQUAL THIRTY-TWO-KB
               MOVE UNSEGMENTED-LENGTH      TO FF-LENGTH
           ELSE
               MOVE THIRTY-TWO-KB           TO FF-LENGTH.

           MOVE LOW-VALUES                  TO FF-DATA.
           MOVE ZFAM-MESSAGE(1:FF-LENGTH)   TO FF-DATA.
           ADD  FF-PREFIX TO FF-LENGTH.

           EXEC CICS WRITE FILE(FF-FCT)
                FROM(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-WRITE                TO FE-FN
               MOVE '4400'                  TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR    THRU 9100-EXIT
               PERFORM 9999-ROLLBACK      THRU 9999-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '06'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  UNSEGMENTED-LENGTH GREATER THAN  OR EQUAL THIRTY-TWO-KB
               SUBTRACT THIRTY-TWO-KB     FROM UNSEGMENTED-LENGTH
               ADD      THIRTY-TWO-KB       TO ZFAM-ADDRESS-X.

       4400-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Replicate POST     request to alternate Data Center.          *
      *****************************************************************
       4500-REPLICATE.

           PERFORM 8100-WEB-OPEN          THRU 8100-EXIT.

           IF  HTTP-ECR-VALUE NOT EQUAL 'Yes'
               MOVE DFHVALUE(POST)          TO WEB-METHOD
               PERFORM 8200-WEB-CONVERSE  THRU 8200-EXIT.

           IF  HTTP-ECR-VALUE     EQUAL 'Yes'
               MOVE DFHVALUE(POST)          TO WEB-METHOD
               PERFORM 8210-WEB-CONVERSE  THRU 8210-EXIT.

           PERFORM 8300-WEB-CLOSE         THRU 8300-EXIT.

       4500-EXIT.
           EXIT.


      *****************************************************************
      * HTTP POST.                                                    *
      * Get HTTP headers for UID and MODULO generation.               *
      *****************************************************************
       4700-GET-HEADER.
           MOVE LENGTH OF HTTP-UID            TO ZFAM-UID-LENGTH.
           MOVE LENGTH OF HTTP-UID-VALUE      TO UID-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-UID)
                NAMELENGTH (ZFAM-UID-LENGTH)
                VALUE      (HTTP-UID-VALUE)
                VALUELENGTH(UID-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'no '                     TO HTTP-UID-VALUE.

           MOVE LENGTH OF HTTP-MODULO         TO ZFAM-MODULO-LENGTH.
           MOVE LENGTH OF HTTP-MODULO-VALUE   TO MODULO-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-MODULO)
                NAMELENGTH (ZFAM-MODULO-LENGTH)
                VALUE      (HTTP-MODULO-VALUE)
                VALUELENGTH(MODULO-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE ZEROES                    TO HTTP-MODULO-VALUE.

           IF  HTTP-MODULO-VALUE NOT NUMERIC
               MOVE ZEROES                    TO HTTP-MODULO-VALUE.

           IF  MODULO-VALUE-LENGTH EQUAL ONE
               MOVE HTTP-MODULO-VALUE(1:1)    TO HTTP-MODULO-VALUE(2:1)
               MOVE ZERO                      TO HTTP-MODULO-VALUE(1:1).

           IF  HTTP-MODULO-VALUE LESS THAN ONE
               MOVE ZEROES                    TO HTTP-MODULO-VALUE.

           IF  HTTP-UID-VALUE EQUAL 'yes'
               PERFORM 4710-LINK-ZUID001    THRU 4710-EXIT
               MOVE LOW-VALUES                TO FK-KEY
               MOVE THE-UNIQUE-KEY(1:32)      TO FK-KEY(1:32).

           IF  HTTP-MODULO-VALUE GREATER THAN ZEROES AND
               HTTP-UID-VALUE    EQUAL  'yes'
               PERFORM 4720-GET-MODULO      THRU 4720-EXIT
                   WITH TEST AFTER
                   UNTIL ZFAM-MOD-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 4740-QUERY-MODULO    THRU 4740-EXIT
               MOVE LOW-VALUES                TO FK-KEY
               MOVE THE-MODULO-KEY(1:37)      TO FK-KEY(1:37).

       4700-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue LINK to zUID001 to obtain a Unique ID for the key.      *
      *****************************************************************
       4710-LINK-ZUID001.
           MOVE 'PLAIN'                      TO ZUID-FORMAT.
           MOVE 'LINK'                       TO ZUID-TYPE.

           EXEC CICS LINK
                PROGRAM (ZUID001)
                COMMAREA(ZUID001-COMMAREA)
                LENGTH  (COMMAREA-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE ZUID-UID                     TO THE-UNIQUE-KEY.

       4710-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue GET COUNTER for current modulo.                         *
      *****************************************************************
       4720-GET-MODULO.
           MOVE EIBTRNID                     TO NC-MOD-TRANID.

           EXEC CICS GET
                COUNTER   (ZFAM-MOD-COUNTER)
                VALUE     (ZFAM-MOD-VALUE)
                INCREMENT (ZFAM-MOD-INCREMENT)
                RESP      (ZFAM-MOD-RESP)
                WRAP
                NOHANDLE
           END-EXEC.

           IF  ZFAM-MOD-RESP NOT EQUAL DFHRESP(NORMAL)
               PERFORM 4730-DEFINE-MODULO  THRU 4730-EXIT.

           MOVE ZFAM-MOD-VALUE               TO THE-MODULO.

       4720-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue DEFINE COUNTER for a modulo request.                    *
      *****************************************************************
       4730-DEFINE-MODULO.
           MOVE HTTP-MODULO-VALUE            TO ZFAM-MOD-MAXIMUM.
           MOVE ONE                          TO ZFAM-MOD-MINIMUM.
           MOVE ONE                          TO ZFAM-MOD-VALUE.

           EXEC CICS DEFINE
                COUNTER   (ZFAM-MOD-COUNTER)
                VALUE     (ZFAM-MOD-VALUE)
                MINIMUM   (ZFAM-MOD-MINIMUM)
                MAXIMUM   (ZFAM-MOD-MAXIMUM)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               PERFORM 9300-NC-ERROR       THRU 9300-EXIT
               MOVE STATUS-400               TO CA090-STATUS
               MOVE '08'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

       4730-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue QUERY  COUNTER for a modulo request.                    *
      * If the requested modulo is different than the maximum,        *
      * 1).  Issue an ENQ to serialize the request.                   *
      * 2).  Issue a  DELETE/DEFINE COUNTER with new modulo maximum.  *
      * 3).  Issue a  DEQ                                             *
      *****************************************************************
       4740-QUERY-MODULO.
           EXEC CICS QUERY
                COUNTER   (ZFAM-MOD-COUNTER)
                VALUE     (ZFAM-MOD-VALUE)
                MINIMUM   (ZFAM-MOD-MINIMUM)
                MAXIMUM   (ZFAM-MOD-MAXIMUM)
                NOHANDLE
           END-EXEC.

           IF  ZFAM-MOD-MAXIMUM NOT EQUAL HTTP-MODULO-VALUE
               PERFORM 4750-ENQ           THRU 4750-EXIT
               PERFORM 4760-DELETE-MODULO THRU 4760-EXIT
               PERFORM 4770-DEQ           THRU 4770-DEQ.

       4740-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue ENQ to serialize DELETE/DEFINE COUNTER.                 *
      *****************************************************************
       4750-ENQ.
           MOVE EIBTRNID                    TO NQ-MOD-TRANID.
           MOVE LENGTH OF ZFAM-MOD-ENQUEUE  TO NQ-MOD-LENGTH.
           EXEC CICS ENQ
                RESOURCE  (ZFAM-MOD-ENQUEUE)
                LENGTH    (NQ-MOD-LENGTH)
                RESP      (ENQRESP)
                NOSUSPEND
                NOHANDLE
           END-EXEC.

       4750-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue DELETE COUNTER for a modulo request.                    *
      * Issue DEFINE COUNTER for a modulo request.                    *
      *****************************************************************
       4760-DELETE-MODULO.
           IF  ENQRESP EQUAL DFHRESP(NORMAL)
               EXEC CICS DELETE
                    COUNTER   (ZFAM-MOD-COUNTER)
                    NOHANDLE
               END-EXEC

               PERFORM 4730-DEFINE-MODULO     THRU 4730-EXIT.

       4760-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue DEQ.                                                    *
      *****************************************************************
       4770-DEQ.
           MOVE EIBTRNID                    TO NQ-MOD-TRANID.
           MOVE LENGTH OF ZFAM-MOD-ENQUEUE  TO NQ-MOD-LENGTH.
           EXEC CICS DEQ
                RESOURCE  (ZFAM-MOD-ENQUEUE)
                LENGTH    (NQ-MOD-LENGTH)
                NOHANDLE
           END-EXEC.

       4770-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue LINK to zFAM011 for secondary column index process.     *
      *****************************************************************
       4800-CI-PROCESS.
           EXEC CICS GET CONTAINER(ZFAM-FAXXFD)
                FLENGTH(CONTAINER-LENGTH)
                CHANNEL(ZFAM-CHANNEL)
                NODATA
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               PERFORM 4810-LINK-ZFAM011      THRU 4810-EXIT.

       4800-EXIT.
           EXIT.

      *****************************************************************
      * HTTP POST.                                                    *
      * Issue LINK to zFAM011 for secondary column index process.     *
      *****************************************************************
       4810-LINK-ZFAM011.
           SET ADDRESS OF ZFAM-MESSAGE TO SAVE-ADDRESS.

           EXEC CICS PUT CONTAINER(ZFAM-NEW-REC)
                FROM   (SAVE-ADDRESS-X)
                FLENGTH(LENGTH OF SAVE-ADDRESS-X)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-NEW-KEY)
                FROM   (FK-FF-KEY)
                FLENGTH(LENGTH OF FK-FF-KEY)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS LINK PROGRAM(ZFAM011)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

       4810-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE                                                   *
      * Read zFAM KEY store.                                          *
      *****************************************************************
       5000-READ-KEY.

           PERFORM 5010-HTTP-HEADER            THRU 5010-EXIT.

           IF  URI-PATH-LENGTH EQUAL ZEROES
               MOVE STATUS-400                   TO CA090-STATUS
               MOVE '06'                         TO CA090-REASON
               PERFORM 9998-ZFAM090            THRU 9998-EXIT.

           MOVE URI-KEY TO FK-KEY.
           MOVE LENGTH  OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE EIBDS                        TO CA090-FILE
               MOVE STATUS-204                   TO CA090-STATUS
               MOVE '02'                         TO CA090-REASON
               PERFORM 9998-ZFAM090            THRU 9998-EXIT.

           IF  WEB-PATH(1:10) EQUAL DEPLICATE
               PERFORM 5500-DEPLICATE-DELETE   THRU 5500-EXIT.

           IF  FK-DDNAME NOT EQUAL SPACES
               MOVE FK-DDNAME                    TO FF-DDNAME.

           PERFORM 5800-OLD-RECORD             THRU 5800-EXIT.

       5000-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeBegin and zFAM-RangeEnd HTTP headers.         *
      * When present, XCTL to zFAM003 to delete all records within    *
      * the range.                                                    *
      *****************************************************************
       5010-HTTP-HEADER.
           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-BEGIN)
                NAMELENGTH  (HEADER-BEGIN-LENGTH)
                VALUE       (BEGIN-VALUE)
                VALUELENGTH (BEGIN-VALUE-LENGTH)
                RESP        (BEGIN-RESPONSE)
                NOHANDLE
           END-EXEC.

           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-END)
                NAMELENGTH  (HEADER-END-LENGTH)
                VALUE       (END-VALUE)
                VALUELENGTH (END-VALUE-LENGTH)
                RESP        (END-RESPONSE)
                NOHANDLE
           END-EXEC.

           IF  BEGIN-RESPONSE EQUAL DFHRESP(NORMAL)
           AND   END-RESPONSE EQUAL DFHRESP(NORMAL)
               PERFORM 5020-RANGE          THRU 5020-EXIT.

           IF  BEGIN-RESPONSE EQUAL DFHRESP(NORMAL)
           OR    END-RESPONSE EQUAL DFHRESP(NORMAL)
               MOVE STATUS-400               TO CA090-STATUS
               MOVE '10'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

       5010-EXIT.
           EXIT.


      *****************************************************************
      * Check zFAM-RangeBegin and zFAM-RangeEnd for correct range.    *
      *****************************************************************
       5020-RANGE.
           IF  BEGIN-VALUE LESS THAN END-VALUE
           OR  BEGIN-VALUE EQUAL     END-VALUE
               EXEC CICS XCTL PROGRAM(ZFAM003)
                    COMMAREA(ZFAM003-COMM-AREA)
                    NOHANDLE
               END-EXEC.

           MOVE STATUS-400                   TO CA090-STATUS.
           MOVE '11'                         TO CA090-REASON.
           PERFORM 9998-ZFAM090            THRU 9998-EXIT.

       5020-EXIT.
           EXIT.


      *****************************************************************
      * HTTP DELETE                                                   *
      * Delete zFAM KEY store record.                                 *
      *****************************************************************
       5100-DELETE-KEY.

           EXEC CICS DELETE FILE(FK-FCT)
                RIDFLD(FK-KEY)
                NOHANDLE
           END-EXEC.

       5100-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE                                                   *
      * Delete zFAM FILE store record                                 *
      *****************************************************************
       5200-DELETE-FILE.
           MOVE FK-FF-KEY               TO FF-KEY.
           MOVE ZEROES                  TO FF-ZEROES.

           IF  FK-ECR EQUAL 'Y'
               MOVE LOW-VALUES          TO FF-KEY.

           EXEC CICS DELETE FILE(FF-FCT)
                RIDFLD(FF-KEY-16)
                NOHANDLE
           END-EXEC.

       5200-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE                                                   *
      * Replicate across active/active Data Center.                   *
      * When ACTIVE-SINGLE,  there is no Data Center replication.     *
      * When ACTIVE-ACTIVE,  perform Data Center replicaiton before   *
      *      sending the response to the client.                      *
      * When ACTIVE-STANDBY, perform Data Center replication after    *
      *      sending the response to the client.                      *
      *****************************************************************
       5300-SEND-RESPONSE.
           PERFORM 8000-GET-URL               THRU 8000-EXIT.

           IF  DC-TYPE        EQUAL ACTIVE-ACTIVE
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 5400-REPLICATE         THRU 5400-EXIT.

           MOVE DFHVALUE(IMMEDIATE)             TO SEND-ACTION.

           IF  FK-ECR EQUAL 'Y'
               PERFORM 9400-WRITE-ECR         THRU 9400-EXIT.

           EXEC CICS WEB SEND
                FROM      (CRLF)
                FROMLENGTH(TWO)
                MEDIATYPE(TEXT-PLAIN)
                SRVCONVERT
                NOHANDLE
                ACTION(SEND-ACTION)
                STATUSCODE(HTTP-STATUS-200)
                STATUSTEXT(HTTP-OK)
           END-EXEC.

           IF  DC-TYPE        EQUAL ACTIVE-STANDBY
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 5400-REPLICATE         THRU 5400-EXIT.

       5300-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE.                                                  *
      * Replicate DELETE quest to active/active Data Center.          *
      *****************************************************************
       5400-REPLICATE.

           PERFORM 8100-WEB-OPEN              THRU 8100-EXIT.

           MOVE DFHVALUE(DELETE)                TO WEB-METHOD

           IF  FK-ECR NOT EQUAL 'Y'
               PERFORM 8200-WEB-CONVERSE      THRU 8200-EXIT.

           IF  FK-ECR     EQUAL 'Y'
               PERFORM 8210-WEB-CONVERSE      THRU 8210-EXIT.

           PERFORM 8300-WEB-CLOSE             THRU 8300-EXIT.


       5400-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE                                                   *
      * Deplicate request from zFAM expiration process from the       *
      * partner Data Center.                                          *
      * Check for expired message.                                    *
      * Delete when expired.                                          *
      * Return ABSTIME when not expired.                              *
      * And yes, 'Deplication' is a word.  Deplication is basically   *
      * 'data deduplication, data reduction, and delta differencing'. *
      *****************************************************************
       5500-DEPLICATE-DELETE.
           MOVE FK-FF-KEY               TO FF-KEY.
           MOVE ZEROES                  TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD     TO FF-LENGTH.

           MOVE ONE TO FF-SEGMENT.

           EXEC CICS READ FILE(FF-FCT)
                INTO(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               PERFORM 5600-CHECK-RET THRU 5600-EXIT.

       5500-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE                                                   *
      * Check for expired message.                                    *
      *****************************************************************
       5600-CHECK-RET.
           EXEC CICS ASKTIME ABSTIME(CURRENT-ABS) NOHANDLE
           END-EXEC.

           MOVE FF-RETENTION            TO RET-SECONDS.
           MOVE RET-TIME                TO RET-MILLISECONDS.

           SUBTRACT FF-ABS FROM CURRENT-ABS GIVING RELATIVE-TIME.
           IF  RELATIVE-TIME LESS THAN RET-MILLISECONDS
           OR  RELATIVE-TIME EQUAL     RET-MILLISECONDS
               PERFORM 5700-SEND-ABS  THRU 5700-EXIT
               PERFORM 9000-RETURN    THRU 9000-EXIT.

       5600-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE                                                   *
      * Deplicate request from the partner Data Center zFAM           *
      * expiration process.                                           *
      * This message has not expired.                                 *
      * Send DELETE response with this record's ABSTIME.              *
      *****************************************************************
       5700-SEND-ABS.

           MOVE FF-ABS                  TO HTTP-ABSTIME.

           MOVE DFHVALUE(IMMEDIATE)     TO SEND-ACTION.

           EXEC CICS WEB SEND
                MEDIATYPE (TEXT-PLAIN)
                ACTION    (SEND-ACTION)
                FROM      (HTTP-ABSTIME)
                FROMLENGTH(HTTP-ABSTIME-LENGTH)
                STATUSCODE(HTTP-STATUS-201)
                STATUSTEXT(HTTP-ABSTIME)
                STATUSLEN (HTTP-ABSTIME-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       5700-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE.                                                  *
      * When a schema is available (FAxxFD), read old record and      *
      * create containers for zFAM041 to delete old secondary CI      *
      * records.                                                      *
      *****************************************************************
       5800-OLD-RECORD.
           EXEC CICS GET CONTAINER(ZFAM-FAXXFD)
                FLENGTH(CONTAINER-LENGTH)
                CHANNEL(ZFAM-CHANNEL)
                NODATA
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               PERFORM 5810-PUT-CONTAINERS    THRU 5810-EXIT.

       5800-EXIT.
           EXIT.

      *****************************************************************
      * HTTP DELETE.                                                  *
      * Create containers with information to delete 'old' secondary  *
      * column indexes.                                               *
      *****************************************************************
       5810-PUT-CONTAINERS.
           PERFORM 3000-READ-ZFAM             THRU 3000-EXIT.

           IF  FF-SEGMENTS EQUAL ONE
               SET ADDRESS OF ZFAM-MESSAGE      TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               SET ADDRESS OF ZFAM-MESSAGE      TO SAVE-ADDRESS.

           SET RECORD-ADDRESS TO ADDRESS OF ZFAM-MESSAGE.

           EXEC CICS PUT CONTAINER(ZFAM-OLD-REC)
                FROM   (RECORD-ADDRESS-X)
                FLENGTH(LENGTH OF RECORD-ADDRESS-X)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-OLD-KEY)
                FROM   (FK-FF-KEY)
                FLENGTH(LENGTH OF FK-FF-KEY)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-PROCESS)
                FROM   (PROCESS-DELETE)
                FLENGTH(LENGTH OF PROCESS-DELETE)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS LINK PROGRAM(ZFAM041)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

       5810-EXIT.
           EXIT.


      *****************************************************************
      * HTTP PUT.                                                     *
      * Read  zFAM KEY record for UPDATE to lock the record.          *
      * If the record does not exist, send an HTTP status code 204    *
      * and status text accordingly.                                  *
      *                                                               *
      * With row level locking, the PUT must match the lock before    *
      * the lock expires.  If an outstanding lock expires, the PUT    *
      * request will be rejected.  When an unlocked PUT is requested  *
      * an outstanding lock must be honored before the request can    *
      * be completed.  When a lock is active, all requests must wait  *
      * until completed, expired or matched.                          *
      *****************************************************************
       6000-READ-KEY.
           PERFORM 6010-GET-HEADER        THRU 6010-EXIT.
           PERFORM 6020-LOCK-PROCESS      THRU 6020-EXIT
               WITH TEST AFTER
               UNTIL LOCK-OBTAINED EQUAL 'Y'.

       6000-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Get HTTP headers for row level locking.                       *
      *****************************************************************
       6010-GET-HEADER.
           MOVE LENGTH OF HTTP-LOCKID         TO ZFAM-LOCKID-LENGTH.
           MOVE LENGTH OF HTTP-LOCKID-VALUE   TO LOCKID-VALUE-LENGTH.

           EXEC CICS WEB READ
                HTTPHEADER (HTTP-LOCKID)
                NAMELENGTH (ZFAM-LOCKID-LENGTH)
                VALUE      (HTTP-LOCKID-VALUE)
                VALUELENGTH(LOCKID-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE SPACES                    TO HTTP-LOCK-VALUE.

           MOVE LENGTH OF HTTP-TIME           TO ZFAM-TIME-LENGTH.
           MOVE LENGTH OF HTTP-TIME-VALUE     TO TIME-VALUE-LENGTH.

       6010-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Row level locking process.                                    *
      *****************************************************************
       6020-LOCK-PROCESS.
           MOVE 'N' TO LOCK-OBTAINED.
           MOVE 'Y' TO ROW-LOCKED.

           PERFORM 6030-READ-KEY          THRU 6030-EXIT.
           PERFORM 6040-CHECK-LOCK        THRU 6040-EXIT.

           IF  ROW-LOCKED EQUAL 'Y'
               PERFORM 6070-UNLOCK-KEY    THRU 6070-EXIT
               PERFORM 6080-WAIT          THRU 6080-EXIT.

       6020-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Issue READ UPDATE for KEY store record.                       *
      *                                                               *
      * Event Control Record (ECR) processing is not allowed for PUT  *
      * requests.                                                     *
      *****************************************************************
       6030-READ-KEY.

           MOVE URI-KEY TO FK-KEY.
           MOVE LENGTH  OF FK-RECORD        TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
                UPDATE
           END-EXEC.

           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-204              TO CA090-STATUS
               MOVE '03'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE '6030'                  TO KE-PARAGRAPH
               MOVE FC-READ                 TO KE-FN
               PERFORM 9200-KEY-ERROR     THRU 9200-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '07'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  FK-ECR EQUAL 'Y'
               PERFORM 9400-WRITE-ECR     THRU 9400-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-409              TO CA090-STATUS
               MOVE '04'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  FK-DDNAME NOT EQUAL SPACES
               MOVE FK-DDNAME               TO FF-DDNAME.

           PERFORM 9001-SEGMENTS          THRU 9001-EXIT.

           MOVE MAX-SEGMENT-COUNT           TO FK-SEGMENTS.

           IF  LOB-RESP EQUAL DFHRESP(NORMAL)
               MOVE 'L'                     TO FK-LOB.

       6030-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Check the KEY store record for a row level lock.              *
      *****************************************************************
       6040-CHECK-LOCK.
           IF  FK-UID EQUAL SPACES
           OR  FK-UID EQUAL LOW-VALUES
               IF  HTTP-LOCKID-VALUE GREATER   THAN SPACES
                   PERFORM 6050-LOCK-FAILED    THRU 6050-EXIT
                   PERFORM 9000-RETURN         THRU 9000-EXIT.

           IF  FK-UID EQUAL SPACES
           OR  FK-UID EQUAL LOW-VALUES
               IF  HTTP-LOCKID-VALUE EQUAL SPACES
                   MOVE 'N' TO ROW-LOCKED
                   MOVE 'Y' TO LOCK-OBTAINED.

           IF  FK-UID NOT EQUAL SPACES
           AND FK-UID NOT EQUAL LOW-VALUES
               IF  HTTP-LOCKID-VALUE EQUAL FK-UID
                   MOVE 'N' TO ROW-LOCKED
                   MOVE 'Y' TO LOCK-OBTAINED.

           IF  FK-UID NOT EQUAL SPACES
           AND FK-UID NOT EQUAL LOW-VALUES
               IF  HTTP-LOCKID-VALUE EQUAL SPACES
                   PERFORM 6060-CHECK-EXPIRED  THRU 6060-EXIT
               ELSE
               IF  HTTP-LOCKID-VALUE NOT EQUAL FK-UID
                   PERFORM 6050-LOCK-FAILED    THRU 6050-EXIT
                   PERFORM 9000-RETURN         THRU 9000-EXIT.

       6040-EXIT.
           EXIT.

      *****************************************************************
      * PUT request with row level locking UID, however the UID on    *
      * the KEY store record header does not match.                   *
      *****************************************************************
       6050-LOCK-FAILED.
           MOVE LENGTH OF HTTP-STATUS         TO ZFAM-STATUS-LENGTH.
           MOVE LENGTH OF HTTP-STATUS-VALUE   TO STATUS-VALUE-LENGTH.

           MOVE LOCK-NOT-ACTIVE               TO HTTP-STATUS-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-STATUS)
                NAMELENGTH (ZFAM-STATUS-LENGTH)
                VALUE      (HTTP-STATUS-VALUE)
                VALUELENGTH(STATUS-VALUE-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE STATUS-409                    TO CA090-STATUS
           MOVE '03'                          TO CA090-REASON
           PERFORM 9998-ZFAM090             THRU 9998-EXIT.

       6050-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Check for an expired lock.                                    *
      *****************************************************************
       6060-CHECK-EXPIRED.
           SUBTRACT FK-ABS FROM WS-ABS GIVING RELATIVE-TIME.

           MOVE FK-LOCK-TIME            TO LOCK-SECONDS.
           MOVE LOCK-TIME               TO LOCK-MILLISECONDS.

           IF  RELATIVE-TIME GREATER THAN LOCK-MILLISECONDS
           OR  RELATIVE-TIME EQUAL        LOCK-MILLISECONDS
               MOVE 'Y'                 TO LOCK-OBTAINED
               MOVE 'N'                 TO ROW-LOCKED.

       6060-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Issue UNLOCK  for KEY store record.                           *
      *****************************************************************
       6070-UNLOCK-KEY.
           EXEC CICS UNLOCK  FILE(FK-FCT)
                NOHANDLE
           END-EXEC.

       6070-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Issue 'wait' for an active lock to be released or expire.     *
      * This routine will call L8WAIT for 100 milliseconds up to      *
      * 50 times, before returning a 'locked' status.                 *
      *****************************************************************
       6080-WAIT.
           ADD ONE TO WAIT-COUNT.

           EXEC CICS LINK PROGRAM(L8WAIT)
                COMMAREA(L8WAIT-COMMAREA)
                NOHANDLE
           END-EXEC.

           IF  WAIT-COUNT EQUAL        FIFTY
           OR  WAIT-COUNT GREATER THAN FIFTY
               PERFORM 6050-LOCK-FAILED   THRU 6050-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       6080-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Get counter, which is used as ZFAM FILE store internal key.   *
      *****************************************************************
       6100-GET-COUNTER.

           EXEC CICS GET DCOUNTER(ZFAM-COUNTER)
                VALUE(ZFAM-NC-VALUE)
                INCREMENT(ZFAM-NC-INCREMENT)
                NOHANDLE
           END-EXEC.

       6100-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Write zFAM FILE store record(s).                              *
      *                                                               *
      * Store media-type for PUT  in zFAM FILE record.                *
      * The media-type will be used for subsequent GET requests       *
      *****************************************************************
       6200-PROCESS-FILE.
           PERFORM 6800-OLD-RECORD        THRU 6800-EXIT.

           MOVE ZFAM-ADDRESS-X              TO SAVE-ADDRESS-X.

           MOVE FK-KEY                      TO FF-FK-KEY.

           CALL ZUIDSTCK USING BY REFERENCE THE-TOD.
           MOVE THE-TOD(1:6)                TO FF-KEY-IDN.
           MOVE ZFAM-NC-HW                  TO FF-KEY-NC.

           MOVE ZEROES                      TO FF-ZEROES.
           MOVE WEB-MEDIA-TYPE              TO FF-MEDIA.

           MOVE MAX-SEGMENT-COUNT           TO FF-SEGMENTS.

           MOVE WS-ABS                      TO FF-ABS.

           PERFORM 6500-WRITE-FILE        THRU 6500-EXIT
               WITH TEST AFTER
               VARYING SEGMENT-COUNT FROM 1 BY 1 UNTIL
                       SEGMENT-COUNT EQUAL  MAX-SEGMENT-COUNT.

       6200-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Rewrite KEY store record with new FILE store internal key.    *
      *****************************************************************
       6300-REWRITE-KEY.
           MOVE FK-FF-KEY                   TO DELETE-KEY.
           MOVE ZEROES                      TO DELETE-ZEROES.

           MOVE THE-TOD(1:6)                TO FK-FF-IDN.
           MOVE ZFAM-NC-HW                  TO FK-FF-NC.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE 'text'                  TO FK-OBJECT
           ELSE
               MOVE 'bits'                  TO FK-OBJECT.

           MOVE SPACES                      TO FK-UID
           MOVE ZEROES                      TO FK-ABS.
           MOVE ZEROES                      TO FK-LOCK-TIME.

           EXEC CICS REWRITE FILE(FK-FCT)
                FROM(FK-RECORD)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE '6300'                  TO FE-PARAGRAPH
               MOVE FC-REWRITE              TO FE-FN
               PERFORM 9200-KEY-ERROR     THRU 9200-EXIT
               PERFORM 9999-ROLLBACK      THRU 9999-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '08'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           PERFORM 6900-NEW-RECORD        THRU 6900-EXIT.

       6300-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Set IMMEDIATE action on WEB SEND command.                     *
      * Send POST response.                                           *
      *                                                               *
      * Replicate across active/active Data Center.                   *
      * Get URL and replication type from document template.          *
      *                                                               *
      * When ACTIVE-SINGLE,  there is no Data Center replication.     *
      * When ACTIVE-ACTIVE,  perform Data Center replicaiton before   *
      *      sending the response to the client.                      *
      * When ACTIVE-STANDBY, perform Data Center replication after    *
      *      sending the response to the client.                      *
      *****************************************************************
       6400-SEND-RESPONSE.
           PERFORM 8000-GET-URL               THRU 8000-EXIT.

           IF  DC-TYPE        EQUAL ACTIVE-ACTIVE
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 6600-REPLICATE         THRU 6600-EXIT.

           MOVE DFHVALUE(IMMEDIATE)             TO SEND-ACTION.

           EXEC CICS WEB SEND
                FROM      (CRLF)
                FROMLENGTH(TWO)
                MEDIATYPE(TEXT-PLAIN)
                SRVCONVERT
                NOHANDLE
                ACTION(SEND-ACTION)
                STATUSCODE(HTTP-STATUS-200)
                STATUSTEXT(HTTP-OK)
           END-EXEC.

           IF  DC-TYPE        EQUAL ACTIVE-STANDBY
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 6600-REPLICATE         THRU 6600-EXIT.

           PERFORM 6700-DELETE                THRU 6700-EXIT
               WITH TEST AFTER
               VARYING DELETE-SEGMENT FROM 1 BY 1
               UNTIL   EIBRESP NOT EQUAL DFHRESP(NORMAL).

       6400-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Write zFAM FILE record.                                       *
      * A logical record can span one hundred 32,000 byte segments.   *
      *****************************************************************
       6500-WRITE-FILE.
           SET ADDRESS OF ZFAM-MESSAGE          TO ZFAM-ADDRESS.
           MOVE SEGMENT-COUNT                   TO FF-SEGMENT.

           IF  UNSEGMENTED-LENGTH LESS THAN     OR EQUAL THIRTY-TWO-KB
               MOVE UNSEGMENTED-LENGTH          TO FF-LENGTH
           ELSE
               MOVE THIRTY-TWO-KB               TO FF-LENGTH.

           MOVE LOW-VALUES                      TO FF-DATA.
           MOVE ZFAM-MESSAGE(1:FF-LENGTH)       TO FF-DATA.
           ADD  FF-PREFIX                       TO FF-LENGTH.

           EXEC CICS WRITE FILE(FF-FCT)
                FROM(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-WRITE                    TO FE-FN
               MOVE '6500'                      TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR        THRU 9100-EXIT
               PERFORM 9999-ROLLBACK          THRU 9999-EXIT
               MOVE EIBDS                       TO CA090-FILE
               MOVE STATUS-507                  TO CA090-STATUS
               MOVE '09'                        TO CA090-REASON
               PERFORM 9998-ZFAM090           THRU 9998-EXIT.

           IF  UNSEGMENTED-LENGTH GREATER THAN  OR EQUAL THIRTY-TWO-KB
               SUBTRACT THIRTY-TWO-KB         FROM UNSEGMENTED-LENGTH
               ADD      THIRTY-TWO-KB           TO ZFAM-ADDRESS-X.

       6500-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Replicate PUT request to partner Data Center.                 *
      *****************************************************************
       6600-REPLICATE.

           PERFORM 8100-WEB-OPEN              THRU 8100-EXIT.

           MOVE DFHVALUE(PUT)                   TO WEB-METHOD
           PERFORM 8200-WEB-CONVERSE          THRU 8200-EXIT.

           PERFORM 8300-WEB-CLOSE             THRU 8300-EXIT.

       6600-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Delete previous record(s).                                    *
      *****************************************************************
       6700-DELETE.
           EXEC CICS DELETE FILE(FF-FCT)
                RIDFLD(DELETE-KEY-16)
                NOHANDLE
           END-EXEC.

       6700-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * When a schema is available (FAxxFD), read old record and      *
      * create containers for zFAM031 to delete old secondary CI      *
      * records.                                                      *
      *****************************************************************
       6800-OLD-RECORD.
           EXEC CICS GET CONTAINER(ZFAM-FAXXFD)
                FLENGTH(CONTAINER-LENGTH)
                CHANNEL(ZFAM-CHANNEL)
                NODATA
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               PERFORM 6810-PUT-CONTAINERS    THRU 6810-EXIT.

       6800-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Create containers with information to delete 'old' secondary  *
      * column indexes.                                               *
      *****************************************************************
       6810-PUT-CONTAINERS.
           PERFORM 3000-READ-ZFAM             THRU 3000-EXIT.

           IF  FF-SEGMENTS EQUAL ONE
               SET ADDRESS OF ZFAM-MESSAGE      TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               SET ADDRESS OF ZFAM-MESSAGE      TO SAVE-ADDRESS.

           SET RECORD-ADDRESS TO ADDRESS OF ZFAM-MESSAGE.

           EXEC CICS PUT CONTAINER(ZFAM-OLD-REC)
                FROM   (RECORD-ADDRESS-X)
                FLENGTH(LENGTH OF RECORD-ADDRESS-X)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-OLD-KEY)
                FROM   (FK-FF-KEY)
                FLENGTH(LENGTH OF FK-FF-KEY)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-PROCESS)
                FROM   (PROCESS-DELETE)
                FLENGTH(LENGTH OF PROCESS-DELETE)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS LINK PROGRAM(ZFAM031)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

       6810-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * When a schema is available (FAxxFD), create containers for    *
      * zFAM031 to create new secondary column index entries.         *
      *****************************************************************
       6900-NEW-RECORD.
           EXEC CICS GET CONTAINER(ZFAM-FAXXFD)
                FLENGTH(CONTAINER-LENGTH)
                CHANNEL(ZFAM-CHANNEL)
                NODATA
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               PERFORM 6910-LINK-ZFAM031      THRU 6910-EXIT.

       6900-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT.                                                     *
      * Issue LINK to zFAM031 for secondary column index process.     *
      *****************************************************************
       6910-LINK-ZFAM031.
           SET ADDRESS OF ZFAM-MESSAGE          TO SAVE-ADDRESS.

           EXEC CICS PUT CONTAINER(ZFAM-NEW-REC)
                FROM   (SAVE-ADDRESS-X)
                FLENGTH(LENGTH OF SAVE-ADDRESS-X)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-NEW-KEY)
                FROM   (FK-FF-KEY)
                FLENGTH(LENGTH OF FK-FF-KEY)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS PUT CONTAINER(ZFAM-PROCESS)
                FROM   (PROCESS-INSERT)
                FLENGTH(LENGTH OF PROCESS-INSERT)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

           EXEC CICS LINK PROGRAM(ZFAM031)
                CHANNEL(ZFAM-CHANNEL)
                NOHANDLE
           END-EXEC.

       6910-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Read  zFAM KEY record for UPDATE to lock the record.          *
      * If the record does not exist, send an HTTP status code 204    *
      * and status text accordingly.                                  *
      *****************************************************************
       7000-READ-KEY.
           MOVE URI-KEY                     TO FK-KEY.
           MOVE LENGTH  OF FK-RECORD        TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
                UPDATE
           END-EXEC.

           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-204              TO CA090-STATUS
               MOVE '04'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE '7000'                  TO KE-PARAGRAPH
               MOVE FC-READ                 TO KE-FN
               PERFORM 9200-KEY-ERROR     THRU 9200-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '11'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

           IF  FK-DDNAME NOT EQUAL SPACES
               MOVE FK-DDNAME               TO FF-DDNAME.

           PERFORM 9001-SEGMENTS          THRU 9001-EXIT.

           IF  APP-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 7010-APPEND        THRU 7010-EXIT.

           MOVE MAX-SEGMENT-COUNT           TO FK-SEGMENTS.

           IF  LOB-RESP EQUAL DFHRESP(NORMAL)
               MOVE 'L'                     TO FK-LOB.

       7000-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Check for HTTP header zFAM-Append.                            *
      *****************************************************************
       7010-APPEND.
           MOVE FK-SEGMENTS                TO APPEND-SEGMENT.
           MOVE FK-SEGMENTS                TO MAX-SEGMENT-TOTAL.
           ADD  MAX-SEGMENT-COUNT          TO MAX-SEGMENT-TOTAL.

           IF  MAX-SEGMENT-TOTAL    LESS THAN SIXTY-FIVE-KB
           OR  MAX-SEGMENT-TOTAL    EQUAL     SIXTY-FIVE-KB
               MOVE MAX-SEGMENT-TOTAL      TO MAX-SEGMENT-COUNT.

           IF  MAX-SEGMENT-TOTAL GREATER THAN SIXTY-FIVE-KB
               MOVE STATUS-413             TO CA090-STATUS
               MOVE '02'                   TO CA090-REASON
               PERFORM 9998-ZFAM090      THRU 9998-EXIT.

       7010-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Write zFAM FILE store record(s).                              *
      *                                                               *
      * Store media-type for PUT  in zFAM FILE record.                *
      * The media-type will be used for subsequent GET requests       *
      *****************************************************************
       7200-PROCESS-FILE.
           MOVE ZFAM-ADDRESS-X              TO SAVE-ADDRESS-X.

           MOVE FK-KEY                      TO FF-FK-KEY.

           MOVE FK-FF-IDN                   TO FF-KEY-IDN.
           MOVE FK-FF-NC                    TO FF-KEY-NC.

           MOVE ZEROES                      TO FF-ZEROES.
           MOVE WEB-MEDIA-TYPE              TO FF-MEDIA.

           MOVE MAX-SEGMENT-COUNT           TO FF-SEGMENTS.

           MOVE WS-ABS                      TO FF-ABS.
           ADD  ONE                         TO APPEND-SEGMENT.

           PERFORM 7500-WRITE-FILE        THRU 7500-EXIT
               WITH TEST AFTER
               VARYING SEGMENT-COUNT FROM APPEND-SEGMENT BY 1
                 UNTIL SEGMENT-COUNT EQUAL  MAX-SEGMENT-COUNT.

       7200-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Rewrite KEY store record with new FILE store internal key.    *
      *****************************************************************
       7300-REWRITE-FK.
           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE 'text'                  TO FK-OBJECT
           ELSE
               MOVE 'bits'                  TO FK-OBJECT.

           MOVE SPACES                      TO FK-UID
           MOVE ZEROES                      TO FK-ABS.
           MOVE ZEROES                      TO FK-LOCK-TIME.

           EXEC CICS REWRITE FILE(FK-FCT)
                FROM(FK-RECORD)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE '7300'                  TO FE-PARAGRAPH
               MOVE FC-REWRITE              TO FE-FN
               PERFORM 9200-KEY-ERROR     THRU 9200-EXIT
               PERFORM 9999-ROLLBACK      THRU 9999-EXIT
               MOVE EIBDS                   TO CA090-FILE
               MOVE STATUS-507              TO CA090-STATUS
               MOVE '12'                    TO CA090-REASON
               PERFORM 9998-ZFAM090       THRU 9998-EXIT.

       7300-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Set IMMEDIATE action on WEB SEND command.                     *
      * Send POST response.                                           *
      *                                                               *
      * Replicate across active/active Data Center.                   *
      * Get URL and replication type from document template.          *
      *                                                               *
      * When ACTIVE-SINGLE,  there is no Data Center replication.     *
      * When ACTIVE-ACTIVE,  perform Data Center replication before   *
      *      sending the response to the client.                      *
      * When ACTIVE-STANDBY, perform Data Center replication after    *
      *      sending the response to the client.                      *
      *****************************************************************
       7400-SEND-RESPONSE.
           PERFORM 8000-GET-URL               THRU 8000-EXIT.

           IF  DC-TYPE        EQUAL ACTIVE-ACTIVE
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 7600-REPLICATE         THRU 7600-EXIT.

           MOVE DFHVALUE(IMMEDIATE)             TO SEND-ACTION.

           EXEC CICS WEB SEND
                FROM      (CRLF)
                FROMLENGTH(TWO)
                MEDIATYPE(TEXT-PLAIN)
                SRVCONVERT
                NOHANDLE
                ACTION(SEND-ACTION)
                STATUSCODE(HTTP-STATUS-200)
                STATUSTEXT(HTTP-OK)
           END-EXEC.

           IF  DC-TYPE        EQUAL ACTIVE-STANDBY
           AND WEB-PATH(1:10) EQUAL DATASTORE
               PERFORM 7600-REPLICATE         THRU 7600-EXIT.

       7400-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Write zFAM FILE record.                                       *
      * A logical record can span one hundred 32,000 byte segments.   *
      *****************************************************************
       7500-WRITE-FILE.
           SET ADDRESS OF ZFAM-MESSAGE          TO ZFAM-ADDRESS.
           MOVE SEGMENT-COUNT                   TO FF-SEGMENT.

           IF  UNSEGMENTED-LENGTH LESS THAN     OR EQUAL THIRTY-TWO-KB
               MOVE UNSEGMENTED-LENGTH          TO FF-LENGTH
           ELSE
               MOVE THIRTY-TWO-KB               TO FF-LENGTH.

           MOVE LOW-VALUES                      TO FF-DATA.
           MOVE ZFAM-MESSAGE(1:FF-LENGTH)       TO FF-DATA.
           ADD  FF-PREFIX                       TO FF-LENGTH.

           EXEC CICS WRITE FILE(FF-FCT)
                FROM(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-WRITE                    TO FE-FN
               MOVE '7500'                      TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR        THRU 9100-EXIT
               PERFORM 9999-ROLLBACK          THRU 9999-EXIT
               MOVE EIBDS                       TO CA090-FILE
               MOVE STATUS-507                  TO CA090-STATUS
               MOVE '13'                        TO CA090-REASON
               PERFORM 9998-ZFAM090           THRU 9998-EXIT.

           IF  UNSEGMENTED-LENGTH GREATER THAN  OR EQUAL THIRTY-TWO-KB
               SUBTRACT THIRTY-TWO-KB         FROM UNSEGMENTED-LENGTH
               ADD      THIRTY-TWO-KB           TO ZFAM-ADDRESS-X.

       7500-EXIT.
           EXIT.

      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Replicate PUT request to partner Data Center.                 *
      *****************************************************************
       7600-REPLICATE.

           PERFORM 8100-WEB-OPEN              THRU 8100-EXIT.

           PERFORM 7700-WRITE-APP             THRU 7700-EXIT.
           PERFORM 7800-WRITE-LOB             THRU 7800-EXIT.

           MOVE DFHVALUE(PUT)                   TO WEB-METHOD
           PERFORM 8200-WEB-CONVERSE          THRU 8200-EXIT.

           PERFORM 8300-WEB-CLOSE             THRU 8300-EXIT.

       7600-EXIT.
           EXIT.


      *****************************************************************
      * HTTP PUT - Append.                                            *
      * Issue WRITE for HTTP Header - zFAM-Append.                    *
      *****************************************************************
       7700-WRITE-APP.
           MOVE LENGTH OF HTTP-APP              TO ZFAM-APP-LENGTH.
           MOVE LENGTH OF HTTP-APP-VALUE        TO APP-VALUE-LENGTH.
           MOVE 'yes'                           TO HTTP-APP-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-APP)
                NAMELENGTH (ZFAM-APP-LENGTH)
                VALUE      (HTTP-APP-VALUE)
                VALUELENGTH(APP-VALUE-LENGTH)
                RESP       (APP-RESP)
                NOHANDLE
           END-EXEC.

       7700-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE HTTPHEADER for the LOB replication.               *
      *****************************************************************
       7800-WRITE-LOB.
           MOVE LENGTH OF HTTP-LOB              TO ZFAM-LOB-LENGTH.
           MOVE LENGTH OF HTTP-LOB-VALUE        TO LOB-VALUE-LENGTH.
           MOVE 'yes'                           TO HTTP-LOB-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-LOB)
                NAMELENGTH (ZFAM-LOB-LENGTH)
                VALUE      (HTTP-LOB-VALUE)
                VALUELENGTH(LOB-VALUE-LENGTH)
                RESP       (LOB-RESP)
                NOHANDLE
           END-EXEC.

       7800-EXIT.
           EXIT.

      *****************************************************************
      * Get URL for replication process.                              *
      * URL must be in the following format:                          *
      * http://hostname:port                                          *
      *****************************************************************
       8000-GET-URL.

           EXEC CICS DOCUMENT CREATE DOCTOKEN(DC-TOKEN)
                TEMPLATE(ZFAM-DC)
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF DC-CONTROL TO DC-LENGTH.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(DC-TOKEN)
                    INTO     (DC-CONTROL)
                    LENGTH   (DC-LENGTH)
                    MAXLENGTH(DC-LENGTH)
                    DATAONLY
                    NOHANDLE
               END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
           AND DC-LENGTH        GREATER THAN  TEN
               SUBTRACT TWELVE FROM DC-LENGTH
                             GIVING THE-OTHER-DC-LENGTH

               EXEC CICS WEB PARSE
                    URL(THE-OTHER-DC)
                    URLLENGTH(THE-OTHER-DC-LENGTH)
                    SCHEMENAME(URL-SCHEME-NAME)
                    HOST(URL-HOST-NAME)
                    HOSTLENGTH(URL-HOST-NAME-LENGTH)
                    PORTNUMBER(URL-PORT)
                    NOHANDLE
               END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
           OR  DC-LENGTH        LESS THAN TEN
           OR  DC-LENGTH        EQUAL     TEN
               MOVE ACTIVE-SINGLE  TO DC-TYPE.

       8000-EXIT.
           EXIT.


      *****************************************************************
      * Open WEB connection with the partner Data Center zFAM.        *
      *****************************************************************
       8100-WEB-OPEN.
           IF  URL-SCHEME-NAME EQUAL 'HTTPS'
               MOVE DFHVALUE(HTTPS)  TO URL-SCHEME
           ELSE
               MOVE DFHVALUE(HTTP)   TO URL-SCHEME.

           EXEC CICS WEB OPEN
                HOST(URL-HOST-NAME)
                HOSTLENGTH(URL-HOST-NAME-LENGTH)
                PORTNUMBER(URL-PORT)
                SCHEME(URL-SCHEME)
                SESSTOKEN(SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       8100-EXIT.
           EXIT.

      *****************************************************************
      * Converse with the partner Data Center zFAM.                   *
      * The first element of the path, which for normal processing is *
      * /datastore, must be changed to /replicate.                    *
      *****************************************************************
       8200-WEB-CONVERSE.
           MOVE REPLICATE TO WEB-PATH(1:10).

           SET ADDRESS OF ZFAM-MESSAGE        TO SAVE-ADDRESS.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE DFHVALUE(CLICONVERT)      TO CLIENT-CONVERT
           ELSE
               MOVE DFHVALUE(NOCLICONVERT)    TO CLIENT-CONVERT.

           IF  WEB-METHOD EQUAL DFHVALUE(POST)
           OR  WEB-METHOD EQUAL DFHVALUE(PUT)
               IF  WEB-QUERYSTRING-LENGTH EQUAL ZEROES
                   EXEC CICS WEB CONVERSE
                        SESSTOKEN(SESSION-TOKEN)
                        PATH(WEB-PATH)
                        PATHLENGTH(WEB-PATH-LENGTH)
                        METHOD(WEB-METHOD)
                        MEDIATYPE(FF-MEDIA)
                        FROM(ZFAM-MESSAGE)
                        FROMLENGTH(RECEIVE-LENGTH)
                        INTO(CONVERSE-RESPONSE)
                        TOLENGTH(CONVERSE-LENGTH)
                        MAXLENGTH(CONVERSE-LENGTH)
                        STATUSCODE(WEB-STATUS-CODE)
                        STATUSLEN(WEB-STATUS-LENGTH)
                        STATUSTEXT(WEB-STATUS-TEXT)
                        CLIENTCONV(CLIENT-CONVERT)
                        NOHANDLE
                   END-EXEC.

           IF  WEB-METHOD EQUAL DFHVALUE(POST)
           OR  WEB-METHOD EQUAL DFHVALUE(PUT)
               IF  WEB-QUERYSTRING-LENGTH GREATER THAN ZEROES
                   EXEC CICS WEB CONVERSE
                        SESSTOKEN(SESSION-TOKEN)
                        PATH(WEB-PATH)
                        PATHLENGTH(WEB-PATH-LENGTH)
                        METHOD(WEB-METHOD)
                        MEDIATYPE(FF-MEDIA)
                        FROM(ZFAM-MESSAGE)
                        FROMLENGTH(RECEIVE-LENGTH)
                        INTO(CONVERSE-RESPONSE)
                        TOLENGTH(CONVERSE-LENGTH)
                        MAXLENGTH(CONVERSE-LENGTH)
                        STATUSCODE(WEB-STATUS-CODE)
                        STATUSLEN(WEB-STATUS-LENGTH)
                        STATUSTEXT(WEB-STATUS-TEXT)
                        QUERYSTRING(WEB-QUERYSTRING)
                        QUERYSTRLEN(WEB-QUERYSTRING-LENGTH)
                        CLIENTCONV(CLIENT-CONVERT)
                        NOHANDLE
                   END-EXEC.

           IF  WEB-METHOD EQUAL DFHVALUE(DELETE)
                   EXEC CICS WEB CONVERSE
                        SESSTOKEN(SESSION-TOKEN)
                        PATH(WEB-PATH)
                        PATHLENGTH(WEB-PATH-LENGTH)
                        METHOD(WEB-METHOD)
                        MEDIATYPE(FF-MEDIA)
                        INTO(CONVERSE-RESPONSE)
                        TOLENGTH(CONVERSE-LENGTH)
                        MAXLENGTH(CONVERSE-LENGTH)
                        STATUSCODE(WEB-STATUS-CODE)
                        STATUSLEN(WEB-STATUS-LENGTH)
                        STATUSTEXT(WEB-STATUS-TEXT)
                        CLIENTCONV(CLIENT-CONVERT)
                        NOHANDLE
                   END-EXEC.

       8200-EXIT.
           EXIT.

      *****************************************************************
      * Converse with the partner Data Center zFAM.                   *
      * The first element of the path, which for normal processing is *
      * /datastore, must be changed to /replicate.                    *
      * This routine is for Event Control Record POST process only.   *
      *****************************************************************
       8210-WEB-CONVERSE.
           MOVE REPLICATE                 TO WEB-PATH(1:10).
           MOVE DFHVALUE(CLICONVERT)      TO CLIENT-CONVERT.
           MOVE TEXT-PLAIN                TO WEB-MEDIA-TYPE.
           MOVE DFHVALUE(IMMEDIATE)       TO SEND-ACTION.
           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           PERFORM 9400-WRITE-ECR       THRU 9400-EXIT.

           IF  WEB-METHOD EQUAL DFHVALUE(POST)
               EXEC CICS WEB CONVERSE
                    SESSTOKEN (SESSION-TOKEN)
                    PATH      (WEB-PATH)
                    PATHLENGTH(WEB-PATH-LENGTH)
                    METHOD    (WEB-METHOD)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    FROM      (URI-KEY)
                    FROMLENGTH(URI-KEY-LENGTH)
                    INTO      (CONVERSE-RESPONSE)
                    TOLENGTH  (CONVERSE-LENGTH)
                    MAXLENGTH (CONVERSE-LENGTH)
                    STATUSCODE(WEB-STATUS-CODE)
                    STATUSLEN (WEB-STATUS-LENGTH)
                    STATUSTEXT(WEB-STATUS-TEXT)
                    CLIENTCONV(CLIENT-CONVERT)
                    NOHANDLE
               END-EXEC.

           IF  WEB-METHOD EQUAL DFHVALUE(DELETE)
               EXEC CICS WEB CONVERSE
                    SESSTOKEN (SESSION-TOKEN)
                    PATH      (WEB-PATH)
                    PATHLENGTH(WEB-PATH-LENGTH)
                    METHOD    (WEB-METHOD)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    INTO      (CONVERSE-RESPONSE)
                    TOLENGTH  (CONVERSE-LENGTH)
                    MAXLENGTH (CONVERSE-LENGTH)
                    STATUSCODE(WEB-STATUS-CODE)
                    STATUSLEN (WEB-STATUS-LENGTH)
                    STATUSTEXT(WEB-STATUS-TEXT)
                    CLIENTCONV(CLIENT-CONVERT)
                    NOHANDLE
               END-EXEC.

       8210-EXIT.
           EXIT.

      *****************************************************************
      * Close WEB connection with the partner Data Center zFAM.       *
      *****************************************************************
       8300-WEB-CLOSE.

           EXEC CICS WEB CLOSE
                SESSTOKEN(SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       8300-EXIT.
           EXIT.

      *****************************************************************
      * Get current DDNAME for FA## file store.                       *
      * This feature allows zFAM to span 100  file structures.  Each  *
      * file structure will be managed at a reasonable allocation,    *
      * such as 50-100GB structures.  The ZFAM-DD and current         *
      * file DDNAME will be updated by a background process.          *
      *****************************************************************
       8400-DDNAME.

           EXEC CICS DOCUMENT CREATE DOCTOKEN(DD-TOKEN)
                TEMPLATE(ZFAM-DD)
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF DD-INFORMATION   TO DD-LENGTH.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(DD-TOKEN)
                    INTO     (DD-INFORMATION)
                    LENGTH   (DD-LENGTH)
                    MAXLENGTH(DD-LENGTH)
                    DATAONLY
                    NOHANDLE
               END-EXEC

           IF  DD-NAME NOT EQUAL SPACES
               MOVE DD-NAME                TO FF-DDNAME.

       8400-EXIT.
           EXIT.

      *****************************************************************
      * Return to CICS                                                *
      *****************************************************************
       9000-RETURN.

           EXEC CICS RETURN
           END-EXEC.

       9000-EXIT.
           EXIT.

      *****************************************************************
      * Create maximum segment count                                  *
      *****************************************************************
       9001-SEGMENTS.
           MOVE RECEIVE-LENGTH        TO UNSEGMENTED-LENGTH.

           DIVIDE RECEIVE-LENGTH BY THIRTY-TWO-KB
               GIVING    MAX-SEGMENT-COUNT
               REMAINDER SEGMENT-REMAINDER.

           IF  SEGMENT-REMAINDER GREATER THAN ZEROES
               ADD ONE TO MAX-SEGMENT-COUNT.

       9001-EXIT.
           EXIT.

      *****************************************************************
      * FAxxFILE I/O error.                                           *
      *****************************************************************
       9100-FILE-ERROR.
           MOVE EIBDS                 TO FE-DS.
           MOVE EIBRESP               TO FE-RESP.
           MOVE EIBRESP2              TO FE-RESP2.
           MOVE FAxxFILE-ERROR        TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

       9100-EXIT.
           EXIT.

      *****************************************************************
      * FAxxKEY  I/O error.                                           *
      *****************************************************************
       9200-KEY-ERROR.
           MOVE EIBDS                 TO KE-DS.
           MOVE EIBRESP               TO KE-RESP.
           MOVE EIBRESP2              TO KE-RESP2.
           MOVE FAxxKEY-ERROR         TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

       9200-EXIT.
           EXIT.

      *****************************************************************
      * DEFINE Modulo Named Counter - error                           *
      *****************************************************************
       9300-NC-ERROR.
           MOVE EIBRESP               TO NC-RESP.
           MOVE EIBRESP2              TO NC-RESP2.
           MOVE NC-ERROR              TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

       9300-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE for HTTP header - zFAM-ECR. (Event Control Record)*
      *****************************************************************
       9400-WRITE-ECR.
           MOVE 'Yes'                         TO HTTP-ECR-VALUE.
           MOVE LENGTH OF HTTP-ECR            TO ZFAM-ECR-LENGTH.
           MOVE LENGTH OF HTTP-ECR-VALUE      TO ECR-VALUE-LENGTH.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-ECR)
                NAMELENGTH (ZFAM-ECR-LENGTH)
                VALUE      (HTTP-ECR-VALUE)
                VALUELENGTH(ECR-VALUE-LENGTH)
                RESP       (ECR-RESP)
                NOHANDLE
           END-EXEC.

       9400-EXIT.
           EXIT.

      *****************************************************************
      * Basic Authenticaion error.                                    *
      *****************************************************************
       9600-AUTH-ERROR.
           MOVE DFHVALUE(IMMEDIATE)    TO SEND-ACTION.

           EXEC CICS WEB SEND
                FROM      (HTTP-AUTH-ERROR)
                FROMLENGTH(HTTP-AUTH-LENGTH)
                MEDIATYPE (TEXT-PLAIN)
                ACTION    (SEND-ACTION)
                STATUSCODE(HTTP-STATUS-401)
                STATUSTEXT(HTTP-AUTH-ERROR)
                STATUSLEN (HTTP-AUTH-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       9600-EXIT.
           EXIT.

      *****************************************************************
      * Write TD CSSL.                                                *
      *****************************************************************
       9900-WRITE-CSSL.

           MOVE EIBTRNID              TO TD-TRANID.
           EXEC CICS FORMATTIME ABSTIME(WS-ABS)
                TIME(TD-TIME)
                YYYYMMDD(TD-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF TD-RECORD   TO TD-LENGTH.
           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM(TD-RECORD)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

       9900-EXIT.
           EXIT.

      *****************************************************************
      * Issue TRACE.                                                  *
      *****************************************************************
       9995-TRACE.

           EXEC CICS ENTER TRACENUM(T_46)
                FROM(T_46_M)
                FROMLENGTH(T_LEN)
                RESOURCE(T_RES)
                NOHANDLE
           END-EXEC.

       9995-EXIT.
           EXIT.

      *****************************************************************
      * Abend has occurred.  Issue 503 with diagnostic info.          *
      *****************************************************************
       9996-ABEND.
           PERFORM 9999-ROLLBACK       THRU 9999-EXIT.

           EXEC CICS ASSIGN ABCODE(HTTP-ABEND-CODE) NOHANDLE
           END-EXEC.

           MOVE HTTP-ABEND-CODE          TO AM-ABEND-CODE.
           MOVE EIBDS                    TO AM-DS.
           MOVE ABEND-MESSAGE            TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL     THRU 9900-EXIT.

           MOVE STATUS-400               TO CA090-STATUS
           MOVE '09'                     TO CA090-REASON
           PERFORM 9998-ZFAM090        THRU 9998-EXIT.

       9996-EXIT.
           EXIT.

      *****************************************************************
      * Issue XCTL to zFAM090 for central error message process.      *
      *****************************************************************
       9998-ZFAM090.
           MOVE FK-KEY                 TO CA090-KEY.

           EXEC CICS XCTL PROGRAM(ZFAM090)
                COMMAREA(ZFAM090-COMMAREA)
                LENGTH  (LENGTH OF ZFAM090-COMMAREA)
                NOHANDLE
           END-EXEC.

           MOVE DFHVALUE(IMMEDIATE)    TO SEND-ACTION.

           EXEC CICS WEB SEND
                FROM      (CRLF)
                FROMLENGTH(TWO)
                MEDIATYPE (TEXT-PLAIN)
                ACTION    (SEND-ACTION)
                STATUSCODE(HTTP-STATUS-503)
                STATUSTEXT(HTTP-503-99-TEXT)
                STATUSLEN (HTTP-503-99-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       9998-EXIT.
           EXIT.

      *****************************************************************
      * Issue SYNCPOINT ROLLBACK                                      *
      *****************************************************************
       9999-ROLLBACK.

           EXEC CICS SYNCPOINT ROLLBACK NOHANDLE
           END-EXEC.

       9999-EXIT.
           EXIT.
