# 🏗️ End-to-End Azure Data Engineering Pipeline

![Azure](https://img.shields.io/badge/Azure-Data%20Factory-0078D4?logo=microsoftazure&logoColor=white)
![Databricks](https://img.shields.io/badge/Azure-Databricks-FF3621?logo=databricks&logoColor=white)
![Synapse](https://img.shields.io/badge/Azure-Synapse%20Analytics-0078D4?logo=microsoftazure&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![License](https://img.shields.io/badge/license-MIT-green)

## 📌 Project Overview

This project implements a fully automated, cloud-native **Medallion Architecture** (Bronze → Silver → Gold) data pipeline on Microsoft Azure. Raw data is ingested from a public GitHub repository via HTTP, progressively transformed and refined across layers, and ultimately served to a Power BI dashboard for business intelligence reporting.

The pipeline demonstrates real-world data engineering patterns including dynamic ingestion, schema-on-read, incremental transformation using Apache Spark, serverless SQL querying, and scalable analytical reporting.

---

## 🏛️ Architecture Overview

```
GitHub (CSV Source)
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│               Azure Data Factory (ADF)                   │
│   HTTP Linked Service  →  ForEach Pipeline (12 files)    │
│              Lookup Activity (JSON config)               │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│          Azure Data Lake Storage Gen2 (ADLS Gen2)        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Bronze    │  │   Silver    │  │      Gold       │  │
│  │  (Raw CSV)  │  │ (Parquet)   │  │  (Views/Tables) │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└──────────────────────────────────────────────────────────┘
        │                   │                   │
        │                   ▼                   ▼
        │     ┌─────────────────────┐   ┌────────────────────┐
        │     │  Azure Databricks   │   │  Azure Synapse     │
        │     │  (PySpark / .ipynb) │   │  Analytics         │
        │     │  Transformations    │   │  (Serverless SQL)  │
        │     └─────────────────────┘   └────────┬───────────┘
        │                                        │
        │                                        ▼
        │                               ┌────────────────────┐
        └──────────────────────────────►│    Power BI        │
                                        │    Dashboard       │
                                        └────────────────────┘
```

---

## 📂 Repository Structure

```
├── bronze/
│   ├── pipeline/
│   │   ├── adf_pipeline_config.json          # ADF ForEach pipeline config (file list)
│   │   └── screenshots/
│   │       ├── 01_adf_pipeline_overview.png
│   │       ├── 02_http_linked_service.png
│   │       ├── 03_lookup_activity_config.png
│   │       ├── 04_foreach_activity.png
│   │       └── 05_adls_bronze_container.png
│
├── silver/
│   ├── notebooks/
│   │   ├── transformation_[dataset_name].ipynb   # One notebook per dataset
│   │   └── ...
│   └── screenshots/
│       ├── 06_databricks_workspace.png
│       ├── 07_entra_app_registration.png
│       ├── 08_spark_config_connection.png
│       └── 09_silver_parquet_output.png
│
├── gold/
│   ├── sql_scripts/
│   │   ├── 01_create_schema.sql
│   │   ├── 02_create_views.sql
│   │   ├── 03_create_external_tables.sql
│   │   ├── 04_create_managed_tables.sql
│   │   └── 05_cetas_statements.sql
│   └── screenshots/
│       ├── 10_synapse_workspace.png
│       ├── 11_serverless_pool_query.png
│       ├── 12_gold_container_output.png
│       └── 13_powerbi_dashboard.png
│
├── docs/
│   └── architecture_diagram.png
│
└── README.md
```

---

## 🔶 Layer 1 — Bronze (Raw Ingestion)

**Services Used:** Azure Data Factory, Azure Data Lake Storage Gen2

### What Was Built

- Configured **ADLS Gen2** with a hierarchical namespace and three containers: `bronze`, `silver`, and `gold`.
- Created an **HTTP Linked Service** in Azure Data Factory to connect to a public GitHub repository as the data source.
- Built a **dynamic, reusable ADF pipeline** using:
  - A **Lookup Activity** that reads a JSON configuration file listing all 12 CSV file names and their source URLs.
  - A **ForEach Activity** that iterates over the JSON array and triggers a parameterised Copy Activity for each file.
  - A **Copy Activity** (inside ForEach) using HTTP as source and ADLS Gen2 as sink, landing raw CSV files into the `bronze/` container.

### Key Concepts Applied

- **Parameterisation:** No hardcoded file names — all paths are driven by the JSON config, making the pipeline extensible (add more files by editing the config only).
- **Linked Services:** Separate linked services for HTTP (GitHub) and ADLS Gen2 ensure clean separation of concerns and reusability.
- **Schema-on-read:** Raw data is stored as-is in CSV format; no transformation at this stage to preserve data lineage and support reprocessing.

### Pipeline Screenshot Placement

| Screenshot | Description |
|---|---|
| `01_adf_pipeline_overview.png` | Full canvas view of the ADF pipeline (Lookup → ForEach → Copy) |
| `02_http_linked_service.png` | HTTP linked service configuration pointing to GitHub |
| `03_lookup_activity_config.png` | Lookup activity reading the JSON file list from ADLS |
| `04_foreach_activity.png` | ForEach settings and inner Copy Activity with dynamic expressions |
| `05_adls_bronze_container.png` | ADLS Gen2 `bronze` container showing all 12 ingested CSV files |

---

## 🥈 Layer 2 — Silver (Transformation)

**Services Used:** Azure Databricks, Apache Spark (PySpark), Microsoft Entra ID

### What Was Built

- Registered an **App (Service Principal)** in **Microsoft Entra ID** (formerly Azure Active Directory) and granted it **Storage Blob Data Contributor** access on ADLS Gen2.
- Configured **Databricks** to authenticate to ADLS Gen2 using the Service Principal via **OAuth 2.0 / Client Credentials flow**, passing `client_id`, `tenant_id`, and `client_secret` through Spark configuration (`spark.conf.set`).
- Loaded each CSV from the `bronze/` container as a **Spark DataFrame** and applied transformations, then wrote the output as **Parquet** to the `silver/` container.

### Transformations Applied (per dataset)

- **Aggregations** — group-by summaries, totals, averages using `groupBy()` and `agg()`
- **Column creation** — derived columns using `withColumn()` and Spark SQL expressions
- **Row splitting** — unpivoting or exploding nested/concatenated values into normalised rows
- **Data type casting** — enforcing correct schema types (dates, integers, decimals)
- **Data cleaning** — null handling (`dropna`, `fillna`), deduplication (`dropDuplicates`), trimming whitespace
- **Renaming and reordering** — standardised column naming conventions

### Why Parquet?

Parquet is a columnar storage format that offers significant compression and query performance advantages over CSV, making it the industry-standard format for data lake Silver layers.

### Screenshot Placement

| Screenshot | Description |
|---|---|
| `06_databricks_workspace.png` | Databricks workspace with cluster running |
| `07_entra_app_registration.png` | Microsoft Entra app registration showing client ID and permissions |
| `08_spark_config_connection.png` | Notebook cell with Spark config connecting to ADLS Gen2 |
| `09_silver_parquet_output.png` | ADLS Gen2 `silver` container showing Parquet output files |

---

## 🥇 Layer 3 — Gold (Serving Layer)

**Services Used:** Azure Synapse Analytics, Serverless SQL Pool, Dedicated SQL Pool

### What Was Built

- Created an **Azure Synapse Analytics Workspace** and established a linked service connection to ADLS Gen2.
- Provisioned both a **Dedicated SQL Pool** (for high-performance, reserved compute workloads) and a **Serverless SQL Pool** (for cost-effective, on-demand querying of the data lake).
- Used **Serverless SQL Pool** to query Parquet files in the `silver/` container directly via `OPENROWSET`.
- Wrote SQL scripts to build a structured serving layer:

| Object | Purpose |
|---|---|
| **Schema** | Logical namespace to organise Gold layer objects |
| **Views** | Lightweight abstractions over `OPENROWSET` queries on Silver Parquet files |
| **External Tables** | Named, queryable table objects pointing to ADLS Gen2 files, requiring an external data source and file format definition |
| **Managed Tables** | Tables with data physically stored within Synapse-managed storage |
| **CETAS (CREATE EXTERNAL TABLE AS SELECT)** | Materialises query results from Silver back into the `gold/` container as Parquet, enabling downstream consumers to query optimised, pre-aggregated data |

- Connected **Power BI Desktop** to Synapse using the **Serverless SQL Endpoint**, imported Gold layer views/tables, and built an interactive dashboard with visuals and slicers.

### Screenshot Placement

| Screenshot | Description |
|---|---|
| `10_synapse_workspace.png` | Synapse Studio overview with linked ADLS Gen2 |
| `11_serverless_pool_query.png` | SQL script using OPENROWSET to query Silver Parquet |
| `12_gold_container_output.png` | ADLS Gen2 `gold/` container with CETAS output files |
| `13_powerbi_dashboard.png` | Completed Power BI dashboard with visuals |

---

## 🔐 Security & Access Management

| Component | Mechanism |
|---|---|
| Databricks → ADLS Gen2 | Service Principal (Microsoft Entra ID) with OAuth 2.0 |
| ADF → ADLS Gen2 | Managed Identity or Linked Service with access key |
| Synapse → ADLS Gen2 | Managed Identity with Storage Blob Data Reader role |
| Power BI → Synapse | Serverless SQL Endpoint (AAD authentication) |

> **Best Practice:** Secrets (`client_secret`, storage account keys) should be stored in **Azure Key Vault** and referenced via Key Vault-backed Databricks Secrets Scope or ADF parameter, never hardcoded in notebooks or pipelines.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Orchestration | Azure Data Factory (ADF) |
| Storage | Azure Data Lake Storage Gen2 (ADLS Gen2) |
| Transformation | Azure Databricks (PySpark) |
| Serving | Azure Synapse Analytics (Serverless + Dedicated SQL Pool) |
| Visualisation | Microsoft Power BI |
| Identity & Access | Microsoft Entra ID (Service Principal / Managed Identity) |
| File Formats | CSV (Bronze), Parquet (Silver & Gold) |
| Notebook Format | Jupyter / `.ipynb` |

---

## 🚀 How to Reproduce

1. **Provision Azure Resources**
   - Create a Resource Group
   - Deploy ADLS Gen2 with hierarchical namespace enabled; create `bronze`, `silver`, `gold` containers
   - Deploy Azure Data Factory, Azure Databricks, Azure Synapse Analytics workspaces

2. **Configure Identity & Access**
   - Register an App in Microsoft Entra ID; note `client_id`, `tenant_id`, `client_secret`
   - Assign **Storage Blob Data Contributor** to the Service Principal on ADLS Gen2

3. **Bronze — Run ADF Pipeline**
   - Import the linked services and pipeline definitions from `bronze/pipeline/`
   - Upload `adf_pipeline_config.json` to ADLS Gen2
   - Trigger the pipeline and verify 12 CSV files appear in the `bronze/` container

4. **Silver — Run Databricks Notebooks**
   - Import `.ipynb` notebooks from `silver/notebooks/` into your Databricks workspace
   - Update the Spark config cells with your `client_id`, `tenant_id`, `client_secret`, and storage account name
   - Run each notebook; verify Parquet files appear in `silver/`

5. **Gold — Run Synapse SQL Scripts**
   - Open Synapse Studio → Develop → New SQL Script
   - Run scripts in order: schema → external data source → file format → views → external tables → CETAS
   - Verify output in the `gold/` container

6. **Power BI — Connect & Visualise**
   - Open Power BI Desktop → Get Data → Azure → Azure Synapse Analytics (SQL DW)
   - Enter the Serverless SQL Endpoint URL from your Synapse workspace
   - Load the Gold layer views/tables and build your report

---

## 📊 Dataset

- **Source:** [Your GitHub repository / dataset name here]
- **Files:** 12 CSV files covering [describe domain, e.g., sales transactions, population data, etc.]
- **Volume:** [Add approximate row count / file sizes if known]

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙋 Author

**[Thando Manciya]**  
Data Engineer | Azure | PySpark | SQL  
[LinkedIn]() · [GitHub](https://github.com/TManciya)
