USE SCREAM2;
GO

/*outcome function*/
CREATE OR ALTER FUNCTION project.outcome (
    @outcome_name VARCHAR(100)
)
RETURNS @outcome TABLE (
    lopnr VARCHAR(9), 
	datum DATE, 
	outcome INT,
	[source] VARCHAR(20)
)
AS BEGIN
    IF @outcome_name = 'anemia'
	    WITH all_diagnoses_data AS (
		    SELECT DISTINCT lopnr, datum, kod
			FROM SCREAM2.KON_DIAGNOSES_LONG 
			UNION 
			SELECT DISTINCT lopnr, datum, kod 
			FROM SCREAM2.OVR_DIAGNOSES_LONG 
			UNION 
			SELECT DISTINCT lopnr, indat AS datum, kod 
			FROM SCREAM2.SLV_DIAGNOSES_LONG
		), anemia_diagnosis AS (
		    SELECT lopnr, datum, 1 AS outcome 
			FROM all_diagnoses_data 
			WHERE PATINDEX('D6[0-4]%', kod) > 0 
		), Hb_tests_data AS (
		    SELECT lopnr, datum, tid, standard_test_name, standard_result, standard_unit 
			FROM SCREAM2.LAB_TESTS 
			WHERE standard_test_name IN ('regular Hb')
		), anemia_test AS (
		    SELECT tb1.lopnr, tb1.datum, 1 AS outcome
			FROM Hb_tests_data tb1
			INNER JOIN SCREAM2.DEMOGRAPHY tb2
			ON tb1.lopnr = tb2.lopnr 
			WHERE (tb1.standard_result < 120 AND female = 1) OR (tb1.standard_result < 130 AND female = 0)
			GROUP BY tb1.lopnr, tb1.datum
		), anemia_treatment AS (
		    SELECT lopnr, edatum AS datum, 1 AS anemia_treatment
			FROM SCREAM2.LMED 
			WHERE PATINDEX('B03[AX]%', ATC) > 0 
			UNION 
			SELECT tb1.lopnr, tb1.datum, 1 AS anemia_treatment 
			FROM ( 
			    SELECT lopnr, datum 
				FROM SCREAM2.OVR_PROCEDURES_LONG 
				WHERE PATINDEX('DT016%', opk) > 0
			) tb1 
			INNER JOIN (
			    SELECT lopnr, datum 
				FROM SCREAM2.LAB_TESTS 
				WHERE standard_test_name = 'transf_sat' AND standard_result < 0.2
			) tb2
			ON tb1.lopnr = tb2.lopnr AND tb1.datum = tb2.datum --on the same day
		), anemia_test_confirmed_by_treatment AS (
		    SELECT tb1.lopnr, tb1.datum, IIF(SUM(tb2.anemia_treatment) > 0, 1, 0) AS outcome
			FROM anemia_test tb1
			INNER JOIN anemia_treatment tb2
			ON tb1.lopnr = tb2.lopnr AND DATEDIFF(day, tb1.datum, tb2.datum) BETWEEN 0 AND 90
			GROUP BY tb1.lopnr, tb1.datum
		), anemia_test_confirmed_by_test AS (
		    SELECT tb1.lopnr, tb1.datum, IIF(SUM(tb2.outcome) > 0, 1, 0) AS outcome
			FROM anemia_test tb1
			INNER JOIN anemia_test tb2
			ON tb1.lopnr = tb2.lopnr AND DATEDIFF(month, tb1.datum, tb2.datum) > 3
			GROUP BY tb1.lopnr, tb1.datum 
		)
		INSERT INTO @outcome
		    SELECT DISTINCT lopnr, datum, outcome, 'diagnosis' AS [source] 
			FROM anemia_diagnosis 
			UNION 
			SELECT DISTINCT lopnr, datum, outcome, 'treatment' AS [source] 
			FROM anemia_test_confirmed_by_treatment 
			UNION 
			SELECT DISTINCT lopnr, datum, outcome, 'test' AS [source]
			FROM anemia_test_confirmed_by_test; 
	IF @outcome_name = 'anemia 12'
	    WITH all_diagnoses_data AS (
		    SELECT DISTINCT lopnr, datum, kod
			FROM SCREAM2.KON_DIAGNOSES_LONG 
			UNION 
			SELECT DISTINCT lopnr, datum, kod 
			FROM SCREAM2.OVR_DIAGNOSES_LONG 
			UNION 
			SELECT DISTINCT lopnr, indat AS datum, kod 
			FROM SCREAM2.SLV_DIAGNOSES_LONG
		), anemia_diagnosis AS (
		    SELECT lopnr, datum, 1 AS outcome 
			FROM all_diagnoses_data 
			WHERE PATINDEX('D6[0-4]%', kod) > 0 
		), Hb_tests_data AS (
		    SELECT lopnr, datum, tid, standard_test_name, standard_result, standard_unit 
			FROM SCREAM2.LAB_TESTS 
			WHERE standard_test_name IN ('regular Hb')
		), anemia_test AS (
		    SELECT tb1.lopnr, tb1.datum, 1 AS outcome
			FROM Hb_tests_data tb1
			INNER JOIN SCREAM2.DEMOGRAPHY tb2
			ON tb1.lopnr = tb2.lopnr 
			WHERE (tb1.standard_result < 120 AND female = 1) OR (tb1.standard_result < 120 AND female = 0)
			GROUP BY tb1.lopnr, tb1.datum
		), anemia_treatment AS (
		    SELECT lopnr, edatum AS datum, 1 AS anemia_treatment
			FROM SCREAM2.LMED 
			WHERE PATINDEX('B03[AX]%', ATC) > 0 
			UNION 
			SELECT tb1.lopnr, tb1.datum, 1 AS anemia_treatment 
			FROM ( 
			    SELECT lopnr, datum 
				FROM SCREAM2.OVR_PROCEDURES_LONG 
				WHERE PATINDEX('DT016%', opk) > 0
			) tb1 
			INNER JOIN (
			    SELECT lopnr, datum 
				FROM SCREAM2.LAB_TESTS 
				WHERE standard_test_name = 'transf_sat' AND standard_result < 0.2
			) tb2
			ON tb1.lopnr = tb2.lopnr AND tb1.datum = tb2.datum --on the same day
		), anemia_test_confirmed_by_treatment AS (
		    SELECT tb1.lopnr, tb1.datum, IIF(SUM(tb2.anemia_treatment) > 0, 1, 0) AS outcome
			FROM anemia_test tb1
			INNER JOIN anemia_treatment tb2
			ON tb1.lopnr = tb2.lopnr AND DATEDIFF(day, tb1.datum, tb2.datum) BETWEEN 0 AND 90
			GROUP BY tb1.lopnr, tb1.datum
		), anemia_test_confirmed_by_test AS (
		    SELECT tb1.lopnr, tb1.datum, IIF(SUM(tb2.outcome) > 0, 1, 0) AS outcome
			FROM anemia_test tb1
			INNER JOIN anemia_test tb2
			ON tb1.lopnr = tb2.lopnr AND DATEDIFF(month, tb1.datum, tb2.datum) > 3
			GROUP BY tb1.lopnr, tb1.datum 
		)
		INSERT INTO @outcome
		    SELECT DISTINCT lopnr, datum, outcome, 'diagnosis' AS [source]  
			FROM anemia_diagnosis 
			UNION 
			SELECT DISTINCT lopnr, datum, outcome, 'treatment' AS [source]  
			FROM anemia_test_confirmed_by_treatment 
			UNION 
			SELECT DISTINCT lopnr, datum, outcome, 'test' AS [source] 
			FROM anemia_test_confirmed_by_test;
	IF @outcome_name = 'anemia 10'
	    WITH all_diagnoses_data AS (
		    SELECT DISTINCT lopnr, datum, kod
			FROM SCREAM2.KON_DIAGNOSES_LONG 
			UNION 
			SELECT DISTINCT lopnr, datum, kod 
			FROM SCREAM2.OVR_DIAGNOSES_LONG 
			UNION 
			SELECT DISTINCT lopnr, indat AS datum, kod 
			FROM SCREAM2.SLV_DIAGNOSES_LONG
		), anemia_diagnosis AS (
		    SELECT lopnr, datum, 1 AS outcome 
			FROM all_diagnoses_data 
			WHERE PATINDEX('D6[0-4]%', kod) > 0 
		), Hb_tests_data AS (
		    SELECT lopnr, datum, tid, standard_test_name, standard_result, standard_unit 
			FROM SCREAM2.LAB_TESTS 
			WHERE standard_test_name IN ('regular Hb')
		), anemia_test AS (
		    SELECT tb1.lopnr, tb1.datum, 1 AS outcome
			FROM Hb_tests_data tb1
			INNER JOIN SCREAM2.DEMOGRAPHY tb2
			ON tb1.lopnr = tb2.lopnr 
			WHERE (tb1.standard_result < 100 AND female = 1) OR (tb1.standard_result < 100 AND female = 0)
			GROUP BY tb1.lopnr, tb1.datum
		), anemia_treatment AS (
		    SELECT lopnr, edatum AS datum, 1 AS anemia_treatment
			FROM SCREAM2.LMED 
			WHERE PATINDEX('B03[AX]%', ATC) > 0 
			UNION 
			SELECT tb1.lopnr, tb1.datum, 1 AS anemia_treatment 
			FROM ( 
			    SELECT lopnr, datum 
				FROM SCREAM2.OVR_PROCEDURES_LONG 
				WHERE PATINDEX('DT016%', opk) > 0
			) tb1 
			INNER JOIN (
			    SELECT lopnr, datum 
				FROM SCREAM2.LAB_TESTS 
				WHERE standard_test_name = 'transf_sat' AND standard_result < 0.2
			) tb2
			ON tb1.lopnr = tb2.lopnr AND tb1.datum = tb2.datum --on the same day
		), anemia_test_confirmed_by_treatment AS (
		    SELECT tb1.lopnr, tb1.datum, IIF(SUM(tb2.anemia_treatment) > 0, 1, 0) AS outcome
			FROM anemia_test tb1
			INNER JOIN anemia_treatment tb2
			ON tb1.lopnr = tb2.lopnr AND DATEDIFF(day, tb1.datum, tb2.datum) BETWEEN 0 AND 90
			GROUP BY tb1.lopnr, tb1.datum
		), anemia_test_confirmed_by_test AS (
		    SELECT tb1.lopnr, tb1.datum, IIF(SUM(tb2.outcome) > 0, 1, 0) AS outcome
			FROM anemia_test tb1
			INNER JOIN anemia_test tb2
			ON tb1.lopnr = tb2.lopnr AND DATEDIFF(month, tb1.datum, tb2.datum) > 3
			GROUP BY tb1.lopnr, tb1.datum 
		)
		INSERT INTO @outcome
		    SELECT DISTINCT lopnr, datum, outcome, 'diagnosis' AS [source]   
			FROM anemia_diagnosis 
			UNION 
			SELECT DISTINCT lopnr, datum, outcome, 'treatment' AS [source]   
			FROM anemia_test_confirmed_by_treatment 
			UNION 
			SELECT DISTINCT lopnr, datum, outcome, 'test' AS [source]  
			FROM anemia_test_confirmed_by_test;
    IF @outcome_name = 'all cause death'
		INSERT INTO @outcome
		    SELECT DISTINCT lopnr, dodsdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.DEATH_LONG;
	IF @outcome_name = 'MACE'
		INSERT INTO @outcome
		    SELECT DISTINCT lopnr, dodsdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.DEATH_LONG
			WHERE death_reason_source = 'ULORSAK' 
			AND IIF(PATINDEX('G4[56]%', death_reason) > 0 OR 
			        PATINDEX('H341%', death_reason) > 0 OR 
					PATINDEX('I%', death_reason) > 0, 1, 0) = 1
			UNION
		    SELECT lopnr, utdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.SLV_DIAGNOSES_LONG
			WHERE diag_no IN ('diag1', 'diag2') 
			AND IIF(PATINDEX('I2[123]%', kod) > 0, 1, 0) = 1
			UNION
			SELECT DISTINCT lopnr, utdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.SLV_DIAGNOSES_LONG
			WHERE diag_no IN ('diag1', 'diag2') 
			AND IIF(PATINDEX('G4[56]%', kod) > 0 OR 
					PATINDEX('H341%', kod) > 0 OR 
					PATINDEX('I6[0134]%', kod) > 0, 1, 0) = 1;
	IF @outcome_name = '5-point MACE'
		INSERT INTO @outcome
		    SELECT DISTINCT lopnr, dodsdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.DEATH_LONG
			WHERE death_reason_source = 'ULORSAK' 
			AND IIF(PATINDEX('G4[56]%', death_reason) > 0 OR 
			        PATINDEX('H341%', death_reason) > 0 OR 
					PATINDEX('I%', death_reason) > 0, 1, 0) = 1
			UNION
		    SELECT DISTINCT lopnr, utdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.SLV_DIAGNOSES_LONG
			WHERE diag_no IN ('diag1', 'diag2') 
			AND IIF(PATINDEX('I2[123]%', kod) > 0, 1, 0) = 1
			UNION
			SELECT DISTINCT lopnr, utdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.SLV_DIAGNOSES_LONG
			WHERE diag_no IN ('diag1', 'diag2') 
			AND IIF(PATINDEX('G4[56]%', kod) > 0 OR 
					PATINDEX('H341%', kod) > 0 OR 
					PATINDEX('I6[0134]%', kod) > 0, 1, 0) = 1
			UNION
		    SELECT DISTINCT lopnr, utdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.SLV_DIAGNOSES_LONG
			WHERE diag_no IN ('diag1', 'diag2') 
			AND IIF(PATINDEX('I099%', kod) > 0 OR 
					PATINDEX('I110%', kod) > 0 OR 
					PATINDEX('I13[02]%', kod) > 0 OR 
					PATINDEX('I255%', kod) > 0 OR 
					PATINDEX('I42[05-9]%', kod) > 0 OR 
					PATINDEX('I43%', kod) > 0 OR 
					PATINDEX('I50%', kod) > 0, 1, 0) = 1
			UNION
		    SELECT DISTINCT lopnr, utdat AS datum, 1 AS outcome, NULL AS [source]
			FROM SCREAM2.SLV_DIAGNOSES_LONG
			WHERE diag_no IN ('diag1', 'diag2') 
			AND IIF(PATINDEX('I200%', kod) > 0, 1, 0) = 1;
    RETURN;
