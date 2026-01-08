SELECT * FROM order_events; -- This table is created by python transformation script used for assessment 1 <br> [Screenshots/Assessment-1-Order-Events.png]

Select * from order_events
order by __hevo__ingested_at DESC
LIMIT 200; -- Loaded a couple of times to check transformation, So limiting the records to 200

SELECT * from customers
where username is not null; -- This table now has one extra colum for username - Python script transformation result <br> [Screensots/Assessment-1-Username-Field.png] <br>

SELECT COUNT(*) from CUSTOMERS; -- Displays the count