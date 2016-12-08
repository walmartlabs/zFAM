       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM004.
       AUTHOR.  Rich Jackson and Randy Frerking.
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager                               *
      *                                                               *
      * This program is executed via XCTL from ZFAM002 to process     *
      * an HTTP/GET request with a query string of GE or GT, which    *
      * is used to 'browse' the table forward one record at a time.   *
      *                                                               *
      * This program is also called by zFAM002 when the query string  *
      * contains 'ex' (?ex), which is used to determine if a record   *
      * key 'exists' on the table.  In this case, the record is not   *
      * returned, only the status code 200 when the record key is     *
      * in the table or 204 if the record key is not in the table.    *
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
       01  DOCUMENT-TOKEN         PIC  X(16) VALUE SPACES.
       01  USERID                 PIC  X(08) VALUE SPACES.
       01  APPLID                 PIC  X(08) VALUE SPACES.
       01  SYSID                  PIC  X(04) VALUE SPACES.
       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  BINARY-ZEROES          PIC  X(01) VALUE LOW-VALUES.
       01  BINARY-ZERO            PIC  X(01) VALUE X'00'.
       01  HEX-01                 PIC  X(01) VALUE X'01'.
       01  CRLF                   PIC  X(02) VALUE X'0D25'.

       01  TWO                    PIC S9(08) COMP VALUE 2.
       01  SERVER-CONVERT         PIC S9(08) COMP VALUE ZEROES.

       01  HEADER-LASTKEY         PIC  X(12) VALUE 'zFAM-LastKey'.
       01  HEADER-LASTKEY-LENGTH  PIC S9(08) COMP VALUE 12.
       01  HEADER-ROWS            PIC  X(09) VALUE 'zFAM-Rows'.
       01  HEADER-ROWS-LENGTH     PIC S9(08) COMP VALUE 09.

       01  MESSAGE-COUNT          PIC  9(04) VALUE 1.
       01  MESSAGE-COUNT-LENGTH   PIC S9(08) COMP VALUE 04.

       01  ZFAM006                PIC  X(08) VALUE 'ZFAM006 '.

       01  LINKAGE-ADDRESSES.
           02  ZFAM-ADDRESS       USAGE POINTER.
           02  ZFAM-ADDRESS-X     REDEFINES ZFAM-ADDRESS
                                  PIC S9(08) COMP.

           02  SAVE-ADDRESS       USAGE POINTER.
           02  SAVE-ADDRESS-X     REDEFINES SAVE-ADDRESS
                                  PIC S9(08) COMP.

       01  GETMAIN-LENGTH         PIC S9(08) COMP VALUE ZEROES.
       01  STATUS-LENGTH          PIC S9(08) COMP VALUE 255.
       01  TRAILING-NULLS         PIC S9(08) COMP VALUE 0.

       01  TWO-FIFTY-FIVE         PIC S9(08) COMP VALUE 255.
       01  ONE                    PIC S9(08) COMP VALUE  1.

       01  HTTP-STATUS-200        PIC S9(04) COMP VALUE 200.
       01  HTTP-STATUS-204        PIC S9(04) COMP VALUE 204.

       01  HTTP-204-LENGTH        PIC S9(08) COMP VALUE 64.
       01  HTTP-204-TEXT.
           02  FILLER             PIC  X(11) VALUE '204 01-004 '.
           02  HTTP-204-FILE      PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(16) VALUE ' Record not foun'.
           02  FILLER             PIC  X(16) VALUE 'd on zFAM table.'.
           02  FILLER             PIC  X(16) VALUE '                '.

       01  HTTP-507-LENGTH        PIC S9(08) COMP VALUE 64.
       01  HTTP-507-TEXT.
           02  FILLER             PIC  X(11) VALUE '507 01-004 '.
           02  HTTP-507-FILE      PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(16) VALUE ' Error accessing'.
           02  FILLER             PIC  X(16) VALUE ' zFAM table.    '.
           02  FILLER             PIC  X(16) VALUE '                '.

       01  HTTP-OK                PIC  X(02) VALUE 'OK'.

       01  TEXT-ANYTHING          PIC  X(04) VALUE 'text'.
       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.
       01  APPLICATION-XML        PIC  X(56) VALUE 'application/xml'.
       01  APPLICATION-JSON       PIC  X(56) VALUE 'application/json'.

       01  PROCESS-COMPLETE       PIC  X(01) VALUE SPACES.
       01  FF-SUCCESSFUL          PIC  X(01) VALUE SPACES.

       01  GET-COUNT              PIC  9(03) VALUE ZEROES.

       01  GET-EX                 PIC  X(02) VALUE 'ex'.
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
           02  GET-CA-KEYS        PIC  X(01).
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
           PERFORM 2000-CHECK-KEY          THRU 2000-EXIT.
           PERFORM 3000-PROCESS-ZFAM       THRU 3000-EXIT.
           PERFORM 4000-SEND-RESPONSE      THRU 4000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Perform initialization.                                       *
      *****************************************************************
       1000-INITIALIZE.
           MOVE EIBTRNID(3:2)               TO FK-TRANID(3:2).
           MOVE EIBTRNID(3:2)               TO FF-TRANID(3:2).

       1000-EXIT.
           EXIT.

      *****************************************************************
      * The valid GET-CA-TYPE parameters for this program are:        *
      * GT - Greater than                                             *
      * GE - Greater than or equal                                    *
      *                                                               *
      * For optimum performance, READ requests will be GTEQ and not   *
      * a STARTBR/READNEXT operation.                                 *
      *                                                               *
      * When GE is specified, use the key as is, however when GT is   *
      * specified, the key must be incremented by one bit otherwise   *
      * the key presented could be read again.                        *
      *****************************************************************
       2000-CHECK-KEY.
           IF  GET-CA-TYPE EQUAL GET-GT
               PERFORM 2100-AUGMENT-KEY  THRU 2100-EXIT.

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
           IF  GET-CA-TYPE EQUAL GET-EX
               PERFORM 5000-EXISTENCE  THRU 5000-EXIT.

           PERFORM 3100-READ-PROCESS   THRU 3100-EXIT
               WITH TEST AFTER
               UNTIL PROCESS-COMPLETE  EQUAL 'Y'.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Read the KEY structure, which contains an internal key to the *
      * FILE structure.                                               *
      *                                                               *
      * Read the FILE structure, which contains the zFAM data as      *
      * record segments.                                              *
      *****************************************************************
       3100-READ-PROCESS.
           MOVE 'Y'                          TO PROCESS-COMPLETE.
           PERFORM 3200-READ-KEY           THRU 3200-EXIT.
           PERFORM 3300-READ-FILE          THRU 3300-EXIT.
           IF  FF-SUCCESSFUL EQUAL 'Y'
               PERFORM 3400-STAGE          THRU 3400-EXIT.
       3100-EXIT.
           EXIT.

      *****************************************************************
      * Read KEY structure using GTEQ.                                *
      *****************************************************************
       3200-READ-KEY.

           MOVE GET-CA-KEY TO FK-KEY.
           MOVE LENGTH     OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
                GTEQ
           END-EXEC.

           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
               MOVE ZEROES                  TO STATUS-LENGTH
               MOVE ZEROES                  TO MESSAGE-COUNT
               PERFORM 9600-HEADER        THRU 9600-EXIT
               MOVE EIBDS                   TO HTTP-204-FILE
               PERFORM 9700-STATUS-204    THRU 9700-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                  TO FE-FN
               MOVE '3200'                   TO FE-PARAGRAPH
               PERFORM 9997-FCT-ERROR      THRU 9997-EXIT
               MOVE EIBDS                    TO CA090-FILE
               MOVE HTTP-STATUS-507          TO CA090-STATUS
               MOVE '01'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

       3200-EXIT.
           EXIT.

      *****************************************************************
      * Read FILE structure.                                          *
      *****************************************************************
       3300-READ-FILE.
           MOVE 'Y'                     TO FF-SUCCESSFUL.

           MOVE FK-DDNAME               TO FF-DDNAME.
           MOVE FK-FF-KEY               TO FF-KEY.
           MOVE ZEROES                  TO FF-ZEROES.
           MOVE LENGTH OF FF-RECORD     TO FF-LENGTH.

           MOVE ONE                     TO FF-SEGMENT.

           EXEC CICS READ FILE(FF-FCT)
                INTO(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NOTFND)
               MOVE FK-KEY              TO GET-CA-KEY
               PERFORM 2100-AUGMENT-KEY  THRU 2100-EXIT
               MOVE 'N'                 TO PROCESS-COMPLETE
               MOVE 'N'                 TO FF-SUCCESSFUL
           ELSE
           IF  EIBRESP     EQUAL DFHRESP(NORMAL)
               NEXT SENTENCE
           ELSE
           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               PERFORM 9810-STATUS-507   THRU 9810-EXIT
               PERFORM 9000-RETURN       THRU 9000-EXIT.

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
               PERFORM 3500-READ-SEGMENTS THRU 3500-EXIT
                   WITH TEST AFTER
                   UNTIL FF-SEGMENT GREATER THAN FF-SEGMENTS
                   OR    FF-SUCCESSFUL EQUAL 'N'.

       3400-EXIT.
           EXIT.

      *****************************************************************
      * Read FILE structure segment records.                          *
      *****************************************************************
       3500-READ-SEGMENTS.
           SET ADDRESS OF ZFAM-MESSAGE           TO ZFAM-ADDRESS.
           MOVE LENGTH OF FF-RECORD              TO FF-LENGTH.

           EXEC CICS READ FILE(FF-FCT)
                INTO(FF-RECORD)
                RIDFLD(FF-KEY-16)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               SUBTRACT FF-PREFIX              FROM FF-LENGTH
               MOVE FF-DATA(1:FF-LENGTH)         TO ZFAM-MESSAGE
               ADD  FF-LENGTH                    TO ZFAM-ADDRESS-X
               ADD  ONE                          TO FF-SEGMENT
               ADD  FF-LENGTH                    TO ZFAM-LENGTH
           ELSE
               MOVE 'N'                          TO PROCESS-COMPLETE
               MOVE 'N'                          TO FF-SUCCESSFUL
               PERFORM 3510-FREEMAIN           THRU 3510-EXIT.

       3500-EXIT.
           EXIT.

      *****************************************************************
      * FREEMAIN message segment buffer.                              *
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
      * Send zFAM   information.                                      *
      *****************************************************************
       4000-SEND-RESPONSE.

           IF  FF-SEGMENTS EQUAL ONE
               SET ADDRESS OF ZFAM-MESSAGE   TO ADDRESS OF FF-DATA.

           IF  FF-SEGMENTS GREATER THAN ONE
               SET ADDRESS OF ZFAM-MESSAGE   TO SAVE-ADDRESS.

           MOVE FF-MEDIA                     TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN               TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)          TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL SPACES BY LOW-VALUES.

           INSPECT FUNCTION REVERSE(FK-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF FK-KEY
               GIVING STATUS-LENGTH.

           PERFORM 9600-HEADER THRU 9600-EXIT.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE DFHVALUE(SRVCONVERT)     TO SERVER-CONVERT
           ELSE
               MOVE DFHVALUE(NOSRVCONVERT)   TO SERVER-CONVERT.

           EXEC CICS WEB SEND
                FROM      (ZFAM-MESSAGE)
                FROMLENGTH(ZFAM-LENGTH)
                MEDIATYPE (WEB-MEDIA-TYPE)
                STATUSCODE(HTTP-STATUS-200)
                STATUSTEXT(FK-KEY)
                STATUSLEN (STATUS-LENGTH)
                ACTION    (SEND-ACTION)
                SERVERCONV(SERVER-CONVERT)
                NOHANDLE
           END-EXEC.

       4000-EXIT.
           EXIT.

      *****************************************************************
      * HTTP GET - ?ex                                                *
      * Read KEY structure to determine whether or not a key exists.  *
      *****************************************************************
       5000-EXISTENCE.
           MOVE GET-CA-KEY TO FK-KEY.
           MOVE LENGTH     OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READ FILE(FK-FCT)
                INTO(FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE FF-MEDIA                    TO WEB-MEDIA-TYPE.

           IF  WEB-MEDIA-TYPE EQUAL SPACES
               MOVE TEXT-PLAIN              TO WEB-MEDIA-TYPE.

           MOVE DFHVALUE(IMMEDIATE)         TO SEND-ACTION.

           INSPECT WEB-MEDIA-TYPE
           REPLACING ALL SPACES BY LOW-VALUES.

           INSPECT FUNCTION REVERSE(FK-KEY)
           TALLYING TRAILING-NULLS
           FOR LEADING LOW-VALUES.

           SUBTRACT TRAILING-NULLS FROM LENGTH OF FK-KEY
               GIVING STATUS-LENGTH.

           IF  WEB-MEDIA-TYPE(1:04) EQUAL TEXT-ANYTHING
           OR  WEB-MEDIA-TYPE(1:15) EQUAL APPLICATION-XML
           OR  WEB-MEDIA-TYPE(1:16) EQUAL APPLICATION-JSON
               MOVE DFHVALUE(SRVCONVERT)     TO SERVER-CONVERT
           ELSE
               MOVE DFHVALUE(NOSRVCONVERT)   TO SERVER-CONVERT.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               EXEC CICS WEB SEND
                    FROM      (CRLF)
                    FROMLENGTH(TWO)
                    STATUSCODE(HTTP-STATUS-200)
                    STATUSTEXT(FK-KEY)
                    STATUSLEN (STATUS-LENGTH)
                    ACTION    (SEND-ACTION)
                    SERVERCONV(SERVER-CONVERT)
                    NOHANDLE
               END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NOTFND)
               MOVE EIBDS                   TO HTTP-204-FILE
               PERFORM 9700-STATUS-204    THRU 9700-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
           AND EIBRESP NOT EQUAL DFHRESP(NOTFND)
               PERFORM 9810-STATUS-507    THRU 9810-EXIT.

           PERFORM 9000-RETURN            THRU 9000-EXIT.

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
      * Write an HTTP header containing the LastKey and Rows.         *
      *****************************************************************
       9600-HEADER.

           EXEC CICS WEB WRITE
                HTTPHEADER (HEADER-LASTKEY)
                NAMELENGTH (HEADER-LASTKEY-LENGTH)
                VALUE      (FK-KEY)
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
                DOCTOKEN  (DOCUMENT-TOKEN)
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
      * zFAM file error.                                              *
      *****************************************************************
       9810-STATUS-507.
           MOVE EIBDS TO HTTP-507-FILE
           EXEC CICS WEB SEND
                FROM      (HTTP-507-TEXT)
                FROMLENGTH(HTTP-507-LENGTH)
                STATUSCODE(HTTP-STATUS-507)
                STATUSTEXT(HTTP-507-TEXT)
                STATUSLEN (HTTP-507-LENGTH)
                ACTION    (SEND-ACTION)
                SERVERCONV(SERVER-CONVERT)
                NOHANDLE
           END-EXEC.

       9810-EXIT.
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
      * File Control Table (FCT) error                                *
      *****************************************************************
       9997-FCT-ERROR.
           MOVE EIBDS                 TO FE-DS.
           MOVE EIBRESP               TO FE-RESP.
           MOVE EIBRESP2              TO FE-RESP2.
           MOVE FCT-ERROR             TO TD-MESSAGE.
           PERFORM 9900-WRITE-CSSL  THRU 9900-EXIT.

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
