CREATE TABLE contacts (
    firstname varchar(255),
    lastname varchar(255),
    company varchar(255),
    street varchar(255),
    pcode varchar(15),
    city varchar(15),
    ccode varchar(2),
    phone varchar(255),
    fax varchar(255),
    email varchar(255)
);

CREATE TABLE domains (
    domain varchar(100),
    tld varchar(15)
);

CREATE TABLE log (
    id integer PRIMARY KEY,
    ts integer,
    input blob,
    output blob,
    command varchar(255),
    code integer,
    message varchar(255)
);

CREATE TABLE handles (
    handle varchar(255)
);

CREATE TABLE systemdomains (
    domain varchar(255)
);
