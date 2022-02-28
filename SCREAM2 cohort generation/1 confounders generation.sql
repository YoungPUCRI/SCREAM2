USE SCREAM2;
GO

/*comorbidity covariates*/
CREATE OR ALTER FUNCTION project.comorbidity_add_on (
    @comorbidity VARCHAR(100), 
	@type VARCHAR(16) = 'time varying', 
	@time_window INT
)
RETURNS @comorbidity_add_on TABLE(
    lopnr INT, 
	index_date DATE, 
	comorbidity INT
)
AS BEGIN
	IF @type = 'time fixed'
	BEGIN
    INSERT INTO @comorbidity_add_on
	    SELECT tb1.lopnr, tb1.index_date AS tstart, IIF(SUM(IIF(tb2.comorbidity = @comorbidity, 1, 0)) > 0, 1, 0) AS comorbidity
	    FROM temp.exposure_dataset tb1
	    LEFT JOIN (
		    SELECT *
			FROM dictionary.comorbidity
			WHERE comorbidity = @comorbidity
		) tb2
	    ON tb1.lopnr = tb2.lopnr 
	    AND (tb2.datum <= tb1.index_date AND tb2.datum >= DATEADD(month, @time_window, tb1.index_date))
		GROUP BY tb1.lopnr, tb1.index_date; 
	END
	ELSE 
	    INSERT INTO @comorbidity_add_on VALUES(NULL, NULL, CAST('typo for parameter @type' AS INT)); -- not customized error message
	RETURN;
END;
GO

--check
--SELECT *
--FROM project.comorbidity_add_on('hypertension', 'time fixed', -120);
--GO

/*use of medication covariates*/
CREATE OR ALTER FUNCTION project.medication_add_on (
    @medication_use VARCHAR(100), 
	@type VARCHAR(16) = 'time varying', 
	@time_window INT
)
RETURNS @medication_use_add_on TABLE(
    lopnr INT, 
	index_date DATE, 
	medication_use INT
)
AS BEGIN
    IF @type = 'time fixed'
	BEGIN
    INSERT INTO @medication_use_add_on
	    SELECT tb1.lopnr, tb1.index_date AS tstart, IIF(SUM(IIF(tb2.medication_use = @medication_use, 1, 0)) > 0, 1, 0) AS medication_use
	    FROM temp.exposure_dataset tb1
	    LEFT JOIN (
		    SELECT *
			FROM dictionary.medication_use
			WHERE medication_use = @medication_use
		) tb2
	    ON tb1.lopnr = tb2.lopnr 
	    AND (tb2.edatum <= tb1.index_date AND tb2.edatum >= DATEADD(month, @time_window, tb1.index_date))
		GROUP BY tb1.lopnr, tb1.index_date; 
	END
	ELSE 
	    INSERT INTO @medication_use_add_on VALUES(NULL, NULL, CAST('typo for parameter @type' AS INT)); -- not customized error message
	RETURN;
END;
GO

--check
--SELECT *
--FROM project.medication_add_on('immunosuppressant', 'time fixed', -120);
--GO

/*lab test covariates*/
CREATE OR ALTER FUNCTION project.lab_test_add_on (
    @test VARCHAR(20), 
	@type VARCHAR(16) = 'time varying', 
	@function VARCHAR(20), 
	@time_window INT
)
RETURNS @lab_test_add_on TABLE(
    lopnr INT, 
	index_date DATE, 
	result FLOAT
)
AS BEGIN
    IF @type = 'time fixed'
	BEGIN
	    IF @function = 'nearest'
	        INSERT INTO @lab_test_add_on
		        SELECT tb3.lopnr, tb3.tstart, CAST(AVG(result) AS DECIMAL(10, 3)) AS result
	            FROM (
		            SELECT tb1.lopnr, tb1.index_date AS tstart, 
				        FIRST_VALUE(tb2.standard_result) OVER(PARTITION BY tb1.lopnr, tb1.index_date ORDER BY tb2.datum DESC, tb2.tid DESC, tb2.standard_result DESC) AS result
	                FROM temp.exposure_dataset tb1
	                LEFT JOIN (
				        SELECT lopnr, datum, tid, standard_result
					    FROM SCREAM2.LAB_TESTS
					    WHERE standard_test_name = @test AND vtype != IIF(@test = 'eGFR', 'IP', '')
				    ) tb2
	                ON tb1.lopnr = tb2.lopnr  
	                AND (tb2.datum <= tb1.index_date AND tb2.datum >= DATEADD(month, @time_window, tb1.index_date))
	            ) tb3
			    GROUP BY tb3.lopnr, tb3.tstart;
		IF @function = 'average'
		    INSERT INTO @lab_test_add_on
		        SELECT tb3.lopnr, tb3.tstart, CAST(AVG(result) AS DECIMAL(10, 3)) AS result
	            FROM (
		            SELECT tb1.lopnr, tb1.index_date AS tstart, 
				        AVG(tb2.standard_result) OVER(PARTITION BY tb1.lopnr, tb1.index_date ORDER BY tb2.datum DESC, tb2.tid DESC, tb2.standard_result DESC) AS result
	                FROM temp.exposure_dataset tb1
	                LEFT JOIN (
				        SELECT lopnr, datum, tid, standard_result
					    FROM SCREAM2.LAB_TESTS
					    WHERE standard_test_name = @test AND vtype != IIF(@test = 'eGFR', 'IP', '')
				    ) tb2
	                ON tb1.lopnr = tb2.lopnr  
	                AND (tb2.datum <= tb1.index_date AND tb2.datum >= DATEADD(month, @time_window, tb1.index_date))
	            ) tb3
			    GROUP BY tb3.lopnr, tb3.tstart;
	END
	ELSE 
	    INSERT INTO @lab_test_add_on VALUES(NULL, NULL, CAST('typo for parameter @type' AS INT)); -- not customized error message
	RETURN;
END;
GO

--check
SELECT *
FROM project.lab_test_add_on('eGFR', 'time fixed', 'average', -12)
WHERE result >= 60;
GO
