 Data Dictionary
 Project 1; Solar Farm Performance Analysis

Plant: Plant 1 | PLANT_ID: 4135001
Period: 15 May 2020 – 17 June 2020 (34 days)
Author: Muhammad Imran
Last updated: 06/07/2026



 How to Read This Document

Every column in every file used in this project is defined here ; both the original raw columns from the downloaded files and every derived column added during cleaning and feature engineering. For each column you will find what it means in plain English, its data type and unit, its actual value range from this specific dataset, any cleaning action taken on it, and why it matters for the analysis.



 FILE 1; Plant_1_Generation_Data.csv

Total rows: 68,778
Total columns: 7
Granularity: One row represents one 15-minute power reading from one inverter
Total inverters: 22
Readings per timestamp: 22 (one per inverter simultaneously)



 DATE_TIME

Data type (raw file): String / Object

Data type (after cleaning): datetime64

Null values: 0

Unique timestamps: 3,158

Range: 20200515 00:00 to 20200617 23:45

Recording interval: 15 minutes

Plain English: The exact date and time when the reading was recorded. Each 15minute interval captures one snapshot of power output from every inverter simultaneously.

Data quality issue found: This column contained two different date formats mixed together in the same file. Format 1 used dashes and appeared in 43,628 rows (example: `15052020 00:00`). Format 2 used slashes and appeared in 25,150 rows (example: `1/6/2020 0:00`). Standard `pd.to_datetime()` fails on mixed formats.

Cleaning applied: `pd.to_datetime(df['DATE_TIME'], dayfirst=True, format='mixed')`

Why it matters: Every timebased calculation in this project ; hourly profiles, daily totals, weekoverweek comparisons, downtime detection ; depends on this column being correctly parsed as a datetime type. If left as text, all time operations silently fail or produce wrong results.



 PLANT_ID

Data type: Integer

Null values: 0

Unique values: 1

Value: 4135001 (constant across every row)

Plain English: A numeric identifier for the plant. This dataset contains data for one plant only. Every single row carries the same value.

Cleaning applied: None required.

Why it matters: In a multiplant dataset this column would be used to filter or group by plant. In this singleplant dataset it serves as a foreign key for joining with plantlevel reference tables. Not used in any KPI calculation.



 SOURCE_KEY

Data type: String

Null values: 0

Unique values: 22

Sample values: 1BY6WEcLGh8j5v7, adLQvlD726eNBSB, bvBOhCH3iADSZry

Plain English: A unique alphanumeric identifier for each inverter; its serial number within the dataset. There are 22 distinct inverters in this plant. Every row belongs to exactly one inverter. At any given 15minute timestamp there are 22 rows in the data, one per inverter.

Cleaning applied: None required.

Why it matters: This is the primary grouping column for all inverterlevel analysis. Every inverter comparison, efficiency ranking, and underperformance flag in this project is grouped by SOURCE_KEY. The two underperforming inverters identified in the analysis are `bvBOhCH3iADSZry` (9.3% below plant average) and `1BY6WEcLGh8j5v7` (7.9% below plant average).



 DC_POWER

Data type: Float

Null values: 0

Unit (raw file): Watts (W) ; confirmed by unit mismatch investigation

Unit (after cleaning): Kilowatts (kW)

Raw range: 0 to 14,471.125

Cleaned range: 0.000 to 14.471 kW

Zerovalue rows: 31,951 (night-time and downtime readings)

Plain English: The Direct Current electrical power output produced by the solar panels connected to each inverter, measured before conversion. Solar panels naturally produce DC electricity. The inverter converts this to AC electricity for use on the grid.

Data quality issue found: The raw file stores DC_POWER in watts while AC_POWER is in kilowatts. This was not labeled in the dataset. The mismatch was detected by observing that raw DC_POWER values of up to 14,471 were approximately 10 times larger than AC_POWER values of up to 1,410.95, which is physically impossible for a healthy inverter that should show DC approximately equal to AC. Dividing by 1,000 brings the ratio to the expected 94–98% efficiency range.

Cleaning applied: `gen['DC_POWER'] = gen['DC_POWER'] / 1000`

