-- Query 1: Value Tier & Behavioral Segmentation Profile:- distinguished customers based on frequency and loyalty
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(eltv),2) as avg_eltv,
    ROUND(AVG(`Previous Purchases`), 2) as avg_tenure,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS promo_code_used
FROM customers_enriched
GROUP BY segment
ORDER BY customer_count DESC;
-- Query-2 : observed the effect of subsriptions on customer long term value and pronmo code usage
SELECT
    segment,
    `Subscription Status`,
    COUNT(*) AS count,
    ROUND(AVG(eltv), 2) AS avg_eltv,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS promo_rate_pct
FROM customers_enriched
GROUP BY segment, `Subscription Status`
ORDER BY segment, `Subscription Status`;
-- Query 3: here we see the effect of different mode of payments vs avg spend and long term value
SELECT
    `Payment Method`,
    COUNT(*) AS count,
    ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS promo_rate_pct,
    ROUND(AVG(eltv), 2) AS avg_eltv
FROM customers_enriched
GROUP BY `Payment Method`
ORDER BY avg_spend DESC;
-- Query 4 : Identifies entry point categories for customer acquisition vs. mature retention anchors.
SELECT
    Category,
    CASE
        WHEN `Previous Purchases` < 10  THEN '1_new (1–9)'
        WHEN `Previous Purchases` < 30  THEN '2_mid (10–29)'
        ELSE                             '3_veteran (30–50)'
    END AS tenure_cohort,
    COUNT(*) AS count,
    ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend
FROM customers_enriched
GROUP BY Category, tenure_cohort
ORDER BY Category, tenure_cohort;
-- Query 5: Seasonal Promo Training & Order Densities
SELECT
    Season,
    COUNT(*) AS count,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS promo_rate_pct,
    ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend,
    SUM(`Discount Applied`) AS discount_count
FROM customers_enriched
GROUP BY Season
ORDER BY promo_rate_pct DESC;
-- Query 6: Category Discount Elasticity & Premium Gap:Quantifies net margin bleed by directly contrasting full-price sales vs. markdown conversions and Isolates revenue-draining categories from volume multipliers (like Footwear) where sales lift tickets
SELECT
    Category,
    ROUND(AVG(CASE WHEN `Discount Applied` = 1 THEN `Purchase Amount (USD)` END), 2) AS avg_spend_discounted,
    ROUND(AVG(CASE WHEN `Discount Applied` = 0 THEN `Purchase Amount (USD)` END), 2) AS avg_spend_full_price,
    ROUND(AVG(CASE WHEN `Discount Applied` = 0 THEN `Purchase Amount (USD)` END)
        - AVG(CASE WHEN `Discount Applied` = 1 THEN `Purchase Amount (USD)` END), 2) AS full_price_premium
FROM customers_enriched
GROUP BY Category
ORDER BY full_price_premium DESC;
-- Query-7: performed geography based calculating the area with high demand of new stores based on customer count , avg_eltv and discount usage
SELECT
    Location AS state,
    COUNT(*) AS customer_count,
    ROUND(AVG(eltv), 2) AS avg_eltv,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS promo_rate_pct,
    ROUND(AVG(eltv) * (1 - AVG(`Promo Code Used`)), 2) AS organic_demand_score
FROM customers_enriched
GROUP BY Location
ORDER BY organic_demand_score DESC;

WITH TopStates AS (
    SELECT Location
    FROM customers_enriched
    GROUP BY Location
    ORDER BY COUNT(*) DESC
    LIMIT 10
)
SELECT
    ce.Location AS state,
    ce.Category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ce.Location), 1) AS pct_of_state
FROM customers_enriched ce
JOIN TopStates ts ON ce.Location = ts.Location
GROUP BY ce.Location, ce.Category
ORDER BY ce.Location, count DESC;
-- Query 9 : analyzed states with high avg_spend and high avg_eltv but lower coustomer counts so that new stores can be opened here
SELECT
    Location AS state,
    COUNT(*) AS customer_count,
    ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS promo_rate_pct,
    ROUND(AVG(eltv), 2) AS avg_eltv
FROM customers_enriched
GROUP BY Location
HAVING
    avg_spend > (SELECT AVG(`Purchase Amount (USD)`) * 1.05 FROM customers_enriched)
    AND customer_count < (SELECT COUNT(*) / 50 FROM customers_enriched)
ORDER BY avg_spend DESC;


