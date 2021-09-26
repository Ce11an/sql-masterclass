/*

Question 1

How many total records do we have in the trading.prices table?

*/

SELECT
  COUNT(prices.market_date) AS total_records
FROM trading.prices;

/*

Question 2

How many records are there per ticker value?

*/

SELECT
  prices.ticker,
  COUNT(prices.market_date) AS record_count
FROM trading.prices
GROUP BY prices.ticker
ORDER BY record_count DESC;

/*

Question 3

What is the minimum and maximum market_date values?

*/

SELECT
  MIN(prices.market_date) AS min_date,
  MAX(prices.market_date) AS max_date
FROM trading.prices;

/*

Question 4

Are there differences in the minimum and maximum market_date values for each ticker?

*/

SELECT
  prices.ticker,
  MIN(prices.market_date) AS min_date,
  MAX(prices.market_date) AS max_date
FROM trading.prices
GROUP BY prices.ticker;

/*

Question 5

What is the average of the price column for Bitcoin records during the year 2020?

*/

SELECT
  AVG(prices.price) AS avg
FROM trading.prices
WHERE prices.ticker = 'BTC' AND EXTRACT(YEAR FROM prices.market_date) = 2020;

/*

Question 6
What is the monthly average of the price column for Ethereum in 2020? Sort the output in chronological order and also round the average price value to 2 decimal places.

*/

SELECT
  EXTRACT(MON FROM prices.market_date) AS month_start,
  ROUND(AVG(prices.price)::NUMERIC, 2) AS average_eth_price
FROM trading.prices
WHERE EXTRACT(YEAR FROM market_date) = 2020
GROUP BY month_start
ORDER BY month_start;

/*

Question 7

Are there any duplicate market_date values for any ticker value in our table?

*/

SELECT
  prices.ticker,
  COUNT(prices.market_date) AS total_count,
  COUNT(DISTINCT prices.market_date) AS unique_count
FROM trading.prices
GROUP BY prices.ticker;

/*

Question 8

How many days from the trading.prices table exist where the high price of Bitcoin is over $30,000?

*/

SELECT
  COUNT(prices.market_date) AS row_count
FROM trading.prices
WHERE prices.ticker = 'BTC' AND prices.high > 30000;

/*

Question 9

How many "breakout" days were there in 2020 where the price column is greater than the open column for each ticker?

*/

SELECT
  prices.ticker,
  COUNT(prices.market_date) AS breakout_days
FROM trading.prices
WHERE EXTRACT(YEAR FROM market_date) = 2020 AND prices.price > prices.open
GROUP BY prices.ticker;

/*

Question 10

How many "non_breakout" days were there in 2020 where the price column is less than the open column for each ticker?

*/

SELECT
  prices.ticker,
  COUNT(prices.market_date) AS breakout_days
FROM trading.prices
WHERE EXTRACT(YEAR FROM market_date) = 2020 AND prices.price < prices.open
GROUP BY prices.ticker;

/*

Question 11

What percentage of days in 2020 were breakout days vs non-breakout days? Round the percentages to 2 decimal places

*/

SELECT
  prices.ticker,
  ROUND(SUM(CASE WHEN prices.price > prices.open THEN 1 ELSE 0 END) / COUNT(prices.market_date)::NUMERIC, 2) AS breakout_percentage,
  ROUND(SUM(CASE WHEN prices.price < prices.open THEN 1 ELSE 0 END) / COUNT(prices.market_date)::NUMERIC, 2) AS non_breakout_percentage
FROM trading.prices
WHERE EXTRACT(YEAR FROM prices.market_date) = 2020
GROUP BY prices.ticker;
