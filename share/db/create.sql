CREATE TABLE handles (
    id integer PRIMARY KEY,
    firstname varchar(255),
    lastname varchar(255),
    company varchar(255),
    street varchar(255),
    pcode varchar(15),
    city varchar(15),
    ccode varchar(2),
    phone varchar(255),
    fax varchar(255),
    email varchar(255),
    handle_type varchar(255),
);

CREATE TABLE domains (
    id integer PRIMARY KEY,
    domain character varying(100),
);

CREATE TABLE log (
    
)

