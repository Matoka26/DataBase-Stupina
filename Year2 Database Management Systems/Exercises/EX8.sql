-- EX8
-- Pentru un client dat dupa nume,sa se returneze suma de bani platita

CREATE OR REPLACE FUNCTION ex8
    (par_nume   client.nume_client%TYPE)
RETURN NUMBER IS
    v_result    NUMBER;
    v_id        client.id_client%TYPE;
    BEGIN
--      am folosit clauza de group by pentru a rezolva situatiile conflictuale de nume
        SELECT c.id_client, SUM(c.cantitate * p.pret)
        INTO v_id,v_result
        FROM cumpara c, client cl, produs p
        WHERE cl.id_client = c.id_client
          AND INITCAP(cl.nume_client) = INITCAP(par_nume)
          AND c.cod_produs = p.cod_produs
          group by c.id_client;

        RETURN v_result;        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20000,
                    'Nu exista clientul '||par_nume);
            WHEN TOO_MANY_ROWS THEN
                RAISE_APPLICATION_ERROR(-20001,
                    'Exista mai multi clineit cu numele '||par_nume);
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20002,'Alta eroare!');

END ex8;
/

SELECT ex8('Mircea') FROM dual;  --1 cu acest nume
SELECT ex8('Popescu') FROM dual; --2 cu acest nume
SELECT ex8('TEST') FROM dual;  --0 cu acest nume