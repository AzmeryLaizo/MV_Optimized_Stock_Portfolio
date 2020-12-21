----------------------------------------------
----------------- Import Quandl Wiki ---------
----------------------------------------------
CREATE TABLE public.eod_quotes
(
    ticker character varying(16) COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    open real,
    high real,
    low real,
    close real,
    volume double precision,
    "ex.dividend" real,
    split_ration real,
    adj_open real,
    adj_high real,
    adj_low real,
    adj_close real,
    adj_volume double precision,
    CONSTRAINT eod_quotes_pkey PRIMARY KEY (ticker, date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;


ALTER TABLE public.eod_quotes
    OWNER to postgres;
	
-- CHECK
SELECT * FROM eod_quotes LIMIT 10;

----------------------------------------------
----------------- Import S&P500 --------------
CREATE TABLE public.eod_indices
(
    symbol character varying(16) COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    open real,
    high real,
    low real,
    close real,
    adj_close real,
    volume double precision,
    CONSTRAINT eod_indices_pkey PRIMARY KEY (symbol, date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
ALTER TABLE public.eod_indices
    OWNER to postgres;
	
-- CHECK
SELECT * FROM eod_indices LIMIT 10;

----------------------------------------------
-----------create a custom calendar-----------
----------------------------------------------
CREATE TABLE public.custom_calendar
(
    date date NOT NULL,
    y bigint,
    m bigint,
    d bigint,
    dow character varying(3) COLLATE pg_catalog."default",
    trading smallint,
    CONSTRAINT custom_calendar_pkey PRIMARY KEY (date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;
ALTER TABLE public.custom_calendar
    OWNER to postgres;

-- CHECK
SELECT * FROM custom_calendar LIMIT 10;


/*
-- LIFELINE
ALTER TABLE public.custom_calendar
    ADD COLUMN eom smallint;


ALTER TABLE public.custom_calendar
    ADD COLUMN prev_trading_day date;
*/
-- CHECK
SELECT * FROM custom_calendar LIMIT 10;
-- Update the table with new data (this will take some time)
UPDATE custom_calendar
SET prev_trading_day = PTD.ptd
FROM (SELECT date, (SELECT MAX(CC.date) 
FROM custom_calendar CC 
WHERE CC.trading=1 AND CC.date<custom_calendar.date) ptd 
  FROM custom_calendar) PTD
WHERE custom_calendar.date = PTD.date;
-- CHECK
SELECT * FROM custom_calendar ORDER BY date;
-- Update the table with new data (this will take some time)
UPDATE custom_calendar
SET eom = EOMI.endofm
FROM (SELECT CC.date,CASE WHEN EOM.y IS NULL THEN 0 ELSE 1 END endofm 
  FROM custom_calendar CC LEFT JOIN 
  (SELECT y,m,MAX(d) lastd 
   FROM custom_calendar 
   WHERE trading=1 GROUP by y,m) EOM 
  ON CC.y=EOM.y AND CC.m=EOM.m AND CC.d=EOM.lastd) EOMI 
  WHERE custom_calendar.date = EOMI.date;
-- CHECK
SELECT * FROM custom_calendar ORDER BY date;
SELECT * FROM custom_calendar WHERE eom=1 ORDER BY date;

-------------------------------------------
----- Create a role for the database ------
-------------------------------------------
CREATE USER stockmarketreader WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	CONNECTION LIMIT -1
	PASSWORD 'read123';

-- Grant read rights (on existing tables and views)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO project_user;

-- Grant read rights (for future tables and views)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO project_user;