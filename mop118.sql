/* ===========================================================                                            
 * ===========================================================
 *                  STEP 1 - Variable section
 * ===========================================================
 * Description: 
 * -----------------------------------------------------------
 * This section is to fulfill somes variables in order to 
 * avoid repetition
 * 1. countrySelect = the country for the new MOP
 * 2. tenderCode = tenderCode of the MOP
 * 3. financialAccountName = name of the financial account for each till
 * 4. financialClosureName = name of the financial account for the store closure
 * -----------------------------------------------------------
 * ===========================================================
 */

@set tenderCode = '118'
@set countrySelect = (select ad_client_id from ad_client where name = 'Decathlon Qatar')
@set financialAccountName = CONCAT('Gift card B2C ', oa.name)
@set financialClosureName = CONCAT( 'Close Gift card B2C ', ao.value)
@set partialFinancialName = 'Gift card B2C'
@set partialClosureName = 'Close Gift card B2C'
@set creationDate = now()
@set updateDate = now()
@set userName = (select ad_user_id from ad_user where username = 'CCECCH_29')
@set mopName = 'Gift card B2C'
@set mopSearchkey = 'DKT:GiftCard'
@set mopSearchKeyTouchpoint = 'DECPM_payment.giftcard'
@set touchpointSearchKeyName = 'DECPM_payment.giftcard'
@set touchpointName = 'Gift card B2C'
@set touchpointLineNumber = 52


/* ===========================================================                                            
 * ===========================================================
 *          STEP - 2 Verification of the method of payment
 * ===========================================================
 * Description: 
 * -----------------------------------------------------------
 * 2 scripts
 * 1 - A select query to see if the MOP exist for the country
 * 2 - Create the mop if not
 * -----------------------------------------------------------
 * ===========================================================
 */

/* ===========================================================                                            
 *  STEP - 2.1 select query to see if the MOP exist for the country
 * ===========================================================
 */

select * from ad_client where ad_client_id  not in (select ad_client_id from fin_paymentmethod where em_decposl_tenderidcode = :tenderCode ) ;
		
/* =========================================================== 
 * 							OPTIONNAL                                            
 *  	STEP - 2.2 Create the mop not exist
 		INFO : This part is for adding the payment method country by country using the countryTmp variable
 		IMPROVE : Can be looped like the other parts
 * ===========================================================
 */
@set countryTmp = (select ad_client_id from ad_client where name = 'Decathlon Qatar')

INSERT INTO public.fin_paymentmethod
(
	fin_paymentmethod_id, ad_client_id, ad_org_id,created, createdby, updated,updatedby, isactive, "name",description, automatic_receipt,automatic_payment, automatic_deposit,automatic_withdrawn, payin_allow,payout_allow, payin_execution_type, payout_execution_type,payin_execution_process_id, payout_execution_process_id, payin_deferred,payout_deferred, uponreceiptuse, upondeposituse,inuponclearinguse, uponpaymentuse, uponwithdrawaluse,outuponclearinguse, payin_ismulticurrency, payout_ismulticurrency,em_decposl_tenderidname, em_decposl_tenderidcode, em_obposl_paymenttype,em_obpos_bankable, em_decgc_tr_name, em_decgc_tr_tenderidname,em_decgc_tr_tenderidcode, em_decfin_prefix, em_decfin_length,em_decfin_isfinancing, em_saft_paymentmechanism, em_obrofp_paymenttype,em_obbgfp_medium, em_decfin_notmandatory
)
VALUES
(
	UPPER(md5(random()::text)), --Random new id
	:countryTmp, -- Country where to create the new payment method
	'0', -- no organization attached
	:creationDate, 
	:userName, 
	:updateDate, 
	:userName, 
	'Y', 
	:mopName, 
	:mopName, 
	'N', 'N', 'N','N', 'Y', 'Y','M', 'M', NULL,NULL, 'N', 'N', NULL, NULL, NULL,NULL, NULL,NULL,'N', 'N',
	:mopSearchkey, 
	:tenderCode,
	NULL, 'Y', NULL,NULL, NULL, NULL, NULL, 'N', NULL,NULL, NULL, 'N'
);

/* ===========================================================                                            
 * ===========================================================
 *         STEP - 3 Verification/Creation of the FINANCIAL ACCOUNT by Till
 * ===========================================================
 * Description: 
 * -----------------------------------------------------------
 * 4 scripts
 * 1 - A select query to see if there is financial account concerning the MOP
 * 2 - A Create temporary table query to setup the needed data and verify them before commit
 * 3 - Check the content of temporary table
 * 4 - Add the content of the temporary table in the financial account
 * -----------------------------------------------------------
 * NOTE : Don't hesitate to execute individually the select prompt in the second query
 * ===========================================================
 */

/* ===========================================================                                            
 *  	STEP - 3.1 Check if there is existing financial account in the country for the MOP
 * ===========================================================
 */
select 
	fp."name", fp.em_decposl_tenderidname, fp.em_decposl_tenderidcode, ffa.name 
from 
	fin_financial_account ffa 
left join 
	fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
left join 
	fin_paymentmethod fp on fp.fin_paymentmethod_id = ffp.fin_paymentmethod_id  
