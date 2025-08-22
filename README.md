# 🏨Hotel-Data-Analysis-Occupancy-Room-Allocation-Optimization (02/2023 - 02/2025)
- Author: Huỳnh Tấn Phát
- Date: /2025
- Tool Used: `SQL`, `PowerBi`
# Table Of Contents (TOCs)
1. **`Background & Overview`**
2. **`Dataset Description`**
3. **`Data Processing by SQL & DAX`**
4. **`Key Insights & Visualizations`**
5.**`Recommendations`**
# Introduction
- A hotel in Vietnam faces business challenges over the past two years, especially about **Occupancy Rate**. By analyzing data, we can provide  **Hotel Mangement Team** with actionable strategies to improve the situation in 2025.
# Dataset Overview
- The dataset contains 6 tables providing insights into booking-related variables (Cofirmed, Pending, Cancelled Bookings), check-in and check-out dates, and customer information such as (Phone, Email). Additionally, it includes **service-related details** (service price, payment type, usage) and **room-related details** (price per night, room type, room number).
# Data processing
Using SQL to detect `Data Anomalies`
  - Identify **booking cases** where the same room number has more than `2 bookings` on the same day => 🚩Flag: Double Booking
  - Detect bookings with **Pending** or **Cancelled** status that still show service usage in the hotel => Update Booking Status
  - Identify cases where the second guest checks in before the first guest has checked out => 🚩Flag: Double Booking

# DAX Calculations & Formulas
Employ some several DAX formulas to calculate **key performance indicators** (KPIs):
<details>
  <summary>Click to view examples of DAX formulas</summary>

  <br>

- **Gross Revenue**:
```dax
Gross Revenue = 
VAR booking_revenue = 
CALCULATE(
    SUMX(booking_table,
    booking_table[price_per_night] * booking_table[stay_duration]))
VAR ancillary_revenue = 
CALCULATE(
    SUMX(detailed_service_usage_table,
    detailed_service_usage_table[price] * detailed_service_usage_table[quantity]))
RETURN 
booking_revenue + ancillary_revenue
```

- **Cancelled Booking**: 

```dax
Cancelled Bookings = 
VAR cancellation = 
CALCULATE(
    COUNTROWS(booking_table),
    FILTER(booking_table,
    booking_table[booking_status] = "Cancelled" &&
    (booking_table[booking_flag] <> "Double Booking" || ISBLANK(booking_table[booking_flag]))))
RETURN
- cancellation
```

- **Revenue Loss**:

```dax
Revenue Loss = 
VAR revenue_loss = 
CALCULATE(
    SUMX(booking_table,
    booking_table[price_per_night] * booking_table[stay_duration]),
    FILTER(booking_table, 
    booking_table[booking_status] = "Cancelled" &&
    (booking_table[booking_flag] <> "Double Booking" ||ISBLANK(booking_table[booking_flag]))
    ))
RETURN
- revenue_loss
```
- **Avg. Length of Stay**: Total Number Of Room Nights / Total Number Of Bookings

```dax
Averge Length of Stay = 
DIVIDE(
    CALCULATE(SUM(booking_table[stay_duration]),
    FILTER(booking_table,
    (ISBLANK(booking_table[booking_flag]) || booking_table[booking_flag] <> "Double Booking") &&
    booking_table[booking_status] = "Confirmed")),
    CALCULATE(COUNTROWS(booking_table),
    FILTER(booking_table,
    booking_table[booking_status] = "Confirmed" &&
    (ISBLANK(booking_table[booking_flag]) || booking_table[booking_flag] <> "Double Booking"))))
```
- **Avg. Daily Rate**: Room Revenues / Room Sold
```dax
Avg Daily Rate (ADR) = DIVIDE(
    CALCULATE(
        SUMX(booking_table,
        booking_table[price_per_night] * booking_table[stay_duration]),
        FILTER(booking_table,
        booking_table[booking_status] = "Confirmed" &&
        (ISBLANK(booking_table[booking_flag]) || booking_table[booking_flag] <> "Double Booking"))),
    CALCULATE(
        SUMX(booking_table,
        booking_table[stay_duration]),
        FILTER(booking_table,
        booking_table[booking_status] = "Confirmed" &&
        (ISBLANK(booking_table[booking_flag]) ||booking_table[booking_flag] <> "Double Booking"))))
```

- **Occupancy Rate**: Rooms Sold / Room Available

```dax
% Occupancy Rate by date = 
  VAR total_occupied_rooms = COUNTROWS('OR Table')
  VAR total_available_rooms = max('OR Table'[available_rooms])
  VAR operation_days = total_available_rooms * DISTINCTCOUNT('OR Table'[curr_check_in])
  RETURN
  DIVIDE(total_occupied_rooms,operation_days)

% Occupancy Rate by Room Type = 
  VAR total_occupied_rooms = COUNTROWS('OR Table')
  VAR available_rooms = MAX('OR Table'[available_room_types])
  VAR operation_days = available_rooms * CALCULATE(DISTINCTCOUNT('OR Table'[curr_check_in]))
  RETURN DIVIDE(total_occupied_rooms, operation_days)

% Occupancy Rate by room_number = 
  VAR total_occupied_rooms = COUNTROWS('OR Table') 
  VAR operation_days = 
    CALCULATE(
        DISTINCTCOUNT('Dim Date'[Date]) * COUNTROWS(VALUES('OR Table'[room_number])))
  RETURN DIVIDE(total_occupied_rooms, operation_days)
```

</details>

# Key Insights 
1. **Booking Trends**: Customer tends to make a reservation in the latter half of the year (especially on Summer | Winter). However, these peak months often have higher cancellation rates than other months.
2. **Cancellations**: On average, there are 18 cancellations per month (around 1-> 4 per day, some spiking to 10). Cancellations accounts for 12% of total bookings, resulting to ~900K in lost potential revenue - but this is not the main reason for the low occupancy rate (%OR).
3. **Gross Revenue**: June, July, September and December show stable revenue over two years. May records the lowest booking and revenue, because customer wants to wait for the peak seasons.
4. **Occupancy Rate**:
- Many rooms remain unsold over 1 - 2 year or are sold at wrong time -> **wasting available room number**
- High or Low ADR is not a problem if there is a right peak-season strategy -> more room would be sold and %OR would be high.
=> If the %OR remains at ~14% in 2025, revenue will lost 3M compared to  %OR (50%)
5. **Room Performance**:
- `Certain room numbers`  have %OR in a month up to 80%, but only 1 - 2 Bookings -> `Long Stay Guests Segment`.
- Some rooms have %OR below 5% or remain unsold for an entire year -> `Short Stay Bookings`.
- Room performance changes over time (e.g: R109 had a good performance in Autumn 2023, but Spring 2024 is better). Bechmark each room's performance over two years (2023 & 2024) to allocate rooms to the right periods.
Root Cause: The low %OR low due to bookings and sold room.
# Recommendations
- Hotel Management:
  1. 
# Conclusion



