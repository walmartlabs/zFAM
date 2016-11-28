# Security Definition

Security can be applied to both basic and query mode zFAM instances. Credentials are all based on RACF user id and password authentication passed to the service via Basic Authorization header.  

    Authorization: Basic base64encodedvalue==

The security document template is optional and when used is defined similiar to the [Query Mode field definition](./readme_query_mode) template. Use the 4 character zFAM instance name and append "SD" to the name like FA01SD. Refer to the [installation document](./Installation.md) on how to define the document template to your CICS region. 

You can define one or more RACF users to have all or selective access to the data.

Here is an example security document template:
```
----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8 {not part of template}
Basic Mode Read Only: yea                               
Query Mode Read Only: nay                               
User=xxxxxxxx,Access,0         1         2         3   ¦
User=xxxxxxxx,Type  ,012345678901234567890123456789012 ¦
                                                       ¦
User=RACF0001,Read  ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=RACF0001,Write ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=RACF0001,Delete,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
                                                       ¦
User=RACF0002,Read  ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=RACF0002,Write ,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
User=RACF0002,Delete,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ¦
----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8 {not part of template}
```

## Layout of the security template
- Each line must be 56 characters long and terminated with "|" string.
- Blank lines, except for character 56, are skipped.
- First two lines are required. They define the basic mode and query mode read only permissions and are only referenced in HTTP mode.
- Following user id lines are defined as:
    - 1-5: Text, "User="
    - 6-13: RACF user id. Should be a valid RACF user id 8 characters long and padded with spaces on the right.
    - 15-20: Access Type, can be read, write or delete.
    - 22: Basic Mode permission flag. This is only valid for basic mode requests.
    - 23:54: Query Mode permission flags. These are associated with the field definitions "Sec=" number for a given column. Position 23 is Sec=01, position 24 is Sec=02, etc...

## Security Order of Precedence
- HTTP Mode
    - Basic Mode
        - Security Document Template Exists, FA01SD
            - "Basic Mode Read Only" = yea
                - All user's have "read" access
            - "Basic Mode Read Only" = nay
                - All users have full access to the data
        - No Security Document Template, FA01SD
            - All users have full access to the data
    - Query Mode
        - Security Document Template Exists, FA01SD
            - "Query Mode Read Only" = yea
                - All user's have "read" access
            - "Query Mode Read Only" = nay
                - All users have full access to the data
        - No Security Document Template, FA01SD
            - All users have full access to the data
- HTTPS Mode
    - Basic Authorization. User id and password are authenticated against RACF.  
        - Basic Mode  
            - Security Document Template Exists, FA01SD  
                - Scan "User=" entries for matching user id.  
                    - No matching user, **no access allowed**  
                    - Matching user  
                        - Compare the "Access Type" field, GET(READ), PUT/POST(WRITE) and DELETE(DELETE)  
                            - Column 22 has an "x".  
                                - **User request processed.**  
            - No Security Document Template, FA01SD  
                - All users have full access to the data  
        - Query Mode  
            - Security Document Template Exists, FA01SD  
                - "Query Mode Read Only" = yea  
                    - All user's have "read" access  
                - "Query Mode Read Only" = nay  
                    - Scan User= entries for matching user id.  
                        - No matching user, no access allowed  
                        - Matching user  
                            - Compare the "Access Type" field, GET(READ), PUT/POST(WRITE) and DELETE(DELETE)
                                - Use the "Sec=" value from the [field definition](./readme_query_mode) template to check for a permission flag in corresponding fields. Sec=01 is column 23, Sec=02 is column 24, etc...  
                                    - **User request processed.**  
            - No Security Document Template, FA01SD  
                - All users have full access to the data  
    - No Basic Authorization. **no access allowed**

