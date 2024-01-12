CREATE OR REPLACE PACKAGE pachet_ex_14 AS
    --type-ul va stoca informatii despre angajarea unui nou lucrator  
    TYPE TypeAngajare IS RECORD (
      id_apicultor      NUMBER(6),
      id_angajat        NUMBER(3),
      nume_angajat      VARCHAR2(20),
      prenume_angajat   VARCHAR2(20),
      cod_locatie       NUMBER(2),
      post              VARCHAR2(20),
      salariu           NUMBER(6)
    );

    -- type-ul va fi folosit pentru crearea unui 
    -- raport cu diverse informatii stranse
    -- de un apicultor intr-o luna a anului
    TYPE TypeRaportLunar IS RECORD (
        id_apicultor             NUMBER,
        nume_apicultor           VARCHAR2(30),
        prenume_apicultor        VARCHAR2(30),
        luna_raport              NUMBER, 
        --an_raport              NUMBER,
        numar_stupi_verificati   NUMBER,
        productie_medie_miere    NUMBER,
        comentariu               VARCHAR2(255)
    );
    -- Functia ia un obiect the tip TypeAngajare si returneaza
    -- 2 -> daca angajatul nu este inca inregistrat
    -- 1 -> daca angajatul a mai fost inregistrat inainte
    -- 0 -> daca apare vreo eroare
    FUNCTION verificaAngajare (potential_angajat TypeAngajare)
            RETURN NUMBER;
            
    -- Procedura insereaza informatii despre un viitor angajat
    -- in tabelele corespunzatoare dupa caz
    PROCEDURE angajeazaPersonal
            (id_apicultor      apicultor.id_apicultor%TYPE,
             id_angajat        NUMBER,
             nume_angajat      VARCHAR2,
             prenume_angajat   VARCHAR2,
             cod_locatie       NUMBER,
             post              VARCHAR2,
             salariu           NUMBER);
             
    -- Procedura va adauga in tabela MATCA o noua matca pentru un stup
    -- daca acesta nu avea deja una,
    -- daca avea deja una,cea veche va fi marcata ca inlocuita si cea 
    -- noua va fi inserata in schimb
    PROCEDURE schimbaMatca
            (p_id_stup    familie_de_albine.id_stup%TYPE,
             p_id_matca   matca.id_matca%TYPE);   
    
    -- Functia va returna un obiect de tip TypeRaportLunar
    -- care va contine informati aferente
    FUNCTION IntocmireRaport
                  (p_id_apicultor NUMBER,
                   p_data_raport    DATE,
                   p_comentariu   VARCHAR2)
            RETURN TypeRaportLunar;
    
    -- Procedura doar va afisa formatat un raport,
    -- primind aceeasi parametrii ca IntocmireRaport(...)
    PROCEDURE printRaport
            (p_id_apicultor NUMBER,
             p_data_raport    DATE,
             p_comentariu   VARCHAR2);

    -- O varianta overloaded a procedurii de mai sus
    -- care ia ca parametru un obiect,dar face exact
    -- acelasi lucru
    PROCEDURE printRaport
        (v_raport TypeRaportLunar);
        
END pachet_ex_14;
/


CREATE OR REPLACE PACKAGE BODY pachet_ex_14 AS
----------------------------------------------
    
    FUNCTION verificaAngajare
        (potential_angajat      TypeAngajare)
    RETURN NUMBER IS
        v_lucreaza_in_prezent   DATE;
        v_check_locatie         NUMBER;
        v_check_apicultor       NUMBER;
        v_check_angajat         NUMBER;
        CURSOR c (id  NUMBER) IS
                  SELECT data_eliminare
                  FROM angajeaza an
                  WHERE an.id_angajat = id
                  ORDER BY data_angajare DESC;
        BEGIN
            -- verifica daca apicultorul e valid
            Select count(id_apicultor)
            INTO v_check_apicultor
            from apicultor
            where id_apicultor = potential_angajat.id_apicultor;
    
            IF v_check_apicultor = 0 THEN
                RAISE_APPLICATION_ERROR(-20002,'APICULTOR INVALID');
                RETURN 0;
            END IF;
            -- verifica daca locatie e valida
            Select count(cod_locatie)
            INTO v_check_locatie
            from locatie
            where cod_locatie = potential_angajat.cod_locatie;
    
            IF v_check_locatie = 0 THEN
                RAISE_APPLICATION_ERROR(-20001,'LOCATIE INVALIDA');
                RETURN 0;
            END IF;
    
    
            -- intai verific daca exista deja angajatul intr-o tabela
            Select count(id_angajat)
            INTO v_check_angajat
            from angajat
            where id_angajat = potential_angajat.id_angajat;
            
            IF v_check_angajat = 0 THEN
                RETURN 2;
            END IF;
            
            -- datele de eliminare sunt sortate dupa data angajarii
            -- ultima data de eliminare va corespune ultimei angajari
            -- iar un angajat poate fi angajat o singura data la un
            -- moment de timp, deci prima valoare returnata va spune
            -- daca lucreaza in prezent(NULL) sau nu(o data)
            OPEN c(potential_angajat.id_angajat);
            FETCH c INTO v_lucreaza_in_prezent;  
            CLOSE c;
    
            IF v_lucreaza_in_prezent is NULL THEN
                RAISE_APPLICATION_ERROR(-20000,'ACEST ANGAJAT LUCREAZA DEJA');
                RETURN 0;
            END IF;
    
            RETURN 1;
        END verificaAngajare;
