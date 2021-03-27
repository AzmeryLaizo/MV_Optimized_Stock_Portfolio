# MV_Optimized_Stock_Portfolio
Using PostgreSQL and R, a mean-variance optimized portfolio was developed for 15 stock tickers and compared to the SP500TR benchmark to analyze performance of the portfolio.
ETL processes were performed on the Quandl Wiki and SP500TR datasets in PostgreSQL. A custom calendar was created in MS Excel and imported into PostgreSQL to query the stock ticker prices for trading days.
RPostgreSQL and DBI packages were used in RStudio to create a connection to PostgreSQL data tables. Further analysis was done in R using PerformanceAnalytics, PortfolioAnalytics, ROI, and ROI.plugin.quadprog packages.

Data Sources
The data used in this analysis are the SP500TR index and the historical Quandl Wiki dataset. 
The SP500TR data set was retrieved form the Yahoo’s finance website. The dataset contained the S&P 500 stocks' historical performance within the time frame of 2013 
to 2018. https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC

The Quandl dataset contains the historical ticker information of the portfolio that is compared to the SP500TR data set. 
Retrieved from https://www.quandl.com/