END;
GO

--check
--SELECT *
--FROM project.outcome('anemia')
--ORDER BY lopnr, datum;
--GO

/*censoring function*/
CREATE OR ALTER FUNCTION project.censoring (
    @censoring_name VARCHAR(100)
)
RETURNS @censoring TABLE (
    lopnr VARCHAR(9), 
	datum DATE, 
	censoring INT
)
AS BEGIN
	IF @censoring_name = 'refer to nephrologist'
		INSERT INTO @censoring
	        SELECT DISTINCT lopnr, datum, 1 AS outcome 
			FROM SCREAM2.OVR_KOMBIKA 
			WHERE SUBSTRING(kombika, 6, 3) IN (151, 156); 
	IF @censoring_name = 'emigration'
		INSERT INTO @censoring
	        SELECT DISTINCT lopnr, event_date AS datum, 1 AS outcome 
			FROM SCREAM2.IMMIGRATION
			WHERE event_type = 'U';
    RETURN;
END;
GO

--check
--SELECT*
--FROM project.censoring('refer to nephrologist')
--ORDER BY lopnr, datum;
--GO


/*outcome add on function*/
DROP FUNCTION IF EXISTS project.outcome_add_on;
GO
CREATE OR ALTER FUNCTION project.outcome_add_on (
    @outcome_name VARCHAR(100), 
	@type VARCHAR(40) 
)
RETURNS @outcome TABLE (
    lopnr VARCHAR(9), 
	index_date DATE, 
	outcome_date DATE, 
	outcome INT, 
	[source] VARCHAR(20)
)
AS BEGIN
    IF @type = 'incident'
		INSERT INTO @outcome
	        SELECT tb4.lopnr, tb4.index_date, tb4.outcome_date, 
			    IIF(SUM(tb4.outcome) OVER(PARTITION BY tb4.lopnr ORDER BY tb4.index_date) >= 1, 1, 0) AS outcome, 
				tb4.[source]
			FROM (
			    SELECT tb3.lopnr, tb3.index_date, IIF(MIN(tb3.datum) IS NULL, '2018-12-31', MIN(tb3.datum)) AS outcome_date, 
				    IIF(SUM(tb3.outcome) > 0, 1, 0) AS outcome, MIN(tb3.[source]) AS [source] 
				FROM (
				    SELECT tb1.lopnr, tb1.index_date, tb2.datum, tb2.outcome, 
					FIRST_VALUE(tb2.[source]) OVER(PARTITION BY tb1.lopnr ORDER BY datum ASC) AS [source]
					FROM temp.exposure_dataset tb1 
					LEFT JOIN project.outcome(@outcome_name) tb2 
					ON tb1.lopnr = tb2.lopnr 
					AND (tb2.datum > tb1.index_date AND tb2.datum <= '2018-12-31')
				) tb3
				GROUP BY tb3.lopnr, tb3.index_date
			) tb4; 
    ELSE IF @type = 'recurrent'
	    INSERT INTO @outcome 
		    SELECT tb3.lopnr, tb3.index_date, IIF(MAX(tb3.datum) IS NULL, '2018-12-31', MAX(tb3.datum)) AS outcome_date, 
			    IIF(SUM(tb3.outcome) > 0, SUM(tb3.outcome), 0) AS outcome, NULL AS [source] --need to change later!!!! 
			FROM (
				SELECT tb1.lopnr, tb1.index_date, tb2.datum, tb2.outcome 
				FROM temp.exposure_dataset tb1 
				LEFT JOIN project.outcome(@outcome_name) tb2 
				ON tb1.lopnr = tb2.lopnr 
				AND (tb2.datum > tb1.index_date AND tb2.datum <= '2018-12-31')
			) tb3
			GROUP BY tb3.lopnr, tb3.index_date;
    RETURN;
