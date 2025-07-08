import json

def handler(event, context):
    """
    Dummy Lambda handler for initial Terraform deployment.
    This code is just a placeholder and will be overwritten by CI/CD.
    """
    print("Dummy Lambda handler (from Terraform initial deploy via S3) was invoked.")
    print(f"Event received: {json.dumps(event)}")

    # Example of accessing environment variables set by Terraform
    bank_offer_id = context.function_name # os.getenv('BANK_OFFER_ID', 'UNKNOWN_OFFER')
    demo_version = context.function_version # os.getenv('DEMO_VERSION', 'unknown-version')

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "X-Deployed-By": "Terraform-Initial"
        },
        "body": json.dumps({
            "message": "Dummy Handler: Successfully invoked!",
            "note": "This is the initial placeholder function deployed by Terraform.",
            "function_name": context.function_name,
            "function_version": context.function_version,
            "bank_offer_id_from_env_in_lambda_def": bank_offer_id,
            "demo_version_from_env_in_lambda_def": demo_version,
            "event_preview": event
        })
    }
