all: serverless-wiki-lambda.zip

.PHONY: deploy deploy_aws clean

deploy: deploy_aws

deploy_aws: serverless-wiki-lambda.zip
	terraform apply

#lambda_sources = markdown2.py deploy.py edit.py $(shell find templates -type f) $(shell find resources -type f)
lambda_sources = markdown2.py deploy.py edit.py templates resources id_rsa

serverless-wiki-lambda.zip: $(lambda_sources)
	# boto3 comes preinstalled, so no need to fetch it
	pip install bcrypt dulwich paramiko pyhocon -t lambda
	cp -r $(lambda_sources) lambda
	cd lambda ; zip -r ../serverless-wiki-lambda.zip . ; cd ..

clean:
	-rm -r serverless-wiki-lambda.zip lambda
