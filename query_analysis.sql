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
-- Conclusion -We are highly effective at getting new customers in the door, but we lose them quickly new entry point buyers outnumber mature customers by more than $2$-to-$1$ across every single category. Worse, our average order value (AOV) stays completely flat at 59$ to 60$ no matter how long a customer stays with us. Getting "loyal" doesn't make them spend more per order; it just gives them more opportunities to use discounts.

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
-- Conclusion- Our brand is highly effective at initial acquisition but completely fails to scale customer value over time, suffering a massive 2-to-1 retention drop-off while actively training its most loyal repeat buyers to rely on margin-eroding discounts

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
-- Conclusion:- We can see that customers are likely to use all sorts of payment methods and the expenditure is also equally distributed within these mediums 

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
-- Conclusion -Customer volume plummets drastically at each stage of the customer lifecycle, yet average order value remains entirely stagnant at around $60 across every single product category and tenure cohort

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
-- Conclusion :- we can see that the discounts and purchases are equally distributed that means customer prefer this brand for all seasons and wait for the discounts and promo

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
-- Conclusion :- We can say that customers tend to pay full price for outwears and tend to wait for discounts for footwear


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
-- Conclusion - Here we calculate where the demand of the brand is higher because despite using no discounts they tend to buy materials from them

-- Query 8 : performed category wise distribution across states
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

-- Conclusion - From this we can conclude what type of product category must be promoted in which statement this helps in logistics


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
-- Conclusion - In these states brand should invest more as there are high value customers there 

-- Query 10 : Distinguish the customers on the base of promo using audience and loyal base

SELECT 
    CASE 
        WHEN segment IN ('Organic Loyalist', 'Loyal Promo-User') THEN 'Loyal Base'
        WHEN segment IN ('Promo-Dependent', 'At-Risk / One-Timer') THEN 'Promo-Reliant Base'
        ELSE 'Neutral' 
    END AS strategic_grouping,
    COUNT(*) AS total_customers,
    ROUND(SUM(`Purchase Amount (USD)`), 2) AS total_revenue,
    ROUND(SUM(`Purchase Amount (USD)`) * 100.0 / (SELECT SUM(`Purchase Amount (USD)`) FROM customers_enriched), 2) AS pct_of_total_revenue,
    ROUND(AVG(`Promo Code Used`) * 100, 2) AS group_promo_reliance_pct
FROM customers_enriched
GROUP BY strategic_grouping;

-- Conclusion - it helps in the revenue analysis and check what are actual loyal customers and who are there to buy the cheap when in the discount period




