# process-instance-migration-script

## Required tools:

* bash
* curl
* jq

## Steps:

1. Set the appropriate authentication method and specify it in the curl parameters
2. Set PROCESS_DEF_KEY variable
3. Set REST_API_URL variable

* Migration plans are saved as response_generate_${i}.json, where ${is} is process definition id.
* Validation results are saved as response_validate_${i}.json, where ${is} is process definition id.
* Response code = 204 if execution is OK.