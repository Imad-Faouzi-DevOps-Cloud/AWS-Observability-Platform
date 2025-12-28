import json
import gzip
import base64
import os
import boto3
from datetime import datetime

s3 = boto3.client("s3")
LOGS_BUCKET = os.environ["LOGS_BUCKET"]

def lambda_handler(event, context):
    # 1. Décodage du message CloudWatch
    compressed_payload = base64.b64decode(event["awslogs"]["data"])
    uncompressed_payload = gzip.decompress(compressed_payload)
    logs_data = json.loads(uncompressed_payload)

    processed_logs = []

    # 2. Parcours des logs
    for log_event in logs_data["logEvents"]:
        message = log_event["message"]

        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "message": message,
            "log_group": logs_data["logGroup"],
            "log_stream": logs_data["logStream"],
            "source": "cloudwatch"
        }

        processed_logs.append(log_entry)

    # 3. Écriture dans S3 (logs enrichis)
    s3.put_object(
        Bucket=LOGS_BUCKET,
        Key=f"processed-logs/{datetime.utcnow().date()}.json",
        Body=json.dumps(processed_logs),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "body": f"{len(processed_logs)} logs processed"
    }
