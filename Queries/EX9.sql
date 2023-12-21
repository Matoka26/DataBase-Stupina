--Se dau un nume de apicultor,un nume de locatie si un numar K
--Sa se afiseze id-ul apicultorului si cati angajati care lucreaza
--in prezent a angajat in acea locatie, daca acesta(apicultorul)
--a vizitat mai mult de K locatii

CREATE OR REPLACE PROCEDURE ex9
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
    END;
    /

BEGIN   
    ex9('Dogaru','camp',0);
    ex9('Dogaru','camp',2);
    ex9('Dogaru','acasa');
    ex9('Mircea','acasa');
    ex9('aaaa','acasa');
END;
/


