
-- ALTER VIEW BiView.ContasReceber_Weloze AS 

SELECT 
	
	DATAEMISSAO.DIA_MES_ANO		AS "Data Transa��o",
	DATAEMISSAO.SEMANA_ANO		AS "Data Transa��o (semana/ano)",
	DATAEMISSAO.MES_ANO			AS "Data Transa��o (m�s/ano)",

	DATAVENCIMENTO.DIA_MES_ANO	AS "Data Vencimento",
	DATAVENCIMENTO.SEMANA_ANO	AS "Data Vencimento (semana/ano)",
	DATAVENCIMENTO.MES_ANO		AS "Data Vencimento (m�s/ano)",

	DATAPAGAMENTO.DIA_MES_ANO	AS "Data Pagamento",
	DATAPAGAMENTO.SEMANA_ANO	AS "Data Pagamento (semana/ano)",
	DATAPAGAMENTO.MES_ANO		AS "Data Pagamento (m�s/ano)",

	DATEDIFF(DAY, DATAEMISSAO.DIA_MES_ANO, DATAVENCIMENTO.DIA_MES_ANO) AS "Prazo de Pagamento",

	CONCAT(X.ACCOUNTNUM, ' - ', PT.NAME) AS "Cliente",
	TRANSACAO.TIPO				AS "Tipo de Transa��o",
	CSG.NAME					AS "Grupo de Vendas",

	CASE 
		WHEN X.LASTSETTLEDATE IS NOT NULL THEN
			CASE 
				WHEN X.LASTSETTLEDATE > X.DUEDATE THEN 'PAGO EM ATRASO'
				ELSE 'PAGO'
			END
		ELSE 
			CASE 
				WHEN X.DUEDATE < GETDATE() THEN 'EM ATRASO'
				ELSE 'EM ABERTO' 
			END
	END			AS "Status do Pagamento",

	X.INVOICE	AS "Fatura",
	X.TXT		AS "Descri��o",

	X.AMOUNTCUR							AS "Valor Total",
	X.SETTLEAMOUNTCUR					AS "Valor Pago",
	(X.AMOUNTCUR - X.SETTLEAMOUNTCUR)	AS "Valor em Aberto"

FROM 
(
SELECT 
	T.DATAAREAID
	,T.RECID AS RECID1
	,O.RECID AS RECID2
	,T.ACCOUNTNUM
	,T.TRANSDATE
	,VOUCHER
	,INVOICE
	,TXT
	,O.AMOUNTCUR
	,0 AS SETTLEAMOUNTCUR
	,O.AMOUNTMST
	,SETTLEAMOUNTMST
	,T.CURRENCYCODE, 
	NULLIF(O.DUEDATE, '1900-01-01') AS DUEDATE,
	LASTSETTLEVOUCHER
	,NULL AS LASTSETTLEDATE
	,CLOSED
	,TRANSTYPE
	,APPROVED
	,DOCUMENTNUM
	,DOCUMENTDATE
	,SETTLEMENT
	,INTEREST
	,LASTSETTLEACCOUNTNUM
	,PAYMMODE
	,PAYMREFERENCE
	,DELIVERYMODE
	,ORDERACCOUNT
	,O.REPORTINGCURRENCYAMOUNT
	,SETTLEAMOUNTREPORTING
	,APPROVER
FROM CUSTTRANS T
	JOIN CUSTTRANSOPEN O ON O.ACCOUNTNUM = T.ACCOUNTNUM 
		AND O.REFRECID = T.RECID
	CROSS APPLY BiUtil.TipoTransacaoContabil(T.TRANSTYPE) TRANSACAO
WHERE T.DATAAREAID = 'WELO' AND T.TRANSTYPE NOT IN (8, 14, 15, 7, 27, 24, 9)

UNION

SELECT 
	T. DATAAREAID
	,T.RECID AS RECID1
	,S.RECID AS RECID2
	,T.ACCOUNTNUM
	,T.TRANSDATE
	,VOUCHER
	,T.INVOICE
	,TXT
	,S.SETTLEAMOUNTCUR AS AMOUNTCUR
	,S.SETTLEAMOUNTCUR
	,AMOUNTMST
	,S.SETTLEAMOUNTMST
	,T.CURRENCYCODE, 
	NULLIF(S.DUEDATE, '1900-01-01') AS DUEDATE,
	LASTSETTLEVOUCHER
	,NULLIF(S.TRANSDATE, '1900-01-01') AS LASTSETTLEDATE
	,CLOSED
	,TRANSTYPE
	,APPROVED
	,DOCUMENTNUM
	,DOCUMENTDATE
	,SETTLEMENT
	,INTEREST
	,LASTSETTLEACCOUNTNUM
	,PAYMMODE
	,PAYMREFERENCE
	,DELIVERYMODE
	,ORDERACCOUNT
	,REPORTINGCURRENCYAMOUNT
	,S.SETTLEAMOUNTREPORTING
	,APPROVER
FROM CUSTTRANS T
	JOIN CUSTSETTLEMENT S ON S.TRANSCOMPANY = T.DATAAREAID
		AND S.TRANSRECID = T.RECID
		AND S.ACCOUNTNUM = T.ACCOUNTNUM
	CROSS APPLY BiUtil.TipoTransacaoContabil(T.TRANSTYPE) TRANSACAO
WHERE T.DATAAREAID = 'WELO' AND T.TRANSTYPE NOT IN (8, 14, 15, 7, 27, 24, 9)
) AS X
CROSS APPLY BiUtil.TipoTransacaoContabil(X.TRANSTYPE) TRANSACAO
JOIN CUSTTABLE C ON C.ACCOUNTNUM = X.ACCOUNTNUM AND C.DATAAREAID = X.DATAAREAID
LEFT JOIN COMMISSIONSALESGROUP CSG ON CSG.GROUPID = C.SALESGROUP
JOIN DIRPARTYTABLE PT ON PT.RECID = C.PARTY

CROSS APPLY BiUtil.DataFiltro(X.TRANSDATE)		AS DATAEMISSAO
CROSS APPLY BiUtil.DataFiltro(X.DUEDATE)		AS DATAVENCIMENTO
CROSS APPLY BiUtil.DataFiltro(X.LASTSETTLEDATE)	AS DATAPAGAMENTO



