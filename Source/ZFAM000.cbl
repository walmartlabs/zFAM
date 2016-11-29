       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM000.
       AUTHOR.     Rich Jackson and Randy Frerking.
      *****************************************************************
      *                                                               *
      * z/OS File Access Manager.                                     *
      *                                                               *
      * This program executes as a background transaction to expire   *
      * messages from a zFAM table.                                   *
      *                                                               *
      * There will be a task started by zECSPLT for each ZCxx         *
      * URIMAP entry.                                                 *
      *                                                               *
      *                                                               *
      * Date       UserID    Description                              *
      * ---------- --------  ---------------------------------------- *
      *                                                               *
      *****************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *****************************************************************
      * DEFINE LOCAL VARIABLES                                        *
      *****************************************************************
       01  CURRENT-ABS            PIC S9(15) COMP-3 VALUE 0.
       01  CREATED-ABS            PIC S9(15) COMP-3 VALUE 0.
       01  RELATIVE-TIME          PIC S9(15) COMP-3 VALUE 0.
       01  ONE-YEAR               PIC S9(15) COMP-3 VALUE 31536000.
       01  ONE-DAY                PIC S9(15) COMP-3 VALUE 86400.
       01  TWELVE                 PIC S9(02) COMP-3 VALUE 12.
       01  TEN                    PIC S9(02) COMP-3 VALUE 10.
       01  ONE                    PIC S9(02) COMP-3 VALUE 1.
       01  FIVE-HUNDRED           PIC S9(04) COMP-3 VALUE 500.
       01  ONE-HUNDRED            PIC S9(04) COMP-3 VALUE 100.
       01  RECORD-COUNT           PIC S9(04) COMP-3 VALUE 0.
       01  DELETE-COUNT           PIC S9(04) COMP-3 VALUE 0.
       01  RESET-COUNT            PIC S9(04) COMP-3 VALUE 0.
       01  FIVE-TWELVE            PIC S9(08) COMP   VALUE 512.
       01  TWO-FIFTY-SIX          PIC S9(08) COMP   VALUE 256.
       01  NINTY-SIX              PIC S9(08) COMP   VALUE 96.
       01  NINES                  PIC S9(04) COMP   VALUE 9999.
       01  BINARY-ONE             PIC S9(04) COMP   VALUE 1.

      *****************************************************************
      * Trace parameters                                              *
      *****************************************************************
       01  T_LEN                  PIC S9(04) COMP VALUE 8.
       01  T_46                   PIC S9(04) COMP VALUE 46.
       01  T_46_M                 PIC  X(08) VALUE SPACES.
       01  T_RES                  PIC  X(08) VALUE 'ZFAM000 '.

      *****************************************************************
      * faEXPIRE control file resources - start                       *
      *****************************************************************
       01  FX-FCT                 PIC  X(08) VALUE 'FAEXPIRE'.
       01  FX-RESP                PIC S9(08) COMP VALUE ZEROES.
       01  FX-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       01  FX-RECORD.
           02  FX-KEY             PIC  X(04).
           02  FX-ABSTIME         PIC S9(15) COMP-3 VALUE ZEROES.
           02  FX-INTERVAL        PIC S9(07) COMP-3 VALUE 86400.
           02  FX-RESTART         PIC S9(07) COMP-3 VALUE 86400.
           02  FX-DATE            PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FX-TIME            PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FX-APPLID          PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FX-TASKID          PIC  9(06).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(14).

      *****************************************************************
      * faEXPIRE control file resources - end                         *
      *****************************************************************

       01  RET-MILLISECONDS       PIC S9(15) VALUE ZEROES COMP-3.
       01  FILLER.
           02  RET-SEC-MS.
               03  RET-SECONDS    PIC  9(10) VALUE ZEROES.
               03  FILLER         PIC  9(03) VALUE ZEROES.
           02  FILLER REDEFINES RET-SEC-MS.
               03  RET-TIME       PIC  9(13).

       01  USERID                 PIC  X(08) VALUE SPACES.
       01  APPLID                 PIC  X(08) VALUE SPACES.
       01  SYSID                  PIC  X(04) VALUE SPACES.
       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  EOF                    PIC  X(01) VALUE SPACES.
       01  SLASH                  PIC  X(01) VALUE '/'.

       01  FA-PARM.
           02  FA-TRANID          PIC  X(04) VALUE SPACES.
           02  FA-KEY             PIC X(255) VALUE LOW-VALUES.

       01  FA-LENGTH              PIC S9(04) COMP VALUE 20.

       01  ZFAM-DC.
           02  DC-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(02) VALUE 'DC'.
           02  FILLER             PIC  X(42) VALUE SPACES.

       01  FA-EXPIRE-ENQ.
           02  FILLER             PIC  X(08) VALUE 'CICSGRS_'.
           02  FILLER             PIC  X(08) VALUE 'ZFAM000_'.
           02  FA-ENQ-TRANID      PIC  X(04) VALUE SPACES.


       01  FK-FCT.
           02  FK-TRANID          PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(04) VALUE 'KEY '.

       01  FF-FCT.
           02  FF-TRANID          PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(04) VALUE 'FILE'.

       01  FK-RESP                PIC S9(08) COMP VALUE ZEROES.
       01  FK-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  FF-LENGTH              PIC S9(04) COMP VALUE ZEROES.
       01  DELETE-LENGTH          PIC S9(04) COMP VALUE 8.

       COPY ZFAMFKC.

       01  FC-READ                PIC  X(06) VALUE 'READ  '.
       01  FC-DELETE              PIC  X(06) VALUE 'DELETE'.

       01  CSSL                   PIC  X(04) VALUE '@tdq@'.
       01  TD-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       01  TD-EXPIRE.
           02  TD-TRAN-ID         PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(08) VALUE 'zFAM000 '.
           02  TD-CURRENT-DATE    PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-CURRENT-TIME    PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(09) VALUE 'Created: '.
           02  TD-CREATED-DATE    PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-CREATED-TIME    PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(05) VALUE 'TTL: '.
           02  TD-RETENTION-TYPE  PIC  X(01).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-RETENTION       PIC  9(05).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(05) VALUE 'Key: '.
           02  TD-KEY             PIC  X(44).

       01  TD-ERROR.
           02  ER-TRAN            PIC  X(04).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  ER-DATE            PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  ER-TIME            PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  ER-DS              PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(07) VALUE 'EIBFN: '.
           02  ER-FN              PIC  X(06) VALUE SPACES.
           02  FILLER             PIC  X(10) VALUE ' EIBRESP: '.
           02  ER-RESP            PIC  9(08) VALUE ZEROES.
           02  FILLER             PIC  X(11) VALUE ' EIBRESP2: '.
           02  ER-RESP2           PIC  9(04) VALUE ZEROES.
           02  FILLER             PIC  X(12) VALUE ' Paragraph: '.
           02  ER-PARAGRAPH       PIC  X(08) VALUE SPACES.
           02  FILLER             PIC  X(12) VALUE SPACES.

      *****************************************************************
      * Deplicate resources.                                          *
      *****************************************************************

       01  URI-MAP                PIC  X(08) VALUE SPACES.
       01  URI-PATH               PIC X(255) VALUE SPACES.
       01  URI-ZEXPIRE            PIC  X(09) VALUE 'zExpire/*'.

       01  RESOURCES              PIC  X(10) VALUE '/resources'.
       01  DEPLICATE              PIC  X(10) VALUE '/deplicate'.

       01  HTTP-STATUS-200        PIC S9(04) COMP VALUE 200.
       01  HTTP-STATUS-201        PIC S9(04) COMP VALUE 201.

       01  NUMBER-OF-SPACES       PIC S9(08) COMP VALUE ZEROES.
       01  NUMBER-OF-NULLS        PIC S9(08) COMP VALUE ZEROES.
       01  WEB-METHOD             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  WEB-HOST-LENGTH        PIC S9(08) COMP VALUE 120.
       01  WEB-HTTPMETHOD-LENGTH  PIC S9(08) COMP VALUE 10.
       01  WEB-HTTPVERSION-LENGTH PIC S9(08) COMP VALUE 15.
       01  WEB-PATH-LENGTH        PIC S9(08) COMP VALUE 256.
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
       01  WEB-QUERYSTRING        PIC X(256) VALUE SPACES.

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

       01  TWO                    PIC S9(08) COMP  VALUE 2.
       01  SESSION-TOKEN          PIC  9(18) COMP VALUE ZEROES.

       01  URL-SCHEME-NAME        PIC  X(16) VALUE SPACES.
       01  URL-SCHEME             PIC S9(08) COMP VALUE ZEROES.
       01  URL-PORT               PIC S9(08) COMP VALUE ZEROES.
       01  URL-HOST-NAME          PIC  X(80) VALUE SPACES.
       01  URL-HOST-NAME-LENGTH   PIC S9(08) COMP VALUE 80.
       01  WEB-STATUS-CODE        PIC S9(04) COMP VALUE 00.
       01  WEB-STATUS-LENGTH      PIC S9(08) COMP VALUE 96.
       01  WEB-STATUS-TEXT.
           02  WEB-STATUS-ABS     PIC  9(15) VALUE ZEROES.
           02  FILLER             PIC  X(81) VALUE SPACES.

       01  WEB-PATH               PIC X(512) VALUE SPACES.

       01  CONVERSE-LENGTH        PIC S9(08) COMP VALUE 96.
       01  CONVERSE-RESPONSE      PIC  X(96) VALUE SPACES.

       COPY ZFAMFFC.

       LINKAGE SECTION.
       01  DFHCOMMAREA            PIC  X(01).


       PROCEDURE DIVISION.

      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 1000-RETRIEVE           THRU 1000-EXIT.
           PERFORM 2000-START-BROWSE       THRU 2000-EXIT.
           PERFORM 3000-READ-NEXT          THRU 3000-EXIT
                   WITH TEST AFTER
                   UNTIL EOF EQUAL 'Y'.
           PERFORM 8000-RESTART            THRU 8000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Retrieve information for zFAM   table expiration task.        *
      *****************************************************************
       1000-RETRIEVE.
           EXEC CICS ASSIGN APPLID(APPLID)
           END-EXEC.

           EXEC CICS HANDLE ABEND LABEL(9100-ABEND) NOHANDLE
           END-EXEC.

           MOVE LENGTH OF FA-PARM TO FA-LENGTH.

           EXEC CICS RETRIEVE INTO(FA-PARM)
                LENGTH(FA-LENGTH) NOHANDLE
           END-EXEC.

           MOVE FA-KEY TO FK-KEY.

           MOVE FA-TRANID         TO FK-TRANID
                                     FF-TRANID
                                     DC-TRANID.

           MOVE EIBTRNID          TO FA-ENQ-TRANID.

           EXEC CICS ASKTIME ABSTIME(CURRENT-ABS) NOHANDLE
           END-EXEC.

           IF  FA-KEY EQUAL LOW-VALUES
               PERFORM 1100-CONTROL    THRU 1100-EXIT.

       1000-EXIT.
           EXIT.

      *****************************************************************
      * Read faEXPIRE control file when a 'resume' key is not         *
      * provided on the RETRIEVE command.  Issue an ENQ to serialize  *
      * the expiration proces.                                        *
      *****************************************************************
       1100-CONTROL.
           PERFORM 1200-ENQ            THRU 1200-EXIT.

           MOVE EIBTRNID                 TO FX-KEY.
           MOVE LENGTH OF FX-RECORD      TO FX-LENGTH.

           EXEC CICS READ
                FILE   (FX-FCT)
                RIDFLD (FX-KEY)
                INTO   (FX-RECORD)
                LENGTH (FX-LENGTH)
                RESP   (FX-RESP)
                UPDATE
                NOHANDLE
           END-EXEC.

           IF  FX-RESP EQUAL DFHRESP(NOTFND)
               PERFORM 1300-WRITE      THRU 1300-EXIT.

           IF  FX-RESP EQUAL DFHRESP(NORMAL)
               PERFORM 1400-UPDATE     THRU 1400-EXIT.

       1100-EXIT.
           EXIT.

      *****************************************************************
      * Issue ENQ to serialize the expiration process.                *
      *****************************************************************
       1200-ENQ.
           EXEC CICS ENQ RESOURCE(FA-EXPIRE-ENQ)
                LENGTH(LENGTH OF  FA-EXPIRE-ENQ)
                NOHANDLE
                NOSUSPEND
                TASK
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(ENQBUSY)
               PERFORM 8000-RESTART    THRU 8000-EXIT
               PERFORM 9000-RETURN     THRU 9000-EXIT.

       1200-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE to faEXPIRE control file with default information.*
      *****************************************************************
       1300-WRITE.
           MOVE EIBTRNID                 TO FX-KEY.
           MOVE LENGTH OF FX-RECORD      TO FX-LENGTH.

           EXEC CICS FORMATTIME
                ABSTIME (CURRENT-ABS)
                TIME    (FX-TIME)
                YYYYMMDD(FX-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           MOVE CURRENT-ABS              TO FX-ABSTIME.
           MOVE APPLID                   TO FX-APPLID.
           MOVE EIBTASKN                 TO FX-TASKID.

           EXEC CICS WRITE
                FILE   (FX-FCT)
                RIDFLD (FX-KEY)
                FROM   (FX-RECORD)
                LENGTH (FX-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(DUPREC)
               PERFORM 8000-RESTART    THRU 8000-EXIT
               PERFORM 9000-RETURN     THRU 9000-EXIT.


       1300-EXIT.
           EXIT.

      *****************************************************************
      * Update faEXPIRE record.                                       *
      *****************************************************************
       1400-UPDATE.
           MOVE EIBTRNID                 TO FX-KEY.
           MOVE LENGTH OF FX-RECORD      TO FX-LENGTH.

           EXEC CICS FORMATTIME
                ABSTIME (CURRENT-ABS)
                TIME    (FX-TIME)
                YYYYMMDD(FX-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           MOVE FX-INTERVAL              TO RET-SECONDS.
           MOVE RET-TIME                 TO RET-MILLISECONDS.

           SUBTRACT FX-ABSTIME FROM CURRENT-ABS GIVING RELATIVE-TIME.
           IF  RELATIVE-TIME LESS THAN RET-MILLISECONDS
               PERFORM 8000-RESTART    THRU 8000-EXIT
               PERFORM 9000-RETURN     THRU 9000-EXIT.

           MOVE CURRENT-ABS              TO FX-ABSTIME.
           MOVE APPLID                   TO FX-APPLID.
           MOVE EIBTASKN                 TO FX-TASKID.

           EXEC CICS REWRITE
                FILE  (FX-FCT)
                FROM  (FX-RECORD)
                LENGTH(FX-LENGTH)
                NOHANDLE
           END-EXEC.

       1400-EXIT.
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
               MOVE '2000'                  TO ER-PARAGRAPH
               PERFORM 9920-LOG-ERROR     THRU 9920-EXIT
               PERFORM 9000-RETURN        THRU 9000-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Read the key store (FK), which contains the internal key to   *
      * the file/data store.                                          *
      *****************************************************************
       3000-READ-NEXT.
           MOVE LENGTH     OF FK-RECORD TO FK-LENGTH.

           EXEC CICS READNEXT
                FILE  (FK-FCT)
                INTO  (FK-RECORD)
                RIDFLD(FK-KEY)
                LENGTH(FK-LENGTH)
                RESP  (FK-RESP)
                NOHANDLE
           END-EXEC.

           IF  FK-RESP     EQUAL DFHRESP(NOTFND)
           OR  FK-RESP     EQUAL DFHRESP(ENDFILE)
               MOVE 'Y'                   TO EOF
           ELSE
           IF  FK-RESP NOT EQUAL DFHRESP(NORMAL)
               MOVE '3000'                TO ER-PARAGRAPH
               PERFORM 9920-LOG-ERROR   THRU 9920-EXIT
               PERFORM 8000-RESTART     THRU 8000-EXIT
               PERFORM 9000-RETURN      THRU 9000-EXIT.

           IF  FK-RESP     EQUAL DFHRESP(NORMAL)
           IF  FK-ECR      EQUAL 'Y'
               PERFORM 3100-PROCESS-ECR THRU 3100-EXIT.

           IF  FK-RESP     EQUAL DFHRESP(NORMAL)
           IF  FK-ECR  NOT EQUAL 'Y'
               PERFORM 4000-READ-FILE   THRU 4000-EXIT.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Check Event Control Record for expiration.                    *
      * ECRs do not contain entries in the FILE store.                *
      * The ABSTIME in the KEY store is used by ECR for expiration    *
      * and for Basic Mode row level locking.                         *
      *****************************************************************
       3100-PROCESS-ECR.
           IF  FK-RETENTION-TYPE EQUAL 'D'
               MULTIPLY FK-RETENTION BY ONE-DAY  GIVING RET-SECONDS.

           IF  FK-RETENTION-TYPE EQUAL 'Y'
               MULTIPLY FK-RETENTION BY ONE-YEAR GIVING RET-SECONDS.

           MOVE RET-TIME         TO RET-MILLISECONDS.

           SUBTRACT FK-ABS FROM CURRENT-ABS GIVING RELATIVE-TIME.

           MOVE '3100'           TO T_46_M.
           PERFORM 8888-TRACE  THRU 8888-EXIT.

           IF  RELATIVE-TIME GREATER THAN RET-MILLISECONDS
               PERFORM 5000-DEPLICATE   THRU 5000-EXIT.

       3100-EXIT.
           EXIT.

      *****************************************************************
      * Read FAxx file  record.                                       *
      * Since there can be multiple segments for a single zFAM        *
      * record, only check the first record and make decisions        *
      * accordingly.                                                  *
      * When restarting after a resume time interval, the last record *
      * key will be returned on the RETRIEVE command.  Use this key   *
      * to resume processing.                                         *
      *****************************************************************
       4000-READ-FILE.
           MOVE LOW-VALUES                TO FF-KEY-16.
           MOVE FK-FF-KEY                 TO FF-KEY.
           MOVE BINARY-ONE                TO FF-SEGMENT.

           MOVE LENGTH OF FF-RECORD       TO FF-LENGTH.

           EXEC CICS READ FILE(FF-FCT)
                RIDFLD(FF-KEY-16)
                INTO  (FF-RECORD)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'Y'    TO EOF
               PERFORM 8000-RESTART     THRU 8000-EXIT
               PERFORM 9000-RETURN      THRU 9000-EXIT.

           IF  FF-RETENTION-TYPE EQUAL 'D'
               MULTIPLY FF-RETENTION BY ONE-DAY  GIVING RET-SECONDS.

           IF  FF-RETENTION-TYPE EQUAL 'Y'
               MULTIPLY FF-RETENTION BY ONE-YEAR GIVING RET-SECONDS.

           MOVE RET-TIME         TO RET-MILLISECONDS.

           SUBTRACT FF-ABS FROM CURRENT-ABS GIVING RELATIVE-TIME.

           MOVE '4000'           TO T_46_M.
           PERFORM 8888-TRACE  THRU 8888-EXIT.

           IF  RELATIVE-TIME GREATER THAN RET-MILLISECONDS
               PERFORM 5000-DEPLICATE   THRU 5000-EXIT.

       4000-EXIT.
           EXIT.

      *****************************************************************
      * Deplicate request to the other Data Center.                   *
      * Delete *FILE and *KEY  records only when eligible to expire   *
      * at both Data Centers, otherwise update this record with the   *
      * other ABSTIME.                                                *
      *                                                               *
      * If we don't contact the partner Data Center successfully, no  *
      * worries.  The expiration process on the partner Data Center   *
      * will perform the delete during expiration process.            *
      *                                                               *
      *****************************************************************
       5000-DEPLICATE.
           PERFORM 7000-GET-URL               THRU 7000-EXIT.

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

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
           OR  EIBRESP EQUAL DFHRESP(LENGERR)
           IF  WEB-STATUS-CODE EQUAL HTTP-STATUS-201
           AND WEB-STATUS-ABS  NUMERIC
               PERFORM 5100-UPDATE-ABS        THRU 5100-EXIT
           ELSE
               PERFORM 9900-LOG-EXPIRATION    THRU 9900-EXIT
               PERFORM 5200-DELETE            THRU 5200-EXIT.

       5000-EXIT.
           EXIT.

      *****************************************************************
      * Update ABS in the local zFAM  record.                         *
      *****************************************************************
       5100-UPDATE-ABS.
           MOVE LENGTH OF FF-RECORD       TO FF-LENGTH.

           EXEC CICS READ FILE(FF-FCT)
                RIDFLD(FF-KEY-16)
                INTO  (FF-RECORD)
                LENGTH(FF-LENGTH)
                UPDATE
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
               PERFORM 5110-REWRITE     THRU 5110-EXIT.

       5100-EXIT.
           EXIT.

      *****************************************************************
      * Issue REWRITE with ABS from partner site.                     *
      *****************************************************************
       5110-REWRITE.
           MOVE WEB-STATUS-ABS            TO FF-ABS.

           EXEC CICS REWRITE FILE(FF-FCT)
                FROM  (FF-RECORD)
                LENGTH(FF-LENGTH)
                NOHANDLE
           END-EXEC.

           EXEC CICS SYNCPOINT NOHANDLE
           END-EXEC.

           ADD ONE TO RESET-COUNT.
           IF  RESET-COUNT  GREATER THAN FIVE-HUNDRED
               PERFORM 8100-RESTART      THRU 8100-EXIT
               PERFORM 9000-RETURN       THRU 9000-EXIT.

       5110-EXIT.
           EXIT.

      *****************************************************************
      * Delete the local zFAM  record.                                *
      *****************************************************************
       5200-DELETE.
           IF  FK-ECR NOT EQUAL 'Y'
               PERFORM 5210-DELETE           THRU 5210-EXIT
                   WITH TEST AFTER
                   VARYING FF-SEGMENT   FROM 1 BY 1
                   UNTIL   FF-SEGMENT   GREATER THAN FF-SEGMENTS
                   OR      EIBRESP  NOT EQUAL DFHRESP(NORMAL).

           EXEC CICS DELETE FILE(FK-FCT)
                RIDFLD(FK-KEY)
                NOHANDLE
           END-EXEC.

           ADD ONE TO RECORD-COUNT.
           IF  RECORD-COUNT GREATER THAN TEN
               PERFORM 5220-SYNCPOINT    THRU 5220-EXIT.

           ADD ONE TO DELETE-COUNT.
           IF  DELETE-COUNT GREATER THAN FIVE-HUNDRED
               PERFORM 8100-RESTART      THRU 8100-EXIT
               PERFORM 9000-RETURN       THRU 9000-EXIT.

       5200-EXIT.
           EXIT.

      *****************************************************************
      * Issue DELETE for every segment.                               *
      *****************************************************************
       5210-DELETE.
           EXEC CICS DELETE FILE(FF-FCT)
                RIDFLD(FF-KEY-16)
                NOHANDLE
           END-EXEC.

       5210-EXIT.
           EXIT.

      *****************************************************************
      * Issue SYNCPOINT every TEN records.                            *
      *****************************************************************
       5220-SYNCPOINT.
           MOVE ZEROES  TO RECORD-COUNT.

           EXEC CICS SYNCPOINT NOHANDLE
           END-EXEC.

           EXEC CICS DELAY INTERVAL(0) NOHANDLE
           END-EXEC.

       5220-EXIT.
           EXIT.

      *****************************************************************
      * Get URL for deplication process.                              *
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
               MOVE ACTIVE-SINGLE                 TO DC-TYPE.

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

       7100-EXIT.
           EXIT.

      *****************************************************************
      * Converse with the other Data Center zFAM.                     *
      * The first element of the path, which for normal processing is *
      * /resources, must be changed to /deplicate.                    *
      *****************************************************************
       7200-WEB-CONVERSE.
           MOVE NINTY-SIX        TO WEB-STATUS-LENGTH.
           MOVE NINTY-SIX        TO CONVERSE-LENGTH.
           MOVE FIVE-TWELVE      TO WEB-PATH-LENGTH.
           MOVE ZEROES           TO NUMBER-OF-NULLS.
           MOVE ZEROES           TO NUMBER-OF-SPACES.
           MOVE FA-TRANID        TO URI-MAP.
           MOVE 'D'              TO URI-MAP(5:1).

           EXEC CICS INQUIRE URIMAP(URI-MAP)
                PATH(URI-PATH)
                NOHANDLE
           END-EXEC.

           STRING URI-PATH
                  SLASH
                  FK-KEY
                  DELIMITED BY '*'
                  INTO WEB-PATH.

           INSPECT WEB-PATH TALLYING NUMBER-OF-NULLS
                   FOR ALL LOW-VALUES.
           SUBTRACT NUMBER-OF-NULLS  FROM WEB-PATH-LENGTH.

           INSPECT WEB-PATH TALLYING NUMBER-OF-SPACES
                   FOR ALL SPACES.
           SUBTRACT NUMBER-OF-SPACES FROM WEB-PATH-LENGTH.

           MOVE DEPLICATE TO WEB-PATH(1:10).

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
      * Restart (ICE chain).                                          *
      * 24 hour interval for normal processing                        *
      *****************************************************************
       8000-RESTART.

           MOVE LENGTH OF FA-PARM TO FA-LENGTH.
           MOVE LOW-VALUES        TO FA-KEY.

           EXEC CICS START TRANSID(EIBTRNID)
                INTERVAL(240000)
                FROM    (FA-PARM)
                LENGTH  (FA-LENGTH)
                NOHANDLE
           END-EXEC.

       8000-EXIT.
           EXIT.

      *****************************************************************
      * Restart (ICE chain).                                          *
      * 02 second interval when reset  count exceeds 500 hundred.     *
      *****************************************************************
       8100-RESTART.

           MOVE LENGTH OF FA-PARM TO FA-LENGTH.
           MOVE FK-KEY            TO FA-KEY.

           EXEC CICS START TRANSID(EIBTRNID)
                INTERVAL(0002)
                FROM    (FA-PARM)
                LENGTH  (FA-LENGTH)
                NOHANDLE
           END-EXEC.

       8100-EXIT.
           EXIT.

      *****************************************************************
      * Issue TRACE.                                                  *
      *****************************************************************
       8888-TRACE.

           EXEC CICS ENTER TRACENUM(T_46)
                FROM(T_46_M)
                FROMLENGTH(T_LEN)
                RESOURCE(T_RES)
                NOHANDLE
           END-EXEC.

       8888-EXIT.
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
      * Task abended.  Restart and Return.                            *
      *****************************************************************
       9100-ABEND.
           PERFORM 8000-RESTART    THRU 8000-EXIT.
           PERFORM 9000-RETURN     THRU 9000-EXIT.

       9100-EXIT.
           EXIT.

      *****************************************************************
      * Write expiration messages to CSSL.                            *
      *****************************************************************
       9900-LOG-EXPIRATION.
           PERFORM 9950-ABS         THRU 9950-EXIT.
           EXEC CICS FORMATTIME ABSTIME(CURRENT-ABS)
                TIME(TD-CURRENT-TIME)
                YYYYMMDD(TD-CURRENT-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           IF  FK-ECR EQUAL 'Y'
               MOVE FK-RETENTION      TO TD-RETENTION
               MOVE FK-RETENTION-TYPE TO TD-RETENTION-TYPE
               MOVE FK-ABS            TO CREATED-ABS.

           IF  FK-ECR NOT EQUAL 'Y'
               MOVE FF-RETENTION      TO TD-RETENTION
               MOVE FF-RETENTION-TYPE TO TD-RETENTION-TYPE
               MOVE FF-ABS            TO CREATED-ABS.

           EXEC CICS FORMATTIME ABSTIME(CREATED-ABS)
                TIME(TD-CREATED-TIME)
                YYYYMMDD(TD-CREATED-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           MOVE EIBTRNID              TO TD-TRAN-ID.
           MOVE FK-KEY                TO TD-KEY.

           MOVE LENGTH OF TD-EXPIRE   TO TD-LENGTH.

           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM(TD-EXPIRE)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

       9900-EXIT.
           EXIT.

      *****************************************************************
      * Write error messages to CSSL.                                 *
      *****************************************************************
       9920-LOG-ERROR.
           PERFORM 9950-ABS         THRU 9950-EXIT.
           EXEC CICS FORMATTIME ABSTIME(CURRENT-ABS)
                TIME(TD-CURRENT-TIME)
                YYYYMMDD(TD-CURRENT-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           MOVE EIBTRNID              TO ER-TRAN.
           MOVE EIBFN                 TO ER-FN.
           MOVE EIBDS                 TO ER-DS.
           MOVE EIBRESP               TO ER-RESP.
           MOVE EIBRESP2              TO ER-RESP2.

           MOVE LENGTH OF TD-ERROR    TO TD-LENGTH.

           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM(TD-ERROR)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

       9920-EXIT.
           EXIT.

      *****************************************************************
      * Get Absolute time.                                            *
      *****************************************************************
       9950-ABS.
           EXEC CICS ASKTIME ABSTIME(CURRENT-ABS) NOHANDLE
           END-EXEC.

       9950-EXIT.
           EXIT.


      *****************************************************************
      * Get URL for replication process.                              *
      * URL must be in the following format:                          *
      * http://domain-name.wal-mart.com:55123                         *
      *****************************************************************
       9999-GET-URL.

           MOVE LENGTH OF THE-OTHER-DC TO THE-OTHER-DC-LENGTH.

           EXEC CICS DOCUMENT CREATE DOCTOKEN(DC-TOKEN)
                TEMPLATE(ZFAM-DC)
                NOHANDLE
           END-EXEC.

           EXEC CICS DOCUMENT RETRIEVE DOCTOKEN(DC-TOKEN)
                INTO     (THE-OTHER-DC)
                LENGTH   (THE-OTHER-DC-LENGTH)
                MAXLENGTH(THE-OTHER-DC-LENGTH)
                DATAONLY
                NOHANDLE
           END-EXEC.

           IF  EIBRESP EQUAL DFHRESP(NORMAL)
           AND THE-OTHER-DC-LENGTH GREATER THAN TWO
               SUBTRACT TWO FROM THE-OTHER-DC-LENGTH.

           EXEC CICS WEB PARSE
                URL(THE-OTHER-DC)
                URLLENGTH(THE-OTHER-DC-LENGTH)
                SCHEMENAME(URL-SCHEME-NAME)
                HOST(URL-HOST-NAME)
                HOSTLENGTH(URL-HOST-NAME-LENGTH)
                PORTNUMBER(URL-PORT)
                NOHANDLE
           END-EXEC.

       9999-EXIT.
           EXIT.