where 
			ffa.ad_client_id in :countrySelect 
		and 
			(fp.em_decposl_tenderidcode = :tenderCode
		or 
			lower(ffa.name) like lower(CONCAT('%',:partialFinancialName,'%'))
		or 
			ffa.fin_financial_account_id in (select oap.fin_financial_account_id from obpos_app_payment oap  
												where oap.fin_financial_account_id 
													in (
														select ffa2.fin_financial_account_id from fin_financial_account ffa2 
															join 
																fin_finacc_paymentmethod ffp2 on ffp2.fin_financial_account_id = ffa2.fin_financial_account_id 
															 join 
																fin_paymentmethod fp2 on fp2.fin_paymentmethod_id = ffp2.fin_paymentmethod_id 
															where ffa2.ad_client_id in :countrySelect and fp2.em_decposl_tenderidcode = :tenderCode)))
															
															
select oap.fin_financial_account_id from obpos_app_payment oap  
												where oap.fin_financial_account_id 
													in (
														select ffa2.fin_financial_account_id from fin_financial_account ffa2 
															join 
																fin_finacc_paymentmethod ffp2 on ffp2.fin_financial_account_id = ffa2.fin_financial_account_id 
															 join 
																fin_paymentmethod fp2 on fp2.fin_paymentmethod_id = ffp2.fin_paymentmethod_id 
															where ffa2.ad_client_id in :countrySelect and fp2.em_decposl_tenderidcode = :tenderCode)
		
			
    
/* ===========================================================                                            
 *  	STEP - 3.2 MAKE A TEMPORARY TABLE TO HELP US CREATE CORRECT FINANCIAL ACCOUNT
 * ===========================================================
 */												

DROP TABLE IF EXISTS temp_financial_account_making_tills;

WITH temp_financial_account_making_tills_cte AS (
SELECT
    ac.ad_client_id AS ac_id,
    ac.name AS ac_name,
    ac.value AS ac_value,
    ao.ad_org_id AS ao_id,
    ao.name AS ao_name,
    ao.value AS ao_value,
    oa.name AS oa_name,
    oa.value AS oa_,
    ot.name AS ot_name,
    :financialAccountName AS touchpoint_financial_account,
    (select c_currency_id from fin_financial_account where ad_client_id = ac.ad_client_id group by 1 order by count(*) desc limit 1) as currencyForMop,
    :userName AS userCreator 
FROM
    ad_client ac
JOIN
    ad_org ao ON ac.ad_client_id = ao.ad_client_id
JOIN
    obpos_applications oa ON oa.ad_org_id = ao.ad_org_id
JOIN
    obpos_terminaltype ot ON ot.obpos_terminaltype_id = oa.obpos_terminaltype_id
WHERE
    ao.ad_orgtype_id = '2'
    AND ac.ad_client_id IN (:countrySelect)
    AND lower(oa.value) NOT LIKE '%_old'
    AND lower(oa.value) NOT LIKE '%migrated%'
    AND ao.isactive = 'Y'
    AND ot.name not ilike '%mobile%'
    AND NOT EXISTS 
    ( 
        SELECT 1
        FROM 
			fin_financial_account ffa 
		LEFT JOIN 
			fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
		LEFT JOIN 
			fin_paymentmethod fp on fp.fin_paymentmethod_id = ffp.fin_paymentmethod_id  
		WHERE 
				ffa.ad_client_id in :countrySelect
			AND 
				ao.ad_org_id = ffa.ad_org_id 
			AND
			(
				(
					fp.em_decposl_tenderidcode = :tenderCode
				AND 
					(lower(ffa.name) like lower('%' || oa.name || '%'))
				)
				OR 
				(
			   		(lower(ffa.name) = lower(:financialAccountName))
				)
			)
    )
)
SELECT * INTO TEMPORARY TABLE temp_financial_account_making_tills FROM temp_financial_account_making_tills_cte;
/* ===========================================================                                            
 *  	STEP - 3.3 CHECK THE CONTENT OF OUR TEMPORARY TABLE
 * ===========================================================
 */

SELECT * FROM temp_financial_account_making_tills;

SELECT 
	ac_id, ao_name, count(*)
FROM 
	temp_financial_account_making_tills
GROUP BY 1, 2
ORDER BY 1, 3;
	
/* ===========================================================                                            
 *  	STEP - 3.4 CREATE THE FINANCIAL ACCOUNT IN THE TABLE fin_financial_account
 * ===========================================================
 */
	
DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN 
    	(SELECT 
    		UPPER(md5(random()::text)) AS fin_financial_account_id,
            ac_id AS ad_client_id,
            ao_id AS ad_org_id,
            touchpoint_financial_account AS "name",
            currencyformop as currency,
            usercreator as username
        FROM temp_financial_account_making_tills temptill)
    LOOP
        INSERT INTO public.fin_financial_account
        (
        	fin_financial_account_id, ad_client_id, ad_org_id,created, createdby, updated,updatedby, isactive, c_currency_id,"name", description, "type",c_bpartner_id, c_location_id, routingno,swiftcode, codebank, codebranch,bank_digitcontrol, ine_number, account_digitcontrol,codeaccount, accountno, currentbalance,initialbalance, creditlimit, iban,isdefault, fin_matching_algorithm_id, typewriteoff,writeofflimit, genericaccountno, c_country_id,bankformat, em_aprm_importbankfile, em_aprm_matchtransactions,em_aprm_reconcile, em_aprm_matchtrans_force, em_aprm_addtransactionpd,em_aprm_findtransactionspd, em_aprm_addmultiplepayments, em_aprm_funds_trans,em_aprm_isfundstrans_enabled
        )
        VALUES
        (
	        rec.fin_financial_account_id,
	        rec.ad_client_id,
	        rec.ad_org_id,
	        now(), 
	        rec.username,
	        now(),
	        rec.username,
	        'Y', 
	        rec.currency, 
	        rec."name", 
	        NULL, 'B', NULL, NULL, NULL, NULL,NULL, NULL, NULL,NULL, NULL, NULL,NULL, 0, 0,0, NULL, 'N', NULL, NULL, NULL,
	        NULL, '100', NULL, --100 is the country code of United States, value not used
	        'N', 'N', 'N','N', 'N', 'N', 'N', 'N', 'Y'
       );
    END LOOP;
