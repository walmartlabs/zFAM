//DEFEXPR  JOB @job_parms@
//**********************************************************************
//* Customize expiry file for each ZFAM
//**********************************************************************
//* Create config file for following steps
//**********************************************************************
//CONFIG    EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD *
 @environment@  DEV
/*
//SYSUT2    DD DISP=(NEW,PASS),DSN=&&STRINGS,
//             UNIT=VIO,SPACE=(80,(1000,1000)),
//             DCB=(LRECL=80,RECFM=FB)
//SYSIN     DD DUMMY
//**********************************************************************
//* Customize the DFHCSDUP DEFINE statements and pass to next step
//**********************************************************************
//CUSTOMIZ EXEC PGM=IKJEFT1B
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMX)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&CSDCMDS,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=(OLD,PASS),DSN=&&STRINGS
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Define the CSD definition for the FAEXPIRE file
//**********************************************************************
//DEFINE    EXEC  PGM=DFHCSDUP
//STEPLIB   DD    DISP=SHR,DSN=@cics_hlq@.SDFHLOAD
//DFHCSD    DD    DISP=SHR,DSN=@cics_csd@
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    DISP=SHR,DSN=&&CSDCMDS
//**********************************************************************
//* Customize the FAEXPIRE IDCAMS statements and pass to next step
//**********************************************************************
//FAMFILEC EXEC PGM=IKJEFT1B
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(FAEXPIRE)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&FAEXPIRE,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=(OLD,PASS),DSN=&&STRINGS
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Define the FAEXPIRE for one enterprise caching environment
//**********************************************************************
//FAMFILED  EXEC  PGM=IDCAMS
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    DISP=SHR,DSN=&&FAEXPIRE
//*
//