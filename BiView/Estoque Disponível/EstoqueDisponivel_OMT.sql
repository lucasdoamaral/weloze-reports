
-- ALTER VIEW [BiView].[EstoqueDisponivel_OMT]  AS 

SELECT * FROM 

(
SELECT 

	X.CATEGORIA_COMPLETA_ AS "Item - Categoria",
	CD_ITEM AS "Item - Código",
	CONCAT(CD_ITEM, ' - ', NM_ITEM, ' (', UNIDADE_ESTOQUE, ')') AS "Item - Nome", 
	CONCAT(CD_ITEM, ' - ', NM_PESQUISA_ITEM) AS "Item - Nome de Pesquisa",
	X.GRUPO AS "Item - Grupo",
	
	X.QTD_DEDUZIDA AS "Estoque - Deduzido",
	X.QTD_ENCOMENDADA AS "Estoque - Encomendado",
	X.QTD_ORDEM + QTD_RESERVADA_ORDEM AS "Estoque - Em Ordem",
	X.QTD_SALDO + X.QTD_RECEBIDA - X.QTD_DEDUZIDA + X.QTD_REGISTRADA - X.QTD_SEPARADA AS "Estoque - Estoque Físico",
	X.QTD_SALDO + X.QTD_RECEBIDA - X.QTD_DEDUZIDA + X.QTD_REGISTRADA - X.QTD_SEPARADA - X.QTD_ORDEM - QTD_RESERVADA_ORDEM + X.QTD_ENCOMENDADA AS "Estoque - Saldo Disponível",
	
	VL_ESTOQUE AS "Custo Total",
	
	X.Cor AS "Dimensão - Cor",
	X.Lote AS "Dimensão - Lote",
	X.Site AS "Dimensão - Site ", 
	X.Tensão AS "Dimensão - Tensão",
	X.Depósito AS "Dimensão - Depósito", 
	X.Localização AS "Dimensão - Localização", 
	X.TAXFISCALCLASSIFICATION_BR AS "Item - NCM",
	X.[Número de Série] AS "Dimensão - Número de Série",
	X.[Largura da Lâmina] AS "Dimensão - Largura da Lâmina",
	X.TAXITEMGROUPID_COMPRA AS "Item - Grupo de Impostos (Compra)",
	X.TAXITEMGROUPID_VENDA AS "Item - Grupo de Impostos (Venda)"

	FROM (

SELECT 

	CATEGORIA.CATEGORIA AS CATEGORIA_COMPLETA_,
	I.ITEMID AS CD_ITEM,
	T.NAME AS NM_ITEM,
	I.NAMEALIAS AS NM_PESQUISA_ITEM,
	
	SUM(POSTEDQTY) AS QTD_SALDO, 
	SUM(POSTEDVALUE) AS VL_ESTOQUE, 
	SUM(ONORDER) AS QTD_ORDEM, 
	SUM(DEDUCTED) AS QTD_DEDUZIDA, 
	SUM(RECEIVED) AS QTD_RECEBIDA, 
	SUM(RESERVPHYSICAL) QTD_RESERVA, 
	SUM(RESERVORDERED) AS QTD_RESERVADA_ORDEM, 
	SUM(ORDERED) AS QTD_ENCOMENDADA, 
	SUM(QUOTATIONISSUE) AS QTD_COTACAO, 
	SUM(REGISTERED) AS QTD_REGISTRADA, 
	SUM(PICKED) AS QTD_SEPARADA,

	D.WMSLOCATIONID AS "Localização", 
	D.INVENTLOCATIONID AS Depósito, 
	D.INVENTSITEID AS Site,
	D.INVENTSIZEID AS Tensão,
	D.INVENTSTYLEID AS "Largura da Lâmina",
	D.INVENTCOLORID AS Cor,
	D.INVENTSERIALID AS "Número de Série",
	D.INVENTBATCHID AS Lote,
	I.TAXFISCALCLASSIFICATION_BR,
	MC.TAXITEMGROUPID AS TAXITEMGROUPID_COMPRA,
	MV.TAXITEMGROUPID AS TAXITEMGROUPID_VENDA,
	CONCAT(G.ITEMGROUPID, ' - ', GR.NAME) AS GRUPO,
	ME.UNITID AS UNIDADE_ESTOQUE

FROM INVENTTABLE I	
	JOIN ECORESPRODUCT P ON P.RECID = I.PRODUCT
	LEFT JOIN ECORESPRODUCTCATEGORY PC ON PC.PRODUCT = P.RECID
	JOIN ECORESPRODUCTTRANSLATION T ON T.PRODUCT = P.RECID
	JOIN LANGUAGETABLE L ON L.LANGUAGEID = T.LANGUAGEID
	JOIN INVENTSUM "IS" ON "IS".ITEMID = I.ITEMID AND I.DATAAREAID = "IS".DATAAREAID
	JOIN INVENTMODELGROUPITEM MGI ON MGI.ITEMID = I.ITEMID AND MGI.ITEMDATAAREAID = I.DATAAREAID
	LEFT JOIN ECORESCATEGORY C1 ON PC.CATEGORY = C1.RECID
	LEFT JOIN ECORESCATEGORY C2 ON C2.RECID = C1.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C3 ON C3.RECID = C2.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C4 ON C4.RECID = C3.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C5 ON C5.RECID = C4.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C6 ON C6.RECID = C5.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C7 ON C7.RECID = C6.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C8 ON C8.RECID = C7.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C9 ON C9.RECID = C8.PARENTCATEGORY
	LEFT JOIN ECORESCATEGORY C10 ON C10.RECID = C9.PARENTCATEGORY
	JOIN INVENTDIM D ON D.INVENTDIMID = "IS".INVENTDIMID
	OUTER APPLY BiUtil.CategoriaOMT(P.RECID) AS CATEGORIA
	JOIN INVENTTABLEMODULE ME ON ME.ITEMID = I.ITEMID AND ME.DATAAREAID = I.DATAAREAID AND ME.MODULETYPE = 0 -- Estoque
	JOIN INVENTTABLEMODULE MC ON MC.ITEMID = I.ITEMID AND MC.DATAAREAID = I.DATAAREAID AND MC.MODULETYPE = 1 -- Compra
	JOIN INVENTTABLEMODULE MV ON MV.ITEMID = I.ITEMID AND MV.DATAAREAID = I.DATAAREAID AND MV.MODULETYPE = 2 -- Venda
	JOIN INVENTITEMGROUPITEM G ON G.ITEMID = I.ITEMID AND G.ITEMDATAAREAID = I.DATAAREAID
	JOIN INVENTITEMGROUP GR ON GR.ITEMGROUPID = G.ITEMGROUPID AND GR.DATAAREAID = G.ITEMGROUPDATAAREAID
WHERE I.DATAAREAID = 'OMT'
GROUP BY ME.UNITID, GR.NAME, G.ITEMGROUPID, I.COSTGROUPID, P.RECID, I.ITEMID, T.NAME, I.NAMEALIAS, WMSLOCATIONID, INVENTLOCATIONID, INVENTSITEID, INVENTSIZEID, INVENTSTYLEID, INVENTCOLORID, INVENTBATCHID, INVENTSERIALID, CATEGORIA, TAXFISCALCLASSIFICATION_BR, MC.TAXITEMGROUPID, MV.TAXITEMGROUPID ) AS X
WHERE 1=1 AND
(
QTD_SALDO != 0 OR VL_ESTOQUE != 0 OR QTD_ORDEM != 0 OR QTD_DEDUZIDA != 0 OR QTD_RECEBIDA != 0 OR QTD_RESERVA != 0 
OR QTD_RESERVADA_ORDEM != 0 OR QTD_ENCOMENDADA != 0 OR QTD_COTACAO != 0 OR QTD_REGISTRADA != 0 OR QTD_SEPARADA != 0
)
) AS Y
