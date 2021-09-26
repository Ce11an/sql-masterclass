/*

Question 1

How many records are there in the trading.transactions table?

*/

SELECT
  COUNT(transactions.txn_id) AS record_count
FROM trading.transactions;

/*

Question 2

How many unique transactions are there?

*/

SELECT
  COUNT(DISTINCT transactions.txn_id) AS record_count
FROM trading.transactions;

/*

Question 3

How many buy and sell transactions are there for Bitcoin?

*/

SELECT
  transactions.txn_type,
  COUNT(transactions.txn_id) AS transaction_count
FROM trading.transactions
WHERE transactions.ticker = 'BTC'
GROUP BY transactions.txn_type;

/*

Question 4

For each year, calculate the following buy and sell metrics for Bitcoin:
- total transaction count
- total quantity
- average quantity per transaction
- Also round the quantity columns to 2 decimal places

*/

SELECT
  EXTRACT(YEAR FROM transactions.txn_date) AS txn_year,
  transactions.txn_type,
  COUNT(transactions.txn_id) AS transaction_count,
  ROUND(SUM(transactions.quantity)::NUMERIC, 2) AS total_quantity,
  ROUND(AVG(transactions.quantity)::NUMERIC, 2) AS average_quantity
FROM trading.transactions
WHERE transactions.ticker = 'BTC'
GROUP BY txn_year, txn_type
ORDER BY txn_year, txn_type;

/*

Question 5

What was the monthly total quantity purchased and sold for Ethereum in 2020?

*/

SELECT
  EXTRACT(MON FROM transactions.txn_date) AS calendar_month,
  SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE 0 END) AS buy_quantity,
  SUM(CASE WHEN transactions.txn_type = 'SELL' THEN transactions.quantity ELSE 0 END) AS sell_quantity
FROM trading.transactions
WHERE transactions.ticker = 'ETH' AND EXTRACT(YEAR FROM transactions.txn_date) = 2020
GROUP BY calendar_month
ORDER BY calendar_month;

/*

Question 6

Summarise all buy and sell transactions for each member_id by generating 1 row for each member with the following additional columns:
- Bitcoin buy quantity
- Bitcoin sell quantity
- Ethereum buy quantity
- Ethereum sell quantity

*/

SELECT
  transactions.member_id,
  SUM(CASE WHEN transactions.txn_type = 'BUY' AND transactions.ticker = 'BTC' THEN transactions.quantity ELSE 0 END) AS btc_buy_qty,
  SUM(CASE WHEN transactions.txn_type = 'SELL' AND transactions.ticker = 'BTC' THEN transactions.quantity ELSE 0 END) AS btc_sell_qty,
  SUM(CASE WHEN transactions.txn_type = 'BUY' AND transactions.ticker = 'ETH' THEN transactions.quantity ELSE 0 END) AS eth_buy_qty,
  SUM(CASE WHEN transactions.txn_type = 'SELL' AND transactions.ticker = 'ETH' THEN transactions.quantity ELSE 0 END) AS eth_sell_qty
FROM trading.transactions
GROUP BY transactions.member_id;

/*

Question 7

What was the final quantity holding of Bitcoin for each member? Sort the output from the highest BTC holding to lowest.

*/

SELECT
  transactions.member_id,
  SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END) AS final_btc_holding
FROM trading.transactions
WHERE transactions.ticker = 'BTC'
GROUP BY transactions.member_id
ORDER BY final_btc_holding DESC;

/*

Question 8

Which members have sold less than 500 Bitcoin? Sort the output from the most BTC sold to least.

*/

SELECT
  transactions.member_id,
  SUM(transactions.quantity) AS btc_sold_quantity
FROM trading.transactions
WHERE transactions.txn_type = 'SELL' AND transactions.ticker = 'BTC'
GROUP BY transactions.member_id
HAVING SUM(transactions.quantity) < 500
ORDER BY btc_sold_quantity DESC;


/*

Question 9

What is the total Bitcoin quantity for each member_id owns after adding all of the BUY and SELL transactions from the transactions table?
Sort the output by descending total quantity.

*/

SELECT
  transactions.member_id,
  SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END) AS total_quantity
FROM trading.transactions
WHERE transactions.ticker = 'BTC'
GROUP BY transactions.member_id
ORDER BY total_quantity DESC;

/*

Question 10

Which member_id has the highest buy to sell ratio by quantity?

*/

SELECT
  transactions.member_id,
  SUM(CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE 0 END) / SUM(CASE WHEN transactions.txn_type = 'SELL' THEN transactions.quantity ELSE 0 END) AS buy_to_sell_ratio
FROM trading.transactions
GROUP BY transactions.member_id
ORDER BY buy_to_sell_ratio DESC;

/*

Question 11

For each member_id - which month had the highest total Ethereum quantity sold?

*/

WITH cte_ranked AS (
  SELECT
    transactions.member_id,
    DATE_TRUNC('MON', transactions.txn_date)::DATE AS calendar_month,
    SUM(transactions.quantity) AS sold_eth_quantity,
    RANK() OVER (PARTITION BY transactions.member_id ORDER BY SUM(transactions.quantity) DESC) AS month_rank
  FROM trading.transactions
  WHERE transactions.ticker = 'ETH' AND transactions.txn_type = 'SELL'
  GROUP BY transactions.member_id, calendar_month
)
SELECT
  cte_ranked.member_id,
  cte_ranked.calendar_month,
  cte_ranked.sold_eth_quantity
FROM cte_ranked
WHERE month_rank = 1
ORDER BY sold_eth_quantity DESC;
