
USE DAX_Weloze_HIST;

-- ALTER VIEW [BiView].[Compras_HIST_OMT]  AS

SELECT 
	X.TIPO AS "Tipo de Lançamento",
	X.FISCALDOCUMENTNUMBER	AS "Fatura - Número",
	X.FISCALESTABLISHMENT	AS "Fatura - Estabelecimento Fiscal",
	X.DATA AS "Data",
	DATAFILTRO.MESANO AS "Data - Mês/Ano",
	DATEPART(ISO_WEEK, X.DATA)		AS "Data - Nº da Semana",
	X.ACCOUNTNUM AS "Fornecedor - Código",
	CONCAT(X.ACCOUNTNUM, ' - ', X.FORNECEDOR) AS "Fornecedor - Nome",
	X.CNPJ		AS "Fornecedor - CNPJ",
	X.IENUM_BR AS "Fornecedor - IE",
	X.OPERATIONTYPEID AS "Tipo de Operação - Código",

	CATEGORIACOMPRA.CATEGORIA AS "Categoria de Compra",
	X.CFOPID AS "CFOP - Código",
	CONCAT(X.CFOPID, ' - ', X.CFOPNAME) AS "CFOP - Descrição",

	X.ITEMID AS "Item - Código",
	X.TAXFISCALCLASSIFICATION_BR AS "Item - NCM",
	CONCAT(X.ITEMID, ' - ', X.NAMEALIAS) AS "Item - Nome de Pesquisa",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADENF, ')')		 AS "Item (Un. da Nota Fiscal)",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADECOMPRA, ')')	 AS "Item (Un. de Compra)",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADEESTOQUE, ')') AS "Item (Un. de Estoque)",

	X.QUANTITY AS "Quantidade (Un. da Nota Fiscal)",
	CASE WHEN COMPRA.FATOR IS NULL THEN X.QUANTITY ELSE COMPRA.FATOR * X.QUANTITY END AS "Quantidade (Un. de Compra)",
	CASE WHEN ESTOQUE.FATOR IS NULL THEN X.QUANTITY ELSE ESTOQUE.FATOR * X.QUANTITY END AS "Quantidade (Un. de Estoque)",

	X.CATEGORIA AS "Item - Categoria",
	
	CONCAT(X.OPERATIONTYPEID, ' - ', X.OPERATIONNAME) AS "Tipo de Operação - Descrição",
	
	X.FATOR * (X.VALORLINHA + X.IPI + X.ENCARGOS) AS "Valor Bruto",
	X.FATOR * (X.VALORLINHA + X.IPI) AS "Valor Bruto (s/ Encargos)",
	X.FATOR * (X.VALORLINHA + X.ENCARGOS) AS "Valor s/ IPI",
	X.ENCARGOS AS "Valor Encargos",
	X.FATOR * (X.IPI) AS "Valor IPI",
	X.FATOR * (X.PIS) AS "Valor PIS",
	X.FATOR * (X.ICMS) AS "Valor ICMS",
	X.FATOR * (X.COFINS) AS "Valor COFINS",
	X.FATOR * (X.VALORLINHA + X.ENCARGOS - X.PIS - X.ICMS - X.COFINS) AS "Valor Líquido"

 FROM 
