/*1.list of products with base_price > 500 and promo_type = 'BOGOF'*/
SELECT DISTINCT product_name, base_price, promo_type
FROM retail_events_db.dim_products 
JOIN fact_events ON dim_products.product_code = fact_events.product_code
WHERE base_price > 500 AND promo_type = 'BOGOF';

/*2.Report that provides overview of the number of stores in each city*/
SELECT city, COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

/*3.Report showing campaign and revenue generated before and after campaign.*/
SELECT
    campaign_name,
    SUM(`quantity_sold(before_promo)` * base_price) / 1000000 AS `revenue_before(Mn)`,
    SUM(
        CASE WHEN promo_type = 'BOGOF' THEN `quantity_sold(after_promo)` * 2 * promo_price
             ELSE `quantity_sold(after_promo)`*promo_price END
    ) / 1000000 AS `revenue_after(Mn)`
FROM dim_campaigns
JOIN fact_events ON dim_campaigns.campaign_id = fact_events.campaign_id
GROUP BY campaign_name
ORDER BY campaign_name;

/*4.Report that calculates Incremental Sold Quantity (ISU%) for each category during Diwali.*/
WITH DiwaliSales AS (
    SELECT
        category,
        SUM(
        CASE WHEN promo_type = 'BOGOF' THEN ((`quantity_sold(after_promo)` * 2 - `quantity_sold(before_promo)`))
             ELSE 
			((`quantity_sold(after_promo)` - `quantity_sold(before_promo)`))  END) / SUM(`quantity_sold(before_promo)`)*100 AS `isu%`
    FROM dim_products
    JOIN fact_events ON dim_products.product_code = fact_events.product_code
    JOIN dim_campaigns ON fact_events.campaign_id = dim_campaigns.campaign_id
    WHERE dim_campaigns.campaign_name = 'Diwali'
    GROUP BY dim_products.category
)

SELECT
    category,
    `isu%`,
    RANK() OVER (ORDER BY `isu%` DESC) AS rank_order
FROM DiwaliSales;

/*5.Report featuring top 5 products ranked by IR% across all campaigns.*/
WITH IRPercentage AS (
    SELECT
        product_name,
        category,
        ((SUM(fact_events.`quantity_sold(after_promo)`)) - SUM(fact_events.`quantity_sold(before_promo)`)) / SUM(fact_events.`quantity_sold(before_promo)`) * 100 AS `ir%`
    FROM dim_products
    JOIN fact_events ON dim_products.product_code = fact_events.product_code
    GROUP BY dim_products.product_name, dim_products.category
)

SELECT
    product_name,
    category,
    `ir%`
FROM IRPercentage
ORDER BY `ir%` DESC
LIMIT 5;