----------------------------------------------
    PROCEDURE angajeazaPersonal
            (id_apicultor      apicultor.id_apicultor%TYPE,
             id_angajat        NUMBER,
             nume_angajat      VARCHAR2,
             prenume_angajat   VARCHAR2,
             cod_locatie       NUMBER,
             post              VARCHAR2,
             salariu           NUMBER)
        IS
            v_check            NUMBER;
            v_angajat          TypeAngajare;
        BEGIN
    
            v_angajat   := TypeAngajare(
                id_apicultor    => id_apicultor,
                id_angajat      => id_angajat,
                nume_angajat    => nume_angajat,
                prenume_angajat => prenume_angajat,
                cod_locatie     => cod_locatie,
                post            => post,
                salariu        => salariu
            );
    
            -- returneaza 1 daca e ok, else da eroare
            SELECT verificaAngajare(v_angajat) 
            INTO v_check 
            FROM dual; 
    
            IF v_check = 0 THEN
                RAISE_APPLICATION_ERROR(-20003, 'A aparut o eroare');
            -- daca angajatul deja exista trebuie adaugate informatii doar in tabela de angajeaza
            
            ELSE
            
                IF v_check = 2 THEN
                    INSERT INTO angajat values(id_angajat, cod_locatie,nume_angajat,prenume_angajat);
                END IF;
                
                INSERT INTO angajeaza values(id_apicultor, id_angajat, to_date(SYSDATE,'dd.mm.yyyy'),NULL,post,salariu);
                -- daca nu lucreaza inca deloc, trebuie adaugate info si in tabela de angajat cu numele etc
        
            END IF;
    
        END;
----------------------------------------------
    PROCEDURE schimbaMatca
            (p_id_stup    familie_de_albine.id_stup%TYPE,
             p_id_matca   matca.id_matca%TYPE)
        IS
            v_check_stup    NUMBER;
            v_check_matca   NUMBER;
            v_culoare       VARCHAR2(1);
        BEGIN
            SELECT COUNT(p_id_Stup)
            INTO v_check_stup
            FROM familie_de_albine f
            WHERE f.id_stup = p_id_stup;
        
            IF v_check_stup = 0 THEN
                RAISE_APPLICATION_ERROR(-20004, 'Stupul nu exista!');
            END IF;
            
            -- verifica daca stupul are deja matca
            SELECT COUNT(m.id_stup)
            INTO v_check_matca
            FROM matca m
            WHERE m.id_stup = p_id_Stup; 
            
            IF v_check_matca > 0 THEN
                --daca avea deja matca,marcheaz-o ca inlocuita si insereaz-o pe cea noua
                UPDATE matca
                SET data_inlocuire =  to_date(SYSDATE,'dd.mm.yyyy')
                WHERE id_stup = p_id_stup and data_inlocuire is null;
            END IF;    
                --alege culoare conforma anului dupa codul culorilor
            SELECT CASE 
                    WHEN MOD(EXTRACT(YEAR FROM SYSDATE),5) = 0 THEN 's'
                    WHEN MOD(EXTRACT(YEAR FROM SYSDATE),5) = 1 THEN 'a'
                    WHEN MOD(EXTRACT(YEAR FROM SYSDATE),5) = 2 THEN 'g'
                    WHEN MOD(EXTRACT(YEAR FROM SYSDATE),5) = 3 THEN 'r'
                    WHEN MOD(EXTRACT(YEAR FROM SYSDATE),5) = 4 THEN 'v'
                   END
            INTO v_culoare
            FROM DUAL;
            
            INSERT INTO matca VALUES(p_id_matca, p_id_stup, 'carpatina',v_culoare,NULL); 
        END;
        
