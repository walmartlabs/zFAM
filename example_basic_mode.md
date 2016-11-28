# Basic Mode Examples

In the following examples we'll show how to add, update, delete and retrieve values from a zFAM instance. All the examples will use the following variables and assume the keys listed below already exist for the example.
- hostname:port - /zos.com:777
- @path@ - /pro/league/teams/

| Key | Value |
| --- | --- |
| mlb_angels | { "name" : "Los Angeles Angles", "players" : 26 } |
| mlb_astros | { "name" : "Houston Astros", "players" : 26 } |
| mlb_athletics | { "name" : "Oakland Athletics", "players" : 26 } |
| mlb_blue_jays | { "name" : "Toronto Blue Jays", "players" : 26 } |
| mlb_braves | { "name" : "Atlanta Braves", "players" : 26 } |
| mlb_brewers | { "name" : "Milwaukee Brewers", "players" : 26 } |
| mlb_cardinals | { "name" : "St.Louis Cardinals", "players" : 26 } |
| mlb_cubs | { "name" : "Chicago Cubs", "players" : 26 } |
| mlb_diamondbacks | { "name" : "Arizona Diamondbacks", "players" : 26 } |
| mlb_dodgers | { "name" : "Los Angeles Dodgers", "players" : 26 } |
| mlb_giants | { "name" : "San Francisco Giants", "players" : 26 } |
| mlb_indians | { "name" : "Cleveland Indians", "players" : 26 } |
| mlb_mariners | { "name" : "Seattle Mariners", "players" : 26 } |
| mlb_marlins | { "name" : "Florida Marlins", "players" : 26 } |
| mlb_mets | { "name" : "New York Mets", "players" : 26 } |
| mlb_nationals | { "name" : "Washington Nationals", "players" : 26 } |
| mlb_orioles | { "name" : "Baltimore Orioles", "players" : 26 } |
| mlb_padres | { "name" : "San Diego Padres", "players" : 26 } |
| mlb_phillies | { "name" : "Philadelphia Phillies", "players" : 26 } |
| mlb_pirates | { "name" : "Pittsburgh Pirates", "players" : 26 } |
| mlb_rangers | { "name" : "Texas Rangers", "players" : 26 } |
| mlb_rays | { "name" : "Tampa Bay Rays", "players" : 26 } |
| mlb_red_sox | { "name" : "Boston Red Sox", "players" : 26 } |
| mlb_reds | { "name" : "Cincinnati Reds", "players" : 26 } |
| mlb_rockies | { "name" : "Colorado Rockies", "players" : 26 } |
| mlb_royals | { "name" : "Kansas City Royals", "players" : 26 } |
| mlb_tigers | { "name" : "Detroit Tigers", "players" : 26 } |
| mlb_twins | { "name" : "Minnesota Twins", "players" : 26 } |
| mlb_white_sox | { "name" : "Chicago White Sox", "players" : 26 } |
| mlb_yankees | { "name" : "New York Yankees", "players" : 26 } |
| nfl_bengals | { "name" : "Cincinnati Bengals", "players" : 53 } |
| nfl_bills | { "name" : "Buffalo Bills", "players" : 53 } |


1. Retrieve the value for a single key, "mlb_rangers".  
    GET http://zos.com:777/pro/league/teams/mlb_rangers  
    Body: None  
    Request Headers:
    - None

    HTTP Code: 200  
    HTTP Text: Ok  
    Body: { "name" : "Texas Rangers", "players" : 26 }  

2. Retrieve a list of the first 3 "mlb" teams. Use the **_ge_** and **_rows_** query parameters. The **ge** query parameter asks the service to return rows "greater than or equal to" the key value and **rows** indicates how many rows to return with this request.  
Two header values will be returned showing the number of rows retrieved and the last key in the list. The HTTP status is also set to the last key in the list.  
The body format changes to reflect all the keys and values returned by the request. Four values are repeated for each record. There are no quotes around the key or value strings. I prefer this method since it reports the true length of each key and value so it's easily parsed by lengths and don't have to worry about the data values conflicting with the delimiter character.
    - 3 character numeric value representing length of the key.  
    - key, 1 to 255 byte value.  
    - 7 character numeric value representing length of the value.  
    - value, 1 to 3.2MB value.  

    GET http://zos.com:777/pro/league/teams/mlb?ge,rows=3  
    Body: None  
    Request Headers:  
    - None

    HTTP Code: 200  
    HTTP Text: mlb\_dodgers  
    Body: **010**mlb\_angels**0000049**{ "name" : "Los Angeles Angles", "players" : 26 }**010**mlb\_astros**0000045**{ "name" : "Houston Astros", "players" : 26 }**013**mlb\_athletics**0000048**{ "name" : "Oakland Athletics", "players" : 26 }  
    Response Headers:  
    - zFAM-Rows: 3  
    - zFAM-LastKey: mlb\_dodgers  

