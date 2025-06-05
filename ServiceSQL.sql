-- Active Service Counts
CREATE VIEW Active_Service AS
SELECT COUNT(DISTINCT service_id) AS Active_Services
FROM Service_Company_Data
WHERE Status = 'Active'

-- Revenue by Service Type
CREATE VIEW Revenue_Service AS
SELECT Service_Type, SUM(Monthly_Cost) AS Total_Revenue
FROM Service_Company_Data
GROUP BY Service_Type

-- Risk Priority Calculation
CREATE VIEW Account_Risk AS
SELECT 
    Account_Manager,
    Customer_Name,
    Renewal_Probability,
    (Support_Tickets / NULLIF(Active_Services, 0)) AS Tickets_Per_Service,
    CASE 
        WHEN Renewal_Probability < 0.5 AND (Support_Tickets / NULLIF(Active_Services, 0)) > 2 THEN 'Critical'
        WHEN Renewal_Probability < 0.5 THEN 'High Risk'
        WHEN (Support_Tickets / NULLIF(Active_Services, 0)) > 2 THEN 'High Tickets'
        ELSE 'Stable'
    END AS Risk_Category
FROM Service_Company_Data

-- SLA Heatmap
CREATE VIEW SLA_Heatmap AS
SELECT 
    Region,
    Service_Type,
    AVG(SLA_Met_Percent) AS Avg_SLA
FROM Service_Company_Data
GROUP BY Region, Service_Type

-- Auto Renewal Analysis
CREATE VIEW Auto_Renewal_Impact AS
SELECT 
    Is_Auto_Renewal,
    AVG(Customer_Satisfaction) AS AVG_Satisfaction,
    COUNT(*) AS Account_Count
FROM Service_Company_Data
GROUP BY Is_Auto_Renewal

-- Critical Accounts
CREATE VIEW Critical_Accounts AS
SELECT 
    Account_Manager,
    Customer_Name,
    Renewal_Probability,
    Monthly_Cost
FROM Account_Risk
WHERE Risk_Category = 'Critical'
ORDER BY Renewal_Probability ASC

-- QBR Scheduling
CREATE VIEW QBR_Schedule AS
SELECT 
    Customer_Name,
    Account_Manager,
    DATEADD(MONTH, 3, MAX(End_Date)) AS Next_QBR_Date
FROM Service_Company_Data
WHERE Risk_Category IN ('Critical', 'High Risk')
GROUP BY Customer_Name, Account_Manager

-- 6 Month Revenue Forecast
CREATE VIEW Revenue_Forecast AS
WITH Monthly_Revenue AS (
SELECT 
DATE_TRUNC('Month', Start_date) AS Month,
        SUM(Monthly_Cost) AS Revenue
    FROM Service_Company_Data
    GROUP BY DATE_TRUNC('Month', Start_Date)
)
SELECT 
    MONTH,
    Revenue,
    AVG(Revenue) OVER (ORDER BY month ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS Rolling_Avg,
    Revenue * 1.1 AS Optimistic_Forecast, -- 10% growth
    Revenue * 0.95 AS Pessimistic_Forecast -- 5% decline
FROM Monthly_Revenue

