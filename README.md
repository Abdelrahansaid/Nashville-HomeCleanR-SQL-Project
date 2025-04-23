---

**📌 Project Name**  
**Nashville-HomeCleanR**

**🔍 Short Description**  
A T-SQL pipeline to clean, standardize, and validate Nashville residential property sales data—preparing it for analysis or downstream modeling.

---

## README.md

```markdown
# Nashville-HomeCleanR

[![SQL Server](https://img.shields.io/badge/Platform-SQL%20Server-blue)](https://www.microsoft.com/sql-server)  
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Table of Contents

1. [Project Overview](#project-overview)  
2. [Motivation](#motivation)  
3. [Data Description](#data-description)  
4. [Cleaning Steps](#cleaning-steps)  
5. [Usage](#usage)  
6. [Schema & Performance](#schema--performance)  
7. [Results](#results)  
8. [Future Work](#future-work)  
9. [Author](#author)  
10. [License](#license)

---

## Project Overview

**Nashville-HomeCleanR** is a T-SQL–based data-cleaning pipeline built to prepare Nashville housing-sales records for analysis. The script standardizes dates, handles missing and duplicate entries, parses and normalizes address components, cleans monetary and categorical fields, and applies final quality checks and indexing.

---

## Motivation

Raw real-estate transaction data often contains:
- Inconsistent date formats  
- Missing or malformed addresses  
- Duplicate records  
- Mixed categorical labels  
- Non-numeric monetary strings  

Cleaning these at the database level accelerates downstream analytics, reporting, and machine-learning workflows, ensuring accuracy and performance.

---

## Data Description

| Column              | Type       | Description                              |
|---------------------|------------|------------------------------------------|
| ParcelID            | INT        | Unique parcel identifier                 |
| SaleDate            | VARCHAR    | Original sale date (various formats)     |
| SaleDateConverted   | DATE       | Standardized sale date                   |
| PropertyAddress     | NVARCHAR   | Full property address                    |
| PropertyStreet      | NVARCHAR   | Street component                         |
| PropertyCity        | NVARCHAR   | City component                           |
| OwnerAddress        | NVARCHAR   | Full owner mailing address               |
| OwnerStreet, City, State | NVARCHAR | Parsed owner address components       |
| SalePrice, LandValue, BuildingValue, TotalValue | MONEY | Numeric values |
| LandUse             | NVARCHAR   | Usage category (e.g. “SINGLE FAMILY”)    |
| YearBuilt           | INT        | Year constructed                         |
| Bedrooms, FullBath, HalfBath | INT  | Unit counts                             |
| LegalReference      | VARCHAR    | Original legal text                      |
| LegalDate, LegalRefNum | DATE, VARCHAR | Parsed legal components           |
| SoldAsVacant        | NVARCHAR   | “Yes”/“No”                               |

---

## Cleaning Steps

1. **Standardize SaleDate**  
   Convert free-form `SaleDate` to `DATE` in `SaleDateConverted`.  
2. **Impute Missing Addresses**  
   Use `ParcelID` joins to fill null `PropertyAddress`.  
3. **Parse Address Components**  
   Split property and owner addresses into street, city, state.  
4. **Normalize Boolean Flags**  
   Map `Y/N` → `Yes/No` in `SoldAsVacant`.  
5. **Remove Duplicates**  
   Delete rows where all key fields match.  
6. **Drop Unused Columns**  
   Remove original address and staging fields.  
7. **Standardize LandUse**  
   Consolidate variations into four categories.  
8. **Validate YearBuilt**  
   Flag out-of-range build years (<1800 or >current year).  
9. **Clean Monetary Fields**  
   Strip `$`, commas → cast to `MONEY`.  
10. **Validate Room Counts**  
    Identify unrealistic bedroom/bath counts.  
11. **Parse LegalReference**  
    Extract date and reference number.  
12. **Data Quality Checks**  
    Summarize remaining nulls in key columns.  
13. **Indexing**  
    Add indexes on `(PropertyStreet, PropertyCity)` and `SaleDateConverted`.

---

## Usage

1. Clone this repo.  
2. Open the T-SQL script `clean_nashville.sql` in SQL Server Management Studio.  
3. Update the database/schema name if needed.  
4. Execute step-by-step or run all at once.  
5. Query `Potfolio_Project.dbo.Nashville_data` for cleaned output.

```sql
SELECT * 
FROM Potfolio_Project.dbo.Nashville_data;
```

---

## Schema & Performance

- **Indexes**  
  - `idx_PropertyAddress` on `(PropertyStreet, PropertyCity)`  
  - `idx_SaleDate` on `SaleDateConverted`  
- **Row count before/after deduplication**  
  - Before: 56477  
  - After: 56373
  - Deleted: 102 
---

## Results

After cleaning, the dataset is:
- Consistent in date and address formats  
- Free of duplicate records  
- Numeric fields properly typed for analysis  
- Ready for BI visualization or ML modeling  

---

## Future Work

- Automate as an SSIS package or Azure Data Factory pipeline  
- Integrate external geocoding API to enrich with latitude/longitude  
- Add data-profiling dashboards (Power BI / Tableau)  
- Build predictive models for price estimation  

---

## Author

**Abdelrahman Said Mohamed**  
Data Science & Analytics Enthusiast  
- LinkedIn: ([Abdelrahman_Said](https://www.linkedin.com/in/abdelrahman-said-mohamed-96b832234/])  
- Email: abdelrahmanalgamil@gmail.com

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
