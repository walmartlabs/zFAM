//FA##SD   JOB @job_parms@
//**********************************************************************
//* Customize and define security definition for one instance of ZFAM
//**********************************************************************
//* To use this job repeatedly
//* Change ## to the @id@ value in DEFFA##, example: C ## 01 ALL
//* Customize SYSUT1 with the USERIDs and their access levels
//* Submit
//* Enter CANCEL on the command line to cancel changes and exit edit
//**********************************************************************
//* Create FA##SD document template definition
//**********************************************************************
//CREATE    EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD *
Basic Mode Read Only: yea
Query Mode Read Only: nay
User=xxxxxxxx,Access,0         1         2         3   ¦
User=xxxxxxxx,Type  ,012345678901234567890123456789012 ¦
                                                       ¦
User=USERID1 ,Read  ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=USERID1 ,Write ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=USERID1 ,Delete,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
                                                       ¦
User=USERID2 ,Read  ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=USERID2 ,Write ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=USERID2 ,Delete,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
                                                       ¦
                                                       ¦
/*
//SYSUT2    DD DISP=SHR,DSN=@doct_lib@(FA##SD)
//SYSIN     DD DUMMY
//**********************************************************************
//* Define FA##SD document template definition
//**********************************************************************
//DEFDOCT   EXEC  PGM=DFHCSDUP
//STEPLIB   DD    DISP=SHR,DSN=@cics_hlq@.SDFHLOAD
//DFHCSD    DD    DISP=SHR,DSN=@cics_csd@
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    *
 DEFINE DOCTEMPLATE(FA##SD) GROUP(FA##)
        TEMPLATENAME(FA##SD) DDNAME(@doct_dd@) MEMBERNAME(FA##SD)
        APPENDCRLF(YES) TYPE(EBCDIC)
/*
//