END $$;

/* ===========================================================                                            
 * ===========================================================
 *         STEP - 4 Verification/Creation of the closure FINANCIAL ACCOUNT by store
 * ===========================================================
 * Description: 
 * -----------------------------------------------------------
 * 4 scripts
 * 1 - A select query to see if there is financial account concerning the MOP
 * 2 - A Create temporary table query to setup the needed data and verify them before commit
 * 3 - Check the content of temporary table
 * 4 - Add the content of the temporary table in the financial account
 * -----------------------------------------------------------
 * NOTE : Don't hesitate to execute individually the select prompt in the second query
 * ===========================================================
 */
	
/* ===========================================================                                            
 *  	STEP - 4.1 Check if there is existing financial account in the country for the MOP
 * ===========================================================
 */
		
			
--TO CHECK IF THERE IS A FINANCIAL ACCOUNT IN THE TAB CASH MANAGEMENT EVENT FOR THE MOP WE ARE CURRENTLY WORKING
select 
	fp."name", fp.em_decposl_tenderidname, fp.em_decposl_tenderidcode, ffa.name 
from 
	fin_financial_account ffa 
left join 
	fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
left join 
	fin_paymentmethod fp on fp.fin_paymentmethod_id = ffp.fin_paymentmethod_id  
where 
			ffa.fin_financial_account_id in (select oc.fin_financial_account_id from obretco_cmevents oc
												where oc.fin_financial_account_id 
													in (
														select ffa2.fin_financial_account_id from fin_financial_account ffa2 
															join 
																fin_finacc_paymentmethod ffp2 on ffp2.fin_financial_account_id = ffa2.fin_financial_account_id 
															 join 
																fin_paymentmethod fp2 on fp2.fin_paymentmethod_id = ffp2.fin_paymentmethod_id 
															where ffa2.ad_client_id in :countrySelect and 
															fp2.em_decposl_tenderidcode = :tenderCode))			
		
--TO CHECK IF THERE IS A FINANCIAL ACCOUNT WITH A NAME LIKE THE ONE WE ARE TRYING TO create 
															
select 
	fp."name", fp.em_decposl_tenderidname, fp.em_decposl_tenderidcode, ffa.name 
from 
	fin_financial_account ffa 
left join 
	fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
left join 
	fin_paymentmethod fp on fp.fin_paymentmethod_id = ffp.fin_paymentmethod_id  
where (ffa.ad_client_id in :countrySelect 
		and 
			fp.em_decposl_tenderidcode = :tenderCode)
		or 
			lower(ffa.name) ilike lower(:partialClosureName) || '%';													
															
/* ===========================================================                                            
 *  	STEP - 4.2 CREATE THE FINANCIAL ACCOUNT OF CLOSURE BY STORE
 * 				IN A TEMPORARY TABLE
 * ===========================================================
 */
WITH temp_financial_account_making_stores_cte AS (
SELECT
    ac.ad_client_id AS ac_id,
    ac.name AS ac_name,
    ac.value AS ac_value,
    ao.ad_org_id AS ao_id,
    ao.name AS ao_name,
    ao.value AS ao_value,
    :financialClosureName AS stores_financial_account,
    --:currency AS currencyForMop, --currency
    (select c_currency_id from fin_financial_account where ad_client_id = ac.ad_client_id group by 1 order by count(*) desc limit 1),
    :userName AS userCreator -- user id
FROM
    ad_client ac
JOIN
    ad_org ao ON ac.ad_client_id = ao.ad_client_id
WHERE
    ao.ad_orgtype_id = '2' -- FIND ONLY THE REAL STORES
    AND ac.ad_client_id IN (:countrySelect) -- ADD THE NAME OF EVERY COUNTRY WHERE THE NEW PAYMENT METHOD IS NEEDED
    AND lower(ao.value) NOT LIKE '%_old' -- AVOID THE DEACTIVATED TILLS // Example : Toulouse_old
    AND lower(ao.value) NOT LIKE '%migrated%' -- AVOID THE DEACTIVATED TILLS // Example : TOULOUSE_MIGRATED_prod2
    AND ao.isactive = 'Y' -- AVOID THE DEACTIVATED STORES
    AND ao.value like '________'
    AND NOT EXISTS 
    ( --- AVOID THE CREATION OF AN ALREADY EXISTING FINANCIAL ACCOUNT BASED ON THE PAYMENT METHOD AND FINANCIAL ACCOUNT NAME
        SELECT 1
        from 
			fin_financial_account ffa 
		left join 
			fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
		left join 
			fin_paymentmethod fp on fp.fin_paymentmethod_id = ffp.fin_paymentmethod_id  
		where 
				ffa.ad_client_id in :countrySelect 
			and
				(ffa.ad_org_id = ao.ad_org_id 
			and
			    lower(ffa.name) ilike lower(:partialClosureName) || '%')
			or 
				ffa.fin_financial_account_id in (select oc.fin_financial_account_id from obretco_cmevents oc
												where oc.fin_financial_account_id 
													in (
														select ffa2.fin_financial_account_id from fin_financial_account ffa2 
															join 
																fin_finacc_paymentmethod ffp2 on ffp2.fin_financial_account_id = ffa2.fin_financial_account_id 
															 join 
																fin_paymentmethod fp2 on fp2.fin_paymentmethod_id = ffp2.fin_paymentmethod_id 
															where ffa2.ad_client_id in :countrySelect and 
															fp2.em_decposl_tenderidcode = :tenderCode))	
	 )
)
SELECT * INTO TEMPORARY TABLE temp_financial_account_making_stores FROM temp_financial_account_making_stores_cte;