----------------------------------------------
    FUNCTION IntocmireRaport
                  (p_id_apicultor NUMBER,
                   p_data_raport    DATE,
                   p_comentariu   VARCHAR2)
    RETURN TypeRaportLunar
    IS
        raport     TypeRaportLunar   := TypeRaportLunar(NULL,NULL,NULL,NULL,0,0,NULL); --ADD 1 parameter later for year
    BEGIN
        -- completeaza cu info despre apicultor
        -- si trateaza exceptia
        BEGIN
            SELECT id_apicultor,nume_apicultor,prenume_apicultor
            INTO raport.id_apicultor, raport.nume_apicultor, raport.prenume_apicultor
            FROM apicultor
            WHERE id_apicultor = p_id_apicultor;
            
            -- daca id-ul nu este bun 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20002, 'APICULTOR INVALID');
        END;
    
        -- adauga luna si anul    
        raport.luna_raport := EXTRACT(MONTH FROM p_data_raport);
        --raport.an_raport := EXTRACT(YEAR FROM p_data_raport);
        
        -- adauga nr stupi verificati si media de miere
        SELECT count(*), avg(productie_miere)
        INTO raport.numar_stupi_verificati, raport.productie_medie_miere
        FROM verifica
        WHERE id_apicultor = p_id_apicultor
            and EXTRACT(MONTH FROM data_verificare) = raport.luna_raport;
            -- add EXTRACT(YEAR FROM data_verificare) = raport.an_raport;
            
        raport.comentariu := p_comentariu; 
    
        RETURN raport;
    END IntocmireRaport;

----------------------------------------------
    PROCEDURE printRaport
        (p_id_apicultor NUMBER,
         p_data_raport    DATE,
         p_comentariu   VARCHAR2)
    IS
        v_raport    TypeRaportLunar;
    BEGIN
        v_raport := intocmireRaport(p_id_apicultor, p_data_raport, p_comentariu);
    
        DBMS_OUTPUT.PUT_LINE('ID_APICULTOR: '||v_raport.id_apicultor);
        DBMS_OUTPUT.PUT_LINE('NUME_APICULTOR: '||v_raport.nume_apicultor);
        DBMS_OUTPUT.PUT_LINE('PRENUME_APICULTOR: '||v_raport.prenume_apicultor);
        DBMS_OUTPUT.PUT_LINE('LUNA: '||TO_CHAR(TO_DATE(v_raport.luna_raport, 'MM'), 'Month'));
        --DBMS_OUTPUT.PUT_LINE('ANUL: '||TO_CHAR(TO_DATE(v_raport.an_raport, 'YY'), 'Year'));
        DBMS_OUTPUT.PUT_LINE('NUMAR STUPI VERIFICATI: '||v_raport.numar_stupi_verificati);
        DBMS_OUTPUT.PUT_LINE('MEDIE PRODUCTIE MIERE: '||v_raport.productie_medie_miere);
        DBMS_OUTPUT.PUT_LINE('OBSERVATII: '||v_raport.comentariu);
        
    END;
----------------------------------------------
    PROCEDURE printRaport
        (v_raport TypeRaportLunar)
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('ID_APICULTOR: '||v_raport.id_apicultor);
        DBMS_OUTPUT.PUT_LINE('NUME_APICULTOR: '||v_raport.nume_apicultor);
        DBMS_OUTPUT.PUT_LINE('PRENUME_APICULTOR: '||v_raport.prenume_apicultor);
        DBMS_OUTPUT.PUT_LINE('LUNA: '||TO_CHAR(TO_DATE(v_raport.luna_raport, 'MM'), 'Month'));
        --DBMS_OUTPUT.PUT_LINE('ANUL: '||TO_CHAR(TO_DATE(v_raport.an_raport, 'YY'), 'Year'));
        DBMS_OUTPUT.PUT_LINE('NUMAR STUPI VERIFICATI: '||v_raport.numar_stupi_verificati);
        DBMS_OUTPUT.PUT_LINE('MEDIE PRODUCTIE MIERE: '||v_raport.productie_medie_miere);
        DBMS_OUTPUT.PUT_LINE('OBSERVATII: '||v_raport.comentariu);
        
    END;
----------------------------------------------

END pachet_ex_14;
/