3. Issue the same request as item #2 except use the **delim** query parameter. This additional parameter will change the body format and use the single byte delimiter character to delimit the data.  
Two header values will be returned showing the number of rows retrieved and the last key in the list. The HTTP status is also set to the last key in the list.  
The body format changes to reflect all the keys and values delimited by the **delim** character. Again, there are no quotes around the key or value strings.

    GET http://zos.com:777/pro/league/teams/mlb?ge,rows=3,delim=|  
    Body: None  
    Request Headers:  
    - None
	
    HTTP Code: 200  
    HTTP Text: mlb\_dodgers  
    Body: mlb\_angels|{ "name" : "Los Angeles Angles", "players" : 26 }|mlb\_astros|{ "name" : "Houston Astros", "players" : 26 }|mlb\_athletics|{ "name" : "Oakland Athletics", "players" : 26 }  
    Returned Headers:
    - zFAM-Rows: 3
    - zFAM-LastKey: mlb\_dodgers
	
4. Let's query all the **mlb** teams and use the **zFAM-RangeEnd** custom header to stop the query when the key changes from **mlb**. We will increase the **rows** value cause we're not sure how many are in the list and let the **zFAM-RangeEnd** header terminate the list. The **zFAM-Rows** response header will return the number of key/values returned in the body.  

    GET http://zos.com:777/pro/league/teams/mlb?ge,rows=999,delim=|  
    Body: None
    Request Headers:  
    - zFAM-RangeEnd: mlb  

    HTTP Code: 200  
    HTTP Text: mlb\_yankees  
    Body: mlb\_angels|{ "name" : "Los Angeles Angles", "players" : 26 }|mlb\_astros|{ "name" : "Houston Astros", "players" : 26 }|mlb\_athletics|{ "name" : "Oakland Athletics", "players" : 26 }|..._(continues for all 30 teams)_  
    Response Headers:  
    - zFAM-Rows: 30  
    - zFAM-LastKey: mlb\_yankees
	
5. There will be times you just want to see the keys in your zFAM instance. We can do this with the **keysonly** query string parameter. This example will retrieve all the **mlb** keys only. Very similar to #4 except we use the default multi-row body response.  

    GET http://zos.com:777/pro/league/teams/mlb?ge,rows=999,keysonly  
    Body: None
    Request Headers:  
    - zFAM-RangeEnd: mlb  

    HTTP Code: 200  
    HTTP Text: mlb\_yankees  
    Body: **010**mlb\_angels**010**mlb\_astros**013**mlb\_athletics..._(continues for all 30 teams)_  
    Response Headers:  
    - zFAM-Rows: 30  
    - zFAM-LastKey: mlb\_yankees

6. Add a new key/value entry to the same pro team zFAM instance. Insert a new "nfl" team for the "Dallas Cowboys". We'll accept the default time-to-live value of 7 years (2555 days).

    POST http://zos.com:777/pro/league/teams/nfl_cowboys
    Body: { "name" : "Dallas Cowboys", "players" : 53 }
    Request Headers:  
    - None
    
    HTTP Code: 200
    HTTP Text: Ok
    Body: None
    Response Headers: None

7. Update the previously inserted "mlb_cowboys" data to reflect there are 55 players on the team and change the time-to-live value to 10 years (3650 days).

    PUT http://zos.com:777/pro/league/teams/nfl_cowboys?ttl=3650
    Body: { "name" : "Dallas Cowboys", "players" : 55 }
    Request Headers: None  
    
    HTTP Code: 200  
    HTTP Text: Ok  
    Body: None  
    Response Headers: None  

8. Delete the "Minnesota Twins" from the "mlb" team list.

    DELETE http://zos.com:777/pro/league/teams/mlb_twins
    Body: None  
    Request Headers: None
    
    HTTP Code: 200
    HTTP Text: Ok
    Body: None
    Response Headers: None
