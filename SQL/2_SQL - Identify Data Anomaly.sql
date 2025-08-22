
/* Tables */
SELECT *
FROM dbo.hotel_guest_booking;
SELECT *
FROM service_usage_info;
SELECT *
FROM payment_table;

/* Check Data Type */
select column_name, data_type
from information_schema.COLUMNS
where table_name = 'hotel_guest_booking' and table_schema = 'dbo';

select column_name, data_type
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'service_usage_info' and TABLE_SCHEMA = 'dbo';

select column_name, data_type
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'payment_table' and TABLE_SCHEMA = 'dbo';
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Identify cases where the same room number has more than 2 bookings on the same day */
with filter_conf as (
SELECT	
		H1.full_name, 
		H1.booking_id, H1.customer_id, H1.room_id,
		H1.check_in, H1.check_out, 
		H1.room_number, H1.room_type, 
		H1.status, H1.room_status, H1.booking_flag
FROM hotel_guest_booking H1
JOIN
		(select check_in, room_number
		from hotel_guest_booking
		group by check_in, room_number
		having count(room_number) >=2 ) H2
ON H1.check_in = H2.check_in
and H1.room_number = H2.room_number),
count_conf_each_date as (
SELECT	*,
		COUNT(check_in) OVER (PARTITION BY check_in, room_number) as count_check_in_confirmed
FROM filter_conf
WHERE status ='Confirmed'
)
SELECT	full_name, booking_id, customer_id, room_id,
		check_in, check_out, 
		room_number, room_type, 
		status, room_status, booking_flag
FROM count_conf_each_date
WHERE count_check_in_confirmed >=2
ORDER BY check_in asc;


/* Create "booking_flag" column & Tag Double Booking for those above cases */
SELECT *
FROM payment_table
WHERE booking_id IN (488, 947, 1765, 105, 4205, 2504, 4948, 2062, 2514, 3220, 1661, 3197, 2547, 2772, 4655, 4789, 2376, 4992, 2353, 2845)
ORDER BY  booking_id asc;

SELECT *
FROM service_usage_info
WHERE booking_id IN (488, 947, 1765,2062, 2514, 1661,  2547,  4789, 4992, 2353) -- No: 488 
ORDER BY booking_id asc;

ALTER TABLE hotel_guest_booking
ADD booking_flag varchar(50);

