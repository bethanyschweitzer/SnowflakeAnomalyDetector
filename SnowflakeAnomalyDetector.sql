select * from tst_dailyinventory_notreal
order by date;

create or replace view value_history as 
select cast(tst_dailyinventory_notreal.date as timestamp_ntz) date, total_value, [plant, material] as plant_material 
from tst_dailyinventory_notreal  
where date between to_date('5/25/2024') and to_date('5/31/2024')
--and plant = 7129 
--and material = '200000237'
group by date, total_value, plant_material
order by plant_material, date;

select * from value_history;

SELECT COUNT(DISTINCT plant) AS unique_count_plant
FROM value_history;

SELECT COUNT(DISTINCT material) AS unique_count_material
FROM value_history;

SELECT DISTINCT plant, material
FROM value_history;

create or replace snowflake.ml.anomaly_detection ad_model1(
                                        input_data => SYSTEM$REFERENCE('VIEW', 'value_history'),
                                        series_colname => 'plant_material',
                                        timestamp_colname => 'date',
                                        target_colname => 'total_value',
                                        label_colname => '' --unsupervised
                                    );

show snowflake.ml.anomaly_detection;

create or replace view value_for_detection as 
select cast(tst_dailyinventory_nm.date as timestamp_ntz) date, total_value, [plant, material] as plant_material 
from tst_dailyinventory_nm
where date between to_date('6/1/2024') and to_date('6/19/2024') 
--and plant = 7129 
--and material = '200000237'
group by date, total_value, plant_material
order by plant_material, date;

select * from value_for_detection;

call ad_model1!detect_anomalies(input_data => SYSTEM$REFERENCE('VIEW', 'value_for_detection'),
                    series_colname => 'plant_material',
                    timestamp_colname =>'date',
                    target_colname => 'total_value'
                   );


CREATE OR REPLACE TABLE inventory_anomaly_results AS
SELECT *
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SELECT *
FROM inventory_anomaly_results;
