
-- ALTER VIEW BiView.Transacoes_Delav  AS

SELECT 

	X.LNFRECID AS _, -- Utilizado para evitar a perda de linhas iguais
	X.TIPO AS "Nota Fiscal - Tipo",
	X.FISCALDOCUMENTNUMBER	AS "Nota Fiscal - N�mero",
	X.FISCALESTABLISHMENT	AS "Nota Fiscal - Estabelecimento Fiscal",

	X.DATA AS "Data",
	DATAFILTRO.MESANO AS "Data - M�s/Ano",
	DATEPART(ISO_WEEK, X.DATA) AS "Data - N� da Semana",

	X.FISCALDOCUMENTACCOUNTNUM AS "Terceiro - C�digo",
	X.TERCEIRO AS "Terceiro - Nome",
	X.CNPJ AS "Terceiro - CNPJ",
	X.IENUM_BR AS "Terceiro - IE",

	X.ITEMID AS "Item (C�digo)",

	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADENF, ')')		 AS "Item (Un. da Nota Fiscal)",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADEVENDA, ')')	 AS "Item (Un. de Venda)",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADEESTOQUE, ')') AS "Item (Un. de Estoque)",

	X.FISCALCLASSIFICATION AS "Item - NCM",

	X.OPERATIONTYPEID AS "Tipo de Opera��o - C�digo",
	CONCAT(X.OPERATIONTYPEID, ' - ', X.OPERATIONNAME) AS "Tipo de Opera��o - Descri��o",

	X.CFOPID AS "CFOP - C�digo",
	CONCAT(X.CFOPID, ' - ', X.CFOPNAME) AS "CFOP - Descri��o",

	X.DOCUMENTOORIGINAL AS "Ordem de Compra/Venda",

	CASE WHEN X.DIRECTION = 1 
		THEN CASE WHEN ESTOQUE.FATOR IS NULL THEN X.QUANTITY ELSE ESTOQUE.FATOR * X.QUANTITY END
		ELSE CASE WHEN ESTOQUE.FATOR IS NULL THEN X.QUANTITY * -1 ELSE ESTOQUE.FATOR * X.QUANTITY * -1 END
	END AS "Saldo",

	CASE WHEN X.DIRECTION = 1 
		THEN X.LINEAMOUNT
		ELSE X.LINEAMOUNT * -1
	END AS "Valor"

FROM 