/* ===========================================================                                            
 *  	STEP - 4.3 CHECK THE TEMPORARY TABLE temp_financial_account_making_stores
 * ===========================================================
 */

select * from temp_financial_account_making_stores
   
/* ===========================================================                                            
 *  	STEP - 4.4 CREATE THE FINANCIAL ACCOUNT IN THE TABLE fin_financial_account
 * ===========================================================
 */
	 

DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN 
    (
    	SELECT 
    		UPPER(md5(random()::text)) AS fin_financial_account_id,
            ac_id AS ad_client_id,
            ao_id AS ad_org_id,
            stores_financial_account AS "name",
            c_currency_id as currency,
            usercreator as username
        FROM 
        	temp_financial_account_making_stores tempstores
    )
    LOOP
        INSERT INTO public.fin_financial_account
        (
        	fin_financial_account_id, ad_client_id, ad_org_id,created, createdby, updated,updatedby, isactive, c_currency_id,"name", description, "type",c_bpartner_id, c_location_id, routingno,swiftcode, codebank, codebranch,bank_digitcontrol, ine_number, account_digitcontrol,codeaccount, accountno, currentbalance,initialbalance, creditlimit, iban,isdefault, fin_matching_algorithm_id, typewriteoff,writeofflimit, genericaccountno, c_country_id, bankformat, em_aprm_importbankfile, em_aprm_matchtransactions,em_aprm_reconcile, em_aprm_matchtrans_force, em_aprm_addtransactionpd,em_aprm_findtransactionspd, em_aprm_addmultiplepayments, em_aprm_funds_trans,em_aprm_isfundstrans_enabled
        )
        VALUES
        (
	        rec.fin_financial_account_id,
            rec.ad_client_id,
            rec.ad_org_id,
            now(), 
            rec.username,
            now(),
            rec.username,
            'Y', 
            rec.currency, 
            rec."name", 
	        NULL, 'B', NULL,NULL, NULL, NULL,NULL, NULL, NULL,NULL, NULL, NULL,NULL, 0, 0,0, NULL, 'N',NULL, NULL, NULL,NULL, '100', NULL,'N', 'N', 'N','N', 'N', 'N','N', 'N', 'Y'
        );
    END LOOP;
END $$;


/* ===========================================================                                            
 * ===========================================================
 *         STEP - 5 Adding the payment method for each financial account
 * ===========================================================
 * Description:
 * -----------------------------------------------------------
 * 4 scripts
 * 1 - Check if somes financial account already have their Payment method
 * 2 - Temporary table of the data that we want to add
 * 3 - Checking the content of the temporary table
 * 4 - Adding the content of the temporary table in fin_finacc_paymentmethod
 * -----------------------------------------------------------
 * NOTE : x
 * ===========================================================
 */
DROP TABLE IF EXISTS temp_fin_fincc_pmntmthd;
/* ===========================================================                                            
 *  	STEP - 5.1 Select query to verify that we have 
 * financial account matching the name of the mop that we are 
 * 		currently creating with no payment method attached
 * ===========================================================
 */



SELECT 
	ffa.fin_financial_account_id, ffa.ad_org_id, ffa.name, ffa.ad_client_id 
FROM 
	fin_financial_account ffa
LEFT JOIN 
	fin_finacc_paymentmethod ffp ON ffa.fin_financial_account_id = ffp.fin_financial_account_id
 WHERE 
 	(
 		lower(ffa.name) LIKE lower(CONCAT('%',:partialClosureName,'%')) 
 	OR 
 		lower(ffa.name) LIKE lower(CONCAT('%',:partialFinancialName,'%'))
 	)
    AND 
    	ffp.fin_finacc_paymentmethod_id IS NULL  -- We need no payment method attached // Empty tab 
    AND
    	ffa.ad_client_id in :countrySelect
    	
 
 /* ===========================================================                                            
 *  	STEP - 5.2 CREATE THE FINANCIAL ACCOUNT'S PAYMENT METHOD
 * 					IN A TEMPORARY TABLE
 * ===========================================================
 */  	
