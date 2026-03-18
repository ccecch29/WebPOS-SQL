SELECT p.name, p.value, p.isactive 
FROM OBPOS_APP_PAYMENT p
JOIN OBPOS_APPLICATIONS a ON p.OBPOS_Applications_ID = a.OBPOS_Applications_ID
WHERE a.value = 'FRT012920' ---List your Cashtill---
  AND p.value ILIKE '%NEXO%'; --List your Payment Name--


UPDATE OBPOS_APP_PAYMENT
SET IsActive = 'N', 
    Updated = NOW()
WHERE OBPOS_App_Payment_ID IN (
    SELECT p.OBPOS_App_Payment_ID
    FROM OBPOS_APP_PAYMENT p
    JOIN OBPOS_APPLICATIONS a ON p.OBPOS_Applications_ID = a.OBPOS_Applications_ID
    WHERE a.value = 'FRT012920' ---List your Cashtill---
      AND p.value ILIKE '%NEXO%'--List your Payment Name--
);
