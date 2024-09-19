
--1. Find the customers who purchased the most expensive products to identify the customers who tend to purchase premium products.

SELECT c.CustomerID, 
		pp.FirstName, 
		pp.LastName, 
		p.Name AS ProductName, 
		sod.UnitPrice
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh 
		ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c 
		ON soh.CustomerID = c.CustomerID
JOIN Person.Person pp
		ON c.PersonID = pp.BusinessEntityID
JOIN Production.Product p 
		ON sod.ProductID = p.ProductID
ORDER BY sod.UnitPrice DESC;


--2. List products along with their subcategory and category to understand the hierarchy of product categories and subcategories for inventory management.

SELECT p.ProductID, 
		p.Name AS ProductName,
		psc.Name AS SubCategoryName, 
		pc.Name AS CategoryName
FROM Production.Product p
JOIN Production.ProductSubcategory psc 
	ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc 
	ON psc.ProductCategoryID = pc.ProductCategoryID
ORDER BY pc.Name ASC; -- Showing the CategoryName in alphabetical order


--3. List the employees to have a visualization of the staffing structure of the organization

SELECT e.BusinessEntityID, 
	   edh.FirstName, 
	   edh.LastName, e.Gender, 
	   e.JobTitle, edh.Department, 
	   edh.GroupName, 
	   edh.StartDate
FROM HumanResources.Employee e
LEFT JOIN HumanResources.vEmployeeDepartmentHistory edh
	ON e.BusinessEntityID = edh.BusinessEntityID
ORDER BY e.BusinessEntityID 


--4. Retrieve sales order details along with salesperson names for order analysis

SELECT soh.SalesOrderID, 
	   pp.FirstName AS SalesPersonFirstName, 
	   pp.LastName AS SalesPersonLastName,
	   soh.SalesPersonID, 
	   p.Name AS ProductName, 
	   p.ListPrice
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
	ON soh.SalesOrderID =sod.SalesOrderID
JOIN Production.Product p
	ON p.ProductID = sod.ProductID
JOIN Sales.SalesPerson sp 
	ON soh.SalesPersonID = sp.BusinessEntityID
JOIN Person.Person pp 
	ON sp.BusinessEntityID = pp.BusinessEntityID
ORDER BY soh.SalesPersonID;


--5. Find which customers purchased a product in the bike category and get the details of the product they purchased.

SELECT c.CustomerID, 
		pp.FirstName, 
		pp.LastName, 
		p.ProductID, 
		p.Name AS ProductName, 
		pc.Name AS CategoryName
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh 
	ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p 
	ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc 
	ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc 
	ON psc.ProductCategoryID = pc.ProductCategoryID
JOIN Sales.Customer c 
	ON soh.CustomerID = c.CustomerID
JOIN person.Person pp
	ON c.PersonID = pp.BusinessEntityID
WHERE pc.Name = 'Bikes'; -- Filters for Bikes category only


--6. Find products that have never been sold to identify products with zero sales for inventory optimization.

SELECT p.ProductID, p.Name
FROM Production.Product p
WHERE p.ProductID NOT IN (SELECT ProductID 
                          FROM Sales.SalesOrderDetail); -- All the product ID in Sales.SalesOrderDetails table (the inner query)


--7. Find salespeople who generated more than the average total sales to pinpoint and reward top performers.

SELECT sp.BusinessEntityID, 
       pp.FirstName, 
	   pp.LastName, 
	   SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesPerson sp 
		ON soh.SalesPersonID = sp.BusinessEntityID
JOIN Person.Person pp 
		ON sp.BusinessEntityID = pp.BusinessEntityID
GROUP BY sp.BusinessEntityID, pp.FirstName, pp.LastName
HAVING SUM(soh.TotalDue) > (SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader) -- To find the average total sales
ORDER BY TotalSales DESC;


--8. All products that have been purchased by customers located in United States to understand the purchase trend from that part of the world.

SELECT p.ProductID, 
       p.Name AS ProductName
FROM Production.Product p
WHERE p.ProductID IN (
    SELECT sod.ProductID
    FROM Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh 
	ON sod.SalesOrderID = soh.SalesOrderID
    JOIN Sales.Customer c 
	ON soh.CustomerID = c.CustomerID
    JOIN Person.Person pp 
	ON c.PersonID = pp.BusinessEntityID
    JOIN Person.Address a 
	ON pp.BusinessEntityID = a.AddressID
	JOIN Person.vStateProvinceCountryRegion spc 
	ON a.StateProvinceID = spc.StateProvinceID 
    WHERE spc.CountryRegionCode = 'US' -- where country region is the United States
	);


--9. The product name along with the total quantity sold for each product to determine product with the highest quantity sold.