DROP TABLE IF EXISTS temp_fin_fincc_pmntmthd;
    	
 WITH temp_fin_fincc_pmntmthd_cte AS (
SELECT
	ffa.fin_financial_account_id,
	ffa.ad_org_id,
	ffa.name,
	ffa.ad_client_id,
	-- Recupero ID metodo di pagamento (Tender 118)
	(SELECT fin_paymentmethod_id 
     FROM fin_paymentmethod 
     WHERE em_decposl_tenderidcode = '118' 
       AND ad_client_id = ffa.ad_client_id 
     LIMIT 1) as paymentmethod_id,
    -- ID Utente Hardcoded per sicurezza
    '1270E8EAB4554F3F9AC13CEED3241DBC' AS userCreator 
FROM
	fin_financial_account ffa
LEFT JOIN 
	fin_finacc_paymentmethod ffp ON ffa.fin_financial_account_id = ffp.fin_financial_account_id
 WHERE 
 	(
 		ffa.name ILIKE 'Gift card B2C%' 
 		OR 
 		ffa.name ILIKE 'Close Gift card B2C%'
 	)
    AND ffp.fin_finacc_paymentmethod_id IS NULL 
    AND ffa.ad_client_id = (SELECT ad_client_id FROM ad_client WHERE name = 'Decathlon Qatar')
    AND ffa.ad_org_id = (SELECT ad_org_id FROM ad_org WHERE name = 'DOHA VILLAGIO')
)
SELECT * INTO TEMPORARY TABLE temp_fin_fincc_pmntmthd FROM temp_fin_fincc_pmntmthd_cte;

/* ===========================================================                                            
 *  	STEP - 5.3 CHECK THE CONTENT OF THE TEMPORARY TABLE temp_fin_fincc_pmntmthd
 * ===========================================================
 */

select * from temp_fin_fincc_pmntmthd

/* ===========================================================                                            
 *  	STEP - 5.4 CREATE THE FINANCIAL ACCOUNT'S PAYMENT METHOD
 * 				 IN THE TABLE fin_finacc_paymentmethod
 * ===========================================================
 */

DO $$
DECLARE
     rec record;
BEGIN
	 FOR rec IN 
    (
    	SELECT 
    		UPPER(md5(random()::text)) AS fin_financial_paymentmethod_id,
            ad_client_id,
            ad_org_id,
            fin_financial_account_id,
            paymentmethod_id,
            usercreator as username
        FROM 
        	temp_fin_fincc_pmntmthd tempfinccpmntmthd
    )
	LOOP
		INSERT INTO public.fin_finacc_paymentmethod
			(
				fin_finacc_paymentmethod_id, ad_client_id, ad_org_id,created, createdby, updated,updatedby, isactive, fin_paymentmethod_id,fin_financial_account_id, automatic_receipt,automatic_payment, automatic_deposit, automatic_withdrawn,payin_allow, payout_allow, payin_execution_type,payout_execution_type, payin_execution_process_id, payout_execution_process_id,payin_deferred, payout_deferred, uponreceiptuse,upondeposituse, inuponclearinguse, uponpaymentuse,uponwithdrawaluse, outuponclearinguse, payin_ismulticurrency,payout_ismulticurrency, isdefault, payin_invoicepaidstatus,payout_invoicepaidstatus
			)
		VALUES
		(  
			 rec.fin_financial_paymentmethod_id,
		     rec.ad_client_id,
		     rec.ad_org_id,
		     now(), 
		     rec.username,
		     now(),
		     rec.username,
		     'Y',
		     rec.paymentmethod_id,
		     rec.fin_financial_account_id,
		    'N', 'N', 'N','N', 'Y', 'Y','M', 'M', NULL,NULL, 'N', 'N',NULL, NULL, NULL,NULL, NULL, NULL,'N', 'N', 'N','RPR', 'PPM'
		);
	 END LOOP;
END;
$$;


/* ===========================================================                                            
 * ===========================================================
 *         STEP - 6 Adding the payment method for each touchpoint type
 * ===========================================================
 * Description:
 * -----------------------------------------------------------
 * X scripts
 * 1 - 
 * 2 - 
 * 3 - 
 * 4 - 
 * -----------------------------------------------------------
 * NOTE : x
 * ===========================================================
 */


/* ===========================================================                                            
 *  	STEP - 6.1 Select query to see if there is already existing
 * 	payment method in the touchpoint type of the country
 * ===========================================================
 */
SELECT 
	obpos_paymentgroup_id,obpos_paymentmethod_type_id,paymentprovider , refundprovider , *
FROM 
	obpos_app_payment_type oapt
WHERE 
	oapt.fin_paymentmethod_id in 
	(
		select 
			fp.fin_paymentmethod_id 
		from 
			fin_paymentmethod fp 
		where 
			ad_client_id in :countrySelect
		and 
			em_decposl_tenderidcode = :tenderCode
	)
	
/* ===========================================================                                            
 *  	STEP - 6.2 Temporary table for the payment method of each touchpoint type 
 * ===========================================================
 */
DROP TABLE IF EXISTS temp_obpos_app_payment_type;

