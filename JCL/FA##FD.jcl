//FA##FD   JOB @job_parms@
//**********************************************************************
//* Customize and define file definition for one instance of ZFAM
//**********************************************************************
//* To use this job repeatedly
//* Change ## to the @id@ value in DEFFA##, example: C ## 01 ALL
//* Customize SYSUT1 with the USERIDs and their access levels
//* Submit
//* Enter CANCEL on the command line to cancel changes and exit edit
//**********************************************************************
//* Create FA##FD document template definition
//**********************************************************************
//CREATE    EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD *
ID=001,Col=0000001,Len=000010,Type=N,Sec=01,Name=Customer        ¦
ID=000,Col=0000011,Len=000015,Type=C,Sec=01,Name=FirstName       ¦
ID=000,Col=0000026,Len=000015,Type=C,Sec=01,Name=MiddleName      ¦
ID=000,Col=0000041,Len=000025,Type=C,Sec=01,Name=LastName        ¦
ID=000,Col=0000066,Len=000006,Type=N,Sec=01,Name=StreetNumber    ¦
ID=000,Col=0000072,Len=000020,Type=C,Sec=01,Name=StreetName      ¦
ID=000,Col=0000092,Len=000020,Type=C,Sec=01,Name=City            ¦
ID=000,Col=0000112,Len=000020,Type=C,Sec=01,Name=State           ¦
ID=000,Col=0000132,Len=000005,Type=N,Sec=01,Name=ZipCode         ¦
ID=000,Col=0000137,Len=000004,Type=N,Sec=01,Name=ZipCodeExt      ¦
ID=002,Col=0000141,Len=000010,Type=N,Sec=01,Name=PhoneNumber     ¦
/*
//SYSUT2    DD DISP=SHR,DSN=@doct_lib@(FA##FD)
//SYSIN     DD DUMMY
//**********************************************************************
//* Define FA##FD document template definition
//**********************************************************************
//DEFDOCT   EXEC  PGM=DFHCSDUP
//STEPLIB   DD    DISP=SHR,DSN=@cics_hlq@.SDFHLOAD
//DFHCSD    DD    DISP=SHR,DSN=@cics_csd@
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    *
 DEFINE DOCTEMPLATE(FA##FD) GROUP(FA##)
        TEMPLATENAME(FA##FD) DDNAME(@doct_dd@) MEMBERNAME(FA##FD)
        APPENDCRLF(YES) TYPE(EBCDIC)
/*
//