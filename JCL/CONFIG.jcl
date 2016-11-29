//CONFIG   JOB MSGCLASS=R,NOTIFY=&SYSUID
//**********************************************************************
//* This job will modify the members in the .SOURCE and .CNTL libraries
//*
//* Steps for this job to complete successfully
//* --------------------------------------------------------------------
//* 1) Modify JOB card to meet your system installation standards
//*
//* 2) Modify the CONFIG member in the .SOURCE dataset before submitting
//*
//* 3) Change all occurrences of the following:
//*    @source_lib@ to the source library dataset name
//*    @jcl_lib@    to this JCL library dataset name.
//*
//* 4) Submit the job
//**********************************************************************
//* Modify ASMZFAM JCL
//**********************************************************************
//STEP001  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(ASMZFAM)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ASMZFAM JCL
//**********************************************************************
//STEP002   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(ASMZFAM)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAM JCL
//**********************************************************************
//STEP003  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAM)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAM JCL
//**********************************************************************
//STEP004   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAM)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMN JCL
//**********************************************************************
//STEP005  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAMN)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMN JCL
//**********************************************************************
//STEP006   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAMN)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMR JCL
//**********************************************************************
//STEP007  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAMR)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMR JCL
//**********************************************************************
//STEP008   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAMR)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMS JCL
//**********************************************************************
//STEP009  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAMS)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMS JCL
//**********************************************************************
//STEP010   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(CSDZFAMS)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify DEFCI JCL
//**********************************************************************
//STEP011  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(DEFCI)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace DEFCI JCL
//**********************************************************************
//STEP012   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(DEFCI)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify DEFEXPR JCL
//**********************************************************************
//STEP013  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(DEFEXPR)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace DEFEXPR JCL
//**********************************************************************
//STEP014   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(DEFEXPR)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify DEFFA## JCL
//**********************************************************************
//STEP015  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(DEFFA##)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace DEFFA## JCL
//**********************************************************************
//STEP016   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(DEFFA##)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify FA##DC JCL
//**********************************************************************
//STEP017  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(FA##DC)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace FA##DC  JCL
//**********************************************************************
//STEP018   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(FA##DC)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify FA##FD JCL
//**********************************************************************
//STEP019  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(FA##FD)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace FA##FD  JCL
//**********************************************************************
//STEP020   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(FA##FD)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify FA##SD JCL
//**********************************************************************
//STEP021  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@jcl_lib@(FA##SD)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace FA##SD  JCL
//**********************************************************************
//STEP022   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@jcl_lib@(FA##SD)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDFA## CSD definition source
//**********************************************************************
//STEP023  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDFA##)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDFA## CSD definition source
//**********************************************************************
//STEP024   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDFA##)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAM CSD definition source
//**********************************************************************
//STEP025  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAM)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAM CSD definition source
//**********************************************************************
//STEP026   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDZFAM)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMC CSD definition source
//**********************************************************************
//STEP027  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMC)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMC CSD definition source
//**********************************************************************
//STEP028   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDZFAMC)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMN CSD definition source
//**********************************************************************
//STEP029  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMN)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMN CSD definition source
//**********************************************************************
//STEP030   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDZFAMN)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMR CSD definition source
//**********************************************************************
//STEP031  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMR)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMR CSD definition source
//**********************************************************************
//STEP032   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDZFAMR)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMS CSD definition source
//**********************************************************************
//STEP033  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMS)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMS CSD definition source
//**********************************************************************
//STEP034   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDZFAMS)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify CSDZFAMX CSD definition source
//**********************************************************************
//STEP035  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMX)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace CSDZFAMX CSD definition source
//**********************************************************************
//STEP036   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(CSDZFAMX)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify FA##DC CSD definition source
//**********************************************************************
//STEP037  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(FA##DC)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace FA##DC CSD definition source
//**********************************************************************
//STEP038   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(FA##DC)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify FAEXPIRE IDCAMS VSAM file definition
//**********************************************************************
//STEP039  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(FAEXPIRE)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace FAEXPIRE IDCAMS VSAM file definition
//**********************************************************************
//STEP040   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(FAEXPIRE)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAMCI IDCAMS VSAM file definition
//**********************************************************************
//STEP041  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAMCI)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAMCI IDCAMS VSAM file definition
//**********************************************************************
//STEP042   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAMCI)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAMFILE IDCAMS VSAM file definition
//**********************************************************************
//STEP043  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAMFILE)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAMFILE IDCAMS VSAM file definition
//**********************************************************************
//STEP044   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAMFILE)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAMKEY IDCAMS VSAM file definition
//**********************************************************************
//STEP045  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAMKEY)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAMKEY IDCAMS VSAM file definition
//**********************************************************************
//STEP046   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAMKEY)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM000 program source
//**********************************************************************
//STEP047  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM000)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM000 program source
//**********************************************************************
//STEP048   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM000)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM001 program source
//**********************************************************************
//STEP049  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM001)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM001 program source
//**********************************************************************
//STEP050   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM001)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM002 program source
//**********************************************************************
//STEP051  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM002)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM002 program source
//**********************************************************************
//STEP052   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM002)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM003 program source
//**********************************************************************
//STEP053  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM003)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM003 program source
//**********************************************************************
//STEP054   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM003)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM004 program source
//**********************************************************************
//STEP055  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM004)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM004 program source
//**********************************************************************
//STEP056   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM004)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM005 program source
//**********************************************************************
//STEP057  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM005)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM005 program source
//**********************************************************************
//STEP058   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM005)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM006 program source
//**********************************************************************
//STEP059  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM006)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM006 program source
//**********************************************************************
//STEP060   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM006)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM007 program source
//**********************************************************************
//STEP061  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM007)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM007 program source
//**********************************************************************
//STEP062   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM007)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM008 program source
//**********************************************************************
//STEP063  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM008)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM008 program source
//**********************************************************************
//STEP064   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM008)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM009 program source
//**********************************************************************
//STEP065  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM009)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM009 program source
//**********************************************************************
//STEP066   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM009)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM010 program source
//**********************************************************************
//STEP067  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM010)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM010 program source
//**********************************************************************
//STEP068   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM010)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM011 program source
//**********************************************************************
//STEP069  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM011)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM011 program source
//**********************************************************************
//STEP070   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM011)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM020 program source
//**********************************************************************
//STEP071  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM020)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM020 program source
//**********************************************************************
//STEP072   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM020)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM022 program source
//**********************************************************************
//STEP073  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM022)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM022 program source
//**********************************************************************
//STEP074   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM022)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM030 program source
//**********************************************************************
//STEP075  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM030)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM030 program source
//**********************************************************************
//STEP076   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM030)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM031 program source
//**********************************************************************
//STEP077  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM031)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM031 program source
//**********************************************************************
//STEP078   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM031)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM040 program source
//**********************************************************************
//STEP079  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM040)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM040 program source
//**********************************************************************
//STEP080   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM040)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM041 program source
//**********************************************************************
//STEP081  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM041)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM041 program source
//**********************************************************************
//STEP082   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM041)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM090 program source
//**********************************************************************
//STEP083  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM090)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM090 program source
//**********************************************************************
//STEP084   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM090)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM101 program source
//**********************************************************************
//STEP085  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM101)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM101 program source
//**********************************************************************
//STEP086   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM101)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAM102 program source
//**********************************************************************
//STEP087  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAM102)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAM102 program source
//**********************************************************************
//STEP088   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAM102)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAMNC program source
//**********************************************************************
//STEP089  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAMNC)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAMNC program source
//**********************************************************************
//STEP090   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAMNC)
//SYSIN     DD DUMMY
//**********************************************************************
//* Modify ZFAMPLT program source
//**********************************************************************
//STEP091  EXEC PGM=IKJEFT1B,REGION=1024K
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAMPLT)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&OUTPUT,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=SHR,DSN=@source_lib@(CONFIG)
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Replace ZFAMPLT program source
//**********************************************************************
//STEP092   EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD DISP=(OLD,DELETE),DSN=&&OUTPUT
//SYSUT2    DD DISP=SHR,DSN=@source_lib@(ZFAMPLT)
//SYSIN     DD DUMMY
//*
//