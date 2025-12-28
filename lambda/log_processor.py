import json
import gzip
import base64
import os
import boto3
import requests
from datetime import datetime
from requests_aws4auth import AWS4Auth

# AWS clients
s3 = boto3.client("s3")
sns = boto3.client("sns")

# Env variables
LOGS_BUCKET = os.environ["LOGS_BUCKET"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
OPENSEARCH_ENDPOINT = os.environ["OPENSEARCH_ENDPOINT"]
OPENSEARCH_INDEX = os.environ["OPENSEARCH_INDEX"]
REGION = os.environ["AWS_REGION"]

# Error detection
ERROR_KEYWORDS = ["ERROR", "CRITICAL", "Exception"]

# OpenSearch auth (IAM)
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    REGION,
    "es",
    session_token=credentials.token
)

HEADERS = {"Content-Type": "application/json"}

def send_to_opensearch(document):
    """
    Envoie un log enrichi vers OpenSearch
    """
    url = f"{OPENSEARCH_ENDPOINT}/{OPENSEARCH_INDEX}/_doc"
    requests.post(
        url,
        auth=awsauth,
        headers=HEADERS,
        data=json.dumps(document)
    )

def lambda_handler(event, context):
    #  Decode CloudWatch logs
    compressed_payload = base64.b64decode(event["awslogs"]["data"])
    uncompressed_payload = gzip.decompress(compressed_payload)
    logs_data = json.loads(uncompressed_payload)

    processed_logs = []
    critical_logs = []

    # Process logs
    for log_event in logs_data["logEvents"]:
        message = log_event["message"]

        level = "INFO"
        if any(k in message for k in ERROR_KEYWORDS):
            level = "ERROR"
            critical_logs.append(message)

        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": level,
            "message": message,
            "log_group": logs_data["logGroup"],
            "log_stream": logs_data["logStream"],
            "source": "cloudwatch",
            "aws_region": REGION
        }

        processed_logs.append(log_entry)

        # Envoi vers OpenSearch (indexation)
        send_to_opensearch(log_entry)

    # Stockage S3 (archive des logs enrichis)
    s3.put_object(
        Bucket=LOGS_BUCKET,
        Key=f"processed-logs/{datetime.utcnow().date()}.json",
        Body=json.dumps(processed_logs),
        ContentType="application/json"
    )

    # Alerte SNS si erreurs critiques
    if critical_logs:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="🚨 AWS Observability - ERROR détectée",
            Message="\n".join(critical_logs)
        )

    return {
        "statusCode": 200,
        "body": f"{len(processed_logs)} logs processed"
    }
