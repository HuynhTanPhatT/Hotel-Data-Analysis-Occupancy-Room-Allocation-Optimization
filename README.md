 # 🏨Hotel Data Analysis: Occupancy & Room Allocation Optimization (02/2023 - 02/2025)
- Author: Huỳnh Tấn Phát
- Date: 09/2025
- Tool Used: `SQL`, `PowerBi`
# 🧾Table Of Contents (TOCs)
1. [Background & Overview]()
2. [Dataset Description]()
3. [Data Processing (SQL) & Metrics Defination (DAX)]()
4. [Key Insights & Visualizations]()
5. [Recommendations]()
# 📌Background & Overview
## Objective:
📖What is this project about?
This project aims to build a **PowerBi Dashboard** with four pages using the `Hotel Booking Dataset` which includes **booking-related data** (Confirmed Bookings, Pending, Cancelled Bookings), check-in & check-out dates. Additionally, it also has **service-related data** (service price, usage) and **room-related data** (price, room type, room number). The goal is to provide **Hotel Management Team** with data-driven insights to:
  - Understand the current business performance.
  - Identify the root cause of poor Occupancy Rate.
  - Evaluate room allocation & utilization efficiency.

🥷 Who is this project for ?
- Hotel Management Team
- Operation Team

❓Business Questions:
1. What is the hotel's current business performance?
2. Why is the Occupancy Rate below the industry benchmark?
3. Which rooms should be prioritized for improvement?
4. What is the optimal selling time for each room number?

<img width="1149" height="675" alt="image" src="https://github.com/user-attachments/assets/92d53930-dcfc-493c-bb69-4f8adf3effd4" />

