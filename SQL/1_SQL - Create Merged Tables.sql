----------------------------------------------------------------------------------------------------------------------
/* Merge & Create Tables*/

CREATE TABLE dbo.hotel_guest_booking (
	booking_id INT,
	customer_id INT,
	room_id INT,
    check_in DATE,
    check_out DATE,
    status VARCHAR(50),
    full_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    info_registeration_date DATE,
    room_number VARCHAR(50),
    room_type VARCHAR(100),
    price_per_night DECIMAL(10,2),
    room_status VARCHAR(50)
);

INSERT INTO dbo.hotel_guest_booking
select	BT.booking_id, BT.customer_id, BT.room_id, BT.check_in, BT.check_out, BT.status,
		CT.full_name, CT.email, CT.phone, CT.registeration_date AS info_registeration_date,
		RT.room_number, RT.room_type, RT.price_per_night, RT.status
FROM booking_table BT
LEFT JOIN customer_table CT
ON BT.customer_id = CT.customer_id
JOIN room_table RT
ON BT.room_id = RT.room_id;

CREATE TABLE dbo.service_usage_info (
	usage_id INT,
	booking_id INT,
	service_id INT,
	quantity  INT,
	total_price  INT,
	price  INT,
	service_name VARCHAR(50)
);

INSERT INTO dbo.service_usage_info
SELECT	SUT.*,
		ST.service_name
FROM service_usage_table SUT
LEFT JOIN service_table ST
ON SUT.service_id = ST.service_id;
----------------------------------------------------------------------------------------------------------------------
