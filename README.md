# Hospital Performance Analysis (2016–2020)

This project analyzes hospital performance across the U.S. using multi-year datasets. It was conducted as part of the MET CS 689 Data Warehousing course at Boston University.

---

## 📌 Objective

The goal is to answer five key business questions using metrics such as adverse event rates, risk-adjusted rates, hospital ratings, and geographical distribution:

1. Trend analysis of performance metrics from 2016 to 2020.
2. Regional comparisons of hospital metrics.
3. Correlation between risk-adjusted rates and overall hospital ratings.
4. Comparison of large hospital systems vs independent hospitals.
5. Predictive insights on performance based on hospital type.

---

## 🗂️ Datasets Used

### 1. `csv_hospitalreports1620_odp.csv`
- 21,277 rows, 13 columns
- Contains adverse events, risk-adjusted rates, hospital ratings, etc.

### 2. `us_hospital_locations.csv`
- 7,597 rows, 34 columns
- Hospital type, capacity, location (city, state, lat/long), and system info

---

## 🛠️ Tools & Technologies

- **Python (Pandas, NumPy, SQLAlchemy)**
- **SQL** for ETL + SCD management
- **Lucidchart** for EDR design
- **Tableau** for Data Visualization
- **Jupyter Notebook** for exploration

---

## 📊 Data Modeling

Dimensional modeling includes:

- **Fact Tables**:
  - `FactHospitalPerformance` (snapshot)
  - `FactHospitalTransactions` (transactional)
  - `FactHospitalCumulative` (cumulative)

- **Dimension Tables**:
  - `DimHospital` (SCD Type 2)
  - `DimLocation` (SCD Type 3)
  - `DimTime` (SCD Type 0)
  - `DimPatient`, `DimTreatment`, `DimHospitalSystem`

---

## 🔄 SCD Type 2 Implementation

The `DimHospital` table tracks historical changes using:
- `StartDate`, `EndDate`, `IsActive`
- Preserves old and current records for trend analysis

---

## 📈 Visualizations (Tableau)

- **Line Graph** – Adverse events/rates over time
- **Map View** – Regional hospital performance comparisons
- **Bar Chart** – Hospital type vs. performance metrics

---

## 📎 Included Files

- `FinalProjectReport_SahuShivesh_Project.docx` – Main report
- `SQL/` – Scripts and ETL code (optional upload)
- `ERD.png` – (Optional) EDR diagram
- `Tableau_Visuals/` – Screenshots or .twbx files (optional)

---

## 🙋 Author

**Shivesh Raj Sahu**  
Boston University, MET CS 689 (Spring 2023)  
[LinkedIn Profile](https://www.linkedin.com/in/shivesh-raj-sahu-0555681a6/)  