# Dataset Description
📌 Data Source:
- Source: Data Group in [Facebook](https://www.facebook.com/groups/666803394396808?multi_permalinks=1289686542108487&hoisted_section_header_type=recently_seen)
- Size: The  table contains 5.000 records.
- Format: [CSV](https://invited-lancer-0e5.notion.site/Ph-n-T-ch-D-Li-u-t-Ph-ng-Kh-ch-S-n-19764bc2677380eab70bcaa2c408aeed)
<img width="1781" height="687" alt="image" src="https://github.com/user-attachments/assets/8ef2af27-b18d-42d6-9afb-41d212977732" />


# Data Processing by SQL & DAX 

1. Using SQL to detect [Data Anomalies](https://github.com/HuynhTanPhatT/Hotel-Data-Analysis-Occupancy-Room-Allocation-Optimization/blob/main/SQL/2_SQL%20-%20Identify%20Data%20Anomaly.sql)
    - Identify **booking cases** where the same room number has more than `2 bookings` on the same day => 🚩Flag: Double Booking
    - Detect bookings with **Pending** or **Cancelled** status that still show service usage in the hotel => Update Booking Status
    - Identify cases where the second guest checks in before the first guest has checked out => 🚩Flag: Double Booking

2. DAX Calculations & Formulas
  - `Employ some several DAX formulas to calculate Key Performance Indicators (KPIs)`:
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
- **Avg. Daily Rate**:
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

- **Occupancy Rate**:

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

  - `Employ some several DAX formulas to calculate Custom Measure`:
<details>
  <summary>Click to view examples of DAX formulas</summary>

  <br>

- **Target Occupancy Rate**: compare %OR in 2023 & 2024 to (Average %OR * 25% (Off Season) || 40%(Peak Season))

```dax
TargetOR = 
VAR Avg_OR = DIVIDE(([11_% OR 2024] + [11_%OR 2023]),2)
VAR Target = 
    SWITCH(
        TRUE(),
        SELECTEDVALUE('Dim Date'[Travel Time]) = "High Season",0.4,
        SELECTEDVALUE('Dim Date'[Travel Time]) = "Off Season", 0.25)
RETURN
Avg_OR * (1 + Target)
```

- **Bad Performance**: The Occupany Rate (%OR) is lower than the Target %OR

```dax
BadPerformance = 
CALCULATE (
    COUNTROWS ('Diff 2024 vs  2023'),
    FILTER('Diff 2024 vs  2023',
    [%OR 2024] < 'Diff 2024 vs  2023'[TargetOR] || [%OR 2024] = 0))
```

- **Good Performance**: The Occupany Rate (%OR) is higher than the Target %OR

```dax
GoodPerformance = 
CALCULATE (
    COUNTROWS ('Diff 2024 vs  2023'),
    FILTER('Diff 2024 vs  2023',
    [%OR 2024] > 'Diff 2024 vs  2023'[TargetOR]))
```

- **Unsold Cases**: A Room Number remained unsold for consecutive months over the past two years(2023 & 2024)
```dax
Unsold_2_years = 
CALCULATE (
    COUNTROWS('Diff 2024 vs  2023'),FILTER('Diff 2024 vs  2023',
    [%OR 2023] = 0 && [%OR 2024] =0))
```

- **Potential Revenue Loss**: The estimated revenue lost due to rooms unoccupied for one or more days

```dax
PotentialRevenueLoss = 
SUMX(
    VALUES('Room Table'[room_number]), 
    VAR price_per_night = MAX('Room Table'[price_per_night])
    VAR total_days = COUNTROWS(VALUES('Dim Date'[Date]))
    VAR actual_room_revenue = [1_Room Revenue]
    RETURN (price_per_night * total_days) - actual_room_revenue)
```

- **Score Method**: A ranking board to evaluate and identify the Top 10 rooms (out of 200) that needs to be prioritized for improvement

```dax
Score = (Value / Highest Value) * 100
Overall Score: Total Score = (Unsold + Bad Performance + Potential Revenue Loss) score / 3
```
</details>

# 📊Key Insights & Visualizations
## I. Overview
<img width="1301" height="730" alt="image" src="https://github.com/user-attachments/assets/ef46418e-6ad0-4bf8-aeb1-45a10b73d9d7" />

- The fluctuation of metrics over the years is not large, but it is enough to evaluate the hotel's siatuation up to now, by comparing months that exceeded the two-year average.
- Firstly, the total number of bookings recorded from (02/2023 -> 02/2025) was **3.700** bookings:
    - Confirmed Bookings: **2.839 bookings** (76.37%)
    - Cancelled Bookings: **444 bookings** (12%)
    - Pending Bookings: **417 bookings** (11.27%)
1. **Booking Behavior**:
    - Customers' booking trends **leaned toward the mid-to-late months of the year** which exceeding the average (Jun,Jul, Sep,Oct,Dec) -> A growth trend focused on the high season (Summer, Winter and the period before Tet).

2. **Gross Revenue** & **Cancellations**:
    - Gross Revenue increased steadily over the years and reached **8.23M**, with stable months (Jun, July,Sep,Dec). However, **444 cancellations** caused (~901K) in revenue loss.
    - Net Revenue distribution by room type: Presidential ($1.182M), Deluxe($1.166M), Executive($1.090M), Suite($940K), Standard($900K)

3. **ADR** & **Occupancy Rate**:
    - ADR remained flat ($247-$300) -> indicating that the management did not adjust the pricing for room numbers to stimute sales.
    - Occupancy Rate (OR): (~14%), below the industry benchmark (60-70%), even with 200 available rooms.

=> **`Low OR is the root cause affecting other metrics: bookings, revenue,etc)`**.


## II. Occupancy Rate (%OR) Analysis
<img width="1299" height="727" alt="image" src="https://github.com/user-attachments/assets/f6999b90-5f54-4f8d-bbde-7464fc73dd13" />

- The reasons for `"Why the Occupancy Rate low"` come from 3 factors: **Cancelled Room Nights**, **Sold Rooms**, and **ADR**.
1. **Cancelled Room Nights**: 2023 (1.599 cancellations) && 2024 (1.645 cancellations) -> This reflects the loss of potential sold rooms as well as revenue for the hotel.
  
2. **Low Sold Rooms**: 2023 (**8.674** room nights) && 2024 (**9.953** room nights)
   - Problem: the hotel has 200 room available per day (200 * 365 days == 73.00 room nights / year) -> The hotel is operating continuously with only 27 rooms to acount the number of sold rooms in 2023 || 2024.

3. **ADR**: The price ranges from ($51 - $500), but the performance of each room is poor across all the price segments -> Despite high/low ADR, it cant improve the %OR.

- **`Why did it happend`** ?
    - No demand stimulation actions: the hotel needs a collaborate from Sales / Marketing to increase the appeareance of the hotel and %OR.
    - Inefficient rooms: Room numbers consistently underperformed.
    - Inflexible pricing strategy: AD remained rigid overtime.

## III> Room Management | Room Allocation & Right-Selling Time
<img width="1302" height="723" alt="image" src="https://github.com/user-attachments/assets/d5ecce06-602f-4290-8970-d50666f83f67" />

- The hotel operates 200 rooms per day, but allocation and selling-time utilization are ineffective.
    - Maintaining a large number of unsold rooms generates high fixed costs to keep them operational
    - Revenue loss from unoccupied rooms over two years and lost revenue from unoccupied rooms

- These inefficiencies come from three custom measures: **Unsold**, **Bad Performance**, **Potential Revenue Loss**.
    - **572** Unsold cases recorded over two years, resulting to **$65M** in `lost revenue from unoccupied rooms` -> (02/2023-02/2025) **Net Revenue** was only ~$7M compared to the ~$65M in potential revenue loss.
    - **1.547** cases of underperforming cases, where Occupancy Rate (%OR) were lower than the target.
    - Only **849** cases achieved good performance

- **`Why did it happen ?`**:
    - Poor seasonality-based allocation -> wrong timing for selling rooms
    - Large operation capacity (200 rooms/day) vs. actual.

=>🚩 Hotel resources have **`remained underutilized for two consecutive years`**. As a result, strong revenue from booked rooms cannot offset this inefficiency, `preventing the hotel from reaching desired profitability levels`.

## IV> Hotel Operation Analysi | Double Booking
<img width="1299" height="727" alt="image" src="https://github.com/user-attachments/assets/fca0896e-2696-42f8-877b-47f694273486" />

<details>
  <summary>Definition for Double Booking Cases</summary>
  <br>

- A **Double Booking** for a Room Number is defined within the period starting from `min(check_in)` to `max(check_out)`.
- All `BookingID`s with overlapping time periods within this period are grouped into the same case.
- If a new `BookingID` has `check_in > check_out` of the previous case → a new case will be created.
<img width="919" height="320" alt="Example - Double Booking Cases" src="https://github.com/user-attachments/assets/64e94803-1959-4b50-b5f2-afb1e5f5dfe5" />

</details>

- The hotel recorded **581** Double Booking cases from **1.300** bookings, with **458** affected customers (90% of the total 500 customers)
- On average, each case lasted 15 days, with some cases prolonged up to 36 days -> showing that many customers booked continuously, `causing overlapping rooms`.

1. **Double Booking Behavior**:
   - Monthly fluctuation: 85-125 cases (30-35% of total boookings).
    
2. **Double Booking Affections**:
   - Top 5 Rooms with the `Most Double Bookings`: R164, R200,R26O,... (6-7 cases /room).
   - Rooms with more Double Booking affect more customers: R260(18 customers), R300(18 customers).

=>This can cause poor experience of customers and detract from the hotel's reputation.
    - Customers receive duplicate room assignments.
    - If a customer refuses the hotel's room re-arrange offer -> the hotel must cover compensation costs (finding another hotel).

3. **Potential Problems**:
    - Staff Error: Forgetting to update the data after changing the customer's room.
    - System Error: Early check-outs not recorded, but the system not recorded. Therefore, the room still be counted as occupied and creating overlap.


# 💡Recommendations

Mục Đích Cốt Lỗi: Kích cầu và tăng %OR bằng mọi cách - nếu %OR không tăng thì đồng nghĩa Khách Sạn luôn chịu lỗ (bởi vì Khách Hàng ít so với tiềm năng Khách Sạn có thể mang lại).

| WHO             | Strategy       | Insight         | Recommendation  |
|:---------------:|:--------------:|:---------------:|:---------------:|
| Hotel Management Team| 1.🚀Dynamic Pricing Strategy| Giá từng phòng rơi vào ($51-$500) và ADR duy trì ($247-$300), nhưng %OR không cải thiện. Chứng tỏ, Khách Sạn không chủ động trong việc quản lý giá để cải thiện %OR | 💡Xây dựng chiến lược “Right-selling time”: điều chỉnh giá theo mùa và chọn thời điểm tối ưu để mở bán / ngưng bán phòng dựa trên dữ liệu đã có.|
| Hotel Management Team| 2. 🏨Room Allocation| Khách Sạn vận hành 200 phòng mỗi ngày, nhưng nhiều phòng vẫn trong tình trạng không bán được hoặc kém hiệu quả trong thời gian dài. Thời điểm phân bổ bán một phòng  chưa hiệu quả.| - 💡 Chiến lược ngắn hạn:  Ưu tiên cải thiện Top 10 phòng kém hiệu suất → giảm ~10% unsold cases.
-💡  Chiến lược dài hạn: Giảm lượng phòng bán lại và tập trung vào phòng có hiệu suất tốt trước.|
| Operation Team| 3. ⚙️Management System|581 trường hợp Double Booking, tất cả đều Confirmed→ Vấn đề về lỗi nhập liệu / không cập nhật lại phòng lên hệ thống. Điều này, có thể làm ảnh hưởng đến trải nghiệm khách hàng & uy tín | - 💡Tích hợp cảnh báo Double Booking tự động: hệ thống phải báo lỗi khi có trùng lặp.
- 💡Kiểm tra & chỉnh quy trình cập nhật phòng: khi khách đổi phòng/check-out sớm phải cập nhật ngay|




1. Room Allocation & Selling Timing
  - Short-term action: A ranking chart (score 0-100) was created to identify the Top 10 `underperforming rooms`, based on the three measures above. By prioritizing these Top 10, **unsold cases** could be reduced by ~10% -> short-term solution.

