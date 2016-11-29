       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM101.
       AUTHOR.  Rich Jackson and Randy Frerking
      *****************************************************************
      * zFAM - z/OS File Access Manager                               *
      *                                                               *
      * CWR (Copy While Replicating)                                  *
      *                                                               *
      * This program executes as a background transaction to copy     *
      * records from a zFAM table on one CloudPlex to another.        *
      * There will be a task started by FCWR for each FAxx table.     *
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
       01  USERID                 PIC  X(08) VALUE SPACES.
       01  APPLID                 PIC  X(08) VALUE SPACES.
       01  SYSID                  PIC  X(04) VALUE SPACES.
       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  BINARY-ZEROES          PIC  X(01) VALUE LOW-VALUES.
       01  BINARY-ZERO            PIC  X(01) VALUE X'00'.

      *****************************************************************
      ** Start  Global ENQ for zFAM 'copy while replicating'         **
      *****************************************************************
       01  ENQ-CWR.
           02  FILLER              PIC  X(08) VALUE 'CICSGRS_'.
           02  FILLER              PIC  X(08) VALUE 'zFAM_CWR'.
           02  FILLER              PIC  X(01) VALUE '_'.
           02  ENQ-TRANID          PIC  X(04) VALUE SPACES.

      *****************************************************************
      ** End    Global ENQ for zFAM 'copy while replicating'         **
      *****************************************************************

       01  INTERNAL-KEY           PIC  X(08) VALUE LOW-VALUES.
       01  ZRECOVERY              PIC  X(10) VALUE '/zRecovery'.
       01  REPLICATE              PIC  X(10) VALUE '/replicate'.
       01  CRLF                   PIC  X(02) VALUE X'0D25'.
       01  BINARY-ZERO            PIC  X(01) VALUE X'00'.
       01  HEX-01                 PIC  X(01) VALUE X'01'.

       01  THE-SLASH              PIC  X(01) VALUE '/'.

       01  RET-LENGTH             PIC S9(08) COMP VALUE ZEROES.
       01  RET-DURATION           PIC  X(16) VALUE SPACES.

       01  RET-DAYS.
           05  FILLER             PIC  X(10) VALUE '?ret-days='.
           05  THE-DAYS           PIC  9(05) VALUE ZEROES.

       01  RET-YEARS.
           05  FILLER             PIC  X(11) VALUE '?ret-years='.
           05  THE-YEARS          PIC  9(05) VALUE ZEROES.

       01  TRAILING-SPACES        PIC S9(08) VALUE ZEROES COMP.
       01  THE-PATH-LENGTH        PIC S9(08) VALUE ZEROES COMP.
       01  THE-PATH               PIC X(512) VALUE SPACES.

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

       01  GETMAIN-LENGTH         PIC S9(08) COMP VALUE 3200000.
       01  MESSAGE-LENGTH         PIC S9(08) COMP VALUE ZEROES.
       01  TRAILING-NULLS         PIC S9(08) COMP VALUE 0.
       01  ROWS-COUNT             PIC S9(08) COMP VALUE 0.
       01  MESSAGE-COUNT          PIC  9(04)      VALUE 0.
       01  KEY-LENGTH             PIC  9(03)      VALUE 0.
       01  RECORD-LENGTH          PIC  9(07)      VALUE 0.

       01  ZFAM-URI.
           05  URI-TRANID         PIC  X(04) VALUE 'FAXX'.
           05  FILLER             PIC  X(04) VALUE 'R   '.

       01  T_LEN                  PIC S9(04) COMP VALUE 8.
       01  T_46                   PIC S9(04) COMP VALUE 46.
       01  T_46_M                 PIC  X(08) VALUE SPACES.
       01  T_RES                  PIC  X(08) VALUE 'ZFAM002 '.

       01  FK-RESP                PIC S9(04) COMP VALUE 0.
       01  FF-RESP                PIC S9(04) COMP VALUE 0.
       01  TWO-FIFTY-FIVE         PIC S9(08) COMP VALUE 255.
       01  TWELVE                 PIC S9(08) COMP VALUE 12.
       01  TEN                    PIC S9(08) COMP VALUE 10.
       01  ONE                    PIC S9(08) COMP VALUE  1.

       01  TEXT-ANYTHING          PIC  X(04) VALUE 'text'.
       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.
       01  APPLICATION-XML        PIC  X(56) VALUE 'application/xml'.
       01  APPLICATION-JSON       PIC  X(56) VALUE 'application/json'.

       01  RECORD-COMPLETE        PIC  X(01) VALUE SPACES.
       01  FIRST-SEGMENT-OK       PIC  X(01) VALUE SPACES.
       01  COPY-COMPLETE          PIC  X(01) VALUE SPACES.

       01  GET-COUNT              PIC  9(03) VALUE ZEROES.

       01  WEB-MEDIA-TYPE         PIC  X(56).
       01  WEB-METHOD             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-STATUS-CODE        PIC S9(04) COMP VALUE 00.
       01  WEB-STATUS-LENGTH      PIC S9(08) COMP VALUE 80.
       01  WEB-STATUS-TEXT        PIC  X(80) VALUE SPACES.
       01  WEB-PATH-LENGTH        PIC S9(08) COMP VALUE 512.
       01  WEB-PATH               PIC X(512) VALUE SPACES.

       01  CONVERSE-LENGTH        PIC S9(08) COMP VALUE 40.
       01  CONVERSE-RESPONSE      PIC  X(40) VALUE SPACES.
       01  SESSION-TOKEN          PIC  9(18) COMP VALUE ZEROES.
       01  CLIENT-CONVERT         PIC S9(08) COMP VALUE ZEROES.

       01  URL-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  URL-SCHEME-NAME        PIC  X(16) VALUE SPACES.
       01  URL-PORT               PIC S9(08) COMP VALUE ZEROES.
       01  URL-HOST-NAME-LENGTH   PIC S9(08) COMP VALUE 80.
       01  URL-HOST-NAME          PIC  X(80) VALUE SPACES.

       01  CONTAINER-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  THIRTY-TWO-KB          PIC S9(08) COMP VALUE 32000.
       01  SEND-ACTION            PIC S9(08) COMP VALUE ZEROES.

       01  ZFAM-CONTAINER         PIC  X(16) VALUE 'ZFAM_CONTAINER'.
       01  ZFAM-CHANNEL           PIC  X(16) VALUE 'ZFAM_CHANNEL'.
       01  HTML-RESULT            PIC  X(16) VALUE 'HTML-RESULT     '.

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
           02  FILLER             PIC  X(12) VALUE 'FILE  I/O - '.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  FE-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  FE-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  FE-RESP2           PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  FE-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(15) VALUE SPACES.

       01  KEY-ERROR.
           02  FILLER             PIC  X(12) VALUE 'KEY   I/O - '.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  KE-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  KE-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  KE-RESP2           PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  KE-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(15) VALUE SPACES.

       01  DC-ERROR.
           02  FILLER             PIC  X(12) VALUE 'DocTemplate '.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  DC-FN              PIC  X(07) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  DC-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  DC-RESP2           PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  DC-PARAGRAPH       PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(15) VALUE SPACES.

       01  50702-MESSAGE.
           02  FILLER             PIC  X(16) VALUE 'GET/READ primary'.
           02  FILLER             PIC  X(16) VALUE ' key references '.
           02  FILLER             PIC  X(16) VALUE 'an internal key '.
           02  FILLER             PIC  X(16) VALUE 'on *FILE that do'.
           02  FILLER             PIC  X(16) VALUE 'es not exist:   '.
           02  FILLER             PIC  X(02) VALUE SPACES.
           02  50702-KEY          PIC  X(08) VALUE 'xxxxxxxx'.

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
      * HTTP headers for ECR messages.                                *
      *****************************************************************
       01  HTTP-ECR               PIC  X(08) VALUE 'zFAM-ECR'.
       01  HTTP-ECR-VALUE         PIC  X(03) VALUE SPACES.
       01  ZFAM-ECR-LENGTH        PIC S9(08) COMP VALUE ZEROES.
       01  ECR-VALUE-LENGTH       PIC S9(08) COMP VALUE ZEROES.
       01  ECR-RESP               PIC S9(08) COMP VALUE ZEROES.


      *****************************************************************
      * Dynamic Storage                                               *
      *****************************************************************
       LINKAGE SECTION.
       01  DFHCOMMAREA            PIC  X(01).

      *****************************************************************
      * zFAM  message.                                                *
      * This is the complete message, which is then copied to the     *
      * target CloudPlex via HTTP POST.                               *
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
                   UNTIL COPY-COMPLETE EQUAL 'Y'.

           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Perform initialization.                                       *
      *****************************************************************
       1000-INITIALIZE.
           MOVE EIBTRNID                     TO ENQ-TRANID.

           EXEC CICS ENQ RESOURCE(ENQ-CWR)
                LENGTH(LENGTH OF  ENQ-CWR)
                NOSUSPEND
                TASK
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(ENQBUSY)
               PERFORM 9000-RETURN         THRU 9000-EXIT.

           MOVE 'N'                          TO RECORD-COMPLETE.
           MOVE 'N'                          TO COPY-COMPLETE.
           MOVE EIBTRNID(3:2)                TO FK-TRANID(3:2)
                                                FF-TRANID(3:2)
                                                URI-TRANID(3:2)
                                                DC-TRANID(3:2).

           EXEC CICS INQUIRE
                URIMAP(ZFAM-URI)
                PATH  (WEB-PATH)
                NOHANDLE
           END-EXEC.

           INSPECT WEB-PATH
           REPLACING FIRST '*' BY SPACE.

           PERFORM 1200-GET-URL            THRU 1200-EXIT.

           EXEC CICS ASSIGN STARTCODE(ST-CODE)
                NOHANDLE
           END-EXEC.

       1000-EXIT.
           EXIT.

      *****************************************************************
      * Get URL for replication process.                              *
      * URL must be in the following format:                          *
      * http://hostname:port                                          *
      *****************************************************************
       1200-GET-URL.

           EXEC CICS DOCUMENT CREATE DOCTOKEN(DC-TOKEN)
                TEMPLATE(ZFAM-DC)
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF DC-CONTROL TO DC-LENGTH.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
           OR  DC-LENGTH        LESS  THAN TEN
           OR  DC-LENGTH        EQUAL      TEN
               MOVE '1200'                   TO KE-PARAGRAPH
               PERFORM 9300-URL-ERROR      THRU 9300-EXIT
               PERFORM 9000-RETURN         THRU 9000-EXIT.

           EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(DC-TOKEN)
                INTO     (DC-CONTROL)
                LENGTH   (DC-LENGTH)
                MAXLENGTH(DC-LENGTH)
                DATAONLY
                NOHANDLE
           END-EXEC.

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

       1200-EXIT.
           EXIT.

      *****************************************************************
      * Issue STARTBR on the zFAM key store.                          *
      *****************************************************************
       2000-START-BROWSE.
           MOVE LOW-VALUES                  TO FK-KEY.
           MOVE LENGTH      OF FK-RECORD    TO FK-LENGTH.

           EXEC CICS STARTBR
                FILE  (FK-FCT)
                RIDFLD(FK-KEY)
                RESP  (FK-RESP)
                NOHANDLE
                GTEQ
           END-EXEC.

           IF  FK-RESP NOT EQUAL DFHRESP(NORMAL)
               PERFORM 9200-KEY-ERROR     THRU 9200-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Perform the READ process.                                     *
      *****************************************************************
       3000-PROCESS-ZFAM.
           MOVE 'N'                         TO RECORD-COMPLETE.

           PERFORM 3100-READ-PROCESS      THRU 3100-EXIT
               WITH TEST AFTER
               UNTIL RECORD-COMPLETE   EQUAL 'Y'.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Determine record type and process accordingly.                *
      *****************************************************************
       3100-READ-PROCESS.
           PERFORM 3200-READ-KEY           THRU 3200-EXIT.

           IF  FK-ECR EQUAL 'Y'
               PERFORM 3110-ECR            THRU 3110-EXIT.

           IF  FK-ECR NOT EQUAL 'Y'
               PERFORM 3120-NON-ECR        THRU 3120-EXIT.

       3100-EXIT.
           EXIT.

      *****************************************************************
      * Event Control Record.                                         *
      * Issue copy request with just the KEY store data.              *
      *****************************************************************
       3110-ECR.
           PERFORM 4200-COPY-ECR           THRU 4200-EXIT.

       3110-EXIT.
           EXIT.

      *****************************************************************
      * Determine record type of LOB and non-LOB, then process        *
      * accordingly.                                                  *
      *****************************************************************
       3120-NON-ECR.
           IF  FK-LOB NOT EQUAL 'L'
               PERFORM 3300-READ-FILE      THRU 3300-EXIT
               IF  FIRST-SEGMENT-OK EQUAL 'Y'
                   PERFORM 3400-FILE-STORE THRU 3400-EXIT.

           IF  FK-LOB EQUAL 'L'
               PERFORM 3700-LOB            THRU 3700-EXIT.

           IF  FK-LOB NOT EQUAL 'L'
               PERFORM 4000-COPY-RECORD    THRU 4000-EXIT
               IF  FF-SEGMENTS GREATER THAN ONE
                   PERFORM 3510-FREEMAIN   THRU 3510-EXIT.

       3120-EXIT.
           EXIT.

      *****************************************************************
      * Read the zFAM KEY store record, which containes the internal  *
      * key to the FILE/DATA store record.                            *
      *****************************************************************
       3200-READ-KEY.
           MOVE FK-KEY                  TO PREVIOUS-KEY.

           MOVE LENGTH     OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READNEXT
                FILE  (FK-FCT)
                INTO  (FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                RESP  (FK-RESP)
                NOHANDLE
           END-EXEC.

           MOVE '3200'                      TO KE-PARAGRAPH
           PERFORM 3290-CHECK-RESPONSE    THRU 3290-EXIT.

           IF  RECORD-COMPLETE EQUAL 'N'
               ADD 1    TO ROWS-COUNT.

       3200-EXIT.
           EXIT.

      *****************************************************************
      * Check READ FAxxKEY response.                                  *
      *****************************************************************
       3290-CHECK-RESPONSE.
           IF  FK-RESP     EQUAL DFHRESP(NOTFND)
           OR  FK-RESP     EQUAL DFHRESP(ENDFILE)
               MOVE 'Y'                      TO COPY-COMPLETE
               MOVE 'Y'                      TO RECORD-COMPLETE
           ELSE
               IF  FK-RESP NOT EQUAL DFHRESP(NORMAL)
                   PERFORM 9200-KEY-ERROR THRU 9200-EXIT
                   PERFORM 9000-RETURN    THRU 9000-EXIT.

           IF  FK-DDNAME NOT EQUAL SPACES
               MOVE FK-DDNAME               TO FF-DDNAME.

           IF  FK-FF-KEY EQUAL INTERNAL-KEY
               MOVE FK-FF-KEY               TO 50702-KEY
               MOVE 50702-MESSAGE           TO TD-MESSAGE
               PERFORM 9900-WRITE-CSSL    THRU 9900-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       3290-EXIT.
           EXIT.

      *****************************************************************
      * Read zFAM FILE store record.                                  *
      *****************************************************************
       3300-READ-FILE.
           MOVE 'Y'                     TO FIRST-SEGMENT-OK.

           MOVE FK-FF-KEY               TO FF-KEY.
           MOVE ZEROES                  TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD     TO FF-LENGTH.

           MOVE ONE                     TO FF-SEGMENT.

           MOVE FC-READ                 TO FE-FN
           EXEC CICS READ
                FILE  (FF-FCT)
                INTO  (FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                RESP  (FF-RESP)
                NOHANDLE
           END-EXEC.


           IF  FF-RESP EQUAL DFHRESP(NOTFND)
               MOVE FK-FF-KEY                TO INTERNAL-KEY
               MOVE 'N'                      TO RECORD-COMPLETE
               MOVE 'N'                      TO FIRST-SEGMENT-OK.

           IF  FF-RESP EQUAL DFHRESP(NOTFND) OR
               FF-RESP EQUAL DFHRESP(NORMAL)
               NEXT SENTENCE
           ELSE
               MOVE FC-READ                  TO FE-FN
               MOVE '3300'                   TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR     THRU 9100-EXIT
               PERFORM 9000-RETURN         THRU 9000-EXIT.

           IF  FF-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 3999-SET-TTL        THRU 3999-EXIT.

       3300-EXIT.
           EXIT.

      *****************************************************************
      * Issue GETMAIN only when multiple segments.                    *
      * When the logical record is a single segment, set the          *
      * ZFAM-MESSAGE buffer in the LINKAGE SECTION to the record      *
      * buffer address.                                               *
      *****************************************************************
       3400-FILE-STORE.
           IF  FF-SEGMENT EQUAL ZEROES
               MOVE ONE                      TO FF-SEGMENT.

           IF  FF-SEGMENTS EQUAL ONE
               SUBTRACT FF-PREFIX          FROM FF-LENGTH
               SET  ADDRESS OF ZFAM-MESSAGE  TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               MULTIPLY FF-SEGMENTS BY THIRTY-TWO-KB
                   GIVING GETMAIN-LENGTH

               EXEC CICS GETMAIN SET(ZFAM-ADDRESS)
                    FLENGTH(GETMAIN-LENGTH)
                    INITIMG(BINARY-ZEROES)
                    NOHANDLE
               END-EXEC

               SET ADDRESS OF ZFAM-MESSAGE       TO ZFAM-ADDRESS
               MOVE ZFAM-ADDRESS-X               TO SAVE-ADDRESS-X

               SUBTRACT FF-PREFIX              FROM FF-LENGTH
               MOVE FF-DATA(1:FF-LENGTH)         TO ZFAM-MESSAGE
               ADD  FF-LENGTH                    TO ZFAM-ADDRESS-X.

           ADD  ONE                              TO FF-SEGMENT.
           MOVE FF-LENGTH                        TO ZFAM-LENGTH.

           IF  FF-SEGMENTS GREATER THAN ONE
               PERFORM 3500-READ-SEGMENTS      THRU 3500-EXIT
                   WITH TEST AFTER
                   UNTIL FF-SEGMENT GREATER  THAN FF-SEGMENTS
                   OR    FIRST-SEGMENT-OK EQUAL 'N'.

       3400-EXIT.
           EXIT.

      *****************************************************************
      * Read zFAM FILE segment records                                *
      *****************************************************************
       3500-READ-SEGMENTS.
           SET ADDRESS OF ZFAM-MESSAGE           TO ZFAM-ADDRESS.
           MOVE LENGTH OF FF-RECORD              TO FF-LENGTH.

           EXEC CICS READ FILE(FF-FCT)
                INTO  (FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                RESP  (FF-RESP)
                NOHANDLE
           END-EXEC.

           IF  FF-RESP EQUAL DFHRESP(NORMAL)
               SUBTRACT FF-PREFIX              FROM FF-LENGTH
               MOVE FF-DATA(1:FF-LENGTH)         TO ZFAM-MESSAGE
               ADD  FF-LENGTH                    TO ZFAM-ADDRESS-X
               ADD  ONE                          TO FF-SEGMENT
               ADD  FF-LENGTH                    TO ZFAM-LENGTH.

           IF  FF-RESP EQUAL DFHRESP(NOTFND)
               MOVE 'N'                          TO RECORD-COMPLETE
               MOVE 'N'                          TO FIRST-SEGMENT-OK
               MOVE FK-FF-KEY                    TO INTERNAL-KEY
               PERFORM 3510-FREEMAIN           THRU 3510-EXIT.

           IF  FF-RESP EQUAL DFHRESP(NOTFND) OR
               FF-RESP EQUAL DFHRESP(NORMAL)
               NEXT SENTENCE
           ELSE
               MOVE FC-READ                  TO FE-FN
               MOVE '3500'                   TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR     THRU 9100-EXIT
               PERFORM 9000-RETURN         THRU 9000-EXIT.

       3500-EXIT.
           EXIT.

      *****************************************************************
      * FREEMAIN message segment buffer                               *
      *****************************************************************
       3510-FREEMAIN.
           EXEC CICS FREEMAIN
                DATAPOINTER(SAVE-ADDRESS)
                NOHANDLE
           END-EXEC.

       3510-EXIT.
           EXIT.

      *****************************************************************
      * Process LOB requests.                                         *
      *****************************************************************
       3700-LOB.
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

       3700-EXIT.
           EXIT.

      *****************************************************************
      * Read FILE store and send each segment as a message.           *
      *****************************************************************
       3710-READ-FILE.
           MOVE FK-FF-KEY                  TO FF-KEY.
           MOVE ZEROES                     TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD        TO FF-LENGTH.

           MOVE FC-READ                    TO FE-FN
           EXEC CICS READ FILE(FF-FCT)
                INTO  (FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                RESP  (FF-RESP)
                NOHANDLE
           END-EXEC.

           IF  FF-RESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                TO FE-FN
               MOVE '3710'                 TO FE-PARAGRAPH
               PERFORM 9100-FILE-ERROR   THRU 9100-EXIT
               PERFORM 9000-RETURN       THRU 9000-EXIT.

           IF  FF-SEGMENT  EQUAL ONE
               PERFORM 3999-SET-TTL      THRU 3999-EXIT
               PERFORM 3720-POST-LOB     THRU 3720-EXIT.

           IF  FF-SEGMENT  NOT EQUAL ONE
               PERFORM 3730-PUT-LOB      THRU 3730-EXIT.

       3710-EXIT.
           EXIT.

      *****************************************************************
      * POST first segment as a LOB request.                          *
      *****************************************************************
       3720-POST-LOB.
           MOVE FF-MEDIA              TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN        TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)   TO SEND-ACTION.
           MOVE DFHVALUE(POST)        TO WEB-METHOD

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           PERFORM 4100-POST-LOB    THRU 4100-EXIT.

       3720-EXIT.
           EXIT.

      *****************************************************************
      * PUT  remaining segments as an LOB request.                    *
      *****************************************************************
       3730-PUT-LOB.
           MOVE FF-MEDIA              TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN        TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)   TO SEND-ACTION.
           MOVE DFHVALUE(POST)        TO WEB-METHOD

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           PERFORM 4110-PUT-LOB     THRU 4110-EXIT.

       3730-EXIT.
           EXIT.

      *****************************************************************
      * Set TTL for CONVERSE.                                         *
      *****************************************************************
       3999-SET-TTL.
           MOVE LOW-VALUES                   TO RET-DURATION.

           IF  FF-RETENTION-TYPE EQUAL 'D'
               MOVE FF-RETENTION             TO THE-DAYS
               MOVE RET-DAYS                 TO RET-DURATION
               MOVE LENGTH OF RET-DAYS       TO RET-LENGTH.

           IF  FF-RETENTION-TYPE EQUAL 'Y'
               MOVE FF-RETENTION             TO THE-YEARS
               MOVE RET-YEARS                TO RET-DURATION
               MOVE LENGTH OF RET-YEARS      TO RET-LENGTH.
       3999-EXIT.
           EXIT.

      *****************************************************************
      * Replicate across Active/Standby Data Center.                  *
      * Issue POST request for the zFAM record (non-LOB).             *
      *****************************************************************
       4000-COPY-RECORD.
           PERFORM 8000-WEB-OPEN      THRU 8000-EXIT.

           MOVE DFHVALUE(POST)          TO WEB-METHOD
           PERFORM 8100-WEB-CONVERSE  THRU 8100-EXIT.

           PERFORM 8500-WEB-CLOSE     THRU 8500-EXIT.

       4000-EXIT.
           EXIT.

      *****************************************************************
      * Replicate across Active/Standby Data Center.                  *
      * Issue POST request for the first segment  of a LOB record.    *
      *****************************************************************
       4100-POST-LOB.
           PERFORM 8000-WEB-OPEN      THRU 8000-EXIT.
           PERFORM 9996-WRITE-LOB     THRU 9996-EXIT.

           MOVE DFHVALUE(POST)          TO WEB-METHOD
           PERFORM 8200-WEB-CONVERSE  THRU 8200-EXIT.

           PERFORM 8500-WEB-CLOSE     THRU 8500-EXIT.

       4100-EXIT.
           EXIT.

      *****************************************************************
      * Replicate across Active/Standby Data Center.                  *
      * Issue POST request for the first segment  of a LOB record.    *
      * Issue PUT  request for all other segments of a LOB record.    *
      *****************************************************************
       4110-PUT-LOB.
           PERFORM 8000-WEB-OPEN      THRU 8000-EXIT.
           PERFORM 9996-WRITE-LOB     THRU 9996-EXIT.
           PERFORM 9997-WRITE-APP     THRU 9997-EXIT.

           MOVE DFHVALUE(PUT)           TO WEB-METHOD
           PERFORM 8200-WEB-CONVERSE  THRU 8200-EXIT.

           PERFORM 8500-WEB-CLOSE     THRU 8500-EXIT.

       4110-EXIT.
           EXIT.

      *****************************************************************
      * Replicate across Active/Standby Data Center.                  *
      * Issue POST request for the zFAM Event Control Record (ECR)    *
      *****************************************************************
       4200-COPY-ECR.
           PERFORM 8000-WEB-OPEN      THRU 8000-EXIT.
           PERFORM 9998-WRITE-ECR         THRU 9998-EXIT.

           MOVE DFHVALUE(IMMEDIATE)     TO SEND-ACTION.
           MOVE DFHVALUE(POST)          TO WEB-METHOD

           PERFORM 8300-WEB-CONVERSE  THRU 8300-EXIT.

           PERFORM 8500-WEB-CLOSE     THRU 8500-EXIT.

       4200-EXIT.
           EXIT.

      *****************************************************************
      * Open WEB connection with the partner Data Center zFAM.        *
      *****************************************************************
       8000-WEB-OPEN.
           IF  URL-SCHEME-NAME EQUAL 'HTTPS'
               MOVE DFHVALUE(HTTPS)     TO URL-SCHEME
           ELSE
               MOVE DFHVALUE(HTTP)      TO URL-SCHEME.

           EXEC CICS WEB OPEN
                HOST(URL-HOST-NAME)
                HOSTLENGTH(URL-HOST-NAME-LENGTH)
                PORTNUMBER(URL-PORT)
                SCHEME(URL-SCHEME)
                SESSTOKEN(SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       8000-EXIT.
           EXIT.

      *****************************************************************
      * This CONVERSE routine is for non-LOB record, which contains   *
      * all segments on a single request.                             *
      * Converse with the partner Data Center using zFAM services.    *
      * The first element of the path, which for normal processing is *
      * /datastore, must be changed to /replicate.                    *
      *****************************************************************
       8100-WEB-CONVERSE.
           MOVE REPLICATE TO WEB-PATH(1:10).

           PERFORM 9999-CREATE-URI          THRU 9999-EXIT.

           IF  FF-SEGMENTS EQUAL ONE
               SET ADDRESS OF ZFAM-MESSAGE    TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               SET ADDRESS OF ZFAM-MESSAGE    TO SAVE-ADDRESS.

           IF  FF-MEDIA(1:04) EQUAL TEXT-ANYTHING
           OR  FF-MEDIA(1:15) EQUAL APPLICATION-XML
           OR  FF-MEDIA(1:16) EQUAL APPLICATION-JSON
               MOVE DFHVALUE(CLICONVERT)      TO CLIENT-CONVERT
           ELSE
               MOVE DFHVALUE(NOCLICONVERT)    TO CLIENT-CONVERT.

           MOVE LENGTH OF WEB-STATUS-TEXT     TO WEB-STATUS-LENGTH.

           EXEC CICS WEB CONVERSE
                QUERYSTRING(RET-DURATION)
                QUERYSTRLEN(RET-LENGTH)
                SESSTOKEN(SESSION-TOKEN)
                PATH(THE-PATH)
                PATHLENGTH(THE-PATH-LENGTH)
                METHOD(WEB-METHOD)
                MEDIATYPE(FF-MEDIA)
                FROM(ZFAM-MESSAGE)
                FROMLENGTH(ZFAM-LENGTH)
                INTO(CONVERSE-RESPONSE)
                TOLENGTH(CONVERSE-LENGTH)
                MAXLENGTH(CONVERSE-LENGTH)
                STATUSCODE(WEB-STATUS-CODE)
                STATUSLEN(WEB-STATUS-LENGTH)
                STATUSTEXT(WEB-STATUS-TEXT)
                CLIENTCONV(CLIENT-CONVERT)
                NOHANDLE
           END-EXEC.


       8100-EXIT.
           EXIT.

      *****************************************************************
      * This CONVERSE routine is for all LOB records, which contains  *
      * a single segment on each request.                             *
      * Converse with the partner Data Center using zFAM services.    *
      * The first element of the path, which for normal processing is *
      * /datastore, must be changed to /replicate.                    *
      *****************************************************************
       8200-WEB-CONVERSE.
           MOVE REPLICATE                     TO WEB-PATH(1:10).

           PERFORM 9999-CREATE-URI          THRU 9999-EXIT.

           MOVE FF-LENGTH                     TO ZFAM-LENGTH
           SUBTRACT FF-PREFIX FROM ZFAM-LENGTH.

           SET ADDRESS OF ZFAM-MESSAGE TO SAVE-ADDRESS.

           IF  FF-MEDIA(1:04) EQUAL TEXT-ANYTHING
           OR  FF-MEDIA(1:15) EQUAL APPLICATION-XML
           OR  FF-MEDIA(1:16) EQUAL APPLICATION-JSON
               MOVE DFHVALUE(CLICONVERT)      TO CLIENT-CONVERT
           ELSE
               MOVE DFHVALUE(NOCLICONVERT)    TO CLIENT-CONVERT.

           MOVE LENGTH OF WEB-STATUS-TEXT     TO WEB-STATUS-LENGTH.

           EXEC CICS WEB CONVERSE
                QUERYSTRING(RET-DURATION)
                QUERYSTRLEN(RET-LENGTH)
                SESSTOKEN(SESSION-TOKEN)
                PATH(THE-PATH)
                PATHLENGTH(THE-PATH-LENGTH)
                METHOD(WEB-METHOD)
                MEDIATYPE(FF-MEDIA)
                FROM(FF-DATA)
                FROMLENGTH(ZFAM-LENGTH)
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
      * This CONVERSE routine is for Event Control Records (ECR),     *
      * which contains only a record from the KEY store and zero      *
      * records in the FILE/DATA store.                               *
      * Converse with the partner Data Center using zFAM services.    *
      * The first element of the path, which for normal processing is *
      * /datastore, must be changed to /replicate.                    *
      *                                                               *
      * Event Control Records create only KEY store entries and does  *
      * not create FILE/DATA store records, therefore zFAM ignores    *
      * any payload/data when processing an ECR request.  The CICS    *
      * client requires a payload on a POST, so we'll send one to     *
      * make CICS happy, even though zFAM ignores the data.           *
      *****************************************************************
       8300-WEB-CONVERSE.
           MOVE REPLICATE                     TO WEB-PATH(1:10).

           PERFORM 9999-CREATE-URI          THRU 9999-EXIT.

           MOVE LENGTH OF FK-KEY              TO ZFAM-LENGTH
           MOVE DFHVALUE(CLICONVERT)          TO CLIENT-CONVERT
           MOVE LENGTH OF WEB-STATUS-TEXT     TO WEB-STATUS-LENGTH.
           MOVE TEXT-PLAIN                    TO WEB-MEDIA-TYPE.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL LOW-VALUES BY SPACES.

           MOVE LOW-VALUES                    TO RET-DURATION.

           IF  FK-RETENTION-TYPE EQUAL 'D'
               MOVE FK-RETENTION              TO THE-DAYS
               MOVE RET-DAYS                  TO RET-DURATION
               MOVE LENGTH OF RET-DAYS        TO RET-LENGTH.

           IF  FK-RETENTION-TYPE EQUAL 'Y'
               MOVE FK-RETENTION              TO THE-YEARS
               MOVE RET-YEARS                 TO RET-DURATION
               MOVE LENGTH OF RET-YEARS       TO RET-LENGTH.

           EXEC CICS WEB CONVERSE
                QUERYSTRING(RET-DURATION)
                QUERYSTRLEN(RET-LENGTH)
                SESSTOKEN(SESSION-TOKEN)
                PATH(THE-PATH)
                PATHLENGTH(THE-PATH-LENGTH)
                METHOD(WEB-METHOD)
                MEDIATYPE(TEXT-PLAIN)
                FROM(FK-KEY)
                FROMLENGTH(ZFAM-LENGTH)
                INTO(CONVERSE-RESPONSE)
                TOLENGTH(CONVERSE-LENGTH)
                MAXLENGTH(CONVERSE-LENGTH)
                STATUSCODE(WEB-STATUS-CODE)
                STATUSLEN(WEB-STATUS-LENGTH)
                STATUSTEXT(WEB-STATUS-TEXT)
                CLIENTCONV(CLIENT-CONVERT)
                NOHANDLE
           END-EXEC.

       8300-EXIT.
           EXIT.

      *****************************************************************
      * Close WEB connection with the partner Data Center zFAM.       *
      *****************************************************************
       8500-WEB-CLOSE.

           EXEC CICS WEB CLOSE
                SESSTOKEN(SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       8500-EXIT.
           EXIT.


      *****************************************************************
      * Return to CICS                                                *
      *****************************************************************
       9000-RETURN.

           IF  ST-CODE(1:1) EQUAL 'T'
               EXEC CICS SEND FROM(EIBTRNID) LENGTH(4) ERASE
               END-EXEC.

           EXEC CICS RETURN
           END-EXEC.

       9000-EXIT.
           EXIT.

      *****************************************************************
      * zFAM data store error.                                        *
      *****************************************************************
       9100-FILE-ERROR.
           MOVE EIBRESP               TO FE-RESP.
           MOVE EIBRESP2              TO FE-RESP2.
           MOVE FILE-ERROR            TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

       9100-EXIT.
           EXIT.

      *****************************************************************
      * zFAM key  store error.                                        *
      *****************************************************************
       9200-KEY-ERROR.
           MOVE EIBRESP               TO KE-RESP.
           MOVE EIBRESP2              TO KE-RESP2.
           MOVE KEY-ERROR             TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

       9200-EXIT.
           EXIT.

      *****************************************************************
      * FAxxDC Document Template error.                               *
      *****************************************************************
       9300-URL-ERROR.
           MOVE EIBRESP               TO KE-RESP.
           MOVE EIBRESP2              TO KE-RESP2.
           MOVE DC-ERROR              TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

       9300-EXIT.
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


      *****************************************************************
      * Issue WRITE for HTTP header - zFAM LOB (Large Object Binary)  *
      *****************************************************************
       9996-WRITE-LOB.
           MOVE LENGTH OF HTTP-LOB            TO ZFAM-LOB-LENGTH.
           MOVE LENGTH OF HTTP-LOB-VALUE      TO LOB-VALUE-LENGTH.
           MOVE 'yes'                         TO HTTP-LOB-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-LOB)
                NAMELENGTH (ZFAM-LOB-LENGTH)
                VALUE      (HTTP-LOB-VALUE)
                VALUELENGTH(LOB-VALUE-LENGTH)
                RESP       (LOB-RESP)
                SESSTOKEN  (SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       9996-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE for HTTP header - zFAM Append.                    *
      *****************************************************************
       9997-WRITE-APP.
           MOVE LENGTH OF HTTP-APP            TO ZFAM-APP-LENGTH.
           MOVE LENGTH OF HTTP-APP-VALUE      TO APP-VALUE-LENGTH.
           MOVE 'yes'                         TO HTTP-APP-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-APP)
                NAMELENGTH (ZFAM-APP-LENGTH)
                VALUE      (HTTP-APP-VALUE)
                VALUELENGTH(APP-VALUE-LENGTH)
                RESP       (APP-RESP)
                SESSTOKEN  (SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       9997-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE for HTTP header - zFAM ECR (Event Control Record) *
      *****************************************************************
       9998-WRITE-ECR.
           MOVE LENGTH OF HTTP-ECR            TO ZFAM-ECR-LENGTH.
           MOVE LENGTH OF HTTP-ECR-VALUE      TO ECR-VALUE-LENGTH.
           MOVE 'Yes'                         TO HTTP-ECR-VALUE.

           EXEC CICS WEB WRITE
                HTTPHEADER (HTTP-ECR)
                NAMELENGTH (ZFAM-ECR-LENGTH)
                VALUE      (HTTP-ECR-VALUE)
                VALUELENGTH(ECR-VALUE-LENGTH)
                RESP       (ECR-RESP)
                SESSTOKEN  (SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       9998-EXIT.
           EXIT.

      *****************************************************************
      * Create URI Path for replication request.                      *
      *****************************************************************
       9999-CREATE-URI.
           MOVE LOW-VALUES                   TO THE-PATH.

           STRING WEB-PATH         DELIMITED BY SPACE
                  THE-SLASH        DELIMITED BY SIZE
                  FK-KEY           DELIMITED BY LOW-VALUES
                  INTO             THE-PATH.

           MOVE ZEROES             TO TRAILING-SPACES.
           INSPECT FUNCTION REVERSE(THE-PATH)
           TALLYING TRAILING-SPACES
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-SPACES FROM LENGTH OF THE-PATH
           GIVING THE-PATH-LENGTH.

       9999-EXIT.
           EXIT.
