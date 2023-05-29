import datetime
import json
import os
import uuid
from random import randrange, choice

from faker import Faker
from google.cloud import storage

storage_client = storage.Client()
input_bucket = os.getenv("INPUT_BUCKET", "de-da-poc-data")
output_bucket = os.getenv("OUTPUT_BUCKET", "medication-forms")
num_of_records = os.getenv("NUM_RECORDS", 10)


def get_medication_form():
    medication_form = {
        "info": {
            "formName": "Medication Review",
            "version": "1.1",
            "sumbittedTime": str(datetime.datetime.now())
        },
        "data": {

            "patient": "ref patient.json",
            "medication": "[ref medication.json]",
            "pharmacy": "ref pharmacy.json",
            "reaction": "[ref reaction.json]",
            "consentProvided": "true",
            "lifestyle": {
                "alcohol": [
                    "No"
                ],
                "dietaryConcerns": "no",
                "exerciseOverallCheck": "false",
                "notesCheck": "false",
                "otherCheck": "false",
                "recDrugs": [
                    "No"
                ],
                "smokingCessationCheck": "no",
                "tobacco": [
                    "No"
                ],
                "tobaccoCessationOffered": "no"
            },
            "ackDate": "2023-01-01",
            "acknowledgement": {
                "comments": "",
                "virtualComment": ""
            },
            "drugPlan": [
                {
                    "drugPlan": {
                        "clientID": "5959404558",
                        "coverageExpiryDate": "2040-12-31",
                        "coverageRelationship": "NOT KNOWN",
                        "nameEN": "ONTARIO DRUG BENEFIT PROGRAM (REGULAR)"
                    }
                },
                {
                    "drugPlan": {
                        "clientID": "5959404558",
                        "coverageRelationship": "NOT KNOWN",
                        "nameEN": "NARCOTIC MONITORING SYSTEM PROGRAM (NMS) (REGULAR)"
                    }
                }
            ]
        }
    }
    return medication_form


def read_record(path):
    bucket = storage_client.get_bucket(input_bucket)
    blob = bucket.blob(path).download_as_string()
    data = json.loads(blob)
    num = randrange(0, len(data), 1)
    print("The record position is", num)
    return data[num]


def get_patient_data():
    num = randrange(0, 49, 1)
    print("Patient num", num)
    patient_path = "patient/patient-{}.json".format(num)
    return read_record(patient_path)


def get_pharmacy_data():
    num = randrange(0, 299, 1)
    print("Pharmacy num", num)
    pharmacy_path = "pharmacy-Data/pharmacy-{}.json".format(num)
    return read_record(pharmacy_path)


def get_medication_data():
    record_num = randrange(1, 6, 1)
    medication_list = []
    for i in range(0, record_num):
        num = randrange(0, 284, 1)
        print("Medication num", num)

        medication_path = "medication_data/medication-{}.json".format(num)
        medication_list.append(read_record(medication_path))
    return medication_list


def get_reaction_data():
    record_num = randrange(0, 5, 1)
    reaction_list = []
    for i in range(0, record_num):
        num = randrange(0, 198, 1)
        print("Reaction num", num)

        reaction_path = "reaction/record{}.json".format(num)
        reaction_list.append(read_record(reaction_path))
    return reaction_list


def get_drug_plan_data():
    record_num = randrange(1, 3, 1)
    drug_plans_list = []
    for i in range(0, record_num):
        num = randrange(0, 99, 1)
        print("Drug Plan num", num)

        reaction_path = "drug_plans/drug_plans-{}.json".format(num)
        drug_plans_list.append(read_record(reaction_path))
    return drug_plans_list


def generate_medication_form(patient_data, pharmacy_data, medication_data, reaction_data, drug_plans_data, file_name):
    list_true_false = ["true", "false"]
    list_yes_no = ["Yes", "No"]
    fake = Faker()
    medication_form = get_medication_form()
    medication_form["data"]["patient"] = patient_data
    medication_form["data"]["medication"] = medication_data
    medication_form["data"]["pharmacy"] = pharmacy_data
    medication_form["data"]["reaction"] = reaction_data
    medication_form["data"]["drugPlan"] = drug_plans_data
    medication_form['data']['consentProvided'] = choice(list_true_false)
    medication_form['data']['lifestyle']['alcohol'] = [choice(list_yes_no)]
    medication_form['data']['lifestyle']['dietaryConcerns'] = choice(list_yes_no)
    medication_form['data']['lifestyle']['exerciseOverallCheck'] = choice(list_true_false)
    medication_form['data']['lifestyle']['notesCheck'] = choice(list_true_false)
    medication_form['data']['lifestyle']['otherCheck'] = choice(list_true_false)
    medication_form['data']['lifestyle']['recDrugs'] = [choice(list_yes_no)]
    medication_form['data']['lifestyle']['smokingCessationCheck'] = choice(list_yes_no)
    medication_form['data']['lifestyle']['tobacco'] = [choice(list_yes_no)]
    medication_form['data']['lifestyle']['tobaccoCessationOffered'] = choice(list_yes_no)
    medication_form['data']['ackDate'] = str(fake.date_time_between(start_date='-5y', end_date='now').date())
    return create_json(medication_form, file_name)


def create_json(json_object, filename):
    '''
    this function will create json object in
    google cloud storage
    '''
    # create a blob
    new_bucket = storage_client.get_bucket(output_bucket)
    blob = new_bucket.blob(filename)
    # upload the blob
    blob.upload_from_string(
        data=json.dumps(json_object),
        content_type='application/json'
    )
    result = filename + ' upload complete'
    return {'response': result}


def generate_data(request):
    print("Request is", request)
    for i in range(0, int(num_of_records)):
        patient_data = get_patient_data()
        pharmacy_data = get_pharmacy_data()
        medication_data = get_medication_data()
        reaction_data = get_reaction_data()
        drug_plans_data = get_drug_plan_data()
        message_uuid = str(uuid.uuid4())
        file_name = "medication_form-{}.json".format(message_uuid)
        result = generate_medication_form(patient_data, pharmacy_data, medication_data, reaction_data, drug_plans_data,
                                          file_name)
        print(result)
    return {'response': "Successfully Uploaded"}


