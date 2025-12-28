import json
import gzip
import base64
import os
import boto3
from datetime import datetime

s3 = boto3.client("s3")
sns = boto3.client("sns")

LOGS_BUCKET = os.environ["LOGS_BUCKET"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

ERROR_KEYWORDS = ["ERROR", "CRITICAL", "Exception"]

def lambda_handler(event, context):
    compressed_payload = base64.b64decode(event["awslogs"]["data"])
    uncompressed_payload = gzip.decompress(compressed_payload)
    logs_data = json.loads(uncompressed_payload)

    processed_logs = []
    critical_logs = []

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
            "source": "cloudwatch"
        }

        processed_logs.append(log_entry)

    # Stockage S3 (logs enrichis)
    s3.put_object(
        Bucket=LOGS_BUCKET,
        Key=f"processed-logs/{datetime.utcnow().date()}.json",
        Body=json.dumps(processed_logs),
        ContentType="application/json"
    )

    # Alerte SNS si erreur critique
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
