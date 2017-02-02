
-- ALTER VIEW [BiView].[OrdensVendaLiquidaComRemessas_Delav]  AS 

SELECT 

	S.SALESID AS "Ordem de Venda - Número",
	STATUS.STATUS AS "Ordem de Venda - Status",

	CASE WHEN REMAINSALESPHYSICAL > 0 THEN 'Sim' ELSE 'Não' END AS "Ordem de Venda - Pendente",

	CASE ESTABELECIMENTO.VALOR 
		WHEN NULL THEN 'Não definido' 
		ELSE ESTABELECIMENTO.VALOR 
	END AS Estabelecimento,

	CONVERT(DATETIME, CONVERT(VARCHAR, S.CREATEDDATETIME , 101)) AS "Data de Criação",
	CONCAT('Semana ', DATEPART(ISO_WEEK, S.CREATEDDATETIME))	AS "Data de Criação - Nº da Semana",
	DATAMESANO.MESANO AS "Data de Criação - Mês/Ano",

	L.SHIPPINGDATEREQUESTED AS "Data de Entrega",
	ENTREGA.MESANO AS "Data de Entrega - Mês/Ano",
	
	C.CNPJCPFNUM_BR AS "Cliente - CNPJ",
	C.ACCOUNTNUM	AS "Cliente - Código",
	PT.NAME			AS "Cliente - Nome",
	CONCAT(C.ACCOUNTNUM, ' - ', PT.NAME) AS "Cliente - Código e Nome",

	O.OPERATIONTYPEID AS "Tipo de Operaçao",

	CF.CFOPID	AS "CFOP - Código",  
	CF.NAME		AS "CFOP - Nome",
	CONCAT(CF.CFOPID, ' - ', CF.NAME)	AS "CFOP - Código e Nome",

	I.ITEMID						AS "Item - Código",
	T.NAME							AS "Item - Nome",
	CONCAT(I.ITEMID, ' - ', T.NAME) AS "Item - Código e Nome",
	CATEGORIA.CATEGORIA				AS "Item - Categoria",

	D.INVENTBATCHID AS "Dimensão - Lote",
	D.INVENTCOLORID AS "Dimensão - Cor",
	D.INVENTLOCATIONID AS "Dimensão - Depósito",
	D.INVENTSERIALID AS "Dimensão - Número de Série",
	D.INVENTSITEID AS "Dimensão - Site",
	D.INVENTSIZEID AS "Dimensão - Tensão",
	D.INVENTSTYLEID AS "Dimensão - Largura da Lâmina",
	D.WMSLOCATIONID AS "Dimensão - Localização",

	L.SALESQTY AS "Quantidade Total",
	L.REMAINSALESPHYSICAL AS "Quantidade Pendente",

	L.LINEAMOUNT + COALESCE(IPI.VALOR, 0) + COALESCE(ENCARGO.VALOR, 0) AS "Valor Bruto",
	L.LINEAMOUNT + COALESCE(IPI.VALOR, 0) AS "Valor Bruto s/ Encargos",
	L.LINEAMOUNT + COALESCE(ENCARGO.VALOR, 0) AS "Valor Bruto s/ IPI",
	COALESCE(ENCARGO.VALOR, 0) AS "Valor Encargos",
	COALESCE(IPI.VALOR, 0) AS "Valor IPI",
	COALESCE(PIS.VALOR, 0) AS "Valor PIS",
	COALESCE(ICMS.VALOR, 0) AS "Valor ICMS",
	COALESCE(COFINS.VALOR, 0) AS "Valor COFINS",
	COALESCE(ISSQN.VALOR, 0) AS "Valor ISSQN",
	L.LINEAMOUNT + COALESCE(ENCARGO.VALOR, 0) - COALESCE(PIS.VALOR, 0) - COALESCE(COFINS.VALOR, 0) - COALESCE(ICMS.VALOR, 0) - COALESCE(ISSQN.VALOR, 0) AS "Valor Líquido",

	(L.LINEAMOUNT + COALESCE(IPI.VALOR, 0) + COALESCE(ENCARGO.VALOR, 0)) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor Bruto Pendente",
	(L.LINEAMOUNT + COALESCE(IPI.VALOR, 0)) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor Bruto s/ Encargos Pendente",
	(L.LINEAMOUNT + COALESCE(ENCARGO.VALOR, 0)) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor Bruto s/ IPI Pendente",
	COALESCE(ENCARGO.VALOR, 0) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor Encargos Pendente",
	COALESCE(IPI.VALOR, 0) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor IPI Pendente",
	COALESCE(PIS.VALOR, 0) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor PIS Pendente",
	COALESCE(ICMS.VALOR, 0) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor ICMS Pendente",
	COALESCE(COFINS.VALOR, 0) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor COFINS Pendente",
	(COALESCE(ISSQN.VALOR, 0)) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor ISSQN Pendente",
	(L.LINEAMOUNT + COALESCE(ENCARGO.VALOR, 0) - COALESCE(PIS.VALOR, 0) - COALESCE(COFINS.VALOR, 0) - COALESCE(ICMS.VALOR, 0) - COALESCE(ISSQN.VALOR, 0)) / L.SALESQTY * L.REMAINSALESPHYSICAL AS "Valor Líquido Pendente"

