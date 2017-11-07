import os
import markdown2
import sys
import fileinput
import bcrypt
import re
import shutil
import boto3
from subprocess import call

from dulwich import client as _mod_client
from dulwich.contrib.paramiko_vendor import ParamikoSSHVendor

import templating

class MyParamikoSSHVendor(ParamikoSSHVendor):
  def __init__(self):
    self.ssh_kwargs = { 'key_filename': sys.path[0] + '/id_rsa' }

_mod_client.get_ssh_vendor = MyParamikoSSHVendor

from dulwich import porcelain
from pyhocon import ConfigFactory

def fetch_source():
  if os.path.isdir('/tmp/source/.git'):
    print('pulling')
    porcelain.pull('/tmp/source', os.environ['SOURCE_GIT_URL'], 'refs/heads/master')
  else:
    print('cloning')
    porcelain.clone(os.environ['SOURCE_GIT_URL'], '/tmp/source')
  print('updated')

def get_user(username):
  try:
    return ConfigFactory.parse_file('/tmp/source/users/%s.hocon' % username)
  except IOError:
    return None

s3 = boto3.resource('s3')
bucket = s3.Bucket('serverless-wiki')

def update_storage(page, html):
  print('putting object')
  bucket.put_object(Key=page + '.html', Body=html, ContentType='text/html')
  print('put object')

def update_git(page, new_md, username, user):
  filename = "/tmp/source/%s.md" % page
  with open(filename, "w") as text_file:
    text_file.write(new_md)

  porcelain.add('/tmp/source', filename)

  author = user.get_string('full_name') + ' <' + username + '@invalid>'
  committer = 'lambda <lambda@bzzt.net>'
  print('committing')
  porcelain.commit('/tmp/source', "Page '%s' updated" % page, author=author, committer=committer)
  print('pushing')
  porcelain.push('/tmp/source', os.environ['SOURCE_GIT_URL'], 'refs/heads/master')
  print('pushed')

def error(status, body):
  return {
    'statusCode': status,
    'body': body,
    'headers': {
      'Access-Control-Allow-Origin': '*',
    }
  }

name_pattern = re.compile("^[a-zA-Z0-9_]+$")

def valid_name(name):
  return name_pattern.match(name)

def hello(post, context):
  username = post['queryStringParameters']['user']
  auth = post['queryStringParameters']['auth']
  page = post['queryStringParameters']['page']

  if not valid_name(username):
    return error('400', 'Invalid user')
  if not valid_name(page):
    return error('400', 'Invalid page')

  fetch_source()
  user = get_user(username)

  if not user:
    return error('401', 'Unknown user')

  print('checking bcrypt hash')
  if not bcrypt.checkpw((os.environ['NONCE'] + auth).encode('utf-8'), user.get_string('password_hash').encode('utf-8')):
    return error('401', 'Invalid password')

  print('applying template')
  apiId = post['requestContext']['apiId']
  new_html = templating.apply_template(post['body'], 'https://' + apiId + '.execute-api.' + os.environ['AWS_REGION'] + '.amazonaws.com/sw_prod')

  update_git(page, post['body'], username, user)
  update_storage(page, new_html)

  return {
    'statusCode': '200',
    'body': new_html,
    'headers': {
      'Content-Type': 'text/html',
      'Access-Control-Allow-Origin': '*',
    }
  }
