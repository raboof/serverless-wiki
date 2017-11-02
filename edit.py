import os
import markdown2
import sys
import fileinput
import bcrypt
from dulwich import porcelain
from pyhocon import ConfigFactory

def fetch_source():
  if os.path.isdir('/tmp/source/.git'):
    porcelain.pull('/tmp/source', os.environ['SOURCE_GIT_URL'], 'refs/heads/master')
  else:
    porcelain.clone(os.environ['SOURCE_GIT_URL'], '/tmp/source')

def get_user(username):
  return ConfigFactory.parse_file('/tmp/source/users/%s.hocon' % username)

def apply_template(md):
  with open (sys.path[0] + "/templates/index.html", "r") as template:
    result = ''
    line = template.readline()
    while line:
      if (line == '<!-- PAGE_CONTENT_HERE -->\n'):
        markdown = ''
        for line in fileinput.input():
          markdown += line
        # TODO further processing, e.g. handling in-wiki links
        # both to existing and non-existing pages.
        result += markdown2.markdown(md)
      else:
        result += (line.replace('\n', ''))
      line = template.readline()
  return result

def hello(post, context):
  user = post['queryStringParameters']['user']
  auth = post['queryStringParameters']['auth']

  fetch_source()
  user = get_user(user)

  if bcrypt.checkpw((os.environ['NONCE'] + auth).encode('utf-8'), user.get_string('password_hash').encode('utf-8')):
    return {
      'statusCode': '200',
      'body': apply_template(post['body']),
      'headers': {
        'Content-Type': 'text/html',
      },
    }
  else:
    return {
      'statusCode': '401',
      'body': 'Invalid password',
      'headers': {
        'Content-Type': 'text/plain',
      },
    }
