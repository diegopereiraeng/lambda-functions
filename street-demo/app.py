import json
import os
import random

def handler(event, context):
    """
    AWS Lambda function for a "Street Demo" App simulating a quick loan eligibility check.
    """
    try:
        customer_name = "Valued Customer"
        requested_loan_amount = None

        # Try to parse input from API Gateway event body
        if 'body' in event and event['body']:
            try:
                body = json.loads(event['body'])
                customer_name = body.get('name', customer_name)
                requested_loan_amount = body.get('requested_loan_amount')
                if requested_loan_amount:
                    requested_loan_amount = float(requested_loan_amount)
            except json.JSONDecodeError:
                print("Warning: Could not decode JSON body.")
            except ValueError:
                print("Warning: Could not convert requested_loan_amount to float.")
                requested_loan_amount = None # Reset if conversion fails
        else:
            # Fallback for direct invocation or other event types
            customer_name = event.get('name', customer_name)
            requested_loan_amount = event.get('requested_loan_amount')
            if requested_loan_amount:
                try:
                    requested_loan_amount = float(requested_loan_amount)
                except ValueError:
                    print("Warning: Could not convert requested_loan_amount to float.")
                    requested_loan_amount = None # Reset if conversion fails

        # Get bank offer ID from environment variable
        bank_offer_id = os.getenv('BANK_OFFER_ID', 'DEFAULT_OFFER_001')
        demo_version = os.getenv('DEMO_VERSION', 'v1.0-beta')

        eligibility_message = ""
        quick_approval_threshold = 5000.00
        interest_rate_suggestion = round(random.uniform(3.5, 8.5), 2) # Mock interest rate

        if requested_loan_amount is not None:
            if requested_loan_amount <= 0:
                eligibility_message = f"Hello {customer_name}, the loan amount must be positive. Please try again."
            elif requested_loan_amount <= quick_approval_threshold:
                eligibility_message = (
                    f"Hello {customer_name}! For a loan of ${requested_loan_amount:,.2f}, "
                    f"you're pre-qualified for a quick review! "
                    f"We can offer a potential interest rate around {interest_rate_suggestion}%. "
                    f"(Offer ID: {bank_offer_id})"
                )
            else:
                eligibility_message = (
                    f"Hi {customer_name}! For a loan of ${requested_loan_amount:,.2f}, "
                    f"you're eligible for our standard loan application process. "
                    f"An agent will contact you shortly. "
                    f"(Reference Offer ID: {bank_offer_id})"
                )
        else:
            eligibility_message = (
                f"Welcome, {customer_name}! Interested in a loan? "
                f"Provide a 'requested_loan_amount' to check your quick eligibility. "
                f"(Current Promo: {bank_offer_id})"
            )

        print(f"Processed request for: {customer_name}, Amount: {requested_loan_amount}")
        print(f"Eligibility message: {eligibility_message}")
        print(f"Demo Version: {demo_version}, Offer ID from env: {bank_offer_id}")

        response = {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "X-Demo-Version": demo_version
            },
            "body": json.dumps({
                "greeting": f"Welcome to YourBank's Quick Loan Checker, {customer_name}!",
                "eligibility_status": eligibility_message,
                "bank_offer_id": bank_offer_id,
                "demo_details": {
                    "version": demo_version,
                    "lambda_request_id": context.aws_request_id
                }
            })
        }
        return response

    except Exception as e:
        error_message = f"Server Error: We encountered an issue processing your request. Details: {str(e)}"
        print(f"Error processing event: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({"message": "Internal Server Error", "error_details": error_message})
        }

# Example of how you might test locally
if __name__ == "__main__":
    # Mock context object
    class MockContext:
        def __init__(self, request_id):
            self.aws_request_id = request_id

    print("\n--- Local Test: Generic Welcome ---")
    os.environ['BANK_OFFER_ID'] = 'LOCAL_PROMO_JULY'
    os.environ['DEMO_VERSION'] = 'v1.1-local'
    test_event_welcome = {"name": "Local Tester"}
    response_welcome = handler(test_event_welcome, MockContext('test-welcome-123'))
    print(json.dumps(response_welcome, indent=2))

    print("\n--- Local Test: Quick Loan Pre-qualification (API Gateway Style) ---")
    test_event_quick_loan = {
        "body": json.dumps({"name": "Jane Doe", "requested_loan_amount": 4500}),
        "headers": {"Content-Type": "application/json"}
    }
    response_quick_loan = handler(test_event_quick_loan, MockContext('test-quickloan-456'))
    print(json.dumps(response_quick_loan, indent=2))

    print("\n--- Local Test: Standard Loan Processing (Direct Invocation) ---")
    test_event_standard_loan = {"name": "John Smith", "requested_loan_amount": 15000}
    response_standard_loan = handler(test_event_standard_loan, MockContext('test-standard-789'))
    print(json.dumps(response_standard_loan, indent=2))

    print("\n--- Local Test: Invalid Loan Amount ---")
    test_event_invalid_loan = {"name": "Invalid User", "requested_loan_amount": -100}
    response_invalid_loan = handler(test_event_invalid_loan, MockContext('test-invalid-000'))
    print(json.dumps(response_invalid_loan, indent=2))

    print("\n--- Local Test: Body not JSON ---")
    test_event_bad_body = {
        "body": "this is not json",
        "headers": {"Content-Type": "application/json"}
    }
    response_bad_body = handler(test_event_bad_body, MockContext('test-badbody-111'))
    print(json.dumps(response_bad_body, indent=2))
