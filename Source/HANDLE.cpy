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

      *****************************************************************
      * Check READ KEY store response.                                *
      *****************************************************************
       3290-CHECK-RESPONSE.
           IF  EIBRESP     EQUAL DFHRESP(NOTFND)
               MOVE EIBDS                    TO CA090-FILE
               MOVE STATUS-204               TO CA090-STATUS
               MOVE '01'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE FC-READ                  TO FE-FN
               MOVE '3290'                   TO FE-PARAGRAPH
               PERFORM 9997-FCT-ERROR      THRU 9997-EXIT
               MOVE EIBDS                    TO CA090-FILE
               MOVE HTTP-STATUS-507          TO CA090-STATUS
               MOVE '01'                     TO CA090-REASON
               PERFORM 9998-ZFAM090        THRU 9998-EXIT.

       3290-EXIT.
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
