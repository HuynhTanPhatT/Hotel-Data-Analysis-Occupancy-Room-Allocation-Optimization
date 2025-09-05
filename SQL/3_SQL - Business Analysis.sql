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
-- Double Booking Cases + Merge Intervals
-- Mục đích: Xác định và gom nhóm các khoảng thời gian Double Booking của từng phòng
WITH double_booking_cases as (
SELECT	booking_id,
		full_name as customer,
		check_in, check_out,
		room_number
FROM hotel_guest_booking
WHERE booking_flag = 'Double Booking' -- Bước 1: Lọc ra các BookingID 'Double Booking'
),
check_in_out_range as (  --Identify Overlapping Records
SELECT	*,
		(CASE 
			WHEN check_in <= lag(check_out) OVER (PARTITION BY room_number ORDER BY check_in) -- Bước 2: Sử dụng LAG(check-out) để so sánh check-in hiện tại với check-out trước đó
			THEN 0 -- Nếu check-in <= check-out (tức nằm trong khoảng thời gian check-out trước đó) -> date_range = 0
			ELSE 1 END) as date_range -- Nếu check-in > check-out (không nằm trong khoảng thời gian check-out trước đó) => Một case mới bắt đầu với 1 (Merge Overlapping Date Ranges)
FROM double_booking_cases
),
group_range as ( -- Identify date Range Groups
SELECT	*,
		SUM(date_range) OVER (PARTITION BY room_number ORDER BY check_in) as group_range -- Bước 3: Sum để gán số case cho từng phòngs
FROM check_in_out_range
),
min_max_intervals as (
SELECT	*,		
		MIN(check_in) OVER (PARTITION BY room_number, group_range) as min_interval, -- Xác định khoảng thời gian của một Case bắt đầu (dựa trên group_range)
		MAX(check_out) OVER (PARTITION BY room_number, group_range) as max_interval -- Xác định khoảng thời gian của một  Case kết thúc (dựa trên group_range)
FROM group_range
)
SELECT	*,
		room_number + '- Case 0' + cast(group_range as varchar(10)) as case_name -- Tạo cột "Tên" (Room + Case) để dễ đọc, thay vì phải nhìn qua check-in và check-out 
FROM min_max_intervals
--WHERE room_number = 'R260'
ORDER BY room_number, check_in asc;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