FROM SALESTABLE S	
	JOIN SALESTABLE_BR SBR ON SBR.SALESTABLE = S.RECID
	JOIN SALESLINE L ON L.SALESID = S.SALESID	
	JOIN SALESLINE_BR LBR ON LBR.SALESLINE = L.RECID
	JOIN INVENTTABLE i	ON I.ITEMID = L.ITEMID	AND I.DATAAREAID = L.DATAAREAID	
	JOIN ECORESPRODUCT PR ON PR.RECID = I.PRODUCT
	OUTER APPLY BI.DimensaoFinanceira(S.DEFAULTDIMENSION, 'ESTABELECIMENTO') AS ESTABELECIMENTO
	JOIN CUSTTABLE C ON C.ACCOUNTNUM = S.CUSTACCOUNT	
	JOIN DIRPARTYTABLE	PT ON PT.RECID = C.PARTY		
	LEFT JOIN SALESPURCHOPERATIONTYPE_BR O ON O.RECID = SBR.SALESPURCHOPERATIONTYPE_BR	
	LEFT JOIN CFOPTABLE_BR CF ON CF.RECID = LBR.CFOPTABLE_BR
	JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = PR.RECID
	LEFT JOIN MARKUPTRANS M ON M.TRANSRECID = L.RECID AND M.TRANSTABLEID = 359
	JOIN INVENTDIM D ON D.INVENTDIMID = L.INVENTDIMID

	CROSS APPLY BI.DataFiltroAnoMes(S.CREATEDDATETIME) AS DATAMESANO
	CROSS APPLY BI.CategoriaOMT(PR.RECID) AS CATEGORIA
	CROSS APPLY BI.StatusOrdemVenda (S.SALESSTATUS) AS STATUS
	CROSS APPLY BI.DataFiltroAnoMes(L.SHIPPINGDATEREQUESTED) AS ENTREGA	

	OUTER APPLY BiUtil.EncargoLinhaOrdemVenda (L.RECID) AS ENCARGO
	OUTER APPLY BiUtil.ImpostoPorGrupos (S.DATAAREAID, L.TAXGROUP, L.TAXITEMGROUP, 2, L.LINEAMOUNT) AS ICMS
	OUTER APPLY BiUtil.ImpostoPorGrupos (S.DATAAREAID, L.TAXGROUP, L.TAXITEMGROUP, 8, L.LINEAMOUNT) AS IPI
	OUTER APPLY BiUtil.ImpostoPorGrupos (S.DATAAREAID, L.TAXGROUP, L.TAXITEMGROUP, 1, L.LINEAMOUNT) AS PIS
	OUTER APPLY BiUtil.ImpostoPorGrupos (S.DATAAREAID, L.TAXGROUP, L.TAXITEMGROUP, 3, L.LINEAMOUNT) AS COFINS
	OUTER APPLY BiUtil.ImpostoPorGrupos (S.DATAAREAID, L.TAXGROUP, L.TAXITEMGROUP, 4, L.LINEAMOUNT) AS ISSQN

WHERE L.DATAAREAID	= 'DELA' AND L.SALESQTY != 0
	AND	O.CREATEINVENTTRANS = 1
	AND S.SALESSTATUS != 4 -- Cancelada
	AND S.SALESTYPE != 4 -- Ordem devolvida