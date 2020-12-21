rm(list=ls(all=T))

require(RPostgreSQL) # did you install this package?
require(DBI)
require(PerformanceAnalytics)
require(xts)
require(dygraphs)


pg = dbDriver("PostgreSQL")
conn = dbConnect(drv=pg
                 ,user="stockmarketreader"
                 ,password="read123"
                 ,host="localhost"
                 ,port=5432
                 ,dbname="stockmarket"
)

cuscal_13_17_qry="SELECT * FROM custom_calendar  
              WHERE date BETWEEN '2012-12-31' AND '2017-12-31'
              ORDER by date"
cuscal_18_qry="SELECT * FROM custom_calendar  
              WHERE date BETWEEN '2017-12-29' AND '2018-03-27'
              ORDER by date"

cuscal_13_17_ccal<-dbGetQuery(conn,cuscal_13_17_qry)
cuscal_18_ccal<-dbGetQuery(conn,cuscal_18_qry)

tickers_13_17_qry = "SELECT ticker,date,adj_close 
                FROM eod_quotes 
                WHERE date BETWEEN '2012-12-31' AND '2017-12-31' and ticker in ('Y', 'YORW','YUM',
'LABL',	'LAD', 'LAMR', 'JAKK', 'JBLU', 'JMBA', 'YELP','YRCW','SCCO','GIS','GLAD','GIII')"

index_13_17_qry = "SELECT symbol,date,adj_close 
                FROM eod_indices 
                WHERE date BETWEEN '2012-12-31' AND '2017-12-31' and symbol = 'SP500TR'"

index_18_qry = "SELECT symbol,date,adj_close 
                FROM eod_indices 
                WHERE date BETWEEN '2017-12-29' AND '2018-03-27' and symbol = 'SP500TR'"

ticker_18_qry = "SELECT ticker,date,adj_close 
                FROM eod_quotes 
                WHERE date BETWEEN '2017-12-29' AND '2018-03-27' and ticker in ('Y','YORW','YUM',
'LABL',	'LAD', 'LAMR', 'JAKK', 'JBLU', 'JMBA', 'YELP','YRCW','SCCO','GIS','GLAD','GIII')"

data_13_17 = dbGetQuery(conn,paste(tickers_13_17_qry,'UNION',index_13_17_qry))

index_18_data = dbGetQuery(conn,index_18_qry)
ticker_18_data = dbGetQuery(conn,ticker_18_qry)
both_18_data = dbGetQuery(conn,paste(index_18_qry,'UNION',ticker_18_qry))

dbDisconnect(conn)

# head(data_13_17)
# tail(data_13_17)
# nrow(data_13_17)
# 
# head(index_18_data)
# tail(index_18_data)
# nrow(index_18_data)
# 
# head(ticker_18_data)
# tail(ticker_18_data)
# nrow(ticker_18_data)

########################################################################################
# 1.	Cumulative return chart for 2013-2017 for the selected stock tickers

# Transform (Pivot) -------------------------------------------------------
trading_days_13_17 = cuscal_13_17_ccal[which(cuscal_13_17_ccal$trading==1),,drop=F]

# Completeness ----------------------------------------------------------
pct = table(data_13_17$ticker)/(nrow(trading_days_13_17)-1)
selected_symbols_daily = names(pct)[which(pct>=0.99)]

data_13_17 = data_13_17[which(data_13_17$ticker 
                                             %in% selected_symbols_daily),,drop=F]

# Transform (Pivot) -------------------------------------------------------
require(reshape2)
data_13_17_pvt = dcast(data_13_17, 
                          date ~ ticker,
                          value.var='adj_close',
                          fun.aggregate = mean, 
                          fill=NULL)


# Merge with Calendar -----------------------------------------------------
data_13_17_pvt_complete = merge.data.frame(x=trading_days_13_17[,'date',drop=F],
                                              y=data_13_17_pvt,by='date',all.x=T)

rownames(data_13_17_pvt_complete) = data_13_17_pvt_complete$date
data_13_17_pvt_complete$date = NULL

# Missing Data Imputation -----------------------------------------------------
require(zoo)
data_13_17_pvt_complete = na.locf(data_13_17_pvt_complete,na.rm=F,fromLast=F,maxgap=3)

# Calculating Returns -----------------------------------------------------
require(PerformanceAnalytics)
data_13_17_ret = CalculateReturns(data_13_17_pvt_complete)

