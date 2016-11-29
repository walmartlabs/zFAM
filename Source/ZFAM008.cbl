       CBL DBCS,CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM008.
       AUTHOR.  Rich Jackson and Randy Frerking
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager.                              *
      *                                                               *
      * This program is executed via XCTL from ZFAM002 to process     *
      * an HTTP/GET request with a query string of LE or LT           *
      * when the ROWS parameter is specified.                         *
      *                                                               *
      * Date       UserID   Description                               *
      * ---------- -------- ----------------------------------------- *
      *                                                               *
      *****************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *****************************************************************
      * DEFINE LOCAL VARIABLES                                        *
      *****************************************************************
       01  EBCDIC-CCSID           PIC  9(04) BINARY VALUE 1140.
       01  ASCII-CCSID            PIC  9(04) BINARY VALUE 819.
       01  FIELD-LENGTH           PIC  9(03) VALUE ZEROES.

       01  HEADER-LENGTH          PIC S9(08) COMP VALUE 11.
       01  HEADER-NAME            PIC  X(11) VALUE 'zFAM-Select'.
       01  SELECT-LENGTH          PIC S9(08) COMP VALUE 6.
       01  SELECT-TYPE            PIC  X(06) VALUE 'text'.
       01  SELECT-MATCH           PIC  X(01).

       01  RANGE-RESPONSE         PIC S9(08) COMP VALUE ZEROES.
       01  HEADER-RANGE-LENGTH    PIC S9(08) COMP VALUE 13.
       01  HEADER-RANGE           PIC  X(13) VALUE 'zFAM-RangeEnd'.
       01  RANGE-VALUE-LENGTH     PIC S9(08) COMP VALUE 255.
       01  RANGE-VALUE            PIC X(255) VALUE LOW-VALUES.

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
       01  HTTP-STATUS-507        PIC S9(04) COMP VALUE 507.

       01  HTTP-204-TEXT          PIC  X(24) VALUE SPACES.
       01  HTTP-204-LENGTH        PIC S9(08) COMP VALUE ZEROES.

       01  HTTP-503-TEXT          PIC  X(24) VALUE SPACES.
       01  HTTP-503-LENGTH        PIC S9(08) COMP VALUE ZEROES.

       01  HTTP-507-TEXT          PIC  X(24) VALUE SPACES.
       01  HTTP-507-LENGTH        PIC S9(08) COMP VALUE ZEROES.

       01  HTTP-OK                PIC  X(02) VALUE 'OK'.
       01  HTTP-NOT-FOUND         PIC  X(16) VALUE 'Record not found'.

       01  HTTP-NOT-FOUND-LENGTH  PIC S9(08) COMP VALUE 16.

       01  TEXT-ANYTHING          PIC  X(04) VALUE 'text'.
       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.
       01  APPLICATION-XML        PIC  X(56) VALUE 'application/xml'.

       01  PROCESS-COMPLETE       PIC  X(01) VALUE SPACES.
       01  SEGMENTS-SUCCESSFUL    PIC  X(01) VALUE SPACES.
       01  SEGMENTS-COMPLETE      PIC  X(01) VALUE SPACES.
       01  BUFFER-FULL            PIC  X(01) VALUE SPACES.

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
           MOVE 'N'                          TO PROCESS-COMPLETE.
           MOVE EIBTRNID(3:2)                TO FK-TRANID(3:2).
           MOVE EIBTRNID(3:2)                TO FF-TRANID(3:2).

           EXEC CICS GETMAIN SET(ORIGINAL-ADDRESS)
                FLENGTH(GETMAIN-LENGTH)
                INITIMG(BINARY-ZEROES)
                NOHANDLE
           END-EXEC.

           SET ADDRESS OF ZFAM-MESSAGE       TO ORIGINAL-ADDRESS.
           MOVE ORIGINAL-ADDRESS-X           TO START-ADDRESS-X.

           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-NAME)
                NAMELENGTH  (HEADER-LENGTH)
                VALUE       (SELECT-TYPE)
                VALUELENGTH (SELECT-LENGTH)
                NOHANDLE
           END-EXEC.

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
      * LT - Less than                                                *
      * LE - Less than or equal                                       *
      *                                                               *
      * Issue Start Browse (STARTBR) using the supplied key.          *
      * Set   Start Browse (STARTBR) key to x'FF' when READ/GETQ      *
      * receives NOTFND condition.                                    *
      *****************************************************************
       2000-START-BROWSE.
           MOVE GET-CA-KEY                   TO FK-KEY.
           MOVE LENGTH     OF FK-RECORD      TO FK-LENGTH.

           EXEC CICS READ     FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                GTEQ
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE HIGH-VALUES              TO FK-KEY.

           EXEC CICS STARTBR FILE(FK-FCT)
                RIDFLD(FK-KEY)
                NOHANDLE
                GTEQ
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE ZEROES                   TO STATUS-LENGTH
               MOVE ZEROES                   TO MESSAGE-COUNT
               PERFORM 9600-HEADER         THRU 9600-EXIT
               MOVE HTTP-NOT-FOUND           TO HTTP-204-TEXT
               MOVE HTTP-NOT-FOUND-LENGTH    TO HTTP-204-LENGTH
               PERFORM 9700-STATUS-204     THRU 9700-EXIT
               PERFORM 9000-RETURN         THRU 9000-EXIT.

           IF  GET-CA-TYPE EQUAL GET-LE
               IF  FK-KEY  GREATER GET-CA-KEY
                   IF  FK-KEY NOT EQUAL HIGH-VALUES
                       PERFORM 2100-ADJUST-INDEX THRU 2100-EXIT.

           IF  GET-CA-TYPE EQUAL GET-LT
               IF  FK-KEY  GREATER GET-CA-KEY
               OR  FK-KEY  EQUAL   GET-CA-KEY
                   PERFORM 2100-ADJUST-INDEX     THRU 2100-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Adjust initial index for READPREV section.                    *
      *****************************************************************
       2100-ADJUST-INDEX.
           EXEC CICS READPREV FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE ZEROES                   TO STATUS-LENGTH
               MOVE ZEROES                   TO MESSAGE-COUNT
               PERFORM 9600-HEADER         THRU 9600-EXIT
               MOVE HTTP-NOT-FOUND           TO HTTP-204-TEXT
               MOVE HTTP-NOT-FOUND-LENGTH    TO HTTP-204-LENGTH
               PERFORM 9700-STATUS-204     THRU 9700-EXIT
               PERFORM 9000-RETURN         THRU 9000-EXIT.

       2100-EXIT.
           EXIT.

      *****************************************************************
      * Perform the READPREV process for the KEY store records.       *
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
           PERFORM 3200-READ-KEY           THRU 3200-EXIT.

           IF  PROCESS-COMPLETE = 'N'
               IF  SELECT-MATCH = 'Y'
                   PERFORM 3300-READ-FILE  THRU 3300-EXIT.

           IF  ROWS-COUNT EQUAL GET-CA-ROWS
               MOVE 'Y' TO PROCESS-COMPLETE.

       3100-EXIT.
           EXIT.

      *****************************************************************
      * Issue READPREV to KEY store records.                          *
      *****************************************************************
       3200-READ-KEY.
           MOVE 'N'                     TO SELECT-MATCH.
           MOVE FK-KEY                  TO PREVIOUS-KEY.

           MOVE LENGTH     OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READPREV FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE ZEROES                  TO RECORD-LENGTH.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'Y'                 TO PROCESS-COMPLETE.

           IF  RANGE-RESPONSE EQUAL DFHRESP(NORMAL)
               PERFORM 3210-RANGE     THRU 3210-EXIT.

           IF  PROCESS-COMPLETE EQUAL 'N'
           IF  SELECT-TYPE(1:4)     EQUAL 'text'    AND
               FK-OBJECT            EQUAL 'text'
               MOVE 'Y'   TO SELECT-MATCH
               ADD 1      TO ROWS-COUNT.

           IF  PROCESS-COMPLETE EQUAL 'N'
           IF  SELECT-TYPE(1:4) NOT EQUAL 'text'    AND
               FK-OBJECT        NOT EQUAL 'text'
               MOVE 'Y'   TO SELECT-MATCH
               ADD 1      TO ROWS-COUNT.

       3200-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeEnd and compare with Primary Key.             *
      *****************************************************************
       3210-RANGE.
           IF  FK-KEY     (1:RANGE-VALUE-LENGTH) LESS THAN
               RANGE-VALUE(1:RANGE-VALUE-LENGTH)
               MOVE 'Y' TO PROCESS-COMPLETE.

       3210-EXIT.
           EXIT.

      *****************************************************************
      * Read FILE/DATA store record segment(s).                       *
      *****************************************************************
       3300-READ-FILE.
           MOVE 'Y'                     TO SEGMENTS-SUCCESSFUL.

           MOVE FK-DDNAME               TO FF-DDNAME.
           MOVE FK-FF-KEY               TO FF-KEY.
           MOVE ZEROES                  TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD     TO FF-LENGTH.

           MOVE ONE                     TO FF-SEGMENT.

           SET ADDRESS OF ZFAM-MESSAGE  TO START-ADDRESS.

           MOVE ZEROES TO TRAILING-NULLS.
           INSPECT FUNCTION REVERSE(FK-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF FK-KEY
               GIVING KEY-LENGTH.

           IF  GET-CA-DELIM EQUAL LOW-VALUES OR SPACES
               MOVE KEY-LENGTH          TO ZFAM-MESSAGE(1:3)
               MOVE 3                   TO FIELD-LENGTH
               PERFORM 5000-ASCII     THRU 5000-EXIT
               ADD 3 TO START-ADDRESS-X GIVING CURRENT-ADDRESS-X.

           IF  GET-CA-DELIM NOT EQUAL LOW-VALUES AND
               GET-CA-DELIM NOT EQUAL SPACES
               IF  MESSAGE-COUNT = ZEROES
                   MOVE START-ADDRESS-X         TO CURRENT-ADDRESS-X
               ELSE
                   MOVE GET-CA-DELIM            TO ZFAM-MESSAGE(1:1)
                   MOVE 1                       TO FIELD-LENGTH
                   PERFORM 5000-ASCII         THRU 5000-EXIT
                   ADD 1 TO START-ADDRESS-X GIVING CURRENT-ADDRESS-X.

           SET ADDRESS OF ZFAM-MESSAGE  TO CURRENT-ADDRESS.

           MOVE FK-KEY(1:KEY-LENGTH)    TO ZFAM-MESSAGE(1:KEY-LENGTH).
           MOVE KEY-LENGTH              TO FIELD-LENGTH.
           PERFORM 5000-ASCII         THRU 5000-EXIT.
           ADD KEY-LENGTH TO CURRENT-ADDRESS-X.
           ADD KEY-LENGTH TO MESSAGE-LENGTH.

           SET ADDRESS OF ZFAM-MESSAGE  TO CURRENT-ADDRESS.
           MOVE CURRENT-ADDRESS-X       TO LENGTH-ADDRESS-X.

           IF  GET-CA-DELIM EQUAL LOW-VALUES OR SPACES
               MOVE ZEROES              TO ZFAM-MESSAGE(1:7)
               MOVE 7                   TO FIELD-LENGTH
               PERFORM 5000-ASCII     THRU 5000-EXIT
               ADD 7 TO CURRENT-ADDRESS-X GIVING CURRENT-ADDRESS-X
           ELSE
               MOVE GET-CA-DELIM        TO ZFAM-MESSAGE(1:1)
               MOVE 1                   TO FIELD-LENGTH
               PERFORM 5000-ASCII     THRU 5000-EXIT
               ADD 1 TO CURRENT-ADDRESS-X GIVING CURRENT-ADDRESS-X.

           SET ADDRESS OF ZFAM-MESSAGE  TO CURRENT-ADDRESS.

           MOVE 'N'                     TO SEGMENTS-COMPLETE.
           MOVE 'N'                     TO BUFFER-FULL.

           PERFORM 3400-SEGMENTS      THRU 3400-EXIT
               WITH TEST AFTER
               UNTIL SEGMENTS-COMPLETE   EQUAL  'Y'  OR
                     SEGMENTS-SUCCESSFUL EQUAL  'N'.

           IF  SEGMENTS-SUCCESSFUL = 'Y'
               IF  GET-CA-DELIM   = SPACES OR LOW-VALUES
               SET ADDRESS OF ZFAM-MESSAGE TO LENGTH-ADDRESS
               MOVE RECORD-LENGTH          TO ZFAM-MESSAGE(1:7)
               MOVE 7                      TO FIELD-LENGTH
               PERFORM 5000-ASCII        THRU 5000-EXIT
               ADD 10                      TO MESSAGE-LENGTH.

           IF  SEGMENTS-SUCCESSFUL = 'Y'
               IF  GET-CA-DELIM   NOT = SPACES  AND
                   GET-CA-DELIM   NOT = LOW-VALUES
                   IF  MESSAGE-COUNT  = ZEROES
                       ADD 1               TO MESSAGE-LENGTH
                   ELSE
                       ADD 2               TO MESSAGE-LENGTH.

           IF  SEGMENTS-SUCCESSFUL = 'Y'
               ADD 1 TO MESSAGE-COUNT
               ADD  RECORD-LENGTH TO MESSAGE-LENGTH
               MOVE CURRENT-ADDRESS-X TO START-ADDRESS-X.

           SET ADDRESS OF ZFAM-MESSAGE TO START-ADDRESS.

       3300-EXIT.
           EXIT.

      *****************************************************************
      * Issue READ command and build the current zFAM record from     *
      * the segment(s).                                               *
      *****************************************************************
       3400-SEGMENTS.
           SET ADDRESS OF ZFAM-MESSAGE         TO CURRENT-ADDRESS.
           MOVE LENGTH OF FF-RECORD            TO FF-LENGTH.

           EXEC CICS READ FILE(FF-FCT)
                INTO(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               IF  FF-SEGMENT = FF-SEGMENTS
                   MOVE 'Y'                    TO SEGMENTS-COMPLETE.

           IF  FF-SEGMENT = ONE
               PERFORM 3420-CHECK-LENGTH     THRU 3420-EXIT.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               IF  BUFFER-FULL   = 'N'
                   SUBTRACT FF-PREFIX        FROM FF-LENGTH
                   MOVE FF-DATA(1:FF-LENGTH)   TO ZFAM-MESSAGE
                   ADD  FF-LENGTH              TO CURRENT-ADDRESS-X
                   ADD  ONE                    TO FF-SEGMENT
                   ADD  FF-LENGTH              TO RECORD-LENGTH.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'N'                        TO SEGMENTS-SUCCESSFUL.

       3400-EXIT.
           EXIT.

      *****************************************************************
      * Compare next logical record length with remaining buffer      *
      * length.                                                       *
      * When there's not enough buffer area to hold the next logical  *
      * record, set the BUFFER-FULL condition.                        *
      *****************************************************************
       3420-CHECK-LENGTH.
           MULTIPLY FF-SEGMENTS BY THIRTY-TWO-KB
               GIVING LOGICAL-LENGTH.

           SUBTRACT MESSAGE-LENGTH FROM GETMAIN-LENGTH
               GIVING AVAILABLE-LENGTH.

           IF  LOGICAL-LENGTH GREATER THAN AVAILABLE-LENGTH
               MOVE 'N'  TO SEGMENTS-SUCCESSFUL
               MOVE 'Y'  TO BUFFER-FULL
               MOVE 'Y'  TO PROCESS-COMPLETE.

       3420-EXIT.
           EXIT.

      *****************************************************************
      * Send zFAM   information.                                      *
      *****************************************************************
       4000-SEND-RESPONSE.
           IF  MESSAGE-COUNT EQUAL ZEROES
               MOVE ZEROES                  TO STATUS-LENGTH
               PERFORM 9600-HEADER        THRU 9600-EXIT
               MOVE HTTP-NOT-FOUND          TO HTTP-204-TEXT
               MOVE HTTP-NOT-FOUND-LENGTH   TO HTTP-204-LENGTH
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

           SET ADDRESS OF ZFAM-MESSAGE      TO ORIGINAL-ADDRESS.

           MOVE '4000   '       TO T_46_M.
           PERFORM 9995-TRACE THRU 9995-EXIT.

           MOVE FF-MEDIA                    TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN              TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)         TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL SPACES BY LOW-VALUES.

           IF  BUFFER-FULL   = 'Y'
               MOVE PREVIOUS-KEY            TO LAST-KEY
               MOVE HTTP-STATUS-206         TO HTTP-STATUS.

           IF  BUFFER-FULL   = 'N'
           AND RANGE-RESPONSE  EQUAL DFHRESP(NORMAL)
               MOVE PREVIOUS-KEY            TO LAST-KEY
               MOVE HTTP-STATUS-200         TO HTTP-STATUS.

           IF  BUFFER-FULL   = 'N'
           AND RANGE-RESPONSE  NOT EQUAL DFHRESP(NORMAL)
               MOVE FK-KEY                  TO LAST-KEY
               MOVE HTTP-STATUS-200         TO HTTP-STATUS.

           MOVE ZEROES TO TRAILING-NULLS.
           INSPECT FUNCTION REVERSE(LAST-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF LAST-KEY
               GIVING STATUS-LENGTH.

           PERFORM 9600-HEADER THRU 9600-EXIT.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
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
      * When the HTTP Header 'zFAM-Select' is not 'text'              *
      * convert the KEY, CHARVAR and DELIM from EBCDIC to ASCII       *
      *****************************************************************
       5000-ASCII.
           IF SELECT-TYPE(1:4) NOT EQUAL 'text'
              MOVE FUNCTION
              DISPLAY-OF
              (FUNCTION NATIONAL-OF
              (ZFAM-MESSAGE(1:FIELD-LENGTH), EBCDIC-CCSID) ASCII-CCSID)
           TO  ZFAM-MESSAGE(1:FIELD-LENGTH).

       5000-EXIT.
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
      * zFAM FILE or KEY store I/O error.                             *
      *****************************************************************
       9400-STATUS-507.

           EXEC CICS WEB SEND
                FROM      (HTTP-507-TEXT)
                FROMLENGTH(HTTP-507-LENGTH)
                MEDIATYPE (TEXT-PLAIN)
                STATUSCODE(HTTP-STATUS-507)
                STATUSTEXT(HTTP-507-TEXT)
                STATUSLEN (HTTP-507-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       9400-EXIT.
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
