       CBL DBCS,CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM009.
       AUTHOR.  Rich Jackson and Randy Frerking
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager.                              *
      *                                                               *
      * This program is executed via XCTL from ZFAM002 to process     *
      * an HTTP/GET request with a query string of GE or GT           *
      * when the ROWS parameter is specified and the KEYSONLY         *
      * parameter is requested.                                       *
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
       01  DOCUMENT-TOKEN         PIC  X(16) VALUE SPACES.
       01  USERID                 PIC  X(08) VALUE SPACES.
       01  APPLID                 PIC  X(08) VALUE SPACES.
       01  SYSID                  PIC  X(04) VALUE SPACES.
       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  BINARY-ZEROES          PIC  X(01) VALUE LOW-VALUES.
       01  BINARY-ZERO            PIC  X(01) VALUE X'00'.
       01  HEX-01                 PIC  X(01) VALUE X'01'.

       01  ZFAM006                PIC  X(08) VALUE 'ZFAM006 '.

       01  HEADER-LASTKEY         PIC  X(12) VALUE 'zFAM-LastKey'.
       01  HEADER-LASTKEY-LENGTH  PIC S9(08) COMP VALUE 12.
       01  HEADER-ROWS            PIC  X(09) VALUE 'zFAM-Rows'.
       01  HEADER-ROWS-LENGTH     PIC S9(08) COMP VALUE 9.

       01  RANGE-RESPONSE         PIC S9(08) COMP VALUE ZEROES.
       01  HEADER-RANGE-LENGTH    PIC S9(08) COMP VALUE 13.
       01  HEADER-RANGE           PIC  X(13) VALUE 'zFAM-RangeEnd'.
       01  RANGE-VALUE-LENGTH     PIC S9(08) COMP VALUE 255.
       01  RANGE-VALUE            PIC X(255) VALUE LOW-VALUES.

       01  LINKAGE-ADDRESSES.
           02  ORIGINAL-ADDRESS   USAGE POINTER.
           02  ORIGINAL-ADDRESS-X REDEFINES ORIGINAL-ADDRESS
                                  PIC S9(08) COMP.

           02  CURRENT-ADDRESS    USAGE POINTER.
           02  CURRENT-ADDRESS-X  REDEFINES CURRENT-ADDRESS
                                  PIC S9(08) COMP.

           02  START-ADDRESS      USAGE POINTER.
           02  START-ADDRESS-X    REDEFINES START-ADDRESS
                                  PIC S9(08) COMP.

           02  LENGTH-ADDRESS     USAGE POINTER.
           02  LENGTH-ADDRESS-X   REDEFINES LENGTH-ADDRESS
                                  PIC S9(08) COMP.

       01  GETMAIN-LENGTH         PIC S9(08) COMP VALUE 3200000.
       01  LOGICAL-LENGTH         PIC S9(08) COMP VALUE ZEROES.
       01  AVAILABLE-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  MESSAGE-LENGTH         PIC S9(08) COMP VALUE ZEROES.
       01  STATUS-LENGTH          PIC S9(08) COMP VALUE 255.
       01  TRAILING-NULLS         PIC S9(08) COMP VALUE 0.
       01  ROWS-COUNT             PIC S9(08) COMP VALUE 0.
       01  MESSAGE-COUNT-LENGTH   PIC S9(08) COMP VALUE 4.
       01  MESSAGE-COUNT          PIC  9(04)      VALUE 0.
       01  KEY-LENGTH             PIC  9(03)      VALUE 0.
       01  RECORD-LENGTH          PIC  9(07)      VALUE 0.

       01  T_LEN                  PIC S9(04) COMP VALUE 8.
       01  T_46                   PIC S9(04) COMP VALUE 46.
       01  T_46_M                 PIC  X(08) VALUE SPACES.
       01  T_RES                  PIC  X(08) VALUE 'ZFAM002 '.

       01  TWO-FIFTY-FIVE         PIC S9(08) COMP VALUE 255.
       01  ONE                    PIC S9(08) COMP VALUE  1.

       01  HTTP-STATUS            PIC S9(04) COMP VALUE 000.
       01  HTTP-STATUS-200        PIC S9(04) COMP VALUE 200.
       01  HTTP-STATUS-201        PIC S9(04) COMP VALUE 201.
       01  HTTP-STATUS-204        PIC S9(04) COMP VALUE 204.
       01  HTTP-STATUS-206        PIC S9(04) COMP VALUE 206.
       01  HTTP-STATUS-400        PIC S9(04) COMP VALUE 400.
       01  HTTP-STATUS-401        PIC S9(04) COMP VALUE 401.
       01  HTTP-STATUS-503        PIC S9(04) COMP VALUE 503.

       01  HTTP-204-TEXT          PIC  X(24) VALUE SPACES.
       01  HTTP-204-LENGTH        PIC S9(08) COMP VALUE ZEROES.

       01  HTTP-503-TEXT          PIC  X(24) VALUE SPACES.
       01  HTTP-503-LENGTH        PIC S9(08) COMP VALUE ZEROES.

       01  HTTP-OK                PIC  X(02) VALUE 'OK'.
       01  HTTP-NOT-FOUND         PIC  X(16) VALUE 'Record not found'.

       01  HTTP-NOT-FOUND-LENGTH  PIC S9(08) COMP VALUE 16.

       01  TEXT-ANYTHING          PIC  X(04) VALUE 'text'.
       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.
       01  APPLICATION-XML        PIC  X(56) VALUE 'application/xml'.
       01  APPLICATION-JSON       PIC  X(56) VALUE 'application/json'.

       01  PROCESS-COMPLETE       PIC  X(01) VALUE SPACES.

       01  GET-COUNT              PIC  9(03) VALUE ZEROES.

       01  GET-EQ                 PIC  X(02) VALUE 'eq'.
       01  GET-GE                 PIC  X(02) VALUE 'ge'.
       01  GET-GT                 PIC  X(02) VALUE 'gt'.
       01  GET-LE                 PIC  X(02) VALUE 'le'.
       01  GET-LT                 PIC  X(02) VALUE 'lt'.

       01  WEB-MEDIA-TYPE         PIC  X(56).

       01  CONTAINER-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  THIRTY-TWO-KB          PIC S9(08) COMP VALUE 32000.
       01  SEND-ACTION            PIC S9(08) COMP VALUE ZEROES.

       01  ZFAM-CONTAINER         PIC  X(16) VALUE 'ZFAM_CONTAINER'.
       01  ZFAM-CHANNEL           PIC  X(16) VALUE 'ZFAM_CHANNEL'.

       01  FC-READ                PIC  X(07) VALUE 'READ   '.
       01  CSSL                   PIC  X(04) VALUE '@tdq@'.
       01  TD-LENGTH              PIC S9(04) VALUE ZEROES COMP.
       01  TD-ABS                 PIC S9(15) VALUE ZEROES COMP-3.

       01  TD-RECORD.
           02  TD-DATE            PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TIME            PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TRANID          PIC  X(04).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-MESSAGE         PIC  X(90) VALUE SPACES.

       01  FILE-ERROR.
           02  FILLER             PIC  X(12) VALUE 'FF    I/O - '.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  FE-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  FE-RESP            PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  FE-RESP2           PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  FE-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(19) VALUE SPACES.

       01  KEY-ERROR.
           02  FILLER             PIC  X(12) VALUE 'FK    I/O - '.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  KE-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  KE-RESP            PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  KE-RESP2           PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  KE-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(19) VALUE SPACES.

       01  FK-FCT.
           02  FK-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(04) VALUE 'KEY '.

       01  FF-FCT.
           02  FF-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FF-DDNAME          PIC  X(04) VALUE 'FILE'.

       01  FK-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  FF-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       01  PREVIOUS-KEY           PIC X(255) VALUE LOW-VALUES.
       01  LAST-KEY               PIC X(255) VALUE LOW-VALUES.

       COPY ZFAMFKC.

       COPY ZFAMFFC.

       01  ZFAM-LENGTH            PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * Dynamic Storage                                               *
      *****************************************************************
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           02  GET-CA-TYPE        PIC  X(02).
           02  GET-CA-ROWS        PIC  9(04).
           02  GET-CA-DELIM       PIC  X(01).
           02  GET-CA-KEYS-ONLY   PIC  X(01).
           02  GET-CA-TTL         PIC  X(01).
           02  FILLER             PIC  X(07).
           02  GET-CA-KEY-LENGTH  PIC S9(08) COMP.
           02  GET-CA-KEY         PIC X(255).


      *****************************************************************
      * zFAM  message.                                                *
      * This is the response message buffer.                          *
      *****************************************************************
       01  ZFAM-MESSAGE           PIC  X(32000).

       PROCEDURE DIVISION.

      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 1000-INITIALIZE         THRU 1000-EXIT.
           PERFORM 2000-START-BROWSE       THRU 2000-EXIT.

           PERFORM 3000-PROCESS-ZFAM       THRU 3000-EXIT
               WITH TEST AFTER
                   UNTIL PROCESS-COMPLETE EQUAL 'Y'.

           PERFORM 4000-SEND-RESPONSE      THRU 4000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Perform initialization.                                       *
      *****************************************************************
       1000-INITIALIZE.
           MOVE 'N'                         TO PROCESS-COMPLETE.
           MOVE EIBTRNID(3:2)               TO FK-TRANID(3:2).
           MOVE EIBTRNID(3:2)               TO FF-TRANID(3:2).

           EXEC CICS GETMAIN SET(ORIGINAL-ADDRESS)
                FLENGTH(GETMAIN-LENGTH)
                INITIMG(BINARY-ZEROES)
                NOHANDLE
           END-EXEC.

           SET ADDRESS OF ZFAM-MESSAGE      TO ORIGINAL-ADDRESS.
           MOVE ORIGINAL-ADDRESS-X          TO START-ADDRESS-X.

           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-RANGE)
                NAMELENGTH  (HEADER-RANGE-LENGTH)
                VALUE       (RANGE-VALUE)
                VALUELENGTH (RANGE-VALUE-LENGTH)
                RESP        (RANGE-RESPONSE)
                NOHANDLE
           END-EXEC.

       1000-EXIT.
           EXIT.

      *****************************************************************
      * The valid GET-CA-TYPE parameters for this program are:        *
      * GT - Greater than                                             *
      * GE - Greater than or equal                                    *
      *                                                               *
      * All other GET-CA-TYPE parameters are handled as GE.           *
      *                                                               *
      * When GE is specified, use the key as is, however when GT is   *
      * specified, the key must be incremented by one bit otherwise   *
      * the key presented could be read again.                        *
      *****************************************************************
       2000-START-BROWSE.
           IF  GET-CA-TYPE EQUAL GET-GT
               PERFORM 2100-AUGMENT-KEY  THRU 2100-EXIT.

           MOVE GET-CA-KEY TO FK-KEY.
           MOVE LENGTH     OF FK-RECORD    TO FK-LENGTH.

           EXEC CICS STARTBR FILE(FK-FCT)
                RIDFLD(FK-KEY)
                NOHANDLE
                GTEQ
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE HTTP-NOT-FOUND          TO HTTP-204-TEXT
               MOVE HTTP-NOT-FOUND-LENGTH   TO HTTP-204-LENGTH
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * GET-CA-TYPE specified GT (Greater Than)                       *
      *                                                               *
      * When GE is specified, use the key as is, however when GT is   *
      * specified, the key must be incremented by one bit otherwise   *
      * the key presented could be read again.  Since the key field   *
      * is 255 bytes, if a keylength of less than 255 is presented,   *
      * then simply set the last byte (255) of the key to x'01', as   *
      * the key is always padded with x'00' (low-values).  Since this *
      * program is in COBOL, flippin bits is a 'bit' challenging      *
      * (and yes, pun intended), so we'll have to LINK to an          *
      * Assembler program, to augment the key by one bit.             *
      *****************************************************************
       2100-AUGMENT-KEY.
           IF  GET-CA-KEY-LENGTH LESS  THAN TWO-FIFTY-FIVE
               MOVE HEX-01 TO GET-CA-KEY(255:1).

           IF  GET-CA-KEY-LENGTH EQUAL TWO-FIFTY-FIVE
               EXEC CICS LINK PROGRAM(ZFAM006)
                    COMMAREA(DFHCOMMAREA)
                    NOHANDLE
               END-EXEC.

       2100-EXIT.
           EXIT.

      *****************************************************************
      * Perform the READ process.                                     *
      *****************************************************************
       3000-PROCESS-ZFAM.
           PERFORM 3100-READ-PROCESS   THRU 3100-EXIT
               WITH TEST AFTER
               UNTIL PROCESS-COMPLETE  EQUAL 'Y'.
       3000-EXIT.
           EXIT.


      *****************************************************************
      * Read the KEY structure, which contains an internal key to the *
      * FILE structure..                                              *
      *                                                               *
      * Read the FILE structure, which contains the zFAM data as      *
      * record segments.                                              *
      *****************************************************************
       3100-READ-PROCESS.
           PERFORM 3200-READ-KEY       THRU 3200-EXIT.

           IF  PROCESS-COMPLETE = 'N'
               PERFORM 3300-KEYSONLY   THRU 3300-EXIT.

           IF  ROWS-COUNT EQUAL GET-CA-ROWS
               MOVE 'Y' TO PROCESS-COMPLETE.

       3100-EXIT.
           EXIT.

      *****************************************************************
      * Issue READNEXT for KEY store records.                         *
      *****************************************************************
       3200-READ-KEY.
           MOVE FK-KEY                   TO PREVIOUS-KEY.

           MOVE LENGTH     OF FK-RECORD  TO FK-LENGTH.

           EXEC CICS READNEXT FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE ZEROES                   TO RECORD-LENGTH.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'Y'                  TO PROCESS-COMPLETE.

           IF  RANGE-RESPONSE EQUAL DFHRESP(NORMAL)
               PERFORM 3210-RANGE      THRU 3210-EXIT.

           IF  PROCESS-COMPLETE EQUAL 'N'
               ADD 1 TO ROWS-COUNT.

       3200-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeEnd and compare with Primary Key.             *
      *****************************************************************
       3210-RANGE.
           IF  FK-KEY     (1:RANGE-VALUE-LENGTH) GREATER THAN
               RANGE-VALUE(1:RANGE-VALUE-LENGTH)
               MOVE 'Y' TO PROCESS-COMPLETE.

       3210-EXIT.
           EXIT.


      *****************************************************************
      * Create KEYSONLY list.                                         *
      *****************************************************************
       3300-KEYSONLY.
           SET ADDRESS OF ZFAM-MESSAGE   TO START-ADDRESS.

           MOVE ZEROES TO TRAILING-NULLS.
           INSPECT FUNCTION REVERSE(FK-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF FK-KEY
               GIVING KEY-LENGTH.

           IF  GET-CA-DELIM EQUAL LOW-VALUES OR SPACES
               MOVE KEY-LENGTH           TO ZFAM-MESSAGE(1:3)
               ADD 3 TO MESSAGE-LENGTH
               ADD 3 TO START-ADDRESS-X GIVING CURRENT-ADDRESS-X.

           IF  GET-CA-DELIM NOT EQUAL LOW-VALUES
           AND GET-CA-DELIM NOT EQUAL SPACES
               IF  MESSAGE-COUNT = ZEROES
                   MOVE START-ADDRESS-X  TO CURRENT-ADDRESS-X
               ELSE
                   MOVE GET-CA-DELIM     TO ZFAM-MESSAGE(1:1)
                   ADD 1 TO MESSAGE-LENGTH
                   ADD 1 TO START-ADDRESS-X GIVING CURRENT-ADDRESS-X.

           SET ADDRESS OF ZFAM-MESSAGE   TO CURRENT-ADDRESS.

           MOVE FK-KEY(1:KEY-LENGTH)     TO ZFAM-MESSAGE(1:KEY-LENGTH).
           ADD KEY-LENGTH TO CURRENT-ADDRESS-X.
           ADD KEY-LENGTH TO MESSAGE-LENGTH.

           SET ADDRESS OF ZFAM-MESSAGE   TO CURRENT-ADDRESS.
           MOVE CURRENT-ADDRESS-X        TO START-ADDRESS-X.

           ADD 1 TO MESSAGE-COUNT.

           SET ADDRESS OF ZFAM-MESSAGE   TO START-ADDRESS.

       3300-EXIT.
           EXIT.

      *****************************************************************
      * Send zFAM   information.                                      *
      *****************************************************************
       4000-SEND-RESPONSE.
           SET ADDRESS OF ZFAM-MESSAGE      TO ORIGINAL-ADDRESS.

           MOVE '4000   '       TO T_46_M.
           PERFORM 9995-TRACE THRU 9995-EXIT.

           IF  MESSAGE-COUNT EQUAL ZEROES
               MOVE ZEROES                  TO STATUS-LENGTH
               PERFORM 9600-HEADER        THRU 9600-EXIT
               MOVE HTTP-NOT-FOUND          TO HTTP-204-TEXT
               MOVE HTTP-NOT-FOUND-LENGTH   TO HTTP-204-LENGTH
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

           MOVE TEXT-PLAIN                  TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)         TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL SPACES BY LOW-VALUES.

           MOVE FK-KEY                      TO LAST-KEY.
           MOVE HTTP-STATUS-200             TO HTTP-STATUS.

           IF  RANGE-RESPONSE EQUAL DFHRESP(NORMAL)
               MOVE PREVIOUS-KEY            TO LAST-KEY.

           MOVE ZEROES TO TRAILING-NULLS.
           INSPECT FUNCTION REVERSE(LAST-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF LAST-KEY
               GIVING STATUS-LENGTH.

           PERFORM 9600-HEADER THRU 9600-EXIT.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               EXEC CICS WEB SEND
                    FROM      (ZFAM-MESSAGE)
                    FROMLENGTH(MESSAGE-LENGTH)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    STATUSCODE(HTTP-STATUS)
                    STATUSTEXT(LAST-KEY)
                    STATUSLEN (STATUS-LENGTH)
                    ACTION    (SEND-ACTION)
                    SRVCONVERT
                    NOHANDLE
               END-EXEC
           ELSE
               EXEC CICS WEB SEND
                    FROM      (ZFAM-MESSAGE)
                    FROMLENGTH(MESSAGE-LENGTH)
                    MEDIATYPE (WEB-MEDIA-TYPE)
                    STATUSCODE(HTTP-STATUS)
                    STATUSTEXT(LAST-KEY)
                    STATUSLEN (STATUS-LENGTH)
                    ACTION    (SEND-ACTION)
                    NOSRVCONVERT
                    NOHANDLE
               END-EXEC.

       4000-EXIT.
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
      * Write an HTTP header containing the LastKey and Rows.         *
      *****************************************************************
       9600-HEADER.

           EXEC CICS WEB WRITE
                HTTPHEADER (HEADER-LASTKEY)
                NAMELENGTH (HEADER-LASTKEY-LENGTH)
                VALUE      (LAST-KEY)
                VALUELENGTH(STATUS-LENGTH)
                NOHANDLE
           END-EXEC.

           EXEC CICS WEB WRITE
                HTTPHEADER (HEADER-ROWS)
                NAMELENGTH (HEADER-ROWS-LENGTH)
                VALUE      (MESSAGE-COUNT)
                VALUELENGTH(MESSAGE-COUNT-LENGTH)
                NOHANDLE
           END-EXEC.

       9600-EXIT.
           EXIT.

      *****************************************************************
      * Status 204 response.                                          *
      *****************************************************************
       9700-STATUS-204.
           EXEC CICS DOCUMENT CREATE DOCTOKEN(DOCUMENT-TOKEN)
                NOHANDLE
           END-EXEC.

           MOVE DFHVALUE(IMMEDIATE)     TO SEND-ACTION.

           EXEC CICS WEB SEND
                DOCTOKEN(DOCUMENT-TOKEN)
                MEDIATYPE(TEXT-PLAIN)
                SRVCONVERT
                NOHANDLE
                ACTION(SEND-ACTION)
                STATUSCODE(HTTP-STATUS-204)
                STATUSTEXT(HTTP-204-TEXT)
                STATUSLEN (HTTP-204-LENGTH)
           END-EXEC.


       9700-EXIT.
           EXIT.

      *****************************************************************
      * Write TD CSSL.                                                *
      *****************************************************************
       9900-WRITE-CSSL.
           PERFORM 9950-ABS         THRU 9950-EXIT.
           MOVE EIBTRNID              TO TD-TRANID.
           EXEC CICS FORMATTIME ABSTIME(TD-ABS)
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
      * Get Absolute time.                                            *
      *****************************************************************
       9950-ABS.
           EXEC CICS ASKTIME ABSTIME(TD-ABS) NOHANDLE
           END-EXEC.

       9950-EXIT.
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
