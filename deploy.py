#!/usr/bin/env python

# Deploy your statically generated site. For now only implemented for uploading to s3,
# would be nice to also support scp, rsync, gh-pages, etc.

# TODO somehow create a 'package' that also includes boto3
import boto3
import os

s3 = boto3.resource('s3')

bucket = s3.Bucket('serverless-wiki')
top = os.environ['TARGET']

types = {
  '.html': "text/html",
  '.css': "text/css",
  '.js': "application/javascript",
  '.hocon': "application/hocon",
}

for dir, _, files in os.walk(top):
  reldir = os.path.relpath(dir, top)
  for file in files:
    target = file if reldir == '.' else os.path.join(reldir, file)
    type = types[os.path.splitext(file)[1]]
    print('Storing ', file, 'to', target, 'as', type)
    bucket.put_object(Key=target, Body=open(os.path.join(dir, file), 'rb'), ContentType=type)
