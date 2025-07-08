# Use an official AWS Lambda Python runtime image
# You can specify a Python version, e.g., public.ecr.aws/lambda/python:3.9
# Using a more generic tag will get the latest supported version for the region/runtime.
FROM public.ecr.aws/lambda/python:3.11

# Set the working directory in the container
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy the requirements file first (to leverage Docker cache)
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
# If requirements.txt is empty, this command will still run but do nothing.
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy the Lambda function code
COPY app.py .

# Set the CMD to your handler (app.handler)
# The file is app.py and the handler function is handler
CMD [ "app.handler" ]
