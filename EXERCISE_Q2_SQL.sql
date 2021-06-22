#-------------------------------------------------*****************************-----------------------------------------
#-- 1.What are the top 5 brands by receipts scanned for most recent month?
#-------------------------------------------------*****************************-----------------------------------------

	# 1. Assuming the most recent month is the current month

	WITH TOP_BRANDS_CURRENT_MONTH AS
	(
			/*
				RETRIVES THE BRAND NAMES AND THE RESPECTIVE RANK 
				BASED ON THE COUNT OF TIMES THE BRAND WAS SCANNED
			*/
			SELECT BRANDS.NAME,ROW_NUMBER() OVER(ORDER BY COUNT(BRANDS.NAME) DESC) AS RNK_ 
			FROM RECEIPT_SCANNED_FACT AS SCANNED
			INNER JOIN PURCHASED_ITEM_DIMENSION AS PURCHASES
			ON SCANNED.RECEIPTID = PURCHASES.RECEIPTID
			INNER JOIN BRAND_DIMENSION BRANDS 
			ON BRANDS.BRANDID = PURCHASES.BRAND_ID
			INNER JOIN RECEIPT_STATUS_DIMENSION AS STATUS
			ON SCANNED.RECEIPTSTATUSID = STATUS.RECEIPTSTATUSID
			WHERE dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000') BETWEEN dateadd(month, datediff(month, 0, getdate()), 0) AND GETDATE()
			AND STATUS.RECEIPTSTATUS = 'FINISHED'
			GROUP BY BRANDS.NAME
		)
	)
	SELECT NAME,RNK_ FROM TOP_BRANDS_CURRENT_MONTH
	WHERE RNK_ <=5
	ORDER BY RNK_

