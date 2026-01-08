**Hevo Assessment**

Initial Installations:

1) Docker:
  Docker Desktop + wsl2 installed
  Docker version 29.1.3, build f52814d (Screenshots/docker-setup.png)

2) Hevo Trial Account:
   Partner Connect Trail Activated
   Team Name: Jayanth-hevo (Screenshots/hevo-dashboard.png)

3) Snowflake:
   Snowflake account created (Screenshots/snowflake-page.png)

4) ngrok

## Initial Setup (Step-by-Step)
1. Docker Desktop:
   Commands - 
   docker run --name hevo-postgres -e POSTGRES_PASSWORD=hevo123 -p 5432:5432 -d postgres:15 (logical replication not enabled, so removed and added again) <br>
   docker stop hevo-postgres <br>
   docker rm hevo-postgres <br>
   docker run -d --name hevo-postgres -p 5432:5432 -e POSTGRES_PASSWORD=hevo123 postgres:15 -c wal_level=logical -c max_wal_senders=5 -c max_replication_slots=5 <br>

   Verification command - docker exec -it hevo-postgres psql -U postgres -d postgres  <br>
   command 2 - docker ps
   

## Verification
docker exec -it hevo-postgres psql -U postgres -c "SHOW wal_level;" <br>
- logical

### 2. ngrok setup

1. Downlaoded ngrok for windows
   Added Auth Token using command

   ngrok config add-authtoken 37rvoir4Z7MnFCgeXUKqlIOb6tl_AnmoUbfjW3xyv4YCD1rR <br>

2. For ngrok sessions used below command <br>
   ngrok tcp 5432/ ngrok tcp 5433 <br>

   Forwarding link and port numnber: tcp://0.tcp.in.ngrok.io:16619 -> localhost:5433


## 3. PostgreSQL Tables and Data for Assessment

### Create Tables
docker exec -it hevo-postgres psql -U postgres -d postgres <br>

CREATE TABLE customers (
  id INTEGER PRIMARY KEY, 
  first_name VARCHAR(100), 
  last_name VARCHAR(100), 
  email VARCHAR(255), 
  address JSONB 
); <br> <br>

CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  status VARCHAR(50)
); <br> <br>

CREATE TABLE feedback (
  id INTEGER PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  rating INTEGER,
  comments TEXT
); <br> <br>

ALTER TABLE feedback ADD CONSTRAINT feedback_order_id_key UNIQUE(order_id);<br><br>


### 3.1 Data Loading in Postgres
Downloaded CSVs from: https://github.com/muskan-kesharwani-hevo/hevo-assessment-csv <br> <br>

Copying to temporary folder location <br>

docker cp customers.csv hevo-postgres:/tmp/customers.csv <br>
docker cp orders.csv hevo-postgres:/tmp/orders.csv <br>
docker cp feedback.csv hevo-postgres:/tmp/feedback.csv <br>

\copy customers FROM '/tmp/customers.csv' CSV HEADER; <br>
\copy orders FROM '/tmp/orders.csv' CSV HEADER; <br>
\copy feedback FROM '/tmp/feedback.csv' CSV HEADER; <br>

** Issue faced** : while copying feedback table from CSV (Found 79 duplicates!) <br>

Dropped feedback table constraint and truncated tables temporarily -> Then copied data and de-duplicated the feedback table and added constraint back <br>

ALTER TABLE feedback DROP CONSTRAINT IF EXISTS feedback_order_id_key; <br>
TRUNCATE customers, orders, feedback RESTART IDENTITY CASCADE; <br>
\copy customers FROM '/tmp/customers.csv' CSV HEADER; <br>
\copy orders FROM '/tmp/orders.csv' CSV HEADER; <br>
\copy feedback FROM '/tmp/feedback.csv' CSV HEADER; <br>

SELECT 'customers' table_name, COUNT(*) rows FROM customers <br>
UNION ALL SELECT 'orders', COUNT(*) FROM orders <br>
UNION ALL SELECT 'feedback', COUNT(*) FROM feedback; <br>

 table_name | rows  <br>
------------+------ <br>
 customers  |  202  <br>
 orders     |  200  <br>
 feedback   |  121  <br>
(3 rows)

(screenshot - hevo-postgress-count.png)


### 4. Hevo Pipeline Creation
**Assessment - 1**
- Source: PostgreSQL (ngrok tcp://0.tcp.in.ngrok.io:16619) <br>
- Username: hevo-postgress and Password: hevo123 <br>
- Mode: LOGICAL REPLICATION and Tables: customers, orders, feedback  <br>
- Destination: Snowflake HEVO_DB <br>
-Pipeline Name and Info: Postgres SQL Source <br>

Host: 0.tcp.in.ngrok.io
Port: 16619;
User: postgres;
Merge Tables: true;
Database: postgres;
Pipeline Mode: WAL;
Load historical data: true;
Replication Slot: hevo_slot_1767706311065;
Output plugin: test_decoding;
Replicate JSON Fields: Replicate JSON fields to JSON columns;
Include New Objects: true; <br>
- Pipeline ID: [#4] | Team: Jayanth-hevo | URL: https://in.hevodata.com/pipeline/4/overview [Screenshots/Assessment-1-Pipeline.png] <br>

**Assessment - 2**
- Source: PostgreSQL (ngrok tcp://0.tcp.in.ngrok.io:16619) <br>
- Username: hevo-postgress and Password: hevo123 <br>
- Mode: LOGICAL REPLICATION and Tables: customers, orders, feedback  <br>
- Destination: Snowflake HEVO_DB <br>
-Pipeline Name and Info: Postgres SQL Source <br>

Host: 0.tcp.in.ngrok.io;
Port: 16619;
User: postgres;
Merge Tables: true;
Database: postgres;
Pipeline Mode: WAL;
Load historical data: true;
Replication Slot: hevo_slot_1767782840920;
Output plugin: test_decoding;
Replicate JSON Fields: Replicate JSON fields to JSON columns;
Include New Objects: true; <br> <br>

- Pipeline ID: [#6] | Team: Jayanth-hevo | URL: https://in.hevodata.com/pipeline/6/overview [Screenshots/Assessment-2-Pipeline.png] <br>

### 5. Transformations (Python Script - Assessment 1)

Please see this google document for transformation code: https://docs.google.com/document/d/1VrM77M0qohcc3pEtG0DAlkkvs8bUb_RenAZlMl2faww/edit?usp=sharing <br>

The above python code has a logic of extracting the proper usernames before @symbol in the email addresses and also generates events for differnet order statuses.

Deployed the above transformation script -> Restarted the historical load and ran the events manually again for Customers. <br>

#### Transformations (Model Creations - Assessment 2):
I have created a google document for 4 transformation queries used for Models created (Document Link: https://docs.google.com/document/d/1MKrj5-iltZaP1aGJ6HFXHDmZ14Po-bSGT-OXagosO68/edit?usp=sharing) <br> <br>

4 models named: <br>
- Clean Customer Model
- Clean Orders Model
- Clean Products Model
- Final Resultant Model

### 6. Snowflake Validation 
