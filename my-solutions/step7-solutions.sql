/*

Prep Query

*/

DROP TABLE IF EXISTS temp_portfolio_base;
CREATE TEMP TABLE temp_portfolio_base AS
WITH cte_joined_data AS (
  SELECT
    members.first_name,
    members.region,
    transactions.txn_date,
    transactions.ticker,
    CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END AS adjusted_quantity
  FROM trading.transactions
  INNER JOIN trading.members
    ON transactions.member_id = members.member_id
  WHERE transactions.txn_date <= '2020-12-31'
)
SELECT
  cte_joined_data.first_name,
  cte_joined_data.region,
  (DATE_TRUNC('YEAR', cte_joined_data.txn_date) + INTERVAL '12 MONTHS' - INTERVAL '1 DAY')::DATE AS year_end,
  cte_joined_data.ticker,
  SUM(cte_joined_data.adjusted_quantity) AS yearly_quantity
FROM cte_joined_data
GROUP BY cte_joined_data.first_name, cte_joined_data.region, year_end, cte_joined_data.ticker;

DROP TABLE IF EXISTS temp_cumulative_portfolio_base;
CREATE TEMP TABLE temp_cumulative_portfolio_base AS
SELECT
  temp_portfolio_base.first_name,
  temp_portfolio_base.region,
  temp_portfolio_base.year_end,
  temp_portfolio_base.ticker,
  temp_portfolio_base.yearly_quantity,
  SUM(temp_portfolio_base.yearly_quantity) OVER (
    PARTITION BY temp_portfolio_base.first_name, temp_portfolio_base.ticker
    ORDER BY temp_portfolio_base.year_end
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_quantity
FROM temp_portfolio_base;

/*

Question 1

What is the total portfolio value for each mentor at the end of 2020?

*/

SELECT
  base.first_name,
  ROUND(SUM(base.cumulative_quantity * prices.price)::NUMERIC, 2) AS portfolio_value
FROM temp_cumulative_portfolio_base base
INNER JOIN trading.prices
  ON base.ticker = prices.ticker
  AND base.year_end = prices.market_date
WHERE base.year_end = '2020-12-31'
GROUP BY base.first_name
ORDER BY portfolio_value DESC;

/*

Question 2

What is the total portfolio value for each region at the end of 2019?

*/

SELECT
  base.region,
  ROUND(SUM(base.cumulative_quantity * prices.price)::NUMERIC, 2) AS portfolio_value
FROM temp_cumulative_portfolio_base base
INNER JOIN trading.prices
  ON base.ticker = prices.ticker
  AND base.year_end = prices.market_date
WHERE base.year_end = '2019-12-31'
GROUP BY base.region
ORDER BY portfolio_value DESC;

/*

Question 3

What percentage of regional portfolio values does each mentor contribute at the end of 2018?

*/

WITH cte_mentor_portfolio AS (
  SELECT
    base.region,
    base.first_name,
    ROUND(SUM(base.cumulative_quantity * prices.price)::NUMERIC, 2) AS portfolio_value
  FROM temp_cumulative_portfolio_base base
  INNER JOIN trading.prices
    ON base.ticker = prices.ticker
    AND base.year_end = prices.market_date
  WHERE base.year_end = '2018-12-31'
  GROUP BY base.region, base.first_name
),
cte_region_portfolio AS (
  SELECT
    cte_mentor_portfolio.region,
    cte_mentor_portfolio.first_name,
    cte_mentor_portfolio.portfolio_value,
    SUM(cte_mentor_portfolio.portfolio_value) OVER (PARTITION BY cte_mentor_portfolio.region) AS region_total
  FROM cte_mentor_portfolio
)
SELECT
  cte_region_portfolio.region,
  cte_region_portfolio.first_name,
  ROUND(100 * (cte_region_portfolio.portfolio_value / cte_region_portfolio.region_total), 2) AS contribution_percentage
FROM cte_region_portfolio
ORDER BY cte_region_portfolio.region_total DESC, contribution_percentage DESC;

/*

Question 4

Does this region contribution percentage change when we look across both Bitcoin and Ethereum portfolios independently at the end of 2017?

*/

WITH cte_mentor_portfolio AS (
  SELECT
    base.region,
    base.first_name,
    base.ticker,
    ROUND(SUM(base.cumulative_quantity * prices.price)::NUMERIC, 2) AS portfolio_value
  FROM temp_cumulative_portfolio_base base
  INNER JOIN trading.prices
    ON base.ticker = prices.ticker
    AND base.year_end = prices.market_date
  WHERE base.year_end = '2017-12-31'
  GROUP BY base.region, base.first_name, base.ticker
),
cte_region_portfolio AS (
  SELECT
    cte_mentor_portfolio.region,
    cte_mentor_portfolio.first_name,
    cte_mentor_portfolio.ticker,
    cte_mentor_portfolio.portfolio_value,
    SUM(cte_mentor_portfolio.portfolio_value) OVER (PARTITION BY cte_mentor_portfolio.region, cte_mentor_portfolio.ticker) AS region_total
  FROM cte_mentor_portfolio
)
SELECT
  cte_region_portfolio.region,
  cte_region_portfolio.first_name,
  cte_region_portfolio.ticker,
  ROUND(100 * (cte_region_portfolio.portfolio_value / cte_region_portfolio.region_total)::NUMERIC, 2) AS contribution_percentage
FROM cte_region_portfolio
ORDER BY  cte_region_portfolio.ticker, cte_region_portfolio.region, contribution_percentage DESC;

/*

Question 5

Calculate the ranks for each mentor in the US and Australia for each year and ticker.

*/

WITH cte_ranks AS (
SELECT
  base.year_end,
  base.region,
  base.first_name,
  base.ticker,
  RANK() OVER (PARTITION BY base.region, base.year_end, base.ticker ORDER BY cumulative_quantity DESC) AS ranking
FROM temp_cumulative_portfolio_base base
WHERE base.region IN ('United States', 'Australia')
)
SELECT
  cte_ranks.region,
  cte_ranks.first_name,
  MAX(CASE WHEN cte_ranks.ticker = 'BTC' AND cte_ranks.year_end = '2017-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "BTC 2017",
  MAX(CASE WHEN cte_ranks.ticker = 'BTC' AND cte_ranks.year_end = '2018-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "BTC 2018",
  MAX(CASE WHEN cte_ranks.ticker = 'BTC' AND cte_ranks.year_end = '2019-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "BTC 2019",
  MAX(CASE WHEN cte_ranks.ticker = 'BTC' AND cte_ranks.year_end = '2020-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "BTC 2020",
  MAX(CASE WHEN cte_ranks.ticker = 'ETH' AND cte_ranks.year_end = '2017-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "ETH 2017",
  MAX(CASE WHEN cte_ranks.ticker = 'ETH' AND cte_ranks.year_end = '2018-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "ETH 2018",
  MAX(CASE WHEN cte_ranks.ticker = 'ETH' AND cte_ranks.year_end = '2019-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "ETH 2019",
  MAX(CASE WHEN cte_ranks.ticker = 'ETH' AND cte_ranks.year_end = '2020-12-31' THEN cte_ranks.ranking ELSE NULL END) AS "ETH 2020"
FROM cte_ranks
GROUP BY cte_ranks.region, cte_ranks.first_name
ORDER BY cte_ranks.region, "BTC 2017";