#-------------------------------------------------*****************************-----------------------------------------
#-- 2.How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
#-------------------------------------------------*****************************-----------------------------------------

	/*
	 1. ASSUMING THE MOST RECENT MONTH IS THE CURRENT_MONTH
	 2. ASSUMING THE PREVIOUS MONTH IS THE CURRENT_MONTH - 1
	 3. "FINISHED" RECEIPT STATUS ARE THE ONES THAT ARE OF INTEREST
	*/

	WITH RESULTS AS(

		/*
			RESULTS THE YEAR,MONTH,COUNT OF TIMES SCANNED,AND 
			RANK AGAINST EACH BRAND BASED ON NUMBER OF TIMES THE BRAND WAS SCANNED
		*/

		SELECT BRANDS.NAME AS NAME,
		YEAR(dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000')) AS YEAR,
		MONTH(dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000')) AS MONTH,
		COUNT(BRANDS.NAME) AS CNT_,
		ROW_NUMBER() OVER(PARTITION BY YEAR(dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000')),MONTH(dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000')) ORDER BY COUNT(BRANDS.NAME) desc) AS RNK_ 
		FROM RECEIPT_SCANNED_FACT AS SCANNED
		INNER JOIN PURCHASED_ITEM_DIMENSION AS PURCHASES
		ON SCANNED.RECEIPTID = PURCHASES.RECEIPTID
		INNER JOIN BRAND_DIMENSION BRANDS 
		ON BRANDS.BRANDID = PURCHASES.BRAND_ID
		INNER JOIN RECEIPT_STATUS_DIMENSION AS STATUS
		ON SCANNED.RECEIPTSTATUSID = STATUS.RECEIPTSTATUSID
		WHERE dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000') BETWEEN dateadd(month, datediff(month, 0, getdate())-1, 0) AND GETDATE()  #converts unix timestamp and compares dates
		AND STATUS.RECEIPTSTATUS = 'FINISHED'
		GROUP BY YEAR(dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000')),MONTH(dateadd(s,SCANNED.DATE_SCANNED,'19700101 05:00:00:000')),BRANDS.NAME
		ORDER BY CNT_ DESC
	)
	SELECT NAME,YEAR,MONTH,CNT_,RNK_ FROM RESULTS
	WHERE RNK <= 5


#-------------------------------------------------*****************************-----------------------------------------
#-- 3.When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
#-------------------------------------------------*****************************-----------------------------------------

	/*
		RESULTS THE rewardsReceiptStatus WITH MAXIMUM AVERAGE SPENDS
	*/
	SELECT TOP 1 STATUS.RECEIPTSTATUS,AVG(TOTALSPENT) AS AVG_SPENT FROM RECEIPT_SCANNED_FACT SCANNED
	INNER JOIN RECEIPT_STATUS_DIMENSION STATUS
	ON SCANNED.RECEIPTSTATUSID = STATUS.RECEIPTSTATUSID
	WHERE STATUS.RECEIPTSTATUS IN ('ACCEPTED','REJECTED')
	GROUP BY STATUS.RECEIPTSTATUS
	ORDER BY AVG_SPENT DESC

#-------------------------------------------------*****************************-----------------------------------------
#-- 4. When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
#-------------------------------------------------*****************************-----------------------------------------

	/*
		RESULTS THE rewardsReceiptStatus WITH MAXIMUM PURCHASED PURCHASED
	*/
	SELECT TOP 1 STATUS.RECEIPTSTATUS,SUM(PURCHASEDITEMCOUNTS) AS TOTAL_ITEMS FROM RECEIPT_SCANNED_FACT SCANNED
	INNER JOIN RECEIPT_STATUS_DIMENSION STATUS
	ON SCANNED.RECEIPTSTATUSID = STATUS.RECEIPTSTATUSID
	WHERE STATUS.RECEIPTSTATUS IN ('ACCEPTED','REJECTED')
	GROUP BY STATUS.RECEIPTSTATUS
	ORDER BY TOTAL_ITEMS DESC

#-------------------------------------------------*****************************-----------------------------------------
#-- 5. Which brand has the most spend among users who were created within the past 6 months?
#-------------------------------------------------*****************************-----------------------------------------

	# 1. "FINISHED" RECEIPT STATUS ARE THE ONES THAT ARE OF INTEREST
	/*
		RESULTS THE BRAND NAME WITH MAXIMUM SPEND BY THE USERS CREATED IN PAST 6 MONTHS
	*/
	SELECT TOP 1 BRANDS.NAME AS BRAND_NAME,SUM(SCANNED.TOTALSPENT) AS TOTAL_SPEND FROM USER_DIMENSION USERS
	INNER JOIN RECEIPT_SCANNED_FACT SCANNED
	ON SCANNED.USERID = USERS.USERID
	INNER JOIN PURCHASED_ITEMS_DIMENSION ITEMS
	ON ITEMS.RECEIPTID = SCANNED.RECEIPTID
	INNER JOIN BRAND_DIMENSION BRANDS
	ON BRANDS.BRANDID = ITEMS.BRANDID
	INNER JOIN RECEIPT_STATUS_DIMENSION STATUS
	ON SCANNED.RECEIPTSTATUSID = STATUS.RECEIPTSTATUSID
	WHERE dateadd(s,USERS.CREATEDATE,'19700101 05:00:00:000') BETWEEN dateadd(month, datediff(month, 0, getdate())-6, 0) AND dateadd(month, datediff(month, 0, getdate()), 0) #converts unix timestamp and compares dates
	AND STATUS.RECEIPTSTATUS = 'FINISHED'
	GROUP BY BRANDS.NAME
	ORDER BY TOTAL_SPEND DESC


#-------------------------------------------------*****************************-----------------------------------------
#-- 6. Which brand has the most transactions among users who were created within the past 6 months?
#-------------------------------------------------*****************************-----------------------------------------

	# 1. "FINISHED" RECEIPT STATUS ARE THE ONES THAT ARE OF INTEREST
	/*
		RESULTS THE BRAND NAME WITH MAXIMUM TRANSACTIONS BY THE USERS CREATED IN PAST 6 MONTHS
	*/
	SELECT TOP 1 BRANDS.NAME AS BRAND_NAME,COUNT(BRANDS.NAME) AS MOST_TRANSACTIONS FROM USER_DIMENSION USERS
	INNER JOIN RECEIPT_SCANNED_FACT SCANNED
	ON SCANNED.USERID = USERS.USERID
	INNER JOIN PURCHASED_ITEMS_DIMENSION ITEMS
	ON ITEMS.RECEIPTID = SCANNED.RECEIPTID
	INNER JOIN BRAND_DIMENSION BRANDS
	ON BRANDS.BRANDID = ITEMS.BRANDID
	INNER JOIN RECEIPT_STATUS_DIMENSION STATUS
	ON SCANNED.RECEIPTSTATUSID = STATUS.RECEIPTSTATUSID
	WHERE dateadd(s,USERS.CREATEDATE,'19700101 05:00:00:000') BETWEEN dateadd(month, datediff(month, 0, getdate())-6, 0) AND dateadd(month, datediff(month, 0, getdate()), 0)
	AND STATUS.RECEIPTSTATUS = 'FINISHED'
	GROUP BY BRANDS.NAME
	ORDER BY MOST_TRANSACTIONS DESC