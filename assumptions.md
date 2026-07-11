 Assumptions Log
 Project 1; Solar Farm Performance Analysis

Author: Muhammad Imran
Last updated: 06/07/2026
Purpose: This document records every assumption made during data cleaning, KPI calculation, and analysis. Each assumption is numbered, explains the evidence behind it, and states what would change if the assumption were wrong.



 ASSUMPTION 01; DC_POWER Is Stored in Watts, Not Kilowatts

Statement: The DC_POWER column in the raw generation file contains values in watts (W), despite no unit label being provided in the dataset. All DC_POWER values were divided by 1,000 to convert to kilowatts (kW) before any calculation.

Evidence:
The raw DC_POWER maximum is 14,471. The raw AC_POWER maximum is 1,410.95 kW. The ratio is 14,471 divided by 1,410.95, which equals 10.26; approximately 10 times larger. A healthy inverter converts DC to AC at 94–98% efficiency, meaning DC and AC values in the same unit should be nearly equal. A 10 times difference is only consistent with one column being in watts and the other in kilowatts. After dividing DC_POWER by 1,000, the DCtoAC ratio becomes 0.977 (97.7% efficiency), which is within the expected range for a commercialgrade inverter.

What would change if this assumption is wrong:
If DC_POWER were already in kW, then raw values of up to 14,471 kW would represent a 14.5 MW single inverter; far beyond any commercially available unit. This is physically impossible, confirming the watts interpretation is correct.

Cleaning action taken:
`gen['DC_POWER'] = gen['DC_POWER'] / 1000`
Applied before any efficiency calculation.



 ASSUMPTION 02; Total Installed Capacity Is 30,460 kW (30.46 MW)

Statement: The plant's total installed AC capacity is estimated at 30,460 kW, calculated as the sum of the maximum observed AC_POWER output across all 22 inverters.

Calculation:
Each inverter's peak observed AC output was summed: `gen.groupby('SOURCE_KEY')['AC_POWER'].max().sum() = 30,460 kW`. Individual inverter peaks ranged from 1,265 kW (bvBOhCH3iADSZry) to 1,411 kW (wCURE6d3bPkepu2).

Limitation:
The observed peak is a dataderived estimate, not a nameplate capacity figure from the plant's technical specification. The true nameplate capacity may differ slightly if the dataset period did not capture each inverter at its absolute maximum, if some inverters were derated during the period, or if nameplate ratings differ from observed peaks.

Used in: Capacity Factor calculation and Performance Ratio denominator.

What would change if this assumption is wrong:
If actual nameplate capacity is higher, for example 33 MW, the Capacity Factor would decrease from 21.29% to approximately 19.6%. If actual capacity is lower, CF would increase. The relative rankings between days are unaffected ; only the absolute CF percentage changes.



 ASSUMPTION 03; Each Reading Represents a 15-Minute Interval (0.25 Hours)

Statement: Each AC_POWER reading in kilowatts represents the average power output over a 15minute interval. Multiplying by 0.25 hours converts instantaneous power (kW) to energy (kWh).

Formula used throughout:
Energy in kWh = SUM(AC_POWER in kW) × 0.25 hours

Evidence:
The generation file has 3,158 unique timestamps over 34 days, which equals approximately 92.9 timestamps per day per inverter, consistent with 96 readings per day at 15minute intervals accounting for minor gaps. The weather file has 3,182 rows at 15minute intervals across the same 34day period.

What would change if this assumption is wrong:
If readings were 30minute intervals, all energy totals would need to be multiplied by 2. If readings were 5minute intervals, totals would need to be divided by 3. All KPIs expressed in kWh would change proportionally while relative daytoday comparisons would remain the same.



 ASSUMPTION 04; Daytime Is Defined as Hours 6 to 18 (06:00 to 18:00)

Statement: For downtime detection, daytime is defined as any reading where `hour >= 6 AND hour <= 18`. Zero AC_POWER readings outside this window are treated as expected nighttime readings and are not flagged as downtime events.

Rationale:
The irradiation data shows nonzero values between approximately 06:00 and 18:30. Using 06:00–18:00 as the daytime boundary captures all meaningful generation hours while excluding twilight edge readings with very low irradiance.

Impact on downtime calculation:
This definition means a zerooutput reading at 05:45 is not flagged as downtime even if irradiance was marginally positive at that time. This is a conservative approach that avoids false positive downtime flags at the edges of the day.

What would change if this assumption is wrong:
If daytime were defined more broadly as 05:00–19:00, a small number of additional readings during lowirradiance twilight hours might be flagged as potential downtime events, increasing the total downtime count slightly.



 ASSUMPTION 05; The Single Weather Sensor Represents Conditions Across the Entire Array

Statement: The single weather station (SOURCE_KEY: HmiyD2TTLFNqkNe) provides irradiance and temperature readings that are representative of conditions across the entire 30.46 MW plant.

Limitation:
A 30 MW solar plant covers a significant physical area, typically 100–200 hectares. Irradiance and temperature can vary across this area due to localised cloud cover, soiling patterns, or shading from nearby structures. A single sensor at one location may not capture this spatial variation.

Impact on analysis:
All Performance Ratio calculations use this single irradiance reading as the input. If portions of the array experience different irradiance than the sensor location, the PR calculation for those inverters will be slightly distorted.

