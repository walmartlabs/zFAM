       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM031.
       AUTHOR.  Rich Jackson and Randy Frerking.
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager.                              *
      *                                                               *
      * Basic Mode PUT/UPDATE request for a table that has a Query    *
      * Mode FAxxFD schema.                                           *
      *                                                               *
      * When a schema exists, ZFAM002 will LINK to ZFAM031 to         *
      * determine if there are secondary column indexes defined,      *
      * and if so, delete the old CI records and create the new       *
      * CI records.                                                   *
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

       01  WS-ABS                 PIC S9(15) COMP-3 VALUE ZEROES.
       01  SIXTY-FOUR-KB          PIC S9(08) COMP   VALUE 64000.
       01  HEX-INDEX              PIC S9(04) COMP   VALUE ZEROES.

       01  PROCESS-LENGTH         PIC S9(08) COMP   VALUE ZEROES.
       01  PROCESS-TYPE           PIC  X(06) VALUE SPACES.
       01  NEW-KEY                PIC  X(08) VALUE SPACES.
       01  OLD-KEY                PIC  X(08) VALUE SPACES.
       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  ONE                    PIC  9(03) VALUE 001.

       01  ZFAM090                PIC  X(08) VALUE 'ZFAM090 '.
       01  ZFAM090-COMMAREA.
           02  CA090-STATUS       PIC  9(03) VALUE ZEROES.
           02  CA090-REASON       PIC  9(02) VALUE ZEROES.
           02  CA090-USERID       PIC  X(08) VALUE SPACES.
           02  CA090-PROGRAM      PIC  X(08) VALUE SPACES.
           02  CA090-FILE         PIC  X(08) VALUE SPACES.
           02  CA090-FIELD        PIC  X(16) VALUE SPACES.

       01  LINKAGE-ADDRESSES.
           02  RECORD-ADDRESS     USAGE POINTER.
           02  RECORD-ADDRESS-X   REDEFINES RECORD-ADDRESS
                                  PIC S9(08) COMP.

           02  FAXXFD-ADDRESS     USAGE POINTER.
           02  FAXXFD-ADDRESS-X   REDEFINES FAXXFD-ADDRESS
                                  PIC S9(08) COMP.

       01  BASE-RECORD-ADDRESS    PIC S9(08) COMP VALUE ZEROES.
       01  BASE-FAXXFD-ADDRESS    PIC S9(08) COMP VALUE ZEROES.

       01  T_LEN                  PIC S9(04) COMP VALUE 8.
       01  T_46                   PIC S9(04) COMP VALUE 46.
       01  T_46_M                 PIC  X(08) VALUE SPACES.
       01  T_RES                  PIC  X(08) VALUE 'ZFAM031 '.

       01  ZFAM-CONTAINER         PIC  X(16) VALUE 'ZFAM-CONTAINER'.
       01  ZFAM-CHANNEL           PIC  X(16) VALUE 'ZFAM-CHANNEL  '.
       01  ZFAM-PROCESS           PIC  X(16) VALUE 'ZFAM-PROCESS  '.
       01  ZFAM-FAXXFD            PIC  X(16) VALUE 'ZFAM-FAXXFD   '.
       01  ZFAM-OLD-REC           PIC  X(16) VALUE 'ZFAM-OLD-REC  '.
       01  ZFAM-NEW-REC           PIC  X(16) VALUE 'ZFAM-NEW-REC  '.
       01  ZFAM-OLD-KEY           PIC  X(16) VALUE 'ZFAM-OLD-KEY  '.
       01  ZFAM-NEW-KEY           PIC  X(16) VALUE 'ZFAM-NEW-KEY  '.

       01  POINTER-LENGTH         PIC S9(08) COMP VALUE ZEROES.
       01  KEY-LENGTH             PIC S9(08) COMP VALUE ZEROES.

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

      *****************************************************************
      * File resources                                                *
      *****************************************************************

       01  CI-FCT.
           02  CI-TRANID          PIC  X(04) VALUE 'FA##'.
           02  FILLER             PIC  X(02) VALUE 'CI'.
           02  CI-INDEX           PIC  9(02) VALUE ZEROES.

       01  CI-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       COPY ZFAMCIC.

      *****************************************************************
      * FAxxFD control fields.                                        *
      *****************************************************************

       01  FAXXFD-LENGTH          PIC S9(08) COMP VALUE ZEROES.
       01  FD-ENTRY-LENGTH        PIC S9(08) COMP VALUE ZEROES.
       01  LEN                    PIC S9(08) COMP VALUE ZEROES.
       01  COL                    PIC S9(08) COMP VALUE ZEROES.

      *****************************************************************
      * Dynamic Storage                                               *
      *****************************************************************
       LINKAGE SECTION.
       01  DFHCOMMAREA            PIC  X(01).

      *****************************************************************
      * FAxxFD.                                                       *
      * zFAM002 retrieves the information from the document template  *
      * and issues a PUT CONTAINER for zFAM031 to process.            *
      *****************************************************************

       01  FD-ENTRY.
           02  FILLER             PIC  X(03).
           02  FD-INDEX           PIC  9(03).
           02  FILLER             PIC  X(05).
           02  FD-COLUMN          PIC  9(07).
           02  FILLER             PIC  X(05).
           02  FD-LENGTH          PIC  9(06).
           02  FILLER             PIC  X(06).
           02  FD-TYPE            PIC  X(01).
           02  FILLER             PIC  X(05).
           02  FD-SEC             PIC  9(02).
           02  FILLER             PIC  X(06).
           02  FD-NAME            PIC  X(16).
           02  FILLER             PIC  X(01).
           02  FD-CRLF            PIC  X(02).

      *****************************************************************
      * zFAM  record.                                                 *
      * This is the complete record as provided by the client request.*
      * The fields in this buffer are referenced using the FD-LENGTH  *
      * and FD-COLUMN.                                                *
      *****************************************************************
       01  ZFAM-RECORD.
           05  ZFAM-DATA          PIC  X(32768).

       PROCEDURE DIVISION.

      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 1000-ACCESS-PARMS       THRU 1000-EXIT.

           IF  PROCESS-TYPE EQUAL 'DELETE'
               PERFORM 2000-GET-OLD-RECORD THRU 2000-EXIT
               PERFORM 3000-PROCESS-FAXXFD THRU 3000-EXIT.

           IF  PROCESS-TYPE EQUAL 'INSERT'
               PERFORM 4000-GET-NEW-RECORD THRU 4000-EXIT
               PERFORM 5000-PROCESS-FAXXFD THRU 5000-EXIT.

           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Access parms.                                                 *
      *****************************************************************
       1000-ACCESS-PARMS.
           EXEC CICS ASSIGN  CHANNEL(ZFAM-CHANNEL) NOHANDLE
           END-EXEC.

           MOVE EIBTRNID(3:2)                TO CI-TRANID(3:2).

           MOVE LENGTH OF PROCESS-TYPE       TO PROCESS-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-PROCESS)
                CHANNEL  (ZFAM-CHANNEL)
                INTO     (PROCESS-TYPE)
                FLENGTH  (PROCESS-LENGTH)
                NOHANDLE
           END-EXEC.
       1000-EXIT.
           EXIT.

      *****************************************************************
      * Issue GET CONTAINER for old record information.               *
      *****************************************************************
       2000-GET-OLD-RECORD.
           MOVE SIXTY-FOUR-KB                TO FAXXFD-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-FAXXFD)
                CHANNEL  (ZFAM-CHANNEL)
                FLENGTH  (FAXXFD-LENGTH)
                SET      (FAXXFD-ADDRESS)
                NOHANDLE
           END-EXEC.

           SET ADDRESS OF FD-ENTRY           TO FAXXFD-ADDRESS.
           MOVE FAXXFD-ADDRESS-X             TO BASE-FAXXFD-ADDRESS.

           MOVE LENGTH OF RECORD-ADDRESS-X   TO POINTER-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-OLD-REC)
                CHANNEL  (ZFAM-CHANNEL)
                INTO     (RECORD-ADDRESS-X)
                FLENGTH  (POINTER-LENGTH)
                NOHANDLE
           END-EXEC.

           SET  ADDRESS OF ZFAM-RECORD       TO RECORD-ADDRESS.
           MOVE RECORD-ADDRESS-X             TO BASE-RECORD-ADDRESS.

           MOVE LENGTH OF OLD-KEY            TO KEY-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-OLD-KEY)
                CHANNEL  (ZFAM-CHANNEL)
                INTO     (OLD-KEY)
                FLENGTH  (KEY-LENGTH)
                NOHANDLE
           END-EXEC.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Process FAxxFD by parsing each entry.  When an Index greater  *
      * than 001 is found, delete a record from the secondary column  *
      * index file (FAxxCI##).                                        *
      *****************************************************************
       3000-PROCESS-FAXXFD.
           PERFORM 3100-PARSE-FAXXFD       THRU 3100-EXIT
               WITH TEST AFTER
               UNTIL FAXXFD-LENGTH EQUAL ZEROES.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Parset FAxxFD entry.  Delete a record from the secondary      *
      * column index file (FAxxCI##) when an index greater than 1     *
      * is found.                                                     *
      *****************************************************************
       3100-PARSE-FAXXFD.
           IF  FD-INDEX GREATER THAN ONE
               PERFORM 3200-DELETE-CI      THRU 3200-EXIT.

           SUBTRACT LENGTH OF FD-ENTRY     FROM FAXXFD-LENGTH.
           ADD      LENGTH OF FD-ENTRY       TO FAXXFD-ADDRESS-X.
           SET ADDRESS OF FD-ENTRY           TO FAXXFD-ADDRESS.

       3100-EXIT.
           EXIT.

      *****************************************************************
      * Issue DELETE for secondary column index file (FAxxCI##).      *
      *****************************************************************
       3200-DELETE-CI.
           MOVE FD-INDEX               TO CI-INDEX.
           MOVE LOW-VALUES             TO CI-KEY.
           MOVE FD-COLUMN              TO COL.
           MOVE FD-LENGTH              TO LEN.
           MOVE ZFAM-DATA(COL:LEN)     TO CI-FIELD(1:LEN).
           MOVE OLD-KEY                TO CI-I-KEY.

           MOVE FD-INDEX(2:2)          TO CI-INDEX.

           EXEC CICS DELETE
                FILE(CI-FCT)
                RIDFLD(CI-KEY)
                NOHANDLE
           END-EXEC.

       3200-EXIT.
           EXIT.

      *****************************************************************
      * Issue GET CONTAINER for new record information.               *
      *****************************************************************
       4000-GET-NEW-RECORD.
           MOVE SIXTY-FOUR-KB                TO FAXXFD-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-FAXXFD)
                CHANNEL  (ZFAM-CHANNEL)
                FLENGTH  (FAXXFD-LENGTH)
                SET      (FAXXFD-ADDRESS)
                NOHANDLE
           END-EXEC.

           SET ADDRESS OF FD-ENTRY           TO FAXXFD-ADDRESS.
           MOVE FAXXFD-ADDRESS-X             TO BASE-FAXXFD-ADDRESS.

           MOVE LENGTH OF RECORD-ADDRESS-X   TO POINTER-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-NEW-REC)
                CHANNEL  (ZFAM-CHANNEL)
                INTO     (RECORD-ADDRESS-X)
                FLENGTH  (POINTER-LENGTH)
                NOHANDLE
           END-EXEC.

           SET  ADDRESS OF ZFAM-RECORD       TO RECORD-ADDRESS.
           MOVE RECORD-ADDRESS-X             TO BASE-RECORD-ADDRESS.

           MOVE LENGTH OF NEW-KEY            TO KEY-LENGTH.

           EXEC CICS GET
                CONTAINER(ZFAM-NEW-KEY)
                CHANNEL  (ZFAM-CHANNEL)
                INTO     (NEW-KEY)
                FLENGTH  (KEY-LENGTH)
                NOHANDLE
           END-EXEC.

       4000-EXIT.
           EXIT.

      *****************************************************************
      * Process FAxxFD by parsing each entry.  When an Index greater  *
      * than 001 is found, write a record to the secondary column     *
      * index file (FAxxCI##).                                        *
      *****************************************************************
       5000-PROCESS-FAXXFD.
           PERFORM 5100-PARSE-FAXXFD       THRU 5100-EXIT
               WITH TEST AFTER
               UNTIL FAXXFD-LENGTH EQUAL ZEROES.

       5000-EXIT.
           EXIT.

      *****************************************************************
      * Parset FAxxFD entry.  Write a record to the secondary column  *
      * index file (FAxxCI##) when an index greater than 1 is found.  *
      *****************************************************************
       5100-PARSE-FAXXFD.
           IF  FD-INDEX GREATER THAN ONE
               PERFORM 5200-WRITE-CI       THRU 5200-EXIT.

           SUBTRACT LENGTH OF FD-ENTRY     FROM FAXXFD-LENGTH.
           ADD      LENGTH OF FD-ENTRY       TO FAXXFD-ADDRESS-X.
           SET ADDRESS OF FD-ENTRY           TO FAXXFD-ADDRESS.

       5100-EXIT.
           EXIT.

      *****************************************************************
      * Issue WRITE to secondary column index file (FAxxCI##).        *
      *****************************************************************
       5200-WRITE-CI.
           MOVE LENGTH OF CI-RECORD    TO CI-LENGTH.
           MOVE FD-INDEX               TO CI-INDEX.
           MOVE LOW-VALUES             TO CI-KEY.
           MOVE FD-COLUMN              TO COL.
           MOVE FD-LENGTH              TO LEN.
           MOVE ZFAM-DATA(COL:LEN)     TO CI-FIELD(1:LEN).
           MOVE NEW-KEY                TO CI-I-KEY.

           MOVE FD-INDEX(2:2)          TO CI-INDEX.

           EXEC CICS WRITE
                FILE(CI-FCT)
                FROM(CI-RECORD)
                RIDFLD(CI-KEY)
                LENGTH(CI-LENGTH)
                NOHANDLE
           END-EXEC.

       5200-EXIT.
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
