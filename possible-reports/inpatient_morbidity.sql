-- Parameters
SET @start_date = '2014-09-01';
SET @end_date = '2014-10-01';

-- Constants
SET @ipd_visit_type =  'IPD';
SET @discharge_encounter_type = 'DISCHARGE';
SET @report_group_name = 'Inpatient Discharge Reports';

-- Query for disease age group count
SELECT diagnosis.code, diagnosis.full_name as disease,
observed_age_group.name AS age_group,
SUM(CASE WHEN person.gender = 'F' THEN 1 ELSE 0 END) AS female,
SUM(CASE WHEN person.gender = 'M' THEN 1 ELSE 0 END) AS male
FROM diagnosis_icd10_mapping AS diagnosis
JOIN valid_confirmed_diagnosis ON valid_confirmed_diagnosis.diagnois_concept_id = diagnosis.concept_id 
							   AND valid_confirmed_diagnosis.visit_type = @ipd_visit_type
JOIN person ON valid_confirmed_diagnosis.person_id = person.person_id
JOIN encounter_data ON encounter_data.patient_id = person.person_id AND encounter_data.encounter_type = @discharge_encounter_type
JOIN possible_age_group as observed_age_group ON observed_age_group.report_group_name = @report_group_name AND
					valid_confirmed_diagnosis.obs_datetime BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY)) 
					AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))  
WHERE valid_confirmed_diagnosis.obs_datetime BETWEEN @start_date AND @end_date
GROUP BY diagnosis.concept_id, diagnosis.full_name, diagnosis.code, observed_age_group.id
ORDER BY disease;

-- Query for disease and death count
SELECT diagnosis.code, diagnosis.full_name as disease,
SUM(CASE WHEN person.gender = 'F' THEN 1 ELSE 0 END) AS female_death,
SUM(CASE WHEN person.gender = 'M' THEN 1 ELSE 0 END) AS male_death
FROM diagnosis_icd10_mapping AS diagnosis
JOIN valid_confirmed_diagnosis ON valid_confirmed_diagnosis.diagnois_concept_id = diagnosis.concept_id 
							   AND valid_confirmed_diagnosis.visit_type = @ipd_visit_type
LEFT OUTER JOIN person ON valid_confirmed_diagnosis.person_id = person.person_id AND person.dead = 1
					   AND person.death_date BETWEEN @start_date AND @end_date
WHERE valid_confirmed_diagnosis.obs_datetime BETWEEN @start_date AND @end_date
GROUP BY diagnosis.concept_id, diagnosis.full_name, diagnosis.code
ORDER BY disease;