WITH temp_obpos_app_payment_type_cte AS (
SELECT
    ac.ad_client_id AS ac_id,
    ao.ad_org_id AS ao_id,
    ot.obpos_terminaltype_id as obpos_terminaltype_id,
    (select fp2.fin_paymentmethod_id from fin_paymentmethod fp2 where fp2.ad_client_id = ac.ad_client_id and fp2.em_decposl_tenderidcode = :tenderCode) as fin_pmntmthd_id,
    :mopName as mop_name,
    :mopSearchkey as mop_searchkey,
    :userName AS userCreator,
    (select c_currency_id from fin_financial_account where ad_client_id = ac.ad_client_id group by 1 order by count(*) desc limit 1) as currency,
    -- Mapping G/L Items con nomi flessibili
    (select c_glitem_id from c_glitem where ad_client_id = ac.ad_client_id and name ILIKE '%difference%' AND isactive='Y' LIMIT 1) as gl_diff,
    (select c_glitem_id from c_glitem where ad_client_id = ac.ad_client_id and (name ILIKE '%Drop%' OR name ILIKE '%Deposit%') AND isactive='Y' LIMIT 1) as gl_drop_dep,
    (select c_glitem_id from c_glitem where ad_client_id = ac.ad_client_id and name ILIKE '%Write%Off%' AND isactive='Y' LIMIT 1) as gl_writeoff,
	-- Payment Groups
	(select obpos_paymentgroup_id from obpos_paymentgroup where provider = 'DECGC_GiftCardGroupProvider' and ad_client_id = ac.ad_client_id LIMIT 1) as obpos_pmntgrp_id,
	(select obpos_paymentmethod_type_id from obpos_paymentmethod_type where provider = 'DECGC_GiftCardGroupProvider' and value = :tenderCode LIMIT 1) as obpos_pmntgrp_tp_id
FROM
    obpos_terminaltype ot
JOIN ad_client ac ON ac.ad_client_id = ot.ad_client_id 
JOIN ad_org ao ON ao.ad_org_id  = ot.ad_org_id 
WHERE 
	ac.name = 'Decathlon Qatar'-----------> CHECK IT <---
	AND ot.name NOT ILIKE '%mobile%'
)
SELECT * INTO TEMPORARY TABLE temp_obpos_app_payment_type FROM temp_obpos_app_payment_type_cte;

-- Verifica semplificata (senza nomi di colonne incerte)
SELECT * FROM temp_obpos_app_payment_type;
-- VERIFICA: Assicurati che gl_writeoff NON sia null qui sotto
SELECT ao_name, gl_diff, gl_drop_dep, gl_writeoff FROM temp_obpos_app_payment_type;

SELECT mop_name, gl_diff, gl_drop_dep, gl_writeoff FROM temp_obpos_app_payment_type;

--6.4

DO $$
DECLARE
     rec record;
     -- Definiamo la variabile internamente per evitare l'errore di sintassi
     v_touchpoint_value VARCHAR := 'DECPM_payment.giftcard'; 
BEGIN
    FOR rec IN (SELECT * FROM temp_obpos_app_payment_type)
    LOOP
    INSERT INTO public.obpos_app_payment_type
    (
        obpos_app_payment_type_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, 
        value, 
        "name", fin_paymentmethod_id, c_currency_id, obpos_terminaltype_id, 
        automatemovementtoother, keepfixedamount, allowvariableamount, allowdontmove, allowmoveeverything, allowdrops, allowdeposits,
        c_glitem_diff_id, c_glitem_dropdep_id, c_glitem_writeoff_id,  
        iscash, allowopendrawer, printtwice, countcash, isreversable, refundable, countpaymentincashup, 
        obpos_paymentgroup_id, obpos_paymentmethod_type_id, em_obsco_printreceipt, isrounding
    )
    VALUES (
        UPPER(md5(random()::text)), rec.ac_id, rec.ao_id, 'Y', now(), rec.userCreator, now(), rec.userCreator,
        v_touchpoint_value, -- <--- Usiamo la variabile interna definita sopra
        rec.mop_name, rec.fin_pmntmthd_id, rec.currency, rec.obpos_terminaltype_id, 
        'N', 'N', 'N', 'N', 'N', 'N', 'N',
        rec.gl_diff, rec.gl_drop_dep, rec.gl_writeoff,   
        'N', 'N', 'N', 'N', 'Y', 'N', 'Y', 
        rec.obpos_pmntgrp_id, rec.obpos_pmntgrp_tp_id, 'never', 'N'
    );
    END LOOP;
END $$;

COMMIT;



/* ===========================================================                                            
 * ===========================================================
 *         STEP - 7 Cash management event
 * ===========================================================
 * Description:
 * -----------------------------------------------------------
 * X scripts
 * 1 - 
 * 2 - 
 * 3 - 
 * 4 - 
 * -----------------------------------------------------------
 * NOTE : x
 * ===========================================================
 */


/* ===========================================================                                            
 *  	STEP - 7.1 Select query to see if there is already existing
 * 	cash management event for stores in country
 * ===========================================================
 */


select * from obretco_cmevents oc where oc.fin_paymentmethod_id  in (select fp2.fin_paymentmethod_id from fin_paymentmethod fp2 where 
fp2.ad_client_id in :countrySelect and 
em_decposl_tenderidcode = :tenderCode)
COMMIT;
/* ===========================================================                                            
 *  	STEP - 7.2 Temporary table for the cash management event
 * ===========================================================
 */

