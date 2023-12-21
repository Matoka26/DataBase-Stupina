CREATE OR REPLACE TRIGGER ex10
    AFTER INSERT OR UPDATE ON angajeaza
DECLARE
    --pentru fiecare angajat verifica de cate ori apare are data concedierii null
    --semnificand ca lucreaza in prezent, aceasta poate fi 0(nu mai lucreaza deloc)
    --sau 1(lucreaza in prezent)
    CURSOR c is(select id_angajat,sum(nvl2(data_eliminare,0,1)) 
                from angajeaza 
                group by id_angajat);
                
    v_id_angajat    angajeaza.id_angajat%TYPE;    
    v_count         PLS_INTEGER;
BEGIN
    OPEN c;
    LOOP
        FETCH c INTO v_id_angajat, v_count;
        EXIT WHEN c%NOTFOUND;
    
        --daca se gaseste un angajat cu mai mult de 1 angajare 
        IF v_count > 1 THEN
            RAISE_APPLICATION_ERROR(-20010,v_id_angajat||' Nu poate fi angajat simultan de mai multi apicultori');
        END IF;
    END LOOP;
END;
/


insert into angajeaza values (194821,113 ,to_date('04.04.2023','dd.mm.yyyy'),to_date('04.04.2023','dd.mm.yyyy'),'paznic','1500');
insert into angajeaza values (947821,113 ,to_date('04.04.2023','dd.mm.yyyy'),NULL,'paznic','1500');

update angajeaza
set data_eliminare = null
where id_angajat = 113;

rollback;

select * from angajeaza where id_angajat = 113;
