      *****************************************************************
      * zFAM KEY  record definition.                                  *
      *****************************************************************
       01  FK-RECORD.
           02  FK-KEY             PIC X(255) VALUE LOW-VALUES.
           02  FK-ECR             PIC  X(01) VALUE LOW-VALUES.
           02  FK-FF-KEY.
               05  FK-FF-IDN      PIC  X(06) VALUE LOW-VALUES.
               05  FK-FF-NC       PIC  X(02) VALUE LOW-VALUES.
           02  FK-OBJECT          PIC  X(04) VALUE SPACES.
           02  FK-DDNAME          PIC  X(04) VALUE SPACES.
           02  FK-UID             PIC  X(32) VALUE SPACES.
           02  FK-ABS             PIC S9(15) VALUE ZEROES COMP-3.
           02  FK-LOCK-TIME       PIC  9(01) VALUE ZEROES.
           02  FK-LOB             PIC  X(01) VALUE SPACES.
           02  FK-SEGMENTS        PIC  9(04) VALUE ZEROES COMP.
           02  FK-RETENTION       PIC S9(07) VALUE ZEROES COMP-3.
           02  FK-RETENTION-TYPE  PIC  X(01) VALUE SPACES.
           02  FILLER             PIC X(191) VALUE SPACES.