Why it matters: DC_POWER is the denominator in the inverter efficiency calculation (AC divided by DC). If left in watts the efficiency calculates to 9.77%, which is physically impossible. After correction efficiency calculates to 97.72%, which is normal for a healthy commercial inverter.



 AC_POWER

Data type: Float

Null values: 0

Unit: Kilowatts (kW)

Range: 0.000 to 1,410.950 kW

Mean (nonzero readings): 574.85 kW

Zerovalue rows: 31,951 (nighttime and downtime)

Negative values: 0

Plain English: The Alternating Current electrical power output after the inverter has converted the DC power from the panels. This is the electricity actually delivered to the grid or load. Every generation KPI in this project ; daily yield, capacity factor, performance ratio; is calculated from this column.

Cleaning applied: None required. No negative values, no nulls, no outliers beyond the physical maximum.

Why zeros are correct: At night (approximately 19:00 to 06:00) irradiation is zero and panels produce nothing. These zero readings are legitimate data and must not be interpolated or removed. Only zeros occurring during daylight hours (06:00–18:00) are flagged as potential downtime events.

Why it matters: This is the single most important column in the entire dataset. Everything else supports the analysis of this column.



 DAILY_YIELD

Data type: Float

Null values: 0

Unit: Kilowatthours (kWh)

Range: 0.000 to 9,163.000 kWh

Mean: 3,295.97 kWh

Zerovalue rows: 18,696 (midnight reset readings)

Resets: Yes; resets to 0.000 at midnight each day

Plain English: A running counter of how much energy this specific inverter has generated so far today, starting from zero at midnight. As the sun rises and the inverter generates power, this number climbs. By end of day when generation stops it reaches its daily peak and stays there until midnight when it resets to zero again.

Cleaning applied: None required.

Important usage note: DAILY_YIELD is an accumulated total per inverter per day. For all plantlevel daily generation calculations in this project we used `SUM(AC_POWER)  0.25` rather than DAILY_YIELD, for consistency and full control over the calculation.

Why it matters: Useful for quick sanitychecking of daily totals per inverter. The daily maximum value should approximately equal `SUM(AC_POWER)  0.25` for the same inverter on the same day. Any large discrepancy indicates a data inconsistency.



 TOTAL_YIELD

Data type: Float

Null values: 0

Unit: Kilowatthours (kWh)

Range: 6,183,645.0 to 7,846,821.0 kWh

Mean: 6,978,711.76 kWh

Zerovalue rows: 0

Resets: Never; monotonically increasing since plant commissioning

Plain English: The total cumulative energy this inverter has generated since it was first switched on at the plant ; its lifetime odometer reading. This number never decreases. The difference between TOTAL_YIELD at the start and end of the 34day analysis period equals the energy generated during that period.

Cleaning applied: None required.

Generation range per inverter across 34 days:
 Lowest (least generated): `bvBOhCH3iADSZry`; 218,309 kWh across the period
 Highest (most generated): `adLQvlD726eNBSB`; 249,281 kWh across the period

Why it matters: Useful for calculating total generation over any custom period and for detecting meter resets or data gaps. If TOTAL_YIELD ever decreases between consecutive readings for the same inverter, that is a data integrity flag.



 FILE 2; Plant_1_Weather_Sensor_Data.csv

Total rows: 3,182
Total columns: 6
Granularity: One row represents one 15minute weather reading from one sensor
Total sensors: 1 (one sensor serves the entire 30.46 MW plant)



 DATE_TIME (Weather file)

Data type (raw file): String / Object

Data type (after cleaning): datetime64

Null values: 0

Unique timestamps: 3,182

Range: 20200515 00:00 to 20200617 23:45

Recording interval: 15 minutes

Format in raw file: Slash format only ; example: `5/15/2020 0:00`

Plain English: The exact timestamp of each weather reading. Unlike the generation file, the weather file uses one consistent date format throughout.

Cleaning applied: `pd.to_datetime(df['DATE_TIME'], format='mixed')`

Why it matters: Used as the join key when merging weather and generation data. Both files share the same timestamp range, enabling a clean inner join on this column.



 PLANT_ID (Weather file)

