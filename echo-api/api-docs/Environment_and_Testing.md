You, as an integrating partner, are expected to maintain your own development, test and production environments from which to call the corresponding Address Validation System API and to follow the software development life-cycle.


## Environment Detail
| Name | Use | Address |
| ------ | ------ | ------ |
|Development Environment | This environment is for development and unit testing | https://address-validation-system-api-dev.cloudhub.io/addressValidation/v1.0.0/*
|QA Environment | This environment is for validation testing | https://address-validation-system-api-qa.cloudhub.io/addressValidation/v1.0.0/*
|UAT Environment | This environment is for pre-prod validation testing | https://address-validation-system-api-uat.cloudhub.io/addressValidation/v1.0.0/*
|Production Environment | This environment is for live use. | https://address-validation-system-api.cloudhub.io/addressValidation/v1.0.0/*

## Pre-requisites
Request Access to the API and generate Client ID/Secret. Please refer the *How to Consume API* and *Security* page for more details.<br>

## Testing Your Application
In order to make your integration easy and robust we provide below some sample test cases that you can use to test your integration.
Please extend with test cases specific to your business.

| Suggested Test Cases | URL | Expected Result |
| ------ | ------ | ------ |
| Verify given address | verification?street=50 Fremont St&zip=94105&apt=Suite 300 | Expected options are displayed |
| Retrieve City and State for a given Zip | cityState?zip=94111 | Expected options are displayed |
| Retrieve Zip for a given City,State and Street | zip?street=77 Geary St&city=San Francisco&state=CA | Expected options are displayed |