(

	-- Entradas

	SELECT 
		LNF.RECID AS LNFRECID,
		PR.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		OT.CREATEFINANCIALTRANS, 
		OT.CREATEINVENTTRANS, 
		NF.FISCALDOCUMENTACCOUNTNUM,
		CF.CFOPID, CF.NAME AS CFOPNAME,  
		LNF.FISCALCLASSIFICATION,
		IT.ITEMID, T.NAME ITEMNAME, 
		P.PURCHID AS DOCUMENTOORIGINAL,
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE AS DATA, PT.NAME AS TERCEIRO, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF AS CNPJ, V.IENUM_BR,
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		'Entradas' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.LINEAMOUNT,
		LNF.UNIT AS UNIDADENF,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		MODCOMPRA.UNITID AS UNIDADECOMPRA,
		MODVENDA.UNITID AS UNIDADEVENDA
	FROM FISCALDOCUMENT_BR NF
		JOIN FISCALDOCUMENTLINE_BR LNF ON LNF.FISCALDOCUMENT = NF.RECID
		JOIN VENDINVOICEJOUR I ON I.RECID = NF.REFRECID AND NF.REFTABLEID = 491
		LEFT JOIN PURCHTABLE P ON P.PURCHID = I.PURCHID
		LEFT JOIN PURCHTABLE_BR PBR ON PBR.PURCHTABLE = P.RECID
		LEFT JOIN SALESPURCHOPERATIONTYPE_BR OT ON OT.RECID = PBR.SALESPURCHOPERATIONTYPE_BR
		JOIN VENDTABLE V ON V.ACCOUNTNUM = NF.FISCALDOCUMENTACCOUNTNUM
		JOIN DIRPARTYTABLE PT ON PT.RECID = V.PARTY
		JOIN CFOPTABLE_BR CF ON CF.CFOPID = LNF.CFOP AND CF.DATAAREAID = LNF.DATAAREAID
		JOIN INVENTTABLE IT ON IT.ITEMID = LNF.ITEMID AND IT.DATAAREAID = LNF.DATAAREAID
		JOIN ECORESPRODUCT PR ON PR.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = PR.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		OUTER APPLY BiUtil.CategoriaOMT (PR.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
		JOIN INVENTTABLEMODULE MODCOMPRA ON MODCOMPRA.ITEMID = IT.ITEMID AND MODCOMPRA.DATAAREAID = IT.DATAAREAID AND MODCOMPRA.MODULETYPE = 1 -- Compra
		JOIN INVENTTABLEMODULE MODVENDA ON MODVENDA.ITEMID = IT.ITEMID AND MODVENDA.DATAAREAID = IT.DATAAREAID AND MODVENDA.MODULETYPE = 2 -- Venda
	WHERE 1=1 
	AND NF.DATAAREAID = 'DELA'
	AND NF.STATUS = 1 
	AND OT.CREATEINVENTTRANS = 1

	UNION

	-- Sa�das

	SELECT 
		LNF.RECID AS LNFRECID,
		P.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		OT.CREATEFINANCIALTRANS, 
		OT.CREATEINVENTTRANS, 
		NF.FISCALDOCUMENTACCOUNTNUM, 
		CF.CFOPID, CF.NAME AS CFOPNAME,  
		LNF.FISCALCLASSIFICATION,
		IT.ITEMID, T.NAME ITEMNAME, 
		S.SALESID AS DOCUMENTOORIGINAL,
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE AS DATA, PT.NAME AS TERCEIRO, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF AS CNPJ, C.IENUM_BR, 
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		'Sa�das' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.LINEAMOUNT,
		LNF.UNIT AS UNIDADENF,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		MODCOMPRA.UNITID AS UNIDADECOMPRA,
		MODVENDA.UNITID AS UNIDADEVENDA
	FROM FISCALDOCUMENT_BR NF
		JOIN FISCALDOCUMENTLINE_BR LNF ON LNF.FISCALDOCUMENT = NF.RECID
		JOIN CUSTINVOICEJOUR I ON I.RECID = NF.REFRECID AND NF.REFTABLEID = 62
		LEFT JOIN SALESTABLE S ON S.SALESID = I.SALESID
		LEFT JOIN SALESTABLE_BR SBR ON SBR.SALESTABLE = S.RECID
		LEFT JOIN SALESPURCHOPERATIONTYPE_BR OT ON OT.RECID = SBR.SALESPURCHOPERATIONTYPE_BR
		JOIN CUSTTABLE C ON C.ACCOUNTNUM = NF.FISCALDOCUMENTACCOUNTNUM
		JOIN DIRPARTYTABLE PT ON PT.RECID = C.PARTY
		JOIN CFOPTABLE_BR CF ON CF.CFOPID = LNF.CFOP AND CF.DATAAREAID = LNF.DATAAREAID
		JOIN INVENTTABLE IT ON IT.ITEMID = LNF.ITEMID AND IT.DATAAREAID = LNF.DATAAREAID
		JOIN ECORESPRODUCT P ON P.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = P.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		OUTER APPLY BiUtil.CategoriaOMT(P.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
		JOIN INVENTTABLEMODULE MODCOMPRA ON MODCOMPRA.ITEMID = IT.ITEMID AND MODCOMPRA.DATAAREAID = IT.DATAAREAID AND MODCOMPRA.MODULETYPE = 1 -- Compra
		JOIN INVENTTABLEMODULE MODVENDA ON MODVENDA.ITEMID = IT.ITEMID AND MODVENDA.DATAAREAID = IT.DATAAREAID AND MODVENDA.MODULETYPE = 2 -- Venda
	WHERE 1=1 
		AND LNF.DATAAREAID = 'DELA'
		AND NF.STATUS = 1
		AND (OT.CREATEINVENTTRANS = 1 OR (OT.OPERATIONTYPEID IN ('S5902/690', 'S5925/6925') AND OT.DATAAREAID = 'OMT'))

	UNION

	-- Transfer�ncias

	SELECT 
		LNF.RECID AS LNFRECID,
		P.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		0 AS CREATEFINANCIALTRANS, 
		1 AS CREATEINVENTTRANS, 
		NF.FISCALDOCUMENTACCOUNTNUM, 
		CF.CFOPID, 
		CF.NAME AS CFOPNAME,  
		LNF.FISCALCLASSIFICATION,
		IT.ITEMID, 
		T.NAME ITEMNAME, 
		S.TRANSFERID AS DOCUMENTOORIGINAL,
		NF.FISCALESTABLISHMENT, 
		NF.ACCOUNTINGDATE AS DATA, 
		PT.NAME AS TERCEIRO, 
		NF.FISCALDOCUMENTNUMBER, 
		NF.THIRDPARTYCNPJCPF AS CNPJ, 
		C.IENUM_BR, 
		LNF.LINEAMOUNT VALORLINHA, 
		'TRANSFER�NCIA' AS OPERATIONTYPEID, 
		'TRANSFER�NCIA' AS OPERATIONNAME,
		'Transfer�ncias' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.LINEAMOUNT,
		LNF.UNIT AS UNIDADENF,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		MODCOMPRA.UNITID AS UNIDADECOMPRA,
		MODVENDA.UNITID AS UNIDADEVENDA
	FROM FISCALDOCUMENT_BR NF
		JOIN FISCALDOCUMENTLINE_BR LNF ON LNF.FISCALDOCUMENT = NF.RECID
		JOIN INVENTTRANSFERJOUR I ON I.RECID = NF.REFRECID AND NF.REFTABLEID = 1706
		LEFT JOIN INVENTTRANSFERTABLE S ON S.TRANSFERID = I.TRANSFERID
		JOIN CUSTTABLE C ON C.ACCOUNTNUM = NF.FISCALDOCUMENTACCOUNTNUM
		JOIN DIRPARTYTABLE PT ON PT.RECID = C.PARTY
		JOIN CFOPTABLE_BR CF ON CF.CFOPID = LNF.CFOP AND CF.DATAAREAID = LNF.DATAAREAID
		JOIN INVENTTABLE IT ON IT.ITEMID = LNF.ITEMID AND IT.DATAAREAID = LNF.DATAAREAID
		JOIN ECORESPRODUCT P ON P.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = P.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		OUTER APPLY BiUtil.CategoriaOMT(P.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
		JOIN INVENTTABLEMODULE MODCOMPRA ON MODCOMPRA.ITEMID = IT.ITEMID AND MODCOMPRA.DATAAREAID = IT.DATAAREAID AND MODCOMPRA.MODULETYPE = 1 -- Compra
		JOIN INVENTTABLEMODULE MODVENDA ON MODVENDA.ITEMID = IT.ITEMID AND MODVENDA.DATAAREAID = IT.DATAAREAID AND MODVENDA.MODULETYPE = 2 -- Venda
	WHERE 1=1 
		AND LNF.DATAAREAID = 'DELA'
		AND NF.STATUS = 1

) AS X

CROSS APPLY BiUtil.DataFiltroAnoMes(X.DATA) AS DATAFILTRO
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADEESTOQUE, ECORESPRODUCTID)	AS ESTOQUE
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADECOMPRA, ECORESPRODUCTID)		AS COMPRA
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADEVENDA, ECORESPRODUCTID)		AS VENDA

UNION 

SELECT * FROM DAX_WELOZE_HIST.BiView.Transacoes_HIST_Delav