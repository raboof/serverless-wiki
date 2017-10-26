all: serverless-wiki-lambda.zip

.PHONY: deploy deploy_aws clean

deploy: deploy_aws

deploy_aws: serverless-wiki-lambda.zip
	terraform apply

lambda_sources = markdown2.py deploy.py edit.py

serverless-wiki-lambda.zip: $(lambda_sources)
	# boto3 comes preinstalled, so no need to fetch it
	# pip install boto3 -t lambda
	zip serverless-wiki-lambda.zip $(lambda_sources)

clean:
	rm -r serverless-wiki-lambda.zip
