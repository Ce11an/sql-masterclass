/*

Question 1

What is the earliest and latest date of transactions for all members?

*/

SELECT
  MIN(transactions.txn_date) AS earliest_date,
  MAX(transactions.txn_date) AS latest_date
FROM trading.transactions;

/*

Question 2

What is the range of market_date values available in the prices data?

*/

SELECT
  MIN(prices.market_date) AS earliest_date,
  MAX(prices.market_date) AS latest_date
FROM trading.prices;

/*

Question 3

Which top 3 mentors have the most Bitcoin quantity as of the 29th of August?

*/

SELECT
  members.first_name,
  SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END) AS total_quantity
FROM trading.transactions
INNER JOIN trading.members
  ON transactions.member_id = members.member_id
WHERE transactions.ticker = 'BTC'
GROUP BY members.first_name
ORDER BY total_quantity DESC
LIMIT 3;

/*

Question 4

What is total value of all Ethereum portfolios for each region at the end date of our analysis? Order the output by descending portfolio value.

*/

WITH cte_eth_latest_price AS (
  SELECT
    prices.ticker,
    prices.price
  FROM trading.prices
  WHERE prices.market_date = '2021-08-29' AND prices.ticker = 'ETH'
)
SELECT
  members.region,
  SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END) * cte_eth_latest_price.price AS ethereum_value
FROM trading.transactions
INNER JOIN cte_eth_latest_price
  ON transactions.ticker = cte_eth_latest_price.ticker
INNER JOIN trading.members
  ON transactions.member_id = members.member_id
GROUP BY members.region, cte_eth_latest_price.price
ORDER BY avg_ethereum_value DESC;

/*

Question 5

What is the average value of each Ethereum portfolio in each region? Sort this output in descending order.

*/

WITH cte_eth_latest_price AS (
  SELECT
    prices.ticker,
    prices.price
  FROM trading.prices
  WHERE prices.market_date = '2021-08-29' AND prices.ticker = 'ETH'
),
cte_calculations AS (
  SELECT
    members.region,
    SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END) * cte_eth_latest_price.price AS ethereum_value,
    COUNT(DISTINCT members.member_id) AS mentor_count
  FROM trading.transactions
  INNER JOIN cte_eth_latest_price
    ON transactions.ticker = cte_eth_latest_price.ticker
  INNER JOIN trading.members
    ON transactions.member_id = members.member_id
  GROUP BY members.region, cte_eth_latest_price.price
)
SELECT
  cte_calculations.region,
  cte_calculations.ethereum_value,
  cte_calculations.mentor_count,
  cte_calculations.ethereum_value / cte_calculations.mentor_count AS avg_ethereum_value
FROM cte_calculations
ORDER BY avg_ethereum_value DESC;
