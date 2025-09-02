	/* EDA */
SELECT *
FROM dbo.hotel_guest_booking;
SELECT *
FROM service_usage_info;
SELECT *
FROM payment_table;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Pending		417
   Confirmed	4139
   Cancelled	444 */
select updated_booking_status, count(*)
from hotel_guest_booking
group by updated_booking_status;


SELECT	room_type, 
		count(*) as numbers_rooms
FROM room_table
group by room_type;
/*	Deluxe			40
	Executive		44
	Presidential	45
	Standard		30
	Suite			41 
	Total			200  */
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 /* % Occupancy Rate by Date */
/* Check In < Check Out => Check In + 1 Until Check Out - Check In = 1 */
WITH expand_booking_by_date as (
SELECT	booking_id, room_number, room_type,
		check_in, 
		check_in as curr_check_in, --Thời điểm bắt đầu của một BookingID && + 1 row khi < check out 1 ngày 
		check_out,
		DATEDIFF(DAY, check_in,check_out) as stay_duration
FROM hotel_guest_booking
WHERE (updated_booking_status = 'Confirmed')
AND (booking_flag is null or booking_flag <> 'Double Booking')
UNION ALL
SELECT	booking_id,room_number, room_type,
		check_in,
		DATEADD(DAY,1,curr_check_in) as occupied_check_in_by_bookingID, -- Tăng Ngày + 1 , nếu đáp ứng điều kiện < hơn Check Out hiện tại 1 ngày 
		check_out,
		stay_duration
FROM expand_booking_by_date 
WHERE curr_check_in < DATEADD(day,-1,check_out) -- Dừng đến khi Check Out > Check In 1 ngày 
),
daily_booked_by_check_in as ( --Số phòng đã bán vào từng ngày / trên từng loại phòng 
SELECT	booking_id,
		check_in,
		curr_check_in,	
		check_out,
		room_type,
		room_number -- Đếm số phòng bị chiếm trong ngày 
FROM expand_booking_by_date  --Không thể có số phòng giống nhau bởi vì đã lọc Double Booking
),
total_available_room_segment as (
SELECT	room_type,
		count(room_number) as room_type_rooms
FROM room_table
GROUP BY room_type
)
SELECT	dbb.booking_id,
		check_in,
		dbb.curr_check_in,
		dbb.check_out,
		dbb.room_type,
		tar.room_type_rooms, -- Tổng số phòng có sẵn 
		dbb.room_number,
		(SELECT count(*) FROM room_table) as available_rooms --  Đếm tổng số lượng phòng của từng loại phòng 
FROM daily_booked_by_check_in dbb
JOIN total_available_room_segment  tar
ON dbb.room_type = tar.room_type
ORDER BY dbb.curr_check_in;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
