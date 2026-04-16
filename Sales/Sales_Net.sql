WITH SalesBase AS (
    SELECT
        CAST(s.ValueDate AS date) AS ValueDate,
        YEAR(s.ValueDate) AS [Year],
        MONTH(s.ValueDate) AS [Month],
        s.DocNumber,
        s.TransType,
        s.AccountKey,
        s.AccountName,
        a.SortGroup,

        sm.ItemKey,
        sm.ItemName,
        sm.Warehouse,

        ABS(ISNULL(sm.Quantity, 0)) AS BaseQuantity,
        ISNULL(sm.Price, 0) AS SalesPrice,
        ISNULL(sm.DiscountPrc, 0) AS LineDiscountPrc,
        ISNULL(s.DiscountPrc, 0) AS DocDiscountPrc,

        ISNULL(sm.PurchPrice, 0) AS PurchPrice,
        ISNULL(sm.StockValPrice, 0) AS StockValPrice,

        CASE
            WHEN s.TransType = N'חז' THEN -1
            ELSE 1
        END AS SignFactor

    FROM Stock s
    INNER JOIN StockMoves sm
        ON s.ID = sm.StockID
    INNER JOIN Accounts a
        ON s.AccountKey = a.AccountKey

    WHERE sm.ItemKey IS NOT NULL
      AND LTRIM(RTRIM(ISNULL(sm.ItemKey, ''))) <> ''
      AND YEAR(s.ValueDate) IN (2025, 2026)
      AND a.SortGroup IN (3010, 3020, 3030, 3040, 3050)
      AND s.TransType IN (N'חל', N'חז')
)

SELECT
    ValueDate,
    [Year],
    [Month],
    DocNumber,
    TransType,
    AccountKey,
    AccountName,
    SortGroup,
    ItemKey,
    ItemName,
    Warehouse,

    BaseQuantity * SignFactor AS Quantity,
    SalesPrice,
    LineDiscountPrc,
    DocDiscountPrc,

    (BaseQuantity * SalesPrice) * SignFactor AS GrossSales,

    (
        (BaseQuantity * SalesPrice)
        * (1 - LineDiscountPrc / 100.0)
    ) * SignFactor AS AmountAfterLineDiscount,

    (
        (BaseQuantity * SalesPrice)
        * (1 - LineDiscountPrc / 100.0)
        * (1 - DocDiscountPrc / 100.0)
    ) * SignFactor AS NetSales,

    PurchPrice,
    StockValPrice,

    (
        BaseQuantity * COALESCE(NULLIF(StockValPrice, 0), NULLIF(PurchPrice, 0), 0)
    ) * SignFactor AS CostAmount,

    (
        (
            (BaseQuantity * SalesPrice)
            * (1 - LineDiscountPrc / 100.0)
            * (1 - DocDiscountPrc / 100.0)
        )
        -
        (
            BaseQuantity * COALESCE(NULLIF(StockValPrice, 0), NULLIF(PurchPrice, 0), 0)
        )
    ) * SignFactor AS GrossProfit,

    CASE
        WHEN TransType = N'חל' THEN N'חשבונית'
        WHEN TransType = N'חז' THEN N'זיכוי'
        ELSE N'אחר'
    END AS DocTypeName

FROM SalesBase;
