
-- ALTER VIEW [BiView].[DesoneracaoFolha_Nopin]  AS

SELECT 

	CASE X.PAYROLLDISCHARGEGROUPSTATUS 
		WHEN 0 THEN '1 - N�o Incentivado'
		WHEN 1 THEN '2 - Incentivado'
		ELSE		'3 - N�o Definido '
	END AS "Desonera��o",

	X.[Grupo CFOP/NCM],

	X.TIPO					AS "Nota Fiscal - Tipo",
	X.FISCALDOCUMENTNUMBER	AS "Nota Fiscal - N�mero",
	X.FISCALESTABLISHMENT	AS "Nota Fiscal - Estabelecimento Fiscal",
	X.NUMLINHA				AS "Nota Fiscal - N�mero da Linha",

	X.FISCALDOCUMENTDATE						AS "Data",
	DATAFILTRO.MESANO							AS "Data - M�s/Ano",
	DATEPART(ISO_WEEK, X.FISCALDOCUMENTDATE)	AS "Data - N� da Semana",

	CONCAT(X.FISCALDOCUMENTACCOUNTNUM, ' - ', X.CLIENTE) AS "Cliente - Nome",

	X.FISCALCLASSIFICATION	AS "Item - NCM",
	X.CATEGORIA				AS "Item - Categoria",

	X.OPERATIONTYPEID									AS "Tipo de Opera��o - C�digo",
	CONCAT(X.OPERATIONTYPEID, ' - ', X.OPERATIONNAME)	AS "Tipo de Opera��o - Descri��o",

	X.CFOPID							AS "CFOP - C�digo",
	CONCAT(X.CFOPID, ' - ', X.CFOPNAME) AS "CFOP - Descri��o",

	X.DOCUMENTOORIGINAL AS "Ordem de Compra/Venda",
	X.GRUPOVENDA		AS "Grupo de Vendas",

	X.ITEMID															AS "Item - C�digo",
	CONCAT(X.ITEMID, ' - ', X.NAMEALIAS)								AS "Item - Nome de Pesquisa",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADENF, ')')			AS "Item (Un. da Nota Fiscal)",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADEVENDA, ')')		AS "Item (Un. de Venda)",
	CONCAT(X.ITEMID, ' - ', X.ITEMNAME, ' (', X.UNIDADEESTOQUE, ')')	AS "Item (Un. de Estoque)",

	X.FATOR * (X.VALORLINHA + X.IPI + X.ENCARGOS)	AS "Valor Fat. Bruto",
	X.IPI											AS "Valor IPI",
	X.FATOR * (X.VALORLINHA + X.ENCARGOS)			AS "Valor Rec. Bruta (s/ IPI)"

 FROM 
