
ALTER FUNCTION [biwelozew3].[_faturasNoPrazo] (@CodigoFornecedor VARCHAR(20), @Periodo DATE)
RETURNS TABLE AS

	RETURN (
	
		SELECT CAST(COUNT(V.ACCOUNTNUM) AS FLOAT) AS QUANTIDADE,
			DATEPART(YEAR, @Periodo) AS ANO,
			DATEPART(MONTH, @Periodo) AS MES	
		FROM PURCHTABLE P	
			JOIN PURCHTABLE_BR PBR ON PBR.PURCHTABLE = P.RECID
			JOIN PURCHLINE L ON L.PURCHID = P.PURCHID
	
			JOIN INVENTTABLE I	ON I.ITEMID = L.ITEMID	AND I.DATAAREAID = L.DATAAREAID	
			JOIN ECORESPRODUCT PR ON PR.RECID = I.PRODUCT
			OUTER APPLY BI.DimensaoFinanceira(P.DEFAULTDIMENSION, 'ESTABELECIMENTO') AS ESTABELECIMENTO
			JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = PR.RECID
			CROSS APPLY BI.CategoriaOMT(PR.RECID) AS CATEGORIA

			JOIN VENDTABLE V ON V.ACCOUNTNUM = P.INVOICEACCOUNT
			JOIN DIRPARTYTABLE	PT ON PT.RECID = V.PARTY		

			LEFT JOIN SALESPURCHOPERATIONTYPE_BR O ON O.RECID = PBR.SALESPURCHOPERATIONTYPE_BR	
			LEFT JOIN CFOPTABLE_BR CF ON CF.RECID = L.CFOPTABLE_BR
			CROSS APPLY BI.DataFiltroAnoMes(P.CREATEDDATETIME) AS DATAMESANO

			JOIN VENDINVOICETRANS VIT ON VIT.ORIGPURCHID = P.PURCHID AND VIT.ITEMID = L.ITEMID AND VIT.PURCHASELINELINENUMBER = L.LINENUMBER 

		WHERE L.DATAAREAID	= 'WELO' AND L.PURCHQTY > 0 AND PT.ORGNUMBER <> '' 
			AND V.ACCOUNTNUM = @CodigoFornecedor
			AND CONCAT(DATEPART(YEAR, VIT.INVOICEDATE),'/',DATEPART(MONTH, VIT.INVOICEDATE)) = CONCAT(DATEPART(YEAR, @Periodo),'/',DATEPART(MONTH, @Periodo))
			AND DATEADD(DAY, -3, VIT.INVOICEDATE) <= L.DELIVERYDATE
	
	);



GO