(

	-- Compras

	SELECT PR.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		OT.CREATEFINANCIALTRANS, 
		OT.CREATEINVENTTRANS, 
		V.ACCOUNTNUM,
		CF.CFOPID, CF.NAME AS CFOPNAME,  
		IT.ITEMID, T.NAME ITEMNAME, 
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE AS DATA, PT.NAME AS FORNECEDOR, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF AS CNPJ, V.IENUM_BR,
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		IIPI.VALOR AS IPI,
		IPIS.VALOR AS PIS,
		IICMS.VALOR AS ICMS,
		ICOFINS.VALOR AS COFINS,
		ENCARGO.ENCARGO AS ENCARGOS,
		1 AS FATOR,
		'Compra' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.UNIT AS UNIDADENF,
		MODCOMPRA.UNITID AS UNIDADECOMPRA,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		IT.NAMEALIAS,
		IT.TAXFISCALCLASSIFICATION_BR
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
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 8) AS IIPI
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 1) AS IPIS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 2) AS IICMS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 3) AS ICOFINS
		CROSS APPLY WELO.EncargoLinha (LNF.RECID) AS ENCARGO
		OUTER APPLY BiUtil.CategoriaOMT (PR.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODCOMPRA ON MODCOMPRA.ITEMID = IT.ITEMID AND MODCOMPRA.DATAAREAID = IT.DATAAREAID AND MODCOMPRA.MODULETYPE = 1 -- Compra
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
	WHERE 1=1 
	AND NF.STATUS = 1 
	AND NF.DIRECTION = 1
	AND NF.DATAAREAID = 'OMT'
	AND OT.OPERATIONTYPEID NOT IN ('E1201/2201', 'DV1201/2201', 'E201/202', -- devolução de venda
		'E1406/2406', 'E1551/2551' -- compra do ativo imobilizado
	)
	AND OT.CREATEFINANCIALTRANS = 1 

	UNION

	-- Ordens Devolvidas (Nunca foi usado)

	SELECT PR.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		OT.CREATEFINANCIALTRANS, 
		OT.CREATEINVENTTRANS, 
		V.ACCOUNTNUM,
		CF.CFOPID, CF.NAME AS CFOPNAME,  
		IT.ITEMID, T.NAME ITEMNAME, 
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE AS DATA, PT.NAME AS FORNECEDOR, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF AS CNPJ, V.IENUM_BR,
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		IIPI.VALOR AS IPI,
		IPIS.VALOR AS PIS,
		IICMS.VALOR AS ICMS,
		ICOFINS.VALOR AS COFINS,
		ENCARGO.ENCARGO AS ENCARGOS,
		1 AS FATOR,
		'Ordem Devolvida' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.UNIT AS UNIDADENF,
		MODCOMPRA.UNITID AS UNIDADECOMPRA,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		IT.NAMEALIAS,
		IT.TAXFISCALCLASSIFICATION_BR
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
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 8) AS IIPI
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 1) AS IPIS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 2) AS IICMS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 3) AS ICOFINS
		CROSS APPLY WELO.EncargoLinha (LNF.RECID) AS ENCARGO
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		OUTER APPLY BiUtil.CategoriaOMT (PR.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODCOMPRA ON MODCOMPRA.ITEMID = IT.ITEMID AND MODCOMPRA.DATAAREAID = IT.DATAAREAID AND MODCOMPRA.MODULETYPE = 1 -- Compra
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
	WHERE 1=1 
	AND NF.STATUS = 1 
	AND NF.DIRECTION = 2
	AND NF.DATAAREAID = 'OMT'
	--AND OT.OPERATIONTYPEID NOT IN ('E1201/2201', 'DV1201/2201', 'E201/202')
	AND OT.CREATEFINANCIALTRANS = 1 

	UNION

	-- Devolução por Ordem de Venda

	SELECT PR.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		OT.CREATEFINANCIALTRANS, 
		OT.CREATEINVENTTRANS, 
		VT.ACCOUNTNUM,
		CF.CFOPID, CF.NAME AS CFOPNAME,  
		IT.ITEMID, T.NAME ITEMNAME, 
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE AS DATA, PT.NAME AS FORNECEDOR, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF AS CNPJ, C.IENUM_BR,
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		IIPI.VALOR AS IPI,
		IPIS.VALOR AS PIS,
		IICMS.VALOR AS ICMS,
		ICOFINS.VALOR AS COFINS,
		ENCARGO.ENCARGO AS ENCARGOS,
		-1 AS FATOR,
		'Devolução por Ordem de Venda' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.UNIT AS UNIDADENF,
		MODCOMPRA.UNITID AS UNIDADECOMPRA,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		IT.NAMEALIAS,
		IT.TAXFISCALCLASSIFICATION_BR
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
		JOIN ECORESPRODUCT PR ON PR.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = PR.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 8) AS IIPI
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 1) AS IPIS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 2) AS IICMS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 3) AS ICOFINS
		CROSS APPLY WELO.EncargoLinha (LNF.RECID) AS ENCARGO
		JOIN VENDTABLE VT ON VT.CNPJCPFNUM_BR = C.CNPJCPFNUM_BR AND VT.DATAAREAID = C.DATAAREAID
		CROSS APPLY BiUtil	.CategoriaOMT (PR.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODCOMPRA ON MODCOMPRA.ITEMID = IT.ITEMID AND MODCOMPRA.DATAAREAID = IT.DATAAREAID AND MODCOMPRA.MODULETYPE = 1 -- Compra
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
	WHERE 1=1 
	AND NF.STATUS = 1 
	AND NF.DIRECTION = 2
	AND NF.DATAAREAID = 'OMT'
	AND OT.OPERATIONTYPEID IN ('S413', 'DC5201', 'S5201/6201', 'S5413/6413', 'S5556/6556', 'S201')
	AND OT.CREATEFINANCIALTRANS = 1 

	UNION 

	-- Diários de Fatura de Fornecedor (com grupo que inicie com "F-")

	SELECT '' AS ECORESPRODUCTID,
		'' AS STATUS,
		1 AS DIRECTION,
		L.DATAAREAID,
		1 AS CREATEFINANCIALTRANS,
		0 AS CREATEINVENTTRANS,
		D.DISPLAYVALUE AS ACCOUNTNUM,
		'' AS CFOPID, '' AS CFOPNAME,
		CONCAT('Comprovante ', T.VOUCHER) AS ITEMID, T.TXT AS ITEMNAME,
		ESTABELECIMENTO.VALOR AS FISCALESTABLISHMENT,
		T.TRANSDATE AS DATA, PT.NAME AS FORNECEDOR,
		CONCAT('Fatura ', T.INVOICE, ' - Diário ', L.JOURNALNUM) AS FISCALDOCUMENTNUMBER,
		V.CNPJCPFNUM_BR AS CNPJ, V.IENUM_BR, 
		T.AMOUNTCURCREDIT - T.AMOUNTCURDEBIT AS VALORLINHA, 
		'' AS OPERATIONTYPEID, '' AS OPERATIONNAME,
		(SELECT ABS(ISNULL(SUM(TT.TAXAMOUNT), 0)) FROM TAXTRANS TT WHERE TT.SOURCERECID = T.RECID AND TT.SOURCETABLEID = 212 AND TT.TAXPERIOD IN ('IPI', 'IPIIND')) AS IPI,
		(SELECT ABS(ISNULL(SUM(TT.TAXAMOUNT), 0)) FROM TAXTRANS TT WHERE TT.SOURCERECID = T.RECID AND TT.SOURCETABLEID = 212 AND TT.TAXPERIOD IN ('PIS')) AS PIS,
		(SELECT ABS(ISNULL(SUM(TT.TAXAMOUNT), 0)) FROM TAXTRANS TT WHERE TT.SOURCERECID = T.RECID AND TT.SOURCETABLEID = 212 AND TT.TAXPERIOD IN ('ICMS IND.', 'ICMSIND')) AS ICMS,
		(SELECT ABS(ISNULL(SUM(TT.TAXAMOUNT), 0)) FROM TAXTRANS TT WHERE TT.SOURCERECID = T.RECID AND TT.SOURCETABLEID = 212 AND TT.TAXPERIOD IN ('COFINS')) AS COFINS,
		0 AS ENCARGOS,
		1 AS FATOR,
		'Diário' AS TIPO,
		T.LINENUM AS NUMLINHA,
		'Sem Categoria' AS CATEGORIA,
		1 AS QUANTITY,
		'Diário' AS UNIDADENF,
		'Diário' AS UNIDADECOMPRA,
		'Diário' AS UNIDADEESTOQUE,
		'Diário' AS NAMEALIAS,
		'0000.00.00'
	FROM LEDGERJOURNALTABLE L
		JOIN LEDGERJOURNALTRANS T ON T.JOURNALNUM = L.JOURNALNUM AND T.ACCOUNTTYPE = 2 AND L.JOURNALTYPE = 10 -- AND T.AMOUNTCURCREDIT > 0
		JOIN DIMENSIONATTRIBUTEVALUECOMBINATION D ON D.RECID = T.LEDGERDIMENSION
		JOIN VENDTABLE V ON V.ACCOUNTNUM = D.DISPLAYVALUE AND (V.VENDGROUP LIKE 'F-%' OR V.VENDGROUP LIKE 'F %')
		JOIN DIRPARTYTABLE PT ON PT.RECID = V.PARTY
		OUTER APPLY BIUTIL.DimensaoFinanceira (T.DEFAULTDIMENSION, 'ESTABELECIMENTO') AS ESTABELECIMENTO
	WHERE L.JOURNALNAME != 'CTRC' 
		--AND L.DATAAREAID = 'DELA' AND T.TRANSDATE >= '2014-07-01'
		AND L.DATAAREAID = 'OMT' AND T.TRANSDATE >= '2015-01-01'
	
) AS X

CROSS APPLY BIUTIL.DataFiltroAnoMes(X.DATA) AS DATAFILTRO
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADEESTOQUE, ECORESPRODUCTID)	AS ESTOQUE
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADECOMPRA, ECORESPRODUCTID)		AS COMPRA
OUTER APPLY BiUtil.CategoriaCompra(X.CFOPID) AS CATEGORIACOMPRA