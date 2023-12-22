CREATE OR REPLACE TRIGGER ex11
    BEFORE INSERT OR UPDATE ON cumpara
    FOR EACH ROW
BEGIN
    IF :NEW.data_vanzare > sysdate THEN
        RAISE_APPLICATION_ERROR(-20011, 'Vanzarea nu poate fi facuta in avans :)');
    END IF;
    IF :new.data_vanzare < sysdate - 7 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Vanzarile trebuie inregistrate in maxim 7zile >:(');
    END IF;
END;
/


insert into cumpara values(index_vanzare.nextval, 6,11234121341,1,to_date('03.01.2023','dd.mm.yyyy'));
insert into cumpara values(index_vanzare.nextval, 6,11234121341,1,sysdate + 1);
insert into cumpara values(index_vanzare.nextval, 6,11234121341,1,sysdate);

