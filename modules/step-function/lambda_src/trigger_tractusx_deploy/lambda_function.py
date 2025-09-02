import boto3
import os

def lambda_handler(event, context):
    codebuild = boto3.client("codebuild")
    
    project_name = os.environ.get("CODEBUILD_PROJECT_NAME", "tractusx-helm-deploy")
    
    try:
        response = codebuild.start_build(projectName=project_name)
        return {
            "statusCode": 200,
            "body": f"Triggered CodeBuild project: {project_name}",
            "buildId": response["build"]["id"]
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Failed to trigger CodeBuild project: {project_name}, error: {str(e)}"
        }
