      *****************************************************************
      * Start FAxxCIxx - Secondary Column Index record                *
      *****************************************************************
       01  CI-RECORD.
           02  CI-KEY.
             05  CI-FIELD         PIC  X(56) VALUE LOW-VALUES.
             05  CI-I-KEY.
               10  CI-ID          PIC  X(06) VALUE LOW-VALUES.
               10  CI-NC          PIC  X(02) VALUE LOW-VALUES.
           02  CI-DS              PIC  X(04) VALUE 'FILE'.

      *****************************************************************
      * End   FAxxCIxx - Secondary Column Index record                *
      *****************************************************************