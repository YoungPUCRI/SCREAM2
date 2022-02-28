USE SCREAM2;
GO

/*comorbidity*/
DROP TABLE IF EXISTS ##analysis_dataset_comorbidity;
GO
SELECT * INTO ##analysis_dataset_comorbidity
FROM project.exposure_dataset_PEANUT;
GO
--comorbidity combination
CREATE OR ALTER PROC project.comorbidity_combination @comorbidity_list VARCHAR(8000), @time_window_list VARCHAR(8000)
AS
    DECLARE @comorbidity_pos INT;
    DECLARE @comorbidity_len INT;
    DECLARE @time_window_pos INT;
    DECLARE @time_window_len INT;
    DECLARE @comorbidity_value VARCHAR(200);
    DECLARE @time_window_value VARCHAR(200);
	DECLARE @comorbidity_name VARCHAR(60);

    SET @comorbidity_pos = 0;
    SET @comorbidity_len = 0;
    SET @time_window_pos = 0;
    SET @time_window_len = 0;
    WHILE CHARINDEX(';', @comorbidity_list, @comorbidity_pos + 1)>0
    BEGIN
        SET @comorbidity_len = CHARINDEX(';', @comorbidity_list, @comorbidity_pos + 1) - @comorbidity_pos;
	    SET @time_window_len = CHARINDEX(';', @time_window_list, @time_window_pos + 1) - @time_window_pos;
        SET @comorbidity_value = SUBSTRING(@comorbidity_list, @comorbidity_pos, @comorbidity_len);
	    SET @time_window_value = SUBSTRING(@time_window_list, @time_window_pos, @time_window_len);
		SET @comorbidity_name = REPLACE(SUBSTRING(@comorbidity_value, 1, 
		    IIF(PATINDEX('%(%', @comorbidity_value) = 0, 
			    LEN(@comorbidity_value) + 2, 
				PATINDEX('%(%', @comorbidity_value)) - 2), ' ', '_');
        PRINT @comorbidity_value; -- for debug porpose   
        DROP TABLE IF EXISTS ##table_comorbidity;
	    EXEC('SELECT tb1.*, 
        tb2.comorbidity AS cov_' + @comorbidity_name + 
	    ' INTO ##table_comorbidity FROM ##analysis_dataset_comorbidity tb1
        INNER JOIN project.comorbidity_add_on(''' + @comorbidity_value + ''', ''time fixed'', CAST(' + @time_window_value + 
	    ' AS INT)) tb2
        ON tb1.lopnr = tb2.lopnr AND tb1.index_date = tb2.index_date;');
	    DROP TABLE IF EXISTS ##analysis_dataset_comorbidity; 
	    SELECT * INTO ##analysis_dataset_comorbidity
	    FROM ##table_comorbidity;
	    DROP TABLE IF EXISTS ##table_comorbidity;
        SET @comorbidity_pos = CHARINDEX(';', @comorbidity_list, @comorbidity_pos + @comorbidity_len) + 1;
	    SET @time_window_pos = CHARINDEX(';', @time_window_list, @time_window_pos + @time_window_len) + 1;
    END;
GO

--set your parameter here
EXEC project.comorbidity_combination 
@comorbidity_list = 'diabetes;hypertension;MI;heart failure;peripheral vascular disease;cerebrovascular disease (includes stroke);atrial fibrillation;COPD;dementia;inflammatory bowel disease;rheumatoid disease;liver disease;peptic ulcer disease;', 
@time_window_list = '-120;-120;-120;-120;-120;-120;-120;-120;-120;-120;-120;-120;-120;';
GO

--check
SELECT *
FROM ##analysis_dataset_comorbidity;
GO


/*medication use*/
DROP TABLE IF EXISTS ##analysis_dataset_medication_use;
GO
SELECT * INTO ##analysis_dataset_medication_use
FROM ##analysis_dataset_comorbidity;
GO

--medication use combination
CREATE OR ALTER PROC project.medication_use_combination @medication_use_list VARCHAR(8000), @time_window_list VARCHAR(8000)
AS
    DECLARE @medication_use_pos INT;
    DECLARE @medication_use_len INT;
    DECLARE @time_window_pos INT;
    DECLARE @time_window_len INT;
    DECLARE @medication_use_value VARCHAR(200);
    DECLARE @time_window_value VARCHAR(200);
	DECLARE @medication_use_name VARCHAR(60);

    SET @medication_use_pos = 0;
    SET @medication_use_len = 0;
    SET @time_window_pos = 0;
    SET @time_window_len = 0;
    WHILE CHARINDEX(';', @medication_use_list, @medication_use_pos + 1)>0
    BEGIN
        SET @medication_use_len = CHARINDEX(';', @medication_use_list, @medication_use_pos + 1) - @medication_use_pos;
	    SET @time_window_len = CHARINDEX(';', @time_window_list, @time_window_pos + 1) - @time_window_pos;
        SET @medication_use_value = SUBSTRING(@medication_use_list, @medication_use_pos, @medication_use_len);
	    SET @time_window_value = SUBSTRING(@time_window_list, @time_window_pos, @time_window_len);
		SET @medication_use_name = REPLACE(REPLACE(REPLACE(SUBSTRING(@medication_use_value, 1, 
		    IIF(PATINDEX('%(%', @medication_use_value) = 0, 
			    LEN(@medication_use_value) + 2, 
				PATINDEX('%(%', @medication_use_value)) - 2), ' ', '_'), ',_', '_'), '_&', '');
        PRINT @medication_use_value; -- for debug porpose   
        DROP TABLE IF EXISTS ##table_medication_use;
	    EXEC('SELECT tb1.*, 
        tb2.medication_use AS cov_' + @medication_use_name + 
	    ' INTO ##table_medication_use FROM ##analysis_dataset_medication_use tb1
        INNER JOIN project.medication_add_on(''' + @medication_use_value + ''', ''time fixed'', CAST(' + @time_window_value + 
	    ' AS INT)) tb2
        ON tb1.lopnr = tb2.lopnr AND tb1.index_date = tb2.index_date;');
	    DROP TABLE IF EXISTS ##analysis_dataset_medication_use; 
	    SELECT * INTO ##analysis_dataset_medication_use
	    FROM ##table_medication_use;
	    DROP TABLE IF EXISTS ##table_medication_use;
        SET @medication_use_pos = CHARINDEX(';', @medication_use_list, @medication_use_pos + @medication_use_len) + 1;
	    SET @time_window_pos = CHARINDEX(';', @time_window_list, @time_window_pos + @time_window_len) + 1;
    END;
GO

--set your parameter here
EXEC project.medication_use_combination 
@medication_use_list = 'corticosteroid;immunosuppressant;antibiotic, antiviral, antimycotic;aspirin;NSAID;ACEI & ARB;MRA;beta blocker;vitamin K antagonist;', 
@time_window_list = '-6;-6;-6;-6;-6;-6;-6;-6;-6;';
GO

--check
SELECT *
FROM ##analysis_dataset_medication_use;
GO

/*lab test*/
DROP TABLE IF EXISTS ##analysis_dataset_lab_test;
GO
SELECT * INTO ##analysis_dataset_lab_test
FROM ##analysis_dataset_medication_use;
GO

--lab test combination
CREATE OR ALTER PROC project.lab_test_combination @lab_test_list VARCHAR(8000), @function_list VARCHAR(8000), @time_window_list VARCHAR(8000)
AS
    DECLARE @lab_test_pos INT;
    DECLARE @lab_test_len INT;
    DECLARE @time_window_pos INT;
    DECLARE @time_window_len INT;
	DECLARE @function_pos INT;
    DECLARE @function_len INT;
    DECLARE @lab_test_value VARCHAR(200);
    DECLARE @time_window_value VARCHAR(200);
	DECLARE @function_value VARCHAR(200);
	DECLARE @lab_test_name VARCHAR(60);

    SET @lab_test_pos = 0;
    SET @lab_test_len = 0;
    SET @time_window_pos = 0;
    SET @time_window_len = 0;
	SET @function_pos = 0;
    SET @function_len = 0;
    WHILE CHARINDEX(';', @lab_test_list, @lab_test_pos + 1)>0
    BEGIN
        SET @lab_test_len = CHARINDEX(';', @lab_test_list, @lab_test_pos + 1) - @lab_test_pos;
	    SET @time_window_len = CHARINDEX(';', @time_window_list, @time_window_pos + 1) - @time_window_pos;
		SET @function_len = CHARINDEX(';', @function_list, @function_pos + 1) - @function_pos;
        SET @lab_test_value = SUBSTRING(@lab_test_list, @lab_test_pos, @lab_test_len);
	    SET @time_window_value = SUBSTRING(@time_window_list, @time_window_pos, @time_window_len);
		SET @function_value = SUBSTRING(@function_list, @function_pos, @function_len);
		SET @lab_test_name = REPLACE(REPLACE(@lab_test_value, ' ', '_'), '-', '_');
        PRINT @lab_test_value; -- for debug porpose   
        DROP TABLE IF EXISTS ##table_lab_test;
	    EXEC('SELECT tb1.*, 
        tb2.result AS cov_' + @lab_test_name + 
	    ' INTO ##table_lab_test FROM ##analysis_dataset_lab_test tb1
        INNER JOIN project.lab_test_add_on(''' + @lab_test_value + ''', ''time fixed'', ''' + @function_value + ''', CAST(' + @time_window_value + 
	    ' AS INT)) tb2
        ON tb1.lopnr = tb2.lopnr AND tb1.index_date = tb2.index_date;');
	    DROP TABLE IF EXISTS ##analysis_dataset_lab_test; 
	    SELECT * INTO ##analysis_dataset_lab_test
	    FROM ##table_lab_test;
	    DROP TABLE IF EXISTS ##table_lab_test;
        SET @lab_test_pos = CHARINDEX(';', @lab_test_list, @lab_test_pos + @lab_test_len) + 1;
	    SET @time_window_pos = CHARINDEX(';', @time_window_list, @time_window_pos + @time_window_len) + 1;
		SET @function_pos = CHARINDEX(';', @function_list, @function_pos + @function_len) + 1;
    END;
GO

--set your parameter here
EXEC project.lab_test_combination 
@lab_test_list = 'salb;ualb;all crp;transf_sat;ferritin;eGFR;', 
@function_list = 'nearest;nearest;nearest;nearest;nearest;nearest;', 
@time_window_list = '-12;-12;-12;-12;-12;-12;';
GO

--check
SELECT *
FROM ##analysis_dataset_lab_test;
GO


/*outcome*/
DROP TABLE IF EXISTS ##analysis_dataset_outcome;
GO
SELECT * INTO ##analysis_dataset_outcome
FROM ##analysis_dataset_lab_test;
GO

--outcome combination
CREATE OR ALTER PROC project.outcome_combination @outcome_list VARCHAR(8000), @type_list VARCHAR(8000)
AS
    DECLARE @outcome_pos INT;
    DECLARE @outcome_len INT;
    DECLARE @type_pos INT;
    DECLARE @type_len INT;
    DECLARE @outcome_value VARCHAR(200);
    DECLARE @type_value VARCHAR(200);
	DECLARE @outcome_name VARCHAR(60);

    SET @outcome_pos = 0;
    SET @outcome_len = 0;
    SET @type_pos = 0;
    SET @type_len = 0;
    WHILE CHARINDEX(';', @outcome_list, @outcome_pos + 1)>0
    BEGIN
        SET @outcome_len = CHARINDEX(';', @outcome_list, @outcome_pos + 1) - @outcome_pos;
	    SET @type_len = CHARINDEX(';', @type_list, @type_pos + 1) - @type_pos;
        SET @outcome_value = SUBSTRING(@outcome_list, @outcome_pos, @outcome_len);
	    SET @type_value = SUBSTRING(@type_list, @type_pos, @type_len);
		SET @outcome_name = REPLACE(REPLACE(@outcome_value, ' ', '_'), '-', '_');
        PRINT @outcome_value; -- for debug porpose   
        DROP TABLE IF EXISTS ##table_outcome;
	    EXEC('SELECT tb1.*, 
        tb2.outcome AS outcome_' + @outcome_name + ', tb2.outcome_date AS outcome_date_' + @outcome_name + 
		', tb2.source AS source_' + @outcome_name + 
	    ' INTO ##table_outcome FROM ##analysis_dataset_outcome tb1
        INNER JOIN project.outcome_add_on(''' + @outcome_value + ''', ''' + @type_value + 
	    ''') tb2
        ON tb1.lopnr = tb2.lopnr AND tb1.index_date = tb2.index_date;');
	    DROP TABLE IF EXISTS ##analysis_dataset_outcome; 
	    SELECT * INTO ##analysis_dataset_outcome
	    FROM ##table_outcome;
	    DROP TABLE IF EXISTS ##table_outcome;
        SET @outcome_pos = CHARINDEX(';', @outcome_list, @outcome_pos + @outcome_len) + 1;
	    SET @type_pos = CHARINDEX(';', @type_list, @type_pos + @type_len) + 1;
    END;
GO

--set your parameter here
EXEC project.outcome_combination 
@outcome_list = 'anemia;all cause death;anemia 12;anemia 10;', 
@type_list = 'incident;incident;incident;incident;';
GO

--check
SELECT *
FROM ##analysis_dataset_outcome;
GO


/*censoring*/
DROP TABLE IF EXISTS ##analysis_dataset_censoring;
GO
SELECT * INTO ##analysis_dataset_censoring
FROM ##analysis_dataset_outcome;
GO

--censoring combination
CREATE OR ALTER PROC project.censoring_combination @censoring_list VARCHAR(8000)
AS
    DECLARE @censoring_pos INT;
    DECLARE @censoring_len INT;
    DECLARE @censoring_value VARCHAR(200);
	DECLARE @censoring_name VARCHAR(60);

    SET @censoring_pos = 0;
    SET @censoring_len = 0;
    WHILE CHARINDEX(';', @censoring_list, @censoring_pos + 1)>0
    BEGIN
        SET @censoring_len = CHARINDEX(';', @censoring_list, @censoring_pos + 1) - @censoring_pos;
        SET @censoring_value = SUBSTRING(@censoring_list, @censoring_pos, @censoring_len);
		SET @censoring_name = REPLACE(@censoring_value, ' ', '_');
        PRINT @censoring_value; -- for debug porpose   
        DROP TABLE IF EXISTS ##table_censoring;
	    EXEC('SELECT tb1.*, 
        tb2.censoring AS censoring_' + @censoring_name + ', tb2.censoring_date AS censoring_date_' + @censoring_name + 
	    ' INTO ##table_censoring FROM ##analysis_dataset_censoring tb1
        INNER JOIN project.censoring_add_on(''' + @censoring_value + ''') tb2
        ON tb1.lopnr = tb2.lopnr AND tb1.index_date = tb2.index_date;');
	    DROP TABLE IF EXISTS ##analysis_dataset_censoring; 
	    SELECT * INTO ##analysis_dataset_censoring
	    FROM ##table_censoring;
	    DROP TABLE IF EXISTS ##table_censoring;
        SET @censoring_pos = CHARINDEX(';', @censoring_list, @censoring_pos + @censoring_len) + 1;
    END;
GO

--set your parameter here
EXEC project.censoring_combination 
@censoring_list = 'refer to nephrologist;emigration;';
GO

--check
DROP TABLE IF EXISTS project.analysis_dataset_PEANUT_primary_objective;
GO
SELECT * INTO project.analysis_dataset_PEANUT_primary_objective
FROM ##analysis_dataset_censoring
WHERE anemia_indicator = 0;
GO
SELECT *
FROM project.analysis_dataset_PEANUT_primary_objective;
GO
