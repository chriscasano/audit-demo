insert into customers values
(gen_random_uuid(), 'Chris', '1 Happpy St', 'Merrick', 'NY', '11566', 1, 1.380),
(gen_random_uuid(), 'Oscar', '2 Sullen St', 'Middletown', 'NY', '22222', 55, 909.7),
(gen_random_uuid(), 'Carli', '3 Peezy St', 'Ellenville', 'NY', '34567', 900, 100),
(gen_random_uuid(), 'Jenny', '55 Papa St', 'San Diego', 'CA', '98765', 1000, 0.98),
(gen_random_uuid(), 'Harry', '100 Street St', 'El Paso', 'TX', '56738', 63, 0)
;

insert into orders values
(gen_random_uuid(), 'Chris'),
(gen_random_uuid(), 'Oscar'),
(gen_random_uuid(), 'Carli'),
(gen_random_uuid(), 'Jenny'),
(gen_random_uuid(), 'Harry')
;


update customers set
street = '9 Madison Ave'
where name = 'Chris';
;

delete from customers where name = 'Harry';