WITH temp_obretco_cmevents_cte AS (
SELECT
    ac.ad_client_id AS ac_id,
    ac.name AS ac_name,
    ac.value AS ac_value,
    ao.ad_org_id AS ao_id,
    ao.name as ao_name,
    ao.value as ao_value,
    :userName as usercreator,
    :partialClosureName as nameEvent,
    --:currency as currency,
    (select c_currency_id from fin_financial_account where ad_client_id = ac.ad_client_id group by 1 order by count(*) desc limit 1) as currency,
    (select fp2.fin_paymentmethod_id from fin_paymentmethod fp2 where fp2.ad_client_id = ac.ad_client_id and em_decposl_tenderidcode = :tenderCode) as paymentmethod_id,
    ffa.fin_financial_account_id,
    ffa.name
FROM
    fin_financial_account ffa
JOIN
    ad_org ao ON ao.ad_org_id  = ffa.ad_org_id
JOIN
    ad_client ac ON ac.ad_client_id = ffa.ad_client_id  
WHERE 
	ffa.name ilike :partialClosureName || '%'
	and 
	ffa.ad_client_id in :countrySelect
AND ffa.fin_financial_account_id NOT IN (
	SELECT 
		oce.fin_financial_account_id 
    FROM 
    	OBRETCO_CMEvents oce
    WHERE 
    	fin_paymentmethod_id  in (select fp2.fin_paymentmethod_id from fin_paymentmethod fp2 where 
		fp2.ad_client_id in :countrySelect and 
		em_decposl_tenderidcode = :tenderCode)
	)
)
SELECT * INTO TEMPORARY TABLE temp_obretco_cmevents FROM temp_obretco_cmevents_cte;

/* ===========================================================                                            
 *  	STEP - 7.3 Check Temporary table for the cash management event
 * ===========================================================
 */

drop table temp_obretco_cmevents

select * from temp_obretco_cmevents

/* ===========================================================                                            
 *  	STEP - 7.4 Add data to the table cash management event
 * ===========================================================
 */


DO $$
DECLARE
     rec record;
BEGIN
	 FOR rec IN 
    (
    	SELECT 
    		ac_id,
			ao_id,
    		usercreator,
    		nameEvent,
			currency,
			paymentmethod_id,
			fin_financial_account_id 
        FROM 
        	temp_obretco_cmevents
    )
    LOOP
        INSERT INTO public.obretco_cmevents
        (obretco_cmevents_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, "name", c_currency_id, fin_paymentmethod_id, eventtype, fin_financial_account_id, em_decposl_code, em_obposl_tendercontroltype, em_decposl_reasonname, em_decui_cashmgmt_limit, em_decui_store_expense)
        VALUES (
            UPPER(md5(random()::text)),
            rec.ac_id,
            rec.ao_id,
            'Y',
            now(),
            rec.usercreator,
            now(),
            rec.usercreator,
            rec.nameEvent,
            rec.currency,
            rec.paymentmethod_id,
            'CL',
            rec.fin_financial_account_id,
            1,
            'TLOAN',
            NULL,
            NULL,
            'N'
        );
    END LOOP;
END $$;

/* ===========================================================                                            
 * ===========================================================
 *         STEP - 8 Payment method on touchpoint
 * ===========================================================
 * Description:
 * -----------------------------------------------------------
 * X scripts
 * 1 - 
 * 2 - 
 * 3 - 
 * 4 - 
 * -----------------------------------------------------------
 * NOTE : x
 * ===========================================================
 */


/* ===========================================================                                            
 *  	STEP - 8.1 Select query to see if there is already existing
 * 	payment method on touchpoint view
 * ===========================================================
 */

select * from obpos_app_payment where name ilike 'Gift Card B2C';

Select 
    ac.ad_client_id,
    ac.name as acName,
    ac.value as acValue,
    ao.ad_org_id,
    ao.name as aoName,
    ao.value as aoValue,
    :userName as username,
    :touchpointSearchKeyName as searchKeyName,
    ffa.fin_financial_account_id  as financial_account_id,
    oa.name as oaName, 
    oa.obpos_applications_id as obpos_applications_id,
    ot.name as otName, 
    oapt.name as oaptName,
    oapt.obpos_app_payment_type_id as obpos_app_payment_type_id,
    oc.obretco_cmevents_id as obretco_cmevents_id,
    oc.name as ocName,
    :touchpointName as touchpointName,
    :touchpointLineNumber as line
from 
    fin_financial_account ffa 
join ad_client ac on ffa.ad_client_id = ac.ad_client_id 
join ad_org ao on ao.ad_org_id = ffa.ad_org_id 
join obpos_applications oa on oa.ad_org_id = ao.ad_org_id 
join obpos_terminaltype ot on ot.obpos_terminaltype_id = oa.obpos_terminaltype_id 
join obpos_app_payment_type oapt on oapt.obpos_terminaltype_id = ot.obpos_terminaltype_id 
join fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
join fin_paymentmethod fp on ffp.fin_paymentmethod_id = fp.fin_paymentmethod_id 
join obretco_cmevents oc ON oc.ad_org_id = ao.ad_org_id 
where 
    ffa.name ilike  '%' || oa.name || '%'
    AND lower(oa.value) NOT LIKE '%_old'
    AND lower(oa.value) NOT LIKE '%migrated%'
    AND lower(ao.name) NOT LIKE '%template%'
    AND ao.isactive = 'Y'
    and fp.em_decposl_tenderidcode = :tenderCode 
    and fp.ad_client_id in :countrySelect
    and ot.name not ilike ('%mobile%')
    and oapt.fin_paymentmethod_id = fp.fin_paymentmethod_id 
    and oc.fin_paymentmethod_id = fp.fin_paymentmethod_id 
    and ffa.ad_client_id in :countrySelect
    and ffa.fin_financial_account_id not in 
    (
        select oap.fin_financial_account_id  
        from obpos_app_payment oap
        where oap.ad_client_id in :countrySelect
    );