SELECT
    p.Name AS ProductName,
    (SELECT SUM(sod.OrderQty)
     FROM Sales.SalesOrderDetail sod
     WHERE sod.ProductID = p.ProductID) AS TotalQuantitySold
FROM Production.Product p
ORDER BY TotalQuantitySold DESC;


--10. Find customers who have made more than 5 purchases and have spent more than $5,000 in total.

SELECT c.CustomerID, 
	   pp.FirstName, 
	   pp.LastName, 
	   COUNT(soh.SalesOrderID) AS PurchaseCount, 
	   SUM(soh.TotalDue) AS TotalSpent
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c 
      ON soh.CustomerID = c.CustomerID
JOIN Person.Person pp 
	  ON c.PersonID = pp.BusinessEntityID
WHERE c.CustomerID IN (SELECT CustomerID
					   FROM Sales.SalesOrderHeader
					   GROUP BY CustomerID
					   HAVING COUNT(SalesOrderID) > 5 AND SUM(TotalDue) > 5000 -- Inner query shows Customer ID with more than 5 counts of purchase and a total purchase amount greater than $5000
)
GROUP BY c.CustomerID, pp.FirstName, pp.LastName
ORDER BY PurchaseCount; -- To show the table in an organized manner using PurchaseCount in ascending order.


--11. Find all employees who have worked more than 5 years in the company to analyze employee retention based on tenure

WITH EmployeeTenure AS (
    SELECT BusinessEntityID, 
	HireDate, 
	DATEDIFF(YEAR, HireDate, GETDATE()) AS Tenure
    FROM HumanResources.Employee
)
SELECT BusinessEntityID, 
       HireDate, 
	   Tenure
FROM EmployeeTenure
WHERE Tenure > 5;


--12. Analyze salesperson's contribution by Total sales
-- Calculates the total sales for each salesperson and then filters the results for salespeople who have made more than $1,000,000 in sales.

WITH SalesPersonTotalSales AS (
    SELECT
        SalesPersonID,
        SUM(TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader
    GROUP BY SalesPersonID -- All salespersons ID and their total sales
)
SELECT
    sp.BusinessEntityID, 
	s.FirstName, 
	s.LastName, 
	sps.TotalSales
FROM Sales.SalesPerson sp
JOIN Person.Person s
    ON sp.BusinessEntityID = s.BusinessEntityID
JOIN SalesPersonTotalSales sps
    ON sp.BusinessEntityID = sps.SalesPersonID
WHERE sps.TotalSales > 1000000
ORDER BY sps.TotalSales DESC; -- this then adds the names of sales persons with over $1,000,000 total sales and ranks from highest to lowest


--13. Determine the 10 highest selling product by ranking products by total quantity sold for analysis.

WITH ProductSalesRanking AS (
    SELECT
        p.ProductID,
        p.Name AS ProductName,
        SUM(sod.OrderQty) AS TotalQuantitySold,
        RANK() OVER (ORDER BY SUM(sod.OrderQty) DESC) AS SalesRank
    FROM Production.Product p
    JOIN Sales.SalesOrderDetail sod
        ON p.ProductID = sod.ProductID
    GROUP BY p.ProductID, p.Name 
)
SELECT 
    ProductName, 
    TotalQuantitySold, 
    SalesRank
FROM ProductSalesRanking
WHERE SalesRank <= 10; -- Top 10 products by total quantity sold


--14. Analysis of Sales generated in 2014 and measure the growth on a Month on Month basis.

WITH MonthlySales AS (
    SELECT
        YEAR(OrderDate) AS SalesYear,
		MONTH(OrderDate) AS SalesMonthNo,
        DATENAME(MONTH,OrderDate) AS SalesMonth, -- To get the month name
        SUM(TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2014
    GROUP BY YEAR(OrderDate), DATENAME(MONTH,OrderDate), MONTH(OrderDate)
)
SELECT
    SalesMonthNo,
    SalesMonth,
    TotalSales
FROM MonthlySales
ORDER BY SalesMonthNo; -- Brings the data out in the right order from the 1st Month of the year(January)

--15. Calculate Yearly Sales Growth from 2011 through 2014 for trend analysis.

WITH YearlySales AS (
    SELECT
        YEAR(OrderDate) AS SalesYear,
        SUM(TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate) -- Total sales of each year
)
SELECT
    SalesYear,
    TotalSales,
    LAG(TotalSales, 1) OVER (ORDER BY SalesYear) AS PreviousYearSales, -- Previous sales of each year
    (TotalSales - LAG(TotalSales, 1) OVER (ORDER BY SalesYear)) / LAG(TotalSales, 1) OVER (ORDER BY SalesYear) * 100 AS YearOnYearGrowth --  year-on-year growth percentage
FROM YearlySales
ORDER BY SalesYear;

