       CBL CICS(SP)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZFAM090.
       AUTHOR.  Rich Jackson and Randy Frerking
      *****************************************************************
      *                                                               *
      * zFAM - z/OS File Access Manager                               *
      *                                                               *
      * This program is called by zFAM programs to display error      *
      * messages and return HTTP status codes/text for unfavorable    *
      * conditions.                                                   *
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
       01  ABS-TIME               PIC S9(15) COMP-3 VALUE 0.
       01  TABLE-INDEX            PIC S9(08) COMP   VALUE 0.
       01  SEND-ACTION            PIC S9(08) COMP   VALUE 0.
       01  TWO                    PIC S9(08) COMP   VALUE 2.

       01  DOCUMENT-LENGTH        PIC S9(08) COMP   VALUE ZEROES.
       01  DOCUMENT-TOKEN         PIC  X(16) VALUE SPACES.

       01  SYSID                  PIC  X(04) VALUE SPACES.
       01  BINARY-ZEROES          PIC  X(01) VALUE LOW-VALUES.
       01  FIVE-ZERO-SEVEN        PIC  9(03) VALUE 507.
       01  FIVE-ZERO-THREE        PIC  9(03) VALUE 503.
       01  FIVE-HUNDRED           PIC  9(03) VALUE 500.
       01  FOUR-TWELVE            PIC  9(03) VALUE 412.
       01  FOUR-ZERO-NINE         PIC  9(03) VALUE 409.
       01  TWO-ZERO-FOUR          PIC  9(03) VALUE 204.
       01  NINES                  PIC  9(03) VALUE 999.
       01  CRLF                   PIC  X(02) VALUE X'0D25'.
       01  STATUS-FOUND           PIC  X(01) VALUE 'N'.
       01  EOT                    PIC  X(01) VALUE 'N'.

       01  HTTP-STATUS            PIC S9(04) COMP VALUE 0.

       01  HTTP-STATUS-TEXT       PIC  X(71) VALUE SPACES.
       01  HTTP-STATUS-LENGTH     PIC S9(08) COMP VALUE 71.

       01  INVOKING-PROGRAM.
           05  FILLER             PIC  X(04) VALUE SPACES.
           05  PROGRAM-SUFFIX     PIC  X(03) VALUE SPACES.
           05  FILLER             PIC  X(01) VALUE SPACES.

       01  UNKNOWN-STATUS.
           05  FILLER             PIC  9(02) VALUE 99.
           05  FILLER             PIC  X(01) VALUE '-'.
           05  UNKNOWN-SUFFIX     PIC  X(03) VALUE SPACES.
           05  FILLER             PIC  X(01) VALUE SPACES.
           05  FILLER             PIC  X(16) VALUE 'Invalid request.'.
           05  FILLER             PIC  X(16) VALUE '  STATUS/REASON '.
           05  FILLER             PIC  X(16) VALUE 'not defined in s'.
           05  FILLER             PIC  X(16) VALUE 'tatus table     '.

       01  CSSL                   PIC  X(04) VALUE '@tdq@'.
       01  TD-LENGTH              PIC S9(04) COMP VALUE ZEROES.

       01  TD-RECORD.
           02  TD-DATE            PIC  X(10).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TIME            PIC  X(08).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-TRANID          PIC  X(04).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-STATUS          PIC  9(03).
           02  FILLER             PIC  X(01) VALUE SPACES.
           02  TD-MESSAGE         PIC  X(71) VALUE SPACES.

       01  TD-KEY-LINE-01.
           02  FILLER             PIC  X(16) VALUE 'Record Key bytes'.
           02  FILLER             PIC  X(09) VALUE '  1- 80: '.
           02  TD-KEY-01          PIC  X(80) VALUE SPACES.

       01  TD-KEY-LINE-02.
           02  FILLER             PIC  X(16) VALUE 'Record Key bytes'.
           02  FILLER             PIC  X(09) VALUE ' 81-160: '.
           02  TD-KEY-02          PIC  X(80) VALUE SPACES.

       01  TD-KEY-LINE-03.
           02  FILLER             PIC  X(16) VALUE 'Record Key bytes'.
           02  FILLER             PIC  X(09) VALUE '161-240: '.
           02  TD-KEY-03          PIC  X(80) VALUE SPACES.

       01  TD-KEY-LINE-04.
           02  FILLER             PIC  X(16) VALUE 'Record Key bytes'.
           02  FILLER             PIC  X(09) VALUE '241-255: '.
           02  TD-KEY-04          PIC  X(15) VALUE SPACES.

       01  TEXT-PLAIN             PIC  X(56) VALUE 'text/plain'.

       01  FILLER.
           02  STATUS-ARRAY.
      *****************************************************************
      * zFAM001 messages                                              *
      *****************************************************************
               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid HTTP met'.
               05  FILLER         PIC  X(16) VALUE 'hod detected dur'.
               05  FILLER         PIC  X(16) VALUE 'ing security aut'.
               05  FILLER         PIC  X(16) VALUE 'horization      '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid HTTP met'.
               05  FILLER         PIC  X(16) VALUE 'hod detected dur'.
               05  FILLER         PIC  X(16) VALUE 'ing Basic Mode F'.
               05  FILLER         PIC  X(16) VALUE 'AxxFD process   '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'WEB RECEIVE comm'.
               05  FILLER         PIC  X(16) VALUE 'and failed.  Thi'.
               05  FILLER         PIC  X(16) VALUE 's error should n'.
               05  FILLER         PIC  X(16) VALUE 'ever occur.     '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid HTTP met'.
               05  FILLER         PIC  X(16) VALUE 'hod detected dur'.
               05  FILLER         PIC  X(16) VALUE 'ing Query Mode p'.
               05  FILLER         PIC  X(16) VALUE 'rocess.         '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid HTTP met'.
               05  FILLER         PIC  X(16) VALUE 'hod detected dur'.
               05  FILLER         PIC  X(16) VALUE 'ing Query Mode s'.
               05  FILLER         PIC  X(16) VALUE 'ecurity process.'.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Query Mode synta'.
               05  FILLER         PIC  X(16) VALUE 'x error while pa'.
               05  FILLER         PIC  X(16) VALUE 'rsing INSERT com'.
               05  FILLER         PIC  X(16) VALUE 'mand.           '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Query Mode synta'.
               05  FILLER         PIC  X(16) VALUE 'x error while pa'.
               05  FILLER         PIC  X(16) VALUE 'rsing SELECT com'.
               05  FILLER         PIC  X(16) VALUE 'mand.           '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  08.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Query Mode synta'.
               05  FILLER         PIC  X(16) VALUE 'x error while pa'.
               05  FILLER         PIC  X(16) VALUE 'rsing UPDATE com'.
               05  FILLER         PIC  X(16) VALUE 'mand.           '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  09.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Query Mode synta'.
               05  FILLER         PIC  X(16) VALUE 'x error while pa'.
               05  FILLER         PIC  X(16) VALUE 'rsing DELETE com'.
               05  FILLER         PIC  X(16) VALUE 'mand.           '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  10.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid query st'.
               05  FILLER         PIC  X(16) VALUE 'ring on POST/PUT'.
               05  FILLER         PIC  X(16) VALUE ' request - DFHCO'.
               05  FILLER         PIC  X(16) VALUE 'MMAREA parser.  '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Basic Authentica'.
               05  FILLER         PIC  X(16) VALUE 'tion credentials'.
               05  FILLER         PIC  X(16) VALUE ' not present in '.
               05  FILLER         PIC  X(16) VALUE 'HTTPS request   '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Basic Authentica'.
               05  FILLER         PIC  X(16) VALUE 'tion credentials'.
               05  FILLER         PIC  X(16) VALUE ' invalid in HTTP'.
               05  FILLER         PIC  X(16) VALUE 'S request       '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'RACF rejected Us'.
               05  FILLER         PIC  X(16) VALUE 'erID/Password pr'.
               05  FILLER         PIC  X(16) VALUE 'ovided in the HT'.
               05  FILLER         PIC  X(16) VALUE 'TPS header      '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTP/GET request'.
               05  FILLER         PIC  X(16) VALUE ' received.  Basi'.
               05  FILLER         PIC  X(16) VALUE 'c Mode Read Only'.
               05  FILLER         PIC  X(16) VALUE ' is disabled    '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTP/PUT, POST, '.
               05  FILLER         PIC  X(16) VALUE 'DELETE not allow'.
               05  FILLER         PIC  X(16) VALUE 'ed in Basic Mode'.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Basic Mode'.
               05  FILLER         PIC  X(16) VALUE '.  UserID not fo'.
               05  FILLER         PIC  X(16) VALUE 'und in FAxxSD se'.
               05  FILLER         PIC  X(16) VALUE 'curity table    '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Basic Mode'.
               05  FILLER         PIC  X(16) VALUE ' POST.    UserID'.
               05  FILLER         PIC  X(16) VALUE ' not allowed WRI'.
               05  FILLER         PIC  X(16) VALUE 'TE  access      '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  08.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Basic Mode'.
               05  FILLER         PIC  X(16) VALUE ' GET.     UserID'.
               05  FILLER         PIC  X(16) VALUE ' not allowed REA'.
               05  FILLER         PIC  X(16) VALUE 'D   access      '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  09.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Basic Mode'.
               05  FILLER         PIC  X(16) VALUE ' PUT.     UserID'.
               05  FILLER         PIC  X(16) VALUE ' not allowed WRI'.
               05  FILLER         PIC  X(16) VALUE 'TE  access      '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  10.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Basic Mode'.
               05  FILLER         PIC  X(16) VALUE ' DELETE.  UserID'.
               05  FILLER         PIC  X(16) VALUE ' not allowed DEL'.
               05  FILLER         PIC  X(16) VALUE 'ETE access      '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  11.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTP/GET request'.
               05  FILLER         PIC  X(16) VALUE ' received.  Quer'.
               05  FILLER         PIC  X(16) VALUE 'y Mode Read Only'.
               05  FILLER         PIC  X(16) VALUE ' is disabled    '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  12.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTP/PUT, POST, '.
               05  FILLER         PIC  X(16) VALUE 'DELETE not allow'.
               05  FILLER         PIC  X(16) VALUE 'ed in Query Mode'.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  13.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Query Mode'.
               05  FILLER         PIC  X(16) VALUE '.  UserID not fo'.
               05  FILLER         PIC  X(16) VALUE 'und in FAxxSD se'.
               05  FILLER         PIC  X(16) VALUE 'curity table    '.

               05  FILLER         PIC  9(03) VALUE 401.
               05  FILLER         PIC  9(02) VALUE  14.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'HTTPS Query Mode'.
               05  FILLER         PIC  X(16) VALUE '.  UserID not au'.
               05  FILLER         PIC  X(16) VALUE 'thorized for req'.
               05  FILLER         PIC  X(16) VALUE 'uested field.   '.

               05  FILLER         PIC  9(03) VALUE 405.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid Query Mo'.
               05  FILLER         PIC  X(16) VALUE 'de command on PO'.
               05  FILLER         PIC  X(16) VALUE 'ST   method.  Mu'.
               05  FILLER         PIC  X(16) VALUE 'st be an INSERT.'.

               05  FILLER         PIC  9(03) VALUE 405.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid Query Mo'.
               05  FILLER         PIC  X(16) VALUE 'de command on GE'.
               05  FILLER         PIC  X(16) VALUE 'T    method.  Mu'.
               05  FILLER         PIC  X(16) VALUE 'st be a  SELECT.'.

               05  FILLER         PIC  9(03) VALUE 405.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid Query Mo'.
               05  FILLER         PIC  X(16) VALUE 'de command on PU'.
               05  FILLER         PIC  X(16) VALUE 'T    method.  Mu'.
               05  FILLER         PIC  X(16) VALUE 'st be an UPDATE.'.

               05  FILLER         PIC  9(03) VALUE 405.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid Query Mo'.
               05  FILLER         PIC  X(16) VALUE 'de command on DE'.
               05  FILLER         PIC  X(16) VALUE 'LETE method.  Mu'.
               05  FILLER         PIC  X(16) VALUE 'st be a  DELETE.'.

               05  FILLER         PIC  9(03) VALUE 405.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Query Mode reque'.
               05  FILLER         PIC  X(16) VALUE 'st failed due to'.
               05  FILLER         PIC  X(16) VALUE ' FAxxFD table no'.
               05  FILLER         PIC  X(16) VALUE 't defined.      '.

               05  FILLER         PIC  9(03) VALUE 411.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Zero length on W'.
               05  FILLER         PIC  X(16) VALUE 'EB RECEIVE comma'.
               05  FILLER         PIC  X(16) VALUE 'nd during PUT/PO'.
               05  FILLER         PIC  X(16) VALUE 'ST process.     '.

               05  FILLER         PIC  9(03) VALUE 412.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxxxxxxxxxx'.
               05  FILLER         PIC  X(16) VALUE ' field not found'.
               05  FILLER         PIC  X(16) VALUE ' while parsing P'.
               05  FILLER         PIC  X(16) VALUE 'OST request.    '.

               05  FILLER         PIC  9(03) VALUE 412.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxxxxxxxxxx'.
               05  FILLER         PIC  X(16) VALUE ' field not found'.
               05  FILLER         PIC  X(16) VALUE ' while parsing G'.
               05  FILLER         PIC  X(16) VALUE 'ET  request.    '.

               05  FILLER         PIC  9(03) VALUE 412.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxxxxxxxxxx'.
               05  FILLER         PIC  X(16) VALUE ' field not found'.
               05  FILLER         PIC  X(16) VALUE ' while parsing P'.
               05  FILLER         PIC  X(16) VALUE 'UT  request.    '.

               05  FILLER         PIC  9(03) VALUE 413.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Maximum RECEIVE '.
               05  FILLER         PIC  X(16) VALUE 'length exceeded '.
               05  FILLER         PIC  X(16) VALUE 'during PUT/POST '.
               05  FILLER         PIC  X(16) VALUE 'process.        '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Query string max'.
               05  FILLER         PIC  X(16) VALUE 'imum length exce'.
               05  FILLER         PIC  X(16) VALUE 'eded.           '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Path maximum len'.
               05  FILLER         PIC  X(16) VALUE 'gth exceeded.   '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Maximum fields ('.
               05  FILLER         PIC  X(16) VALUE '256) exceeded du'.
               05  FILLER         PIC  X(16) VALUE 'ring POST   (INS'.
               05  FILLER         PIC  X(16) VALUE 'ERT) process.   '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Maximum fields ('.
               05  FILLER         PIC  X(16) VALUE '256) exceeded du'.
               05  FILLER         PIC  X(16) VALUE 'ring GET    (SEL'.
               05  FILLER         PIC  X(16) VALUE 'ECT) process.   '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Maximum fields ('.
               05  FILLER         PIC  X(16) VALUE '256) exceeded du'.
               05  FILLER         PIC  X(16) VALUE 'ring GET    (SEL'.
               05  FILLER         PIC  X(16) VALUE 'ECT) process.   '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Maximum fields ('.
               05  FILLER         PIC  X(16) VALUE '256) exceeded du'.
               05  FILLER         PIC  X(16) VALUE 'ring PUT    (UPD'.
               05  FILLER         PIC  X(16) VALUE 'ATE) process.   '.

               05  FILLER         PIC  9(03) VALUE 414.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Maximum fields ('.
               05  FILLER         PIC  X(16) VALUE '256) exceeded du'.
               05  FILLER         PIC  X(16) VALUE 'ring PUT    (UPD'.
               05  FILLER         PIC  X(16) VALUE 'ATE) process.   '.

               05  FILLER         PIC  9(03) VALUE 500.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'pppppppp - Error'.
               05  FILLER         PIC  X(16) VALUE ' when attempting'.
               05  FILLER         PIC  X(16) VALUE ' to XCTL for Bas'.
               05  FILLER         PIC  X(16) VALUE 'ic Mode request.'.

               05  FILLER         PIC  9(03) VALUE 500.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'pppppppp - Error'.
               05  FILLER         PIC  X(16) VALUE ' when attempting'.
               05  FILLER         PIC  X(16) VALUE ' to XCTL for Que'.
               05  FILLER         PIC  X(16) VALUE 'ry Mode request.'.

      *****************************************************************
      * zFAM010 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary Key is n'.
               05  FILLER         PIC  X(16) VALUE 'ot provided and '.
               05  FILLER         PIC  X(16) VALUE 'zFAM-UID header '.
               05  FILLER         PIC  X(16) VALUE 'is not present. '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary Key and '.
               05  FILLER         PIC  X(16) VALUE 'zFAM-UID are pre'.
               05  FILLER         PIC  X(16) VALUE 'sent, but zFAM-C'.
               05  FILLER         PIC  X(16) VALUE 'oncat is omitted'.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary Key and '.
               05  FILLER         PIC  X(16) VALUE 'zFAM-Concat are '.
               05  FILLER         PIC  X(16) VALUE 'present, but zFA'.
               05  FILLER         PIC  X(16) VALUE 'M-UID is omitted'.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'zFAM-UID and zFA'.
               05  FILLER         PIC  X(16) VALUE 'M-Concat are pre'.
               05  FILLER         PIC  X(16) VALUE 'sent, but Primar'.
               05  FILLER         PIC  X(16) VALUE 'y key is omitted'.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary key and '.
               05  FILLER         PIC  X(16) VALUE 'zUID length exce'.
               05  FILLER         PIC  X(16) VALUE 'eds FAxxFD defin'.
               05  FILLER         PIC  X(16) VALUE 'ed key length   '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary key leng'.
               05  FILLER         PIC  X(16) VALUE 'th exceeds FAxxF'.
               05  FILLER         PIC  X(16) VALUE 'D defined key le'.
               05  FILLER         PIC  X(16) VALUE 'ngth            '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'zUID exceeds FAx'.
               05  FILLER         PIC  X(16) VALUE 'xFD defined key '.
               05  FILLER         PIC  X(16) VALUE 'length          '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 409.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Dupli'.
               05  FILLER         PIC  X(16) VALUE 'cate record when'.
               05  FILLER         PIC  X(16) VALUE ' inserting a rec'.
               05  FILLER         PIC  X(16) VALUE 'ord.            '.

               05  FILLER         PIC  9(03) VALUE 409.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Dupli'.
               05  FILLER         PIC  X(16) VALUE 'cate record when'.
               05  FILLER         PIC  X(16) VALUE ' inserting a rec'.
               05  FILLER         PIC  X(16) VALUE 'ord.            '.

               05  FILLER         PIC  9(03) VALUE 412.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxxxxxxxxxx'.
               05  FILLER         PIC  X(16) VALUE ' - field defined'.
               05  FILLER         PIC  X(16) VALUE ' with invalid fi'.
               05  FILLER         PIC  X(16) VALUE 'eld type.       '.


               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - File '.
               05  FILLER         PIC  X(16) VALUE 'is disabled.  IN'.
               05  FILLER         PIC  X(16) VALUE 'SERT request fai'.
               05  FILLER         PIC  X(16) VALUE 'led.            '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - File '.
               05  FILLER         PIC  X(16) VALUE 'is not defined/f'.
               05  FILLER         PIC  X(16) VALUE 'ound.  INSERT re'.
               05  FILLER         PIC  X(16) VALUE 'quest failed.   '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - NOSPA'.
               05  FILLER         PIC  X(16) VALUE 'CE in file.  INS'.
               05  FILLER         PIC  X(16) VALUE 'ERT request fail'.
               05  FILLER         PIC  X(16) VALUE 'ed.             '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - NOTOP'.
               05  FILLER         PIC  X(16) VALUE 'EN condition.  I'.
               05  FILLER         PIC  X(16) VALUE 'NSERT request fa'.
               05  FILLER         PIC  X(16) VALUE 'iled            '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '010'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - INSER'.
               05  FILLER         PIC  X(16) VALUE 'T request failed'.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

      *****************************************************************
      * zFAM020 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '020'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '020'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '020'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found whil'.
               05  FILLER         PIC  X(16) VALUE 'e processing spa'.
               05  FILLER         PIC  X(16) VALUE 'nned segments   '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '020'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Error'.
               05  FILLER         PIC  X(16) VALUE ' on segment arra'.
               05  FILLER         PIC  X(16) VALUE 'y scan.  This sh'.
               05  FILLER         PIC  X(16) VALUE 'ould not happen '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '020'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found whil'.
               05  FILLER         PIC  X(16) VALUE 'e accessing zQL '.
               05  FILLER         PIC  X(16) VALUE 'SELECT fields   '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '020'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary key not '.
               05  FILLER         PIC  X(16) VALUE ' present in WHER'.
               05  FILLER         PIC  X(16) VALUE 'E statement on S'.
               05  FILLER         PIC  X(16) VALUE 'ELECT command.  '.

      *****************************************************************
      * zFAM030 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '030'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary key not '.
               05  FILLER         PIC  X(16) VALUE 'provided on zQL '.
               05  FILLER         PIC  X(16) VALUE 'UPDATE (PUT).  N'.
               05  FILLER         PIC  X(16) VALUE 'o can do.       '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '030'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '030'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '030'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Error'.
               05  FILLER         PIC  X(16) VALUE ' on segment arra'.
               05  FILLER         PIC  X(16) VALUE 'y scan.  This sh'.
               05  FILLER         PIC  X(16) VALUE 'ould not happen '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '030'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found whil'.
               05  FILLER         PIC  X(16) VALUE 'e accessing zQL '.
               05  FILLER         PIC  X(16) VALUE 'UPDATE fields   '.

      *****************************************************************
      * zFAM040 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '040'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Primary key not '.
               05  FILLER         PIC  X(16) VALUE 'provided on zQL '.
               05  FILLER         PIC  X(16) VALUE 'DELETE.  Too bad'.
               05  FILLER         PIC  X(16) VALUE '.  So sad.      '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '040'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex key store   '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '040'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex file store  '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '040'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Segme'.
               05  FILLER         PIC  X(16) VALUE 'nt not found on '.
               05  FILLER         PIC  X(16) VALUE 'Primary Column I'.
               05  FILLER         PIC  X(16) VALUE 'ndex file store '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '040'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Segme'.
               05  FILLER         PIC  X(16) VALUE 'nt not found on '.
               05  FILLER         PIC  X(16) VALUE 'Primary Column I'.
               05  FILLER         PIC  X(16) VALUE 'ndex file store '.

      *****************************************************************
      * zFAM021 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on S'.
               05  FILLER         PIC  X(16) VALUE 'econdary Column '.
               05  FILLER         PIC  X(16) VALUE 'Index           '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Error'.
               05  FILLER         PIC  X(16) VALUE ' on Segment Arra'.
               05  FILLER         PIC  X(16) VALUE 'y Scan.  This sh'.
               05  FILLER         PIC  X(16) VALUE 'ould not happen '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Error'.
               05  FILLER         PIC  X(16) VALUE ' on Segment Arra'.
               05  FILLER         PIC  X(16) VALUE 'y Reset.  This s'.
               05  FILLER         PIC  X(16) VALUE 'hould not happen'.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  08.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - No re'.
               05  FILLER         PIC  X(16) VALUE 'cords found on S'.
               05  FILLER         PIC  X(16) VALUE 'econdary Column '.
               05  FILLER         PIC  X(16) VALUE 'Index request   '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - START'.
               05  FILLER         PIC  X(16) VALUE 'BR error on Seco'.
               05  FILLER         PIC  X(16) VALUE 'ndary Column Ind'.
               05  FILLER         PIC  X(16) VALUE 'ex              '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - READN'.
               05  FILLER         PIC  X(16) VALUE 'EXT error on Sec'.
               05  FILLER         PIC  X(16) VALUE 'ondary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - error'.
               05  FILLER         PIC  X(16) VALUE ' on Primary file'.
               05  FILLER         PIC  X(16) VALUE ' store          '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Colum'.
               05  FILLER         PIC  X(16) VALUE 'n Index file not'.
               05  FILLER         PIC  X(16) VALUE ' found in Parser'.
               05  FILLER         PIC  X(16) VALUE ' Array          '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '021'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Secon'.
               05  FILLER         PIC  X(16) VALUE 'dary Column Inde'.
               05  FILLER         PIC  X(16) VALUE 'x not found in C'.
               05  FILLER         PIC  X(16) VALUE 'I Array         '.

      *****************************************************************
      * zFAM022 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on S'.
               05  FILLER         PIC  X(16) VALUE 'econdary Column '.
               05  FILLER         PIC  X(16) VALUE 'Index           '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found on P'.
               05  FILLER         PIC  X(16) VALUE 'rimary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Error'.
               05  FILLER         PIC  X(16) VALUE ' on Segment Arra'.
               05  FILLER         PIC  X(16) VALUE 'y Scan.  This sh'.
               05  FILLER         PIC  X(16) VALUE 'ould not happen '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Error'.
               05  FILLER         PIC  X(16) VALUE ' on Segment Arra'.
               05  FILLER         PIC  X(16) VALUE 'y Reset.  This s'.
               05  FILLER         PIC  X(16) VALUE 'hould not happen'.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  08.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - No re'.
               05  FILLER         PIC  X(16) VALUE 'cords found on S'.
               05  FILLER         PIC  X(16) VALUE 'econdary Column '.
               05  FILLER         PIC  X(16) VALUE 'Index request   '.

               05  FILLER         PIC  9(03) VALUE 412.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxxxxxxxxxx'.
               05  FILLER         PIC  X(16) VALUE ' - filter field '.
               05  FILLER         PIC  X(16) VALUE 'exceeds 256 maxi'.
               05  FILLER         PIC  X(16) VALUE 'mum length      '.

               05  FILLER         PIC  9(03) VALUE 412.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxxxxxxxxxx'.
               05  FILLER         PIC  X(16) VALUE ' - Secondary CI '.
               05  FILLER         PIC  X(16) VALUE 'exceeds  56 maxi'.
               05  FILLER         PIC  X(16) VALUE 'mum length      '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - START'.
               05  FILLER         PIC  X(16) VALUE 'BR error on Seco'.
               05  FILLER         PIC  X(16) VALUE 'ndary Column Ind'.
               05  FILLER         PIC  X(16) VALUE 'ex              '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - READN'.
               05  FILLER         PIC  X(16) VALUE 'EXT error on Sec'.
               05  FILLER         PIC  X(16) VALUE 'ondary Column In'.
               05  FILLER         PIC  X(16) VALUE 'dex             '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - error'.
               05  FILLER         PIC  X(16) VALUE ' on Primary file'.
               05  FILLER         PIC  X(16) VALUE ' store          '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Colum'.
               05  FILLER         PIC  X(16) VALUE 'n Index file not'.
               05  FILLER         PIC  X(16) VALUE ' found in Parser'.
               05  FILLER         PIC  X(16) VALUE ' Array          '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '022'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - Secon'.
               05  FILLER         PIC  X(16) VALUE 'dary Column Inde'.
               05  FILLER         PIC  X(16) VALUE 'x not found in C'.
               05  FILLER         PIC  X(16) VALUE 'I Array         '.

      *****************************************************************
      * zFAM002 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'WEB RECEIVE erro'.
               05  FILLER         PIC  X(16) VALUE 'r               '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Invalid URI form'.
               05  FILLER         PIC  X(16) VALUE 'at.  Must have s'.
               05  FILLER         PIC  X(16) VALUE 'even slashes.   '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'URI Key exceeds '.
               05  FILLER         PIC  X(16) VALUE '255 byte maximum'.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'URI Key missing '.
               05  FILLER         PIC  X(16) VALUE 'on GET request  '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'URI Key missing '.
               05  FILLER         PIC  X(16) VALUE 'on PUT request  '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'URI Key missing '.
               05  FILLER         PIC  X(16) VALUE 'on DELETE reques'.
               05  FILLER         PIC  X(16) VALUE 't               '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'URI Key missing '.
               05  FILLER         PIC  X(16) VALUE 'on POST   reques'.
               05  FILLER         PIC  X(16) VALUE 't               '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  08.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'DEFINE Named Cou'.
               05  FILLER         PIC  X(16) VALUE 'nter for zFAM Mo'.
               05  FILLER         PIC  X(16) VALUE 'dulo failed.    '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  09.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'zFAM task abende'.
               05  FILLER         PIC  X(16) VALUE 'd during I/O pro'.
               05  FILLER         PIC  X(16) VALUE 'cessing         '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  10.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'zFAM-RangeBegin '.
               05  FILLER         PIC  X(16) VALUE 'or zFAM-RangeEnd'.
               05  FILLER         PIC  X(16) VALUE ' specified for D'.
               05  FILLER         PIC  X(16) VALUE 'ELETE request.  '.

               05  FILLER         PIC  9(03) VALUE 400.
               05  FILLER         PIC  9(02) VALUE  11.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'zFAM-RangeBegin '.
               05  FILLER         PIC  X(16) VALUE 'is less than zFA'.
               05  FILLER         PIC  X(16) VALUE 'M-RangeEnd for D'.
               05  FILLER         PIC  X(16) VALUE 'ELETE request.  '.

               05  FILLER         PIC  9(03) VALUE 411.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'WEB RECEIVE leng'.
               05  FILLER         PIC  X(16) VALUE 'th is zero, inva'.
               05  FILLER         PIC  X(16) VALUE 'lid for PUT/POST'.
               05  FILLER         PIC  X(16) VALUE ' request.       '.

               05  FILLER         PIC  9(03) VALUE 413.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'WEB RECEIVE exce'.
               05  FILLER         PIC  X(16) VALUE 'eded 3.2MB limit'.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 413.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'LOB Append excee'.
               05  FILLER         PIC  X(16) VALUE 'ds the 2GB limit'.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD Primary key '.
               05  FILLER         PIC  X(16) VALUE 'error           '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD references a'.
               05  FILLER         PIC  X(16) VALUE 'n invalid key on'.
               05  FILLER         PIC  X(16) VALUE ' FAxxFILE       '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD internal key'.
               05  FILLER         PIC  X(16) VALUE ' error          '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD internal key'.
               05  FILLER         PIC  X(16) VALUE ' error          '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  05.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - POST/'.
               05  FILLER         PIC  X(16) VALUE 'WRITE primary ke'.
               05  FILLER         PIC  X(16) VALUE 'y error         '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  06.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - POST/'.
               05  FILLER         PIC  X(16) VALUE 'WRITE internal k'.
               05  FILLER         PIC  X(16) VALUE 'ey error        '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  07.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD UPDATE Prima'.
               05  FILLER         PIC  X(16) VALUE 'ry key error    '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  08.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT/R'.
               05  FILLER         PIC  X(16) VALUE 'EWRITE Primary k'.
               05  FILLER         PIC  X(16) VALUE 'ey error        '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  09.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT/W'.
               05  FILLER         PIC  X(16) VALUE 'RITE internal ke'.
               05  FILLER         PIC  X(16) VALUE 'y error         '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  10.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD  internal ke'.
               05  FILLER         PIC  X(16) VALUE 'y error         '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  11.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT/R'.
               05  FILLER         PIC  X(16) VALUE 'EAD Primary key '.
               05  FILLER         PIC  X(16) VALUE 'error during LOB'.
               05  FILLER         PIC  X(16) VALUE ' Append.        '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  12.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT/R'.
               05  FILLER         PIC  X(16) VALUE 'EWRITE Primary k'.
               05  FILLER         PIC  X(16) VALUE 'ey error during '.
               05  FILLER         PIC  X(16) VALUE 'LOB Append.     '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  13.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT/W'.
               05  FILLER         PIC  X(16) VALUE 'RITE Primary key'.
               05  FILLER         PIC  X(16) VALUE ' error during LO'.
               05  FILLER         PIC  X(16) VALUE 'B Append.       '.

               05  FILLER         PIC  9(03) VALUE 409.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET r'.
               05  FILLER         PIC  X(16) VALUE 'ow-level lock fa'.
               05  FILLER         PIC  X(16) VALUE 'iled.  Record al'.
               05  FILLER         PIC  X(16) VALUE 'ready locked    '.

               05  FILLER         PIC  9(03) VALUE 409.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - POST/'.
               05  FILLER         PIC  X(16) VALUE 'WRITE duplicate '.
               05  FILLER         PIC  X(16) VALUE 'record for prima'.
               05  FILLER         PIC  X(16) VALUE 'ry key          '.

               05  FILLER         PIC  9(03) VALUE 409.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT r'.
               05  FILLER         PIC  X(16) VALUE 'ejected.  Reques'.
               05  FILLER         PIC  X(16) VALUE 'ted Lock ID not '.
               05  FILLER         PIC  X(16) VALUE 'active          '.

               05  FILLER         PIC  9(03) VALUE 409.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT r'.
               05  FILLER         PIC  X(16) VALUE 'ejected.  The ke'.
               05  FILLER         PIC  X(16) VALUE 'y is an Event Co'.
               05  FILLER         PIC  X(16) VALUE 'ntrol Record    '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - GET P'.
               05  FILLER         PIC  X(16) VALUE 'rimary key recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found     '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - DELET'.
               05  FILLER         PIC  X(16) VALUE 'E Primary key re'.
               05  FILLER         PIC  X(16) VALUE 'cord not found  '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  03.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT P'.
               05  FILLER         PIC  X(16) VALUE 'rimary key recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found     '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 204.
               05  FILLER         PIC  9(02) VALUE  04.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '002'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'xxxxxxxx - PUT P'.
               05  FILLER         PIC  X(16) VALUE 'rimary key recor'.
               05  FILLER         PIC  X(16) VALUE 'd not found duri'.
               05  FILLER         PIC  X(16) VALUE 'ng LOB Append.  '.

      *****************************************************************
      * zFAM003 messages                                              *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  01.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '003'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'STARTBR I/O erro'.
               05  FILLER         PIC  X(16) VALUE 'r               '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

               05  FILLER         PIC  9(03) VALUE 507.
               05  FILLER         PIC  9(02) VALUE  02.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '003'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'READNEXT I/O err'.
               05  FILLER         PIC  X(16) VALUE 'or              '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

      *****************************************************************
      * This must be the last entry in the table.                     *
      *****************************************************************

               05  FILLER         PIC  9(03) VALUE 999.
               05  FILLER         PIC  9(02) VALUE  99.
               05  FILLER         PIC  X(01) VALUE '-'.
               05  FILLER         PIC  X(03) VALUE '001'.
               05  FILLER         PIC  X(01) VALUE SPACE.
               05  FILLER         PIC  X(16) VALUE 'Last entry in th'.
               05  FILLER         PIC  X(16) VALUE 'e STATUS-TABLE. '.
               05  FILLER         PIC  X(16) VALUE '                '.
               05  FILLER         PIC  X(16) VALUE '                '.

           02  STATUS-TABLE REDEFINES STATUS-ARRAY OCCURS 140 TIMES.
               05  STATUS-CODE    PIC  9(03).
               05  STATUS-MESSAGE.
                10 REASON-CODE    PIC  9(02).
                10 FILLER         PIC  X(01).
                10 PROGRAM-NUMBER PIC  X(03).
                10 FILLER         PIC  X(01).
                10 STATUS-TEXT.
                 15 PROGRAM-NAME  PIC  X(08).
                 15 FILLER        PIC  X(56).
                10 FILLER REDEFINES STATUS-TEXT.
                 15 FIELD-NAME    PIC  X(16).
                 15 FILLER        PIC  X(48).
                10 FILLER REDEFINES STATUS-TEXT.
                 15 FILE-NAME     PIC  X(08).
                 15 FILLER        PIC  X(56).
                10 FILLER REDEFINES STATUS-TEXT.
                 15 FILLER        PIC  X(56).
                 15 DS-NAME       PIC  X(08).

      *****************************************************************
      * Dynamic Storage                                               *
      *****************************************************************
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           02  CA-STATUS          PIC  9(03).
           02  CA-REASON          PIC  9(02).
           02  CA-USERID          PIC  X(08).
           02  CA-PROGRAM         PIC  X(08).
           02  CA-FILE            PIC  X(08).
           02  CA-FIELD           PIC  X(16).
           02  CA-KEY             PIC X(255).

       PROCEDURE DIVISION.
      *****************************************************************
      * Main process.                                                 *
      *****************************************************************
           PERFORM 0000-INITIALIZE         THRU 0000-EXIT.
           PERFORM 1000-SEARCH-TABLE       THRU 1000-EXIT.
           PERFORM 2000-LOG-MESSAGE        THRU 2000-EXIT.
           PERFORM 3000-SEND-RESPONSE      THRU 3000-EXIT.
           PERFORM 9000-RETURN             THRU 9000-EXIT.

      *****************************************************************
      * Assign INVOKINGPROGRAM, which is used to determine which      *
      * status/reason code to display.                                *
      *****************************************************************
       0000-INITIALIZE.
           EXEC CICS ASSIGN INVOKINGPROG(INVOKING-PROGRAM)
               NOHANDLE
           END-EXEC.

       0000-EXIT.
           EXIT.

      *****************************************************************
      * Search table for matching status code and reason code         *
      *****************************************************************
       1000-SEARCH-TABLE.
           PERFORM 1100-SEARCH-TABLE   THRU 1100-EXIT
               WITH TEST AFTER
               VARYING TABLE-INDEX     FROM 1 BY 1
               UNTIL STATUS-FOUND = 'Y'
                  OR EOT          = 'Y'.

       1000-EXIT.
           EXIT.

      *****************************************************************
      * Set indicator when status code match or EOT.                  *
      *****************************************************************
       1100-SEARCH-TABLE.
           IF  STATUS-CODE(TABLE-INDEX)  EQUAL FIVE-HUNDRED
               MOVE CA-PROGRAM           TO PROGRAM-NAME(TABLE-INDEX).

           IF  STATUS-CODE(TABLE-INDEX)  EQUAL FOUR-TWELVE
               MOVE CA-FIELD             TO FIELD-NAME(TABLE-INDEX).

           IF  STATUS-CODE(TABLE-INDEX)  EQUAL FIVE-ZERO-SEVEN
               MOVE CA-FILE              TO FILE-NAME(TABLE-INDEX).

           IF  STATUS-CODE(TABLE-INDEX)  EQUAL FOUR-ZERO-NINE
               MOVE CA-FILE              TO FILE-NAME(TABLE-INDEX).

           IF  STATUS-CODE(TABLE-INDEX)  EQUAL TWO-ZERO-FOUR
               MOVE CA-FILE              TO FILE-NAME(TABLE-INDEX).

           IF  STATUS-CODE        (TABLE-INDEX) EQUAL CA-STATUS
           AND REASON-CODE        (TABLE-INDEX) EQUAL CA-REASON
           AND PROGRAM-NUMBER     (TABLE-INDEX) EQUAL PROGRAM-SUFFIX
               MOVE STATUS-MESSAGE(TABLE-INDEX) TO HTTP-STATUS-TEXT
               MOVE STATUS-CODE   (TABLE-INDEX) TO HTTP-STATUS
               MOVE 'Y'                         TO STATUS-FOUND.

           IF  STATUS-CODE(TABLE-INDEX)  EQUAL NINES
               MOVE PROGRAM-SUFFIX          TO UNKNOWN-SUFFIX
               MOVE UNKNOWN-STATUS          TO HTTP-STATUS-TEXT
               MOVE NINES                   TO HTTP-STATUS
               MOVE 'Y'                     TO EOT.

       1100-EXIT.
           EXIT.


      *****************************************************************
      * Log the message.                                              *
      *****************************************************************
       2000-LOG-MESSAGE.
           EXEC CICS ASKTIME ABSTIME(ABS-TIME) NOHANDLE
           END-EXEC.

           MOVE HTTP-STATUS               TO TD-STATUS.
           MOVE HTTP-STATUS-TEXT          TO TD-MESSAGE.
           MOVE EIBTRNID                  TO TD-TRANID.

           EXEC CICS FORMATTIME ABSTIME(ABS-TIME)
                TIME(TD-TIME)
                YYYYMMDD(TD-DATE)
                TIMESEP
                DATESEP
                NOHANDLE
           END-EXEC.

           MOVE LENGTH OF TD-RECORD       TO TD-LENGTH.
           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM(TD-RECORD)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

       2000-EXIT.
           EXIT.

      *****************************************************************
      * Send HTTP STATUSCODE and STATUSTEXT.                          *
      *****************************************************************
       3000-SEND-RESPONSE.
           MOVE DFHVALUE(IMMEDIATE)       TO SEND-ACTION.

           IF  STATUS-CODE(TABLE-INDEX) EQUAL TWO-ZERO-FOUR
               PERFORM 3204-SEND        THRU 3204-EXIT
           ELSE
               PERFORM 3999-SEND        THRU 3999-EXIT.

       3000-EXIT.
           EXIT.

      *****************************************************************
      * Send HTTP STATUSCODE and STATUSTEXT (204 status only)         *
      *****************************************************************
       3204-SEND.
           MOVE CA-KEY(1:80)              TO TD-KEY-01.

           MOVE LENGTH OF TD-KEY-LINE-01  TO TD-LENGTH.
           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM  (TD-KEY-LINE-01)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE CA-KEY(81:80)             TO TD-KEY-02.

           MOVE LENGTH OF TD-KEY-LINE-02  TO TD-LENGTH.
           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM  (TD-KEY-LINE-02)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE CA-KEY(161:80)            TO TD-KEY-03.

           MOVE LENGTH OF TD-KEY-LINE-03  TO TD-LENGTH.
           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM  (TD-KEY-LINE-03)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

           MOVE CA-KEY(241:15)            TO TD-KEY-04.

           MOVE LENGTH OF TD-KEY-LINE-04  TO TD-LENGTH.
           EXEC CICS WRITEQ TD QUEUE(CSSL)
                FROM  (TD-KEY-LINE-04)
                LENGTH(TD-LENGTH)
                NOHANDLE
           END-EXEC.

           EXEC CICS DOCUMENT CREATE DOCTOKEN(DOCUMENT-TOKEN)
                NOHANDLE
           END-EXEC.

           EXEC CICS WEB SEND
                DOCTOKEN  (DOCUMENT-TOKEN)
                ACTION    (SEND-ACTION)
                MEDIATYPE (TEXT-PLAIN)
                STATUSCODE(HTTP-STATUS)
                STATUSTEXT(HTTP-STATUS-TEXT)
                STATUSLEN (HTTP-STATUS-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       3204-EXIT.
           EXIT.

      *****************************************************************
      * Send HTTP STATUSCODE and STATUSTEXT (All non-204 status)      *
      *****************************************************************
       3999-SEND.
           EXEC CICS WEB SEND
                FROM      (CRLF)
                FROMLENGTH(TWO)
                ACTION    (SEND-ACTION)
                MEDIATYPE (TEXT-PLAIN)
                STATUSCODE(HTTP-STATUS)
                STATUSTEXT(HTTP-STATUS-TEXT)
                STATUSLEN (HTTP-STATUS-LENGTH)
                SRVCONVERT
                NOHANDLE
           END-EXEC.

       3999-EXIT.
           EXIT.

      *****************************************************************
      * RETURN to CICS                                                *
      *****************************************************************
       9000-RETURN.
           EXEC CICS RETURN
           END-EXEC.

       9000-EXIT.
           EXIT.