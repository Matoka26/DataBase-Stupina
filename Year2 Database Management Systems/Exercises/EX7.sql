-- EX7
--NOTE: AM PUS IN INSERTURI ANUL DE 2024 PENTRU VERIFICAREA DIN SESIUNE
--     CAND LUCREZ O SA FOLOSESC extract(year from sysdate) + 1 
--     CA REZULTATELE SA CORESPUNDA


-- nota stupilor verificati anul asta din locatia par_loc si produsele recoltate

CREATE OR REPLACE PROCEDURE ex7
    (par_loc locatie.cod_locatie%TYPE DEFAULT 1)
IS
    TYPE refcursor IS REF CURSOR;
    
    CURSOR c (par_cursor locatie.cod_locatie%TYPE) IS
        --     id                media mediei calificativelor
        SELECT l.id_stup ,avg((blandete + instinct_roire + productie_miere)/3), 
                --intoarce produsele recoltate de la stupii respectivi
                CURSOR(select p.id_recoltare,pr.nume_produs
                        from familie_de_albine f, produce p,produs pr
                        where f.id_stup = p.id_stup
                          and l.id_stup = f.id_stup 
                          and pr.cod_produs = p.cod_produs)
        FROM  verifica l
        --verifica locatia potrivita
        WHERE par_cursor = l.cod_locatie
        --verifica anul potrivit
          AND EXTRACT(YEAR FROM l.data_verificare) 
                = EXTRACT(YEAR FROM sysdate) + 1
        GROUP BY l.id_stup;
        
    v_cursor        refcursor;
    v_id_stup       verifica.id_stup%TYPE;
    v_medie         NUMBER;
    v_id_rec        produce.id_recoltare%TYPE;
    v_nume_prod     produs.nume_produs%TYPE;
    v_cnt_lines     NUMBER;
    
    BEGIN
    
    OPEN c(par_loc);
    LOOP
        FETCH c INTO v_id_stup, v_medie, v_cursor;
        EXIT WHEN c%NOTFOUND;
        
        v_cnt_lines := 0;
        
        DBMS_OUTPUT.PUT_LINE('Id stup: '||v_id_stup||'  Medie califactiv: '||round(v_medie,2));
        
        LOOP
            FETCH v_cursor INTO v_id_rec, v_nume_prod;
            EXIT WHEN v_cursor%NOTFOUND;
            
            v_cnt_lines := 1;
            DBMS_OUTPUT.PUT_LINE('   ->Id recoltare: '||v_id_rec||'  Nume produs: '||v_nume_prod);
            
        END LOOP;
        
        --verifica daca cursorul a returnat macar o linie pentru a afisa mesajul
        IF v_cnt_lines = 0 THEN
            DBMS_OUTPUT.PUT_LINE('   ->Niciun produs recoltat');
        END IF;
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    CLOSE c;
    END;
    /
    
    
BEGIN
    ex7(4);
END;
/



