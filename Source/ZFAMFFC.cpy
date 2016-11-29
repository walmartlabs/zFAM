      *****************************************************************
      * zFAM FILE record definition.                                  *
      *****************************************************************
       01  FF-PREFIX              PIC S9(08) VALUE 356    COMP.

       01  FF-RECORD.
           02  FF-KEY-16.
               05  FF-KEY.
                 10  FF-KEY-IDN   PIC  X(06) VALUE LOW-VALUES.
                 10  FF-KEY-NC    PIC  X(02) VALUE LOW-VALUES.
               05  FF-SEGMENT     PIC  9(04) VALUE ZEROES COMP.
               05  FF-SUFFIX      PIC  9(04) VALUE ZEROES COMP.
               05  FF-ZEROES      PIC  9(08) VALUE ZEROES COMP.
           02  FF-ABS             PIC S9(15) VALUE ZEROES COMP-3.
           02  FF-RETENTION       PIC S9(07) VALUE ZEROES COMP-3.
           02  FF-SEGMENTS        PIC  9(04) VALUE ZEROES COMP.
           02  FF-RETENTION-TYPE  PIC  X(01).
           02  FF-EXTRA           PIC  X(14).
           02  FF-FK-KEY          PIC  X(255).
           02  FF-MEDIA           PIC  X(56).
           02  FF-DATA            PIC  X(32000).
           02  FILLER             PIC  X(344).
