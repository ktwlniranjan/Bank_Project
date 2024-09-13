
# Developing a Data Warehouse with MSSQL Server and SSIS

In this project, we developed a comprehensive Data Warehouse solution using Microsoft SQL Server, leveraging SQL Server Integration Services (SSIS) for efficient data transformation. The data model follows a star schema structure, designed to optimize query performance and support analytical workloads 

Key Components:
Data Extraction:
We utilized SSIS to extract data from an on-premises SQL Server environment, ensuring a seamless connection to the source systems.

Data Transformation:
The extracted data underwent extensive transformations within SSIS, including data cleansing, deduplication, and formatting, to meet the specific business requirements.

Data Loading:
Transformed data was then loaded into SQL Server. Depending on the data change patterns, we implemented both batch loading and incremental loading to ensure efficiency and accuracy.

Data Partitioning:
To optimize storage and query performance, table partitioning was applied based on date attributes, allowing for more manageable data handling and faster query execution.

Automation & Monitoring:
The entire ETL process was automated using scheduled triggers. In addition, Log Analytics was integrated to monitor performance, track process execution, and manage errors effectively. 



## FAQ

#### What tools were used in the project?

The project utilized Microsoft SQL Server for developing the Data Warehouse and SQL Server Integration Services (SSIS) for handling data extraction, transformation, and loading (ETL) processes.

#### What was the goal of the project?

The primary goal was to perform a data lift & shift while implementing a star schema for data modeling and building a robust Data Warehouse in SQL Server to support business intelligence and reporting.

####  On what basis was the data transformed?

The data transformation was based on specific business requirements, ensuring that the data was cleansed, deduplicated, and formatted to meet the necessary criteria for accurate reporting and analysis.

####  What type of data model was used?

A star schema was implemented to organize the data in the Data Warehouse, optimizing it for querying and reporting in analytical scenarios

#### What kind of business challenges did the solution address?

The solution streamlined the data transformation and loading process, addressed challenges like data consistency, deduplication, and performance optimization, and ultimately enabled better business decision-making through reliable reporting.

## Features

- End-to-End Data Warehouse Development
- Efficient Data Transformation with SSIS
- Batch and Incremental Data Loading
- Business Rule-Based Data Transformation
- Table Partitioning for Performance Optimization
- Automated ETL Execution
- Real-Time Monitoring and Error Handling
- Data Lift & Shift for Improved Architecture
- Scalable and Maintainable Data Architecture


## Authors

- [@ktwlniranjan](https://github.com/ktwlniranjan)