What would change with multiple sensors:
With one weather sensor per inverter cluster, which is best practice for large plants, Performance Ratio could be calculated at the cluster level, enabling more precise fault localisation than the plantwide PR this analysis provides.



 ASSUMPTION 06; Performance Ratio Uses Rated Capacity as the Denominator

Statement: Performance Ratio is calculated as Total AC Output in kW divided by (Irradiation in kW/m² multiplied by Installed Capacity in kW). The denominator uses the full installed capacity of 30,460 kW and the measured irradiation at Standard Test Condition efficiency.

Rationale:
This follows the IEC 61724 definition of Performance Ratio, the international standard for solar plant performance monitoring. It normalises output for irradiance, enabling meaningful comparison across different days and weather conditions.

Note on PR values above 100%:
31 readings in the dataset show irradiation above 1.0 kW/m², the STC reference value. During these readings, PR can exceed 100%. This is physically valid ; irradiance enhancement from reflected and diffuse light can push measured irradiance above the STC value. These readings are retained and not capped.



 ASSUMPTION 07; Dataset Originates from India, Not Nigeria

Statement: Based on irradiance levels, temperature ranges, and Kaggle dataset documentation, this data is from a solar plant in India. The analysis applies this dataset as a proxy for utilityscale solar analytics.

Why this matters for interpretation:
Indian irradiance levels with a peak of approximately 1.22 kW/m² are broadly similar to Nigerian levels, making the dataset a reasonable analytical proxy. Temperature ranges of 20–35°C ambient are comparable to Nigerian conditions. Capacity Factor benchmarks for India and Nigeria are similar for utilityscale projects at 15–25%. Specific seasonal patterns differ; Nigeria has harmattan and rainy seasons rather than Indian monsoon patterns; and these patterns are not represented in this dataset.

How this is disclosed in the portfolio:
The README, recommendation report, and Tableau dashboard all state that this dataset is from an Indian plant used as a proxy. The analytical methodology, Python code, SQL queries, KPI definitions, and dashboard structure transfer directly to Nigerian solar projects.



 ASSUMPTION 08; The Analysis Period Is Treated as a Standalone Period

Statement: No attempt is made to extrapolate annual generation figures, seasonal patterns, or longterm degradation trends from this 34day dataset. All findings are stated as observations for the specific analysis period only.

Rationale:
34 days spanning parts of two calendar months is insufficient for seasonal analysis. Annualised projections from 34 days carry high uncertainty and are not presented in the main findings. Capacity Factor benchmarks cited in the report are drawn from published industry sources, not extrapolated from this data.



 ASSUMPTION 09; Downtime Count Is Divided by 22 to Get Plant Level Hours

Statement: When counting zerooutput readings during daytime hours, the raw count is divided by 22 (the number of inverters) to convert from inverterreadings to plantlevel hours.

Rationale:
The generation table has 22 rows per timestamp, one per inverter. If all 22 inverters show zero output at 10:00, that represents one plantlevel downtime event of 0.25 hours, not 22 separate 0.25hour events. Dividing by 22 corrects for this multirow structure.

Limitation:
This approach assumes all 22 inverters experience downtime simultaneously. If only some inverters show zero output while others generate normally, the plantlevel count would understate the actual number of stringlevel downtime events. Stringlevel downtime analysis would require filtering by SOURCE_KEY before counting.



 ASSUMPTION 10; Inverter Underperformance Threshold Is Set at 5% Below Plant Average

Statement: An inverter is classified as underperforming if its total generation across the analysis period is more than 5% below the plant average per inverter.

Rationale:
Minor variation between inverters of plus or minus 2–3% is normal due to slight differences in panel string configuration, cabling length, and sensor calibration. A 5% threshold flags meaningful underperformance while avoiding false positives from normal operational variation.

Result under this threshold:
Two out of 22 inverters are flagged:

 bvBOhCH3iADSZry is 9.3% below average
 1BY6WEcLGh8j5v7 is 7.9% below average

What would change with a different threshold:
At a 3% threshold the same two inverters would still be flagged as their gaps are well above 3%. At a 10% threshold only bvBOhCH3iADSZry at 9.3% below average would be flagged.



 ASSUMPTION 11; Temperature Coefficient of 0.4–0.5% per Degree Celsius

Statement: The analysis applies a temperature efficiency penalty of approximately 0.4–0.5% per degree Celsius above 25°C when interpreting module temperature versus performance ratio relationships.

Sources:
This is the published temperature coefficient range for standard crystalline silicon solar panels as specified under IEC 61215, the international design qualification standard for terrestrial PV modules. The range is confirmed by multiple manufacturer datasheets and industry references including Sinovoltaics and 8MSolar.

Validation against actual data:
The theoretical penalty at the maximum observed module temperature of 65.55°C (40.55°C above the 25°C STC baseline) at 0.4% per degree is approximately 16.2%. The measured Performance Ratio drop from 100.1% at moderate temperatures to 89.9% above 55°C; a gap of 10.2 percentage points; is consistent with this range, noting that the 89.9% average is across all readings above 55°C, not just those at the maximum temperature.

Reference:
Sinovoltaics. Measuring the Temperature Coefficient of a PV Module. https://sinovoltaics.com/solarbasics/measuringthetemperaturecoefficientsofapvmodule/

IEC 61215:2016; Terrestrial Photovoltaic Modules: Design Qualification and Type Approval. https://webstore.iec.ch/publication/24312
