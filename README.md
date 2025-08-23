# 🏨Hotel Data Analysis: Occupancy & Room Allocation Optimization (02/2023 - 02/2025)
- Author: Huỳnh Tấn Phát
- Date: /2025
- Tool Used: `SQL`, `PowerBi`
# Table Of Contents (TOCs)
1. **`Background & Overview`**
2. **`Dataset Description`**
3. **`Data Processing by SQL & DAX`**
4. **`Key Insights & Visualizations`**
5. **`Recommendations`**
# 📌Background & Overview
## Objective:
📖What is this project about?
- This project aims to build  **PowerBi dashboards** using the `Hotel Booking dataset`, which contains tables providing insights into booking-related variables (Cofirmed, Pending, Cancelled Bookings), check-in and check-out dates. Additionally, it includes **service-related details** (service price, usage) and **room-related details** (price per night, room type, room number). The goal is to provide **Hotel Management Team** with actionable strategies to improve the situation:
    - Understand the current business performance
    - Identify factors affected to Occupancy Rate (%OR)
    - Optimize room allocation on each time (Season, Month,...)

🥷 Who is this project for ?
- Hotel Management Team
  
❓Business Questions:
- What is the current business performance of this hotel ?

🎯Project Outcome:
- x
<img width="1102" height="594" alt="Screenshot 2025-08-22 125115" src="https://github.com/user-attachments/assets/abe31a28-7574-4e32-9d7a-30d0a08804c0" />

# Dataset Description
📌 Data Source:
- Source: Data Group (https://www.facebook.com/groups/666803394396808?multi_permalinks=1289686542108487&hoisted_section_header_type=recently_seen)
- Size: The  table contains 5,000 records.
- Format: CSV (https://invited-lancer-0e5.notion.site/Ph-n-T-ch-D-Li-u-t-Ph-ng-Kh-ch-S-n-19764bc2677380eab70bcaa2c408aeed)
<img width="1618" height="656" alt="image" src="https://github.com/user-attachments/assets/9a0daffb-71cc-467a-b132-a998813ece12" />


# Data Processing by SQL & DAX 
Using SQL to detect `Data Anomalies` (https://github.com/HuynhTanPhatT/Hotel-Data-Analysis-Occupancy-Room-Allocation-Optimization/blob/main/SQL/2_SQL%20-%20Identify%20Data%20Anomaly.sql)
  - Identify **booking cases** where the same room number has more than `2 bookings` on the same day => 🚩Flag: Double Booking
  - Detect bookings with **Pending** or **Cancelled** status that still show service usage in the hotel => Update Booking Status
  - Identify cases where the second guest checks in before the first guest has checked out => 🚩Flag: Double Booking

DAX Calculations & Formulas
- Employ some several DAX formulas to calculate **key performance indicators** (KPIs):
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

# 📊Key Insights & Visualizations
## I. Overview
<img width="1296" height="728" alt="image" src="https://github.com/user-attachments/assets/163cdddb-85a6-433e-9c1e-248876db7db3" />

- The fluctuation of metrocs over the years is not large, but it is enough for us to evaluate the hotel's siatuation up to now, based on months that exceeded the two-year average.
- Firstly, the total number of bookings recorded from (02/2023 -> 02/2025) was **3.700** bookings:
    - Confirmed Bookings: 2.839 bookings (76.37%)
    - Cancelled Bookings: 444 bookings (12%)
    - Pending Bookings: 417 bookings (11.27%)
1. Booking Behavior:
- Customers' booking trends leaned toward the mid to end of the year by months exceeding the average (Jun,Jul, Sep,Oct,Dec) -> A growth trend focused on the high season (Summer, Winter and the period before Tet).
<img width="1101" height="256" alt="Screenshot 2025-08-23 062414" src="https://github.com/user-attachments/assets/a9925375-4a33-401e-a44d-ba27a7fe181f" />

2. Gross Revenue & Cancellations:
- Gross Revenue increased steadily over the years and reached 8.23M, with stable months (Jun, July,Sep,Dec). However, 444 cancellations caused (~901K) in revenue loss.
- Net Revenue distribution by room type: Presidential (~$1.182M), Deluxe(~$1.166M), Executive(~$1.090M), Suite(~$940K), Standard(~$900K)
<img width="1102" height="257" alt="Screenshot 2025-08-23 063353" src="https://github.com/user-attachments/assets/a392691d-2877-40c4-b871-d4835fec3ebf" />
<img width="1094" height="258" alt="Screenshot 2025-08-23 064519" src="https://github.com/user-attachments/assets/87ce8247-c07a-4ece-8a1f-e8770911eac7" />
<img width="1092" height="253" alt="Screenshot 2025-08-23 064541" src="https://github.com/user-attachments/assets/b262f54b-9e70-4b9c-9299-251c63be1563" />

3. ADR & Occupancy Rate:
- ADR ranged from $247 -> $300 showing that hotel did not have a flexible pricing strategy over time, which lead to the uncontrol the price per night for each room compared to the market. As a result, the %OR remained low.
- The occupancy Rate (%OR) was ~14%, which is very low compared to the standard (60-70%), although the hotel has 200 room numbers.
=> **`This is the root cause affecting other metrics (Booking, Revenue, Room Usage, etc)`**.
<img width="1094" height="254" alt="Screenshot 2025-08-23 073302" src="https://github.com/user-attachments/assets/e07a3461-10e5-4d55-8577-83164b69cc13" />
<img width="1095" height="253" alt="Screenshot 2025-08-23 073540" src="https://github.com/user-attachments/assets/e9223ac9-51f3-4164-8958-1dc8e6402032" />

## II. Occupancy Rate (%OR) Analysis
<img width="1297" height="727" alt="image" src="https://github.com/user-attachments/assets/f82957b4-57d5-44a7-be7f-cb403b81c618" />

1. **Booking Trends**: Customer tends to make a reservation in the latter half of the year (especially on Summer | Winter). However, these peak months often have higher cancellation rates than other months.
3. **Cancellations**: On average, there are 18 cancellations per month (around 1-> 4 per day, some spiking to 10). Cancellations accounts for 12% of total bookings, resulting to ~900K in lost potential revenue - but this is not the main reason for the low occupancy rate (%OR).
4. **Gross Revenue**: June, July, September and December show stable revenue over two years. May records the lowest booking and revenue, because customer wants to wait for the peak seasons.
5. **Occupancy Rate**:
- Many rooms remain unsold over 1 - 2 year or are sold at wrong time -> **wasting available room number**
- High or Low ADR is not a problem if there is a right peak-season strategy -> more room would be sold and %OR would be high.
=> If the %OR remains at ~14% in 2025, revenue will lost 3M compared to  %OR (50%)
5. **Room Performance**:
- `Certain room numbers`  have %OR in a month up to 80%, but only 1 - 2 Bookings -> `Long Stay Guests Segment`.
- Some rooms have %OR below 5% or remain unsold for an entire year -> `Short Stay Bookings`.
- Room performance changes over time (e.g: R109 had a good performance in Autumn 2023, but Spring 2024 is better). Bechmark each room's performance over two years (2023 & 2024) to allocate rooms to the right periods.
Root Cause: The low %OR low due to bookings and sold room.

## III> Room Management || Check Room Allocation in months across 2023 & 2024
<img width="1297" height="726" alt="image" src="https://github.com/user-attachments/assets/e4a0ed1c-8457-452f-b2e3-7901d2924002" />


# Recommendations
- 

# Conclusion