Data type: Integer

Null values: 0

Unique values: 1

Value: 4135001 (constant)

Plain English: Same plant identifier as in the generation file. Confirms both files belong to the same plant. Not used in any calculation.



 SOURCE_KEY (Weather file)

Data type: String

Null values: 0

Unique values: 1

Value: HmiyD2TTLFNqkNe (constant)

Plain English: The unique identifier for the weather sensor. There is only one weather sensor for this entire plant, compared to 22 inverters on the generation side. The single sensor reading is treated as representative of conditions across the entire 30.46 MW array.

Cleaning applied: None required.



 AMBIENT_TEMPERATURE

Data type: Float

Null values: 0

Unit: Degrees Celsius (°C)

Range: 20.40°C to 35.25°C

Mean: 25.53°C

Zerovalue rows: 0

Plain English: The air temperature at the plant site measured at the weather station. This is the temperature of the air surrounding the panels, not the panels themselves. That is MODULE_TEMPERATURE.

Cleaning applied: None required.

Why it matters: Ambient temperature contributes to module temperature but is not the direct cause of efficiency losses. High ambient temperature on a clear day with strong wind results in lower module temperature than the same ambient temperature on a calm day because wind cools the panels. Used as a supporting variable in the temperatureefficiency analysis.



 MODULE_TEMPERATURE

Data type: Float

Null values: 0

Unit: Degrees Celsius (°C)

Range: 18.14°C to 65.55°C

Mean: 31.09°C

Readings above 45°C: 599

Readings above 55°C: 155

Zerovalue rows: 0

Plain English: The actual surface temperature of the solar panels themselves. This is always higher than ambient temperature during daylight hours because panels absorb sunlight; including wavelengths they cannot convert to electricity, which become heat instead.

Cleaning applied: None required.

Why it matters: This is the most direct temperature variable for efficiency analysis. Crystalline silicon panels lose approximately 0.4–0.5% of rated power for every degree Celsius above 25°C (the Standard Test Condition temperature), as defined under IEC 61215. At the maximum observed temperature of 65.55°C ; which is 40.55°C above STC; the theoretical efficiency penalty is approximately 16–20%. The analysis confirmed a measured Performance Ratio drop to 89.9% during readings above 55°C compared to 100.1% at moderate temperatures.



 IRRADIATION

Data type: Float

Null values: 0

Unit: Kilowatts per square metre (kW/m²)

Range: 0.000 to 1.222 kW/m²

Mean (all readings): 0.228 kW/m²

Mean (nonzero readings only): 0.414 kW/m²

Zerovalue readings: 1,425 (nighttime)

Readings above 1.0 kW/m²: 31

Standard Test Condition value: 1.0 kW/m²

Plain English: The intensity of sunlight hitting the panel surface. At midday on a clear day this approaches 1.0 kW/m², which is the standard used to rate panel efficiency. The plant recorded values slightly above 1.0 kW/m² on 31 occasions; this is physically possible due to reflected and diffuse light adding to direct irradiance, known as irradiance enhancement.

Cleaning applied: None required.

Why it matters: This is the primary input variable for the entire analysis. The Pearson correlation between IRRADIATION and total plant AC_POWER output is 0.9925, meaning irradiance alone explains 98.5% of the variation in plant generation. It is also the denominator in the Performance Ratio calculation: `PR = AC_POWER divided by (IRRADIATION × Installed Capacity)`.



 DERIVED COLUMNS ; Added During Cleaning

These columns do not exist in the raw files. They were created during feature engineering in the Jupyter notebook and are present in both clean_generation.csv and clean_weather.csv.



 hour

Data type: Integer

Range: 0 to 23

Derived from: `DATE_TIME.dt.hour`

Plain English: The hour of the day extracted from DATE_TIME. Hour 0 is midnight to 00:59. Hour 12 is noon to 12:59.

Why it was created: Required for every hourly aggregation in SQL (`GROUP BY hour`) and for defining daytime hours in downtime detection (`WHERE hour BETWEEN 6 AND 18`). Without this column, extracting the hour in SQLite requires a string function on every query.



 date

