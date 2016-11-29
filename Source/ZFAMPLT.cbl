       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAMPLT.
       AUTHOR.     Rich Jackson and Randy Frerking
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager                               *
      *                                                               *
      * This program executes in the PLT and performs the following:  *
      *                                                               *
      * 1).  Browse URIMAP                                            *
      * 2).  Issue START for the zFAM expiration task (FX##) for      *
      *      each zFAM URIMAP.                                        *
      * 3).  Issue WTO for each START command.                        *
      *                                                               *
      * Date       UserID    Description                              *
      * ---------- --------  ---------------------------------------- *
      *                                                               *
      *****************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *****************************************************************
      * Define Constant and Define Storage.                           *
      *****************************************************************

       01  ST-CODE                PIC  X(02) VALUE SPACES.
       01  EOF                    PIC  X(01) VALUE SPACES.
       01  FA                     PIC  X(02) VALUE 'FA'.

       01  URI-MAP.
           02  URI-PREFIX         PIC  X(04) VALUE SPACES.
           02  URI-SUFFIX         PIC  X(04) VALUE SPACES.

       01  URI-TRAN               PIC  X(04) VALUE SPACES.

       01  FX-TRANID.
           02  FILLER             PIC  X(02) VALUE 'FX'.
           02  FX-SUFFIX          PIC  X(02) VALUE SPACES.

       01  CSSL                   PIC  X(04) VALUE '@tdq@'.
       01  TD-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       01  TD-RECORD.
           02  FILLER             PIC  X(13) VALUE 'zFAM start FX'.
           02  TD-SUFFIX          PIC  X(02) VALUE SPACES.
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  FILLER             PIC  X(04) VALUE 'for '.
           02  TD-TRAN            PIC  X(04) VALUE SPACES.
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-PATH            PIC  X(80) VALUE SPACES.

       01  URI-PATH               PIC X(256) VALUE SPACES.


       LINKAGE SECTION.
       01  DFHCOMMAREA            PIC  X(01).

       PROCEDURE DIVISION.

      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 1000-INQUIRE-START      THRU 1000-EXIT.
           PERFORM 2000-INQUIRE-NEXT       THRU 2000-EXIT
                   WITH TEST AFTER
                   UNTIL EOF EQUAL 'Y'.
           PERFORM 3000-INQUIRE-END        THRU 3000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Inquire URIMAP START.                                         *
      *****************************************************************
       1000-INQUIRE-START.
           EXEC CICS INQUIRE URIMAP START
                NOHANDLE
           END-EXEC.

       1000-EXIT.
           EXIT.

      *****************************************************************
      * Inquire URIMAP NEXT.                                          *
      *****************************************************************
       2000-INQUIRE-NEXT.
           EXEC CICS INQUIRE URIMAP(URI-MAP)
                PATH(URI-PATH)
                TRANSACTION(URI-TRAN)
                NEXT
                NOHANDLE
           END-EXEC.

           IF  EIBRESP NOT EQUAL DFHRESP(NORMAL)
               MOVE 'Y'    TO EOF.

           IF  EIBRESP     EQUAL DFHRESP(NORMAL)
               PERFORM 2100-CHECK-URIMAP   THRU 2100-EXIT.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Check URIMAP for FA* entries                                  *
      *****************************************************************
       2100-CHECK-URIMAP.
           IF  URI-PREFIX(1:2) EQUAL FA      AND
               URI-SUFFIX      EQUAL SPACES
               PERFORM 2200-START          THRU 2200-EXIT.

       2100-EXIT.
           EXIT.

      *****************************************************************
      * Issue START command for exipiration process.                  *
      * Issue WRITEQ TD QUEUE(CSSL)                                   *
      * Issue WTO                                                     *
      *****************************************************************
       2200-START.
           MOVE URI-PREFIX(3:2)       TO FX-SUFFIX
                                         TD-SUFFIX.

           MOVE LENGTH OF TD-RECORD   TO TD-LENGTH.

           EXEC CICS START TRANSID(FX-TRANID)
                FROM(URI-TRAN)
                LENGTH(4)
                NOHANDLE
           END-EXEC.

           MOVE URI-TRAN              TO TD-TRAN.
           MOVE URI-PATH              TO TD-PATH.

           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM  (TD-RECORD)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

           EXEC CICS WRITE OPERATOR
                TEXT(TD-RECORD)
                NOHANDLE
           END-EXEC.

       2200-EXIT.
           EXIT.

      *****************************************************************
      * Inquire URIMAP END.                                           *
      *****************************************************************
       3000-INQUIRE-END.
           EXEC CICS INQUIRE URIMAP END
                NOHANDLE
           END-EXEC.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Return to CICS                                                *
      *****************************************************************
       9000-RETURN.

           EXEC CICS RETURN
           END-EXEC.

       9000-EXIT.
           EXIT.
