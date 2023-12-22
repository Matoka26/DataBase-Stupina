CREATE OR REPLACE PACKAGE pachet_ex_13 AS
    
    PROCEDURE ex6 (k    NUMBER, val NUMBER);
    PROCEDURE ex7 (par_loc locatie.cod_locatie%TYPE DEFAULT 1);
    FUNCTION  ex8 (par_nume   client.nume_client%TYPE)
        RETURN NUMBER;
    PROCEDURE ex9 (par_nume       apicultor.nume_apicultor%TYPE,
                   par_locatie    locatie.nume_loc%TYPE,
                   par_k_vizite   NUMBER DEFAULT 0);

END pachet_ex_13;
/
CREATE OR REPLACE PACKAGE BODY pachet_ex_13 AS
----------------------------------------------
    PROCEDURE ex6
            (k    NUMBER, val NUMBER)
        IS
            --va stoca lunile din an in care s-au facut vanzari
            TYPE vector_luni IS VARRAY(12) OF NUMBER;    
            --va stoca categoriile de produse 
            TYPE tablou_indexat_categorii IS TABLE OF PLS_INTEGER INDEX BY produs.categorie%TYPE;
            --va stoca clientii care au cheltuit ... in luna respectiva
            TYPE tablou_imbricat_clienti IS TABLE OF VARCHAR2(50); 
        
            t_luni              vector_luni := vector_luni();
            t_categorii         tablou_indexat_categorii;
            t_clienti           tablou_imbricat_clienti;
            
            v_aux               NUMBER;
            v_aux_nume_luna     VARCHAR2(20);
            v_aux_nume_client   VARCHAR2(40);
        
        BEGIN
        -- ia numarul de vanzari din fiecare luna
            FOR i IN 1..k LOOP
                --facem un tabel nou pentru fiecare luna 
                t_clienti := tablou_imbricat_clienti(); 
                
                t_luni.extend;
                
                select  count(extract(month from data_vanzare)) 
                into t_luni(i)
                from cumpara  
                where i = extract(month from data_vanzare);
                
                --converteste din int in numele lunii
                SELECT TO_CHAR(TO_DATE(i, 'MM'), 'Month') 
                into v_aux_nume_luna
                from dual;
                
                DBMS_OUTPUT.PUT_LINE(v_aux_nume_luna||' vanzari:'||t_luni(i));
                
                -- cate vanzari au fost din fiecare categorie
                FOR v_categ IN (SELECT DISTINCT nvl(categorie, 'nespecificat') AS category FROM produs) LOOP 
                  
                    SELECT nvl(SUM(c.cantitate),0)
                    INTO t_categorii(v_categ.category)
                    FROM cumpara c, produs p
                    WHERE p.cod_produs = c.cod_produs
                        AND nvl(p.categorie, 'nespecificat') = v_categ.category
                        AND EXTRACT(MONTH FROM c.data_vanzare) = i ; 
                        
                    DBMS_OUTPUT.PUT_LINE('  '||v_categ.category||' unitati:'||t_categorii(v_categ.category));
                    END LOOP;
                                    
                --ia clientii care au facut macar o plata mai mare decat parametru val in acea luna
                SELECT DISTINCT cl.nume_client||' '||cl.prenume_client
                BULK COLLECT INTO t_clienti
                FROM cumpara c, produs p, client cl
                WHERE c.cod_produs = p.cod_produs 
                  AND cl.id_client = c.id_client
                  AND EXTRACT(MONTH FROM c.data_vanzare) = i
                  AND p.pret * c.cantitate >= val;
              
            IF t_clienti.COUNT = 0 
                THEN DBMS_OUTPUT.PUT_LINE('Nu a fost niciun client cu o plata asa mare');
            
                ELSE DBMS_OUTPUT.PUT_LINE('Clientii care a avut o plata cu suma cel putin'||val||' in luna '||v_aux_nume_luna||':');
                FOR i IN 1..t_clienti.COUNT LOOP
                    DBMS_OUTPUT.PUT_LINE('    '||t_clienti(i));
                END LOOP;
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('');
            END LOOP;
        END ex6;
        
----------------------------------------------
    PROCEDURE ex7
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
    END ex7;
    
----------------------------------------------
    FUNCTION ex8
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

----------------------------------------------

    PROCEDURE ex9
        (par_nume       apicultor.nume_apicultor%TYPE,
         par_locatie    locatie.nume_loc%TYPE,
         par_k_vizite   NUMBER DEFAULT 0)
        IS
            v_id_apic   apicultor.id_apicultor%TYPE;
            v_cnt_ang   NUMBER;
            v_cnt_viz   NUMBER;
        BEGIN
            --cati angajati a angajat apicultorul in acea locatie si inca lucreaza
            SELECT ap.id_apicultor,count(a.id_angajat), count(id_vizita)
            INTO v_id_apic, v_cnt_ang,v_cnt_viz
            FROM apicultor ap, locatie l, angajeaza an,angajat a, viziteaza v
            WHERE
                --cauta apicultor dupa nume
                ap.nume_apicultor = Initcap(par_nume)
                --cauta locatia dupa nume
                AND l.nume_loc = par_locatie  
                
                -- join pentru angajati pe locatie
                AND a.id_angajat = an.id_angajat
                AND a.cod_locatie = l.cod_locatie
                
                --join pt count(id_angajat) ->cati a angajat in acea locatie si inca lucreaza
                AND ap.id_apicultor = an.id_apicultor 
                AND an.data_eliminare is null
            
                --join uri pentru  count (id_vizita)
                AND v.id_apicultor = ap.id_apicultor 
                AND v.cod_locatie = l.cod_locatie
                   
            group by ap.id_apicultor
            having count(id_vizita) > par_k_vizite;
            DBMS_OUTPUT.PUT_LINE(v_id_apic||' '||v_cnt_ang);
            
            EXCEPTION 
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('Niciun apicultor cu acest nume nu corespunde sau locatie invalida');
                WHEN TOO_MANY_ROWS THEN
                    DBMS_OUTPUT.PUT_LINE('Mai multi apicultori cu aces nume');
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Alta eroare');
    END ex9;

----------------------------------------------
END pachet_ex_13;
/