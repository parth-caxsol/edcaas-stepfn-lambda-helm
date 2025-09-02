import boto3
import os

codebuild_client = boto3.client("codebuild")

PROJECT_NAME = os.environ.get("CODEBUILD_PROJECT_NAME", "eks-admin-ops")

def lambda_handler(event, context):
    """
    Lambda to trigger CodeBuild that creates a namespace in EKS.
    Namespace is already defined in the CodeBuild project script.
    """
    try:
        response = codebuild_client.start_build(projectName=PROJECT_NAME)
        build_id = response["build"]["id"]
        print(f"Triggered CodeBuild: {build_id}")

        return {
            "status": "STARTED",
            "buildId": build_id
        }

    except Exception as e:
        print(f"Error starting CodeBuild: {e}")
        raise