Data type: Date object, stored as text YYYYMMDD in SQLite

Range: 20200515 to 20200617

Unique values: 34

Derived from: `DATE_TIME.dt.date`

Plain English: The calendar date only, with no time component. `20200515 14:30:00` becomes `20200515`.

Why it was created: This is the primary grouping column for all daily aggregations in SQL. The original DATE_TIME column had mixed formats causing inconsistent sorting in SQLite. The date column is always in clean YYYYMMDD format, making every `GROUP BY date` query safe and consistent.



 day

Data type: Integer

Range: 1 to 31

Derived from: `DATE_TIME.dt.day`

Plain English: The day of the month extracted from DATE_TIME. May 15 is 15. June 3 is 3.

Why it was created: Enables dayofmonth analysis and calendarstyle heatmap visualisations in Tableau.



 month

Data type: Integer

Unique values: 2 (May = 5, June = 6)

Derived from: `DATE_TIME.dt.month`

Plain English: The month as a number. Only two months appear in this dataset.

Why it was created: Required for monthly GROUP BY in SQL and monthlevel slicers in Tableau.



 month_name

Data type: String

Unique values: 2 (May, June)

Derived from: `DATE_TIME.dt.strftime('%B')`

Plain English: The month as a readable label ; May or June ; instead of a number.

Why it was created: Used as a display label in Tableau charts. May is more readable than 5 on a dashboard axis.



 year

Data type: Integer

Unique values: 1 (2020 only)

Derived from: `DATE_TIME.dt.year`

Plain English: The calendar year. Only 2020 appears in this dataset. Included for forward compatibility ; if a multiyear dataset were added, this column enables yearoveryear comparisons immediately.



 weekday

Data type: String

Unique values: 7 (Monday through Sunday)

Derived from: `DATE_TIME.dt.day_name()`

Plain English: The full name of the day of the week.

Why it was created: Used in the weekday versus weekend comparison analysis and Tableau filters.



 is_weekend

Data type: Boolean (True or False)

Unique values: 2

Derived from: `DATE_TIME.dt.dayofweek >= 5`

Plain English: True if the reading was taken on a Saturday or Sunday. False for Monday through Friday. Saturday is dayofweek 5, Sunday is dayofweek 6.

Why it was created: Enables direct weekday versus weekend comparison without needing a CASE WHEN expression in every SQL query.



 week

Data type: Integer

Range: 20 to 25 (ISO calendar week numbers)

Unique values: 6

Derived from: `DATE_TIME.dt.isocalendar().week.astype(int)`

Plain English: The ISO calendar week number of the year. Week 20 covers the period beginning 15 May 2020. Week 25 covers the period ending 17 June 2020.

Why it was created: Used for weekoverweek generation trend analysis using the SQL LAG window function.



 inv_efficiency (Generation file only)

Data type: Float

Unit: Ratio ; multiply by 100 for percentage

Valid range: 0.9571 to 1.0664

Mean (valid readings): 0.9772 (97.72%)

Null values: 31,951 (where DC_POWER equals 0)

Derived from: `AC_POWER / DC_POWER` where DC_POWER is greater than 0

Plain English: The ratio of AC power output to DC power input for each inverter reading. A value of 0.977 means the inverter converted 97.7% of the DC electricity from the panels into AC electricity, with the remaining 2.3% lost as heat inside the inverter.

Why nulls are correct: When DC_POWER is 0 at night, dividing by zero is undefined. These rows are set to null intentionally. Null here means efficiency is not calculable because there was no input; it should not be interpolated or filled.

Why it matters: This column is the core diagnostic for inverter health. A healthy inverter shows 94–98% efficiency consistently. Values above 100% are possible and indicate slight sensor calibration variation rather than physically impossible overefficiency.



 MERGED TABLE; solar_merged (SQLite only)

This table was created by merging clean_generation.csv and clean_weather.csv on the DATE_TIME column. It contains all columns from both files in one table, enabling queries that combine generation and weather variables. Used for the irradianceoutput correlation analysis, the temperatureperformance ratio analysis, and the Performance Ratio KPI calculation. Not saved as a CSV ; exists only as a table inside solar.db.