UPDATE  hotel_guest_booking
SET booking_flag = 'Double Booking'
WHERE booking_id IN (
  488, 947, 1765, 105, 4205, 2504, 4948, 2062, 2514, 3220,
  1661, 3197, 2547, 2772, 4655, 4789, 2376, 4992, 2353, 2845
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Pending & Cancelled status but recorded using service 
	(5,286 rows & 2,507 Unique Booking_ID ) */
SELECT	PT.payment_id, HGB.customer_id, HGB.booking_id, HGB.room_id,
		PT.payment_method, HGB.status as booking_status,
		HGB.check_in, HGB.check_out, PT.payment_date,
		HGB.price_per_night, SUI.service_name, SUI.price, PT.amount as paid
FROM service_usage_info SUI
LEFT JOIN payment_table PT
ON SUI.booking_id = PT.booking_id
JOIN hotel_guest_booking HGB
ON SUI.booking_id = HGB.booking_id
WHERE HGB.status <> 'Confirmed' --and HGB.booking_id = 1
ORDER BY  HGB.customer_id, HGB.check_in asc;


/* Flag those Booking ID in the hotel_guest_booking table */
UPDATE hotel_guest_booking
SET booking_flag = 'Pending/Cancelled But Paid'
WHERE booking_id in (	SELECT	 distinct(HGB.booking_id)
						FROM service_usage_info SUI
						LEFT JOIN payment_table PT
						ON SUI.booking_id = PT.booking_id
						JOIN hotel_guest_booking HGB
						ON SUI.booking_id = HGB.booking_id
						WHERE HGB.status <> 'Confirmed');

/* Update Booking Status */
ALTER TABLE hotel_guest_booking
ADD updated_booking_status VARCHAR(50);

UPDATE hotel_guest_booking
SET updated_booking_status = 
	(CASE
		WHEN booking_id IN (	SELECT	 distinct(HGB.booking_id)
								FROM service_usage_info SUI
								LEFT JOIN payment_table PT
								ON SUI.booking_id = PT.booking_id
								JOIN hotel_guest_booking HGB
								ON SUI.booking_id = HGB.booking_id
								WHERE HGB.status <> 'Confirmed') then 'Confirmed'
	ELSE  hotel_guest_booking.status END);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Recheck Double Booking cases after updating booking status \
	( 105 rows - 52 cases) */
WITH filter_conf as (
SELECT	
		H1.full_name, 
		H1.booking_id, H1.customer_id, H1.room_id,
		H1.check_in, H1.check_out, 
		H1.room_number, H1.room_type, 
		H1.updated_booking_status, H1.room_status, H1.booking_flag
FROM hotel_guest_booking H1
JOIN
		(select check_in, room_number
		from hotel_guest_booking
		group by check_in, room_number
		having count(room_number) >=2 ) H2
ON H1.check_in = H2.check_in
and H1.room_number = H2.room_number
),
count_conf_each_date as (
SELECT	*,
		COUNT(check_in) OVER (PARTITION BY check_in, room_number) as count_check_in_confirmed --phải thêm dòng room_number tránh tình trạng khác booking có room_number khác bị ảnh hưởng
FROM filter_conf
WHERE updated_booking_status ='Confirmed'
)
SELECT	full_name, booking_id, customer_id, room_id,
		check_in, check_out, 
		room_number, room_type, 
		updated_booking_status, room_status, booking_flag
FROM count_conf_each_date
WHERE count_check_in_confirmed >=2 
ORDER BY check_in asc;


UPDATE hotel_guest_booking
SET booking_flag = 'Double Booking'
WHERE booking_id IN (
  488, 947, 105, 1765, 3452, 3558, 4, 1494, 3954, 4158, 4205, 2504, 2693, 3308, 1336, 840,
  2485, 4899, 3921, 7, 2004, 4043, 2253, 3538, 3496, 736, 845, 4344, 4948, 3974, 2062, 1419,
  1453, 2514, 3220, 4598, 601, 1000, 4009, 1619, 3775, 3246, 4733, 1322, 4175, 3757, 921, 543,
  1679, 1661, 3197, 3025, 3935, 4571, 4409, 4829, 3112, 882, 1929, 4979, 4672, 2547, 2772,
  2977, 4115, 4038, 1985, 156, 3433, 369, 2043, 2271, 2305, 2109, 2921, 4655, 4789, 4123, 694,
  4047, 2983, 1522, 2892, 2376, 4992, 4633, 4328, 3603, 932, 2502, 1894, 3425, 4611, 3091,
  4005, 1787, 545, 666, 827, 2845, 2353, 236, 4688, 4475, 2340
)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* A Double Booking Flag:  double booking happens 
when the second guest arrives before the first guest has checked out*/

UPDATE hotel_guest_booking
SET booking_flag = 'Double Booking'
WHere booking_id in (
Select	B1.booking_id
from hotel_guest_booking b1
join hotel_guest_booking b2
on b1.room_number = b2.room_number
and b1.booking_id <> b2.booking_id
and b1.check_in < b2.check_out
and b2.check_in < b1.check_out
and b1.updated_booking_status = 'Confirmed'
and b2.updated_booking_status  = 'Confirmed'
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Update  Room Status: Booked || Available */
select	booking_id, customer_id, room_id,
		check_in, check_out,
		updated_booking_status,
		updated_room_status
from hotel_guest_booking
order by check_in, room_number asc;

ALTER TABLE hotel_guest_booking
ADD updated_room_status VARCHAR(50);

UPDATE hotel_guest_booking
SET updated_room_status = (
	CASE
			WHEN updated_booking_status = 'Confirmed' then 'Booked'
			WHEN updated_booking_status = 'Pending' then 'Available'
			ELSE 'Available' END);
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



