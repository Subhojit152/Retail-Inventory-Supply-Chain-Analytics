Select * from retail_inventory;

-- 1. Identify overstocked products (Inventory Level > Units Sold by a large margin)
		SELECT Product_ID, Category, Inventory_Level, Units_Sold
		FROM retail_inventory
		WHERE Inventory_Level > Units_Sold * 2;

-- 2.  Find products with frequent stockouts (Units Ordered > Inventory Level)
		Select product_id, category, count(*) as stockouts 
		from retail_inventory
		where units_ordered > inventory_level
		group by product_id, 2 
		order by 3 desc;

-- 3. Total units sold and revenue by category
		Select category, sum(units_sold) total_units, 
		sum(units_sold * price) as revenue
		from retail_inventory
		group by 1
		order by 3 desc;

-- 4. Top 5 best-selling products by total units sold
		Select product_id, sum(units_sold) total_units 
		from retail_inventory
		group by 1 
		order by 2 desc
		limit 5;

-- 5.  Average Forecast Error per Product.
		SELECT Product_ID, 
       AVG(ABS(Units_Sold - Demand_Forecast)) AS Avg_Forecast_Error
FROM retail_inventory
GROUP BY Product_ID
ORDER BY Avg_Forecast_Error DESC;

-- 6. Correlation of discount with sales (check if higher discounts lead to more sales)
		Select discount, avg(units_sold) avg_units from retail_inventory
		group by 1
		order by 1;
		
-- 7. Products priced lower than competitors but still underperforming.
		Select product_id, units_sold, price, competitor_pricing
		from retail_inventory
		where price < competitor_pricing and units_sold < 100;

-- 8. Compare sales performance across regions
		Select region, sum(units_sold) Total_unit_sold
		from retail_inventory
		group by 1
		order by 2;

-- 9. Store-level performance: total sales, revenue, average discount
		Select store_id,
		sum(units_sold) total_units_sold,
		sum(units_sold * price) total_revenue,
		avg(discount) avg_discount
		from retail_inventory
		group by 1
		order by total_revenue desc;

-- 10. Does weather affect sales?
		Select weather_condition, sum(units_sold) total_units_sold, avg(units_sold)
		from retail_inventory
		group by 1
		order by 2 desc;

-- 11. Analyze seasonal performance of each category.
		  Select seasonality, category,
		  sum(units_sold) total_units,
		  sum(price * units_sold) revenue
		  from retail_inventory
		  group by 1,2
		  order by 2 , 3 desc;

-- 12. Running Total of Units Sold by Product.
		Select product_id, date, 
		units_sold, 
		sum(units_sold) over (partition by product_id order by date desc) as cumm
		from retail_inventory;

-- 13. Monthly Average Demand Forecast vs. Actual Sales.
		SELECT 
    TO_CHAR(DATE_TRUNC('month', date), 'YYYY-MM') AS month,
    ROUND(AVG(demand_forecast)::NUMERIC, 2) AS avg_forecast,
    ROUND(AVG(units_sold)::NUMERIC, 2) AS avg_units,
	    ROUND(
	        (100.0 * AVG(units_sold) / NULLIF(AVG(demand_forecast), 0))::NUMERIC, 2
	    ) AS forecast_accuracy_percent
	FROM 
	    retail_inventory
	GROUP BY 
	    TO_CHAR(DATE_TRUNC('month', date), 'YYYY-MM')
	ORDER BY 
	    month;

-- 12. Top 10% Products by Forecast Accuracy.
			With forecast_error as 
			(Select product_id,
			ABS(SUM(units_sold) - sum(demand_forecast)) as total_error
			from retail_inventory
			group by 1), ranked_product as (
					Select *, 
							percent_rank() over (order by total_error asc) as accuracy_rank
					from forecast_error
			)
			Select * from ranked_product
			where accuracy_rank <= 0.10;


-- 13. List the products whose sales forecasting accuracy falls in the bottom 50% percentile.
			WITH forecast_error AS (
    SELECT 
        product_id,
        ABS(SUM(units_sold) - SUM(demand_forecast)) AS total_error
    FROM 
        retail_inventory
    GROUP BY 
        product_id
), ranked_product AS (
    SELECT 
        *,
        PERCENT_RANK() OVER (ORDER BY total_error ASC) AS accuracy_rank
    FROM 
        forecast_error
)
SELECT *
FROM 
    ranked_product
WHERE 
    accuracy_rank >= 0.50; 

-- 14. Flag Inventory Risk (Low Inventory but High Forecast)
			Select * from retail_inventory 
			where inventory_level < demand_forecast 
			and units_ordered < demand_forecast * 0.5;

-- 15.  Moving Average of Units Sold (7-day window)
			SELECT 
    Product_ID,
    Date,
    Units_Sold,
    AVG(Units_Sold) OVER (
        PARTITION BY Product_ID 
        ORDER BY Date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Moving_Avg_7_Day
FROM retail_inventory;

-- 16. Category-Wise Discount Elasticity (Sales per Discount % Bracket)
		SELECT 
	    Category,
	    CASE 
	    WHEN Discount BETWEEN 0 AND 5 THEN '0-5%'
        WHEN Discount BETWEEN 6 AND 10 THEN '6-10%'
        WHEN Discount BETWEEN 11 AND 15 THEN '11-15%'
        WHEN Discount BETWEEN 16 AND 20 THEN '16-20%'
        ELSE '20%+' 
	    END AS Discount_Bracket,
	    AVG(Units_Sold) AS Avg_Sales
		FROM retail_inventory
		GROUP BY Category, Discount_Bracket
		ORDER BY Category, Discount_Bracket;

-- 17. Store Efficiency Ranking (Revenue per Unit of Inventory)
		SELECT 
	    Store_ID,
	    SUM(Units_Sold * Price) AS Revenue,
	    SUM(Inventory_Level) AS Total_Inventory,
	    ROUND(SUM(Units_Sold * Price) * 1.0 / SUM(Inventory_Level), 2) AS Revenue_per_Inventory
		FROM retail_inventory
		GROUP BY Store_ID
		ORDER BY Revenue_per_Inventory DESC;

-- 18. Demand Forecast Error % by Category
		SELECT 
	    Category,
	    ROUND(AVG(ABS(Units_Sold - Demand_Forecast) * 100.0 / NULLIF(Demand_Forecast, 0)), 2) AS Forecast_Error_Percentage
		FROM retail_inventory
		GROUP BY Category
		ORDER BY Forecast_Error_Percentage DESC;

-- 19. Subquery: Best Season for Each Category
		SELECT Category, Seasonality, Total_Units_Sold
		FROM (
		    SELECT 
		        Category,
		        Seasonality,
		        SUM(Units_Sold) AS Total_Units_Sold,
		        RANK() OVER (PARTITION BY Category ORDER BY SUM(Units_Sold) DESC) AS season_rank
		    FROM retail_inventory
		    GROUP BY Category, Seasonality
		) ranked
		WHERE season_rank = 1;
		