data_13_17_ret = tail(data_13_17_ret,-1) 

# Check for extreme returns -------------------------------------------
colMax <- function(data) sapply(data, max, na.rm = TRUE)
# Apply it
max_tickers_13_17_daily_ret<-colMax(data_13_17_ret)
max_tickers_13_17_daily_ret 
# And proceed just like we did with percentage (completeness)
selected_symbols_daily<-names(max_tickers_13_17_daily_ret)[which(max_tickers_13_17_daily_ret<=1.00)]
length(selected_symbols_daily)

#subset 
data_13_17_ret<-data_13_17_ret[,which(colnames(data_13_17_ret) %in% selected_symbols_daily)]
#check
data_13_17_ret[1:10,] #first 10 rows and first 4 columns 
ncol(data_13_17_ret)
nrow(data_13_17_ret)


tickers_13_17_xts<-as.xts(data_13_17_ret[,c('Y', 'YORW','YUM',
                                            'LABL','LAD', 'LAMR', 
                                            'JAKK', 'JBLU', 'JMBA', 
                                            'YELP','YRCW', 'SCCO',
                                            'GIS','GLAD','GIII'),drop=F])

table.Stats(tickers_13_17_xts)

table.Distributions(tickers_13_17_xts)

table.AnnualizedReturns(tickers_13_17_xts,scale=252)

tickers_13_17_acul_daly = Return.cumulative(tickers_13_17_xts)

dygraph(tickers_13_17_xts, 
        main = 'Tickers Between 2013 And 2017', 
        ylab = 'Return', xlab = 'time')

chart.CumReturns(tickers_13_17_xts,legend.loc='topleft', plot.engine = 'dygraph')

tickers_13_17_acul<-Return.cumulative(tickers_13_17_xts)
tickers_13_17_acul


dygraph(tickers_13_17_xts, 
        main = 'Tickers Between 2013 And 2017', 
        ylab = 'Return', xlab = 'time')

index_13_17_xts<-as.xts(data_13_17_ret[,'SP500TR',drop=F])

index_13_17_acul<-Return.cumulative(index_13_17_xts)
index_13_17_acul

########################################################################################
# 2.	Weights of the optimized portfolio (four digits precision) ----------------------
# and the sum of these weights ---------------------------------------------------------

tickers_13_17_training<-tickers_13_17_xts
index_13_17_training<-index_13_17_xts

#optimize the MV (Markowitz 1950s) portfolio weights based on training
table.AnnualizedReturns(index_13_17_training)
mar<-mean(index_13_17_training) #we need daily minimum acceptable return

require(PortfolioAnalytics)
require(ROI) # make sure to install it
require(ROI.plugin.quadprog)  # make sure to install it
tickers_13_17_spec<-portfolio.spec(assets=colnames(tickers_13_17_training))
tickers_13_17_spec<-add.objective(portfolio=tickers_13_17_spec,type="risk",name='StdDev')
tickers_13_17_spec<-add.constraint(portfolio=tickers_13_17_spec,type="full_investment")
tickers_13_17_spec<-add.constraint(portfolio=tickers_13_17_spec,type="return",return_target=mar)

tickers_13_17_spec_opt<-optimize.portfolio(R=tickers_13_17_training,
                                           portfolio=tickers_13_17_spec,
                                           optimize_method = 'ROI')

tickers_13_17_spec_opt_weight = round(tickers_13_17_spec_opt$weights,4)
tickers_13_17_spec_opt_weight
sum(tickers_13_17_spec_opt_weight)
sum(tickers_13_17_spec_opt$weights)



########################################################################################
# 3 Cumulative return (annualized) chart for the optimized portfolio and SP500TR -
#  index for available 2018 data (approximately 3 months) ------------------------------

trading_days_18 = cuscal_18_ccal[which(cuscal_18_ccal$trading==1),,drop=F]

index_18_pvt = dcast(index_18_data, 
                     date ~ symbol,
                     value.var='adj_close',
                     fun.aggregate = mean, 
                     fill=NULL)

index_18_pvt_complete = merge.data.frame(x=trading_days_18[,'date',drop=F],
                                         y=index_18_pvt,
                                         by='date',
                                         all.x=T)

rownames(index_18_pvt_complete) = index_18_pvt_complete$date
index_18_pvt_complete$date = NULL

index_18_pvt_complete = na.locf(index_18_pvt_complete,na.rm=F,fromLast=F,maxgap=3)