(

	-- Sa�das de faturamento (excluindo devolu��es de compra e simples faturamento)

	SELECT P.RECID AS ECORESPRODUCTID,
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
		NF.FISCALESTABLISHMENT, NF.FISCALDOCUMENTDATE, PT.NAME AS CLIENTE, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF, C.IENUM_BR, 
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		IIPI.VALOR AS IPI,
		IPIS.VALOR AS PIS,
		COALESCE(IICMS.VALOR, 0) + COALESCE(IICMSDIF.VALOR, 0) AS ICMS,
		ICOFINS.VALOR AS COFINS,
		IISSQN.VALOR AS ISSQN,
		ENCARGO.ENCARGO AS ENCARGOS,
		1 AS FATOR,
		'Venda' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.UNIT AS UNIDADENF,
		MODVENDA.UNITID AS UNIDADEVENDA,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		IT.NAMEALIAS,
		C.SEGMENTID,
		C.SUBSEGMENTID,
		C.LINEOFBUSINESSID,
		S.SALESGROUP AS GRUPOVENDA,
		LPA.COUNTRYREGIONID PAIS,
		LPA.STATE AS ESTADO,
		LPA.CITY AS CIDADE,
		PDG.PAYROLLDISCHARGEGROUPSTATUS,
		CONCAT(LNF.CFOP, ' - ', LNF.FISCALCLASSIFICATION) AS "Grupo CFOP/NCM"
	FROM FISCALDOCUMENT_BR NF
		JOIN FISCALDOCUMENTLINE_BR LNF ON LNF.FISCALDOCUMENT = NF.RECID
		JOIN CUSTINVOICEJOUR I ON I.RECID = NF.REFRECID AND NF.REFTABLEID = 62
		LEFT JOIN SALESTABLE S ON S.SALESID = I.SALESID
		LEFT JOIN SALESTABLE_BR SBR ON SBR.SALESTABLE = S.RECID
		LEFT JOIN BI_WELOZE.[dbo].[FISCALDOCUMENT_OPERATIONTYPEBR] FDOT 
			ON FDOT.FISCALDOCUMENTNUMBER = NF.FISCALDOCUMENTNUMBER 
				AND FDOT.SALESID = I.SALESID
		LEFT JOIN SALESPURCHOPERATIONTYPE_BR OT ON 
			(OT.RECID = SBR.SALESPURCHOPERATIONTYPE_BR 
			OR OT.OPERATIONTYPEID = FDOT.OPERATIONTYPE
			)
		JOIN CUSTTABLE C ON C.ACCOUNTNUM = NF.FISCALDOCUMENTACCOUNTNUM
		JOIN DIRPARTYTABLE PT ON PT.RECID = C.PARTY
		JOIN CFOPTABLE_BR CF ON CF.CFOPID = LNF.CFOP AND CF.DATAAREAID = LNF.DATAAREAID
		JOIN INVENTTABLE IT ON IT.ITEMID = LNF.ITEMID AND IT.DATAAREAID = LNF.DATAAREAID
		JOIN ECORESPRODUCT P ON P.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = P.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 8) AS IIPI
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 1) AS IPIS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 2) AS IICMS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 15) AS IICMSDIF
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 3) AS ICOFINS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 4) AS IISSQN
		CROSS APPLY WELO.EncargoLinha (LNF.RECID) AS ENCARGO
		OUTER APPLY BiUtil.CategoriaNopin(P.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODVENDA ON MODVENDA.ITEMID = IT.ITEMID AND MODVENDA.DATAAREAID = IT.DATAAREAID AND MODVENDA.MODULETYPE = 2 -- Venda
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
		JOIN LOGISTICSLOCATION LL ON LL.RECID = PT.PRIMARYADDRESSLOCATION
		JOIN LOGISTICSPOSTALADDRESS LPA ON LPA.LOCATION = LL.RECID AND CONVERT(DATE, GETDATE()) BETWEEN LPA.VALIDFROM AND LPA.VALIDTO
		LEFT JOIN PAYROLLDISCHARGEGROUP PDG ON PDG.CFOPID_BR = LNF.CFOP AND PDG.TAXFISCALCLASSIFICATIONID_BR = LNF.FISCALCLASSIFICATION
	WHERE 1=1 
		AND LNF.DATAAREAID = 'NBRA'
		AND NF.STATUS = 1 -- Status da Nota Fiscal = Aprovado
		AND NF.DIRECTION = 2 -- Dire��o Sa�da
		AND (( 
			OT.CREATEFINANCIALTRANS = 1 -- Movimenta financeiro
			AND OT.OPERATIONTYPEID NOT IN (
				'S5556/6556', 'S5201/6201', 'S5410', 'S5412/6412', 'S5413/6413', 'S5553/6553', 'S5556/6556', 'S5201/6201', 'S413', 'S201', 'S5206', 'DC5201', 'S5413', -- devolu��o de compra
				'S5206/6206', 'S5206', -- anula��o de frete
				'S5551/6551' -- desconsidera venda de ativo imobilizado
					)
				)
			OR (OT.OPERATIONTYPEID = 'S5902/5124' AND LNF.CFOP = '5.124') -- opera��o especial Master
			OR (OT.OPERATIONTYPEID = 'T5902/5124' AND LNF.CFOP = '5.124') -- opera��o especial Master
		)


	UNION

	-- Ordens de Devolu��o

	SELECT P.RECID AS ECORESPRODUCTID,
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
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE, PT.NAME AS CLIENTE, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF, C.IENUM_BR, 
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		IIPI.VALOR AS IPI,
		IPIS.VALOR AS PIS,
		COALESCE(IICMS.VALOR, 0) + COALESCE(IICMSDIF.VALOR, 0) AS ICMS,
		ICOFINS.VALOR AS COFINS,
		IISSQN.VALOR AS ISSQN,
		ENCARGO.ENCARGO AS ENCARGOS,
		-1 AS FATOR, 
		'Ordem Devolvida' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.UNIT AS UNIDADENF,
		MODVENDA.UNITID AS UNIDADEVENDA,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		IT.NAMEALIAS,
		C.SEGMENTID,
		C.SUBSEGMENTID,
		C.LINEOFBUSINESSID,
		S.SALESGROUP AS GRUPOVENDA,
		LPA.COUNTRYREGIONID PAIS,
		LPA.STATE AS ESTADO,
		LPA.CITY AS CIDADE,
		PDG.PAYROLLDISCHARGEGROUPSTATUS,
		CONCAT(LNF.CFOP, ' - ', LNF.FISCALCLASSIFICATION) AS "Grupo CFOP/NCM"
	FROM FISCALDOCUMENT_BR NF
		JOIN FISCALDOCUMENTLINE_BR LNF ON LNF.FISCALDOCUMENT = NF.RECID
		JOIN CUSTINVOICEJOUR I ON I.RECID = NF.REFRECID AND NF.REFTABLEID = 62
		LEFT JOIN SALESTABLE S ON S.SALESID = I.SALESID
		LEFT JOIN SALESTABLE_BR SBR ON SBR.SALESTABLE = S.RECID
		LEFT JOIN BI_WELOZE.[dbo].[FISCALDOCUMENT_OPERATIONTYPEBR] FDOT 
			ON FDOT.FISCALDOCUMENTNUMBER = NF.FISCALDOCUMENTNUMBER 
				AND FDOT.SALESID = I.SALESID
		LEFT JOIN SALESPURCHOPERATIONTYPE_BR OT ON 
			(OT.RECID = SBR.SALESPURCHOPERATIONTYPE_BR 
			OR OT.OPERATIONTYPEID = FDOT.OPERATIONTYPE
			)
		JOIN CUSTTABLE C ON C.ACCOUNTNUM = NF.FISCALDOCUMENTACCOUNTNUM
		JOIN DIRPARTYTABLE PT ON PT.RECID = C.PARTY
		JOIN CFOPTABLE_BR CF ON CF.CFOPID = LNF.CFOP AND CF.DATAAREAID = LNF.DATAAREAID
		JOIN INVENTTABLE IT ON IT.ITEMID = LNF.ITEMID AND IT.DATAAREAID = LNF.DATAAREAID
		JOIN ECORESPRODUCT P ON P.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = P.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 8) AS IIPI
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 1) AS IPIS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 2) AS IICMS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 15) AS IICMSDIF
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 3) AS ICOFINS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 4) AS IISSQN
		CROSS APPLY WELO.EncargoLinha (LNF.RECID) AS ENCARGO
		OUTER APPLY BiUtil.CategoriaNopin(P.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODVENDA ON MODVENDA.ITEMID = IT.ITEMID AND MODVENDA.DATAAREAID = IT.DATAAREAID AND MODVENDA.MODULETYPE = 2 -- Venda
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
		JOIN LOGISTICSLOCATION LL ON LL.RECID = PT.PRIMARYADDRESSLOCATION
		JOIN LOGISTICSPOSTALADDRESS LPA ON LPA.LOCATION = LL.RECID AND CONVERT(DATE, GETDATE()) BETWEEN LPA.VALIDFROM AND LPA.VALIDTO
		LEFT JOIN PAYROLLDISCHARGEGROUP PDG ON PDG.CFOPID_BR = LNF.CFOP AND PDG.TAXFISCALCLASSIFICATIONID_BR = LNF.FISCALCLASSIFICATION
	WHERE 1=1 
		AND LNF.DATAAREAID = 'NBRA'
		AND NF.STATUS = 1 
		AND NF.DIRECTION = 1
		AND (
			(OT.CREATEFINANCIALTRANS = 1 AND
			OT.OPERATIONTYPEID IN ('F116', 'S101/102', 'S107/108', 'S118', 'S501', 'S5101', 'S5101 001', 'S5101 V.SU', 
				'S5102', 'S5116', 'S5116/6116', 'S5122/6122', 'S5124/5125', 'S5124/S5125', 'S5501/6501', 'S5118', 'S5118/6118', 
				'S5551/6551', 'S6101', 'S6101 001', 'S6116', 'S6118', 'S6122', 'S6124/6125', 'S7101/7127', 'S933', 
				'SFERRAM.RA', 'SFERRAMENT', 'SSUCATAS'))
			OR (OT.OPERATIONTYPEID = 'S5902/5124' AND LNF.CFOP = '1.949') -- opera��o especial Master
			OR (OT.OPERATIONTYPEID = 'T5902/5124' AND LNF.CFOP = '1.949') -- opera��o especial Master
		)
		
	UNION

	-- Devolu��es por Ordem de Compra

	SELECT P.RECID AS ECORESPRODUCTID,
		NF.STATUS,
		NF.DIRECTION,
		NF.DATAAREAID AS EMPRESA, 
		OT.CREATEFINANCIALTRANS, 
		OT.CREATEINVENTTRANS, 
		CT.ACCOUNTNUM,
		CF.CFOPID, CF.NAME AS CFOPNAME,  
		LNF.FISCALCLASSIFICATION,
		IT.ITEMID, T.NAME ITEMNAME, 
		P.PURCHID AS DOCUMENTOORIGINAL,
		NF.FISCALESTABLISHMENT, NF.ACCOUNTINGDATE, PT.NAME AS CLIENTE, 
		NF.FISCALDOCUMENTNUMBER, NF.THIRDPARTYCNPJCPF, V.IENUM_BR,
		LNF.LINEAMOUNT VALORLINHA, OT.OPERATIONTYPEID, OT.NAME AS OPERATIONNAME,
		IIPI.VALOR AS IPI,
		IPIS.VALOR AS PIS,
		COALESCE(IICMS.VALOR, 0) + COALESCE(IICMSDIF.VALOR, 0) AS ICMS,
		ICOFINS.VALOR AS COFINS,
		IISSQN.VALOR AS ISSQN,
		ENCARGO.ENCARGO AS ENCARGOS,
		-1 AS FATOR,
		'Devolu��o por Ordem de Compra' AS TIPO,
		LNF.LINENUM AS NUMLINHA,
		CATEGORIA.CATEGORIA,
		LNF.QUANTITY,
		LNF.UNIT AS UNIDADENF,
		MODVENDA.UNITID AS UNIDADEVENDA,
		MODESTOQUE.UNITID AS UNIDADEESTOQUE,
		IT.NAMEALIAS,
		CT.SEGMENTID,
		CT.SUBSEGMENTID,
		CT.LINEOFBUSINESSID,
		'DEV POR O.C.' AS GRUPOVENDA,
		LPA.COUNTRYREGIONID PAIS,
		LPA.STATE AS ESTADO,
		LPA.CITY AS CIDADE,
		PDG.PAYROLLDISCHARGEGROUPSTATUS,
		CONCAT(LNF.CFOP, ' - ', LNF.FISCALCLASSIFICATION) AS "Grupo CFOP/NCM"
	FROM FISCALDOCUMENT_BR NF
		JOIN FISCALDOCUMENTLINE_BR LNF ON LNF.FISCALDOCUMENT = NF.RECID
		JOIN VENDINVOICEJOUR I ON I.RECID = NF.REFRECID AND NF.REFTABLEID = 491
		LEFT JOIN PURCHTABLE P ON P.PURCHID = I.PURCHID
		LEFT JOIN PURCHTABLE_BR PBR ON PBR.PURCHTABLE = P.RECID
		LEFT JOIN BI_WELOZE.[dbo].[FISCALDOCUMENT_OPERATIONTYPEBR] FDOT 
			ON FDOT.FISCALDOCUMENTNUMBER = NF.FISCALDOCUMENTNUMBER 
				AND FDOT.SALESID = I.PURCHID
		LEFT JOIN SALESPURCHOPERATIONTYPE_BR OT ON 
			(OT.RECID = PBR.SALESPURCHOPERATIONTYPE_BR 
			OR OT.OPERATIONTYPEID = FDOT.OPERATIONTYPE
			)
		JOIN VENDTABLE V ON V.ACCOUNTNUM = NF.FISCALDOCUMENTACCOUNTNUM
		JOIN DIRPARTYTABLE PT ON PT.RECID = V.PARTY
		JOIN CFOPTABLE_BR CF ON CF.CFOPID = LNF.CFOP AND CF.DATAAREAID = LNF.DATAAREAID
		JOIN INVENTTABLE IT ON IT.ITEMID = LNF.ITEMID AND IT.DATAAREAID = LNF.DATAAREAID
		JOIN ECORESPRODUCT PR ON PR.RECID = IT.PRODUCT
		JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = PR.RECID
		JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
		JOIN CUSTTABLE CT ON CT.CNPJCPFNUM_BR = V.CNPJCPFNUM_BR AND CT.DATAAREAID = V.DATAAREAID
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 8) AS IIPI
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 1) AS IPIS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 2) AS IICMS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 15) AS IICMSDIF
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 3) AS ICOFINS
		CROSS APPLY WELO.ImpostoLinha (LNF.RECID, 4) AS IISSQN
		CROSS APPLY WELO.EncargoLinha (LNF.RECID) AS ENCARGO
		OUTER APPLY BiUtil.CategoriaNopin(P.RECID) AS CATEGORIA
		JOIN INVENTTABLEMODULE MODVENDA ON MODVENDA.ITEMID = IT.ITEMID AND MODVENDA.DATAAREAID = IT.DATAAREAID AND MODVENDA.MODULETYPE = 2 -- Venda
		JOIN INVENTTABLEMODULE MODESTOQUE ON MODESTOQUE.ITEMID = IT.ITEMID AND MODESTOQUE.DATAAREAID = IT.DATAAREAID AND MODESTOQUE.MODULETYPE = 0 -- Estoque
		JOIN LOGISTICSLOCATION LL ON LL.RECID = PT.PRIMARYADDRESSLOCATION
		JOIN LOGISTICSPOSTALADDRESS LPA ON LPA.LOCATION = LL.RECID AND CONVERT(DATE, GETDATE()) BETWEEN LPA.VALIDFROM AND LPA.VALIDTO
		LEFT JOIN PAYROLLDISCHARGEGROUP PDG ON PDG.CFOPID_BR = LNF.CFOP AND PDG.TAXFISCALCLASSIFICATIONID_BR = LNF.FISCALCLASSIFICATION
	WHERE 1=1 
		AND NF.STATUS = 1 
		AND NF.DIRECTION = 1
		AND LNF.DATAAREAID = 'NBRA'
		AND OT.OPERATIONTYPEID IN ('E1201/2201', 'DV1201/2201', 'E201/202', 'E3201')
		AND OT.CREATEFINANCIALTRANS = 1 
) AS X

CROSS APPLY BI.DataFiltroAnoMes(X.FISCALDOCUMENTDATE) AS DATAFILTRO
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADEESTOQUE, ECORESPRODUCTID)	AS ESTOQUE
OUTER APPLY BiUtil.FatorConversaoUnidades (UNIDADENF, UNIDADEVENDA, ECORESPRODUCTID)	AS COMPRA
