/* Scott Hidlebaugh
Lab 2 Part 2
CIT 325
*/

/* Enable output*/
set serveroutput on

DECLARE
 lv_input VARCHAR2(100);
 lv_local VARCHAR2(10);
 lv_print VARCHAR2(17);
 i_length NUMBER;
 i_switch NUMBER := 10;

BEGIN
/* Receive input*/
lv_input := '&1';

/* Figure out length of input*/
i_length := LENGTH(lv_input);

/* Determine criteria */
IF i_length < i_switch
        THEN
                lv_local := lv_input;

ELSIF i_length > i_switch
        THEN
                lv_local := SUBSTR(lv_input, 1, i_switch);
END IF;

/* Combine results*/
lv_print := 'Hello' || lv_local || '!';

/* Output results*/
dbms_output.put_line(lv_print);

END;