index_18_ret = CalculateReturns(index_18_pvt_complete)

index_18_ret = tail(index_18_ret,-1) 

index_18_xts = as.xts(index_18_ret)

table.Stats(index_18_xts)

table.Distributions(index_18_xts)

table.AnnualizedReturns(index_18_xts,scale=252)

dygraph(index_18_xts, 
        main = 'index in 2018', 
        ylab = 'Return', 
        xlab = 'time')

index_18_acul = Return.cumulative(index_18_xts)
index_18_acul


########################################################################################
# 4. Annualized returns for the portfolio ------------------------------------------
# and SP500TR index for available 2018 data --------------------------------------------
# (approximately 3 months ending on Mar. 27th, 2018) -----------------------------------

pct<-table(both_18_data$symbol)/(nrow(trading_days_18)-1)

selected_symbols_daily<-names(pct)[which(pct>=0.99)]

both_18_data<-both_18_data[which(both_18_data$symbol %in% selected_symbols_daily),,drop=F]

both_18_pvt = dcast(both_18_data, 
                     date ~ symbol,
                     value.var='adj_close',
                     fun.aggregate = mean, 
                     fill=NULL)

both_18_pvt_complete = merge.data.frame(x=trading_days_18[,'date',drop=F],
                                         y=both_18_pvt,
                                         by='date',
                                         all.x=T)

rownames(both_18_pvt_complete) = both_18_pvt_complete$date

both_18_pvt_complete$date = NULL

both_18_pvt_complete = na.locf(both_18_pvt_complete,na.rm=F,fromLast=F,maxgap=3)

both_18_ret = CalculateReturns(both_18_pvt_complete)

both_18_ret = tail(both_18_ret,-1) 

both_18_xts = as.xts(both_18_ret)
tickers_18_xts<-both_18_xts[,c('Y', 'YORW','YUM',
                                            'LABL','LAD', 'LAMR', 
                                            'JAKK', 'JBLU', 'JMBA', 
                                            'YELP','YRCW', 'SCCO',
                                            'GIS','GLAD','GIII'),drop=F]
index_18_xts<-both_18_xts[,'SP500TR',drop=F]

table.Stats(both_18_xts)

table.Distributions(both_18_xts)

both_18_annal_ret = Return.annualized(both_18_xts,scale = 252)
both_18_annal_ret

table.AnnualizedReturns(both_18_xts,scale=252)

dygraph(both_18_xts, 
        main = 'index in 2018', 
        ylab = 'Return', 
        xlab = 'time')

both_18_acul = Return.cumulative(both_18_xts)
both_18_acul

Rp = index_18_xts
Rp$ptf = tickers_18_xts %*% tickers_13_17_spec_opt_weight
chart.CumReturns(Rp,legend.loc = 'topleft')

table.AnnualizedReturns(Rp)

########################################################################################
# 5. Another approach --------------------------------------------------------------------

trading_days_18<-cuscal_18_ccal[which(cuscal_18_ccal$trading==1),,drop=F]

ticker_18_pvt = dcast(ticker_18_data, 
                    date ~ ticker,
                    value.var='adj_close',
                    fun.aggregate = mean, 
                    fill=NULL)

ticker_18_pvt_complete = merge.data.frame(x=trading_days_18[,'date',drop=F],
                                        y=ticker_18_pvt,
                                        by='date',
                                        all.x=T)

rownames(ticker_18_pvt_complete) = ticker_18_pvt_complete$date
ticker_18_pvt_complete$date = NULL

ticker_18_pvt_complete = na.locf(ticker_18_pvt_complete,na.rm=F,fromLast=F,maxgap=3)

ticker_18_ret = CalculateReturns(ticker_18_pvt_complete)

ticker_18_ret = tail(ticker_18_ret,-1) 

ticker_18_xts = as.xts(ticker_18_ret)


charts.PerformanceSummary(both_18_xts, main = 'Index&Tickers in 2018')

charts.PerformanceSummary(Rp, main = 'Index&Tickers in 2018')

chart.RelativePerformance(ticker_18_xts, index_18_xts, 
                          colorset = rainbow8equal, 
                          lwd = 2, 
                          legend.loc = "bottomleft")

chart.RelativePerformance(Rp$ptf, Rp$SP500TR, 
                          colorset = rainbow8equal, 
                          lwd = 2, 
                          legend.loc = "bottomleft")





