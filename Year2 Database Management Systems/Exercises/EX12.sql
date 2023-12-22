--Sa nu se permita unui utilizator sa foloseasca
--comanda DROP decat daca are rolul de DBA(administrator)


CREATE OR REPLACE TRIGGER ex12
    AFTER DROP ON SCHEMA
DECLARE
    v_role  user_role_privs.granted_role%TYPE;
BEGIN
    SELECT granted_role 
    INTO v_role
    FROM USER_ROLE_PRIVS
    WHERE username = (SELECT username FROM user_users)
      AND granted_role = 'DBA';
      
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_role := 'NO_DBA';
    
      
    IF v_role <> 'DBA' THEN
        RAISE_APPLICATION_ERROR(-20901,'Nu esti admin,nu poti da DROP');
    END IF;
END;
/



SELECT username, granted_role 
    FROM USER_ROLE_PRIVS
    WHERE username = (SELECT username FROM user_users);
    

create table test(nr number);

drop table test;
drop trigger ex12;