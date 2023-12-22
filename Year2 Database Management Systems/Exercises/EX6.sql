--EX 6

--Se da un numar k care reprezinta primele k luni ale anului 
--si un numar val care reprezinta o suma de bani pe o singura plata

--Sa se afiseze pentru cele k luni:
--   -> cate plati au fost realizate
--   -> cate unitati din fiecare categorie au fost achizitionate
--   -> care au fost clientii care in luna i au cheltuit cel putin val 
--                unitati monetare pe o singura plata, unde i <-[1,k]

CREATE OR REPLACE PROCEDURE ex6
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
    END;
    /
    
BEGIN
    ex6(3,400);
END;
/