/* ===========================================================                                            
 *  	STEP - 8.2 temporary table for payment method in touchpoint
 * ===========================================================
 */
WITH temp_obpos_app_payment_cte AS (
	Select 
		ac.ad_client_id,
		ac.name as acName,
		ac.value as acValue,
		ao.ad_org_id,
		ao.name as aoName,
		ao.value as aoValue,
		:userName as username,
		:touchpointSearchKeyName as searchKeyName,
		ffa.fin_financial_account_id  as financial_account_id,
		oa.name as oaName, 
		oa.obpos_applications_id as obpos_applications_id,
		ot.name as otName, 
		oapt.name as oaptName,
		oapt.obpos_app_payment_type_id as obpos_app_payment_type_id,
		oc.obretco_cmevents_id as obretco_cmevents_id,
		oc.name as ocName,
		:touchpointName as touchpointName,
		:touchpointLineNumber as line
	from 
		fin_financial_account ffa 
	join ad_client ac on ffa.ad_client_id = ac.ad_client_id 
	join ad_org ao on ao.ad_org_id = ffa.ad_org_id 
	join obpos_applications oa on oa.ad_org_id = ao.ad_org_id 
	join obpos_terminaltype ot on ot.obpos_terminaltype_id = oa.obpos_terminaltype_id 
	join obpos_app_payment_type oapt on oapt.obpos_terminaltype_id = ot.obpos_terminaltype_id 
	join fin_finacc_paymentmethod ffp on ffp.fin_financial_account_id = ffa.fin_financial_account_id 
	join fin_paymentmethod fp on ffp.fin_paymentmethod_id = fp.fin_paymentmethod_id 
	join obretco_cmevents oc ON oc.ad_org_id = ao.ad_org_id 
	where ot.ad_client_id in :countrySelect
	and ot.name not ilike ('%mobile%')
	and ffa.name ilike  '%' || oa.name
	    AND lower(oa.value) NOT LIKE '%_old' -- AVOID THE DEACTIVATED TILLS // Example : Toulouse_old
    AND lower(oa.value) NOT LIKE '%migrated%' -- AVOID THE DEACTIVATED TILLS // Example : TOULOUSE_MIGRATED_prod2
    AND lower(ao.name) NOT LIKE '%template%' -- AVOID THE DEACTIVATED TILLS // Example : TOULOUSE_MIGRATED_prod2
    AND ao.isactive = 'Y' -- AVOID THE DEACTIVATED STORES
	and fp.em_decposl_tenderidcode = :tenderCode and fp.ad_client_id in :countrySelect
	and oapt.fin_paymentmethod_id = fp.fin_paymentmethod_id 
	and oc.fin_paymentmethod_id = fp.fin_paymentmethod_id 
	and ffa.ad_client_id in :countrySelect
	and ffa.fin_financial_account_id not in 
		(
			select oap.fin_financial_account_id  
			from obpos_app_payment oap
			where oap.ad_client_id in :countrySelect
		)
	and oa.obpos_applications_id not in 
		( select oap2.obpos_applications_id from obpos_app_payment oap2 
		where oap2.value = :touchpointSearchKeyName)
)
SELECT * INTO TEMPORARY TABLE temp_obpos_app_payment FROM temp_obpos_app_payment_cte;



/* ===========================================================                                            
 *  	STEP - 8.3 check temporary table 
 * ===========================================================
 */

drop table temp_obpos_app_payment;

select * from temp_obpos_app_payment order by ad_org_id, obpos_applications_id;

/* ===========================================================                                            
 *  	STEP - 8.4 Create the touchpoint payment method
 * ===========================================================
 */

DO $$
DECLARE
     rec record;
BEGIN
	 FOR rec IN 
    (
    	SELECT 
    		ad_client_id,
    		ad_org_id,
			username,
			searchKeyName,
			financial_account_id,
			obpos_applications_id,
			obpos_app_payment_type_id,
			obretco_cmevents_id,
			touchpointName,
			line
        FROM 
        	temp_obpos_app_payment
    )
     LOOP
	INSERT INTO public.obpos_app_payment
	(
      obpos_app_payment_id,ad_client_id,ad_org_id,isactive,created,createdby,updated,updatedby,value,fin_financial_account_id,obpos_applications_id,obpos_app_payment_type_id,obretco_cmevents_id,"name",line,overrideconfiguration,c_glitem_diff_id,c_glitem_dropdep_id,automatemovementtoother,keepfixedamount,amount,allowvariableamount,allowdontmove,allowmoveeverything,countcash
	)
VALUES(
    UPPER(md5(random()::text)),
    rec.ad_client_id,
    rec.ad_org_id,
    'N', 
    now(), 
    rec.username, 
    now(), 
    rec.username,
    rec.searchKeyName, 
    rec.financial_account_id, 
    rec.obpos_applications_id,
    rec.obpos_app_payment_type_id,
    rec.obretco_cmevents_id,
    rec.touchpointName, 
    rec.line,
    'N', 
    NULL, 
    NULL, 
    'N', 
    'N', 
    NULL, 
    'N', 
    'N', 
    'N', 
    'N'
 	);
    END LOOP;
END $$;


update obpos_app_payment 
set isactive = 'Y'
where name = :touchpointSearchKeyName and isactive = 'N' and createdby = :userName