END;
GO

--check
--SELECT *
--FROM project.outcome_add_on('anemia 12', 'incident')
--ORDER BY lopnr, index_date;
--GO

/*censoring add on function*/
CREATE OR ALTER FUNCTION project.censoring_add_on (
    @censoring_name VARCHAR(100)
)
RETURNS TABLE
AS
    RETURN (
	    SELECT tb4.lopnr, tb4.index_date, tb4.censoring_date, 
		    IIF(SUM(tb4.censoring) OVER(PARTITION BY tb4.lopnr ORDER BY tb4.index_date) >= 1, 1, 0) AS censoring
		FROM (
	        SELECT tb3.lopnr, tb3.index_date, IIF(MIN(tb3.datum) IS NULL, '2018-12-31', MIN(tb3.datum)) AS censoring_date, 
			    IIF(SUM(tb3.censoring) > 0, 1, 0) AS censoring
	        FROM (
		        SELECT tb1.lopnr, tb1.index_date, tb2.datum, tb2.censoring
	            FROM temp.exposure_dataset tb1
	            LEFT JOIN project.censoring(@censoring_name) tb2
	            ON tb1.lopnr = tb2.lopnr 
	            AND (tb2.datum >= tb1.index_date AND tb2.datum <= '2018-12-31')
	        ) tb3
	        GROUP BY tb3.lopnr, tb3.index_date
		) tb4
	);
GO

--check
--SELECT *
--FROM project.censoring_add_on('refer to nephrologist')
--ORDER BY lopnr, index_date;
--GO