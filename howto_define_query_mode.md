# Create Query Mode Definition

Shows how to define the columns for zFAM Query Mode instances.

When zFAM instances are created they're all given a 4 character identifier like FA01. Using the zFAM identifier you will need to create a document template in your CICS region to list the columns for the table. Each line must be the correct length with the exact name and their values in the defined positions. If you're not familiar with document templates please work with your CICS systems group to have one defined.

Rules for the document template definition:
- Document template name must be the 4 character zFAM name followed by "FD", FA01FD. The template is looked up at execution time to get the column attributes.
- Each line must be 66 characters long with the last character being "|".
- On the document template definition it should be set to APPENDCRLF(APPEND). This is specified in the installation portion for defining the query mode templates. Normally managed by the CICS infrastructure team.
- There are 6 attributes for each column defined. The labels and values are case sensitive and must be in the proper columns.
    - **ID:** Index ID
    - **Col:** Offset in record
    - **Len:** Data length
    - **Type:** Type of data
    - **Sec:** Security option for column.
    - **Name:** Column name
    
    Example definition:  
    ```
    ----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8
    ID=001,Col=0000001,Len=000032,Type=C,Sec=01,Name=Id              |  
    ID=002,Col=0000033,Len=000040,Type=C,Sec=01,Name=first_name      |  
    ID=000,Col=0000073,Len=000040,Type=C,Sec=01,Name=last_name       |  
    ```
    
    Attribute Definitions:
    - **ID:** Defines the primary and secondary indexes. 
        - 3 character numeric value and must be padded with leading zeros.
        - The first line must be 001 for the primary index. 
        - Values range from 000 to 099.
            - 000: No secondary index.
            - 001: Primary index column. **Must be the first column in the list.**
            - 002-099: Secondary index columns.
    - **Col:** Offset in the record for the given column. 
        - 7 character numeric value that must be padded with leading zeros.
        - First line must begin with 1.
        - You can have overlapping fields.
    - **Len:** Data length. 
        - Secondary indexed character fields can be 1 to 56. ID field > 0.
        - Non indexed character fields can be 1 to 262,144 (256K). ID field must be 000.
        - Numeric fields can be 1 to 31.
    - **Type:** Column type. Must be uppercase.
        - C, for character fields.
        - N, for numeric fields.
    - **Sec:** Security for this column.
        - Ranges from 1 to 32.
        - Must be padded with leading zeros
        - References the security model to use in the zFAM security document template.
    - **Name:** Column name. 
        - 1 to 16 character name that must be padded with spaces. 
        - Name restrictions are limited to the URL encoding. 
        - Each name must be unique.
        - Names are case sensitive and must match the zQL commands.
