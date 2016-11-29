       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM003.
       AUTHOR.  Rich Jackson and Randy Frerking
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager                               *
      *                                                               *
      * This program is executed when an HTTP/DELETE request WITH     *
      * HTTP headers zFAM-RangeBegin and zFAM-RangeEnd are found by   *
      * the Basic Mode program zFAM002.                               *
      *                                                               *
      * A maximum of 1000 records will be deleted on a single request *
      * with the number of records deleted and the last key deleted   *
      * returned in a response header.  The last key can be used by   *
      * the client/consumer on a subsequent request when the maximum  *
      * 1000 records are deleted before reaching the key in the       *
      * zFAM-RangeEnd header.                                         *
      *                                                               *
      * Date       UserID    Description                              *
      * ---------- --------  ---------------------------------------- *
      *                                                               *
      *                                                               *
      *****************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *****************************************************************
      * DEFINE LOCAL VARIABLES                                        *
      *****************************************************************
       01  CURRENT-ABS            PIC S9(15) COMP-3 VALUE ZEROES.
       01  STATUS-LENGTH          PIC S9(08) COMP   VALUE 255.
       01  RESPONSE-LENGTH        PIC S9(08) COMP   VALUE 4.
       01  RESPONSE-COUNT         PIC S9(08) COMP   VALUE 0.
       01  READ-COUNT             PIC S9(08) COMP   VALUE 0.
       01  DELETE-COUNT           PIC S9(08) COMP   VALUE 0.
       01  TRAILING-NULLS         PIC S9(08) COMP   VALUE 0.
       01  ONE-THOUSAND           PIC S9(08) COMP   VALUE 1000.
       01  TWELVE                 PIC S9(08) COMP   VALUE 12.
       01  TEN                    PIC S9(08) COMP   VALUE 10.
       01  EIGHT                  PIC S9(08) COMP   VALUE 8.
       01  SEVEN                  PIC S9(08) COMP   VALUE 7.
       01  TWO                    PIC S9(08) COMP   VALUE 2.
       01  ONE                    PIC S9(08) COMP   VALUE 1.
       01  FIVE-TWELVE            PIC S9(08) COMP   VALUE 512.

       01  TYPE-FULL              PIC  X(07) VALUE 'Full   '.
       01  TYPE-GENERIC           PIC  X(07) VALUE 'Generic'.

       01  EOF                    PIC  X(01) VALUE SPACES.
       01  SLASH                  PIC  X(01) VALUE '/'.

       01  ADR                    PIC  X(03) VALUE 'ADR'.
       01  SDR                    PIC  X(03) VALUE 'SDR'.

       01  DOT                    PIC  X(01) VALUE '.'.

       01  CRLF                   PIC  X(02) VALUE X'0D25'.


      *****************************************************************
      * HTTP headers for LastKey and Rows response.                   *
      *****************************************************************
       01  HEADER-LASTKEY         PIC  X(12) VALUE 'zFAM-LastKey'.
       01  HEADER-LASTKEY-LENGTH  PIC S9(08) COMP VALUE 12.
       01  HEADER-ROWS            PIC  X(09) VALUE 'zFAM-Rows'.
       01  HEADER-ROWS-LENGTH     PIC S9(08) COMP VALUE 9.

       01  RESPONSE-DISPLAY       PIC  9(04) VALUE ZEROES.
       01  LAST-KEY               PIC X(255) VALUE LOW-VALUES.

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

       01  TYPE-RESPONSE          PIC S9(08) COMP VALUE ZEROES.
       01  HEADER-TYPE-LENGTH     PIC S9(08) COMP VALUE 14.
       01  HEADER-TYPE            PIC  X(15) VALUE 'zFAM-RangeType'.
       01  TYPE-VALUE-LENGTH      PIC S9(08) COMP VALUE 07.
       01  TYPE-VALUE             PIC  X(07) VALUE 'Full   '.

       01  ZFAM-DC.
           02  DC-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(02) VALUE 'DC'.
           02  FILLER             PIC  X(42) VALUE SPACES.

       01  FK-FCT.
           02  FK-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(04) VALUE 'KEY '.

       01  FF-FCT.
           02  FF-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(04) VALUE 'FILE'.

       01  FK-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  FF-LENGTH              PIC S9(04) COMP VALUE ZEROES.

      *****************************************************************
      * zFAM KEY  record definition.                                  *
      *****************************************************************
       COPY ZFAMFKC.

       01  T_LEN                  PIC S9(04) COMP VALUE 8.
       01  T_46                   PIC S9(04) COMP VALUE 46.
       01  T_46_M                 PIC  X(08) VALUE SPACES.
       01  T_RES                  PIC  X(08) VALUE 'ZFAM002 '.

      *****************************************************************
      * Start - zFAM error message resources.                         *
      *****************************************************************
       01  ZFAM090                PIC  X(08) VALUE 'ZFAM090 '.
       01  CSSL-ABS               PIC S9(15) COMP-3 VALUE ZEROES.

       01  HTTP-STATUS-503        PIC  9(03) VALUE 503.
       01  HTTP-STATUS-507        PIC  9(03) VALUE 507.

       01  HTTP-503-99-LENGTH     PIC S9(08) COMP VALUE 48.
       01  HTTP-503-99-TEXT.
           02  FILLER             PIC  X(16) VALUE '99-002 Service u'.
           02  FILLER             PIC  X(16) VALUE 'navailable and l'.
           02  FILLER             PIC  X(16) VALUE 'ogging disabled '.

       01  ZFAM090-COMMAREA.
           02  CA090-STATUS       PIC  9(03) VALUE ZEROES.
           02  CA090-REASON       PIC  9(02) VALUE ZEROES.
           02  CA090-USERID       PIC  X(08) VALUE SPACES.
           02  CA090-PROGRAM      PIC  X(08) VALUE SPACES.
           02  CA090-FILE         PIC  X(08) VALUE SPACES.
           02  CA090-FIELD        PIC  X(16) VALUE SPACES.
           02  CA090-KEY          PIC X(255) VALUE SPACES.

       01  FCT-ERROR.
           02  FILLER             PIC  X(13) VALUE 'File Error   '.
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

      *****************************************************************
      * End   - zFAM error message resources.                         *
      *****************************************************************

       01  FC-READ                PIC  X(06) VALUE 'READ  '.
       01  FC-DELETE              PIC  X(06) VALUE 'DELETE'.
       01  CSSL                   PIC  X(04) VALUE '@tdq@'.
       01  TD-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       01  TD-RECORD.
           02  TD-DATE            PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TIME            PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TRANID          PIC  X(04).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-MESSAGE         PIC  X(90) VALUE SPACES.


       01  URI-MAP                PIC  X(08) VALUE SPACES.
       01  URI-PATH               PIC X(255) VALUE SPACES.

       01  RESOURCES              PIC  X(10) VALUE '/resources'.
       01  REPLICATE              PIC  X(10) VALUE '/replicate'.

       01  HTTP-STATUS            PIC S9(04) COMP.
       01  HTTP-TEXT-LENGTH       PIC S9(08) COMP.
       01  HTTP-TEXT              PIC  X(48).

       01  HTTP-STATUS-200        PIC S9(04) COMP VALUE 200.
       01  HTTP-200-LENGTH        PIC S9(08) COMP VALUE 02.
       01  HTTP-200-TEXT          PIC  X(02) VALUE 'OK'.

       01  HTTP-STATUS-204        PIC S9(04) COMP VALUE 204.
       01  HTTP-204-LENGTH        PIC S9(08) COMP VALUE 64.
       01  HTTP-204-TEXT.
           02  FILLER             PIC  X(04) VALUE '204 '.
           02  HTTP-204-RC        PIC  X(02) VALUE '00'.
           02  FILLER             PIC  X(10) VALUE '-003 Range'.
           02  FILLER             PIC  X(16) VALUE 'Begin Key provid'.
           02  FILLER             PIC  X(16) VALUE 'ed for DELETE no'.
           02  FILLER             PIC  X(16) VALUE 't found.        '.

       01  HTTP-STATUS-206        PIC S9(04) COMP VALUE 206.
       01  HTTP-206-LENGTH        PIC S9(08) COMP VALUE 64.
       01  HTTP-206-TEXT.
           02  FILLER             PIC  X(16) VALUE '206 01-003 Maxim'.
           02  FILLER             PIC  X(16) VALUE 'um delete of 100'.
           02  FILLER             PIC  X(16) VALUE '0 records comple'.
           02  FILLER             PIC  X(16) VALUE 'ted successfully'.

       01  SEND-ACTION            PIC S9(08) COMP VALUE ZEROES.
       01  NUMBER-OF-SPACES       PIC S9(08) COMP VALUE ZEROES.
       01  NUMBER-OF-NULLS        PIC S9(08) COMP VALUE ZEROES.
       01  WEB-METHOD             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-PATH-LENGTH        PIC S9(08) COMP VALUE 256.

       01  ACTIVE-SINGLE          PIC  X(02) VALUE 'A1'.
       01  ACTIVE-ACTIVE          PIC  X(02) VALUE 'AA'.
       01  ACTIVE-STANDBY         PIC  X(02) VALUE 'AS'.

       01  DC-CONTROL.
           02  FILLER             PIC  X(06).
           02  DC-TYPE            PIC  X(02) VALUE SPACES.
           02  DC-CRLF            PIC  X(02).
           02  THE-OTHER-DC       PIC X(160) VALUE SPACES.
           02  FILLER             PIC  X(02).
       01  DC-LENGTH              PIC S9(08) COMP  VALUE ZEROES.
       01  DC-TOKEN               PIC  X(16) VALUE SPACES.

       01  THE-OTHER-DC-LENGTH    PIC S9(08) COMP  VALUE 160.

       01  SESSION-TOKEN          PIC  9(18) COMP VALUE ZEROES.

       01  URL-SCHEME-NAME        PIC  X(16) VALUE SPACES.
       01  URL-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  URL-PORT               PIC S9(08) COMP VALUE ZEROES.
       01  URL-HOST-NAME          PIC  X(80) VALUE SPACES.
       01  URL-HOST-NAME-LENGTH   PIC S9(08) COMP VALUE 80.
       01  WEB-STATUS-CODE        PIC S9(04) COMP VALUE 00.
       01  WEB-STATUS-LENGTH      PIC S9(08) COMP VALUE 80.
       01  WEB-STATUS-TEXT        PIC  X(80) VALUE SPACES.

       01  WEB-PATH               PIC X(512) VALUE SPACES.

       01  CONVERSE-LENGTH        PIC S9(08) COMP VALUE 80.
       01  CONVERSE-RESPONSE      PIC  X(80) VALUE SPACES.

       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.

      *****************************************************************
      * zFAM FILE record definition.                                  *
      *****************************************************************
       COPY ZFAMFFC.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           02  CA-TYPE            PIC  X(03).
           02  CA-URI-FIELD-01    PIC  X(10).

       PROCEDURE DIVISION.

      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 1000-INITIALIZE         THRU 1000-EXIT.
           PERFORM 2000-REPLICATE          THRU 2000-EXIT.
           PERFORM 3000-START-BROWSE       THRU 3000-EXIT
           PERFORM 4000-READ-NEXT          THRU 4000-EXIT
                   WITH TEST AFTER
                   UNTIL EOF  EQUAL 'Y'
                OR READ-COUNT EQUAL        ONE-THOUSAND
                OR READ-COUNT GREATER THAN ONE-THOUSAND.
           PERFORM 5000-DELETE-COMPLETE    THRU 5000-EXIT.
           PERFORM 8000-SEND-RESPONSE      THRU 8000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Initialize resources for Delete 'Range' request.              *
      * When this is a replicate request to the partner Data Center,  *
      *   issue SEND IMMEDIATE.                                       *
      * When this is an asynchronous delete request on the local      *
      *   Data Center, SEND IMMEDIATE.                                *
      *****************************************************************
       1000-INITIALIZE.
           MOVE EIBTRNID(3:2)     TO FK-TRANID(3:2)
                                     FF-TRANID(3:2)
                                     DC-TRANID(3:2).

           EXEC CICS ASKTIME ABSTIME(CURRENT-ABS) NOHANDLE
           END-EXEC.

           PERFORM 1100-HTTP-HEADER        THRU 1100-EXIT.

       1000-EXIT.
           EXIT.

      *****************************************************************
      * Read zFAM-RangeBegin and zFAM-RangeEnd HTTP headers.          *
      * Read zFAM-RangeType HTTP header.                              *
      *****************************************************************
       1100-HTTP-HEADER.
           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-BEGIN)
                NAMELENGTH  (HEADER-BEGIN-LENGTH)
                VALUE       (BEGIN-VALUE)
                VALUELENGTH (BEGIN-VALUE-LENGTH)
                RESP        (BEGIN-RESPONSE)
                NOHANDLE
           END-EXEC.

           INSPECT BEGIN-VALUE
           REPLACING ALL SPACES BY LOW-VALUES.

           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-END)
                NAMELENGTH  (HEADER-END-LENGTH)
                VALUE       (END-VALUE)
                VALUELENGTH (END-VALUE-LENGTH)
                RESP        (END-RESPONSE)
                NOHANDLE
           END-EXEC.

           INSPECT END-VALUE
           REPLACING ALL SPACES BY LOW-VALUES.

           EXEC CICS WEB READ
                HTTPHEADER  (HEADER-TYPE)
                NAMELENGTH  (HEADER-TYPE-LENGTH)
                VALUE       (TYPE-VALUE)
                VALUELENGTH (TYPE-VALUE-LENGTH)
                RESP        (TYPE-RESPONSE)
                NOHANDLE
           END-EXEC.

       1100-EXIT.
           EXIT.

      *****************************************************************
      * Replicate request to the partner Data Center.                 *
      * If this is a replicate request, set document type to null,    *
      * as this IS the partner Data Center.                           *
      *****************************************************************
       2000-REPLICATE.
           PERFORM 7000-GET-URL               THRU 7000-EXIT.

           IF  CA-URI-FIELD-01 EQUAL REPLICATE
               MOVE LOW-VALUES TO    DC-TYPE.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
           IF  DC-TYPE EQUAL ACTIVE-ACTIVE
           OR  DC-TYPE EQUAL ACTIVE-STANDBY
               PERFORM 7100-WEB-OPEN          THRU 7100-EXIT.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
           IF  DC-TYPE EQUAL ACTIVE-ACTIVE
           OR  DC-TYPE EQUAL ACTIVE-STANDBY
               MOVE DFHVALUE(DELETE)            TO WEB-METHOD
               PERFORM 7200-WEB-CONVERSE      THRU 7200-EXIT.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
           IF  DC-TYPE EQUAL ACTIVE-ACTIVE
           OR  DC-TYPE EQUAL ACTIVE-STANDBY
               PERFORM 7300-WEB-CLOSE         THRU 7300-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Start browse of KEY store.                                    *
      *****************************************************************
       3000-START-BROWSE.

           MOVE BEGIN-VALUE TO FK-KEY.
           MOVE LENGTH      OF FK-RECORD TO FK-LENGTH.

           EXEC CICS STARTBR FILE(FK-FCT)
                RIDFLD(FK-KEY)
                NOHANDLE
                GTEQ
           END-EXEC.

           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
           OR  EIBRESP     EQUAL DFHRESP(ENDFILE)
               MOVE '01'                    TO HTTP-204-RC
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                  TO FE-FN
               MOVE '3000'                   TO FE-PARAGRAPH
               PERFORM 9997-FCT-ERROR      THRU 9997-EXIT
               MOVE EIBDS                    TO CA090-FILE
               MOVE HTTP-STATUS-507          TO CA090-STATUS
               MOVE '01'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Issue READNEXT for the KEY store.                             *
      *****************************************************************
       4000-READ-NEXT.
           EXEC CICS READNEXT
                FILE  (FK-FCT)
                INTO  (FK-RECORD)
                RIDFLD(FK-KEY)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
           OR  EIBRESP     EQUAL DFHRESP(ENDFILE)
               MOVE 'Y'                     TO EOF.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                  TO FE-FN
               MOVE '4000'                   TO FE-PARAGRAPH
               PERFORM 9997-FCT-ERROR      THRU 9997-EXIT
               MOVE EIBDS                    TO CA090-FILE
               MOVE HTTP-STATUS-507          TO CA090-STATUS
               MOVE '02'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

           IF  EOF NOT EQUAL 'Y'
               PERFORM 4100-RANGE-BEGIN   THRU 4100-EXIT.

           IF  EOF NOT EQUAL 'Y'
               PERFORM 4200-RANGE-END     THRU 4200-EXIT.

           IF  EOF NOT EQUAL 'Y'
               ADD ONE                      TO RESPONSE-COUNT
               MOVE FK-KEY                  TO LAST-KEY
               PERFORM 4300-DELETE        THRU 4300-EXIT.

           ADD ONE                          TO READ-COUNT.
           ADD ONE                          TO DELETE-COUNT.

           IF  DELETE-COUNT EQUAL        TEN
           OR  DELETE-COUNT GREATER THAN TEN
               PERFORM 4500-SYNCPOINT     THRU 4500-EXIT.

       4000-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeBegin and compare with Primary Key using      *
      * 'Full' key comparison.                                        *
      *****************************************************************
       4100-RANGE-BEGIN.
           EXEC CICS IGNORE CONDITION SYSIDERR
           END-EXEC.

           IF  TYPE-VALUE EQUAL TYPE-FULL
           IF  BEGIN-VALUE LESS THAN FK-KEY
               MOVE '02'                    TO HTTP-204-RC
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       4100-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeType for 'Full' or 'Generic' key range.       *
      *****************************************************************
       4200-RANGE-END.
           IF  TYPE-VALUE EQUAL TYPE-FULL
               PERFORM 4210-FULL          THRU 4210-EXIT.

           IF  TYPE-VALUE EQUAL TYPE-GENERIC
               PERFORM 4220-GENERIC       THRU 4220-EXIT.

       4200-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeEnd and compare with Primary Key using        *
      * 'Full' key comparison.                                        *
      *****************************************************************
       4210-FULL.
           IF  FK-KEY     GREATER THAN
               END-VALUE
               MOVE 'Y' TO EOF.
       4210-EXIT.
           EXIT.

      *****************************************************************
      * Check zFAM-RangeEnd and compare with Primary Key using        *
      * 'Generic' key comparison.                                     *
      *****************************************************************
       4220-GENERIC.
           IF  FK-KEY     (1:END-VALUE-LENGTH) GREATER THAN
               END-VALUE  (1:END-VALUE-LENGTH)
               MOVE 'Y' TO EOF.
       4220-EXIT.
           EXIT.

      *****************************************************************
      * Delete the KEY store record.                                  *
      *****************************************************************
       4300-DELETE.
           EXEC CICS DELETE FILE(FK-FCT)
                RIDFLD(FK-KEY)
                NOHANDLE
           END-EXEC.

           MOVE FK-FF-KEY                   TO FF-KEY.
           PERFORM 4400-DELETE            THRU 4400-EXIT
               WITH TEST AFTER
               VARYING FF-SEGMENT FROM 1 BY ONE
               UNTIL EIBRESP NOT EQUAL DFHRESP(NORMAL).

       4300-EXIT.
           EXIT.

      *****************************************************************
      * Delete the FILE store record.                                 *
      *****************************************************************
       4400-DELETE.
           EXEC CICS DELETE FILE(FF-FCT)
                RIDFLD(FF-KEY-16)
                NOHANDLE
           END-EXEC.

       4400-EXIT.
           EXIT.

      *****************************************************************
      * Issue SYNCPOINT and DELAY for every 10 DELETE commands.       *
      *****************************************************************
       4500-SYNCPOINT.
           MOVE ZERO TO DELETE-COUNT.

           EXEC CICS SYNCPOINT NOHANDLE
           END-EXEC.

           EXEC CICS DELAY INTERVAL(0) NOHANDLE
           END-EXEC.

           EXEC CICS ENDBR FILE(FK-FCT) NOHANDLE
           END-EXEC.

           PERFORM 3000-START-BROWSE      THRU 3000-EXIT.

       4500-EXIT.
           EXIT.

      *****************************************************************
      * DELETE request complete.                                      *
      *****************************************************************
       5000-DELETE-COMPLETE.
           MOVE '5000    '                  TO T_46_M.
           PERFORM 9995-TRACE             THRU 9995-EXIT.

           IF  READ-COUNT EQUAL ONE
               MOVE '03'                    TO HTTP-204-RC
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       5000-EXIT.
           EXIT.

      *****************************************************************
      * Get URL for replication process.                              *
      * URL must be in the following format:                          *
      * http://hostname:port                                          *
      *****************************************************************
       7000-GET-URL.

           EXEC CICS DOCUMENT CREATE DOCTOKEN(DC-TOKEN)
                TEMPLATE(ZFAM-DC)
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF DC-CONTROL TO DC-LENGTH.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               EXEC CICS DOCUMENT RETRIEVE
                    DOCTOKEN (DC-TOKEN)
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
                    URL       (THE-OTHER-DC)
                    URLLENGTH (THE-OTHER-DC-LENGTH)
                    SCHEMENAME(URL-SCHEME-NAME)
                    HOST      (URL-HOST-NAME)
                    HOSTLENGTH(URL-HOST-NAME-LENGTH)
                    PORTNUMBER(URL-PORT)
                    NOHANDLE
               END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
           OR  DC-LENGTH        LESS THAN TEN
           OR  DC-LENGTH        EQUAL     TEN
               MOVE ACTIVE-SINGLE          TO DC-TYPE.

       7000-EXIT.
           EXIT.


      *****************************************************************
      * Open WEB connection with the other Data Center zFAM.          *
      *****************************************************************
       7100-WEB-OPEN.
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

           PERFORM 7110-HTTP-HEADER   THRU 7110-EXIT.

       7100-EXIT.
           EXIT.

      *****************************************************************
      * Write zFAM-RangeBegin and zFAM-RangeEnd HTTP headers.         *
      *****************************************************************
       7110-HTTP-HEADER.
           EXEC CICS WEB WRITE
                HTTPHEADER  (HEADER-BEGIN)
                NAMELENGTH  (HEADER-BEGIN-LENGTH)
                VALUE       (BEGIN-VALUE)
                VALUELENGTH (BEGIN-VALUE-LENGTH)
                RESP        (BEGIN-RESPONSE)
                SESSTOKEN   (SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

           EXEC CICS WEB WRITE
                HTTPHEADER  (HEADER-END)
                NAMELENGTH  (HEADER-END-LENGTH)
                VALUE       (END-VALUE)
                VALUELENGTH (END-VALUE-LENGTH)
                RESP        (END-RESPONSE)
                SESSTOKEN   (SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

           EXEC CICS WEB WRITE
                HTTPHEADER  (HEADER-TYPE)
                NAMELENGTH  (HEADER-TYPE-LENGTH)
                VALUE       (TYPE-VALUE)
                VALUELENGTH (TYPE-VALUE-LENGTH)
                RESP        (TYPE-RESPONSE)
                SESSTOKEN   (SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       7110-EXIT.
           EXIT.

      *****************************************************************
      * Converse with the partner Data Center zFAM.                   *
      * The first element of the path, which for normal processing is *
      * /resources, must be changed to /replicate.                    *
      *****************************************************************
       7200-WEB-CONVERSE.
           MOVE FIVE-TWELVE      TO WEB-PATH-LENGTH.
           MOVE ZEROES           TO NUMBER-OF-NULLS.
           MOVE ZEROES           TO NUMBER-OF-SPACES.
           MOVE EIBTRNID         TO URI-MAP.
           MOVE 'R'              TO URI-MAP(5:1).

           EXEC CICS INQUIRE URIMAP(URI-MAP)
                PATH(URI-PATH)
                NOHANDLE
           END-EXEC.

           STRING URI-PATH
                  DOT
                  ADR
                  SLASH
                  DELIMITED BY '*'
                  INTO WEB-PATH.

           INSPECT WEB-PATH TALLYING NUMBER-OF-NULLS
                   FOR ALL LOW-VALUES.
           SUBTRACT NUMBER-OF-NULLS  FROM WEB-PATH-LENGTH.

           INSPECT WEB-PATH TALLYING NUMBER-OF-SPACES
                   FOR ALL SPACES.
           SUBTRACT NUMBER-OF-SPACES FROM WEB-PATH-LENGTH.

           MOVE REPLICATE TO WEB-PATH(1:10).

           EXEC CICS WEB CONVERSE
                SESSTOKEN (SESSION-TOKEN)
                PATH      (WEB-PATH)
                PATHLENGTH(WEB-PATH-LENGTH)
                METHOD    (WEB-METHOD)
                MEDIATYPE (FF-MEDIA)
                INTO      (CONVERSE-RESPONSE)
                TOLENGTH  (CONVERSE-LENGTH)
                MAXLENGTH (CONVERSE-LENGTH)
                STATUSCODE(WEB-STATUS-CODE)
                STATUSLEN (WEB-STATUS-LENGTH)
                STATUSTEXT(WEB-STATUS-TEXT)
                NOOUTCONVERT
                NOHANDLE
           END-EXEC.

       7200-EXIT.
           EXIT.

      *****************************************************************
      * Close WEB connection with the other Data Center zFAM.         *
      *****************************************************************
       7300-WEB-CLOSE.

           EXEC CICS WEB CLOSE
                SESSTOKEN(SESSION-TOKEN)
                NOHANDLE
           END-EXEC.

       7300-EXIT.
           EXIT.

      *****************************************************************
      * Send response to client                                       *
      *****************************************************************
       8000-SEND-RESPONSE.
           MOVE ZEROES TO TRAILING-NULLS.
           INSPECT FUNCTION REVERSE(LAST-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF LAST-KEY
               GIVING STATUS-LENGTH.

           PERFORM 9600-HEADER       THRU 9600-EXIT.

           MOVE DFHVALUE(IMMEDIATE)    TO SEND-ACTION.

           IF  EOF EQUAL 'Y'
               MOVE HTTP-STATUS-200    TO HTTP-STATUS
               MOVE HTTP-200-LENGTH    TO HTTP-TEXT-LENGTH
               MOVE HTTP-200-TEXT      TO HTTP-TEXT.

           IF  EOF NOT EQUAL 'Y'
               MOVE HTTP-STATUS-206    TO HTTP-STATUS
               MOVE HTTP-206-LENGTH    TO HTTP-TEXT-LENGTH
               MOVE HTTP-206-TEXT      TO HTTP-TEXT.

           EXEC CICS WEB SEND
                FROM       (CRLF)
                FROMLENGTH (TWO)
                MEDIATYPE  (TEXT-PLAIN)
                ACTION     (SEND-ACTION)
                STATUSCODE (HTTP-STATUS)
                STATUSTEXT (HTTP-TEXT)
                STATUSLEN  (HTTP-TEXT-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       8000-EXIT.
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
      * Write an HTTP header containing the LastKey and Rows          *
      *****************************************************************
       9600-HEADER.
           MOVE RESPONSE-COUNT          TO RESPONSE-DISPLAY.

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
                VALUE      (RESPONSE-DISPLAY)
                VALUELENGTH(RESPONSE-LENGTH)
                NOHANDLE
           END-EXEC.

       9600-EXIT.
           EXIT.

      *****************************************************************
      * Status 204 response.                                          *
      *****************************************************************
       9700-STATUS-204.
           EXEC CICS DOCUMENT CREATE DOCTOKEN(DC-TOKEN)
                NOHANDLE
           END-EXEC.

           MOVE DFHVALUE(IMMEDIATE)     TO SEND-ACTION.

           EXEC CICS WEB SEND
                DOCTOKEN  (DC-TOKEN)
                MEDIATYPE (TEXT-PLAIN)
                ACTION    (SEND-ACTION)
                STATUSCODE(HTTP-STATUS-204)
                STATUSTEXT(HTTP-204-TEXT)
                STATUSLEN (HTTP-204-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       9700-EXIT.
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
      * File Control Table (FCT) error                                *
      *****************************************************************
       9997-FCT-ERROR.
           MOVE EIBDS                 TO FE-DS.
           MOVE EIBRESP               TO FE-RESP.
           MOVE EIBRESP2              TO FE-RESP2.
           MOVE FCT-ERROR             TO TD-MESSAGE.
           PERFORM 9999-WRITE-CSSL  THRU 9999-EXIT.

       9997-EXIT.
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

           EXEC CICS RETURN
           END-EXEC.

       9998-EXIT.
           EXIT.

      *****************************************************************
      * Write TD CSSL.                                                *
      *****************************************************************
       9999-WRITE-CSSL.

           EXEC CICS ASKTIME ABSTIME(CSSL-ABS) NOHANDLE
           END-EXEC.

           MOVE EIBTRNID              TO TD-TRANID.

           EXEC CICS FORMATTIME ABSTIME(CSSL-ABS)
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

       9999-EXIT.
           EXIT.
