import boto3

def lambda_handler(event, context):
    codebuild = boto3.client("codebuild")
    project_name = "eks-deploy-vault"

    try:
        response = codebuild.start_build(projectName=project_name)
        build_id = response["build"]["id"]
        print(f"Triggered CodeBuild: {build_id}")

        return {
            "statusCode": 200,
            "body": f"Started CodeBuild project '{project_name}' with build id: {build_id}"
        }

    except Exception as e:
        print(f"Error starting CodeBuild: {e}")
        return {
            "statusCode": 500,
            "body": f"Failed to start CodeBuild project '{project_name}': {str(e)}"
        }
