# Solar Farm Performance Analysis; Plant 1

**A data analytics portfolio project by Muhammad Imran**

[![Tableau Dashboard](https://img.shields.io/badge/Dashboard-Tableau_Public-blue)](https://public.tableau.com/views/SolarPerformanceAnalysis/ExecutiveOverview?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)



## Business Problem

Plant 1 is a 30.46 MW utility-scale solar facility operating 22 inverters. The operations team needed to understand why daily generation varied significantly across the analysis period — ranging from 117,742 kWh on the worst day to 192,894 kWh on the best day, a 64% gap — and whether the underperformance was driven by weather, equipment issues, or both.

This analysis identifies the root causes of that variation, flags two specific underperforming inverters, quantifies thermal efficiency losses, and provides three actionable recommendations to improve plant output.


## Dataset

| File | Rows | Columns | Period |
|---|---|---|---|
| Plant_1_Generation_Data.csv | 68,778 | 7 | 15 May 2020 – 17 June 2020 |
| Plant_1_Weather_Sensor_Data.csv | 3,182 | 6 | 15 May 2020 – 17 June 2020 |

**Source:** [Kaggle — Solar Power Generation Data](https://www.kaggle.com/datasets/anikannal/solar-power-generation-data)

**Plant:** Utility-scale solar facility | 30.46 MW installed capacity | 22 inverters

**Interval:** 15-minute readings

**Note:** Dataset originates from an Indian solar plant used as a proxy for utility-scale solar analysis. The methodology, KPIs, SQL queries, and dashboard structure apply directly to Nigerian and African solar projects.


## Tools Used

| Tool | Purpose |
|---|---|
| Python 3 — pandas | Data cleaning, KPI calculation, feature engineering |
| Python — matplotlib, seaborn | Exploratory data analysis and charts |
| SQLite + DB Browser | SQL analysis — 15 business queries |
| Tableau Public | Interactive 3-page dashboard |
| VS Code + Jupyter Notebook | Development environment |
| GitHub | Version control and portfolio hosting |


## Key Data Quality Findings

During inspection and cleaning, the following issues were identified and resolved:

1. **Mixed datetime formats**: The DATE_TIME column contained two inconsistent formats (`15-05-2020 00:00` and `1/6/2020 0:00`) mixed across 43,628 dash-format rows and 25,150 slash-format rows. Resolved using `pd.to_datetime(format='mixed', dayfirst=True)`.

2. **DC_POWER unit mismatch**: DC_POWER was stored in watts while AC_POWER was in kilowatts. The raw DC_POWER maximum was 14,471 versus AC_POWER maximum of 1,410.95 kW — a 10x discrepancy impossible for a healthy inverter. Resolved by dividing DC_POWER by 1,000 across all rows before any efficiency calculation.

3. **No nulls or duplicates**: Both files had zero missing values and zero duplicate rows across all columns.

4. **Feature engineering**: Added 9 derived columns: hour, date, day, month, month_name, year, weekday, is_weekend, week, and inv_efficiency.


## KPIs Defined and Calculated

| KPI | Formula | Unit | Result |
|---|---|---|---|
| Total Generation | SUM(AC_POWER × 0.25) | MWh | 5,292.51 MWh |
| Average Daily Generation | Total ÷ 34 days | MWh/day | 155.66 MWh |
| Capacity Factor | Actual kWh ÷ (Capacity kW × 24 hrs) | % | 21.29% average |
| Performance Ratio | AC Output ÷ (Irradiance × Capacity) | % | 97.49% average |
| Irradiance Correlation | Pearson R — irradiance vs output | 0 to 1 | 0.9925 |
| Inverter Efficiency | AC_POWER ÷ DC_POWER | % | 97.72% average |
| Underperforming Inverters | More than 5% below plant average | Count | 2 inverters |


## Key Findings

1. **Irradiance is the dominant driver of generation variation.** Pearson R of 0.9925 between irradiance and output confirms 98.5% of generation variance is weather-driven. The plant is responding to solar conditions as expected and no plant-wide equipment failure is indicated.

2. **Two inverters are consistently underperforming.** Inverters `bvBOhCH3iADSZry` (−9.3% vs plant average) and `1BY6WEcLGh8j5v7` (−7.9% vs plant average) underperformed across all 34 days despite showing normal DC-to-AC conversion efficiency of 97.73%, pointing to a string-level issue upstream of the inverter hardware.

3. **High module temperatures reduce efficiency at peak hours.** Performance Ratio drops to 89.9% when module temperature exceeds 55°C, compared to 100.1% at moderate temperatures — a 10.2 percentage point efficiency penalty during peak afternoon hours. Module temperature reached a maximum of 65.55°C across 155 readings.

4. **151.7 MWh of generation was lost across the 5 worst days** compared to what would have been generated at the plant's own 34-day daily average, quantifying the maximum recoverable upside from operational improvements.

5. **Overall plant health is good.** Average Capacity Factor of 21.29% and average Performance Ratio of 97.49% confirm the plant is fundamentally sound. Improvements are targeted, not systemic.


## Recommendations

1. **Immediate: Inspect panel strings on inverters `bvBOhCH3iADSZry` and `1BY6WEcLGh8j5v7`** using IV curve tracing and thermal imaging (infrared drone survey) to identify and correct the string-level underperformance contributing to a 7.9–9.3% generation gap vs the plant average.

2. **Short term: Implement a temperature-triggered cleaning schedule.** Target panel cleaning within 48 hours when the 7-day rolling average of daily peak module temperature exceeds 50°C, to recover the 10.2 percentage point PR drop observed during extreme temperature readings.

3. **Medium term; Deploy irradiance-based generation forecasting** to shift maintenance windows to low-irradiance forecast days, recovering generation currently lost during maintenance scheduled on high-sun days.


## Project Structure

```
Project_1_Solar_Farm/
├── data/
│   ├── raw/
│   │   ├── Plant_1_Generation_Data.csv
│   │   └── Plant_1_Weather_Sensor_Data.csv
│   └── clean/
│       ├── clean_generation.csv
│       └── clean_weather.csv
├── sql/
│   ├── solar.db
│   └── solar_queries.sql
├── notebooks/
│   └── solar_analysis.ipynb
├── dashboard/
│   └── Tableau Public link.txt (see badge above)
├── reports/
│   ├── Solar_Farm_Performance_Report.pdf
│   ├── chart1_daily_generation.png
│   ├── chart2_hourly_profile.png
│   ├── chart3_irradiance_scatter.png
│   ├── chart4_inverter_comparison.png
│   └── chart5_temp_efficiency.png
├── data_dictionary.md
├── assumptions.md
├── requirements.txt
└── README.md
```


## How to Reproduce This Analysis

1. Clone this repository
   ```
   git clone https://github.com/wondermindimran/solar_farm_performance_analysis
   ```

2. Install dependencies
   ```
   pip install -r requirements.txt
   ```

3. Open the notebook
   ```
   cd notebooks
   jupyter notebook solar_analysis.ipynb
   ```

4. Run all cells in order from top to bottom. The clean CSV files will be saved to `data/clean/` and the SQLite database will be created at `sql/solar.db`.

5. Open `sql/solar.db` in DB Browser for SQLite and run the queries from `sql/solar_queries.sql`.

6. Open Tableau Public and connect to `data/clean/clean_generation.csv` and `data/clean/clean_weather.csv` to build or view the dashboard.


## References

1. International Electrotechnical Commission. *IEC 61215:2016 — Terrestrial Photovoltaic Modules: Design Qualification and Type Approval.* Standard Test Condition reference temperature: 25°C. https://webstore.iec.ch/publication/24312

2. Kaggle. *Solar Power Generation Data.* Dataset by Aikannal. https://www.kaggle.com/datasets/anikannal/solar-power-generation-data


## Limitations

- 34 days of data only: insufficient for seasonal or annual analysis
- Dataset originates from India: benchmarks reflect Indian climate and irradiance conditions
- No fault log available: root causes are inferred from data patterns, not confirmed by maintenance records
- Single weather sensor serves the entire 30.46 MW array: spatial variation in irradiance is not captured
- No financial data available: revenue impact is necessary, estimates are indicative only


## Author

**Muhammad Imran**
Data Analyst | SQL, Python, Power BI, Tableau | Interest in renewable energy & sustainability analytics
https://www.linkedin.com/in/muhammad-imran-96318a23b/?lipi=urn%3Ali%3Apage%3Ad_flagship3_detail_base%3BAmVvyhLaR5O%2Fmzll%2FjNVkw%3D%3D
